# 🚀 PROJECT_RULES.md - Marketplace de Servicios Empíricos

## 1. Visión General y Rol del Agente
Actúa como un Arquitecto de Software Senior. Estamos construyendo un marketplace bilateral para servicios empíricos basado en subasta inversa con geolocalización. El sistema utiliza persistencia políglota: Firebase para el tiempo real y PostgreSQL para la verdad transaccional.

## 2. Stack Tecnológico Definitivo
- **Frontend Móvil:** Flutter (Dart).
- **Gestión de Estado UI:** BLoC (Patrón estricto de eventos y estados).
- **Backend Core (Transaccional):** Java 21 con Spring Boot, expuesto como API REST, desplegado en Google Cloud Run.
- **Base de Datos Core:** PostgreSQL. Uso de Foreign Keys estrictas, constraints y triggers para auditoría de estados.
- **Capa Tiempo Real & Auth:** Firebase (Firestore para la subasta activa, Firebase Auth para tokens JWT, Cloud Storage para fotos del daño).
- **Pagos:** Integración API con Wompi/MercadoPago para retención y dispersión de fondos.

## 3. Reglas de Negocio (Subastas y Diagnósticos)
- **Subasta Inversa Efímera:** El cliente sube evidencia. Firestore abre un documento temporal. Los trabajadores pujan. Al aceptar una oferta, el documento de Firestore se destruye/archiva y la orden definitiva nace en PostgreSQL.
- **Diagnóstico vs. Cierre:** El trabajador DEBE indicar si su oferta es "Cierre Final" o "Visita de Diagnóstico". Si es diagnóstico, el sistema informará al usuario que el costo se descontará del precio final si se acepta la reparación.
- **Trazabilidad Financiera:** La lógica de retención de pagos y comisiones vive exclusivamente en el backend de Spring Boot, NUNCA en el frontend ni en Firebase.

## 4. Patrones de Diseño (Agent Instructions)
1. **Clean Architecture:** En Flutter, separa las capas en `presentation`, `domain` y `data`. En Spring Boot, usa `Controllers`, `Services`, y `Repositories`.
2. **Evaluación Heurística UI:** Las pantallas deben prevenir errores (ej. confirmación doble al aceptar un costo de diagnóstico) y mostrar el estado del sistema siempre (ej. loaders, distancia del trabajador).
3. **Manejo de Errores:** Todos los errores de red o base de datos deben ser capturados y mostrados al usuario sin exponer la traza técnica.

## 5. Proceso de Desarrollo y VibeCoding

Para mantener la estabilidad del sistema, el agente debe seguir estrictamente este orden al desarrollar cualquier nueva funcionalidad (Feature):

1. **Análisis y Diseño:** Antes de codificar, genera un `implementation_plan.md` breve. Si la funcionalidad requiere guardar datos, diseña primero el esquema (SQL o JSON).
2. **Capa de Datos:** Crea las tablas de PostgreSQL, las reglas de Firestore o las funciones de almacenamiento necesarias.
3. **Capa de Lógica (Backend/BLoC):** Implementa los controladores en Spring Boot o los eventos/estados en el BLoC de Flutter. Asegura que la lógica de negocio funcione sin depender de la interfaz.
4. **Capa de Presentación (UI):** Construye la interfaz visual en Flutter consumiendo los estados ya definidos.
5. **Autocorrección:** Si el emulador arroja un error de compilación o ejecución, el agente debe leer el log de errores completo antes de proponer un parche a ciegas.
6. **Pruebas (Testing):** Todo código nuevo debe ir acompañado de pruebas unitarias (en Dart y Java) y de integración (Smoke Tests para APIs y Flows críticos en Flutter). El agente no debe marcar una tarea como completada sin haber generado las pruebas correspondientes.
7. **Documentación:** Al finalizar una Feature, actualiza `ARCHITECTURE.md` con los cambios en el esquema de base de datos o en el flujo de eventos si es necesario.
8. **Performance & Cost Control (Critical):**
    - **Firestore:** Evita queries que escaneen colecciones completas (`>1000` documentos). Usa índices manuales o TTL (Time-to-Live) para documentos temporales de subastas. Evita pagos por "Query Snapshots" en bucles infinitos.
    - **Spring Boot:** Implementa paginación (`Pageable`) en todos los endpoints de listado. Usa `Lazy Loading` en las relaciones de Hibernate para evitar consultas N+1.

## 6. Políticas de Seguridad y Arquitectura Defensiva

El agente debe aplicar una postura de "Confianza Cero" (Zero Trust) en todo el código generado:

- **Reglas de Firebase (Firestore & Storage):** Denegación por defecto (`allow read, write: if false;`). El acceso a lectura/escritura en los nodos de subasta debe estar estrictamente limitado mediante validación del `auth.uid`. Los trabajadores solo pueden insertar en la subcolección de "ofertas" y no pueden modificar documentos de terceros.
- **Seguridad en Backend (Spring Boot / Java 21):** Ningún endpoint REST transaccional puede ser público. Todos deben exigir y validar criptográficamente el token JWT emitido por Firebase Auth. 
- **Idempotencia Financiera:** Cualquier mutación de estado que involucre pagos, aceptación de ofertas o cobros de "Visitas de Diagnóstico" debe requerir y validar una `idempotency_key` única para evitar cobros duplicados por latencia de red.
- **Validación de Identidad y KYC:** La arquitectura de la base de datos debe contemplar los campos necesarios para almacenar el estado de verificación de identidad de los contratistas. 
- **Cumplimiento Normativo (Colombia):** El tratamiento de fotografías y notas de voz debe estructurarse respetando el marco de protección de datos. Asimismo, el modelo de datos de los trabajadores debe estar preparado para integrarse con APIs de validación de antecedentes penales y disciplinarios (estructurado para soportar validaciones bajo marcos como la Ley 906 de 2004 u otros procedimientos judiciales y administrativos locales). Jamás se almacenará información de tarjetas de crédito en texto plano; se usará exclusivamente tokenización.

## 7. Máquina de Estados y Reglas de Penalización (The State Machine)

La gestión del ciclo de vida de una Orden debe basarse estrictamente en transacciones de estado. NUNCA se debe actualizar un estado sin validar los requisitos (ej. ubicación GPS, tiempo transcurrido).

### Reglas de Cancelación y El "Punto de No Retorno"
- **Punto de No Retorno:** Se activa cuando el trabajador ha recorrido el 50% de la distancia o está a menos de 1km/5 minutos de distancia (validado vía telemetría GPS en el backend).
- **Cancelación de Gracia:** Si el cliente cancela ANTES del Punto de No Retorno, no hay cobro.
- **Cancelación Tardía (Cliente):** Si el cliente cancela DESPUÉS del Punto de No Retorno, el sistema ejecuta automáticamente el cobro de la "Tarifa de Desplazamiento" de su tarjeta retenida y se lo transfiere al trabajador. La orden pasa a `CANCELADA_CON_PENALIZACION_CLIENTE`.
- **Protección Anti-Fraude (SLA Trabajador):** Si la telemetría indica que el trabajador NO se ha acercado al destino en un umbral de 10 minutos, o si el ETA inicial se ha excedido al doble, el Punto de No Retorno se ANULA. El cliente puede cancelar gratis, y la orden pasa a `CANCELADA_POR_RETRASO_TRABAJADOR` (afectando la reputación del trabajador).

## 8. Infraestructura Avanzada y Servicios Core

El sistema depende de las siguientes herramientas de infraestructura para escalar. El agente debe utilizarlas estrictamente según estas directrices:

### 8.1 Motor Geoespacial (Proximidad y Asignación)
- **Tecnología:** PostGIS (Extensión de PostgreSQL).
- **Regla:** El cálculo de distancia (`ST_DWithin`) se hace SIEMPRE en el backend (Spring Boot). El frontend JAMÁS debe descargar listas de trabajadores para filtrar por ubicación localmente.
- **Telemetría:** La app del trabajador en estado "En Camino" enviará pings GPS periódicos. El backend evaluará estas coordenadas para determinar "El Punto de No Retorno".

### 8.2 Notificaciones Push (FCM)
- **Tecnología:** Firebase Cloud Messaging (FCM).
- **Regla:** Las alertas de "Nueva Solicitud" para los trabajadores deben enviarse como notificaciones de alta prioridad (Data Messages) desde el backend de Spring Boot, incluyendo el `subasta_id` en el payload para despertar la app y conectar automáticamente al WebSocket de Firestore.

### 8.3 Timeouts y Limpieza (Garbage Collection)
- **Subastas Huérfanas:** Toda subasta en Firestore tiene un tiempo de vida máximo de 15 minutos. Debe implementarse un mecanismo de limpieza (Políticas TTL de Firestore o Cron Jobs en Spring Boot) que pase la orden a `CANCELADA_SISTEMA_SIN_OFERTAS` y elimine el documento temporal para no consumir costos de lectura.
- **Timeouts de Trabajador:** Si un trabajador acepta la orden pero su GPS no se mueve hacia el destino en un umbral de 10 minutos, el sistema debe anular su protección y permitir la cancelación gratuita al cliente.

### 8.4 Observabilidad y Manejo de Errores
- **Tecnología:** Firebase Crashlytics (Frontend) y Sentry (Backend).
- **Regla Estricta (Anti-Silencio):** Queda terminantemente prohibido usar bloques `try/catch` vacíos o ignorar excepciones. Todo error de red, base de datos o lógica debe ser registrado en las herramientas de observabilidad con el contexto necesario (`user_id`, `orden_id`) antes de devolver un mensaje genérico al usuario.