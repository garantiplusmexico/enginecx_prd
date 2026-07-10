# Registro de Avance — Panel del Cliente Go Virtual (MVP · Fase 1)

> Este documento lo actualiza Claude Code conforme ejecuta tareas del plan. Quien retome el
> trabajo debe leerlo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `enginecx_prd/sitios web/PJ3893-prueba-de-prd/PLAN.md` |
| Rama | `feature/panel-cliente-mvp` (en `panel-cliente-api` y `panel-cliente-web`) |
| Responsable actual | Abigail Estrada / Claude Code |
| Última actualización | 2026-07-10 |
| Estado general | 🟡 En progreso — Fase 0 completada |
| Modelo | claude-opus-4-8 — esfuerzo: alto |

---

## Resumen de estado

Repos locales creados (`panel-cliente-api` NestJS, `panel-cliente-web` Next.js) con la
estructura de ramas de Engine (`main`/`develop`/`pre-qa`/`qa` + `feature/panel-cliente-mvp`).
**Fase 0 (Fundaciones) completada**: scaffold de ambos servicios, modelo de datos multi-tenant
en Mongoose y cliente de consumo de `govirtual-api`. Pendiente: `npm install` + build/typecheck
(no ejecutable en esta sesión) y **revisión del modelo de tenancy por GV** antes de continuar a
Fase 1. Push a GitHub pendiente (remoto no creado / sin auth en esta sesión).

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Scaffold `panel-cliente-api` (NestJS) + healthcheck | Claude Code | 2026-07-10 | `GET v1/health`, helmet, CORS, ValidationPipe, Swagger, Throttler, Dockerfile |
| T-02 | Scaffold `panel-cliente-web` (Next.js) | Claude Code | 2026-07-10 | App Router, página placeholder, `.env.example` |
| T-03 | Modelo de datos multi-tenant (Mongoose) | Claude Code | 2026-07-10 | organization/user/membership/password-reset/addon-config/access-log + enums Role/TenantLevel. **Requiere revisión de GV** |
| T-04 | Cliente de consumo de `govirtual-api` | Claude Code | 2026-07-10 | axios con timeout + reintentos backoff; DTOs de sitio (GRID/BRICK) y lead; método SSO Duda |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| — | — | — | — | Fase 1 arranca tras autorización del commit de Fase 0 y revisión del modelo de tenancy |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-05…T-10 | Fase 1 — Autenticación y seguridad | Revisión del modelo de tenancy por GV |
| T-11…T-16 | Fase 2 — Usuarios y endpoints del panel interno | — |
| T-17…T-21 | Fase 3 — Dashboard de sitios | — |
| T-22…T-24 | Fase 4 — SSO Duda + add-ons | T-24: discovery SSO Uberall/Cloud Campaign; T-22: rate limit Duda |
| T-25 | Fase 5 — Leads (condicional) | Confirmación de viabilidad en discovery |
| T-26…T-28 | Fase 6 — BI, hardening, QA | — |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-24 | SSO add-ons | Falta confirmar SSO programático de Uberall/Cloud Campaign | GV + proveedores (discovery) |
| T-22 | SSO Duda (escala) | Falta validar rate limit de Duda para ~350 concurrentes | GV / equipo govirtual-api |
| (push) | Subir ramas a GitHub | Remoto no creado y sin auth GitHub en esta sesión | Responsable (crear repos + accesos) |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Backend en NestJS + MongoDB Atlas | Compatibilidad con `govirtual-api` (RNF-07/08/13); confirmado por el responsable | Diverge del default Engine (.NET/PostgreSQL) |
| Infra AWS (ECS/Fargate + S3) | Decisión del responsable; alinea con `infraestructura.md` | Diverge del PRD que mencionaba Render/Vercel |
| Dos repos separados (api / web) | Independencia de despliegue (RNF-13) | Frontend y backend evolucionan en paralelo |
| Cliente `govirtual-api` con reintentos backoff y 502 en fallo persistente | Resiliencia ante latencia/fallos del upstream | Mitiga riesgo de latencia del PRD |
| `sitesAccess` se resuelve en tiempo real desde `govirtual-api` para scopes GROUP/BRAND | Evita duplicar la fuente de verdad (RNF-07) | Membership guarda scope, no la lista completa |

---

## Archivos creados o modificados

| Archivo | Tipo | Tarea |
|---|---|---|
| panel-cliente-api/package.json, tsconfig*.json, nest-cli.json, .gitignore, .env.example, Dockerfile, CLAUDE.md, README.md | Creado | T-01 |
| panel-cliente-api/src/main.ts, app.module.ts, common/config/configuration.ts | Creado | T-01 |
| panel-cliente-api/src/health/{health.controller,health.module}.ts | Creado | T-01 |
| panel-cliente-api/src/tenancy/enums/{role,tenant-level}.enum.ts | Creado | T-03 |
| panel-cliente-api/src/tenancy/schemas/{organization,user,membership,password-reset,addon-config,access-log}.schema.ts | Creado | T-03 |
| panel-cliente-api/src/tenancy/tenancy.module.ts | Creado | T-03 |
| panel-cliente-api/src/govirtual/dto/{site,lead}.dto.ts, govirtual.client.ts, govirtual.module.ts | Creado | T-04 |
| panel-cliente-web/package.json, tsconfig.json, next.config.mjs, .gitignore, .env.example, CLAUDE.md, README.md | Creado | T-02 |
| panel-cliente-web/app/{layout,page}.tsx | Creado | T-02 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| (pendiente) | Fase 0 — Fundaciones | pendiente de autorización |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** tras aprobar el modelo de tenancy (T-03) con GV, ejecutar Fase 1
  (T-05…T-10: login/bcrypt, JWT+claims, recovery, lockout, logout, scope guard).
- **Contexto importante:** `sitesAccess` del JWT se resuelve desde `govirtual-api`; el
  `ScopeGuard` (T-10) es el control central de RNF-06. El cliente de `govirtual-api` ya está en
  `src/govirtual/`.
- **Decisiones pendientes de input:** revisión del modelo de tenancy por GV; discovery de SSO
  Uberall/Cloud Campaign; rate limit de Duda; si leads (T-25) entra al MVP; hosting del frontend
  (Amplify vs S3+CloudFront vs Vercel); creación de repos GitHub + accesos para el push.
- **No verificado en esta sesión:** `npm install`, build y typecheck de ambos repos.

---

*Actualizado automáticamente por Claude Code — Engine CX*
