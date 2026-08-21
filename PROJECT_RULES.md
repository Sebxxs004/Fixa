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