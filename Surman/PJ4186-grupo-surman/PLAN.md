# Plan de Desarrollo — Surman Drive · MVP "La base" (Grupo Surman)

> Generado por Claude Code a partir del PRD `Surman/PJ4186-grupo-surman/PRD.md`.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Surman/PJ4186-grupo-surman/PRD.md` (v0.1 — 2026-07-30) |
| Repositorio | `surman-drive-web` (**a crear** — no existe repositorio previo) |
| Rama | `feature/PJ4186-grupo-surman-mvp-base` |
| Tipo | Proyecto nuevo |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | `PJ4186` |
| Fecha de generación | 2026-07-31 |
| Estado | Borrador |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |

**Alcance de este plan: únicamente el MVP "La base" (mes 0–3) — RF-01 a RF-11 del PRD, más RF-26 limitado a la capa Surman.**
Fase 1 ("La relación") y Fase 2 ("La transacción") del PRD quedan fuera de este plan: §3.1 y §14 del PRD las declaran planteamiento inicial sujeto a definición. Se planearán en documentos aparte cuando su alcance esté cerrado.

> ⚠️ **Proyecto nuevo — sin rama base previa.** No existe repositorio, por lo tanto no hay `develop` ni `main` de dónde partir. La Fase 0 crea el repositorio y la arquitectura de ramas completa de Engine (`main`, `develop`, `pre-qa`, `qa`) según `rules/version-control.md`. A partir de ese punto, la rama base es `develop` y la rama funcional es `feature/PJ4186-grupo-surman-mvp-base`.

---

## 1. Resumen técnico

Se construye la **capa Surman** de Surman Drive: una aplicación web **multi-sitio y multi-marca** (49 marcas, ~160 storefronts de agencia) sobre una sola infraestructura, que consume la **plataforma base de Go Virtual (BRICK)** vía API.

**Lo que este plan construye (capa Surman — transferible):**
- Frontend Next.js/React/TypeScript/Tailwind con resolución de storefront por marca y plaza.
- **BFF (Backend-for-Frontend)** como única frontera hacia la plataforma base: el navegador nunca habla directo con BRICK (RNF-04).
- Fichas de modelo (MRP), listados y fichas de unidad de inventario (nuevos y seminuevos), buscador con filtros, localizador de las ~160 agencias y calculadora de crédito orientativa.
- Formularios de lead prellenados con captura de la capa de campaña, y entrega del lead al motor de leads de la plataforma base + contexto a Biky.Ai.
- Módulo de contenido gestionable (blog, promociones, banners, landing pages por plaza) sobre PostgreSQL.
- Capa de medición **ASC sobre GA4** y SEO técnico + AEO (schema.org, URLs semánticas, sitemaps segmentados).
- Control de accesos por rol para la operación de la capa Surman.

**Lo que este plan NO construye (ya existe / se consume como servicio):**
- **Motor de inventarios** (ingesta de feeds, normalización, reglas de publicación) — ya existe en el backend de Go Virtual. Se consume vía API. RF-11 se cubre desde el consumo, la observabilidad y la degradación controlada, no desde la construcción del motor.
- **Motor de leads** (armado del ADF+JSON y enrutamiento a la agencia correcta entre ~160) — ya existe. RF-05 se cubre desde la entrega del lead al motor, no desde su construcción.
- CRM del grupo (Vicky) y Biky.Ai — sistemas de Surman/GV; solo se integran.

**Stack aplicado:**

| Capa | Tecnología | Justificación |
|---|---|---|
| Frontend | Next.js (App Router) + React + TypeScript + Tailwind | Fijado por el PRD (RNF-09, §3.2) para habilitar el co-desarrollo con Surman y la transferencia futura de la capa. `rules/stack.md`: proyecto nuevo → React. |
| BFF | Route Handlers de Next.js (TypeScript) | Es parte de la capa Surman transferible según §3.2 del PRD. **Desviación de `rules/stack.md` (backend nuevo → .NET Core 8) que requiere validación explícita — ver §12 y R-01.** |
| Base de datos | PostgreSQL (RDS) | `rules/stack.md`: default obligatorio. |
| Contenido | Payload CMS 3 embebido en la app Next.js, persistiendo en el mismo PostgreSQL | Cubre RF-10 en días en lugar de semanas dentro de la ventana de 3 meses, sin introducir otro motor de base de datos. **Decisión a validar — ver §12.** |
| Contenerización | Docker (Next.js standalone) | `rules/stack.md`. |
| Despliegue | ECS + Fargate detrás de ALB, con CloudFront como CDN | `rules/infraestructura.md`: todo servicio nuevo → contenedor en ECS + Fargate. CloudFront cubre RNF-02/RNF-03. |
| Medios | S3 + CloudFront | `rules/infraestructura.md`. |
| DNS | Cloudflare (dominios) + Route 53 (servicios AWS) | `rules/infraestructura.md`. |
| Secrets | AWS Secrets Manager + variables de entorno | `rules/coding-guidelines.md` §11. Nunca en código. |

**Arquitectura aplicable (`rules/arquitectura.md`):** *Frontend + Backend separados (Componentes)* del lado de la capa Surman — un contenedor de aplicación con su BFF y su PostgreSQL propio — consumiendo por REST los microservicios existentes de la plataforma base. No se justifica dividir la capa Surman en microservicios: sus dominios (catálogo, inventario, leads, contenido) comparten el mismo ciclo de despliegue y la mayor parte de la lógica de dominio vive en BRICK.

---

## 2. Prerequisitos

**Bloqueantes antes de iniciar la Fase 0:**
- [ ] PRD validado por el responsable y por Aldo Álvarez (revisión técnica, §13 del PRD).
- [ ] Definición del BFF resuelta: Route Handlers de Next.js vs. servicio .NET Core 8 separado (ver §12 y R-01).
- [ ] Consola AWS destino confirmada (Go Virtual) y región definida — `rules/infraestructura.md` no la documenta todavía.
- [ ] Permisos para crear repositorio en la organización de GitHub de Engine/Go Virtual.

**Bloqueantes antes de iniciar la Fase 1 (desarrollo de UI):**
- [ ] **Gate de diseño del PRD §3.3 aprobado**: diseño UX/UI en Figma + prototipo con visto bueno formal de Surman (marca/marketing y TI). Sin este visto bueno no arranca T-13 en adelante.
- [ ] Design tokens y biblioteca de componentes exportables desde Figma.

**Insumos de terceros requeridos (dependencias externas):**
- [ ] **Contratos de API de la plataforma base GV** documentados y estables: inventario normalizado (JSON), catálogo/fichas MRP, alta de lead (ADF+JSON), taxonomía de marcas y agencias. Con ambiente de pruebas y credenciales.
- [ ] Credenciales y contrato de integración con **Biky.Ai / CRM Vicky** (incluye alcance exacto de la bidireccionalidad — pregunta abierta del PRD §14).
- [ ] **Catálogo maestro de las 49 marcas** y **directorio de las ~160 agencias** (nombre, dirección, CP, geo, teléfono, WhatsApp propio, horarios, marcas que atiende).
- [ ] Parámetros de la calculadora de crédito: tasas, plazos, enganche mínimo y disclaimer legal aprobado.
- [ ] Propiedad **GA4** y contenedor **GTM** de Surman, con el diccionario de eventos ASC validado por Data World.
- [ ] Inventario de URLs del sitio corporativo actual para el mapa de redirecciones 301.
- [ ] Aviso de privacidad y política de cookies aprobados (LFPDPPP).
- [ ] `CLAUDE.md` en el repositorio (se genera con `/init` en T-03).

---

## 3. Arquitectura del cambio

```
                            Cloudflare (DNS)
                                   │
                            CloudFront (CDN global)
                                   │
                                  ALB
                                   │
        ┌──────────────── ECS + Fargate ────────────────┐
        │      Aplicación Next.js (capa Surman)         │
        │  ┌─────────────────────────────────────────┐  │
        │  │ Frontend RSC/ISR  ·  Payload CMS admin  │  │
        │  ├─────────────────────────────────────────┤  │
        │  │      BFF (Route Handlers) ── FRONTERA   │  │
        │  └─────────────────────────────────────────┘  │
        └───────┬──────────────────┬────────────────────┘
                │                  │
       RDS PostgreSQL          S3 + CloudFront
    (contenido, agencias,        (medios)
     storefronts, bitácora
     de leads, roles)
                │
    ════════════╪═══════ frontera técnica (§3.2 del PRD) ═══════════
                │
                ▼
     Plataforma base Go Virtual — BRICK  (servicio gestionado, ya existe)
     ├── Motor de inventarios  → inventario normalizado (JSON)
     ├── Motor de leads        → arma ADF+JSON y enruta a la agencia correcta
     ├── Base central de contenidos de marcas → fichas MRP
     └── CDP / reglas de negocio
                │
                ├──► CRM del grupo (Vicky) ──► Asesor humano cierra
                └──► Biky.Ai (continuidad conversacional)

     GA4 + GTM  ◄── eventos ASC (cliente) y eventos de negocio (servidor)
```

**Regla de frontera:** todo lo que está arriba del BFF es capa Surman (transferible, co-desarrollable). El BFF es el único componente que habla con BRICK, usando JWT servicio-a-servicio. Ningún secreto ni endpoint de la plataforma base se expone al navegador (RNF-04).

**Estrategia de frescura de datos (RNF-13):** ISR con revalidación de ~120 s para catálogo, fichas MRP e inventario, más revalidación *on-demand* vía webhook cuando la plataforma base o el CMS notifican un cambio. Ante feed inválido o plataforma no disponible, se sirve el último snapshot válido y se alerta; **nunca se publican datos corruptos** (RNF-14).

---

## 4. Tareas de desarrollo

Prioridades: **P1** = indispensable para el go-live del MVP · **P2** = importante, recortable a post-go-live · **P3** = deseable.

### Fase 0 — Cimentación, contratos y entorno (P1)

- [ ] **T-01** — Crear el repositorio y la arquitectura de ramas de Engine
  - Archivos a crear/modificar: `.gitignore`, `README.md`, `.github/CODEOWNERS`
  - Criterio de completitud: repositorio `surman-drive-web` creado con `main`, `develop`, `pre-qa`, `qa`; protección de `main` con 2 aprobaciones; rama `feature/PJ4186-grupo-surman-mvp-base` creada desde `develop` y publicada.

- [ ] **T-02** — Scaffolding de la aplicación Next.js + TypeScript + Tailwind
  - Archivos a crear/modificar: `package.json`, `tsconfig.json`, `next.config.ts`, `tailwind.config.ts`, `eslint.config.mjs`, `.prettierrc`, `src/app/layout.tsx`, `src/app/page.tsx`
  - Criterio de completitud: `npm run build` y `npm run lint` pasan en limpio; estructura de carpetas documentada (`src/app`, `src/components`, `src/lib`, `src/server`, `src/types`).

- [ ] **T-03** — Generar `CLAUDE.md` y convenciones del repositorio
  - Archivos a crear/modificar: `CLAUDE.md`, `docs/CONVENTIONS.md`
  - Criterio de completitud: `/init` ejecutado; `CLAUDE.md` describe stack, estructura, comandos y la frontera del BFF; convenciones alineadas con `rules/coding-guidelines.md` (código e identificadores en inglés).

- [ ] **T-04** — Dockerizar la aplicación y levantar el entorno local
  - Archivos a crear/modificar: `Dockerfile`, `.dockerignore`, `docker-compose.yml`, `.env.example`
  - Criterio de completitud: build multi-stage con salida `standalone`; `docker compose up` levanta app + PostgreSQL y responde en local.

- [ ] **T-05** — Provisionar la infraestructura AWS del ambiente de desarrollo
  - Archivos a crear/modificar: `infra/` (IaC), `docs/INFRA.md`
  - Criterio de completitud: ECR, cluster ECS + servicio Fargate, ALB, RDS PostgreSQL, bucket S3 de medios, distribución CloudFront y registro DNS operativos en dev; **alarma de facturación configurada** (`rules/infraestructura.md` §5).

- [ ] **T-06** — Pipeline CI/CD hacia ECS
  - Archivos a crear/modificar: `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`
  - Criterio de completitud: en cada PR corre lint + type-check + pruebas; merge a `develop` despliega a dev y a `qa` despliega a QA, con imagen etiquetada por commit y rollback documentado.

- [ ] **T-07** — Configuración y gestión de secretos por ambiente
  - Archivos a crear/modificar: `src/lib/env.ts`, `infra/secrets/`, `.env.example`
  - Criterio de completitud: esquema de variables validado en el arranque (falla rápido si falta una); secretos leídos de AWS Secrets Manager; **cero secretos en el repositorio** verificado con escaneo.

- [ ] **T-08** — Formalizar y tipar los contratos con la plataforma base GV
  - Archivos a crear/modificar: `src/types/platform/*.ts`, `docs/API-CONTRACTS.md`, `src/mocks/platform/*`
  - Criterio de completitud: contratos versionados de inventario normalizado, catálogo/MRP, alta de lead (ADF+JSON) y taxonomía marcas/agencias; tipos TypeScript y mocks que permiten desarrollar sin dependencia del ambiente de GV; pruebas de contrato en CI.

- [ ] **T-09** — Cliente HTTP del BFF hacia la plataforma base
  - Archivos a crear/modificar: `src/server/platform/client.ts`, `src/server/platform/auth.ts`, `src/server/platform/resilience.ts`
  - Criterio de completitud: JWT servicio-a-servicio con renovación automática, timeouts, reintentos con backoff exponencial, circuit breaker y `correlationId` propagado en logs; cubierto con pruebas unitarias.

- [ ] **T-10** — Observabilidad base
  - Archivos a crear/modificar: `src/lib/logger.ts`, `src/app/healthz/route.ts`, `src/app/readyz/route.ts`, `infra/monitoring/`
  - Criterio de completitud: logs estructurados sin datos personales ni tokens (`rules/coding-guidelines.md` §9); `/healthz` y `/readyz` consumidos por el target group del ALB; dashboard CloudWatch y alarmas de error rate, latencia y fallo de integraciones (RNF-10).

### Fase 1 — Núcleo multi-sitio, marcas y fichas MRP (P1)

> Arranca únicamente tras el visto bueno del diseño (gate del PRD §3.3).

- [ ] **T-11** — Modelo de tenancy y resolución de storefront
  - Archivos a crear/modificar: `src/middleware.ts`, `src/server/tenancy/resolver.ts`, `src/server/tenancy/context.ts`
  - Criterio de completitud: una sola infraestructura resuelve marca y plaza por host y/o ruta para las 49 marcas y ~160 storefronts; contexto de tenant disponible en servidor; **aislamiento verificado** — ninguna consulta devuelve datos de otro tenant (RNF-05, RNF-12).

- [ ] **T-12** — Esquema de base de datos de la capa Surman
  - Archivos a crear/modificar: `src/server/db/schema/*.ts`, `migrations/0001_init.sql`
  - Criterio de completitud: tablas de §5 creadas con migración versionada y reversible; índices de consulta por marca+ciudad y por slug; migración aplicada en dev y QA.

- [ ] **T-13** — Design system base a la identidad de Surman
  - Archivos a crear/modificar: `src/styles/tokens.css`, `tailwind.config.ts`, `src/components/ui/*`
  - Criterio de completitud: tokens (color, tipografía, espaciado, radios) derivados del Figma aprobado; primitivos (botón, input, select, card, modal, tabs, badge, breadcrumb) con estados y variantes; catálogo de componentes navegable.

- [ ] **T-14** — Layout global, navegación multi-marca y páginas de sistema
  - Archivos a crear/modificar: `src/app/layout.tsx`, `src/components/layout/*`, `src/app/not-found.tsx`, `src/app/error.tsx`
  - Criterio de completitud: header con navegación por marca y plaza, footer corporativo, breadcrumbs, 404 y 500 con contenido útil; navegación operativa en móvil y escritorio.

- [ ] **T-15** — Home corporativa de Grupo Surman y páginas de marca
  - Archivos a crear/modificar: `src/app/(site)/page.tsx`, `src/app/(site)/[brand]/page.tsx`, `src/server/catalog/brands.ts`
  - Criterio de completitud: home corporativa y las 49 páginas de marca se generan dinámicamente desde la base central de contenidos; sin páginas hardcodeadas por marca; ISR activo.

- [ ] **T-16** — Fichas de modelo (MRP) dinámicas — **RF-01**
  - Archivos a crear/modificar: `src/app/(site)/[brand]/[model]/page.tsx`, `src/components/mrp/*`, `src/server/catalog/models.ts`
  - Criterio de completitud: precio, versiones y especificaciones se leen de la plataforma base y nunca se capturan a mano; selector de versión/color; galería; CTA de lead que hereda el contexto del vehículo; revalidación ~120 s verificada.

- [ ] **T-17** — Páginas dinámicas por marca/ciudad e índices de navegación — **RF-01, RF-09**
  - Archivos a crear/modificar: `src/app/(site)/[brand]/[city]/page.tsx`, `src/server/catalog/taxonomy.ts`
  - Criterio de completitud: combinaciones marca × plaza generadas dinámicamente con URLs semánticas e indexables, contenido diferenciado por plaza y sin páginas huérfanas ni duplicadas.

- [ ] **T-18** — Localizador de la red de ~160 agencias — **RF-03**
  - Archivos a crear/modificar: `src/app/(site)/agencias/page.tsx`, `src/app/(site)/agencias/[dealer]/page.tsx`, `src/components/dealers/*`
  - Criterio de completitud: listado y mapa con filtros por marca, estado y ciudad; búsqueda por CP; ficha de agencia con **WhatsApp propio de esa agencia**, teléfono, horarios y formulario; las ~160 agencias cargadas y verificadas.

### Fase 2 — Inventario, buscador y calculadora (P1)

- [ ] **T-19** — Consumo del inventario normalizado (nuevos y seminuevos) — **RF-02, RF-11**
  - Archivos a crear/modificar: `src/server/inventory/repository.ts`, `src/server/inventory/cache.ts`, `src/app/api/v1/inventory/route.ts`
  - Criterio de completitud: el BFF expone inventario por agencia y ciudad desde el motor existente; snapshot de respaldo en PostgreSQL; revalidación on-demand por webhook; **cero captura manual de unidades**.

- [ ] **T-20** — Listado de inventario con filtros y ordenamiento — **RF-02**
  - Archivos a crear/modificar: `src/app/(site)/inventario/page.tsx`, `src/components/inventory/filters/*`
  - Criterio de completitud: filtros por marca, modelo, año, rango de precio, ciudad, agencia y condición (nuevo/seminuevo); ordenamiento y paginación; estado de filtros reflejado en URL indexable y compartible.

- [ ] **T-21** — Ficha de unidad de inventario — **RF-02, RF-04**
  - Archivos a crear/modificar: `src/app/(site)/inventario/[stockId]/page.tsx`, `src/components/inventory/detail/*`
  - Criterio de completitud: identificador de stock, agencia, precio y galería; distinción explícita respecto de la ficha MRP; CTA de lead prellenado con la unidad; manejo correcto de unidad vendida o retirada del feed.

- [ ] **T-22** — Buscador global — **RF-02**
  - Archivos a crear/modificar: `src/app/(site)/buscar/page.tsx`, `src/server/search/*`
  - Criterio de completitud: búsqueda por marca, modelo, versión, agencia y ciudad con sugerencias; tolerancia a errores de tecleo; resultados relevantes en menos de 500 ms sobre el catálogo completo.

- [ ] **T-23** — Calculadora de crédito — **RF-07**
  - Archivos a crear/modificar: `src/app/api/v1/credit-quotes/route.ts`, `src/components/credit-calculator/*`, `src/server/credit/calculator.ts`
  - Criterio de completitud: se alimenta del precio real de la unidad; enganche, plazo y tasa parametrizados desde configuración (no hardcodeados); devuelve mensualidad **orientativa** con disclaimer visible; **no ejecuta ni simula autorización alguna**; CTA que convierte a lead.

- [ ] **T-24** — Degradación controlada ante fallos de datos — **RNF-13, RNF-14**
  - Archivos a crear/modificar: `src/server/inventory/fallback.ts`, `src/server/platform/errors.ts`, `infra/monitoring/alerts.tf`
  - Criterio de completitud: ante feed inválido o plataforma no disponible se sirve el último snapshot válido o se oculta la sección, **nunca datos corruptos**; el error queda registrado y dispara alerta; comportamiento probado con inyección de fallos.

### Fase 3 — Captación y enrutamiento de leads e integraciones (P1)

- [ ] **T-25** — Formularios de lead prellenados — **RF-04**
  - Archivos a crear/modificar: `src/components/leads/LeadForm.tsx`, `src/server/leads/validation.ts`
  - Criterio de completitud: el formulario hereda marca, modelo, versión, unidad y agencia del contexto donde el usuario está, **sin pedir recaptura**; validación en cliente y servidor; protección anti-spam (rate limit + captcha invisible); accesible por teclado y lector de pantalla.

- [ ] **T-26** — Captura y persistencia de la capa de campaña — **RF-05, RF-08**
  - Archivos a crear/modificar: `src/lib/attribution.ts`, `src/middleware.ts`
  - Criterio de completitud: UTMs, `gclid`/`fbclid`, referrer, landing de entrada e identificador de sesión se capturan en el primer contacto y sobreviven la navegación completa hasta el envío del lead; verificado en un recorrido multipágina.

- [ ] **T-27** — Endpoint de creación de lead en el BFF — **RF-05**
  - Archivos a crear/modificar: `src/app/api/v1/leads/route.ts`, `src/server/leads/dispatcher.ts`, `src/server/leads/mapper.ts`
  - Criterio de completitud: el BFF arma la carga con prospecto + vehículo + campaña y la entrega al motor de leads existente en formato ADF+JSON; llave de idempotencia que evita duplicados por doble envío; respuesta al usuario en menos de 2 s independientemente de la latencia del CRM.

- [ ] **T-28** — Resiliencia y bitácora de entrega de leads — **RNF-06, RNF-14**
  - Archivos a crear/modificar: `src/server/leads/outbox.ts`, `src/server/leads/retry.ts`, `migrations/0002_lead_log.sql`
  - Criterio de completitud: todo lead se persiste en bitácora antes de intentar la entrega; reintentos con backoff ante fallo del motor o del CRM; alerta al superar el umbral de reintentos; **ningún lead se pierde ante caída del CRM** (probado con el destino apagado).

- [ ] **T-29** — Integración con Biky.Ai / CRM Vicky — **RF-06**
  - Archivos a crear/modificar: `src/server/biky/client.ts`, `src/app/api/v1/biky/webhook/route.ts`
  - Criterio de completitud: Biky.Ai recibe el lead con contexto completo y continúa la conversación; webhook entrante autenticado y validado; conversación trazable contra el lead original; probado punta a punta en QA con el ambiente de Surman.

- [ ] **T-30** — Cierre del flujo hacia el usuario y trazabilidad — **RF-03, RF-06**
  - Archivos a crear/modificar: `src/app/(site)/gracias/page.tsx`, `src/components/leads/LeadConfirmation.tsx`
  - Criterio de completitud: confirmación con expectativa de contacto y acceso directo al WhatsApp de la agencia asignada; el lead queda consultable en la bitácora con su agencia destino, campaña y estado de entrega.

### Fase 4 — Contenido gestionable y accesos (P2)

- [ ] **T-31** — Módulo de contenido sobre PostgreSQL — **RF-10**
  - Archivos a crear/modificar: `src/payload.config.ts`, `src/collections/*`, `migrations/0003_content.sql`
  - Criterio de completitud: colecciones de blog, promociones, banners y landing pages con campos por marca y plaza, versionado y borradores; persistencia en el mismo PostgreSQL; panel de administración accesible solo autenticado.

- [ ] **T-32** — Renderizado de contenido por marca y plaza — **RF-10**
  - Archivos a crear/modificar: `src/app/(site)/blog/**`, `src/app/(site)/promociones/**`, `src/components/content/*`, `src/app/api/v1/revalidate/route.ts`
  - Criterio de completitud: blog, promociones y banners se muestran segmentados por marca y plaza; publicar en el CMS refleja el cambio en el sitio en menos de un minuto vía revalidación on-demand.

- [ ] **T-33** — Constructor de landing pages de campaña — **RF-10**
  - Archivos a crear/modificar: `src/collections/LandingPages.ts`, `src/components/blocks/*`, `src/app/(site)/lp/[slug]/page.tsx`
  - Criterio de completitud: marketing arma una landing por plaza con bloques reutilizables (hero, galería, beneficios, unidades destacadas, formulario de lead) **sin intervención de desarrollo**; la landing hereda campaña y medición.

- [ ] **T-34** — Gestión y optimización de medios — **RNF-02**
  - Archivos a crear/modificar: `src/lib/media.ts`, `next.config.ts`, `infra/s3-media.tf`
  - Criterio de completitud: subidas del CMS almacenadas en S3 y servidas por CloudFront; imágenes servidas en formato moderno y tamaño responsivo; peso de imagen no degrada el objetivo de Core Web Vitals.

- [ ] **T-35** — Control de accesos por rol sobre la capa Surman — **RF-26, RNF-07**
  - Archivos a crear/modificar: `src/server/auth/*`, `src/collections/Users.ts`, `migrations/0004_roles.sql`
  - Criterio de completitud: roles diferenciados (marketing Surman, TI Surman, operación GV, administrador) con permisos granulares por colección, marca y plaza; intento de acción fuera de permiso devuelve 403 y queda auditado.

- [ ] **T-36** — Documentación de operación y handover de la capa Surman — **§3.2 del PRD** (P3)
  - Archivos a crear/modificar: `docs/OPERATION-GUIDE.md`, `docs/HANDOVER.md`
  - Criterio de completitud: guía operativa del CMS, storefronts y roles, más documentación técnica que permite a Surman co-desarrollar la capa (arquitectura, contratos, ambientes, despliegue); validada en una sesión con el equipo de Surman.

### Fase 5 — Medición ASC, SEO/AEO y performance (P1)

- [ ] **T-37** — Capa de analítica y consentimiento — **RF-08**
  - Archivos a crear/modificar: `src/lib/analytics/gtm.ts`, `src/lib/analytics/dataLayer.ts`, `src/components/consent/*`
  - Criterio de completitud: GTM instalado sin degradar el FCP; `dataLayer` tipado en TypeScript; identificador de sesión estable; banner de consentimiento que condiciona la medición no esencial.

- [ ] **T-38** — Eventos ASC sobre GA4 — **RF-08, §11 del PRD**
  - Archivos a crear/modificar: `src/lib/analytics/asc-events.ts`, `src/components/**` (instrumentación)
  - Criterio de completitud: los ocho eventos ASC (`asc_pageview`, `asc_menu_interaction`, `asc_special_offer`, `asc_element_configuration`, `asc_media_interaction`, `asc_retail_process`, `asc_cta_interaction`, `asc_form_engagement`) emitidos con los campos mínimos del PRD §11 (fecha/hora, usuario/sesión, marca, modelo, agencia/ciudad, campaña, resultado y motivo); nomenclatura conforme al estándar ASC.

- [ ] **T-39** — Eventos de negocio del MVP — **RF-08**
  - Archivos a crear/modificar: `src/lib/analytics/business-events.ts`, `src/server/analytics/server-events.ts`
  - Criterio de completitud: `lead_generado`, `lead_enrutado` y `calculadora_credito_usada` emitidos con su contexto; `lead_enrutado` se dispara del lado servidor con la agencia real de destino, no con la supuesta.

- [ ] **T-40** — Validación de la medición con Data World Surman — **§12 del PRD**
  - Archivos a crear/modificar: `docs/EVENT-DICTIONARY.md`
  - Criterio de completitud: diccionario de eventos publicado; recorrido completo validado en GA4 DebugView y aprobado por el equipo de Data de Surman; **línea base del programa existiendo desde el día uno**.

- [ ] **T-41** — SEO técnico y migración de URLs — **RF-09, RNF-11**
  - Archivos a crear/modificar: `src/app/sitemap.ts`, `src/app/robots.ts`, `src/lib/seo/metadata.ts`, `migrations/0005_redirects.sql`, `src/middleware.ts`
  - Criterio de completitud: URLs semánticas, canónicals correctos y sitemaps segmentados por marca y ciudad dentro de los límites de tamaño; mapa de redirecciones 301 del sitio actual cargado y verificado; cero errores de rastreo en la auditoría previa al go-live.

- [ ] **T-42** — Datos estructurados schema.org — **RF-09, RNF-11**
  - Archivos a crear/modificar: `src/lib/seo/structured-data/*.ts`
  - Criterio de completitud: `Organization`, `AutoDealer` (por agencia), `Car`/`Vehicle` y `Offer` (fichas MRP y unidades), `BreadcrumbList`, `FAQPage` y `BlogPosting` emitidos y **validados sin errores** en la herramienta de resultados enriquecidos de Google.

- [ ] **T-43** — AEO: visibilidad en motores de IA — **RF-09, RNF-11** (P2)
  - Archivos a crear/modificar: `src/app/llms.txt/route.ts`, `src/app/robots.ts`, `src/lib/seo/aeo.ts`
  - Criterio de completitud: contenido citable con respuestas directas y datos estructurados consistentes; `llms.txt` publicado; política explícita de rastreo para agentes de IA (GPTBot, PerplexityBot, ClaudeBot) alineada con la decisión de Surman; contenido accesible sin JavaScript.

- [ ] **T-44** — Presupuesto de rendimiento y Core Web Vitals — **RNF-02, RNF-03**
  - Archivos a crear/modificar: `lighthouserc.json`, `.github/workflows/ci.yml`, `next.config.ts`
  - Criterio de completitud: FCP ~0.8 s y Core Web Vitals en verde en móvil sobre las plantillas críticas (home, marca, ficha MRP, listado de inventario, ficha de unidad); presupuesto de rendimiento verificado por Lighthouse CI que **bloquea el merge** si se degrada.

### Fase 6 — QA, hardening y go-live (P1)

- [ ] **T-45** — Suite de pruebas automatizadas
  - Archivos a crear/modificar: `tests/unit/**`, `tests/contract/**`, `tests/e2e/**`, `playwright.config.ts`
  - Criterio de completitud: unitarias sobre BFF, calculadora, atribución y mapeo de leads; pruebas de contrato contra los mocks de la plataforma base; E2E de los flujos críticos (explorar → ficha → lead enviado; buscar inventario → calculadora → lead; localizar agencia → WhatsApp); suite verde en CI.

- [ ] **T-46** — Hardening de seguridad — **RNF-04, RNF-05**
  - Archivos a crear/modificar: `src/middleware.ts`, `next.config.ts`, `infra/waf.tf`
  - Criterio de completitud: HTTPS/TLS end-to-end, HSTS, CSP, `X-Content-Type-Options` y `Referrer-Policy`; CORS restrictivo; rate limiting en endpoints de escritura; WAF y protección DDoS activos; revisión de aislamiento multi-tenant sin fugas; escaneo de dependencias sin vulnerabilidades altas.

- [ ] **T-47** — Accesibilidad y compatibilidad
  - Archivos a crear/modificar: `tests/a11y/**`, `src/components/**`
  - Criterio de completitud: navegación por teclado, contraste, etiquetas y foco correctos en plantillas críticas; auditoría automatizada sin violaciones críticas; verificado en móvil iOS/Android y en los navegadores de escritorio vigentes.

- [ ] **T-48** — Carga y verificación de datos en QA
  - Archivos a crear/modificar: `scripts/seed/brands.ts`, `scripts/seed/dealers.ts`, `docs/QA-CHECKLIST.md`
  - Criterio de completitud: las 49 marcas y las ~160 agencias cargadas y revisadas una por una (WhatsApp, teléfono, dirección, marcas atendidas); paridad de contenido con el sitio actual confirmada por marketing Surman; inventario real fluyendo desde los feeds.

- [ ] **T-49** — Pruebas de carga de picos de campaña — **RNF-03** (P2)
  - Archivos a crear/modificar: `tests/load/campaign-spike.js`, `docs/CAPACITY.md`
  - Criterio de completitud: escenario de pico de campaña ejecutado sin degradar latencia ni disparar errores; política de autoscaling de ECS ajustada; costo por escenario documentado y dentro de lo previsto.

- [ ] **T-50** — Privacidad y cumplimiento LFPDPPP — **RNF-08**
  - Archivos a crear/modificar: `src/app/(site)/privacidad/page.tsx`, `src/app/(site)/cookies/page.tsx`, `src/components/leads/LeadForm.tsx`
  - Criterio de completitud: aviso de privacidad y política de cookies publicados; consentimiento explícito y registrado en cada formulario; política de retención de la bitácora de leads definida; sin datos personales en logs.

- [ ] **T-51** — Go-live
  - Archivos a crear/modificar: `docs/GO-LIVE-RUNBOOK.md`, `infra/dns/`
  - Criterio de completitud: despliegue a producción con imagen versionada y etiqueta semántica en `main`; cutover de DNS ejecutado con plan de rollback probado; redirecciones 301 activas; monitoreo y alertas verificados en producción; sitio sirviendo las 49 marcas y ~160 agencias.

- [ ] **T-52** — Estabilización post go-live y traspaso operativo
  - Archivos a crear/modificar: `docs/POST-LAUNCH-LOG.md`
  - Criterio de completitud: dos semanas de seguimiento con incidencias resueltas; métricas de leads, inventario publicado y Core Web Vitals reportadas contra la línea base; operación de contenido en manos del equipo de Surman.

---

## 5. Cambios en base de datos

Base de datos nueva (PostgreSQL en RDS) exclusiva de la capa Surman. **No se replica el inventario ni el catálogo como sistema de registro** — la fuente de verdad sigue siendo la plataforma base; solo se guardan snapshots de respaldo.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `brands` | Nueva | Catálogo local de las 49 marcas: slug, nombre, tipo (auto/moto/llanta), identidad visual, referencia al catálogo de la plataforma base. |
| `dealers` | Nueva | ~160 agencias: nombre, dirección, CP, coordenadas, teléfono, **WhatsApp propio**, horarios, estado y ciudad. |
| `dealer_brands` | Nueva | Relación N:N de qué marcas atiende cada agencia. |
| `storefronts` | Nueva | Configuración de cada storefront (marca y/o plaza): host, tema, módulos activos, metadatos. |
| `content_pages` | Nueva | Páginas editoriales y landing pages de campaña con bloques, versionado y estado de publicación. |
| `blog_posts` | Nueva | Entradas de blog con autoría, categorías, marca/plaza y SEO. |
| `promotions` | Nueva | Promociones por marca y plaza con vigencia. |
| `banners` | Nueva | Banners por ubicación, marca, plaza y vigencia. |
| `media_assets` | Nueva | Metadatos de medios almacenados en S3. |
| `lead_submissions` | Nueva | Bitácora de leads: prospecto, vehículo, campaña, agencia destino, estado de entrega (RNF-06). |
| `lead_delivery_attempts` | Nueva | Intentos de entrega al motor de leads y a Biky.Ai con resultado y error. |
| `inventory_snapshots` | Nueva | Último snapshot válido del inventario normalizado por agencia, para degradación controlada (RNF-14). |
| `redirects` | Nueva | Mapa de redirecciones 301 del sitio corporativo actual. |
| `users` / `roles` / `role_permissions` | Nuevas | Control de accesos por rol sobre la capa Surman (RF-26, RNF-07). |
| `audit_log` | Nueva | Auditoría de cambios en contenido, configuración y permisos (RNF-06). |
| Índices | Nuevos | `dealers(state, city)`, `dealers` geoespacial, `dealer_brands(brand_id)`, `content_pages(slug, storefront_id)`, `lead_submissions(created_at, dealer_id, campaign)`, `redirects(source_path)`. |

---

## 6. Endpoints nuevos o modificados

Todos son endpoints del **BFF de la capa Surman**. Convención de rutas según `rules/coding-guidelines.md` §5: sustantivos en plural, versionado `v1`, kebab-case.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/api/v1/brands` | Catálogo de marcas y su taxonomía. | Nuevo |
| GET | `/api/v1/models/{brand}/{model}` | Ficha MRP: precio, versiones y especificaciones. | Nuevo |
| GET | `/api/v1/inventory` | Inventario normalizado con filtros, orden y paginación. | Nuevo |
| GET | `/api/v1/inventory/{stockId}` | Detalle de una unidad de inventario. | Nuevo |
| GET | `/api/v1/dealers` | Localizador de agencias con filtros por marca, estado, ciudad y CP. | Nuevo |
| GET | `/api/v1/dealers/{dealerId}` | Ficha de agencia con contacto y WhatsApp propio. | Nuevo |
| POST | `/api/v1/credit-quotes` | Mensualidad orientativa; sin autorización ni compromiso. | Nuevo |
| POST | `/api/v1/leads` | Alta de lead con prospecto, vehículo y campaña; entrega al motor de leads. | Nuevo |
| GET | `/api/v1/search` | Buscador global con sugerencias. | Nuevo |
| POST | `/api/v1/biky/webhook` | Recepción de eventos de continuidad conversacional de Biky.Ai. | Nuevo |
| POST | `/api/v1/revalidate` | Revalidación on-demand disparada por la plataforma base o el CMS. | Nuevo |
| GET | `/healthz` · `/readyz` | Health y readiness para el target group del ALB. | Nuevo |

Códigos de estado según `rules/coding-guidelines.md` §5: `200` consulta, `201` alta de lead, `400` validación, `401`/`403` acceso, `404` recurso inexistente, `409` lead duplicado por idempotencia, `429` rate limit, `502` fallo de la plataforma base o del CRM.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `NODE_ENV` / `APP_ENV` | Entorno de ejecución. | Desarrollo / QA / Producción |
| `NEXT_PUBLIC_SITE_URL` | URL pública base del sitio. | Desarrollo / QA / Producción |
| `DATABASE_URL` | Conexión a RDS PostgreSQL. **Secrets Manager.** | Desarrollo / QA / Producción |
| `GV_PLATFORM_BASE_URL` | Base de la API de la plataforma base (BRICK). | Desarrollo / QA / Producción |
| `GV_PLATFORM_CLIENT_ID` | Identificador de cliente para JWT servicio-a-servicio. | Desarrollo / QA / Producción |
| `GV_PLATFORM_CLIENT_SECRET` | Secreto de cliente. **Secrets Manager.** | Desarrollo / QA / Producción |
| `GV_INVENTORY_ENDPOINT` | Ruta del inventario normalizado. | Desarrollo / QA / Producción |
| `GV_LEADS_ENDPOINT` | Ruta de alta de lead (ADF+JSON). | Desarrollo / QA / Producción |
| `BIKY_API_BASE_URL` | Base de la API de Biky.Ai. | Desarrollo / QA / Producción |
| `BIKY_API_KEY` | Credencial de Biky.Ai. **Secrets Manager.** | Desarrollo / QA / Producción |
| `BIKY_WEBHOOK_SECRET` | Secreto de validación del webhook entrante. **Secrets Manager.** | Desarrollo / QA / Producción |
| `PAYLOAD_SECRET` | Clave de firma del CMS. **Secrets Manager.** | Desarrollo / QA / Producción |
| `REVALIDATE_SECRET` | Token del endpoint de revalidación on-demand. **Secrets Manager.** | Desarrollo / QA / Producción |
| `ISR_REVALIDATE_SECONDS` | Ventana de revalidación (default `120`, RNF-02). | Desarrollo / QA / Producción |
| `AWS_REGION` | Región de la consola de Go Virtual. | Desarrollo / QA / Producción |
| `S3_MEDIA_BUCKET` | Bucket de medios. | Desarrollo / QA / Producción |
| `CLOUDFRONT_MEDIA_DOMAIN` | Dominio de CDN de medios. | Desarrollo / QA / Producción |
| `NEXT_PUBLIC_GTM_ID` | Contenedor de Google Tag Manager. | Desarrollo / QA / Producción |
| `NEXT_PUBLIC_GA4_MEASUREMENT_ID` | Propiedad GA4 de Surman. | Desarrollo / QA / Producción |
| `TURNSTILE_SITE_KEY` / `TURNSTILE_SECRET_KEY` | Anti-spam de formularios. Secreto en **Secrets Manager**. | Desarrollo / QA / Producción |
| `CREDIT_CALCULATOR_CONFIG` | Tasas, plazos y enganche mínimo parametrizados. | Desarrollo / QA / Producción |
| `LOG_LEVEL` | Nivel de log estructurado. | Desarrollo / QA / Producción |

Ningún valor sensible se versiona: `.env.example` documenta las llaves sin valores y el arranque falla rápido si falta alguna requerida.

---

## 8. Consideraciones de seguridad

- **IAM con mínimo privilegio:** el rol de tarea de ECS solo accede al secreto de su ambiente, a su bucket de medios y a su instancia RDS. Sin permisos de administrador (`rules/infraestructura.md` §5).
- **El navegador nunca habla con la plataforma base** (RNF-04): todo pasa por el BFF, que es el único poseedor de credenciales de BRICK y de Biky.Ai. Autenticación servicio-a-servicio con JWT.
- **Secretos fuera del código** (`rules/coding-guidelines.md` §11): AWS Secrets Manager en todos los ambientes; escaneo de secretos en CI.
- **Aislamiento multi-tenant** (RNF-05): el contexto de tenant se resuelve en servidor y se aplica en cada consulta; los datos de Surman quedan aislados de otros clientes de la plataforma.
- **Datos personales del prospecto** (RNF-08, LFPDPPP): consentimiento explícito registrado con cada lead, política de retención definida para la bitácora, cifrado en tránsito y en reposo, y **prohibición de registrar datos personales o tokens en logs** (`rules/coding-guidelines.md` §9).
- **Superficie de escritura:** solo `/api/v1/leads`, `/api/v1/credit-quotes`, `/api/v1/biky/webhook` y `/api/v1/revalidate`. Todas con rate limiting; las dos primeras con anti-spam; el webhook con firma verificada; la revalidación con token.
- **Entrada validada y consultas parametrizadas** siempre (`rules/coding-guidelines.md` §11). CORS restrictivo en producción.
- **Autorización granular** (RF-26, RNF-07): roles por marca y plaza sobre el panel de contenido; toda acción privilegiada queda en `audit_log`.
- **WAF y protección DDoS** delante de CloudFront/ALB, con reglas para bots de scraping de inventario.

---

## 9. Consideraciones de infraestructura

- **Consola AWS:** Go Virtual. `rules/infraestructura.md` no documenta todavía la región de esta consola — **debe definirse antes de T-05**; la recomendación es `us-east-1` por proximidad al tráfico mexicano y paridad con GarantiPlus México.
- **Servicios nuevos requeridos:** ECR (1 repositorio), ECS + Fargate (servicio por ambiente: dev, QA, producción), ALB, RDS PostgreSQL, S3 (medios + artefactos), CloudFront (sitio y medios), Secrets Manager, CloudWatch (logs, dashboards, alarmas), WAF.
- **Costo:** AWS no tiene tope automático de gasto (`rules/infraestructura.md`). Se configura alarma de facturación desde T-05 y se dimensiona Fargate al alza solo bajo autoscaling. Los picos de campaña se absorben con CDN + ISR para no multiplicar el cómputo (RNF-03).
- **DNS:** dominios administrados en Cloudflare; registros de servicios AWS en Route 53. El cutover de T-51 se hace con TTL reducido previamente y plan de rollback.
- **Ambientes:** dev, QA y producción con base de datos independiente. `pre-qa` se consolida localmente antes del PR a `qa` (`rules/version-control.md` §2).
- **Estrategia de caché:** CloudFront para estáticos y medios; ISR de Next.js para páginas de catálogo, inventario y contenido, con revalidación on-demand por webhook. La caché de ISR debe ser compartida entre tareas de Fargate para no servir versiones distintas según la tarea que atienda — **punto a resolver en T-05/T-19**.

---

## 10. Criterios de aceptación

- [ ] Las **49 marcas** y las **~160 agencias** se sirven desde una sola infraestructura multi-sitio, sin páginas hardcodeadas por marca (RF-01, RNF-12).
- [ ] Las **fichas MRP** muestran precio, versiones y specs provenientes de la plataforma base, con actualización visible en menos de ~2 minutos tras un cambio en origen (RF-01, RNF-13).
- [ ] El **inventario de nuevos y seminuevos** se publica automáticamente desde los feeds, con **0 unidades capturadas manualmente** (RF-02, RF-11).
- [ ] El **buscador con filtros** y las páginas por marca/ciudad permiten llegar a cualquier unidad publicada con URLs indexables (RF-02, RF-09).
- [ ] El **localizador** muestra las ~160 agencias con su **WhatsApp propio**, teléfono y formulario, verificados uno por uno (RF-03).
- [ ] Los **formularios de lead** llegan prellenados con el vehículo que el usuario vio, **sin recaptura** (RF-04).
- [ ] Cada lead llega al **CRM de la agencia correcta** con prospecto, vehículo y **campaña** completos, en formato ADF+JSON (RF-05).
- [ ] **Ningún lead se pierde** ante caída del CRM o del motor de leads: queda en bitácora y se reintenta (RNF-14, RNF-06).
- [ ] **Biky.Ai** continúa la conversación con el contexto del prospecto, probado punta a punta en QA (RF-06).
- [ ] La **calculadora de crédito** entrega mensualidad orientativa con disclaimer, alimentada por el inventario y **sin ninguna autorización automática** (RF-07).
- [ ] Los **8 eventos ASC** y los 3 eventos de negocio del MVP se registran en GA4 con sus campos mínimos y están **validados por Data World Surman** (RF-08, §11).
- [ ] **Datos estructurados schema.org sin errores** en la herramienta de resultados enriquecidos de Google, y URLs semánticas con las 301 del sitio actual activas (RF-09, RNF-11).
- [ ] Marketing Surman publica blog, promociones, banners y una landing de campaña por plaza **sin intervención de desarrollo** (RF-10).
- [ ] **FCP ~0.8 s** y Core Web Vitals en verde en móvil sobre las plantillas críticas, verificado por Lighthouse CI (RNF-02).
- [ ] Ante feed inválido, el sistema **no publica datos corruptos**: registra el error y alerta (RNF-14, RNF-10).
- [ ] Roles con permisos granulares operativos sobre la capa Surman, con intentos fuera de permiso rechazados y auditados (RF-26, RNF-07).
- [ ] Aviso de privacidad, cookies y consentimiento en formularios conforme a LFPDPPP (RNF-08).
- [ ] Cero secretos en el repositorio y cero datos personales en logs.
- [ ] Suite de pruebas (unitarias, contrato, E2E, accesibilidad) verde en CI, con el pipeline desplegando a los tres ambientes.
- [ ] Sitio en producción con monitoreo y alertas activos, y rollback probado (T-51).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **R-01** — El BFF en TypeScript se desvía de `rules/stack.md` (backend nuevo → .NET Core 8) y se rechaza después de iniciado el desarrollo | Media | Alto | Resolver como **prerequisito bloqueante** antes de la Fase 0 con el Gerente de TI. Si se exige .NET 8, el BFF sale a un contenedor propio en ECS: sumar 8–12 días hábiles y perder la coherencia de la capa transferible del PRD §3.2. |
| **R-02** — El alcance completo del MVP no cabe en la ventana de 3 meses con un solo desarrollador | **Alta** | Alto | Ver el análisis de deadline en §13. Requiere al menos 3 desarrolladores en paralelo o recorte explícito a P1. Decisión necesaria **antes** de arrancar. |
| **R-03** — Contratos de API de la plataforma base inestables o incompletos (riesgo ya identificado en el PRD §13) | Alta | Alto | Congelar y versionar los contratos en T-08; desarrollar contra mocks; pruebas de contrato en CI que detectan la ruptura el mismo día. |
| **R-04** — Heterogeneidad de los feeds de ~160 agencias produce datos incompletos en el sitio | Alta | Medio | La normalización es responsabilidad del motor existente. Del lado Surman: validación de esquema en el BFF, ocultar campos faltantes en lugar de mostrar vacíos, tablero de calidad de feed por agencia y alertas (T-24). |
| **R-05** — El gate de diseño (§3.3 del PRD) se retrasa y arrastra toda la Fase 1 | Alta | Alto | Paralelizar: Fase 0, contratos, integración de leads y medición no dependen del diseño. Acordar fecha límite de visto bueno y número de iteraciones incluidas antes de arrancar. |
| **R-06** — Volumen del sitio (49 marcas × ~160 plazas × inventario) genera explosión de páginas y tiempos de build o costo de ISR inmanejables | Media | Alto | Generación bajo demanda con ISR en lugar de build estático completo; sitemaps segmentados; limitar combinaciones marca × plaza a las que tienen agencia real; presupuesto de rendimiento en CI (T-44). |
| **R-07** — Caché de ISR no compartida entre tareas de Fargate produce contenido inconsistente entre usuarios | Media | Medio | Definir caché compartida (almacén externo o una sola tarea de revalidación) en T-05/T-19 y verificarlo con varias tareas activas. |
| **R-08** — El objetivo de FCP ~0.8 s no se alcanza con el peso de galerías, mapas y GTM | Media | Medio | Presupuesto de rendimiento desde T-44; carga diferida de mapa y GTM; imágenes en formato moderno vía CDN; medición continua en cada PR. |
| **R-09** — Alcance de la bidireccionalidad con Vicky sin definir (pregunta abierta del PRD §14) | Media | Medio | Implementar primero el sentido crítico (sitio → CRM). El webhook entrante se construye contra contrato acordado; si no se cierra a tiempo, se degrada a P2 sin bloquear el go-live. |
| **R-10** — Duplicación de leads por doble envío o reintentos | Media | Medio | Llave de idempotencia y deduplicación por prospecto + vehículo + ventana temporal (T-27). |
| **R-11** — Payload CMS introduce una dependencia con la que el equipo de Surman no está familiarizado, complicando el handover | Baja | Medio | Validar la decisión en §12; documentar y capacitar en T-36; el modelo de contenido vive en el mismo PostgreSQL, por lo que los datos son portables si se cambia de panel. |
| **R-12** — Mapa de redirecciones incompleto y pérdida de posicionamiento en el cutover | Media | Alto | Inventario completo de URLs actuales antes de T-41; auditoría de rastreo previa al go-live; monitoreo de 404 la primera semana (T-52). |
| **R-13** — Región/consola AWS de Go Virtual sin definir bloquea el aprovisionamiento | Media | Medio | Resolver como prerequisito; la IaC queda parametrizada por región para no rehacer trabajo. |
| **R-14** — Picos de campaña elevan el costo de AWS sin tope automático | Media | Medio | Alarma de facturación desde T-05, autoscaling acotado, absorción de tráfico en CDN + ISR y prueba de carga con costo documentado (T-49). |

---

## 12. Notas para el programador

**Decisiones tomadas durante la generación del plan — validar antes de ejecutar:**

1. **BFF en Route Handlers de Next.js (TypeScript), no en .NET Core 8.** `rules/stack.md` obliga .NET Core 8 para todo backend nuevo y admite Node.js "solo para casos muy puntuales y justificados". La justificación aquí es que el PRD (§3.2, RNF-09) define el BFF como el límite de la **capa Surman transferible**, cuyo stack fija explícitamente en Next.js/React/TypeScript para habilitar el co-desarrollo con Surman y la propiedad futura. Partir el BFF a .NET rompería esa transferibilidad y agregaría un salto de red. **Esta desviación requiere el visto bueno del Gerente de TI antes de la Fase 0** (R-01).

2. **Payload CMS 3 embebido en la app, sobre el mismo PostgreSQL.** RF-10 (blog, promociones, banners y landing pages editables por plaza) es un módulo administrativo completo. Construirlo a mano consume varias semanas de la ventana de 3 meses. Payload corre dentro de Next.js y persiste en PostgreSQL, así que no rompe el default de base de datos ni agrega infraestructura. **Alternativa si se rechaza:** panel propio (sumar ~10–15 días hábiles) o CMS headless externo (agrega un proveedor y saca el contenido del perímetro AWS).

3. **No se replica el inventario ni el catálogo como sistema de registro.** La fuente de verdad es la plataforma base. `inventory_snapshots` existe solo para degradación controlada (RNF-14) y se marca explícitamente como caché, no como dato maestro.

4. **`lead_enrutado` se emite del lado servidor**, con la agencia real que devuelve el motor de leads. Emitirlo desde el navegador mediría la intención, no el enrutamiento, y falsearía la métrica central del PRD (§12: "% que llega a la agencia correcta").

5. **Idioma:** el código, los identificadores y los comentarios van en inglés (`rules/coding-guidelines.md` §1). El contenido y las rutas de cara al usuario van en español (`/inventario`, `/agencias`, `/promociones`).

6. **Las convenciones de `rules/coding-guidelines.md` se aplican por analogía en TypeScript**: una responsabilidad por archivo, máximo 200 líneas efectivas, API First (los contratos de §6 se definen antes de implementar), rutas REST en plural con versión `v1`, y los códigos de estado de la tabla de §6.

**Puntos que el programador debe cerrar con el negocio antes de ejecutar:**
- Los cuatro prerequisitos bloqueantes de §2 (validación del PRD, decisión del BFF, consola/región AWS, permisos de GitHub).
- La **decisión de recursos** derivada del análisis de deadline en §13: tres desarrolladores en paralelo o recorte a P1. Este plan está estimado para un desarrollador y **no cabe en la ventana de 3 meses en esa configuración**.
- La fecha límite del visto bueno de diseño y el número de iteraciones incluidas (§3.3 y §14 del PRD).
- El diccionario de eventos ASC con Data World antes de T-38, para no instrumentar dos veces.
- La política de rastreo para agentes de IA en T-43: es una decisión de negocio de Surman, no técnica.

**Fuera de este plan, por diseño:** RF-12 a RF-25 (Fase 1 y Fase 2 del PRD). El esquema de base de datos, el modelo de tenancy y la capa de medición se diseñan de modo que Login/Mi Garage y las transacciones se sumen sin reescritura, según el supuesto de "base tecnológica única heredada por fases" (PRD §13).

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles para un (1) desarrollador**, sin incluir el tiempo de diseño UX/UI ni los ciclos de aprobación del cliente (§3.3 del PRD), que corren por fuera de este plan.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Cimentación, contratos y entorno (P1)** | Repositorio y ramas, scaffolding Next.js, `CLAUDE.md`, Docker, infraestructura AWS, CI/CD, secretos, contratos tipados con BRICK, cliente resiliente, observabilidad | T-01 a T-10 | 8 – 12 días | |
| **Fase 1 — Núcleo multi-sitio, marcas y fichas MRP (P1)** | Tenancy de 49 marcas y ~160 storefronts, esquema PostgreSQL, design system, layout, home y páginas de marca, fichas MRP, páginas marca/ciudad, localizador de agencias | T-11 a T-18 | 15 – 20 días | |
| **Fase 2 — Inventario, buscador y calculadora (P1)** | Consumo de inventario normalizado, listado con filtros, ficha de unidad, buscador global, calculadora de crédito, degradación controlada | T-19 a T-24 | 12 – 16 días | |
| **Fase 3 — Leads e integraciones (P1)** | Formularios prellenados, capa de campaña, endpoint de lead, bitácora y reintentos, Biky.Ai/Vicky, confirmación y trazabilidad | T-25 a T-30 | 10 – 14 días | |
| **Fase 4 — Contenido gestionable y accesos (P2)** | CMS sobre PostgreSQL, render por marca/plaza, constructor de landings, medios en S3, roles y permisos, documentación de handover | T-31 a T-36 | 10 – 14 días | |
| **Fase 5 — Medición ASC, SEO/AEO y performance (P1)** | GTM y consentimiento, 8 eventos ASC, eventos de negocio, validación con Data World, SEO técnico y 301, schema.org, AEO, presupuesto de rendimiento | T-37 a T-44 | 12 – 17 días | |
| **Fase 6 — QA, hardening y go-live (P1)** | Suite de pruebas, hardening de seguridad, accesibilidad, carga de 49 marcas y ~160 agencias, pruebas de carga, LFPDPPP, go-live y estabilización | T-45 a T-52 | 12 – 17 días | |
| **Total proyecto (MVP completo)** | Fases 0 a 6 | **52 tareas** | **~79 – 110 días hábiles (≈ 16 – 22 semanas)** | — |
| **Solo P1 (guardarraíl del go-live)** | Fases 0, 1, 2, 3, 5 y 6 — excluye Fase 4 y T-43, T-49 | 44 tareas | **~66 – 92 días hábiles (≈ 13 – 18 semanas)** | — |

> **Notas sobre la tabla:**
> - El PRD no divide el MVP en prioridades P1/P2/P3, así que las prioridades de esta tabla se derivan de §5 y §12 del PRD: es P1 todo lo que el principio rector exige desde el día uno (catálogo, inventario, leads con contexto, medición ASC, SEO). La Fase 4 (contenido gestionable, RF-10) es lo único diferible sin romper el flujo central "explora → deja sus datos → enrutamiento al CRM → cierre humano", a costa de que marketing dependa de desarrollo para publicar en las primeras semanas.
> - Los rangos salen de la complejidad de cada tarea. La Fase 1 es la más pesada por el volumen de plantillas y el design system; la Fase 6 concentra la verificación manual de 49 marcas y ~160 agencias, que no se puede automatizar del todo.
> - La estimación **no incluye** el diseño UX/UI ni el prototipado en Figma, ni los ciclos de visto bueno del cliente (§3.3 del PRD), ni el trabajo de la plataforma base de Go Virtual (onboarding y normalización de los feeds de ~160 agencias).
> - La columna **ID (BD)** la llena el flujo al registrar el plan en la base de datos (`pm_plan_fase.id`); no editarla a mano.

> **Riesgo de deadline.**
> El PRD fija el MVP en **mes 0–3**. Contados desde el 2026-08-03, hay aproximadamente **64 días hábiles** hasta finales de octubre de 2026 (descontando el 16 de septiembre).
>
> - **MVP completo con 1 desarrollador: ~79–110 días hábiles. No cabe.** El faltante es de 15 a 46 días hábiles, es decir entre 3 y 9 semanas de desfase.
> - **Solo P1 con 1 desarrollador: ~66–92 días hábiles. Tampoco cabe**, ni en el extremo optimista.
>
> **Recomendación explícita: sumar desarrolladores, no recortar el MVP.** El alcance P1 es el guardarraíl del PRD (§5: "base sólida, medible y visible desde el día uno") y recortarlo más significaría entregar un sitio sin medición o sin enrutamiento de leads, lo que vacía el objetivo del programa.
>
> - **3 desarrolladores en paralelo** es la configuración mínima viable. Las Fases 1, 2, 3, 4 y 5 son ampliamente paralelizables una vez cerrada la Fase 0 y aprobado el diseño; el cuello secuencial es la Fase 0 (~8–12 días, poco divisible) y la Fase 6 (integración y verificación final). Con 3 desarrolladores la compresión estimada es de **~45–55 % del calendario de un solo recurso**, lo que sitúa el MVP completo en **~45–60 días hábiles y lo hace caber en la ventana**, con holgura ajustada.
> - **2 desarrolladores** llevarían el MVP completo a ~55–75 días hábiles: cabe únicamente el alcance P1, y sin margen para retrasos del gate de diseño ni de los contratos de la plataforma base.
> - Si no es posible sumar recursos, la única salida realista es **negociar con Surman una entrega escalonada**: go-live con P1 al cierre del mes 3 y la Fase 4 (contenido gestionable) en las 2–3 semanas siguientes.
> - Dos factores externos pueden invalidar cualquiera de estos escenarios y deben acordarse con fecha antes de arrancar: el **visto bueno de diseño** (R-05) y la **estabilidad de los contratos de la plataforma base** (R-03).

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
