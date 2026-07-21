# Registro de Avance — CMS Autoexplora (Strapi)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `autoexplora-cms` — `git@github.com:Sitios-Web-Go-Virtual/autoexplora-cms.git` (CMS) y `autoexplora-alfa` — `git@github.com:Sitios-Web-Go-Virtual/autoexplora-alfa.git` (sitio, desde T-11) |
| Rama | `feature/PJ5040-cms-autoexplora-mvp` en ambos repos (en `autoexplora-alfa`, creada desde `dev`) |
| Responsable actual | Sharon Mendoza |
| Última actualización | 2026-07-20 |
| Modelo de ejecución | claude-sonnet-5 — esfuerzo: máximo |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

**Fase 0 completada. Fase 1 (P1) completa: T-06 a T-12.** CMS (`autoexplora-cms`) con Postgres local, S3 con lectura/escritura/CORS/CSP verificados, rol Editor acotado a Banner, content type Banner (Dynamic Zone imagen/video, desktop+mobile), validación de archivos, reordenamiento automático por vigencia, publicación en dos etapas con webhook, y registro de auditoría (create/update/publish/unpublish, verificado en vivo con usuario real). El sitio (`autoexplora-alfa`) ya consume banners reales del CMS desde T-11. Despliegue del CMS: EC2 + Nginx + systemd (sin Docker), instancia aún no aprovisionada (solicitada a Alexis, 2026-07-20). **Guardarraíl del PRD:** con P1 completo, el compromiso mínimo del 31 jul ya está cubierto; P2 (blog) y P3 (textos) son las siguientes si el tiempo lo permite. Siguiente paso: T-13 (content type Article, P2) o cerrar Fase 1 aquí según tiempo disponible.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Scaffold de Strapi con TypeScript | Claude Code | 2026-07-16 | Verificado: `npm run develop` levanta el admin contra Postgres local |
| T-02 | Configurar Strapi con PostgreSQL (dev local + Postgres local en EC2 para qa/prod) | Claude Code | 2026-07-16 | Postgres local vía Postgres.app (sin Homebrew); qa/prod 100% por env vars/Secrets Manager, sin hardcode |
| T-03 | Conectar Media Library a S3 | Claude Code | 2026-07-17 | ✅ Completamente verificado, incluyendo lectura pública. Subida real confirmada en `govirtual-autoexplora-cms-qa`. Fix de subida: `config/plugins.ts` necesita `ACL: undefined` explícito (bucket con ACLs deshabilitadas, "Bucket owner enforced"). Lectura pública requirió **dos pasos** en AWS (aplicados por Alexis Herrera, 2026-07-17): (1) bucket policy de `s3:GetObject` público, (2) destildar las 2 opciones de "Block Public Access" relacionadas a bucket policies. Verificado con `curl` → `200 OK` sobre la URL directa del objeto. |
| T-04 | Ejecutar `/init` en el repo del CMS | Claude Code | 2026-07-16 | `CLAUDE.md` generado con stack, comandos y arquitectura |
| T-05 | Nginx + systemd para despliegue en EC2 *(rehecha 2026-07-17)* | Claude Code | 2026-07-16 → 2026-07-17 | Versión original (Dockerfile + ECS/Fargate, verificada con Docker Desktop) **retirada** por decisión de infraestructura del programador. Versión actual: `deploy/nginx.conf`, `deploy/strapi.service`, `deploy/README.md` — no verificable hasta que exista la instancia EC2 real (la crea el equipo de infraestructura) |
| T-06 | Autenticación y rol único "editor" | Claude Code | 2026-07-17 | Corrección de alcance sobre el plan: el mecanismo correcto es el RBAC nativo del Admin Panel (rol "Editor" de fábrica), no el plugin Users & Permissions (ese es para usuarios finales de un sitio público). Permisos otorgados por bootstrap idempotente (`src/bootstrap/ensureEditorPermissions.ts`). Verificado en BD: solo Banner + Media Library, sin Settings/Users/Roles |
| T-07 | Content type Banner | Claude Code | 2026-07-17 | Rediseñado durante pruebas manuales (ver Decisiones): Dynamic Zone con componentes Imagen/Video, desktop+mobile en ambos, sin campo `sección` ni `altText` propio. CRUD y Draft & Publish verificados por el programador en el admin |
| T-08 | Validación de formato y peso de archivos | Claude Code | 2026-07-20 | Alcance reducido: póster obligatorio ya resuelto en T-07 (schema), esta tarea solo valida formato/peso. Implementado como hook global (`strapi.db.lifecycles.subscribe` sobre `plugin::upload.file`) — aplica a todo el CMS, no solo Banner. Verificado: 8 casos unitarios en los límites exactos + prueba manual en el admin |
| T-09 | Reordenamiento automático de banners por vigencia | Claude Code | 2026-07-20 | Dos disparadores: cron cada 5 min (respaldo pasivo) + hook reactivo en afterCreate/afterUpdate (inmediato, con guardia anti-reentrancia). Banner expirado se despublica vía Document Service (`unpublish`), preservando el borrador (reversible). Verificado con script standalone: el hook reactivo recompactó automáticamente al crear los datos de prueba, antes de la llamada manual |
| T-10 | Publicación en dos etapas (API + webhook) | Claude Code | 2026-07-20 | **Hallazgo:** el plan decía `publicationState` (sintaxis Strapi v4) — corregido a `status=draft\|published` (Strapi v5), verificado empíricamente con token real. Webhook registrado por código (idempotente), verificado end-to-end con receptor HTTP local: `entry.publish`/`entry.unpublish` llegaron con el secreto correcto al publicar/despublicar un banner real |
| T-11 | Integración mínima en el sitio `autoexplora-alfa` | Claude Code | 2026-07-20 | Primer cambio de código en `autoexplora-alfa` (rama `feature/PJ5040-cms-autoexplora-mvp` creada desde `dev`). Fetch server-only (`lib/server/strapiApi.ts`) invocado directo desde `app/page.tsx` (Server Component) — sin ruta `/api/*` intermedia, decisión deliberada para no construir el endpoint de revalidación instantánea todavía (ISR de 2 min es suficiente por ahora). `HomeCarousel.tsx` pasó de array hardcodeado a prop `slides`; de paso se corrigió el LCP (estaba fijo al índice 2, debe ser el 0). Token de solo lectura para el sitio, verificado con `POST → 403`. Verificado en navegador: borrador visible, vacío sin error, publicado visible |
| T-12 | Registro de auditoría | Claude Code | 2026-07-20 | Content type `AuditLog` sin Draft & Publish. Implementado con `strapi.documents.use()` (no un hook de BD genérico) para distinguir sin ambigüedad create/update/publish/unpublish — internamente publicar es un delete+create que un hook de BD no puede diferenciar de forma confiable de una edición. Usuario obtenido de `strapi.requestContext.get().state.user`. Escritura del log en try/catch, nunca bloquea la acción real. **Verificado en vivo: las 4 acciones sobre un banner real quedaron registradas con el usuario correcto. Completa el alcance P1 del MVP (T-06 a T-12).** |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| | | | | |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-13 | Content type Article (P2) | |
| T-14 | Editor de texto enriquecido con embeds (P2) | |
| T-15 | Consumo de blog en el sitio (P2) | |
| T-16 | Content type StaticText (P3) | |
| T-17 | Consumo de textos estáticos en el sitio (P3) | |
| T-18 | Manejo de errores y observabilidad | |
| T-19 | Despliegue final y monitoreo de facturación | |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-05 (verificación real) | Verificar `deploy/nginx.conf` + `deploy/strapi.service` en una instancia real | La instancia EC2 no existe aún | Alexis Herrera — solicitud de aprovisionamiento enviada 2026-07-20 (specs: Ubuntu, puertos 80/443/22, Postgres solo local; pendiente confirmar consola AWS, qa/prod separadas o compartidas, y dominio) |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Commit inicial de bootstrap directo en `main` (README + `.gitignore`) | El repo se creó completamente vacío; no puede existir `develop`/`pre-qa`/`qa` sin al menos un commit del que derivarlas. Es la única excepción a la regla de "nunca commits directos a main". | Ninguno — `main` queda con solo el bootstrap; todo el desarrollo real ocurre en la rama funcional. |
| Modelo de ejecución: Sonnet 5 (no Opus) | El workflow `ejecutar-plan.md` especifica siempre modelo Sonnet para la fase de ejecución (Opus es solo para generar el plan). Confirmado con el programador. | Ninguno funcional; solo trazabilidad de qué modelo generó el código. |
| PostgreSQL local vía Postgres.app (no Homebrew/Docker) | La máquina no tenía Homebrew, Docker ni Postgres instalados. Postgres.app no requiere permisos de administrador; se inicializó y arrancó el servidor por línea de comandos (`initdb`/`pg_ctl`) sin abrir la GUI. | Desarrollo local requiere que el desarrollador arranque el servidor manualmente (`pg_ctl start`) — no es un servicio del sistema. Documentar en onboarding si otro compañero retoma. |
| Scaffold de Strapi generado en carpeta temporal y movido al repo | `create-strapi-app` exige un directorio vacío; el repo ya tenía `.git`, `.gitignore` y `README.md` del bootstrap. Se generó en `/tmp` y se fusionó preservando `.git` y el README del proyecto. | Ninguno — resultado final idéntico a un scaffold directo. |
| Docker Desktop instalado por el programador durante la ejecución | No había runtime Docker disponible al iniciar T-05; el programador lo instaló para poder verificar el Dockerfile localmente en vez de dejarlo como bloqueo. | T-05 quedó verificado (build + run + health check) en vez de solo documentado. |
| S3 (T-03): código completo, verificación real diferida | No existe aún bucket S3 ni usuario IAM dedicado. Se decidió no usar credenciales personales/admin del programador (regla de mínimo privilegio de `infraestructura.md`) — se solicitará un usuario IAM dedicado con permisos acotados al bucket. | La tarea T-03 se considera completa en código; la subida de prueba real queda como tarea bloqueada explícita (ver arriba), no como pendiente silenciosa. |
| **Cambio de arquitectura de despliegue: EC2+Nginx+systemd en vez de Docker/ECS+Fargate** | El programador confirmó (2026-07-17) que se usará una instancia EC2 con Nginx y PostgreSQL local, sin Docker. Es una excepción explícita a los defaults de Engine (`infraestructura.md`: "ECS+Fargate para todos los nuevos desarrollos"; `arquitectura.md` marca el patrón app+BD en una sola instancia como monolítico, no recomendado para proyectos nuevos). Aceptada como decisión de infraestructura del cliente. | Se retiró el trabajo de T-05 basado en Docker (ya commiteado y verificado) y se rehizo con Nginx/systemd. Ver riesgo nuevo en `PLAN.md` §11 (app+BD en la misma instancia, sin RDS → backups manuales). |
| **PostgreSQL sin RDS: backups manuales** | Consecuencia directa de correr Postgres en la misma EC2 que la app. AWS no gestiona backups/HA en este esquema. | Documentado en `deploy/README.md` §3: mínimo, `pg_dump` programado. Pendiente de implementar cuando exista la instancia. |
| **Un solo usuario IAM con acceso a ambos buckets S3 (prod y qa)** | El programador confirmó que las credenciales entregadas son de un usuario con acceso a los dos buckets, no separado por ambiente. | Riesgo aceptado y documentado (`PLAN.md` §11); no bloquea el desarrollo. Recomendable separar en el futuro. |
| **`ACL: undefined` explícito en `config/plugins.ts`** | El bucket usa "Bucket owner enforced" (ACLs deshabilitadas, default de S3 desde abril 2023). El provider de Strapi intenta mandar `ACL: public-read` salvo que se le indique lo contrario, y S3 rechaza cualquier header de ACL en estos buckets con `AccessControlListNotSupported`. | La subida a S3 ahora funciona (verificado). Como efecto secundario, `isPrivate()` del provider (que depende de `ACL === 'private'`) nunca puede ser `true` en este tipo de bucket — el control de acceso público/privado queda 100% en manos de la bucket policy, no de Strapi. |
| **Modelo de publicación confirmado: Draft & Publish + webhook** | El programador confirmó (2026-07-17) la recomendación ya documentada en `PLAN.md` §3, cerrando la pregunta abierta del PRD §13. | Desbloquea T-10 sin necesidad de validación adicional del equipo. |
| **Rama base del sitio confirmada: `dev`** | El programador confirmó (2026-07-17) que, como `autoexplora-alfa` no tiene `develop`, los cambios de integración (T-11, T-15, T-17) se basan en `dev` — excepción al flujo estándar de Engine, ya documentada en `PLAN.md` §12. | Desbloquea T-11 sin necesidad de validación adicional del equipo del sitio. |
| **T-06: RBAC nativo del Admin Panel en vez del plugin Users & Permissions** | El plan original decía "plugin Users & Permissions", pero ese plugin es para autenticación de usuarios finales de un sitio público — no aplica a quien entra al admin de Strapi. El sistema correcto es el RBAC nativo (Settings > Roles), usando el rol "Editor" que Strapi trae de fábrica. | Corrección de alcance sin impacto en el criterio de aceptación (login de editor con permisos acotados) — solo cambia el mecanismo técnico. |
| **T-07: Banner rediseñado con Dynamic Zone (Imagen/Video) tras prueba manual** | Al probar el formulario, el programador identificó 3 problemas de producto: (1) el campo "sección" era redundante (un solo carrusel en home, no multi-sitio); (2) el póster aparecía aunque no se hubiera elegido tipo de media, sin flujo progresivo; (3) faltaba soporte de versiones desktop/mobile separadas. Se resolvió con una Dynamic Zone de dos Componentes (Imagen/Video), cada uno con sus propios campos desktop/mobile — logra la UX progresiva pedida usando UI nativa de Strapi, sin construir un formulario custom (que sí hubiera arriesgado el deadline). | Cambia el modelo de datos de Banner respecto al PRD original (RF-03 decía "por sección"); documentado como decisión de producto del programador. Bonus: el póster obligatorio en video (RF-04) ahora se cumple nativamente vía `required: true` en el componente, sin necesitar lifecycle hook para esa parte — T-08 se reduce a validar formato/peso de archivo. |
| **`altText` propio eliminado de los componentes de Banner** | El programador notó que Strapi ya provee "texto alternativo" nativo por archivo en la Media Library — el campo custom era redundante. | Ninguno — simplificación, sin pérdida de funcionalidad. |
| **Bucket policy de lectura pública aplicada (Alexis Herrera, 2026-07-17)** | Tras la bucket policy inicial, seguía dando `403` porque nunca se había guardado ninguna policy (confirmado con "No hay ninguna política que mostrar" en la consola). Se le compartió el JSON exacto de policy pública (`s3:GetObject`) para ambos buckets; tras aplicarla, verificado con `curl` → `200 OK`. | T-03 queda 100% cerrado, incluyendo lectura pública — ya no hay bloqueo pendiente de S3. |
| **T-08: validación como hook global, no por content type** | RF-11 describe la validación de formato/peso como aplicable a "cada subida", no específica de Banner. Se implementó vía `strapi.db.lifecycles.subscribe` sobre `plugin::upload.file` en vez de un lifecycle propio de Banner. | Cubre automáticamente Article (T-13) y StaticText (T-16) sin duplicar lógica cuando se construyan esos content types. |
| ✅ **CORS resuelto en ambos buckets S3 (Alexis Herrera, 2026-07-20)** | Al probar T-08 no se veían las miniaturas en la Media Library aunque las URLs eran públicas. Se diagnosticó falta de configuración CORS y se compartió el JSON a Alexis. Aplicado y verificado el mismo día: `GET` con header `Origin` devuelve `Access-Control-Allow-Origin: *` en `govirtual-autoexplora-cms-qa` y `-prod`. | Necesario pero **no suficiente** — ver siguiente hallazgo. Nota técnica: verificar CORS con `curl -I` (HEAD) da falso negativo — S3 solo devuelve el header en `GET`/`OPTIONS` reales, no en `HEAD`. |
| ✅ **Causa real de las miniaturas rotas: Content Security Policy de Strapi, no CORS** | Tras el fix de CORS, las miniaturas seguían rotas. La consola del navegador mostró el error real: `img-src`/`media-src 'self' data: blob:` bloqueaba cualquier carga desde el bucket S3 — es el CSP por default de Strapi (middleware `strapi::security`), no un problema de AWS. Se corrigió en `config/middlewares.ts`, agregando ambos hosts S3 (qa y prod) a `img-src`/`media-src`. | T-03 (miniaturas) queda 100% cerrado — verificado visualmente por el programador tras el fix. CORS y CSP eran ajustes **complementarios**, ambos necesarios; no hay que revertir el de CORS. |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `README.md`, `.gitignore` | Modificado (bootstrap fusionado con scaffold) | T-01 |
| `package.json`, `package-lock.json`, `tsconfig.json`, `favicon.png` | Creado | T-01 |
| `config/database.ts`, `config/server.ts` | Creado | T-01/T-02 |
| `config/admin.ts`, `config/api.ts`, `config/middlewares.ts` | Creado | T-01 |
| `config/plugins.ts` | Creado, luego modificado (`ACL: undefined` — fix de subida) | T-03 |
| `.env.example` | Creado (vars de BD y S3) | T-02/T-03 |
| `src/`, `database/migrations/.gitkeep`, `public/`, `types/` | Creado | T-01 |
| `CLAUDE.md` | Creado, luego modificado (sección Deployment) | T-04 / rework T-05 |
| `Dockerfile`, `.dockerignore`, `deploy/task-definition.json` | Creado y luego **eliminado** (cambio de arquitectura) | T-05 → rework |
| `deploy/nginx.conf`, `deploy/strapi.service` | Creado | Rework T-05 |
| `deploy/README.md` | Creado, luego reescrito (EC2 en vez de ECS) | T-05 → rework |
| `.env.example` | Modificado (buckets S3 reales) | Rework T-05 |
| `src/api/banner/` (schema, controller, service, routes) | Creado | T-07 |
| `src/components/banner/image-content.json`, `video-content.json` | Creado, luego modificado (se quitó `altText`) | T-07 |
| `src/bootstrap/ensureEditorPermissions.ts` | Creado (idempotente, con auto-actualización de campos) | T-06 |
| `src/index.ts` | Modificado (conecta el bootstrap, luego el hook de validación) | T-06 / T-08 |
| `src/lifecycles/validateUploadedFiles.ts` | Creado | T-08 |
| `src/api/banner/services/reorder.ts` | Creado | T-09 |
| `config/cron-tasks.ts` | Creado | T-09 |
| `src/lifecycles/recompactBannersOnChange.ts` | Creado | T-09 |
| `config/server.ts` | Modificado (cron habilitado) | T-09 |
| `src/bootstrap/ensurePublicationWebhook.ts` | Creado | T-10 |
| `config/custom.ts` | Creado (`SITE_REVALIDATE_WEBHOOK_URL`/`PREVIEW_WEBHOOK_SECRET`) | T-10 |
| `config/middlewares.ts` | Modificado (CSP: hosts S3 en `img-src`/`media-src`) | T-03 (fix) |
| **`autoexplora-alfa`**: `lib/server/strapiApi.ts` | Creado | T-11 |
| **`autoexplora-alfa`**: `app/page.tsx` | Modificado (fetch server-side de banners) | T-11 |
| **`autoexplora-alfa`**: `app/components/HomeCarousel.tsx` | Modificado (array hardcodeado → prop `slides`; fix LCP) | T-11 |
| **`autoexplora-alfa`**: `next.config.ts` | Modificado (hosts S3 del CMS en `remotePatterns`) | T-11 |
| **`autoexplora-alfa`**: `.env.example`/`.env` | Modificado (`STRAPI_API_URL`/`STRAPI_API_TOKEN`/`STRAPI_PUBLICATION_STATUS`) | T-11 |
| `src/api/audit-log/` (schema, controller, service, routes) | Creado | T-12 |
| `src/lifecycles/auditLog.ts` | Creado | T-12 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `4d30ad1` | Inicializar repositorio autoexplora-cms | 2026-07-16 |
| `b50a92e` | [cms-autoexplora] Fase 0 - Scaffold e infraestructura base | 2026-07-16 |
| `b44d14a` | [cms-autoexplora] Rehacer T-05 - Despliegue EC2 + Nginx + systemd (sin Docker) | 2026-07-17 |
| `c2131e2` (enginecx_prd) | cms-autoexplora Actualizar plan - Despliegue EC2 + Nginx + systemd | 2026-07-17 |
| `1b950ad` | [cms-autoexplora] Fix T-03 - Deshabilitar ACL en provider S3 | 2026-07-17 |
| `d209e3d` (enginecx_prd) | cms-autoexplora Actualizar avance y plan - T-03 verificado, bloqueo bucket policy | 2026-07-17 |
| `a9a759f` (enginecx_prd) | cms-autoexplora Confirmar modelo de publicación y rama base del sitio | 2026-07-17 |
| `18f22ad` | [cms-autoexplora] Fase 1 - T-06/T-07: rol Editor + content type Banner | 2026-07-17 |
| `281b6cb` | [cms-autoexplora] Fase 1 - T-08: validación de formato y peso de archivos | 2026-07-20 |
| `0fb79c5` (enginecx_prd) | cms-autoexplora Actualizar plan y avance - T-08 completada, hallazgo CORS S3 | 2026-07-20 |
| `8f352bb` | [cms-autoexplora] Fase 1 - T-09: reordenamiento automático de banners por vigencia | 2026-07-20 |
| `1e1a6a9` (enginecx_prd) | cms-autoexplora Actualizar plan y avance - T-09 completada | 2026-07-20 |
| `cd78590` | [cms-autoexplora] Fase 1 - T-10: publicación en dos etapas (contrato de API + webhook) | 2026-07-20 |
| `d1990e9` (enginecx_prd) | cms-autoexplora Actualizar plan y avance - T-10 completada, corrección de API v5 | 2026-07-20 |
| `414dddb` (enginecx_prd) | cms-autoexplora Registrar solicitud de aprovisionamiento EC2 a Alexis | 2026-07-20 |
| `c3337d6` (enginecx_prd) | cms-autoexplora Cerrar T-03 - CORS + CSP resueltos, miniaturas visibles | 2026-07-20 |
| `ea1c177` | [cms-autoexplora] Fix T-03 - Permitir buckets S3 en Content Security Policy | 2026-07-20 |
| `2fad324` (autoexplora-alfa) | [cms-autoexplora] Fase 1 - T-11: consumir banners del CMS en el home | 2026-07-20 |
| `ff1ad66` (enginecx_prd) | cms-autoexplora Actualizar plan y avance - T-11 completada | 2026-07-20 |
| `f2da662` | [cms-autoexplora] Fase 1 - T-12: registro de auditoría (completa P1) | 2026-07-20 |

---

## Notas para quien retome el trabajo

- El repo `autoexplora-cms` vive en `~/Documents/BRICK-sites/autoexplora-cms` localmente (hermano de `autoexplora-alfa`).
- Rama activa: `feature/PJ5040-cms-autoexplora-mvp`.
- Postgres local: Postgres.app instalado en `/Applications/Postgres.app`; servidor se arranca manualmente con `pg_ctl -D ~/Library/Application\ Support/Postgres/var-16 -l logfile start` (no es un servicio automático del sistema).
- Base de datos local: `autoexplora_cms_dev`, usuario `strapi_cms` — credenciales en `.env` local (no versionado).
- ✅ **P1 completo (T-06 a T-12).** Siguiente paso: decidir con el programador si se continúa a P2 (T-13, Article) o se cierra Fase 1 aquí según tiempo disponible antes del 31 jul.
- Auditoría (T-12): content type `AuditLog` (sin Draft & Publish), poblado vía `strapi.documents.use()` — extender `TRACKED_UIDS` en `src/lifecycles/auditLog.ts` al agregar Article (T-13)/StaticText (T-16), igual que con `EDITOR_MANAGED_CONTENT_TYPES`.
- ⚠️ **Contrato de API corregido:** usar `status=draft`/`status=published`, **no** `publicationState` (eso era Strapi v4; en v5 da error). `status=draft` muestra el borrador de TODO, incluso lo ya publicado — es lo que usa el preview del sitio.
- ✅ Modelo de publicación confirmado (2026-07-17): Draft & Publish + webhook (PLAN.md §3).
- ✅ Rama base del sitio confirmada (2026-07-17): `dev`. Desde T-11, `autoexplora-alfa` también vive en `feature/PJ5040-cms-autoexplora-mvp` (creada desde `dev`), en `~/Documents/BRICK-sites/autoexplora-alfa`.
- Despliegue del CMS: **EC2 + Nginx + systemd, sin Docker**. La instancia no existe aún — solicitada a Alexis Herrera (2026-07-20). `deploy/nginx.conf` y `deploy/strapi.service` listos pero no verificados en una instancia real.
- ✅ Bucket S3: subida, lectura pública, CORS y CSP — todo verificado (2026-07-17 a 2026-07-20). Sin bloqueos de S3 activos.
- Banner (T-07) usa **Dynamic Zone** (`content`, componentes `banner.image-content`/`banner.video-content`), no campos planos — cualquier trabajo futuro sobre Banner (T-13 Article puede reusar el patrón) debe considerar esta estructura, no la original del PRD/plan.
- Validación de archivos (T-08) es un hook **global** (`src/lifecycles/validateUploadedFiles.ts`), no específico de Banner — ya cubre cualquier content type futuro que suba imágenes/video.
- El rol Editor recibe permisos por código en `src/bootstrap/ensureEditorPermissions.ts` — al agregar Article (T-13) o StaticText (T-16), extender `EDITOR_MANAGED_CONTENT_TYPES` ahí, no dar permisos manualmente desde el admin.
- T-09 (reordenamiento) corre vía cron cada 5 min (`config/cron-tasks.ts`) + hook reactivo (`src/lifecycles/recompactBannersOnChange.ts`, con guardia anti-reentrancia). Banner expirado se despublica (no se elimina), preservando el borrador.
- Primer usuario admin de Strapi ya creado por el programador directamente en `http://localhost:1337/admin`.
- **T-11 pendiente de conectar a futuro:** el webhook `site-revalidation` (T-10) sigue sin registrarse porque `SITE_REVALIDATE_WEBHOOK_URL` está vacía — se decidió deliberadamente no construir el endpoint de revalidación instantánea en T-11 (ISR de 2 min es suficiente por ahora); queda como mejora aditiva para T-18 (endurecimiento), sin rework.
- El sitio (`autoexplora-alfa`) consume Strapi vía `lib/server/strapiApi.ts`, invocado directo desde `app/page.tsx` (Server Component) — no hay ruta `/api/banners` intermedia; el token (`STRAPI_API_TOKEN`, solo lectura sobre Banner) nunca llega al navegador.
- Token de solo lectura para el sitio ya generado en Strapi (tipo `custom`, permisos `api::banner.banner.find`/`.findOne`), guardado en `autoexplora-alfa/.env` local (no versionado).

---

*Actualizado automáticamente por Claude Code — Engine CX*
