# Plan de Desarrollo — NISSAN Business Hub (Alianza Valladolid)

> Generado por Claude Code a partir del PRD `NISSAN/business-hub-valladolid/PRD.md` (v0.1).
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/NISSAN/business-hub-valladolid/PRD.md` (v0.1) |
| Repositorio (backend/CMS) | **Nuevo** — propuesto `nissan-business-hub-api` (Strapi) — por crear |
| Repositorio (frontend) | **Nuevo** — propuesto `nissan-business-hub-portal` (Next.js) — por crear |
| Rama base | `develop` (repos nuevos, estructura de ramas Engine: `main`/`develop`/`pre-qa`/`qa`) |
| Rama funcional | `feature/nissan-business-hub-valladolid-mvp` (en ambos repos) |
| Tipo | Proyecto nuevo (Feature web/API) — primera implementación del Portal Comercial B2B |
| Responsable | Equipo de desarrollo Go Virtual — persona específica pendiente de asignar (PRD §4/§14) |
| Solicitante / patrocinador | Christian Torres (NISSAN Perinorte) |
| Responsable de cuenta | Andrea López de Nava (Go Virtual) |
| Fecha de generación | 2026-08-19 |
| Modelo | claude-sonnet-5 |
| Estado | Borrador |

---

## 0. Estimación de tiempos

> Supuesto: **1 desarrollador full-time**. Se da rango por los puntos aún pendientes de definir en el PRD (mecanismo de autenticación, nivel de detalle de validación de carga masiva, disponibilidad de la API de Seekop) — ver Riesgos (§11).

| Fase | Incluye | Tareas | Días hábiles (rango) |
|---|---|---|---|
| **Fase 0 — Scaffold e infraestructura base** | Repos nuevos (backend Strapi + frontend Next.js), EC2/Postgres/S3, `CLAUDE.md`, Nginx/systemd | T-01 a T-05 | 3 – 4 días |
| **Fase 1 — Catálogo, precios, materiales y contenido** | Content types de catálogo/precios/materiales/banners + RBAC de backoffice | T-06 a T-10 | 4 – 5 días |
| **Fase 2 — Autenticación y gestión de ejecutivos** | Rol "Ejecutivo", login, recuperación de contraseña, activación/suspensión, carga masiva CSV/Excel + validación | T-11 a T-15 | 4 – 6 días |
| **Fase 3 — Portal del ejecutivo (frontend)** | Home de la alianza, catálogo/precios/materiales protegidos, diseño responsivo, burbuja WhatsApp | T-16 a T-19 | 5 – 7 días |
| **Fase 4 — Cotización y Seekop** | Formulario + folio, integración de escritura a Seekop, manejo de error en 3 pasos, trazabilidad end-to-end | T-20 a T-23 | 5 – 7 días |
| **Fase 5 — Analítica y reportes** | Eventos de BI, reportes de actividad/solicitudes en backoffice (consulta + exportación) | T-24 a T-25 | 3 – 4 días |
| **Fase 6 — Pruebas, seguridad, observabilidad y despliegue** | Matriz de pruebas end-to-end, logs/manejo de errores, despliegue a producción, verificación 24/7 | T-26 a T-28 | 3 – 4 días |
| **Total proyecto (entregable único, sin desglose de fases priorizadas)** | | 28 tareas | **~27 – 37 días hábiles** (≈ 5.5 – 7.5 semanas) |

> **⚠️ Riesgo de deadline (crítico).** El PRD exige publicar el MVP en un máximo de **2-3 semanas** (≈10-15 días hábiles) desde la validación final, y **no admite desglose de funcionalidades priorizadas dentro de la fase** ("se entrega como un único entregable" — PRD §3.1): a diferencia de otros planes de Engine, aquí **no hay un recorte de alcance tipo P1/P2** disponible como guardarraíl.
>
> Con 1 desarrollador, el alcance completo (28 tareas) cae en ~5.5 – 7.5 semanas — muy por encima de la ventana comprometida. Para acercarse al plazo contractual se requiere **paralelizar con 2-3 desarrolladores** desde la Fase 0:
> - 1 dev en backend/CMS (Fases 0-2: content types, auth, carga masiva)
> - 1 dev en frontend (Fase 3, arrancando en paralelo contra un contrato de API mockeado desde el cierre de Fase 0)
> - 1 dev en integraciones (Fase 4: Seekop) — depende del cliente de Seekop de Fase 0 y del modelo de cotización de Fase 1
>
> Con 3 desarrolladores en paralelo, una compresión razonable (30-40%, consistente con la naturaleza secuencial de Fase 0 y con Fases 1/2/3 parcialmente paralelizables) deja el total en **~17 – 24 días hábiles (≈ 3.5 – 5 semanas)** — **sigue por encima de la ventana de 2-3 semanas**. Recomendación: escalar esta brecha a Go Virtual/NISSAN Perinorte **antes de comprometer fecha** con Valladolid, en vez de descubrirla a medio desarrollo. Esto es lo mismo que el propio PRD señala como riesgo en su §13 ("Definición tardía de flujos complementarios... puede detener el desarrollo y comprometer la ventana de 3 semanas"), pero aplicado al total del alcance, no solo a los flujos complementarios.

---

## 1. Resumen técnico

Portal B2B de dos caras: (a) un **portal de consulta y cotización** para los ejecutivos de sucursal de Valladolid (login individual, catálogo/precios/materiales, formulario de cotización con folio, envío a Seekop, WhatsApp), y (b) un **backoffice de administración** para que NISSAN Perinorte gestione usuarios, precios, materiales, contenido y reportes — sin depender de Go Virtual día a día.

**Componentes:**

1. **Backend/CMS (nuevo, repo propio, Strapi):** headless CMS/backend con content types para Catálogo, Precios/condiciones de flotilla, Materiales, Banners/contenido, Solicitud de cotización y Evento (BI); autenticación de ejecutivos vía el plugin **Users & Permissions** de Strapi (pensado exactamente para usuarios finales de un sitio, a diferencia del RBAC del Admin Panel); RBAC nativo del Admin Panel para el rol "Administrador NISSAN Perinorte" (backoffice); servicio custom de integración con Seekop; media library conectada a S3 para materiales protegidos.
2. **Portal (nuevo, repo propio, Next.js):** frontend del ejecutivo — home de la alianza, catálogo/precios/materiales (consumidos vía API autenticada), formulario de cotización, burbuja de WhatsApp, diseño responsivo.

**Arquitectura:** Frontend + Backend separados (patrón "Componentes" de Engine) — incluso siendo dos audiencias (ejecutivo vs. administrador), no amerita microservicios: dominio único, alcance acotado, plazo corto. El backoffice de NISSAN Perinorte **es el propio Admin Panel de Strapi** (no se construye una segunda UI de administración desde cero), salvo la vista de reportes agregados que sí requiere una pantalla/plugin custom.

**Stack — adoptado de `Autoexplora/PJ5040-cms-autoexplora` por instrucción explícita del project manager:**
- **Backend/CMS:** Strapi (Node.js) — **excepción justificada al default .NET Core 8** de Engine, igual que en PJ5040. A validar con el Gerente de TI si hace falta dejarla por escrito (mismo punto que PJ5040 §12.1).
- **BD:** PostgreSQL.
- **Almacenamiento:** Amazon S3 (materiales/brochures/banners/hero).
- **Frontend del portal:** Next.js (proyecto nuevo — no hay sitio existente que extender, a diferencia de PJ5040).
- **Despliegue:** propuesto EC2 (Ubuntu) + Nginx (reverse proxy) + systemd, igual que PJ5040 — **a confirmar con Go Virtual** porque, a diferencia de PJ5040, este proyecto sí tiene lógica de negocio con dependencias externas (Seekop) y ~100 sucursales concurrentes; si el volumen real (RNF-06, hoy sin cifra — PRD §14) resulta alto, Docker/ECS+Fargate (el default de Engine) da mejor camino de escalamiento horizontal que una sola instancia EC2.

---

## 2. Prerequisitos

- [ ] PRD v0.1 validado por el responsable (dispara la ventana de 2-3 semanas — PRD §13).
- [ ] **Repos nuevos creados**: `nissan-business-hub-api` y `nissan-business-hub-portal`, con acceso al equipo de desarrollo.
- [ ] **Bloqueante:** credenciales/documentación de la API de Seekop (endpoint, autenticación, contrato de "crear oportunidad") — condición para Fase 4 (T-21/T-22) y para cumplir RF-11 dentro del plazo.
- [ ] **Bloqueante:** decisión de autenticación — ¿base propia (Strapi Users & Permissions, asumido en este plan) o integración con SSO/directorio existente de NISSAN Perinorte/Valladolid? (PRD §14, "Integraciones"). Definirlo tarde implica retrabajo de Fase 2.
- [ ] Nivel de detalle de validación de carga masiva (T-15) y de manejo de errores complementarios (recuperación de contraseña, confirmaciones) — el cliente indicó que se resolverían en el arranque; el PRD recomienda cerrarlos **antes** de iniciar desarrollo (PRD §13).
- [ ] Prototipo de Figma de la identidad visual NISSAN–Valladolid (referencia para Fase 3).
- [ ] Contenido real (catálogo, precios, brochures, banners) de NISSAN Perinorte — el desarrollo puede avanzar con datos de prueba, pero la publicación real depende de esto.
- [ ] Definición de quién cubre QA y pruebas de seguridad del lado de Go Virtual (PRD §14).
- [ ] Confirmación de si Aldo Álvarez (u otra persona) hace la revisión técnica antes de iniciar diseño técnico (PRD §14).
- [ ] Instancia(s) EC2 (o decisión de ir a ECS/Fargate — ver §1) + PostgreSQL + bucket(s) S3, aprovisionados por el equipo de infraestructura.
- [ ] `CLAUDE.md` presente en ambos repos nuevos (ejecutar `/init` tras el scaffold).

---

## 3. Arquitectura del cambio

```
                                  ┌─────────────────────────────────────────┐
                                  │   Instancia EC2 (o ECS/Fargate)         │
   Ejecutivo (sucursal) ───────▶ │  ┌───────────────────────────────────┐   │
   Portal Next.js                │  │ Nginx (reverse proxy, TLS)       │   │
   (nissan-business-hub-portal)  │  └───────────────┬───────────────────┘   │
                                  │                  ▼                       │
                                  │  ┌───────────────────────────────────┐   │
   Admin NISSAN Perinorte ──────▶│  │ Strapi (nissan-business-hub-api) │   │
   Admin Panel (backoffice)      │  │ · Users & Permissions (Ejecutivo) │   │
                                  │  │ · Admin RBAC (Administrador)      │   │
                                  │  │ · Content types: Catalogo,        │   │
                                  │  │   PrecioCondicion, Material,      │   │
                                  │  │   Banner, SolicitudCotizacion,    │   │
                                  │  │   EventoBI                        │   │
                                  │  │ · Servicio SeekopIntegration      │   │
                                  │  └───────────────┬───────────────────┘   │
                                  │                  ▼                       │
                                  │  ┌───────────────────────────────────┐   │
                                  │  │ PostgreSQL                        │   │
                                  │  └───────────────────────────────────┘   │
                                  └───────────────────┬───────────────────────┘
                                                       ▼
                                            ┌─────────────────────┐
                                            │  Amazon S3           │
                                            │  (materiales/banners)│
                                            └──────────┬──────────┘
                                                       │
                                            ┌──────────▼──────────┐
                                            │  Seekop (externo)    │
                                            │  POST oportunidad    │
                                            └───────────────────────┘

                                  Enlace de navegación
                                  desde nissanperinorte.com.mx ──▶ Portal
```

**Formulario de cotización → Seekop (RF-09 a RF-11, RF-20):** al enviarse el formulario, se genera el folio y se persiste `SolicitudCotizacion` en estatus `Solicitada`; un servicio custom (`SeekopIntegrationService`) intenta la llamada a Seekop. Éxito → estatus `Enviada`, confirmación al ejecutivo. Falla → sigue el manejo en **3 pasos ya confirmado por el cliente (PRD §14)**: (1) reintento automático, (2) notificación interna a TI, (3) notificación al cliente/ejecutivo — implementado como un job programado (cron) que reprocesa `SolicitudCotizacion` en estatus `Error` con backoff, más un canal de notificación (correo/Slack, a definir con Go Virtual) para el paso 2 y un aviso visible en el portal para el paso 3.

**Burbuja de WhatsApp:** enlace `wa.me` construido 100% en el frontend con los datos de sesión del ejecutivo — sin integración de API ni dependencia del backend.

---

## 4. Tareas de desarrollo

### Fase 0 — Scaffold e infraestructura base

- [ ] **T-01** — Crear los repos `nissan-business-hub-api` y `nissan-business-hub-portal`, estructura de ramas Engine (`main`/`develop`/`pre-qa`/`qa`) y rama funcional `feature/nissan-business-hub-valladolid-mvp` en ambos.
  - Criterio: ambos repos accesibles al equipo, con la estructura de ramas lista.
- [ ] **T-02** — Provisionar infraestructura base: instancia(s) EC2 (o ECS/Fargate según decisión de §1), PostgreSQL, bucket(s) S3 para materiales/banners.
  - Criterio: infraestructura de QA disponible y accesible desde los repos.
- [ ] **T-03** — Scaffold de Strapi (TypeScript) en `nissan-business-hub-api`, conectado a PostgreSQL vía variables de entorno.
  - Criterio: `npm run develop` levanta el admin en local contra Postgres.
- [ ] **T-04** — Conectar Media Library a S3 (`@strapi/provider-upload-aws-s3`).
  - Criterio: una subida de prueba desde el admin queda almacenada en el bucket.
- [ ] **T-05** — Scaffold de Next.js en `nissan-business-hub-portal` con la identidad visual base (según prototipo de Figma) y `CLAUDE.md` en ambos repos (`/init`).
  - Criterio: proyecto Next.js corre en local con el layout base de la alianza NISSAN–Valladolid.

### Fase 1 — Catálogo, precios, materiales y contenido (RF-05 a RF-08, RF-16 a RF-18)

- [ ] **T-06** — Content type **Catálogo** (modelo, versión, características).
  - Criterio (RF-06): CRUD completo desde el Admin Panel; disponible para lectura pública autenticada vía API.
- [ ] **T-07** — Content type **Precio/condición de flotilla** (modelo, versión, precio, vigencia, condición especial), visible solo para usuarios autenticados.
  - Criterio (RF-07, RNF-01): la API rechaza lectura sin token de ejecutivo válido.
- [ ] **T-08** — Content type **Material** (tipo brochure/ficha técnica, archivo en S3, vehículo asociado), sin exposición vía enlace público.
  - Criterio (RF-08, RNF-01): descarga solo autenticada; sin URL pública directa al archivo.
- [ ] **T-09** — Content type **Banner/contenido** (home, avisos destacados, vigencia).
  - Criterio (RF-05, RF-18): el home consume banners activos vigentes.
- [ ] **T-10** — RBAC de backoffice: rol "Administrador NISSAN Perinorte" en el Admin Panel con permisos sobre Catálogo, Precio, Material y Banner (gestión completa).
  - Criterio (RNF-02): el rol administra estos content types sin acceso a configuración global de Strapi.

### Fase 2 — Autenticación y gestión de ejecutivos (RF-01 a RF-04, RF-15, RF-21, RNF-02)

- [ ] **T-11** — Configurar el plugin **Users & Permissions** para el rol "Ejecutivo", con campos custom: número de empleado, sucursal, correo, teléfono.
  - Criterio (RF-01, RF-02): el login devuelve JWT + los datos del ejecutivo, listos para adjuntarse a cada solicitud.
- [ ] **T-12** — Login individual + recuperación de contraseña autoservicio.
  - Criterio (RF-03): el ejecutivo dispara recuperación y recibe el flujo estándar de Strapi (correo con token).
- [ ] **T-13** — Activación/suspensión de cuentas desde el backoffice (Admin Panel).
  - Criterio (RF-04): un administrador activa/suspende una cuenta y el ejecutivo pierde/recupera acceso de inmediato.
- [ ] **T-14** — Alta individual y carga masiva de ejecutivos vía CSV/Excel.
  - Criterio (RF-15): un archivo válido crea/actualiza usuarios en lote, asociados a su sucursal.
- [ ] **T-15** — Validación y reporte de errores de la carga masiva.
  - **Supuesto a confirmar (PRD §14):** reporte a nivel fila + campo + motivo (sucursal inexistente, datos duplicados, formato inválido); ningún registro parcial se guarda si la fila falla.
  - Criterio (RF-21, RNF-07): la carga reporta éxitos/fallidos sin pérdida silenciosa; ver PRD §13 (riesgo de onboarding de ~100 sucursales).

### Fase 3 — Portal del ejecutivo — frontend (RF-05 a RF-08, RF-12, RF-13)

- [ ] **T-16** — Home de la alianza con identidad visual NISSAN–Valladolid.
  - Criterio (RF-05): coincide con el prototipo de Figma.
- [ ] **T-17** — Consumo de catálogo/precios/materiales protegidos vía API autenticada (fetch server-only, token nunca expuesto al navegador).
  - Criterio (RF-06 a RF-08, RNF-01): navegación funcional; materiales y precios solo visibles logueado.
- [ ] **T-18** — Diseño responsivo (escritorio, tablet, móvil).
  - Criterio (RF-13): experiencia funcional verificada en los tres tamaños.
- [ ] **T-19** — Burbuja de WhatsApp con mensaje prellenado (nombre, sucursal, vehículo de interés).
  - Criterio (RF-12): el enlace `wa.me` abre WhatsApp con el mensaje correcto desde cualquier pantalla.

### Fase 4 — Cotización y Seekop (RF-09 a RF-11, RF-20, RNF-03, RNF-07)

- [ ] **T-20** — Formulario de solicitud de cotización (modelo/versión de interés, datos del cliente referido) + generación de folio único.
  - Criterio (RF-09, RF-10): al enviar, se genera folio y se confirma recepción al ejecutivo de inmediato (independiente del resultado del envío a Seekop).
- [ ] **T-21** — Servicio `SeekopIntegrationService`: escritura de oportunidad con identificadores de origen (alianza, distribuidor, ejecutivo, sucursal, modelo/versión, fecha/hora).
  - Criterio (RF-11): una solicitud válida crea una oportunidad en Seekop (o en su ambiente de pruebas) con los identificadores correctos.
- [ ] **T-22** — Manejo de error en 3 pasos (reintento automático → notificación interna a TI → notificación al cliente/ejecutivo).
  - Criterio (RF-20, RNF-07): una falla simulada de Seekop dispara los 3 pasos sin perder la solicitud original.
- [ ] **T-23** — Endpoint de consulta de estatus de la solicitud + trazabilidad end-to-end (folio, ejecutivo, sucursal, fecha/hora, estatus).
  - Criterio (RNF-03): el estatus de cualquier solicitud es consultable por folio.

### Fase 5 — Analítica y reportes (RF-14, RF-19, sección 11 del PRD)

- [ ] **T-24** — Registro de eventos de BI: `usuario_login`, `usuario_login_fallido`, `password_recuperacion_solicitada`, `catalogo_consultado`, `precio_consultado`, `material_descargado`, `cotizacion_solicitada`, `cotizacion_enviada_seekop`, `cotizacion_error_seekop`, `whatsapp_contacto_iniciado`, `usuario_alta_backoffice`, `carga_masiva_procesada`, `contenido_actualizado`.
  - Criterio (RF-14, PRD §11): cada evento se registra con fecha/hora, identificador del actor, sucursal (si aplica) y resultado/motivo cuando represente un intento.
- [ ] **T-25** — Reportes de actividad y solicitudes en el backoffice (consulta + exportación).
  - Criterio (RF-19): un administrador exporta reportes filtrados por sucursal/ejecutivo/rango de fechas.

### Fase 6 — Pruebas, seguridad, observabilidad y despliegue

- [ ] **T-26** — Matriz de pruebas funcionales end-to-end: login exitoso/fallido, recuperación de contraseña, cotización con Seekop disponible/caído, carga masiva con y sin errores, WhatsApp, permisos cruzados entre sucursales.
  - Criterio: los escenarios documentados con evidencia en la carpeta del PRD.
- [ ] **T-27** — Observabilidad y manejo de errores generales (logs de solicitudes fallidas, logins fallidos, cargas masivas con error).
  - Criterio (RNF-07, RNF-08): los tres tipos de fallo quedan auditables sin pérdida silenciosa.
- [ ] **T-28** — Despliegue a producción (infraestructura de §1/§9), verificación de disponibilidad 24/7 y monitoreo de facturación AWS.
  - Criterio (RNF-04): el portal y el backoffice están disponibles 24/7; alertas de facturación configuradas.

---

## 5. Modelo de datos (content types)

Strapi genera y gestiona el esquema PostgreSQL automáticamente a partir de los content types.

| Content type | Tipo | Campos principales |
|---|---|---|
| `up_users` (extendido) | Nativo + custom | Ejecutivo: nombre, email, password, número de empleado, sucursal, teléfono, estatus (activo/suspendido) |
| `catalogo` | Nuevo | Modelo, versión, características |
| `precio_condicion` | Nuevo | Modelo, versión, precio, vigencia, condición especial de flotilla |
| `material` | Nuevo | Tipo (brochure/ficha técnica), archivo (S3), vehículo asociado |
| `banner` | Nuevo | Imagen/contenido, vigencia, orden |
| `solicitud_cotizacion` | Nuevo | Folio, ejecutivo (relación), sucursal, modelo/versión, fecha/hora, estatus (`Solicitada`/`Enviada`/`Error`), payload de envío/respuesta a Seekop |
| `evento_bi` | Nuevo | Tipo de evento, actor, sucursal, identificador de negocio (folio/modelo/material), resultado/motivo, fecha/hora |

---

## 6. Endpoints / contratos principales

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/local` | Login de ejecutivo (Users & Permissions) |
| POST | `/api/auth/forgot-password` / `/api/auth/reset-password` | Recuperación de contraseña |
| GET | `/api/catalogos` | Catálogo de vehículos (autenticado) |
| GET | `/api/precio-condicions` | Precios y condiciones de flotilla (autenticado) |
| GET | `/api/materials` | Biblioteca de materiales (autenticado, sin URL pública directa) |
| GET | `/api/banners` | Banners activos del home |
| POST | `/api/solicitud-cotizacions` | Alta de solicitud de cotización + disparo de folio y envío a Seekop |
| GET | `/api/solicitud-cotizacions/:folio` | Consulta de estatus por folio |
| POST | `/api/ejecutivos/carga-masiva` (custom) | Carga masiva CSV/Excel de ejecutivos, con reporte de errores |
| GET | `/api/reportes/actividad` (custom) | Reporte agregado de actividad/solicitudes para backoffice |

El portal nunca expone el token de Strapi al navegador: los fetch de lectura corren server-side (patrón proxy).

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `DATABASE_URL` / `DATABASE_*` | Conexión PostgreSQL | Dev / QA / Prod |
| `APP_KEYS`, `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, `JWT_SECRET`, `TRANSFER_TOKEN_SALT` | Secrets core de Strapi | Dev / QA / Prod |
| `AWS_ACCESS_KEY_ID`, `AWS_ACCESS_SECRET`, `AWS_REGION`, `AWS_BUCKET` | Provider S3 de materiales/banners | Dev / QA / Prod |
| `SEEKOP_API_URL`, `SEEKOP_API_KEY` (o esquema de auth que confirme Seekop) | Integración de escritura de oportunidad | QA / Prod |
| `SEEKOP_RETRY_MAX_ATTEMPTS`, `SEEKOP_RETRY_BACKOFF_SECONDS` | Parámetros del reintento automático (paso 1 de RF-20) | QA / Prod |
| `SEEKOP_TI_NOTIFICATION_CHANNEL` | Canal de notificación interna (paso 2 de RF-20) — a definir con Go Virtual (correo/Slack) | QA / Prod |
| `STRAPI_API_URL` (en el portal) | Base URL de la API | Dev / Prod |
| `STRAPI_API_TOKEN` (en el portal, server-only) | Token de lectura del portal hacia Strapi | Dev / Prod |
| `WHATSAPP_DEFAULT_NUMBER` | Número destino de la burbuja de WhatsApp | Dev / Prod |

> Todos los secrets viven en variables de entorno / AWS Secrets Manager. Nunca en el código.

---

## 8. Consideraciones de seguridad

- **RNF-01 / RNF-02:** separación estricta entre rol Ejecutivo (lectura + creación de solicitudes, sin acceso cruzado entre sucursales) y rol Administrador (gestión completa vía Admin Panel). Materiales y precios sin exposición vía enlace público.
- **Autenticación:** JWT de Strapi (Users & Permissions) para ejecutivos; RBAC nativo del Admin Panel para administradores. Sin autoservicio de altas de ejecutivo (solo backoffice).
- **Datos personales (RNF-05):** el sistema maneja datos de ejecutivos y de clientes referidos; los requerimientos regulatorios/de política interna específicos siguen pendientes de definir (PRD §14) — **no cerrar el diseño de retención/consentimiento sin esa respuesta**.
- **Integración con Seekop:** credenciales en Secrets Manager; payload de envío/respuesta persistido sin exponer datos sensibles innecesarios en logs.
- **Token del portal → Strapi:** solo server-side, nunca expuesto al navegador.
- **Auditoría (RNF-03, RNF-08):** trazabilidad de solicitudes, logins fallidos y cargas masivas con error, vía `evento_bi` + logs.

---

## 9. Consideraciones de infraestructura

- **Cómputo:** propuesto EC2 + Nginx + systemd (igual que PJ5040); **a confirmar** contra Docker/ECS+Fargate (default de Engine) si el volumen real de las ~100 sucursales (RNF-06, cifra aún pendiente — PRD §14) exige escalamiento horizontal.
- **BD:** PostgreSQL — si se sigue el patrón EC2 de PJ5040 (instancia local, sin RDS), backups (`pg_dump` periódico) quedan a cargo del equipo; alternativa más robusta es RDS gestionado, a decidir con infraestructura.
- **S3:** bucket(s) para materiales/brochures/banners, con bucket policy y CORS configurados desde el inicio (evitar el retrabajo que tuvo PJ5040 en este punto).
- **Disponibilidad 24/7 (RNF-04, ya confirmada):** requiere `systemctl enable` (o equivalente en ECS) para arranque automático y monitoreo de salud.
- **Dominio:** el portal se referencia como sección/enlace desde `nissanperinorte.com.mx` (PRD §10) — coordinar subdominio/URL estable antes de Fase 3.
- **Monitoreo de facturación AWS:** obligatorio desde el día uno (AWS no tiene tope automático de gasto).

---

## 10. Criterios de aceptación

- [ ] Un ejecutivo se autentica con usuario/contraseña individual y el sistema reconoce automáticamente sus datos (RF-01/RF-02).
- [ ] El ejecutivo navega catálogo, precios y materiales solo estando autenticado (RF-06 a RF-08, RNF-01).
- [ ] El formulario de cotización genera folio y confirma recepción, independientemente del resultado del envío a Seekop (RF-09/RF-10).
- [ ] Una solicitud se envía a Seekop con los identificadores de origen correctos (RF-11).
- [ ] Una falla de Seekop dispara los 3 pasos de manejo de error sin perder la solicitud (RF-20).
- [ ] La burbuja de WhatsApp abre con el mensaje prellenado correcto (RF-12).
- [ ] El portal es funcional en escritorio, tablet y móvil (RF-13).
- [ ] El backoffice permite alta individual y carga masiva de ejecutivos, con reporte de errores (RF-15/RF-21).
- [ ] El backoffice gestiona precios, materiales, contenido y reportes sin intervención de Go Virtual (RF-16 a RF-19).
- [ ] Los eventos de BI de la sección 11 del PRD se registran correctamente (RF-14).
- [ ] El portal y el backoffice están disponibles 24/7 (RNF-04).
- [ ] Ningún material ni precio especial es accesible sin autenticación, ni vía enlace directo (RNF-01).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Deadline de 2-3 semanas vs. ~5.5-7.5 semanas de alcance con 1 dev** (ver §0) | Alta | Alto | Escalar la brecha a Go Virtual/NISSAN antes de comprometer fecha; evaluar paralelización con 2-3 desarrolladores |
| Mecanismo de autenticación aún sin definir (propia vs. SSO/directorio existente) | Alta | Alto | Este plan asume Strapi Users & Permissions (base propia); confirmar antes de iniciar Fase 2 para evitar retrabajo |
| Disponibilidad/documentación de la API de Seekop | Alta | Alto | Cerrar T-01 (prerequisito) antes de comenzar Fase 4; sin esto, Fase 4 no puede arrancar |
| Nivel de detalle de validación de carga masiva sin definir | Media | Medio | Este plan asume reporte fila+campo+motivo; confirmar con negocio antes de T-15 |
| Volumen real de usuarios concurrentes sin cifra ("los mismos de DO", PRD §14) | Media | Medio | Obtener la cifra real de Go Virtual antes de decidir EC2 vs. ECS/Fargate (§9) |
| Requerimientos regulatorios de datos personales sin definir (RNF-05) | Media | Alto | No cerrar diseño de retención/consentimiento sin la respuesta; podría requerir cambios post-MVP si llega tarde |
| Entrega tardía de contenido real (catálogo, precios, brochures, banners) | Media | Medio | Desarrollo avanza con datos de prueba; publicación real depende de contenido definitivo a tiempo |
| Onboarding de ~100 sucursales con datos incorrectos de ejecutivos | Media | Alto | Validación de carga masiva (T-15) antes del día de publicación; datos de prueba en QA primero |
| Excepción de stack (Strapi sobre .NET Core 8 default) sin registrar formalmente | Baja | Bajo | Documentar la decisión con el Gerente de TI, igual que se hizo en PJ5040 |

---

## 12. Notas para el programador

1. **Stack heredado de PJ5040 por instrucción directa del project manager**, no por default de Engine — ver §1. Si Strapi resulta insuficiente para la lógica de Seekop/carga masiva (más compleja que el CMS de Autoexplora), la alternativa de respaldo es moverla a un servicio custom aparte que consuma Strapi solo como fuente de contenido — evaluarlo en Fase 0 antes de comprometerse.
2. **El backoffice de NISSAN Perinorte es el Admin Panel de Strapi**, no una segunda aplicación frontend — reduce alcance de forma importante frente a construir un backoffice a medida. La única pieza que probablemente necesite una vista custom es el reporte agregado (T-25), porque cruza varios content types.
3. **Two-audience auth:** el rol "Ejecutivo" usa el plugin Users & Permissions (pensado para usuarios finales); el rol "Administrador NISSAN Perinorte" usa el RBAC nativo del Admin Panel. Son mecanismos distintos de Strapi — no confundirlos (mismo matiz que PJ5040 identificó en su T-06).
4. **Seekop es la dependencia crítica de la Fase 4.** Sin su documentación, T-21 y T-22 no pueden empezar en serio — tratar como bloqueante real, no como riesgo abstracto.
5. **El PRD no permite recortar alcance dentro del MVP** (a diferencia de otros PRDs de Engine con P1/P2/P3): cualquier ajuste de alcance para cumplir el deadline requiere renegociar el PRD mismo con el cliente, no es una decisión que el plan de desarrollo pueda tomar unilateralmente.
6. **Decisión de infraestructura (EC2 vs. ECS/Fargate) pendiente de confirmar** — este plan usa EC2 por continuidad con PJ5040, pero el contexto (integraciones externas, más usuarios concurrentes) es distinto al de un CMS de contenido; no asumir que la misma decisión aplica sin revisarla.

---

*Generado por Claude Code — Engine CX*
*Basado en: `NISSAN/business-hub-valladolid/PRD.md` (v0.1) y el precedente técnico de `Autoexplora/PJ5040-cms-autoexplora/PLAN.md`*
