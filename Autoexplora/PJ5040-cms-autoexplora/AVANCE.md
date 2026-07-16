# Registro de Avance — CMS Autoexplora (Strapi)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `autoexplora-cms` — `git@github.com:Sitios-Web-Go-Virtual/autoexplora-cms.git` |
| Rama | `feature/PJ5040-cms-autoexplora-mvp` |
| Responsable actual | Sharon Mendoza |
| Última actualización | 2026-07-16 |
| Modelo de ejecución | claude-sonnet-5 — esfuerzo: máximo |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

**Fase 0 completada.** Repositorio `autoexplora-cms` creado, bootstrapeado (ramas `main`/`develop`/`pre-qa`/`qa`) y con scaffold de Strapi funcionando en la rama `feature/PJ5040-cms-autoexplora-mvp`: conecta a PostgreSQL local, tiene el provider de media S3 configurado (código listo, prueba real de subida pendiente de bucket/credenciales), `CLAUDE.md` generado, y una imagen Docker que construye y corre localmente con health check OK. Siguiente paso: Fase 1 (P1 — banners, auth, publicación en dos etapas).

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Scaffold de Strapi con TypeScript | Claude Code | 2026-07-16 | Verificado: `npm run develop` levanta el admin contra Postgres local |
| T-02 | Configurar Strapi con PostgreSQL (dev local + RDS prod) | Claude Code | 2026-07-16 | Postgres local vía Postgres.app (sin Homebrew); prod 100% por env vars/Secrets Manager, sin hardcode |
| T-03 | Conectar Media Library a S3 | Claude Code | 2026-07-16 | 🟡 Código completo (`@strapi/provider-upload-aws-s3` instalado y configurado) y arranque verificado; **prueba real de subida pendiente** — ver Tareas bloqueadas |
| T-04 | Ejecutar `/init` en el repo del CMS | Claude Code | 2026-07-16 | `CLAUDE.md` generado con stack, comandos y arquitectura |
| T-05 | Dockerfile + despliegue ECS/Fargate | Claude Code | 2026-07-16 | Imagen construida y contenedor corrido localmente con Docker Desktop; health check `/_health` → 204; `deploy/task-definition.json` y `deploy/README.md` listos |

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
| T-10 | Publicación en dos etapas (Draft & Publish + webhook) | Confirmar modelo de publicación (pregunta abierta PRD §13) |
| T-11 | Integración mínima en el sitio `autoexplora-alfa` | |
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
| T-03 (prueba real) | Verificar subida de archivo a S3 desde el admin | Falta bucket S3 y credenciales de un usuario IAM dedicado (permisos mínimos, no personales) | Sharon Mendoza — en proceso de solicitarlos |

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

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `README.md`, `.gitignore` | Modificado (bootstrap fusionado con scaffold) | T-01 |
| `package.json`, `package-lock.json`, `tsconfig.json`, `favicon.png` | Creado | T-01 |
| `config/database.ts`, `config/server.ts` | Creado | T-01/T-02 |
| `config/admin.ts`, `config/api.ts`, `config/middlewares.ts` | Creado | T-01 |
| `config/plugins.ts` | Creado (provider `aws-s3` configurado) | T-03 |
| `.env.example` | Creado (vars de BD y S3) | T-02/T-03 |
| `src/`, `database/migrations/.gitkeep`, `public/`, `types/` | Creado | T-01 |
| `CLAUDE.md` | Creado | T-04 |
| `Dockerfile`, `.dockerignore` | Creado | T-05 |
| `deploy/task-definition.json`, `deploy/README.md` | Creado | T-05 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `4d30ad1` | Inicializar repositorio autoexplora-cms | 2026-07-16 |
| `b50a92e` | [cms-autoexplora] Fase 0 - Scaffold e infraestructura base | 2026-07-16 |

---

## Notas para quien retome el trabajo

- El repo `autoexplora-cms` vive en `~/Documents/BRICK-sites/autoexplora-cms` localmente (hermano de `autoexplora-alfa`).
- Rama activa: `feature/PJ5040-cms-autoexplora-mvp`.
- Postgres local: Postgres.app instalado en `/Applications/Postgres.app`; servidor se arranca manualmente con `pg_ctl -D ~/Library/Application\ Support/Postgres/var-16 -l logfile start` (no es un servicio automático del sistema).
- Base de datos local: `autoexplora_cms_dev`, usuario `strapi_cms` — credenciales en `.env` local (no versionado).
- Siguiente paso: Fase 1 (T-06 en adelante — auth/roles, banners, publicación en dos etapas).
- Pendiente de confirmar antes de T-10: modelo de publicación borrador→`dev`→producción (ver PLAN.md §3 y §12).
- Pendiente (bloqueado): bucket S3 + usuario IAM dedicado para completar la verificación real de T-03.

---

*Actualizado automáticamente por Claude Code — Engine CX*
