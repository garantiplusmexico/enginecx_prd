# Plan de Desarrollo — CMS Autoexplora (Strapi)

> Generado por Claude Code a partir del PRD `PJ5040-cms-autoexplora/PRD.md`.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Autoexplora/PJ5040-cms-autoexplora/PRD.md` |
| Repositorio (CMS) | **Nuevo** — `autoexplora-cms` (Strapi) — por crear en `github.com/Sitios-Web-Go-Virtual` |
| Repositorio (sitio) | Existente — `autoexplora-alfa` (Next.js 16 / React 19), consumidor del contenido |
| Rama funcional (CMS) | `feature/PJ5040-cms-autoexplora-mvp` |
| Tipo | Proyecto nuevo (CMS) + integración ligera en proyecto existente (sitio) |
| Responsable | Alexis Herrera (revisión técnica) — desarrollo Go Virtual |
| Fecha de generación | 2026-07-15 |
| Modelo | claude-opus-4-8 — esfuerzo: máximo |
| Estado | Borrador |

---

## 1. Resumen técnico

CMS acotado y **aislado** para que el cliente Autoexplora gestione su propio contenido (banners, blog, textos estáticos) sin depender del equipo interno. Construido **obligatoriamente sobre Strapi** (RNF-11), es un servicio **independiente** del panel de cliente general (Fase 2, no comprometida).

**Componentes:**

1. **CMS Strapi (nuevo, repo propio `autoexplora-cms`):** headless CMS con content types para Banner, Artículo, Texto estático, Auditoría; autenticación con rol único "editor"; media library conectada a S3; validación de archivos (formato/peso/póster); reordenamiento automático de banners por vigencia; y el motor de publicación en dos etapas (borrador → `dev`/preview → producción).
2. **Sitio Autoexplora (existente, `autoexplora-alfa`):** migración *incremental* de contenido editorial hardcodeado a consumo de la API de contenido de Strapi. Solo lo mínimo del MVP (P1: banners). El inventario (GRID/Brick) **no se toca**.

**Arquitectura:** Frontend + Backend separados (patrón "Componentes" de `arquitectura.md`) — Strapi es el backend de contenido con su propio admin UI y API REST/GraphQL; el sitio Next.js es el consumidor. No amerita microservicios (dominio único, alcance corto).

**Stack:**
- **CMS/Backend:** Strapi (Node.js) — **excepción justificada al default .NET Core 8**, impuesta por el PRD (RNF-11). Ver §12.
- **BD:** PostgreSQL (RDS en producción) — alineado al default de Engine (`stack.md`).
- **Almacenamiento:** Amazon S3 (bucket de la consola correspondiente).
- **Frontend del sitio:** Next.js 16 / React 19 (el que ya usa el proyecto — se respeta).
- **Despliegue:** Docker en **ECS + Fargate** (default para nuevos servicios), ALB + Route 53/Cloudflare.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable (Abigail Estrada / Alexis Herrera).
- [ ] **Repositorio nuevo `autoexplora-cms` creado** en `Sitios-Web-Go-Virtual` con acceso al equipo de desarrollo.
- [ ] Acceso confirmado al repo del sitio `autoexplora-alfa` (rama `dev` para preview).
- [ ] **Bucket S3** aprovisionado para media del CMS + credenciales IAM (usuario/role de mínimo privilegio).
- [ ] **RDS PostgreSQL** (o instancia Postgres) disponible para Strapi; cadena de conexión como secret.
- [ ] Secrets definidos: `APP_KEYS`, `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, `JWT_SECRET`, `TRANSFER_TOKEN_SALT`, credenciales S3, credenciales DB (nunca en código — AWS Secrets Manager / variables de entorno).
- [ ] `CLAUDE.md` presente en el repo del CMS (ejecutar `/init` en el repo nuevo tras el scaffold de Strapi).
- [ ] **Decisión técnica confirmada** sobre el modelo de publicación borrador→`dev`→producción (ver §11, riesgo abierto del PRD) antes de iniciar la Fase 3.
- [ ] Disponibilidad de Memo para dudas puntuales sobre infra/API existente.

---

## 3. Arquitectura del cambio

Patrón **Frontend + Backend separados** (`arquitectura.md` §2): dominio único de contenido, requiere BD y lógica de negocio, no justifica microservicios. Strapi provee admin UI + API; el sitio Next.js la consume.

```
                    ┌─────────────────────────────────────────┐
                    │  CMS Strapi (ECS + Fargate)             │
  Usuario editor →  │  · Admin UI (login rol "editor")        │
  (Autoexplora)     │  · Content types: Banner / Article /    │
                    │    StaticText / AuditLog                │
                    │  · Validación archivos + póster         │
                    │  · Reordenamiento por vigencia (cron)   │
                    │  · API REST/GraphQL                     │
                    └───────┬──────────────────┬──────────────┘
                            │                  │
                   ┌────────▼──────┐   ┌───────▼────────┐
                   │ RDS Postgres  │   │   Amazon S3    │
                   │ (contenido)   │   │ (imágenes/video)│
                   └───────────────┘   └────────────────┘
                            │
          Publicación en dos etapas (borrador→dev→prod)
                            │
                    ┌───────▼───────────────────────────┐
                    │  Sitio Autoexplora (Next.js)       │
                    │  preview (rama dev) → producción   │
                    │  consume API de contenido Strapi   │
                    └────────────────────────────────────┘
```

**Modelo de publicación en dos etapas (RF-06 / RNF-02) — decisión de diseño recomendada:**
Usar el **Draft & Publish nativo de Strapi** como fuente de estados, con **dos entornos de consumo** en el sitio:
- **Preview (`dev`):** el sitio en su despliegue de preview consulta la API de Strapi incluyendo contenido en estado *draft* (`publicationState=preview`). Corresponde a la rama `dev` del sitio.
- **Producción:** el sitio de producción consulta solo contenido *published*. "Publicar" en Strapi = promover el registro a *published*; un **webhook** de Strapi dispara la revalidación/rebuild del sitio de producción.

> Esta es la opción de menor fricción y menor riesgo para el deadline. La alternativa (escritura directa a la rama `dev` del repo git del sitio) es más frágil y se descarta salvo indicación contraria. **Confirmar con el equipo antes de la Fase 3** (pregunta abierta del PRD §13).

---

## 4. Tareas de desarrollo

Fases alineadas a la priorización del PRD (P1 → P2 → P3) con una Fase 0 de infraestructura. **Guardarraíl de alcance:** si al 31 jul 2026 el desarrollo se extiende, se entrega **solo P1** (Fase 0 + Fase 1 + Fase 2 de este plan).

### Fase 0 — Scaffold e infraestructura base

- [ ] **T-01** — Crear repo `autoexplora-cms` y scaffold de Strapi (última versión estable) con TypeScript.
  - Archivos: proyecto Strapi base, `Dockerfile`, `.env.example`, `README.md`.
  - Criterio: `npm run develop` levanta el admin en local contra Postgres local.

- [ ] **T-02** — Configurar Strapi con PostgreSQL (dev local + RDS prod) vía variables de entorno.
  - Archivos: `config/database.ts`, `config/server.ts`, `.env.example`.
  - Criterio: Strapi conecta a Postgres en local y las credenciales de prod se leen solo de env/Secrets Manager.

- [ ] **T-03** — Conectar Media Library a S3 (`@strapi/provider-upload-aws-s3`).
  - Archivos: `config/plugins.ts`, `.env.example`.
  - Criterio: una subida de prueba desde el admin queda almacenada en el bucket S3.

- [ ] **T-04** — Ejecutar `/init` en el repo del CMS para generar `CLAUDE.md`.
  - Criterio: `CLAUDE.md` documenta stack, comandos y estructura de Strapi.

- [ ] **T-05** — `Dockerfile` + definición de despliegue ECS/Fargate (task definition, servicio, ALB, health check) y dominio en Route 53/Cloudflare.
  - Criterio: imagen construye y corre localmente vía Docker; documento de despliegue listo para infra.

### Fase 1 — P1: Acceso multiusuario, banners y publicación en dos etapas

- [ ] **T-06** — Configurar autenticación y rol único "editor" (plugin Users & Permissions).
  - Archivos: config de roles/permisos, seed opcional.
  - Criterio (RF-01/RF-02/RNF-01): un usuario "editor" dado de alta por Go Virtual entra al admin; no hay autoservicio de altas; los permisos del rol se limitan a los content types del MVP.

- [ ] **T-07** — Content type **Banner** (sección, tipo imagen/video, archivo, póster, enlace destino, orden/posición, vigencia inicio/fin opcional, estado).
  - Archivos: `src/api/banner/**` (schema, controller, service, routes).
  - Criterio (RF-03): CRUD completo de banners por sección desde el admin.

- [ ] **T-08** — Validación de archivos y póster obligatorio en video (lifecycle hooks / validación custom).
  - Archivos: `src/api/banner/content-types/banner/lifecycles.ts`, util de validación compartida.
  - Criterio (RF-04/RF-11): rechaza formato inválido (solo JPG/WebP imagen, MP4 video); imagen >1 MB y video >10 MB bloqueados; video >10 MB muestra aviso sugiriendo embed; video sin póster no se guarda ni publica.

- [ ] **T-09** — Reordenamiento automático de banners por vigencia (recompactar posiciones al caducar).
  - Archivos: `src/api/banner/services/reorder.ts`, tarea cron (`config/cron-tasks.ts`) + hook al editar vigencia.
  - Criterio (RF-05): al caducar un banner, los de posiciones inferiores suben (2→1, 3→2…) sin intervención del usuario.

- [ ] **T-10** — Publicación en dos etapas: habilitar Draft & Publish y exponer API con `publicationState` (preview vs published) + webhook de publicación.
  - Archivos: config del content type (draftAndPublish), config de webhooks, doc del contrato de API.
  - Criterio (RF-06/RF-07/RNF-02/RNF-05): guardar = draft consumible en preview; publicar = published; despublicar/revertir disponible; el cliente nunca escribe directo en producción.

- [ ] **T-11** — Integración mínima en el sitio `autoexplora-alfa`: consumir banners P1 desde la API de Strapi (preview en `dev`, published en prod).
  - Archivos (sitio): capa server-only de fetch a Strapi (patrón proxy, análogo a `lib/server/gridApi.ts`), componente/sección de banners, variables de entorno del sitio.
  - Criterio: los banners publicados en Strapi se ven en producción; los borradores se ven en preview (`dev`); el token de Strapi nunca llega al navegador.

- [ ] **T-12** — Registro de auditoría (usuario + acción + entidad + fecha/hora) para crear/editar/publicar/despublicar.
  - Archivos: content type/`AuditLog` o middleware de auditoría, lifecycle hooks.
  - Criterio (RNF-03/RNF-10): cada acción sobre una pieza queda registrada y consultable; logs de publicaciones y errores emitidos.

### Fase 2 — P2: Gestión de blog *(recortable si se excede el deadline)*

- [ ] **T-13** — Content type **Article** (título, slug, autor, hero imagen/video, cuerpo enriquecido, categoría/etiquetas, estado, fecha).
  - Archivos: `src/api/article/**`, content types de `Category`/`Tag` si aplica.
  - Criterio (RF-08): CRUD completo de artículos con Draft & Publish y validación de hero (reusa T-08).

- [ ] **T-14** — Editor de texto enriquecido con soporte de imágenes, videos y embeds (YouTube/redes).
  - Archivos: config del campo rich text (bloques nativos de Strapi o plugin CKEditor), sanitización de embeds.
  - Criterio (RF-09): barra de formato (itálica, quote, nota al pie…) e inserción de media/embeds funcionando; salida sanitizada.

- [ ] **T-15** — Consumo de blog en el sitio (listado + detalle) desde Strapi *(alcance según tiempo)*.
  - Criterio: artículos publicados renderizan en el sitio; embeds se muestran correctamente.

### Fase 3 — P3: Textos estáticos *(recortable si se excede el deadline)*

- [ ] **T-16** — Content type **StaticText** (sección, contenido enriquecido, estado) con el mismo editor de T-14.
  - Archivos: `src/api/static-text/**`.
  - Criterio (RF-10): edición por sección con Draft & Publish; reusa el editor enriquecido.

- [ ] **T-17** — Consumo de textos estáticos en las secciones correspondientes del sitio *(alcance según tiempo)*.
  - Criterio: los textos publicados sustituyen el contenido hardcodeado de las secciones migradas.

### Fase 4 — Endurecimiento y entrega

- [ ] **T-18** — Manejo de errores y mensajes claros (formato/peso/subida/publicación) + observabilidad (logs).
  - Criterio (RNF-06/RNF-09/RNF-10): mensajes de error claros para usuarios no técnicos; logs de publicaciones y fallos.
- [ ] **T-19** — Despliegue a ECS/Fargate, verificación 24/7 (health checks) y monitoreo de facturación AWS.
  - Criterio (RNF-04): CMS disponible; alertas de billing configuradas.

---

## 5. Cambios en base de datos

Strapi genera y gestiona el esquema PostgreSQL automáticamente a partir de los content types (no se escriben migraciones SQL a mano). Tablas resultantes principales:

| Tabla (auto-generada) | Tipo de cambio | Descripción |
|---|---|---|
| `banners` | Nueva | Banner: sección, tipo, media, póster, enlace, orden, vigencia, estado |
| `articles` | Nueva | Artículo de blog (P2) |
| `categories` / `tags` | Nueva | Taxonomía de blog (P2, si aplica) |
| `static_texts` | Nueva | Textos estáticos por sección (P3) |
| `audit_logs` | Nueva | Registro de auditoría (usuario, acción, entidad, fecha/hora) |
| Tablas core de Strapi | Nueva | `admin_users`, `up_users`, `up_roles`, `files`, etc. (gestionadas por Strapi) |

---

## 6. Endpoints nuevos o modificados

Strapi expone automáticamente REST (y opcionalmente GraphQL) por content type. Contratos principales que consume el sitio:

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/api/banners?publicationState=preview&sort=order` | Banners para preview (`dev`) | Nuevo (auto) |
| GET | `/api/banners?sort=order` | Banners publicados (producción) | Nuevo (auto) |
| GET | `/api/articles` | Listado de blog publicado (P2) | Nuevo (auto) |
| GET | `/api/articles/:slug` | Detalle de artículo (P2) | Nuevo (auto) |
| GET | `/api/static-texts?filters[section]=...` | Texto estático por sección (P3) | Nuevo (auto) |
| POST | webhook de publicación | Dispara revalidación/rebuild del sitio | Nuevo |

> El sitio nunca expone el token de Strapi al navegador: el fetch se hace server-only (patrón proxy análogo a `lib/server/gridApi.ts` en `autoexplora-alfa`).

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `DATABASE_URL` / `DATABASE_*` | Conexión PostgreSQL | Dev / Prod |
| `APP_KEYS`, `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`, `JWT_SECRET`, `TRANSFER_TOKEN_SALT` | Secrets core de Strapi | Dev / Prod |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_BUCKET` | Provider S3 de media | Dev / Prod |
| `STRAPI_API_URL` (en el sitio) | Base URL de la API de contenido | Dev / Prod |
| `STRAPI_API_TOKEN` (en el sitio, server-only) | Token de lectura hacia Strapi | Dev / Prod |
| `PREVIEW_WEBHOOK_SECRET` | Firma del webhook de publicación | Prod |

> Todos los secrets viven en variables de entorno / AWS Secrets Manager. Nunca en el código (`coding-guidelines.md` §11, `infraestructura.md` §5).

---

## 8. Consideraciones de seguridad

- **IAM de mínimo privilegio:** el usuario/role del provider S3 solo puede leer/escribir en el bucket del CMS (no acceso amplio).
- **Autenticación:** solo usuarios dados de alta por Go Virtual (rol "editor"); JWT de Strapi. Sin autoservicio de altas (RF-02).
- **Integridad de producción (RNF-02):** el cliente nunca escribe directo a producción; todo pasa por borrador → `dev` → publicar.
- **Token del sitio → Strapi:** solo server-side; nunca expuesto al navegador.
- **Validación/sanitización:** validar formato/peso de archivos y sanitizar el HTML/embeds del editor enriquecido (evitar XSS vía embeds).
- **API keys / S3:** restringidas; monitoreo de facturación AWS configurado (AWS no corta al llegar a un límite).
- **Auditoría (RNF-03):** trazabilidad de crear/editar/publicar/despublicar por usuario.

---

## 9. Consideraciones de infraestructura

- **Nuevo servicio ECS + Fargate** para el CMS Strapi: task definition, servicio, ALB, health check, autoscaling básico. Estimar costo (Fargate + RDS + S3 + ALB) y configurar alertas de billing.
- **RDS PostgreSQL** para el contenido (o instancia Postgres justificada por costo).
- **S3** bucket dedicado para media del CMS.
- **Route 53 / Cloudflare** para el dominio del admin del CMS (p. ej. `cms.autoexplora...`).
- **Consola AWS:** desplegar en la consola correspondiente a Go Virtual/Autoexplora (confirmar cuál; `infraestructura.md` marca varias "por definir").
- El sitio `autoexplora-alfa` ya restringe imágenes remotas a su bucket S3 en `next.config.ts` — habrá que **agregar el host de media de Strapi/S3** a los remotos permitidos.

---

## 10. Criterios de aceptación

- [ ] Un usuario "editor" (alta por Go Virtual) inicia sesión en el CMS (RF-01).
- [ ] CRUD de banners por sección con imagen o video, enlace, posición y vigencia opcional (RF-03).
- [ ] Video exige póster; sin póster no guarda ni publica (RF-04).
- [ ] Validación de archivos: JPG/WebP ≤1 MB, MP4 ≤10 MB; video >10 MB → aviso + sugerencia de embed (RF-11).
- [ ] Al caducar un banner, las posiciones inferiores suben automáticamente (RF-05).
- [ ] Guardar borrador → visible en preview (`dev`); publicar → visible en producción; despublicar/revertir disponible (RF-06/RF-07/RNF-05).
- [ ] Media almacenada en S3 (RF-12).
- [ ] Auditoría de acciones por usuario registrada (RNF-03).
- [ ] CMS desplegado en ECS/Fargate y disponible 24/7 (RNF-04).
- [ ] **(P2, si tiempo)** CRUD de blog con editor enriquecido y embeds (RF-08/RF-09).
- [ ] **(P3, si tiempo)** Edición de textos estáticos por sección (RF-10).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Modelo borrador→`dev`→prod no reconciliado con Strapi (pregunta abierta PRD §13) | Alta | Alto | Adoptar Draft & Publish + webhook (§3); **confirmar antes de Fase 3**; no bloquear P1 en la variante git |
| Deadline estricto (31 jul) con P1+P2+P3 | Alta | Alto | Guardarraíl: recortar a P1 (Fase 0+1); priorizar entrega de banners y publicación |
| Curva de aprendizaje de Strapi / límites de plugins y MCP | Media | Medio | Usar features nativas (Draft & Publish, Users & Permissions, provider S3); evitar customización innecesaria |
| Conexión Media Library ↔ S3 (pregunta abierta PRD) | Media | Medio | Usar `@strapi/provider-upload-aws-s3` oficial; validar en Fase 0 (T-03) |
| Ausencia de Memo / documentación incompleta de infra existente | Media | Medio | CMS 100% independiente en el MVP; no depender de la API/infra heredada |
| Falta de accesos (repo/AWS) al iniciar | Media | Alto | Bloquear como prerequisito (§2) antes de Fase 0 |
| Migración de contenido hardcodeado del sitio más grande de lo previsto | Media | Medio | Migración incremental; en P1 solo banners; blog/textos según tiempo |
| Sanitización de embeds del editor (XSS) | Baja | Medio | Sanitizar HTML/embeds; whitelist de dominios (YouTube/redes) |

---

## 12. Notas para el programador

1. **Excepción de stack (importante):** el default de Engine para backend nuevo es **.NET Core 8** (`stack.md`), pero el PRD **impone Strapi (Node.js)** como plataforma obligatoria (RNF-11). El plan respeta el PRD: el CMS se construye en Strapi. BD (PostgreSQL), despliegue (Docker/ECS/Fargate) y S3 **sí** siguen los defaults de Engine. Validar esta excepción con el Gerente de TI si hace falta dejarla por escrito.

2. **Rama base / control de versiones:**
   - El CMS es un **repo nuevo** (`autoexplora-cms`). Al inicializarlo, crear la estructura de ramas de Engine (`main`, `develop`, `pre-qa`, `qa`) y trabajar la funcional desde `develop`: `feature/PJ5040-cms-autoexplora-mvp`.
   - ⚠️ **En el repo del sitio `autoexplora-alfa` NO existe `develop`.** Sí existen `dev` (usada como preview del flujo de publicación del PRD) y `qa`. Para los cambios del sitio (T-11, T-15, T-17), la rama base sería `main` según el flujo estándar de Engine, PERO el equipo del sitio trabaja con `dev`. **Confirmar con el equipo del sitio** qué rama base usar antes de tocar `autoexplora-alfa`. Se recomienda alinear el repo del sitio al estándar Engine (crear `develop`).

3. **`dev` tiene dos significados aquí — no confundir:** en el PRD, `dev` es la **rama/entorno de preview del sitio** (destino del contenido en borrador). En el flujo de Engine, `develop` es la rama de integración de desarrollo. Este plan usa Draft & Publish de Strapi como fuente de estados (§3), de modo que "preview" no depende de escribir en la rama git del sitio.

4. **Alcance vs. deadline:** el guardarraíl del PRD manda recortar a **solo P1** si se excede el 31 jul 2026. Las Fases 2 (blog) y 3 (textos) están marcadas como recortables; entregar Fase 0 + Fase 1 completas primero.

5. **Preguntas abiertas del PRD a cerrar antes/durante Fase 3:** modelo de publicación (¿entornos Strapi vs. flujo git?), conexión media↔S3, y si se reutiliza algo de la API de Memo (en el MVP: no).

6. **No se refactoriza** el código existente del sitio salvo lo mínimo para consumir el contenido; el inventario (GRID/Brick) queda intacto.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
