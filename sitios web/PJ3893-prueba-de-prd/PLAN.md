# Plan de Desarrollo — Panel del Cliente Go Virtual (MVP · Fase 1)

> Generado por Claude Code a partir del PRD `enginecx_prd/sitios web/PJ3893-prueba-de-prd/PRD.md`.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.
> **Alcance de este plan:** MVP (Fase 1) a detalle + resumen de Fase 2 y Fase 3.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/sitios web/PJ3893-prueba-de-prd/PRD.md` (v1.0, Mayo 2026) |
| Repositorio | **Nuevo** — `panel-cliente-api` (Panel API) + `panel-cliente-web` (frontend). Servicios independientes (RNF-13). |
| Rama | `feature/panel-cliente-mvp` (desde `develop`, una vez inicializado el repo) |
| Tipo | **Proyecto nuevo** |
| Responsable | Abigail Estrada (PRD) / Alexis Herrera (revisión) — desarrollo: tercero + equipo interno GV |
| Fecha de generación | 2026-07-09 |
| Estado | Borrador |
| Modelo | claude-opus-4-8 — esfuerzo: alto |

---

## 1. Resumen técnico

El **Panel del Cliente** es una plataforma web nueva (`app.govirtual.com.mx`) que da a los clientes de Go Virtual (grupos y concesionarios de los productos **GRID** y **BRICK**) visibilidad de sus sitios y acceso sin fricción (SSO) al editor Duda y a add-ons contratados. El MVP (Fase 1) cubre **autenticación, visibilidad de sitios por jerarquía y SSO**; no incluye autogestión de datos (se difiere a Fase 2).

**Componentes que se crean:**
- **Panel API** — servicio backend nuevo e independiente que orquesta auth, tenancy, permisos y la generación de SSO. **No duplica** la lógica de `govirtual-api`: la consume como fuente de verdad para sitios, DealerInfo, leads e inventarios (RNF-07).
- **Panel Web** — frontend nuevo del cliente (dashboard, login, herramientas).
- **Endpoints para la sección interna GV** — la Panel API expone los endpoints que consumirá la nueva sección del panel Lovable interno; **la UI de esa sección la construye el equipo interno de GV** (fuera de alcance del tercero, ver PRD §6).

**Arquitectura:** Frontend + Backend separados (patrón #2 de `arquitectura.md`), comunicados por API REST. Justificación: dominio único (el portal) con pocos subdominios, requiere BD propia (usuarios/permisos del portal) e independencia de despliegue para que el tercero avance en paralelo sin bloquear a `govirtual-api` (RNF-13). No se usan microservicios (no hay múltiples dominios de negocio independientes) ni N8N (tiene UI + BD).

**Stack a usar (⚠️ diverge de los defaults de Engine — justificado por el PRD, ver §12):**

| Capa | Decisión | Base |
|---|---|---|
| Backend (Panel API) | **NestJS (Node.js) + TypeScript** | Compatibilidad con `govirtual-api` (NestJS) y auth existente (RNF-08). Es el "caso puntual justificado" que `stack.md` permite para NestJS. |
| Base de datos | **MongoDB Atlas** (nueva colección, cluster existente) | RNF-09 — reutilizar infra; `govirtual-api` ya usa Mongo. |
| Frontend (Panel Web) | **Next.js / React** | BRICK ya usa Next.js/Vercel; despliegue en Vercel. |
| Despliegue backend | **AWS ECS + Fargate** (contenedor Docker) | Infra AWS de Engine (`infraestructura.md`): todo servicio nuevo va a ECS+Fargate. NestJS se empaqueta en Docker. |
| Despliegue frontend | **AWS** (Amplify Hosting o S3 + CloudFront) | Next.js desplegado en AWS. Alternativa del PRD: Vercel — confirmar (ver §12). |
| Almacenamiento | **AWS S3** (existente) | Assets del portal; banners en Fase 2. |
| Auth | JWT stateless + bcrypt | RNF-08 — sin proveedores externos de identidad en MVP. |

---

## 2. Prerequisitos

Antes de iniciar la construcción:

- [ ] PRD validado por el responsable (Abigail / Alexis).
- [ ] **Discovery de SSO con Uberall y Cloud Campaign** — confirmar con cada proveedor si su API soporta SSO programático y bajo qué partnership (bloquea RF-27/RF-28; riesgo Alto del PRD).
- [ ] **Validación de rate limits de Duda Partner API** para ~350 clientes concurrentes (RNF-10; riesgo Alto).
- [ ] Acceso a `govirtual-api`: endpoints de sitios/dealers/leads, esquema de respuesta, y **versionado** de los endpoints que consumirá el panel (riesgo Medio: cambios en `govirtual-api` rompen la integración).
- [ ] Confirmar framework backend (NestJS) y BD (MongoDB Atlas) con el líder técnico — divergen del default Engine (.NET/PostgreSQL); la infra es AWS (alineada con Engine). Ver §12.
- [ ] Credenciales/entorno: cluster MongoDB Atlas (cadena de conexión + colección nueva), proveedor SMTP para emails transaccionales, claves de Duda Partner API (ya en `govirtual-api`), claves Uberall/Cloud Campaign.
- [ ] Repos nuevos creados en GitHub con ramas obligatorias (`main`, `develop`, `pre-qa`, `qa`) — ver §12.
- [ ] `CLAUDE.md` presente en cada repo nuevo (ejecutar `/init` al crearlos).
- [ ] Compromiso de tiempo del equipo interno GV para la UI de la sección Lovable (supuesto del PRD).
- [ ] Decisión: ¿la visualización de leads (RF-37C–40C) entra al MVP o se difiere a Fase 2? (confirmar en discovery del proveedor).

---

## 3. Arquitectura del cambio

Patrón **Frontend + Backend separados** (`arquitectura.md` §2). La Panel API es un proxy con lógica de tenancy/permisos que **valida el scope del usuario** antes de consultar/orquestar `govirtual-api` y las APIs de terceros.

```
┌────────────┐      REST/HTTPS      ┌───────────────┐   consume (fuente de verdad)  ┌──────────────┐
│ Panel Web  │ ───────────────────► │   Panel API   │ ────────────────────────────► │ govirtual-api│
│ (Next.js/  │ ◄─── JWT + datos ─── │ (NestJS/AWS)   │                               │ (sitios,     │
│  Vercel)   │                      │               │                               │  dealers,    │
└────────────┘                      │  ┌──────────┐ │                               │  leads)      │
                                    │  │ MongoDB  │ │                               └──────┬───────┘
   Sección interna GV (Lovable) ───►│  │ Atlas    │ │                                      │
   (UI la hace GV, consume          │  │ portal   │ │        SSO tokens                    ▼
    endpoints Panel API)            │  └──────────┘ │ ──────────────────────►  Duda Partner API
                                    └───────┬───────┘                          Uberall API
                                            │ SSO add-ons                      Cloud Campaign API
                                            └────────────────────────────────►
```

**Regla de oro de seguridad (RNF-06):** los permisos se heredan **hacia abajo** en Grupo→Marca→Sitio, **nunca hacia arriba**. Ningún SSO ni consulta de datos se genera para un `site_id` fuera del `sitesAccess` del JWT. Toda escritura del cliente pasa por la Panel API, que valida scope antes de proxear (no hay escritura directa del cliente contra `govirtual-api`).

**Diferenciación GRID vs BRICK (clave desde el día 1):** la UI cambia por tipo de sitio. GRID → botón "Editar en CMS" (SSO Duda). BRICK → tarjeta solo lectura, sin botón (RF-24). Este flag debe venir del dato del sitio de `govirtual-api`.

---

## 4. Tareas de desarrollo

Desglose atómico y ordenado del **MVP (Fase 1)**. Cada tarea es completable y verificable de forma independiente. Prefijo `T-` global.

### Fase 0 — Fundaciones (primer entregable técnico)

- [ ] **T-01** — Scaffold del repo `panel-cliente-api` (NestJS + TypeScript)
  - Archivos: estructura base NestJS (`src/main.ts`, `src/app.module.ts`), config de linter/formatter, `Dockerfile`, `.env.example`, `CLAUDE.md` (`/init`).
  - Ramas: `main`, `develop`, `pre-qa`, `qa` + `feature/panel-cliente-mvp`.
  - Criterio: `npm run start` levanta el servicio en local; healthcheck `GET /v1/health` responde 200.

- [ ] **T-02** — Scaffold del repo `panel-cliente-web` (Next.js + React) desplegable en Vercel
  - Archivos: proyecto Next.js base, config de entorno, `CLAUDE.md` (`/init`), integración con el design system de GV (provisto por GV, PRD §6).
  - Criterio: build de Vercel exitoso; página placeholder accesible por HTTPS.

- [ ] **T-03** — **Modelo de datos multi-tenant y de permisos** (MongoDB Atlas) — *primer entregable, con revisión de GV (mitigación de riesgo Alto)*
  - Archivos: `src/tenancy/schemas/organization.schema.ts`, `user.schema.ts`, `membership.schema.ts` (rol + scope Grupo/Marca/Sitio), `session.schema.ts`, `addon-config.schema.ts`, `access-log.schema.ts`.
  - Modela: jerarquía Grupo→Marca→Sitio, `sitesAccess`, roles (Group/Brand/Site/Viewer/SuperAdmin), herencia hacia abajo.
  - Criterio: modelo revisado y aprobado por el equipo de GV **antes** de continuar; cubre las estructuras reales de clientes (supuesto del PRD).

- [ ] **T-04** — Cliente de consumo de `govirtual-api`
  - Archivos: `src/govirtual/govirtual.client.ts`, `dto/` de respuesta (sitios, dealers, leads), manejo de errores/timeouts/reintentos.
  - Criterio: lectura de sitios por `site_id` funcionando contra ambiente de `govirtual-api`; endpoints consumidos quedan **versionados** de común acuerdo.

### Fase 1 — Autenticación y seguridad (RF-01–09, RNF-01/08)

- [ ] **T-05** — Login email/contraseña + hashing bcrypt (≥12 rounds)
  - Archivos: `src/auth/auth.module.ts`, `auth.controller.ts` (`POST v1/auth/login`), `auth.service.ts`, `password.service.ts`.
  - Criterio: login válido responde <500ms (RNF-01); contraseñas hasheadas con bcrypt ≥12; RF-01/RF-02.

- [ ] **T-06** — Emisión de JWT con claims y expiración configurable (default 8h)
  - Archivos: `src/auth/jwt.service.ts`, `jwt.strategy.ts`, config `JWT_EXPIRES_IN`.
  - Criterio: JWT incluye `userId`, `tenantId`, `role`, `sitesAccess`; expiración configurable; RF-03/RF-04.

- [ ] **T-07** — Recuperación de contraseña (token de un solo uso, 30 min)
  - Archivos: `src/auth/password-recovery.service.ts`, endpoints `POST v1/auth/forgot-password` y `POST v1/auth/reset-password`, plantilla de email.
  - Criterio: token de un solo uso, expira en 30 min; email llega <2 min (RNF-03); RF-05.

- [ ] **T-08** — Bloqueo por intentos fallidos (5 → 15 min)
  - Archivos: `auth.service.ts` (contador de intentos en el doc de usuario), lógica de desbloqueo temporal.
  - Criterio: al 5º intento fallido la cuenta se bloquea 15 min; RF-06.

- [ ] **T-09** — Logout con invalidación de JWT
  - Archivos: `auth.controller.ts` (`POST v1/auth/logout`), estrategia de invalidación (denylist en Mongo o rotación de `tokenVersion`).
  - Criterio: el JWT deja de ser válido tras logout; RF-07.

- [ ] **T-10** — Guard de scope multi-tenant (RNF-06)
  - Archivos: `src/common/guards/scope.guard.ts`, decorador `@RequiresSiteAccess()`.
  - Criterio: cualquier operación sobre un `site_id` fuera de `sitesAccess` responde 403; probado con llamada directa al endpoint.

### Fase 2 — Gestión de usuarios y endpoints del panel interno GV (RF-08/09, RF-31–36)

- [ ] **T-11** — CRUD de usuarios del portal (Super Admin GV)
  - Archivos: `src/admin/users.controller.ts` (`v1/admin/users` GET/POST/PATCH/DELETE), `users.service.ts`.
  - Criterio: crear/activar/desactivar/eliminar usuario; asignar rol, organización/marca(s) y sitios permitidos; RF-08/RF-32/RF-33.

- [ ] **T-12** — Alta de organizaciones (grupos) asociadas a dealers de `govirtual-api`
  - Archivos: `src/admin/organizations.controller.ts` (`v1/admin/organizations`), `organizations.service.ts`.
  - Criterio: crear organización y asociarla a dealers existentes; RF-31.

- [ ] **T-13** — Onboarding first-login (email de bienvenida + set password)
  - Archivos: `users.service.ts` (invitación), plantilla de email, flujo `set-password`.
  - Criterio: al crear usuario se envía email con link de configuración de contraseña; RF-09.

- [ ] **T-14** — Configuración de add-ons por cliente/organización
  - Archivos: `src/admin/addons.controller.ts` (`v1/admin/addons`), `addon-config` schema.
  - Criterio: activar/desactivar qué add-ons ve cada cliente; RF-34.

- [ ] **T-15** — Log de accesos + auth de la sección interna
  - Archivos: `src/admin/access-log.controller.ts` (`v1/admin/access-log`), middleware de registro de login/intentos fallidos.
  - Criterio: se ven último login e intentos fallidos por usuario; los endpoints internos usan el JWT interno de GV (RF-35/RF-36; RNF-12).

- [ ] **T-16** — Entrega de la **especificación de endpoints** de la Panel API para la sección Lovable
  - Archivos: `docs/panel-api-openapi.yaml` (o Swagger auto-generado).
  - Criterio: spec entregada al equipo interno de GV al inicio (mitigación de riesgo de contratos de API).

### Fase 3 — Dashboard de sitios (RF-10–17, RF-24)

- [ ] **T-17** — Endpoint de sitios del usuario (tiempo real desde `govirtual-api`)
  - Archivos: `src/sites/sites.controller.ts` (`GET v1/sites`), `sites.service.ts` (filtra por `sitesAccess` del JWT).
  - Criterio: devuelve solo los sitios en scope; oculta cancelados; RF-10/RF-14/RF-16.

- [ ] **T-18** — Grid de sitios en el frontend (tarjetas)
  - Archivos: `panel-cliente-web` — `app/dashboard/page.tsx`, `components/SiteCard.tsx`.
  - Criterio: cada tarjeta muestra nombre, marca, URL pública, estado, thumbnail/favicon; estados activo/inactivo/en construcción diferenciados visualmente; RF-11/RF-15.

- [ ] **T-19** — Filtro por marca + contador por marca (usuarios de grupo)
  - Archivos: `components/BrandFilter.tsx`, lógica de conteo.
  - Criterio: usuario multi-marca filtra por marca; usuario de grupo ve contador por marca; RF-12/RF-13.

- [ ] **T-20** — Buscador por nombre/URL
  - Archivos: `components/SiteSearch.tsx`.
  - Criterio: filtra en el dashboard por nombre o URL; RF-17.

- [ ] **T-21** — Diferenciación GRID vs BRICK en la tarjeta
  - Archivos: `components/SiteCard.tsx` (render condicional por `type`).
  - Criterio: GRID muestra botón "Editar en CMS"; BRICK solo lectura sin botón; RF-24.

### Fase 4 — SSO al editor Duda y a add-ons (RF-18–23, RF-25–30, RNF-04)

- [ ] **T-22** — Generación de SSO token a Duda (vía `govirtual-api` → Duda Partner API)
  - Archivos: `src/sso/duda-sso.controller.ts` (`POST v1/sso/duda`), `duda-sso.service.ts` (valida scope antes de solicitar).
  - Criterio: genera SSO solo para sitios en scope (RF-23); flujo end-to-end <3s (RNF-04); RF-18/RF-19/RF-21.

- [ ] **T-23** — Apertura de SSO Duda y manejo de error/reintento (frontend)
  - Archivos: `components/EditInCmsButton.tsx`.
  - Criterio: abre el editor en pestaña nueva; ante fallo muestra error con reintento; RF-20/RF-22.

- [ ] **T-24** — Sección "Herramientas" + SSO add-ons (Uberall, Cloud Campaign)
  - Archivos: `src/sso/addons-sso.controller.ts` (`POST v1/sso/addons/:addon`), `uberall-sso.service.ts`, `cloud-campaign-sso.service.ts`; frontend `components/ToolsSection.tsx`.
  - Criterio: solo add-ons contratados; SSO por tenant; fallback a link directo/instrucciones si no hay SSO; abre en pestaña nueva; RF-25–30.
  - ⚠️ Depende del discovery de proveedores (prerequisito).

### Fase 5 — Visualización de leads (CONDICIONAL — RF-37C–40C)

- [ ] **T-25** — Listado de leads últimos 30 días (condicional)
  - Archivos: `src/leads/leads.controller.ts` (`GET v1/leads`), consumo desde `govirtual-api` filtrado por dealers del usuario.
  - Criterio: lista fecha, prospecto, tipo de formulario, sitio de origen; filtros por fecha y sitio; sin exportación; datos sensibles solo Brand Admin+ (RNF-11); RF-37C–40C.
  - Nota: si el discovery no confirma viabilidad, esta fase pasa a Fase 2 sin cambio de especificación.

### Fase 6 — BI, hardening y QA de aceptación

- [ ] **T-26** — Eventos BI del MVP
  - Archivos: `src/bi/bi.service.ts` (emisión de eventos).
  - Criterio: se emiten `portal_login_exitoso`, `portal_login_fallido`, `portal_password_recovery_solicitado`, `sso_duda_generado`, `sso_addon_generado`, `lead_visualizado` con sus campos (PRD §11).

- [ ] **T-27** — Endurecimiento de seguridad y performance
  - Archivos: config de HTTPS-only, rate limiting en endpoints de auth (equivalente a política `Restrictive`), CORS restrictivo, paginación/lazy en leads.
  - Criterio: solo HTTPS (RNF-02); tasa de error login/SSO <1% (RNF-05); soporta concurrencia de 350 clientes sin degradar rate limit de Duda (RNF-10).

- [ ] **T-28** — QA de aceptación del MVP
  - Criterio: se cumplen todos los criterios de §10 con usuarios de distintos niveles de jerarquía y por tipo de sitio.

---

## 5. Cambios en base de datos

**MongoDB Atlas** — nueva colección/base del portal en el cluster existente (⚠️ no PostgreSQL; ver §12).

| Colección | Tipo | Descripción |
|---|---|---|
| `organizations` | Nueva | Grupos/marcas, asociación a dealers de `govirtual-api` |
| `users` | Nueva | Usuarios del portal: email, hash bcrypt, estado, `tokenVersion`, contador de intentos |
| `memberships` | Nueva | Rol + scope (Grupo/Marca/Sitio) + `sitesAccess` por usuario |
| `password_resets` | Nueva | Tokens de recuperación de un solo uso (TTL 30 min) |
| `addon_configs` | Nueva | Add-ons activos por organización |
| `access_logs` | Nueva | Últimos logins e intentos fallidos (RNF-12) |

> No se modifica el esquema de `govirtual-api` (fuera de alcance, PRD §6).

---

## 6. Endpoints nuevos o modificados (Panel API — MVP)

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `v1/auth/login` | Login email/contraseña → JWT | Nuevo |
| POST | `v1/auth/logout` | Invalidación de JWT | Nuevo |
| POST | `v1/auth/forgot-password` | Solicitud de recuperación | Nuevo |
| POST | `v1/auth/reset-password` | Reset con token de un solo uso | Nuevo |
| POST | `v1/auth/set-password` | First-login (onboarding) | Nuevo |
| GET | `v1/sites` | Sitios del usuario (scope JWT, tiempo real) | Nuevo |
| POST | `v1/sso/duda` | SSO token al editor Duda (GRID, valida scope) | Nuevo |
| POST | `v1/sso/addons/:addon` | SSO a Uberall / Cloud Campaign | Nuevo |
| GET | `v1/leads` | Leads 30 días (condicional) | Nuevo (condicional) |
| GET/POST/PATCH/DELETE | `v1/admin/users` | CRUD usuarios del portal | Nuevo |
| GET/POST | `v1/admin/organizations` | Alta/gestión de organizaciones | Nuevo |
| GET/POST | `v1/admin/addons` | Config de add-ons por cliente | Nuevo |
| GET | `v1/admin/access-log` | Log de accesos | Nuevo |
| GET | `v1/health` | Healthcheck | Nuevo |

> Diseño API-First: definir DTOs (Request/Response) y revisarlos antes de implementar (`coding-guidelines.md` §5). Versionado `v1/`, sustantivos en plural, kebab-case.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `MONGODB_URI` | Conexión al cluster Atlas existente (BD del portal) | Todos |
| `JWT_SECRET` | Secreto de firma del JWT | Todos |
| `JWT_EXPIRES_IN` | Expiración configurable (default `8h`) | Todos |
| `GOVIRTUAL_API_BASE_URL` / `GOVIRTUAL_API_KEY` | Consumo de `govirtual-api` | Todos |
| `DUDA_PARTNER_*` | Credenciales Duda Partner API (idealmente vía `govirtual-api`) | Todos |
| `UBERALL_API_KEY` / `CLOUD_CAMPAIGN_API_KEY` | SSO add-ons | Todos |
| `SMTP_*` | Proveedor de emails transaccionales | Todos |
| `CORS_ALLOWED_ORIGINS` | Orígenes permitidos (Panel Web) | Todos |

> Secrets nunca en el código — variables de entorno o AWS Secrets Manager (`coding-guidelines.md` §11, `infraestructura.md` §5).

---

## 8. Consideraciones de seguridad

- **Scope multi-tenant (RNF-06):** guard obligatorio que valida `sitesAccess` del JWT en todo endpoint de sitios/SSO/leads; herencia solo hacia abajo. Prueba de seguridad explícita: llamada directa con `site_id` no asignado → 403.
- **Contraseñas:** bcrypt ≥12 rounds; nunca en logs.
- **Tokens:** recuperación de un solo uso (30 min); JWT con expiración; invalidación en logout.
- **Rate limiting:** política restrictiva en endpoints de auth (mitiga fuerza bruta, complementa el bloqueo de 5 intentos).
- **Datos sensibles de leads:** visibles solo para Brand Admin o superior (RNF-11).
- **Transporte:** solo HTTPS (RNF-02); CORS restrictivo en producción.
- **Secrets:** variables de entorno / AWS Secrets Manager, nunca en el repo.
- **API keys de terceros:** restringidas por dominio/IP donde la plataforma lo permita (`infraestructura.md` §5).

---

## 9. Consideraciones de infraestructura

- **Infra AWS (alineada con `infraestructura.md`):** Panel API en **ECS + Fargate** (contenedor Docker); Panel Web en **AWS** (Amplify Hosting o S3 + CloudFront); **AWS S3** para assets; **MongoDB Atlas** (cluster existente, colección nueva) como BD del portal. Configurar monitoreo de facturación AWS (no hay tope automático).
- **Consola AWS:** desplegar en la consola de la empresa correspondiente (Go Virtual / la que defina TI); región según `infraestructura.md`.
- **Concurrencia (RNF-10):** validar que Duda Partner API soporta ~350 clientes concurrentes sin degradar rate limit; instrumentar métricas de `sso_duda_generado` (tiempo/errores).
- **Dominios/SSL/DNS:** `app.govirtual.com.mx` gestionado por GV (Cloudflare / Route 53); fuera de alcance del tercero (PRD §6).

---

## 10. Criterios de aceptación (MVP)

- [ ] > 60% de clientes activos con al menos 1 login en los primeros 30 días.
- [ ] SSO Duda end-to-end < 3 s (test de performance en producción).
- [ ] Tasa de error login/SSO < 1%.
- [ ] Un usuario ve **solo** los sitios de su scope (QA con múltiples niveles de jerarquía).
- [ ] Usuario GRID ve botón "Editar en CMS"; usuario BRICK ve tarjeta solo lectura sin botón.
- [ ] Un usuario **no** puede solicitar SSO de un sitio fuera de su scope (prueba de seguridad directa al endpoint).
- [ ] Super Admin GV crea un usuario desde el panel interno y lo asigna a una marca (QA de onboarding).
- [ ] La cuenta se bloquea tras 5 intentos fallidos.
- [ ] El email de recuperación llega en < 2 min.
- [ ] (Condicional) Si leads entra al MVP: el cliente ve sus leads de 30 días filtrados por sus dealers.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Uberall/Cloud Campaign sin SSO programático | Media | Alto | Discovery con proveedores antes de comprometer Fase 1; plan B: link directo + credenciales/instrucciones (RF-29). |
| Duda Partner API con límites de rate/permiso para 350 concurrentes | Media | Alto | Validar rate limit en discovery; `govirtual-api` ya usa `@dudadev/partner-api`; instrumentar métricas. |
| Modelo multi-tenant subestimado | Media | Alto | T-03 es el **primer entregable**, con revisión de GV antes de continuar. |
| Cambios en `govirtual-api` rompen la integración | Media | Medio | Versionar endpoints consumidos; coordinación entre equipos. |
| Divergencia de stack/infra vs defaults de Engine | Media | Medio | Confirmar explícitamente con líder técnico y Gerente de TI (ver §12). |
| Latencia de `govirtual-api` degrada el dashboard (si leads entra al MVP) | Baja | Medio | Paginación + carga lazy; definir SLA con el equipo de `govirtual-api`. |
| Onboarding de 350 clientes no estimado | Alta | Medio | Piloto de 20 clientes → rollout gradual. |

---

## 12. Notas para el programador

1. **Decisión de stack (confirmada por el responsable: NestJS + MongoDB + AWS).** El backend usa **NestJS** y la BD **MongoDB Atlas** —divergen del default Engine (.NET 8 + PostgreSQL)— para integrarse con `govirtual-api` (RNF-07/08/13); `stack.md` admite NestJS "para casos puntuales y justificados", y este lo es. La **infraestructura es AWS** (ECS/Fargate + S3), **alineada con `infraestructura.md`**. Matiz respecto al PRD: el PRD menciona Render/Vercel (RNF-09); por decisión del responsable se despliega en **AWS**. Pendiente menor a confirmar: hosting del frontend Next.js en AWS (Amplify vs S3+CloudFront) o Vercel.

2. **Convenciones de código:** `coding-guidelines.md` está orientado a .NET/C#. Se adaptan sus **principios** a NestJS: código y comentarios en **inglés**, API-First (DTOs antes de implementar), REST versionado `v1/`, sustantivos en plural, JWT `[Authorize]`-equivalente por guard, async/await, sin secrets en código, logging sin datos sensibles.

3. **Ramas:** proyecto nuevo → al crear los repos, inicializar `main`, `develop`, `pre-qa`, `qa` (obligatorias, `version-control.md`) y trabajar en `feature/panel-cliente-mvp` desde `develop`. Los PRs los gestiona el programador (Claude Code no crea PRs).

4. **Fuera de alcance del tercero (PRD §6):** UI de la sección interna Lovable (GV la construye; el tercero entrega la spec de endpoints, T-16), config de GA4/Search Console, workflows de Creatio, brand guidelines, infra de dominios/SSL/DNS.

5. **Leads condicional:** decidir en discovery si RF-37C–40C entran al MVP o se difieren a Fase 2 sin cambio de especificación.

6. **Renumeración de RF:** el PRD renumeró RF-01…RF-99; validar que no rompa referencias en la cotización con el tercero (pregunta abierta del PRD §14).

---

## 13. Resumen de Fase 2 — Autogestión (posterior al MVP)

> Complejidad media. Construcción incremental sobre el MVP. Detalle a expandir en su propio plan.

| Bloque | RF | Notas clave / dependencias |
|---|---|---|
| Edición de DealerInfo | RF-41–46 | Escritura vía Panel API → `govirtual-api` → sincronización con Duda (Content Library); log de cambios; campos no editables solo lectura; activable por Super Admin. **BRICK gana autogestión aquí.** |
| Tickets a Creatio | RF-47–53 | Creación/adjuntos (≤10MB)/historial/estado (polling o webhook). **Prerequisito:** acceso a Creatio API, schema de ticket y workflows (riesgo Alto; coordinar antes de iniciar). |
| Métricas (GA4 + Search Console) | RF-54–58 | Service Account de GV; rango de fechas; por sitio o consolidado; visualizaciones. **Prerequisito:** auditar que las propiedades GA4 estén bajo la cuenta de GV. |
| Leads completo | RF-59–64 | Detalle de lead, exportación CSV, filtros ampliados; datos sensibles solo Brand Admin+. |
| Banners/promociones | RF-65–72 | Imagen a S3 (≤5MB), vigencia, activación, validación de dimensiones por template (GV define), propagación vía sincronización; módulo activable por cliente. |
| Tutoriales y docs de API | RF-73–85 | **Prerequisito:** GV define el CMS de contenido (headless/Notion/Contentful/CRUD propio) antes de iniciar. Docs de API restringidas a Brand Admin+. |

**Habilitadores previos a Fase 2:** Creatio API + schema + workflows; auditoría GA4/Search Console; decisión de CMS de tutoriales; especificación de dimensiones de banners por template; bucket S3.

---

## 14. Resumen de Fase 3 — Expansión (posterior a Fase 2)

> Mayor complejidad. Detalle a expandir en su propio plan.

| Bloque | RF | Notas clave / dependencias |
|---|---|---|
| Catálogo de templates + solicitud de sitio | RF-86–88 | Preview visual; validación de URL disponible. |
| Auto-provisioning de sitios GRID | RF-89, RF-91–95 | Invoca `GridSitesWorkerService` existente en `govirtual-api`: crea sitio en Duda, aplica template, configura DealerInfo + External Collections, publica; estado en tiempo real; objetivo 2–4 h; aparición automática en dashboard. |
| Sitios no automatizables (BRICK/custom) | RF-90, RF-96 | Ticket en Creatio + notificación a GV; manejo de fallas del worker con alerta interna + mensaje al cliente. |
| Mejoras de autenticación | RF-97–99 | Google OAuth 2.0 (prioritario), Magic Link (media), Microsoft OAuth (baja, según demanda). |
| Integraciones de suite GV | — | Darwin AI, publicidad pagada (Google/Meta Ads) — mini-fases independientes, sin especificación detallada aún. |

**Métricas de éxito Fase 3:** >80% de sitios template autoprovisionados sin intervención manual; entrega promedio <4 h.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md` y `PRD.md`*
