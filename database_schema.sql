-- 1. Habilitar la extensión espacial (Obligatorio para la proximidad geográfica)
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- Para generación de gen_random_uuid()

-- ==========================================
-- 2. TABLAS BASE Y PERFILES
-- ==========================================

CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL, -- Vínculo con el JWT de Firebase Auth
    nombre_completo VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) UNIQUE,
    email VARCHAR(150) UNIQUE NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('CLIENTE', 'TRABAJADOR', 'ADMIN')),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE perfiles_trabajador (
    usuario_id UUID PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    documento_identidad VARCHAR(50) UNIQUE,
    estado_verificacion VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado_verificacion IN ('PENDIENTE', 'RECHAZADO', 'APROBADO_KYC')),
    calificacion_promedio NUMERIC(3, 2) DEFAULT 5.00,
    total_trabajos_completados INT DEFAULT 0,
    -- Telemetría Geoespacial
    ubicacion_actual GEOMETRY(Point, 4326), 
    ultima_actualizacion_gps TIMESTAMP WITH TIME ZONE
);

-- Índice espacial para búsquedas ultrarrápidas de proximidad (ST_DWithin)
CREATE INDEX idx_trabajador_ubicacion ON perfiles_trabajador USING GIST (ubicacion_actual);

CREATE TABLE categorias_servicio (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    tarifa_base_diagnostico NUMERIC(10, 2) NOT NULL, -- Tarifa de desplazamiento por defecto
    activo BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- 3. NÚCLEO TRANSACCIONAL (MÁQUINA DE ESTADOS)
-- ==========================================

CREATE TABLE ordenes_servicio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subasta_firebase_id VARCHAR(100) UNIQUE, -- Para hacer el puente con la subasta efímera
    cliente_id UUID NOT NULL REFERENCES usuarios(id),
    trabajador_id UUID REFERENCES usuarios(id),
    categoria_id INT NOT NULL REFERENCES categorias_servicio(id),
    
    -- Manejo del Estado (La Máquina de Estados)
    estado VARCHAR(50) NOT NULL CHECK (estado IN (
        'ACEPTADA_EN_CAMINO', 
        'EN_SITIO', 
        'FINALIZADA_EXITOSA', 
        'FINALIZADA_SOLO_DIAGNOSTICO', 
        'CANCELADA_GRATIS_CLIENTE', 
        'CANCELADA_CON_PENALIZACION_CLIENTE', 
        'CANCELADA_TRABAJADOR',
        'CANCELADA_SISTEMA'
    )),
    
    -- Reglas Financieras de la Orden
    es_visita_diagnostico BOOLEAN NOT NULL,
    precio_diagnostico NUMERIC(10, 2) NOT NULL,
    precio_final NUMERIC(10, 2), -- Nulo hasta que el trabajador evalúe el daño en sitio
    comision_plataforma NUMERIC(10, 2),
    
    -- Geolocalización y SLA (Acuerdos de Servicio)
    origen_ubicacion GEOMETRY(Point, 4326) NOT NULL, -- Casa del cliente
    punto_no_retorno_cruzado BOOLEAN DEFAULT FALSE,
    tiempo_estimado_llegada_minutos INT,
    
    -- Trazabilidad
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 4. PAGOS Y ANTIFRAUDE (IDEMPOTENCIA)
-- ==========================================

CREATE TABLE transacciones_pago (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_id UUID NOT NULL REFERENCES ordenes_servicio(id),
    idempotency_key VARCHAR(100) UNIQUE NOT NULL, -- Bloquea cobros duplicados por red inestable
    
    -- Datos de la Pasarela (ej. Wompi)
    token_transaccion_pasarela VARCHAR(255),
    monto_total NUMERIC(10, 2) NOT NULL,
    tipo_movimiento VARCHAR(30) NOT NULL CHECK (tipo_movimiento IN ('RETENCION', 'COBRO_FINAL', 'COBRO_PENALIDAD', 'REEMBOLSO')),
    estado_pago VARCHAR(30) NOT NULL CHECK (estado_pago IN ('PENDIENTE', 'APROBADO', 'DECLINADO', 'REVERTIDO')),
    
    fecha_transaccion TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 5. AUDITORÍA INMUTABLE (HISTORIAL DE ESTADOS)
-- ==========================================

CREATE TABLE historial_estados_orden (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    orden_id UUID NOT NULL REFERENCES ordenes_servicio(id),
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50) NOT NULL,
    modificado_por UUID REFERENCES usuarios(id), -- Quién provocó el cambio (Cliente, Trabajador o Sistema)
    notas TEXT, -- Razón de cancelación, etc.
    fecha_cambio TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 6. TRIGGERS Y AUTOMATIZACIONES (OPCIONAL/RECOMENDADO)
-- ==========================================

-- Función para actualizar automáticamente la columna 'actualizado_en'
CREATE OR REPLACE FUNCTION actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_orden
BEFORE UPDATE ON ordenes_servicio
FOR EACH ROW
EXECUTE FUNCTION actualizar_timestamp();