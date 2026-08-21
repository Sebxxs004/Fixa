# Plan de Implementación - Proyecto Fixa

Este documento presenta la propuesta arquitectónica y la hoja de ruta para el desarrollo del MVP de **Fixa**, un marketplace bidireccional de servicios empíricos basado en subasta inversa con geolocalización en tiempo real.

---

## Estructura de Carpetas del Backend (Spring Boot + Java 21)

Se propone una **Arquitectura Limpia (Clean Architecture)** adaptada a Spring Boot para desacoplar la lógica del negocio de los frameworks y la base de datos.

```
src/main/java/com/fixa
├── core/                         # CAPA DE DOMINIO Y CASOS DE USO (Clean Domain)
│   ├── model/                    # Modelos de dominio puros (Usuario, Orden, Transaccion)
│   ├── repository/               # Interfaces de puertos de salida (DatabasePort, PaymentPort, NotificationPort)
│   └── usecase/                  # Casos de uso (Lógica de negocio: IniciarSubasta, ProcesarPago, CalcularPenalizacion)
│
├── infrastructure/               # CAPA DE INFRAESTRUCTURA (Adaptadores y Frameworks)
│   ├── persistence/              # Persistencia relacional (PostgreSQL + PostGIS)
│   │   ├── entity/               # Entidades JPA (UserEntity, OrderEntity)
│   │   ├── repository/           # Repositorios Spring Data JPA con consultas espaciales
│   │   └── adapter/              # Implementación del puerto de persistencia de dominio
│   ├── firebase/                 # Integración con Firebase Admin SDK
│   │   ├── auth/                 # Validación de tokens JWT de Firebase Auth
│   │   ├── firestore/            # Gestión de subastas efímeras y limpieza (TTL/Crones)
│   │   └── messaging/            # Envío de notificaciones FCM push de alta prioridad
│   ├── payment/                  # Adaptador de pasarela de pagos (Wompi/MercadoPago)
│   └── security/                 # Configuración de Spring Security (Filtro JWT stateless)
│
└── presentation/                 # CAPA DE PRESENTACIÓN (Controladores y API REST)
    ├── controller/               # Controladores REST (endpoints transaccionales)
    ├── dto/                      # Data Transfer Objects (Requests/Responses)
    └── exception/                # GlobalExceptionHandler y formateo estandarizado de errores
```

---

## Estructura de Carpetas de la App Móvil (Flutter)

Se utiliza una arquitectura por capas orientada al patrón **BLoC** para el control de estados reactivos.

```
lib/
├── core/                         # CAPA CORE
│   ├── theme/                    # Paleta de colores e identidad visual
│   ├── network/                  # Cliente HTTP (Dio) con interceptores para JWT e Idempotency Key
│   └── router/                   # Configuración de rutas (go_router)
│
├── data/                         # CAPA DE DATOS
│   ├── datasources/              # Orígenes de datos
│   │   ├── remote_api.dart       # API REST de Spring Boot
│   │   └── firestore_stream.dart # Conexión directa a Firestore para subasta en tiempo real
│   ├── models/                   # Modelos de serialización JSON/Firestore (DTOs de Flutter)
│   └── repositories/             # Implementaciones de las interfaces de dominio
│
├── domain/                       # CAPA DE DOMINIO
│   ├── entities/                 # Entidades de negocio inmutables
│   ├── repositories/             # Interfaces de repositorios (Contratos)
│   └── usecases/                 # Casos de uso específicos de la App (ej. SolicitarServicio)
│
└── presentation/                 # CAPA DE PRESENTACIÓN (UI + BLoCs)
    ├── blocs/                    # BLoCs compartidos
    │   ├── auth/                 # Manejo del ciclo de sesión Firebase
    │   └── location/             # Control del estado del GPS y geofencing
    ├── screens/                  # Pantallas organizadas por flujos
    │   ├── auth/                 # Login y registro
    │   ├── home/                 # Mapa y solicitudes iniciales
    │   ├── auction/              # Flujo reactivo de pujas en tiempo real
    │   ├── order/                # Seguimiento activo y Punto de No Retorno
    │   └── profile/              # Perfil de usuario y subida de documentos KYC
    └── widgets/                  # Componentes reutilizables de UI (botones, cards, loaders)
```

---

## Hoja de Ruta (Roadmap) - 4 Fases para el MVP

### Fase 1: Infraestructura Base, Seguridad y Autenticación
*Prioridad: Establecer el canal seguro de comunicación y la persistencia relacional básica.*
* **Base de datos:** Inicialización de PostgreSQL con extensión PostGIS instalada. Creación de tablas base (`usuarios`, `perfiles_trabajador` y `categorias_servicio`).
* **Backend:** Configuración inicial de Spring Boot, integración con Firebase Admin SDK para verificación de tokens. Configuración de Spring Security para denegar todo endpoint por defecto y validar JWT.
* **App Móvil:** Inicialización del proyecto Flutter, configuración de Firebase Core e integración básica del `AuthBloc` para manejar el login/registro de usuarios.

### Fase 2: Motor de Geolocalización y Telemetría
*Prioridad: Habilitar la precisión y seguridad de la asignación geográfica.*
* **Base de datos:** Creación del índice espacial GIST `idx_trabajador_ubicacion` sobre la tabla de perfiles.
* **Backend:** Desarrollo de endpoints para recibir pings GPS periódicos del trabajador y persistirlos en `perfiles_trabajador`. Implementación de consultas espaciales mediante PostGIS (`ST_DWithin`) para obtener trabajadores aptos a la redonda de la solicitud.
* **App Móvil:** Integración de geolocalización en segundo plano para trabajadores. Desarrollo del `LocationBloc` para trackear la posición.
* **Notificaciones:** Integración del flujo FCM (Firebase Cloud Messaging) para despertar la app de los trabajadores con payloads de alta prioridad cuando se inicie una subasta en su rango.

### Fase 3: Subasta Efímera y Máquina de Estados
*Prioridad: Coordinar la transición del tiempo real (Firestore) a la verdad transaccional (PostgreSQL).*
* **Firebase:** Configuración estricta de `firestore.rules` (Zero Trust). Solo usuarios autenticados pueden operar según su rol. Los trabajadores solo escriben en la subcolección de pujas.
* **Backend:** Lógica de negocio para abrir el documento temporal en Firestore. Listener del backend para cuando el cliente acepte una puja: destrucción automática del documento temporal en Firestore e inserción inmediata en PostgreSQL (`ordenes_servicio`) con estado `ACEPTADA_EN_CAMINO`.
* **Máquina de Estados:** Implementación del trigger de auditoría de estados. Desarrollo de la lógica de "Punto de No Retorno" basada en telemetría de distancias en tiempo real.

### Fase 4: Integración Financiera, Idempotencia y KYC
*Prioridad: Seguridad transaccional final, antifraude y cumplimiento legal.*
* **Pagos:** Integración de la pasarela de pagos (Wompi o MercadoPago) para la retención del dinero (Escrow) al iniciar el servicio, el cobro final o el cobro de penalidades por cancelación tardía.
* **Idempotencia:** Implementación estricta de filtro en Spring Boot que verifique la `idempotency_key` provista por el cliente antes de procesar transacciones financieras.
* **KYC (Know Your Customer):** Modelo de almacenamiento de fotografías de documentos de identidad en Cloud Storage y campos de verificación del perfil de trabajador.
