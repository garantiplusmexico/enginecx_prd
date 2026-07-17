# Registro de Avance — CMS Autoexplora (Strapi)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `autoexplora-cms` — `git@github.com:Sitios-Web-Go-Virtual/autoexplora-cms.git` |
| Rama | `feature/PJ5040-cms-autoexplora-mvp` |
| Responsable actual | Sharon Mendoza |
| Última actualización | 2026-07-17 |
| Modelo de ejecución | claude-sonnet-5 — esfuerzo: máximo |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

**Fase 0 completada, con un cambio de arquitectura de despliegue posterior.** Repositorio `autoexplora-cms` creado, bootstrapeado (ramas `main`/`develop`/`pre-qa`/`qa`) y con scaffold de Strapi funcionando en la rama `feature/PJ5040-cms-autoexplora-mvp`: conecta a PostgreSQL local, tiene el provider de media S3 configurado. El 2026-07-17 el programador confirmó buckets S3 reales (`govirtual-autoexplora-cms-prod`/`-qa`) y decidió **no usar Docker/ECS/Fargate**: el despliegue será en una **instancia EC2 con Nginx + systemd**, con **PostgreSQL local en la misma instancia** (no RDS). Se rehizo T-05 en consecuencia (Dockerfile/ECS retirados, sustituidos por `deploy/nginx.conf` + `deploy/strapi.service` + guía EC2). Siguiente paso: Fase 1 (P1 — banners, auth, publicación en dos etapas).

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Scaffold de Strapi con TypeScript | Claude Code | 2026-07-16 | Verificado: `npm run develop` levanta el admin contra Postgres local |
| T-02 | Configurar Strapi con PostgreSQL (dev local + Postgres local en EC2 para qa/prod) | Claude Code | 2026-07-16 | Postgres local vía Postgres.app (sin Homebrew); qa/prod 100% por env vars/Secrets Manager, sin hardcode |
| T-03 | Conectar Media Library a S3 | Claude Code | 2026-07-17 | ✅ Subida real verificada: archivo de prueba confirmado en `govirtual-autoexplora-cms-qa` (5 objetos — original + 4 tamaños responsivos). Requirió fix: `config/plugins.ts` necesita `ACL: undefined` explícito porque el bucket tiene ACLs deshabilitadas ("Bucket owner enforced"); sin esto, la subida fallaba con `AccessControlListNotSupported`. **Lectura pública sigue bloqueada** — ver Tareas bloqueadas |
| T-04 | Ejecutar `/init` en el repo del CMS | Claude Code | 2026-07-16 | `CLAUDE.md` generado con stack, comandos y arquitectura |
| T-05 | Nginx + systemd para despliegue en EC2 *(rehecha 2026-07-17)* | Claude Code | 2026-07-16 → 2026-07-17 | Versión original (Dockerfile + ECS/Fargate, verificada con Docker Desktop) **retirada** por decisión de infraestructura del programador. Versión actual: `deploy/nginx.conf`, `deploy/strapi.service`, `deploy/README.md` — no verificable hasta que exista la instancia EC2 real (la crea el equipo de infraestructura) |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| | | | | |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-06 | Autenticación y rol único "editor" | |
| T-07 | Content type Banner | |
| T-08 | Validación de archivos y póster obligatorio | |
| T-09 | Reordenamiento automático de banners por vigencia | |
| T-10 | Publicación en dos etapas (Draft & Publish + webhook) | ✅ Modelo confirmado 2026-07-17 — sin bloqueo |
| T-11 | Integración mínima en el sitio `autoexplora-alfa` | ✅ Rama base confirmada 2026-07-17 (`dev`) — sin bloqueo |
| T-12 | Registro de auditoría | |
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
| T-03 (lectura pública) | Los objetos subidos a S3 no son accesibles públicamente (`403 Forbidden` al pedir la URL directa) — la miniatura sale rota en el admin, y lo mismo pasaría en el sitio en producción | Falta una **bucket policy** de lectura pública (`s3:GetObject`) en ambos buckets + revisar "Block Public Access" del bucket. El usuario IAM `autoexplora-cms` no tiene permiso (`s3:PutBucketPolicy`/`s3:GetBucketPolicy` → `AccessDenied`, confirmado) | Alexis Herrera / quien administre la cuenta AWS — solicitud ya enviada por el programador (2026-07-17) |
| T-05 (verificación real) | Verificar `deploy/nginx.conf` + `deploy/strapi.service` en una instancia real | La instancia EC2 no existe aún; la aprovisiona el equipo de infraestructura del cliente | Equipo de infraestructura del cliente |

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

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `4d30ad1` | Inicializar repositorio autoexplora-cms | 2026-07-16 |
| `b50a92e` | [cms-autoexplora] Fase 0 - Scaffold e infraestructura base | 2026-07-16 |
| `b44d14a` | [cms-autoexplora] Rehacer T-05 - Despliegue EC2 + Nginx + systemd (sin Docker) | 2026-07-17 |
| `c2131e2` (enginecx_prd) | cms-autoexplora Actualizar plan - Despliegue EC2 + Nginx + systemd | 2026-07-17 |

---

## Notas para quien retome el trabajo

- El repo `autoexplora-cms` vive en `~/Documents/BRICK-sites/autoexplora-cms` localmente (hermano de `autoexplora-alfa`).
- Rama activa: `feature/PJ5040-cms-autoexplora-mvp`.
- Postgres local: Postgres.app instalado en `/Applications/Postgres.app`; servidor se arranca manualmente con `pg_ctl -D ~/Library/Application\ Support/Postgres/var-16 -l logfile start` (no es un servicio automático del sistema).
- Base de datos local: `autoexplora_cms_dev`, usuario `strapi_cms` — credenciales en `.env` local (no versionado).
- Siguiente paso: Fase 1 (T-06 en adelante — auth/roles, banners, publicación en dos etapas).
- ✅ Modelo de publicación confirmado (2026-07-17): Draft & Publish + webhook (PLAN.md §3). T-10 puede ejecutarse sin más validaciones.
- ✅ Rama base del sitio confirmada (2026-07-17): `dev` (no `develop`/`main`). T-11/T-15/T-17 se ramifican desde ahí.
- Despliegue: **EC2 + Nginx + systemd, sin Docker** (cambio del 2026-07-17). La instancia no existe aún — la crea el equipo de infraestructura del cliente. `deploy/nginx.conf` y `deploy/strapi.service` están listos pero no verificados en una instancia real.
- Bucket S3: subida real verificada (2026-07-17) tras el fix de ACL en `config/plugins.ts`. **Bloqueado**: falta bucket policy de lectura pública en ambos buckets — solicitada a Alexis Herrera. Sin ella, las imágenes/videos no se van a ver ni en el admin ni en el sitio en producción.
- Primer usuario admin de Strapi ya creado por el programador directamente en `http://localhost:1337/admin`.

---

*Actualizado automáticamente por Claude Code — Engine CX*
