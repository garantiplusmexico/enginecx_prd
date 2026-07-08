# PRD - Generación de endpoint de health check (OK) en el servicio de Generales

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Generación de endpoint de health check (OK) en el servicio de Generales |
| **Área / empresa** | Gplus Seguros |
| **Versión** | v0.1 |
| **Fecha** | 2026-07-08 |
| **Autores** | Alexis Herrera (solicitante) · Juan Carlos (implementación) |
| **Revisión / liderazgo** | Aldo Álvarez (Director de TI) |
| **Tipo de proyecto** | Feature web o API |

## 1. Resumen ejecutivo

Se requiere exponer un **endpoint de health check** en el **servicio de Generales** de Gplus Seguros que responda un simple `OK` cuando el servicio está en ejecución. El objetivo es permitir **verificar de forma automática** que el servicio está operativo, sin depender de una comprobación manual o reactiva.

Hoy no existe una forma programática y liviana de confirmar que el servicio responde; los problemas de disponibilidad tienden a detectarse tarde. Este endpoint habilita el monitoreo automático (polling) por parte de una herramienta o servicio que aún está por definirse.

El MVP se limita a un **check de liveness**: el endpoint confirma únicamente que el servicio está vivo y responde, **sin validar dependencias** (base de datos, SIGA u otros) y **sin autenticación**. Queda fuera cualquier verificación de readiness, tablero o configuración de alertas.

Resultado esperado: detección temprana y automática de caídas del servicio de Generales, reduciendo el tiempo entre una caída y su detección.

**Monitor (por definir)** → **GET al endpoint (servicio de Generales)** → **200 `OK`** → **estado registrado / alerta si falla**

## 2. Contexto y problema

- **Hoy:** no hay un endpoint estándar y liviano para consultar si el servicio de Generales está arriba. La verificación es manual o reactiva (se nota cuando algo falla, no antes).
- **Dolor:** falta de visibilidad automática de disponibilidad; posible detección tardía de caídas.
- **Por qué ahora:** se quiere monitorear de forma automática que los servicios funcionan, y este endpoint es el mínimo necesario para lograrlo.
- **Distinción clave del dominio:** *liveness* (el servicio responde) **≠** *readiness* (el servicio y sus dependencias están listos para operar). Este MVP cubre **solo liveness**.

## 3. Objetivo del producto

Exponer un endpoint HTTP liviano en el servicio de Generales que retorne `OK` (HTTP 200) cuando el servicio esté en ejecución, para que un consumidor automático pueda comprobar periódicamente su disponibilidad. La mejora esperada es pasar de una verificación manual/reactiva a una **automática**.

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Endpoint de liveness | Endpoint HTTP en el servicio de Generales que, al ser invocado, responde `OK` con código 200 si el servicio está en ejecución. |
| Acceso público | El endpoint responde sin requerir autenticación ni token, para que un monitor pueda consultarlo directamente. |
| Respuesta liviana | La respuesta no consulta base de datos ni dependencias externas; solo confirma que el servicio atiende peticiones. |

**Principio rector del MVP:** el endpoint debe ser **trivial y sin efectos secundarios** — no valida dependencias, no expone información del sistema ni datos de negocio, no escribe nada. Solo responde que el servicio está vivo.

## 6. Fuera de alcance

- **Readiness / validación de dependencias** (BD, SIGA, etc.): se excluye por simplicidad; se habilitaría si más adelante se necesita distinguir "vivo" de "listo para operar".
- **Autenticación en el endpoint:** se excluye porque un health check público facilita el monitoreo; se reconsideraría si se decide no exponerlo públicamente.
- **Tablero / visualización de estado:** fuera del alcance; corresponde a la herramienta de monitoreo, no al servicio.
- **Configuración de alertas y umbrales:** depende del consumidor (aún por definir), no del endpoint.
- **Métricas de negocio o de salud detallada** (CPU, memoria, latencias internas): el MVP solo devuelve `OK`.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Responder estado del servicio | El endpoint debe responder con HTTP 200 y un indicador `OK` cuando el servicio de Generales está en ejecución. |
| RF-02 | Acceso sin autenticación | El endpoint debe ser consultable sin token ni credenciales. |
| RF-03 | Comprobación de liveness | El endpoint no debe consultar base de datos ni dependencias externas; solo confirma que el servicio atiende. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Tiempo de respuesta | El endpoint debe responder rápido (objetivo: < 500 ms) para ser útil en polling frecuente. |
| RNF-02 | Seguridad / no exposición | Aunque público, no debe exponer datos sensibles, internos ni de negocio: solo el estado `OK`. |
| RNF-03 | Observabilidad | Las invocaciones deberían quedar en los logs estándar del servicio, evitando ruido excesivo por el polling. |
| RNF-04 | Mantenibilidad | Implementación mínima y sin dependencias, para bajo costo de mantenimiento. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| Servicio de Generales (Gplus Seguros) | Aloja el endpoint. No escribe ni lee datos de negocio; solo expone su propio estado. |
| Consumidor de monitoreo (por definir) | Lectura del endpoint mediante polling periódico; alertaría si no recibe `OK`. |

**Datos mínimos:** ninguno de negocio. La única salida es el indicador de estado (`OK`).

**Esquema de permisos:** el endpoint es de **solo lectura de estado**, **público sin token**, **sin capacidad de escritura** y **sin acceso a datos de negocio**. No requiere validación humana ni de TI para ser consultado.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| Disponibilidad detectada del servicio | % de comprobaciones exitosas (`OK`) sobre el total — *depende de definir el consumidor/monitor*. |
| Tiempo de detección de caídas | Reducción del tiempo entre una caída del servicio y su detección (de manual/reactivo a automático). |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| Consumidor | ¿Qué herramienta consumirá el endpoint (uptime externo, CloudWatch, ALB/ECS, N8N, cron) y con qué frecuencia de polling? |
| Contrato del endpoint | ¿Ruta y método definitivos (p. ej. `GET /health`, `/ping`, `/status`)? |
| Formato de respuesta | ¿Texto plano `OK` o JSON (`{"status":"OK"}`)? ¿Siempre 200? |
| Stack del servicio | Confirmar la tecnología del servicio de Generales (¿.NET/C#?) — no se especificó. |
| Ambientes | ¿Se requiere el endpoint en varios ambientes (dev/QA/prod)? |
| Revisión | Confirmar a Aldo Álvarez como Revisión/liderazgo. |
