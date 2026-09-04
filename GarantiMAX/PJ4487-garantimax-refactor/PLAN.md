# Plan de Desarrollo — Reconstrucción de GarantiMAX · Fase 1: núcleo del Asesor Farmer

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/GarantiMAX/PJ4487-garantimax-refactor/PRD.md` (+ anexos A1 arquitectura, A2 ADRs, A3 inventario) |
| Repositorio | **Frontend:** `garantiplusmexico/siga_alfa` (nuevo). **Backend:** `garantiplusmexico/gp_3.0_siga_api`, servicio `Services/GarantiMax/` (nuevo, ADR-011). **Sistema actual:** `garantiplusmexico/garantiplus-dashboard` — solo lectura, es la fuente de las reglas de negocio |
| Rama | `feature/PJ4487-garantimax-refactor-nucleo-asesor` (Fase 0) · una rama por fase con el mismo prefijo, todas desde `develop` |
| Tipo | Proyecto nuevo (re-arquitectura sobre base de datos existente) |
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | PJ4487 |
| Fecha de generación | 2026-08-25 |
| Estado | Validado |
| ID plan (BD) | `56` (`pm_plan_desarrollo.id`) |

**Rama base:** `develop` del repositorio nuevo `siga_alfa`.

> ⚠️ **Nota sobre la rama base.** El repositorio del sistema actual (`garantiplus-dashboard`) **no tiene `develop` ni `main`**: trabaja sobre `master` con ramas `feat/` y `fix/`, y no cumple el estándar de `rules/version-control.md`. Como la aplicación nueva vive en un repositorio propio (decisión tomada en la generación de este plan), **el repositorio nuevo nace ya con la estructura Engine completa** — `main`, `develop`, `pre-qa`, `qa` — y este plan se ejecuta desde `develop`. El repositorio actual se deja como está: normalizarlo obligaría a tocar un sistema en producción que está fuera del alcance de este PRD.

---

## 1. Resumen técnico

Se **reconstruye desde cero la aplicación de terreno del Asesor Farmer** en un repositorio nuevo (`siga_alfa`, solo frontend) servida por un **servicio .NET nuevo** (`Services/GarantiMax/` en el monorepo `gp_3.0_siga_api`) con base de datos PostgreSQL propia. No hay migración de datos: **borrón y cuenta nueva** — la base arranca vacía y el sistema actual queda aislado (ADR-011).

> ⚠️ **Este plan se escribió contra Supabase y se corrigió el 26-08-2026.** Las secciones §5 a §9, los criterios de aceptación y las tareas afectadas están actualizados. Donde el texto describe el **sistema actual** (conteos de queries, módulos, funciones existentes) sigue siendo válido: es el punto de partida, no el destino.

**Qué se crea.** Una SPA React 19 + TypeScript + Vite + Tailwind v4, organizada por **feature de dominio con capas internas** (ADR-001): `domain` · `application` · `ports` · `infrastructure` · `ui` dentro de cada feature (`identidad`, `visitas`, `tareas`, `agenda`, `bitacora`, `gastos`, `referencia`), más `app/` (composición y rutas), `shared/` (sistema de componentes, layouts, errores, sincronización, observabilidad), `infrastructure/` transversal y `config/`. El cliente HTTP de la API queda confinado a `infrastructure/api/`; ninguna vista habla con la red.

**Qué se rediseña frente al sistema actual.** La navegación (de `useState<Tab>` en un `App.tsx` de 916 líneas a rutas reales con React Router), el acceso a datos (de 447 queries dentro de `.tsx` a repositorios por agregado detrás de casos de uso), la experiencia web/móvil (de dos aplicaciones a **un layout adaptativo** — ADR-007), la detección de PWA (de `if (isPWA)` distribuido a un único `DeviceContextProvider`), el manejo de errores (de improvisado a jerarquía tipificada) y el soporte offline (de parches en `App.tsx` a un **decorador de repositorio** — ADR-009).

**Qué se elimina y no se traslada.** El tier legacy `CM/GTE/FARMER` y también la matriz `roles × capacidades` (ADR-011 supera a ADR-008: los permisos se resuelven contra los roles del JWT que emite la API), las carpetas vacías `farmer/` y `bitacora/`, `MiDiaMovilPreview` y el parámetro `?midia`, el drenaje de cola offline desde `App.tsx`, y el login de Google.

**Stack.** React 19 + Vite 8 + TypeScript + Tailwind v4 (continuidad con el sistema actual, PRD §6) · **React Router** (navegación), **TanStack Query** (datos de servidor), **Zustand** acotado (estado de UI transversal) — ADR-006, aprobadas como decisión cerrada en la generación de este plan · Vitest (unitarias e integración) + **Playwright** (E2E, nuevo) · Sentry · Vercel.

**Stack del backend** (repo `gp_3.0_siga_api`, convenciones propias): .NET 8 · ASP.NET Core Web API · EF Core + Npgsql · PostgreSQL · JWT Bearer · Serilog · Swagger/Scalar · AWS ECS + Fargate. **Ojo:** en ese repositorio el código va **en inglés**, al contrario que aquí.

> **Alineación con `rules/stack.md` e `rules/infraestructura.md`.** Tras ADR-011 el backend **sí** es el estándar Engine: .NET 8 sobre ECS + Fargate. La desviación que declaraba la v0.1 de este plan desaparece. Queda **una sola desviación**: el hospedaje del frontend se conserva en **Vercel** en lugar de S3 + CloudFront, por continuidad operativa y porque el PRD deja el cambio de proveedor de hospedaje fuera de alcance. Requiere visto bueno de TI; ver §9.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable (PJ4487, **v0.2** — incluye ADR-011) y anexos A1/A2/A3 leídos por quien ejecuta
> **Repasados el 04-09-2026.** Se marca solo lo que se puede comprobar desde
> los repositorios; lo demás lleva escrito quién lo confirma, porque un
> prerrequisito marcado «por si acaso» es peor que uno pendiente.

- [x] **Repositorio nuevo `siga_alfa` creado** en la organización, con permisos para el responsable
- [x] Acceso de **lectura** al repositorio actual `garantiplusmexico/garantiplus-dashboard`: es la fuente para extraer las reglas de negocio (migraciones, funciones y políticas RLS). **No se escribe nada ahí** — y no se ha escrito
- [x] Acceso de escritura al repositorio de la API `garantiplusmexico/gp_3.0_siga_api` y al entorno donde vive su base de datos
- [~] **Servicio `Services/GarantiMax/` creado** en el monorepo de la API, con su base de datos aprovisionada y su `DbContext` propio — el servicio y el `DbContext` están; que la **base esté aprovisionada** no se puede comprobar desde aquí y nunca se ha corrido una migración contra ella. Lo confirma el responsable
- [~] `VITE_API_BASE_URL` definida para desarrollo, QA y producción (local: puerto 5006 por convención del repo de la API) — **desarrollo sí** (`.env.local`); QA y producción llegan con T-69
- [ ] Usuario de prueba con rol de Asesor Farmer dado de alta en la base de la API, y **nombre exacto del rol** comunicado al frontend (pregunta abierta del PRD §14) — sigue abierta, y es la que bloquea aprobar y pagar una rendición
- [ ] `VITE_SENTRY_DSN` disponible (proyecto Sentry nuevo o reutilizado) — **la variable está vacía en `.env.local`**. En desarrollo es admisible a propósito (`src/config` solo la exige fuera de desarrollo), así que hoy no se reporta nada a Sentry
- [ ] Proyecto Vercel nuevo creado y dominio de transición decidido (ver §9) — bloquea T-69
- [x] `CLAUDE.md` presente en el repositorio nuevo (se genera en T-02; el del repo actual ya existe)
- [x] ADR-006 ratificado por TI (librerías) — **aprobado en la generación de este plan**
- [ ] Disponibilidad confirmada de asesores reales para validaciones periódicas y para el piloto (supuesto del PRD §13)
- [ ] Definido quién revisa y **firma** las reglas de autorización de los endpoints del servicio, sustituto de la auditoría de RLS (pregunta abierta del PRD §14)
- [ ] Datos de prueba sembrados en las tablas de referencia (salas, vendedores de sala, clientes) para poder construir y probar — el script sale de T-18 (**hecha**); la carga real la hace el responsable antes del piloto, y sin ella no se puede probar nada de punta a punta

---

## 3. Arquitectura del cambio

Arquitectura aplicada: **Frontend + Backend separados** en la clasificación de `rules/arquitectura.md`. El backend es un **microservicio .NET propio** —`Services/GarantiMax/`— dentro de un monorepo que ya opera seis (ADR-011). El dominio es único: el trabajo de terreno del asesor, y por eso es **un** servicio y no varios.

La regla que gobierna todo el diseño: **las dependencias apuntan hacia adentro**.

```
                    ┌─────────────────────────────────────────┐
   Presentación     │ Pages · Components · Layouts adaptativos │
   (ui/)            │ Hooks de UI (view-models)               │ ← única capa que habla con application
                    └────────────────────┬────────────────────┘
                                         │
                    ┌────────────────────▼────────────────────┐
   Aplicación       │ Casos de uso · tipificación de errores  │
   (application/)   │ Decide: ¿se ejecuta o se encola?        │
                    └───────┬────────────────────────┬────────┘
                            │                        │
              ┌─────────────▼──────────┐  ┌──────────▼────────────┐
   Dominio    │ Entidades · invariantes│  │ Contratos (ports)     │  Contratos
   (domain/)  │ máquinas de estado     │  │ Repositories·Providers│  (ports/)
              │ TypeScript puro        │  └──────────┬────────────┘
              └────────────────────────┘             │ implementado por
                                         ┌───────────▼───────────────┐
   Infraestructura                       │ ApiXRepository            │
   (infrastructure/)                     │ XRepositoryOffline (deco) │
                                         │ Auth·Storage·Local·Sentry │
                                         └───────────┬───────────────┘
                                                     │
                              ┌──────────────────────┴──────────────┐
                              ▼                                     ▼
        Servicio .NET GarantiMax (REST · JWT ·               IndexedDB
        PostgreSQL · S3) · Sentry                    (snapshot + cola offline)
```

**Prueba de que el diseño se respeta:** si borrar `infrastructure/` rompe la compilación del dominio, el diseño está mal. Se verifica con reglas de linter que fallan la compilación (T-09), no con revisión manual.

**Estructura de directorios** — según A1 §3 (sin `utils/`, sin `lib/`, sin `helpers/`):

```
src/
├─ app/            routes/ · providers/ · container.ts · App.tsx (sin lógica)
├─ domain/         identidad/ · agenda/ · shared/         (dominio compartido)
├─ features/       visitas/ tareas/ agenda/ bitacora/ gastos/ identidad/ referencia/
│                    └─ cada uno: domain/ application/ ports/ infrastructure/ ui/
├─ shared/         ui/ · layouts/ · errors/ · sync/ · observability/
├─ infrastructure/ api/ · auth/ · storage/ · realtime/ (solo puerto) · local/
└─ config/         variables de entorno tipadas y validadas al arrancar
```

---

## 4. Tareas de desarrollo

> Convención: cada tarea es atómica, se prueba sola y se integra a `develop` por PR desde su rama de fase.
> Las rutas de archivo son del **repositorio nuevo** salvo que se indique `[repo actual]`.

> ### 🔀 Reordenamiento de la Fase 0 — 26-08-2026
>
> Con Supabase, las tareas de **extracción de reglas** (T-13 a T-16) podían ir al final de la Fase 0: las reglas ya estaban implementadas en la base y las funciones seguían ahí. Tras ADR-011 eso se invierte — **son el insumo sin el cual el servicio .NET no puede empezar**, así que pasan al frente junto con T-18 (esquema y siembra). El camino crítico del proyecto ya no es el frontend: es la especificación.
>
> **Orden de ejecución acordado**, distinto al de la numeración:
>
> 1. **Fundaciones baratas que desbloquean todo:** T-04, T-05, T-06, T-07 (configuración, errores, contratos transversales, contenedor). No dependen de las reglas.
> 2. **Extracción de reglas:** T-13, T-14, T-15, T-16 — más la **extracción** de las reglas de autorización que estaba en T-67. La revisión firmada sigue en Fase 4; lo que se adelanta es leer las ~150 políticas RLS, porque cada endpoint las necesita el día que se escribe, no al final.
> 3. **T-18** — esquema consolidado y script de siembra.
> 4. **Servicio .NET:** bloque **T-S01 a T-S09** (abajo). Es trabajo nuevo que la v0.1 de este plan no contemplaba.
> 5. **Resto de fundaciones del frontend:** T-08, T-09, T-10, T-11, T-12, T-19.
> 6. **T-17** (línea base medida sobre el sistema actual) en cualquier momento: no bloquea a nadie.
>
> A partir de la Fase 1 se trabaja **por vertical**: para cada feature, endpoints del servicio y luego dominio, casos de uso y UI del frontend — así cada feature queda demostrable de punta a punta antes de pasar a la siguiente.

### Fase 0 — Fundaciones, guardarraíles y extracción de reglas

- [x] **T-01** — Crear el repositorio `siga_alfa` con la estructura de ramas Engine
  - Archivos a crear/modificar: `README.md`, `.gitignore`, `.github/CODEOWNERS`
  - Criterio de completitud: existen `main`, `develop`, `pre-qa`, `qa`; `main` protegida con 2 aprobaciones; `develop` sin commits directos; el responsable tiene acceso

- [x] **T-02** — Andamiaje base de la aplicación y estructura de carpetas de A1 §3
  - Archivos a crear/modificar: `package.json`, `vite.config.ts`, `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`, configuración de Tailwind, `src/main.tsx`, `src/app/App.tsx`, árbol completo de `src/` con un `index.ts` por capa, `CLAUDE.md`
  - Criterio de completitud: `npx tsc -b` y `npm run build` pasan en verde sobre un esqueleto que renderiza una ruta vacía; el árbol de carpetas coincide con A1 §3

- [x] **T-03** — Instalar y configurar React Router, TanStack Query y Zustand (ADR-006)
  - Archivos a crear/modificar: `package.json`, `src/app/providers/QueryProvider.tsx`, `src/app/routes/index.tsx`, `src/shared/sync/store.ts`
  - Criterio de completitud: router montado con dos rutas de prueba y navegación con URL e historial; `QueryClient` configurado con política de reintentos y `staleTime` documentados; store de Zustand creado vacío con su regla de uso escrita en `CLAUDE.md`

- [x] **T-04** — Configuración tipada y validada al arranque
  - Archivos a crear/modificar: `src/config/env.ts`, `src/config/env.test.ts`, `.env.example`
  - Criterio de completitud: si falta o es inválida una variable requerida, la aplicación falla al arrancar con un mensaje claro; ninguna variable se lee con `import.meta.env` fuera de `config/` (verificado por linter en T-09)

- [x] **T-05** — Jerarquía de errores tipificados y su traducción a mensajes
  - Archivos a crear/modificar: `src/shared/errors/*.ts`, `src/shared/errors/traducir.ts`, `src/shared/errors/*.test.ts`
  - Criterio de completitud: existen las 7 categorías de A1 §10 (`DomainError`, `ValidationError`, `AuthenticationError`, `AuthorizationError`, `NetworkError`, `ProviderError`, `InfrastructureError`); pruebas que verifican que ningún mensaje al usuario contiene nombre de tabla, SQL, ruta interna ni el mensaje original del proveedor

- [x] **T-06** — Contratos transversales (ports), sin implementación
  - Archivos a crear/modificar: `src/shared/observability/MonitoringProvider.ts`, `src/infrastructure/auth/AuthProvider.ts`, `src/infrastructure/storage/StorageProvider.ts`, `src/infrastructure/local/LocalStore.ts`, `src/infrastructure/realtime/RealtimeProvider.ts`, `src/domain/shared/ClockProvider.ts`
  - Criterio de completitud: los seis contratos compilan sin ninguna importación de infraestructura; `RealtimeProvider` queda **declarado y sin implementación** (ADR-005 modificado por ADR-011: sin acoplamiento a proveedor), con comentario que registra sus futuros consumidores (War Room, Post-Venta, Call Center)

- [x] **T-07** — Contenedor de composición de dependencias
  - Archivos a crear/modificar: `src/app/container.ts`, `src/app/providers/ContainerProvider.tsx`, `src/app/container.test.ts`
  - Criterio de completitud: un único punto decide qué implementación satisface cada contrato; una prueba monta el contenedor completo con dobles y no toca la red

- [x] **T-08** — Implementaciones de infraestructura transversal
  - Archivos a crear/modificar: `src/infrastructure/api/cliente.ts`, `src/infrastructure/api/errores.ts`, `src/infrastructure/auth/ApiAuthProvider.ts`, `src/infrastructure/storage/ApiStorageProvider.ts`, `src/infrastructure/local/IndexedDBLocalStore.ts`, `src/shared/observability/SentryMonitoringProvider.ts`, `src/domain/shared/RelojDelSistema.ts` + pruebas de cada uno
  - Criterio de completitud: `errores.ts` traduce todo fallo HTTP —incluidos 401/403 y la caída de red— a las categorías de T-05 antes de salir de infraestructura; `IndexedDBLocalStore` se prueba sin navegador con doble de IndexedDB; el cliente HTTP se instancia **una sola vez** y solo aquí, y es el único lugar donde se adjunta el token

- [x] **T-09** — Reglas de linter arquitectónicas (los 5 guardarraíles automáticos de A1 §15)
  - Archivos a crear/modificar: `eslint.config.js`, `tools/eslint-rules/*.js` + pruebas de cada regla
  - Criterio de completitud: fallan la compilación (1) importar el cliente HTTP o llamar `fetch` desde `ui/`, (2) hablar con la red fuera de `infrastructure/api/`, (3) importar `ui/` o `infrastructure/` de otro feature, (4) usar `matchMedia` o `navigator.standalone` fuera del `DeviceContextProvider`, (5) importar cualquier dependencia externa desde `domain/`. Cada regla tiene una prueba con un caso que debe fallar y uno que debe pasar

- [x] **T-10** — Script de métricas arquitectónicas y línea base
  - Archivos a crear/modificar: `tools/metricas-arquitectura.mjs`, `docs/linea-base.md`
  - Criterio de completitud: el script cuenta queries en vistas, archivos que importan el SDK fuera de infraestructura y componentes de terreno duplicados, y falla si alguno es distinto de 0 en el repo nuevo. Deja registrada la línea base **medida** del sistema actual (a 2026-08-25: 840 llamadas `.from()/.rpc()`, 447 dentro de `.tsx`, 157 archivos con el SDK, `App.tsx` de 916 líneas)

- [x] **T-11** — Integración continua
  - Archivos a crear/modificar: `.github/workflows/ci.yml`
  - Criterio de completitud: en cada PR corren `npx tsc -b`, `npm run lint` (incluye T-09), `npm test` y `npm run build`, más el script de T-10; un PR que viole un guardarraíl no puede mergearse

- [x] **T-12** — PWA instalable con shell offline
  - Archivos creados: `vite.config.ts` (vite-plugin-pwa), `src/app/pwa/{manifest.ts,UpdateProvider.tsx,registerServiceWorker.ts}`, `tools/genera-iconos.mjs`, `public/` (cinco iconos) + pruebas
  - Criterio de completitud: la aplicación se instala en Android e iOS, su shell carga sin conexión (RNF-15) y avisa cuando hay versión nueva
  - **El service worker precachea el armazón y NO los datos.** De los datos se encargan los snapshots y la cola, que saben de quién son y cuándo caducan; un service worker cacheando respuestas de la API sería una tercera copia con reglas propias. `/api/` queda **excluido** del fallback de navegación: sin eso, una petición sin señal devolvería el index cacheado y el cliente HTTP intentaría parsear HTML como JSON
  - **Avisa, no actualiza solo** (`registerType: 'prompt'`): aplicar una versión nueva recarga la página, y el asesor puede estar a media visita. El aviso vive por fuera de todo el árbol —no depende de la sesión ni de la ruta— y el registro real está detrás de un puerto de dos funciones, así que se prueba sin empaquetador
  - **Los iconos se generan** con `tools/genera-iconos.mjs`, sin dependencias: PNG a mano con `zlib`. Sin generador, el día que cambie el color de marca alguien actualiza dos de cinco. La variante *maskable* lleva más aire porque Android recorta al lanzador
  - `analiza-bundle.mjs` **falla en CI** si el build no emite el manifiesto, el service worker o los cuatro iconos, o si el service worker deja de precachear el index — comprobado quitando cada cosa. Lo que **no** se prueba aquí es que el shell sirva sin conexión de verdad: eso pide un navegador y va en T-66

- [x] **T-13** — Extracción de reglas del sistema actual: Mi Día, visitas y lobbies
  - Archivos a crear/modificar: `docs/reglas/visitas.md` · fuentes `[repo actual] src/features/visitas/` (70 archivos, 14.245 líneas) y `src/App.tsx`
  - Criterio de completitud: catálogo con cada regla encontrada, su ubicación actual, si se conserva o se descarta y a qué capa va. Incluye obligatoriamente: una visita en curso por asesor, el aviso global ligado al **usuario real** y no al impersonado por "Ver como", el borrador en tres capas (servidor, local, marca de visita abierta) y el cronómetro

- [x] **T-14** — Extracción de reglas: tareas, agenda, cumpleaños y bitácora
  - Archivos a crear/modificar: `docs/reglas/gestion.md` · fuentes `[repo actual] src/features/visitas/` y las migraciones de `plan_tareas`, `agenda_eventos`, `feriados`, `bitacoras`
  - Criterio de completitud: catálogo equivalente al de T-13, incluyendo el cálculo de días hábiles (`limite_habil`), la evaluación de cumplimiento diario de bitácora y las exenciones vigentes

- [x] **T-15** — Extracción de reglas: gastos, boletas y rendiciones
  - Archivos a crear/modificar: `docs/reglas/gastos.md` · fuentes `[repo actual] src/features/gastos/` (26 archivos, 8.779 líneas) y las RPCs `gasto_*` y `rendicion_*`
  - Criterio de completitud: catálogo equivalente, con la máquina de estados de rendición completa (incluidos rechazo y reenvío) y las reglas de la cola de boletas actual (`useSincronizarBoletas`, `idbStore.ts`)

- [x] **T-16** — Extracción de reglas: identidad, permisos, "Ver como" y modo demo
  - Archivos a crear/modificar: `docs/reglas/identidad.md` · fuentes `[repo actual] src/App.tsx`, `src/features/auth/`, `src/types/index.ts`, `demoGuard.ts` y las migraciones de `rol_capacidades` y `usuario_roles`
  - Criterio de completitud: qué puede hacer el AF expresado como **lista de decisiones de acceso**, no como matriz de capacidades — la matriz desaparece (ADR-011). Cada decisión mapeada al rol del JWT que la habilita. Las capacidades del sistema actual (`facturacion`, `salas`, `midia`, `cobertura`, `unoauno`, `config`) se leen como documentación de lo que el permiso significaba. Lista de todos los puntos donde el tier legacy decide algo, con qué lo reemplaza; "Ver como" formulado como **regla de dominio**, no como guard de UI

- [ ] **T-17** — Línea base medida de las métricas de producto
  - Archivos a crear/modificar: `docs/linea-base.md`
  - Criterio de completitud: tiempo de apertura de Mi Día en el sistema actual (con y sin señal, en dispositivo y red representativos) e incidencias por asesor y por semana del último mes. Sin esto, RNF-06 y la métrica de incidencias del PRD §12 no son verificables

- [x] **T-18** — Especificación del esquema y del contrato de idempotencia para el servicio
  - Archivos a crear/modificar: `docs/reglas/esquema-fase1.md` · fuentes: las migraciones, funciones y políticas del repo actual (solo lectura) · destino: el equipo que construye `Services/GarantiMax/`
  - Criterio de completitud: tabla por tabla del alcance de Fase 1, sus campos con tipo y obligatoriedad, sus invariantes y su dueño; **clave de idempotencia con índice único parcial** exigida en visitas, lobbies, eventos de agenda, avances de tarea, bitácoras y gastos (RNF-09), más unicidad por asesor y día en bitácoras; columna de país donde haya dato operativo; claves de un solo tipo y FKs reales — **nada de transcribir el esquema viejo** (A3 §3). Incluye la tabla de eventos de producto del PRD §11. Se entrega como especificación, no como SQL: la implementación es del servicio

- [x] **T-19** — Sistema de componentes base adaptativo
  - Archivos a crear/modificar: `src/shared/ui/*` (botón, campo, selector, lista, tarjeta, hoja inferior, modal, estado vacío, cargando, error), `src/shared/ui/tokens.css`
  - Criterio de completitud: cada componente funciona en pantalla ancha y estrecha sin bifurcación en el consumidor; objetivos táctiles ≥ 44 px y contraste AA verificados (RNF-16, RNF-17); ninguno consulta `matchMedia`
  - **La hoja inferior y el modal son el mismo componente**, sobre `<dialog>` nativo: la diferencia es una clase `sm:` que resuelve el navegador. El nativo trae foco atrapado, Escape y página inerte — reimplementarlos a mano es de los errores de accesibilidad más comunes
  - Los colores llevan **su ratio de contraste anotado**: `muted` es slate-600 y no el slate-400 habitual para texto secundario, porque slate-400 sobre blanco da 2.8:1 y no cumple AA
  - **La lista exige decir qué se ve cuando está vacía.** La mitad de las listas del sistema actual no dicen nada, y el asesor no sabe si no hay visitas o si la consulta falló

### Fase 0-B — Servicio .NET `GarantiMax` (bloque nuevo, ADR-011)

> Trabajo que la v0.1 de este plan no contemplaba porque no había backend que construir. Vive en el repositorio `garantiplusmexico/gp_3.0_siga_api`, con **sus** convenciones: código en **inglés**, mensajes al usuario final en español, nada hardcodeado (`Options/` + `appsettings`), `LogRequestAsync` en cada endpoint, y **el desarrollador compila y arranca — el agente no ejecuta `dotnet build` ni `dotnet run` por su cuenta**.
>
> Entorno verificado en esta máquina el 26-08-2026: .NET SDK 8.0.418, PostgreSQL 16.3 escuchando en 5432, y las propiedades MSBuild `GPProjectBasePath` / `GPProjectsPath` resueltas por variables de entorno.

- [x] **T-S01** — Esqueleto del servicio y su rama
  - Archivos a crear/modificar: `[repo api] Services/GarantiMax/{GarantiMax.csproj,Program.cs,appsettings.json,Dockerfile}`, entrada en `gp_3.0_siga_api.sln`, rama `feature/PJ4487-garantimax-nucleo-asesor` desde `develop`
  - Criterio de completitud: el servicio arranca en el puerto **5006** con Swagger/Scalar; JWT Bearer configurado contra el mismo `JwtSettings` que el resto; Serilog y `LogsMonitorClient` registrados; un endpoint de salud responde y **exige token**

- [x] **T-S02** — `DbContext` propio y base de datos
  - Archivos a crear/modificar: `Services/GarantiMax/Data/GarantiMaxDbContext.cs`, `Options/`, `appsettings.json`
  - Criterio de completitud: contexto propio del servicio contra una base **separada** (`garantimax_db`), con su cadena en `appsettings` bindeada a `Options/`. **No se toca `garantiplus_dbContext`** ni `DataAccess`, congelado desde enero de 2025. La conexión se verifica contra la base local

- [x] **T-S03** — Modelo de datos de Fase 1 y migración inicial
  - Archivos a crear/modificar: `Services/GarantiMax/Models/*`, migración EF inicial
  - Criterio de completitud: implementa la especificación de T-18 — claves de un solo tipo y FKs reales, columna de país, clave de idempotencia con índice único parcial donde T-18 la exige, unicidad por asesor y día en bitácoras. **Nada transcrito del esquema viejo** (A3 §3.1). Los estados van como enums respaldados por restricción

- [x] **T-S04** — Siembra de datos de prueba
  - Archivos a crear/modificar: script de siembra + `Services/GarantiMax/doc/siembra-de-pruebas.md`
  - Criterio de completitud: catálogos de referencia (salas, vendedores de sala, clientes), un asesor de prueba ligado al usuario de prueba que ya existe, y un juego mínimo de datos que permita recorrer los cinco flujos críticos. Idempotente: se puede correr dos veces sin duplicar

- [x] **T-S05** — Autorización base y su documentación
  - Archivos a crear/modificar: `Services/GarantiMax/{Interfaces,Services}/` para la resolución del asesor desde el token, `Services/GarantiMax/doc/README.md` + `doc/quien-puede-ver-que.md`
  - Criterio de completitud: un helper único traduce el token al asesor y **todo endpoint lo usa** — nadie recibe un identificador de asesor por parámetro y confía en él. La regla «el asesor solo lee y escribe lo suyo» queda documentada con ejemplos que pasan y que no, según la convención `doc/` del repo. Es el sustituto de RLS y el punto donde un descuido es un hueco de seguridad, no un bug

- [x] **T-S06** — Endpoints de identidad y perfil
  - Criterio de completitud: perfil del asesor, marca de bienvenida vista y de inducción. Los roles **no** se exponen por endpoint: viajan en el token

- [x] **T-S07** — Endpoints de terreno: Mi Día, visitas y lobbies
  - Criterio de completitud: check-in, cierre, visita en curso, visitas abiertas y lobbies, con la clave de idempotencia respetada en la base. Los catálogos de referencia se exponen **solo en lectura** (RF-24)
  - **La clave primaria por asesor no bastaba.** Con una fila por asesor, un `PUT` de otra visita habría sobrescrito la abierta sin error y sin aviso, perdiendo su borrador; ahora responde **409 nombrando la sala abierta**. Es la invariante V-04 del lado del servidor, que hoy vive en la UI como un `disabled`
  - **No hay bandera `overwrite`:** se deduce del `VisitId`. Una bandera que el cliente debe poner bien es una bandera que algún día estará mal, y el síntoma sería el asesor recibiendo cinco veces el mismo recordatorio (V-23)
  - **Mi Día es una sola respuesta** —visita en curso, agenda resuelta, bitácora y cumpleaños— porque es exactamente lo que se guarda como snapshot offline (V-40): cinco endpoints serían cinco oportunidades de quedarse con medio día. **El día va en la ruta y es obligatorio:** el servicio conoce el país del asesor, no su zona horaria, y resolver «hoy» en UTC adelanta el día a las 21:00 en Santiago
  - Documentado en `Services/GarantiMax/doc/una-visita-en-curso.md`

- [x] **T-S08** — Endpoints de gestión: tareas, avances, agenda, cumpleaños y bitácora
  - Criterio de completitud: reimplementa las reglas de `crear_tarea_sala`, `completar_tarea`, `set_tarea_completada`, `calificar_tarea`, `tarea_avance_crear`, `limite_habil`, `cumpleanos_vendedores` y `vendedor_por_nombre` extraídas en T-13 y T-14. Bitácora con unicidad por asesor y día
  - Archivos creados: `Controllers/{Tasks,Agenda,FieldLog,Greetings}Controller.cs`, `Services/{BusinessCalendar,TaskNegotiation}.cs`, `Interfaces/IBusinessCalendar.cs`, sus DTO y `doc/limite-habil.md`
  - **`limite_habil` estaba mal documentado en los dos sitios donde lo teníamos**, y se descubrió al implementarlo: G-26 decía «el siguiente día hábil a la misma hora» y la nota del esquema decía «23:59:59». La función original hace **las dos cosas** según el día en que se creó la tarea — misma hora si fue día hábil, el día completo si fue fin de semana o feriado, porque a quien le encargan algo un domingo no lo vio. El detalle y los ejemplos, en `doc/limite-habil.md`
  - **Un solo calendario de días hábiles** para las tres reglas que dependen de él (G-08, G-09, G-26). En el sistema actual vivían en tres sitios y solo uno consultaba los feriados
  - **Ningún endpoint escribe el estado de negociación:** las seis transiciones pasan por `TaskNegotiation`, función pura sin `DbContext` ni reloj. Es la compensación por haber sacado la máquina de los *triggers* de PL/pgSQL, donde era imposible de saltar
  - **«Sus tareas» son dos cosas** —las que debe hacer y las que encargó (G-22)—; acotar solo por responsable le escondería a un jefe las que él mismo repartió
  - El «atrasada >48h» (G-20) viaja como **booleano y no como cuenta de días**: la aritmética de fechas dentro de la consulta no tiene traducción garantizada a SQL y habría compilado para fallar al abrir la lista
  - **Dos builds fallidos antes de compilar**, los dos por no verificar un nombre que estaba en disco: la política de *rate limiting* y el *namespace* de los enums

- [x] **T-S09** — Endpoints de gastos y rendiciones
  - Criterio de completitud: la **máquina de estados completa** (`borrador → enviada → aprobada_jefe → aprobada_ops → pagada`, más `rechazada` y el contador de reenvíos) con las transiciones válidas garantizadas en el servicio, no en la UI. Es el bloque con más negocio del alcance. La aprobación y el pago quedan **bloqueados** para el rol del asesor
  - Archivos creados: `[repo api] Services/GarantiMax/{Interfaces/IExpenseClaimWorkflow,Services/ExpenseClaimWorkflow,Controllers/{Expenses,ExpenseClaims}Controller,DTOs/Expenses/*}` y `doc/maquina-de-la-rendicion.md`
  - **La máquina está completa; los endpoints, no**, y es la forma que el criterio pide. Las seis transiciones están implementadas y validadas —incluidas aprobar como jefe, aprobar como Operaciones y marcar pagada— pero **solo `submit` tiene ruta**, porque en Fase 1 el asesor solo observa (E-42)
  - **Y el motivo de que el resto no tenga ruta es una pregunta abierta, no pereza:** autorizarlas necesita nombres de rol —quién es jefe, quién es Operaciones, quién es el Country Manager— y esa decisión sigue pendiente. Añadir dos rutas que cualquiera con la política del asesor pudiera llamar sería peor que no tenerlas. Cuando se decida, lo que se agrega es una política y dos rutas
  - **Enviar y reenviar son el mismo endpoint**, y los distingue el estado de partida. Preguntárselo al cliente dejaría que un reenvío llegara etiquetado como primer envío, perdiendo el contador que hace auditable el ida y vuelta (E-34)
  - **Al reenviar se limpian el rechazo y las aprobaciones del envío anterior**: describen una versión de la rendición que ya no es esta, y dejarlas haría que se leyera como rechazada mientras espera revisión
  - **El atajo de E-32 quedó con su condición precisa**: `enviada → aprobada_ops` salteándose al jefe vale solo si el dueño **no tiene jefe** en el organigrama. Escrito como «Operaciones siempre puede» dejaría que toda rendición se saltara a su jefe
  - **Nadie resuelve lo suyo**, y no está en el catálogo como regla aparte: en el organigrama nadie es su propio jefe, pero depender de que el organigrama esté bien es depender de un dato, y esto es dinero
  - **Los totales se calculan por moneda y nunca se almacenan** (E-24). Limitación dicha en voz alta: el desglose por moneda está en el **detalle** y no en la lista, porque una agrupación así no se traduce dentro de una proyección que OData pueda filtrar y forzarla significaría materializar todas las rendiciones para mostrar una página. La lista lleva la suma local y el conteo de lo no convertido, así que la honestidad de E-23 se mantiene
  - **Dos defectos encontrados al escribirlo y corregidos.** (1) La fusión de gastos cambiaba la clave ajena del archivo pero lo dejaba dentro de la colección del gasto que se borra: la cascada se habría llevado la foto que se acababa de salvar. (2) El estado `procesando` era **inalcanzable**, y es el que sostiene E-02 —la fila existe antes de la lectura, para que una lectura fallida nunca pierda la foto (E-03)—; el comando lleva ahora una bandera de «lectura pendiente», que es lo único del estado que el cliente sabe
  - **El dueño lo pone el servidor y el comando no tiene ese campo** (E-07). Un campo que se ignora es un campo que alguien va a probar
  - **Un gasto en una rendición enviada no se modifica**, con 409 y no 400: la petición está bien formada, es el momento el que no lo está
  - **La detección de duplicados (E-25, E-26) y la conversión de moneda (E-20 a E-23) no están aquí**: son de los casos de uso de gasto (T-57) y del servicio de tasas, y meterlas en el endpoint de guardado las habría dejado fuera del alcance de sus pruebas

> **Los endpoints con IA y los procesos programados** —lectura de boleta, transcripción, mejora de redacción, notificaciones y los dos periódicos— se construyen en la fase donde el frontend los consume (Fase 3 y Fase 4), no aquí. Su especificación son las Edge Functions actuales, y las credenciales de IA viven en `Options/`, nunca en el cliente.

---

### Fase 1 — Núcleo verificable del asesor: identidad, shell, offline, Mi Día y visitas (P1)

- [x] **T-20** — Dominio de identidad
  - Archivos creados: `src/domain/identity/{User,OperatingIdentity,Access,AdvisorProfile}.ts` + pruebas
  - Criterio de completitud: `Usuario` y `Rol` — ya no `Capacidad` (ADR-011); invariantes «los permisos del usuario son los de sus roles, resueltos una sola vez» y «un usuario sin perfil no puede operar»; regla de identidad efectiva vs. real para "Ver como". Todas con prueba unitaria y **sin backend**

- [x] **T-21** — Repositorio del perfil *(uno, no dos: ver corrección abajo)*
  - Archivos creados: `src/features/identity/ports/ProfileRepository.ts`, `src/features/identity/infrastructure/ApiProfileRepository.ts` + pruebas de mapeo
  - **Corrección del 28-08:** es **un** repositorio y no dos. El usuario y sus roles no se piden a ningún endpoint —viajan en el token— y el servicio se niega a exponerlos otra vez por el perfil, porque serían dos fuentes para el mismo hecho y solo una está firmada. Un `UserRepository` envolviendo al `AuthProvider` sería una capa que no traduce nada
  - Criterio de completitud: obtienen el perfil del asesor por endpoint y sus roles del JWT; el dominio nunca ve un DTO de transporte; errores HTTP traducidos a las categorías de T-05

- [x] **T-22** — Casos de uso de sesión
  - Archivos creados: `src/features/identity/application/{SignIn,SignOut,ResolveCurrentSession,DismissWelcome,DismissInduction}.ts` + pruebas con repositorios falsos
  - Criterio de completitud: cada uno devuelve resultado tipificado y no lanza excepciones de infraestructura; la resolución de permisos ocurre **una sola vez** a partir del token y se cachea; si el token no trae roles legibles es un error de infraestructura, **nunca** un permiso adivinado. `IniciarSesion` habla con el servicio `Authentication`; el token es lo único que el frontend persiste

- [x] **T-23** — Interfaz de autenticación
  - Archivos creados: `src/features/identity/ui/{LoginPage,NoProfilePage,SessionUnavailablePage,ProfilePage,SessionProvider}.tsx` y sus hooks
  - **Dos correcciones del 28-08.** (1) ~~y Google~~: el login de Google quedó fuera de todo alcance por decisión del responsable el 26-08 (identidad.md I-41), así que no hay botón ni librería. (2) ~~se renueva sola~~: **no puede** — `Services/Authentication` emite un `refreshToken` pero no expone ningún endpoint para canjearlo. Con la expiración por defecto (60 minutos) el asesor vuelve a entrar a media jornada, y eso exige señal. Queda como decisión pendiente del responsable
  - Y una pantalla que el PLAN no preveía: **«no pudimos comprobar tu sesión»**, para cuando el token es bueno y lo que falló fue preguntar por el perfil. Sin ella ese caso se confunde con «no tienes perfil», que es justo el error del sistema actual
  - Criterio de completitud: correo/contraseña y Google funcionando; la sesión persiste entre aperturas y se renueva sola; el caso "cuenta sin perfil" se informa y ofrece cerrar sesión (RF-01)

- [x] **T-24** — Autorización de rutas por rol
  - Archivos creados: `src/app/routes/guards.tsx`, `src/features/identity/ui/{usePermissions.ts,sessionDestination.ts}` + pruebas
  - **La sesión se resolvió como compuerta, no como redirección a `/entrar`:** no tener sesión no es un lugar de la aplicación, es un estado, y redirigir cambia la URL — con eso se pierde a dónde iba el asesor, salvo que alguien se acuerde de guardarla y restaurarla. La métrica del tier legacy es la quinta de `tools/metricas-arquitectura.mjs`, y busca el tier *usado como dato*: nombrarlo en un comentario para explicar por qué ya no está no cuenta como infracción
  - Criterio de completitud: la UI recibe una decisión ya tomada; ningún componente consulta permisos por su cuenta (RF-02); **cero** referencias al tier `CM/GTE/FARMER` en todo el repositorio, verificado en CI

- [x] **T-25** — Proveedor único de contexto de dispositivo
  - Archivos a crear/modificar: `src/app/providers/DeviceContextProvider.tsx` + pruebas
  - Criterio de completitud: resuelve en un solo lugar tamaño de pantalla, instalación como PWA, cámara, geolocalización y estado de conexión, y **expone una decisión, no datos crudos**; la regla de linter (T-09.4) impide cualquier acceso directo desde componentes

- [x] **T-26** — Layout adaptativo y app shell
  - Archivos a crear/modificar: `src/shared/layouts/{LayoutAdaptativo,NavegacionLateral,NavegacionInferior,AppShell}.tsx`
  - Criterio de completitud: pantalla ancha con navegación lateral y densidad alta; estrecha con navegación inferior, una tarea por pantalla y acciones al alcance del pulgar; **mismas rutas y mismo estado en ambos** (RF-22, RNF-16)
  - **«Mismas rutas» dejó de ser una aspiración:** la navegación es un **dato** que las dos presentaciones reciben, así que ninguna puede inventarse un destino, y hay pruebas que comparan los dos layouts y exigen los mismos enlaces y el mismo contenido. Si alguien le agrega una pantalla a uno solo, fallan
  - Los iconos de la navegación inferior esperan a T-19: uno inventado por destino se adivina mal y hay que aprenderlo igual
  - Las rutas cuelgan de una **ruta de layout** que envuelve, en orden, la compuerta de sesión y el armazón

- [x] **T-27** — Mapa de rutas con carga bajo demanda
  - Archivos a crear/modificar: `src/app/routes/*.tsx`
  - Criterio de completitud: cada pantalla tiene URL propia, navegable, compartible y con historial funcional (RF-23); cada ruta carga su código bajo demanda y la carga inicial no incluye módulos que el asesor no usa (RNF-20), verificado con el análisis del bundle en CI
  - **Escribir `React.lazy` no basta, y esto se descubrió aquí:** el troceado se perdió en el primer intento porque el barril `features/identity/ui/index.ts` reexportaba la pantalla, y ese barril se importa desde caminos que se cargan al arrancar. Vite lo avisa (`INEFFECTIVE_DYNAMIC_IMPORT`) entre decenas de líneas de salida. Ahora **las pantallas que son destino de ruta no se exportan por el barril** y `tools/analiza-bundle.mjs` lo verifica en CI sobre el manifiesto del build
  - Techo de la carga inicial: **150 KB comprimidos** (hoy 107, casi todo React + Router + Query). Holgado a propósito: un margen que salta cada semana se sube sin mirar
  - Se corrigió de paso el paso de build de CI, que no tenía `VITE_AUTH_BASE_URL` desde que T-08 la hizo obligatoria — habría fallado en el primer PR

- [x] **T-28** — Bienvenida y perfil
  - Archivos a crear/modificar: `src/features/identidad/ui/BienvenidaPage.tsx` y el caso de uso `MarcarBienvenidaVista` (RPC `marcar_bienvenida_vista`)
  - Criterio de completitud: pantalla descartable por el usuario y persistente por perfil; muestra datos básicos del asesor y su asignación
  - **Mientras está pendiente, cualquier ruta lleva a ella**, y va fuera del armazón: si se pudiera saltar navegando a otra parte dejaría de cumplir su único propósito, y una barra de navegación solo ofrecería botones que devuelven aquí
  - Al descartarla se **actualiza la sesión en caché** con el perfil que devuelve el caso de uso, en vez de volver a pedirla: sin señal la marca queda encolada, y volver a preguntar dejaría al asesor mirando la bienvenida otra vez. Si el servicio no pudo guardarla, no se da por descartada
  - **La cartera de salas no se muestra:** el endpoint de perfil no la trae —viaja en los catálogos de referencia (T-33)— y una lista inventada en la bienvenida es la peor primera impresión posible

- [x] **T-29** — Dominio de operación encolada
  - Archivos a crear/modificar: `src/domain/shared/OperacionEncolada.ts` + pruebas
  - Criterio de completitud: estados `pending → syncing → completed | failed`; identificador de idempotencia obligatorio; política de reintentos con espera creciente hasta un tope y luego acción manual, **única para toda la aplicación**; todo probado con `ClockProvider` simulado
  - **Se cerró la pregunta abierta de `visitas.md` V-36** («el tope de 12 intentos no tiene justificación escrita: pueden agotarse en minutos o durar días»). Con la espera creciente elegida —5 s duplicándose hasta un techo de 5 min— doce intentos **no pueden** durar menos de media hora, así que el número implica un piso de tiempo. Hay una prueba que lo fija
  - **`failed` no descarta la operación**, a diferencia del sistema actual: allí el ítem se borraba y su contenido se mandaba a monitoreo, de modo que el trabajo del asesor sobrevivía solo en un panel de errores

- [x] **T-30** — Cola offline sobre `LocalStore`
  - Archivos a crear/modificar: `src/shared/sync/ColaOffline.ts`, `src/infrastructure/local/IndexedDBLocalStore.ts` (extensión para blobs) + pruebas
  - Criterio de completitud: persiste operaciones **con sus imágenes**, conserva el orden, sobrevive al cierre de la aplicación y se prueba sin navegador
  - **El orden hubo que construirlo:** IndexedDB recorre por clave y las nuestras son UUID, cuyo orden alfabético es arbitrario. Cada registro lleva número de secuencia, actualizar conserva el suyo, y el contador se siembra al abrir con el mayor de la base — sin eso, al reabrir la aplicación lo de hoy se ordenaría antes de lo que quedó pendiente de ayer

- [x] **T-31** — Decorador offline genérico y casos de uso de sincronización
  - Archivos a crear/modificar: `src/shared/sync/conOffline.ts`, `src/shared/sync/application/{EncolarOperacion,DrenarCola,ReintentarOperacion,ObtenerEstadoDeSincronizacion}.ts` + pruebas
  - Criterio de completitud: el decorador implementa la misma interfaz del repositorio (ADR-009); **ningún caso de uso contiene `if (online)`**; un `NetworkError` en una operación encolable se traduce en encolamiento y no en error visible (A1 §10, regla 2); el drenaje **no vive en el árbol de componentes** ni depende de qué pantalla esté montada
  - **Tres decisiones que el criterio no anticipaba.** (1) Solo se declara encolable un método que devuelve `Promise<void>`, y el tipo lo obliga: cuando la operación se encola no hay resultado que devolver, y un valor de relleno es como nacen los «guardado con éxito» sobre datos que nunca se guardaron. (2) Se encola también el `ProviderError` (408, 429, 5xx), extendiendo la regla 2 a propósito — un 502 pasajero no debe costar la visita escrita, y reintentar es seguro porque la clave primaria es la clave de idempotencia. (3) Si la **cola** no pudo guardar, la operación falla en vez de devolver silencio: el mensaje de `NetworkError` promete que se guardó
  - **El drenaje se detiene en el primer fallo.** El orden de la cola es el orden en que el asesor hizo las cosas y hay operaciones que dependen de otras; seguir haría que el cierre llegue al servidor antes que la apertura
  - **Se cerró un hueco de `identidad.md` I-30 que no estaba implementado:** la cola vive en el dispositivo y el dispositivo se comparte, así que cada operación lleva ahora el **usuario real** como dueño y la cola solo muestra lo suyo. Sin eso, el trabajo pendiente de un asesor lo habría enviado la sesión del siguiente con el token del siguiente

- [x] **T-32** — Estado de sincronización observable
  - Archivos a crear/modificar: `src/shared/sync/store.ts` (Zustand), `src/shared/ui/IndicadorSincronizacion.tsx`
  - Criterio de completitud: el asesor ve pendiente / en curso / fallida y puede reintentar manualmente desde cualquier pantalla (RF-21)
  - **La cola se volvió observable** (`onChange`) en lugar de encuestarla: encuestar cada segundo gasta batería en un teléfono que el asesor lleva todo el día y encima llega tarde — entre encuesta y encuesta el indicador miente
  - **Tres estados y ninguno más.** Sin nada pendiente el indicador **no se muestra**: un aviso permanente que casi siempre dice «todo bien» deja de leerse. Pendiente o enviando, aviso discreto — trabajar sin señal es lo normal en terreno. Agotado, aviso con botón, y lo primero que dice es que **nada se perdió**
  - `retryFailedOperations` es un caso de uso y no un bucle dentro del manejador del botón: «qué significa reintentar» es una decisión de aplicación

- [x] **T-33** — Dominio de visita
  - Archivos a crear/modificar: `src/features/visitas/domain/*.ts` + pruebas
  - Criterio de completitud: `planificada → en_curso → cerrada | descartada`; **una visita en curso por asesor** como invariante del dominio (RF-06); ~~una visita en curso exige sala, hora de inicio y ubicación~~; no se cierra sin registro de lo observado; un usuario impersonado no puede descartar. Cada regla de `docs/reglas/visitas.md` (T-13) tiene su prueba
  - **Dos correcciones al criterio, siguiendo en ambos casos la regla levantada del sistema actual, que es la que tiene el motivo escrito.** (1) La **ubicación no es obligatoria**: V-20 dice lo contrario y explica por qué — bloquear la visita por un permiso denegado deja al asesor sin poder trabajar. (2) «No se cierra sin registro de lo observado» se implementó con el umbral **deliberadamente más bajo posible** —un punto del decálogo respondido, un comentario o un acuerdo—; el sistema actual no exige nada de eso, y un umbral alto es lo que el asesor sortea con datos falsos para cerrar una visita que sí hizo
  - El decálogo se portó del `decalogo.ts` original: **las diez claves siguen en español** porque son contrato de datos con historia (V-24), y hay una prueba que las fija letra por letra

- [x] **T-34** — `VisitaRepository` por agregado
  - Archivos a crear/modificar: `src/features/visitas/ports/VisitaRepository.ts`, `src/features/visitas/infrastructure/ApiVisitaRepository.ts` + pruebas de mapeo
  - Criterio de completitud: una sola interfaz cubre `visitas`, `visitas_abiertas` y `visitas_en_curso` (ADR-003) —dos tablas tras unificarlas en T-S03—; la interfaz habla en lenguaje de negocio; el dominio no sabe cuántas tablas hay
  - **Ningún método recibe el asesor**, al contrario de lo que sugería la firma del criterio: ningún endpoint acepta un id de asesor, lo resuelve del token (I-01). Un parámetro que no se usa sugiere que se puede pedir la visita de otro, que es justo lo que el servicio rechaza
  - **Los enums viajan como números** —ningún servicio del monorepo registra `JsonStringEnumConverter`— y el contrato quedó **fijado por una prueba** en vez de deducido: agregar un valor en medio del enum de C# corre todos los de abajo

- [x] **T-35** — Casos de uso de visita
  - Archivos a crear/modificar: `src/features/visitas/application/{IniciarVisita,GuardarBorradorVisita,CerrarVisita,DescartarVisitaEnCurso,ObtenerVisitaEnCurso}.ts` + pruebas
  - Criterio de completitud: `DiscardOpenVisit` verifica identidad efectiva vs. real y limpia las capas **en orden** —servidor con `await` y después el teléfono—, devolviendo resultado tipificado; todas las pruebas corren sin backend. Son dos capas y no tres: `visitas_abiertas` se unificó con el borrador en T-S03
  - **Qué se espera y qué es best-effort** es la decisión central del tramo: el teléfono siempre se espera —si falla, se avisa antes de empezar la visita, no al cerrarla—; el servidor es best-effort en check-in y autoguardado (V-15); **cerrar no es best-effort**
  - **Si no se pudo saber si hay una visita abierta, no se abre otra:** fallar cerrado cuesta un intento, fallar abierto cuesta la visita que el asesor tenía a medias
  - Un error real que destapó una prueba: `toOutcome` solo reconocía las reglas del dominio de visitas, así que descartar con «Ver como» activo —que lo prohíbe `OperatingIdentity`— caía en «no pudimos hacerlo, inténtalo de nuevo», un mensaje falso para una regla que no se salta reintentando

- [x] **T-36** — Decorador offline de visitas
  - Archivos a crear/modificar: `src/features/visitas/infrastructure/VisitaRepositoryOffline.ts` + pruebas
  - Criterio de completitud: check-in, guardado de borrador y cierre se encolan sin señal con idempotencia; el borrador sobrevive al cierre de la app y a la falta de señal (RF-07); reintentar no duplica la visita (RNF-09)
  - **Son 40 líneas**, y eso es el resultado de T-31: se declara qué es encolable y con qué clave, nada más. En el sistema actual el soporte offline de visitas son ~500 líneas propias y las boletas tienen otras tantas distintas para el mismo problema
  - **El prefijo de la clave del borrador no es cosmético:** sin él, autoguardado y cierre de la misma visita compartirían clave en la cola y el segundo pisaría al primero. Con él, cincuenta autoguardados se colapsan en una sola operación y gana el último

- [x] **T-37** — Interfaz de visita
  - Archivos a crear/modificar: `src/features/visitas/ui/{CheckInPage,VisitaEnCursoPage,CierreVisitaPage}.tsx` + hooks de UI
  - Criterio de completitud: check-in con sala, hora y ubicación; cronómetro de duración; captura de lo observado; cierre (RF-05, RF-08); toda acción produce retroalimentación visible en ≤ 200 ms aunque la operación siga en curso (RNF-07)
  - **El check-in pide dos cosas: sala y tipo.** El asesor está de pie en la puerta con el teléfono en una mano; cada campo de más ahí es un minuto que no está saludando al jefe de sala. La hora es la del toque y la ubicación no se espera (V-20)
  - **No hay botón de guardar:** autoguardado con 700 ms de espera (V-12) más un guardado de emergencia en `visibilitychange` (V-13), que es lo que salva el trabajo cuando entra una llamada
  - **El cronómetro vive aislado** (V-22): dentro del formulario, los diez puntos del decálogo se redibujarían cada segundo
  - **Las interacciones por vendedor y las ventas quedaron hechas el 31-08-2026**, con el catálogo de vendedores ya disponible. Son una **lista con hoja y no un formulario largo**: cuatro datos por vendedor y una sala tiene entre tres y diez, así que puestos a la vez son cuarenta controles en un teléfono sostenido con una mano. La lista resume lo registrado por vendedor —«Capacitación · 3 unidades» o «Sin registrar»— y el asesor ve de un golpe a quién le falta
  - **«No anoté» y «anotó cero» no se confunden:** vacío quita la línea de venta, un cero la conserva. Y el catálogo de vendedores **se guarda como snapshot**, porque una visita ocurre justo donde puede no haber cobertura: sin la lista no hay interacciones que registrar

- [x] **T-38** — Aviso global de visita en curso
  - Archivos a crear/modificar: `src/features/visitas/ui/AvisoVisitaEnCurso.tsx` y su estado transversal
  - Criterio de completitud: visible desde cualquier pantalla con las opciones continuar o descartar; **de solo lectura con "Ver como" activo**; la regla vive en el dominio y el aviso solo la refleja (RF-06)
  - A las tres horas escala **con el mismo umbral que el correo del servicio** (V-07): con dos números, el asesor vería una cosa en la pantalla y leería otra en su bandeja
  - Ocultar el botón de descartar **no es la defensa**: el caso de uso lo comprueba otra vez y el servicio también. Es no ofrecer lo que va a ser rechazado

- [~] **T-39** — Evidencia de visita *(código completo; falta la verificación de corte de red de T-66)*
  - Archivos creados: en la API, `Controllers/FilesController.cs`, `Interfaces/IFileStorage.cs`, `Services/S3FileStorage.cs`, `Options/FileStorageOptions.cs`, `doc/donde-viven-las-fotos.md`; en el frontend, `src/infrastructure/storage/ApiStorageProvider.ts` + pruebas
  - Criterio de completitud: captura desde cámara, subida a Storage y **encolado sin señal igual que las boletas**; ninguna imagen se pierde en las pruebas de corte de red
  - **Decidido el 31-08-2026: los blobs van a S3**, y el bucket existe desde el 04-09. El servicio **arranca sin `FileStorage` configurado a propósito**: validarlo al arrancar dejaría caído el servicio entero por una funcionalidad que nadie puede usar aún, así que los endpoints responden 503 con un mensaje utilizable —«registra la visita sin evidencia»— y el resto sigue trabajando. Esa degradación se queda: es la que protege al asesor el día que el bucket falle
  - **La clave la propone el cliente y el servidor la acota.** `{prefix}/{advisorId}/{scope}/{path}`: el `path` es un uuid del teléfono y la subida sobreescribe (V-31), pero el asesor y el ámbito los pone el servidor desde el token. Por eso no hay consulta de «¿este archivo es mío?»: un archivo que no subió no tiene una clave que pueda nombrar
  - **Se corrigió el contrato `StorageProvider`**, que decía que la ruta la decide el servicio. Estaba mal: con una ruta del servidor, cada reintento de la cola habría creado un objeto nuevo y la fila se habría quedado apuntando al primero, el resto huérfano y pagándose en la factura de S3
  - **Cerrada la parte de código el 04-09-2026.** Reutiliza entero el motor de T-58: `FileUploader` y `LocalFileStore` no saben de gastos ni de visitas, así que la subida sin señal estaba resuelta una sola vez
  - **V-34 sale gratis, y es lo mejor del cambio.** La regla pide el orden «blobs → INSERT idempotente → agenda», y en el sistema actual lo garantizaba un sincronizador que ordenaba los tres pasos a mano dentro de `persistirUno`. Aquí no hay nada que ordenar: la foto se adjunta **mientras el asesor está en la sala** y el cierre ocurre después, así que la subida entra en la cola antes que el cierre y la cola drena en orden de llegada. Es la diferencia entre una regla que se cumple porque está escrita y una que se cumple porque **no hay forma de escribirla al revés**
  - **V-33 traducido**: nuestra pantalla no es un asistente de nueve pasos, así que «el paso» pasa a ser «la sección de la que cuelga la foto». Tres tarjetas —decálogo, ventas, general— y no un cajón único, porque un cajón obligaría a preguntar el paso con un desplegable, y un desplegable que hay que rellenar en cada foto se rellena mal: el asesor está de pie con el teléfono en una mano. Los identificadores se conservan los del sistema actual donde la sección significa lo mismo
  - **Quitar una foto no cancela la subida ni borra el archivo**, y está escrito por qué: la cola no tiene método para cancelar —y darle uno abriría cancelar cualquier cosa—, y borrar el blob dejaría a la operación encolada sin bytes, que es justo el caso que `QueuedFileUploader` reporta a monitoreo. Sería una alarma por cada foto que el asesor descartó a propósito. El coste es un objeto huérfano que nada referencia
  - **Sin evento de BI**, también por decisión: la pregunta que un `foto_adjuntada` respondería —¿las visitas nuevas llevan tanta evidencia como las viejas?— **ya la contesta el dato**, porque `photoCount` viaja en el resumen de cada visita. El catálogo cerrado de T-63 sigue cerrado
  - `prepareReceipt` pasó a **`prepareUpload`**: T-39 necesitaba exactamente lo mismo —validar, comprimir, respetar el EXIF— y un nombre que decía «boleta» habría empujado a escribir una segunda copia para las visitas
  - **Sigue en `[~]` a propósito.** El criterio pide que «ninguna imagen se pierda en las pruebas de corte de red», y esas pruebas son T-66, que espera el sistema corriendo. Lo que sí está verificado son las unitarias: sin señal la foto se queda en el dispositivo, la operación se encola con el puntero y al drenar se sube. Marcarla `[x]` afirmaría algo que nadie ha comprobado de punta a punta

- [x] **T-40** — Lobbies y otros eventos
  - Archivos creados: `src/features/visits/domain/Lobby.ts`, `ports/LobbyRepository.ts`, `infrastructure/{ApiLobbyRepository,offlineLobbyRepository}.ts`, `application/SaveLobby.ts`, `ui/{LobbyPage,LobbyHistoryPage}.tsx`, `app/routes/LobbyRoutes.tsx` + pruebas
  - Criterio de completitud: comparten el ciclo de la visita **sin exigir sala**; tienen detalle e historial propios (RF-09)
  - **No hay `RegistrarOtroEvento`, y el motivo que se anotó aquí era equivocado.** Se dijo que «otro evento» era un lobby sin sala; **no lo es**: `RegistrarOtro.tsx` del sistema actual escribe en `agenda_eventos` con `tipo: 'otro'` y estado `hecho`. Es un **evento de agenda**, y lo cubre el feature de agenda —que ya admite ese tipo (T-49)— en cuanto exista su pantalla (T-50). Corregido el 02-09-2026 al revisar la paridad contra el repositorio del sistema actual
  - **Y no hay `OpenLobby`.** Un lobby no tiene ciclo abierto: no hay check-in, ni cronómetro, ni borrador, porque se anota **después** de que ocurrió. Por eso su pantalla sí tiene botón de guardar, al contrario que la de la visita: no hay nada que salvar de una llamada entrante cuando el asesor no está en medio del evento
  - **El costo vacío es `null` y no cero** (V-50), y la distinción se mantiene en las cinco capas: el campo, el dominio, el repositorio, el viaje por IndexedDB y la línea del historial —«Sin costo registrado» y «$0» son dos frases—. Colapsarla en la pantalla habría deshecho al final lo que todo lo demás se molesta en mantener
  - El decorador offline son **40 líneas y una sola operación**, con el id del lobby como clave: reintentar no crea un segundo lobby (V-48, RNF-09)

- [x] **T-41** — Casos de uso de Mi Día y snapshot
  - Archivos creados: `src/features/visits/application/GetMyDay.ts`, `src/features/visits/{ports/MyDayRepository,infrastructure/ApiMyDayRepository}.ts`, `src/shared/sync/Snapshot.ts` + pruebas
  - Criterio de completitud: compone agenda del día, tareas pendientes, visitas planificadas y cumpleaños; el snapshot se persiste con su marca de tiempo y **caducidad explícita**; sin conexión devuelve el último snapshot indicando su antigüedad (RF-03, RF-04)
  - **Una petición y no cinco.** `GET /api/MyDay/2026-08-31` devuelve el día entero porque lo que devuelve es exactamente lo que se guarda como snapshot: cinco endpoints serían cinco oportunidades de quedarse con medio día —la agenda de hoy con los cumpleaños de ayer—. El día va en la ruta porque **identifica** al recurso; lo que se acota se acota con OData, y OData filtra colecciones
  - **Desviación deliberada — la caducidad es el día, no un plazo.** El plan pedía una caducidad explícita en minutos u horas. Se implementó por **fecha y dueño**: el snapshot solo se devuelve si es del día que se pide y del asesor que lo guardó. Un plazo en minutos daría dos comportamientos peores: uno corto deja al asesor sin nada a media mañana en una sala sin señal, y uno largo permitiría mostrar el día de ayer como si fuera hoy. El día es la unidad real del dato
  - **No hay `SincronizarMiDia`.** No hace falta un caso de uso aparte: Mi Día es lectura, y quien lo refresca es la consulta al volver el foco (V-44). Lo que se sincroniza son las operaciones del asesor, y de eso ya se encarga la cola de T-30
  - **El snapshot se borra al cerrar sesión y la cola no** (V-42): el teléfono de terreno se comparte, pero perder trabajo sin enviar es mucho peor que guardar datos de más. `createSignOut` recibe un `forget` opcional que `main.tsx` conecta al borrado

- [x] **T-42** — Interfaz de Mi Día
  - Archivos creados: `src/features/visits/ui/MyDayPage.tsx`, `src/app/routes/MyDayRoute.tsx` + pruebas
  - Criterio de completitud: una sola implementación para escritorio y móvil (la métrica del PRD §12: de 2 a 1); acceso directo a registrar cada cosa; interactivo en ≤ 2 s con conexión y ≤ 1 s desde snapshot (RNF-06), medido contra la línea base de T-17
  - **De dos implementaciones a una, cumplida.** En el sistema actual la pantalla existe dos veces —`MiDiaMovil.tsx` con 972 líneas y su equivalente de escritorio— y cada arreglo hay que hacerlo dos veces. Aquí lo que cambia entre ancho y estrecho lo resuelve el armazón de T-26; la pantalla no sabe en cuál está
  - **Lo guardado pinta primero, la red corrige después.** Sin eso, el asesor con señal lenta mira una pantalla vacía sabiendo que su agenda está ahí, en su teléfono. Y el snapshot que llega tarde **no pisa lo fresco**: el almacén puede tardar más que la red, y retroceder la pantalla a datos viejos delante del asesor sería peor que no pintarlos
  - **Dice de cuándo son los datos** (V-43): «Sin señal. Estos son los datos guardados a las 08:40». Enseñar la agenda de las ocho como si fuera de ahora es cómo se llega tarde a una cita que se movió
  - `/` deja de redirigir al perfil y **es** Mi Día; la navegación queda Mi día / Visitar / Mi perfil
  - **Falta la medición contra la línea base de T-17**, que sigue sin tomarse. El trozo de la pantalla pesa 4.3 KB y no viaja en la carga inicial, pero eso es tamaño, no tiempo en un teléfono de terreno

- [x] **T-43** — Catálogos de referencia en solo lectura
  - Archivos a crear/modificar: `src/features/referencia/{ports,infrastructure,application}/*` + pruebas
  - Criterio de completitud: lectura de `salas`, `sala_vendedores`, `vendedores`, `clientes`, `proyectos`, `feriados` y del historial de sala; **ninguna operación de escritura expuesta** (RF-24); la frontera con Fase 2 queda declarada en el propio contrato
  - **Clientes y proyectos quedaron con contrato y sin pantalla, a propósito.** Sus consumidores son de fases posteriores —un proyecto se elige al cargar un gasto o una tarea; un cliente es dato informativo de la sala, que ya viaja con `customerName`—. Construir una pantalla que nadie pidió sería adivinar; dejar el contrato probado es lo que esta tarea existe para dejar
  - **El «historial de sala» es el historial de visitas filtrado**, no una lectura aparte: el repositorio ya sabía filtrar por sala. La sala elegida vive en la URL (`?sala=`) para poder volver, compartir y recargar (RF-23), y hay **dos estados vacíos distintos** —«no tienes visitas» y «no tienes visitas en esta sala»— porque con uno solo, quien filtra por una sala nueva creería que perdió su historial
  - **La prueba que enumera los métodos del repositorio hizo su trabajo:** al agregar `customers` y `projects` falló y obligó a justificarlos. Los cinco siguen siendo lecturas

### Fase 2 — Gestión del asesor: tareas, agenda, cumpleaños y bitácora (P2)

- [x] **T-44** — Dominio de tarea
  - Archivos a crear/modificar: `src/features/tareas/domain/*.ts` + pruebas
  - Criterio de completitud: `abierta → en_progreso → completada | cancelada`; los avances son **inmutables** una vez registrados; solo una tarea completada admite calificación; se conserva el vínculo con la sala o el plan que la originó
  - **Desviación: esa máquina de estados no existe.** La extracción de reglas (T-14) encontró que una tarea tiene un **booleano** de completada y un estado **derivado** —completada, atrasada, pendiente (G-19)—, y que la máquina de verdad es otra: la **negociación** —pendiente, aceptada, rechazada, cambio propuesto (G-24)—, que este PLAN no mencionaba. Se implementó lo que hay. Lo demás del criterio sí se cumple: los avances son inmutables (no hay editar ni borrar, ni en el frontend ni en el servicio) y solo lo completado admite nota

- [x] **T-45** — `TareaRepository`
  - Archivos a crear/modificar: `src/features/tareas/{ports,infrastructure}/*.ts` + pruebas de mapeo
  - Criterio de completitud: cubre `plan_tareas`, `tarea_avances`, `tarea_comentarios` y las RPCs `crear_tarea_sala`, `completar_tarea`, `set_tarea_completada`, `calificar_tarea`, `tarea_avance_crear`, todas detrás del contrato

- [x] **T-46** — Casos de uso de tareas y su decorador offline
  - Archivos a crear/modificar: `src/features/tareas/application/{CrearTarea,RegistrarAvance,CompletarTarea,CalificarTarea,ListarMisTareas}.ts`, `src/features/tareas/infrastructure/TareaRepositoryOffline.ts` + pruebas
  - Criterio de completitud: registrar un avance sin señal se encola y no se pierde (RNF-08); reintentar no duplica el avance
  - Las dos mitades del criterio viven en sitios distintos: **no se pierde** porque el método es encolable, y **no se duplica** porque su clave es el id del **avance** y no el de la tarea. Con la de la tarea, dos avances del mismo día se colapsarían en uno y el asesor perdería el de la mañana
  - **Proponer un cambio y responderlo NO se encolan**, y no es limitación técnica: son una **conversación**. Encolarlas dejaría al asesor creyendo que negoció algo que el otro no ha visto, con la propuesta viajando horas después sobre una tarea que quizá ya cambió

- [x] **T-47** — Interfaz de tareas
  - Archivos a crear/modificar: `src/features/tareas/ui/*.tsx`
  - Criterio de completitud: lista, detalle, avances comentados, calificación y cierre, adaptativa en ambos contextos (RF-10)
  - **El detalle tiene URL propia** (`/tareas/:id`) y no es una hoja sobre el listado: es donde se trabaja, y las notificaciones de G-30 hablan de una tarea concreta, así que tienen que poder llevar a ella
  - **Lo que espera aceptación va arriba del listado**, sin importar el filtro: es lo único de esa pantalla que el asesor puede perder por no haberlo visto, porque tiene plazo (G-26)
  - **Rechazar y proponer no son un botón:** abren una hoja con su campo, porque el motivo del rechazo es todo el contenido de la notificación que recibe el mandante (G-28)
  - ⚠️ **Se cerró con un hueco, y lo destapó T-68 el 03-09-2026.** `tasks.create` estaba en el contrato de servicios y **ninguna pantalla lo llamaba**: el asesor no podía crear una tarea. El dominio, el caso de uso y el endpoint sí estaban. Cerrado con `NewTaskSheet` el mismo día. Vale registrarlo porque es el primer «hecho» de este plan que no lo estaba, y lo encontró la lista de paridad haciendo su trabajo

- [x] **T-48** — Dominio de agenda y días hábiles
  - Archivos a crear/modificar: `src/domain/agenda/*.ts` + pruebas con `ClockProvider` simulado
  - Criterio de completitud: `agendado → realizado | reagendado | cancelado`; un evento no se agenda en día inhábil salvo marca explícita; el cálculo de días hábiles y feriados se prueba **sin base de datos** contra los casos de `docs/reglas/gestion.md`
  - **Dos desviaciones.** «Reagendado» **no es un estado**: el catálogo dice `pendiente · hecho · cancelado` (G-31) y reagendar cambia la fecha dejando el evento pendiente; guardarlo como estado dejaría eventos que nadie sabe si ocurrieron. Y un día inhábil **avisa, no bloquea**: no hay tal regla en el catálogo, y un lobby de un sábado o una capacitación en feriado son eventos legítimos
  - Los días hábiles viven en `src/domain/agenda/` **compartido**, no en el feature: de la misma respuesta dependen la agenda, la bitácora (G-09) y el plazo de aceptación de una tarea (G-26). Se prueban sin base de datos, con los feriados como conjunto
  - Una prueba encontró un defecto real: `isBusinessDay('2026-02-31')` devolvía `true`. Ahora una fecha que no existe no es hábil (RF-12)

- [x] **T-49** — `AgendaRepository` y casos de uso
  - Archivos a crear/modificar: `src/features/agenda/{ports,infrastructure,application}/*.ts` + pruebas
  - Criterio de completitud: cubre `agenda_eventos`, `feriados` y la función `limite_habil`; casos de uso `AgendarEvento`, `MarcarEventoRealizado`, `ReagendarEvento`, `CancelarEvento`, `ObtenerAgendaDelDia`
  - `ObtenerAgendaDelDia` es `ObtenerAgenda` con `from === to`: un caso de uso aparte para un rango de un día sería el mismo código con otro nombre
  - **El cliente HTTP ganó `patch`**: el servicio expone la actualización del evento como PATCH y no PUT a propósito, y la primera versión usaba `put` —habría respondido 405—. Segundo hueco del cliente compartido que destapa un endpoint nuevo, después de la cadena de consulta con dos `?`
  - Las cuatro escrituras se encolan, y **reagendar dos veces manda la última fecha** porque comparten clave: si el asesor lo mueve al jueves y después al viernes, lo que tiene que llegar es el viernes

- [x] **T-50** — Interfaz de agenda
  - Archivos creados: `src/features/agenda/ui/AgendaPage.tsx`, `src/app/routes/AgendaRoutes.tsx`, `src/domain/agenda/months.ts`, `src/shared/ui/{dates,Checkbox}.tsx`, `src/features/reference/application/ListHolidays.ts` + pruebas
  - Criterio de completitud: calendario adaptativo; se agenda desde Mi Día; se marca realizado, cancelado o reagendado (RF-11)
  - **Adaptativo con un solo marcado, y sin JavaScript.** Un `grid-cols-1 sm:grid-cols-7` y tres clases: las cabeceras de la semana y las celdas vacías del principio son `hidden sm:block`, y **un día sin nada también**. En ancho es el mes completo con sus huecos; en estrecho, el mismo marcado se queda solo con los días que tienen algo. Es la métrica del PRD §12 otra vez —de dos implementaciones a una—: en el sistema actual el calendario es dos pantallas. Hay una prueba que espía `matchMedia` y falla si alguien lo resuelve en JavaScript
  - **Las pruebas de esta pantalla miran clases de CSS, y es la única excepción del proyecto.** Está razonada en la cabecera del archivo: si el comportamiento vive en el CSS, la única forma de comprobarlo es mirar el CSS, y jsdom no tiene maquetación. T-73 tiene que conservar ese mecanismo
  - **Agendar desde Mi Día es un toque**: `/agenda?nuevo=AAAA-MM-DD` abre el formulario ya en ese día. Y **no** es la acción duplicada que se corrigió en T-42: «Empezar una visita» se hace ahora, «Agendar algo» se anota para después
  - **El «otro evento» ya ocurrido, en un solo paso.** `RegistrarOtro.tsx` escribe tipo `otro` con estado `hecho` de una vez. El POST del servicio fijaba `Pending` a mano, así que reproducirlo eran dos operaciones —crear y marcar— y **sin señal la cola puede entregarlas en orden inverso**: el PATCH de un evento que todavía no existe falla y el asesor se queda con un evento pendiente de algo que ya pasó. Se cambió el servicio (`SaveAgendaEventRequest.State` opcional, `null` = `Pending`, nacer `Cancelled` es un 400) y en el frontend es la casilla «Ya ocurrió», visible **solo para «Otro»**: una visita tiene check-in y cierre y un lobby su propia pantalla
  - **«Tarea» no se ofrece como tipo** (G-32): una tarea se superpone al calendario por su fecha. Ofrecerla crearía un evento suelto que no es la tarea, y mover la tarea no movería el evento
  - **Los feriados se piden por año** y no por mes —cambian una vez al año—, y si fallan el calendario **sigue funcionando** con solo los fines de semana, que es lo que el dominio deja hacer a propósito. Un asesor que no puede abrir su agenda porque no se leyó el catálogo de feriados está peor que uno al que el 18 de septiembre le sale hábil
  - **Leer el calendario exige conexión y no se encola**: un mes pintado desde escrituras pendientes sería un mes inventado. Lo que se guarda para abrir sin señal es el día (T-41)
  - **Aritmética de meses en el dominio, no en la pantalla** (`months.ts`). Una pantalla que calcule su propia rejilla reintroduce el error de zona horaria —`new Date(2026-09-01)` es el 31 de agosto en Chile— y encima solo se nota en la primera y la última celda del mes
  - **El sistema de T-19 no tenía casilla de verificación**, y ahora la tiene. Costó dos intentos: con el texto de ayuda dentro del `<label>`, el nombre accesible es la etiqueta más la ayuda pegadas, y un lector de pantalla anuncia «Ya ocurrió Se guarda como hecho…, casilla». Lo destapó una prueba que no encontraba la casilla por su etiqueta
  - **T-43 había dejado los feriados sin caso de uso.** Se agregó `ListHolidays`: sin él la pantalla tendría que llamar al repositorio, que es la puerta por la que TanStack Query se convierte en la nueva forma de meter consultas en las vistas

- [x] **T-51** — Cumpleaños y saludos
  - Archivos creados: `src/features/agenda/{domain/Greeting,ports/GreetingRepository,infrastructure/{ApiGreetingRepository,offlineGreetingRepository},application/greetings,ui/GreetingSheet}` + pruebas; `[repo api] Controllers/GreetingsController` (GET) y `DTOs/MyDay`
  - Criterio de completitud: el asesor ve quién cumple años en Mi Día, saluda en dos toques y puede ver después lo que mandó (RF-13)
  - **Corrección al criterio original.** Decía «el saludo queda registrado como interacción». **No es así en el sistema actual**: `guardarSaludo` escribe solo en `saludos_cumpleanos` y no crea ninguna interacción. Lo que sí ocurre —y es lo implementado— es que aparece en Mi Día como saludado, con su medio. Verificado en `../garantimax` el 02-09-2026
  - **No hay `ObtenerCumpleanosDelDia`, y es deliberado.** Quién cumple años hoy **viaja en Mi Día**, que es la única petición con la que se abre la jornada. Un caso de uso aparte que respondiera lo mismo sería un segundo sitio donde mantener la regla de que la coincidencia ignora el año (G-38) y dos cachés que se desincronizan
  - **La clave de la cola es el par (vendedor, año), no el id del saludo**, y va contra la costumbre del resto del proyecto. La unicidad real es esa (G-39). Con el id como clave, pulsar «Saludar» dos veces sin señal —sin ver respuesta, que es lo que pasa— encolaría dos operaciones: la segunda solo para que el servidor conteste «ya existía», gastando un viaje de red desde una sala con mala cobertura. Con el par, la segunda pulsación sustituye a la primera y sale una sola
  - **Dos pantallas del sistema viejo en un componente**: `RegistroSaludo` y `SaludoDetalleModal` nunca se ven a la vez. Los seis medios son botones y no un selector —son seis opciones y la respuesta se sabe antes de abrir la pantalla—, con `aria-pressed` porque el color no le llega a quien usa un lector
  - **Mi Día ofrece saludar sin importar la hoja.** La hoja vive en el feature de agenda y el guardarrail 3 prohíbe que un feature use la `ui/` de otro: Mi Día dice a quién se quiere saludar y **la ruta compone**. Del dominio de agenda sí toma el catálogo de medios y la regla de la edad — eso es vocabulario compartido, no una implementación
  - **Un problema de bundle que destapó una prueba.** Importar la hoja desde el **barril** de `agenda/ui` arrastraba `AgendaPage` entero al trozo de Mi Día —la pantalla que más rápido tiene que abrir (RNF-06)—. Se notó porque una prueba de rutas pasó de 300 ms a 1400 y empezó a agotar su espera. Con el módulo concreto, Mi Día son 5.9 KB y el calendario sigue en su propio trozo
  - **La edad viaja como año de nacimiento, no calculada por el servicio** (G-42): la regla —posterior a 1900 y no futura, defensa contra datos sucios de la importación— vive en el dominio, donde tiene sus pruebas. Si el año no es creíble no se muestra nada: ni un cero ni un guion, que son formas de afirmar algo que no se sabe
  - **La foto no se ofrece todavía**, aunque G-41 la admite y el servicio ya guarda su clave: falta el bucket de S3, lo mismo que bloquea la evidencia de la visita (T-39). Un botón que siempre falla es peor que ninguno
  - **Hizo falta un `GET` en el servicio**: `GET /api/Greetings/{vendedor}/{año}`, sin OData porque el par **identifica** el saludo. Sin él, «ya saludado» sería un dato con nada detrás

- [x] **T-52** — Dominio de bitácora
  - Archivos a crear/modificar: `src/features/bitacora/domain/*.ts` + pruebas
  - Criterio de completitud: **una por asesor y día**; se considera cumplida con contenido en los campos obligatorios; el incumplimiento se evalúa al cierre del día hábil; las exenciones vigentes del sistema actual quedan reflejadas o descartadas explícitamente
  - **Las dos reglas que nacieron de un incidente están con su razonamiento intacto.** G-16 —no se guarda en blanco— no es una validación de formulario: sin ella un borrador vacío del teléfono pisaba lo escrito desde la web. G-17 —al reconciliar **gana el que tiene contenido**, no el último— es la única regla de resolución de conflictos del sistema actual, y hay una prueba que fija que lo local pendiente gana **aunque el servidor sea más nuevo**, porque esa es la distinción
  - **Quién está obligado NO se decide en el cliente**, y es deliberado: necesita los feriados, la fecha de inicio de la obligación —distinta por asesor— y la zona horaria, tres cosas que el servicio tiene juntas. En el sistema actual la pantalla las combinaba y daba una respuesta distinta cada vez que la tabla de feriados iba con retraso
  - **Las exenciones quedan descartadas, no reflejadas.** Existían para parchear que la obligación colgaba del **tier legacy** `FARMER`/`GTE`: el tier de quien atendía Contact Center era FARMER aunque su trabajo no fuera de terreno. El tier desaparece (ADR-008) y la obligación pasa a ser atributo del asesor, con lo que las seis exenciones dejan de tener objeto

- [x] **T-53** — `BitacoraRepository` y casos de uso, incluidas las funciones de servidor
  - Archivos a crear/modificar: `src/features/bitacora/{ports,infrastructure,application}/*.ts` (`RegistrarBitacoraDelDia`, `TranscribirDictado`, `MejorarRedaccion`, `VerificarCumplimientoDiario`) + pruebas
  - Criterio de completitud: `transcribir-bitacora`, `mejorar-bitacora` y `mejorar-redaccion` se invocan **desde infraestructura**, reutilizadas tal cual; el cliente nunca maneja credenciales de los proveedores de IA (RF-15, RNF-11); las pruebas de inyección de prompt del sistema actual se portan y se extienden
  - **«Reutilizadas tal cual» no era posible: eran funciones de Supabase** y el criterio se escribió antes de ADR-011. **Portadas al servicio .NET el 03-09-2026**, con los mismos proveedores —Groq/Whisper para el audio, Claude para el texto— y el prompt de producción palabra por palabra: lo que tiene valor ahí es el ajuste, y en particular el ejemplo de calibración es lo que enseña cuánto reescribir. Detalle en `[repo api] Services/GarantiMax/doc/ayuda-de-escritura.md`
  - **Y `mejorar-redaccion` no era la de la bitácora.** El criterio listaba tres funciones; la que usa el botón es `mejorar-bitacora`. `mejorar-redaccion` corrige informes de Post-Venta, con toda una maquinaria de tokenización para proteger montos y patentes: otra funcionalidad, otra fase. Verificado en `../garantimax`
  - **Las claves van vacías en `appsettings` y sin ellas los endpoints responden 503**, que el cliente traduce a «esto no está encendido» y no reintenta. La bandera `VITE_AYUDA_ESCRITURA` sigue apagada, pero ya no espera código: espera las claves
  - **La defensa contra inyección de prompt está implementada, y no verificada.** Cinco medidas —marcas `⟦DATO⟧`, la regla que prevalece, **quitar las marcas que ya venían en la entrada**, forzar la herramienta y limpiar la respuesta—; la tercera es la que suele faltar, porque sin ella escribir `⟦/DATO⟧` cierra el bloque antes de tiempo. Lo que falta son las **pruebas**: no hay proyectos de test en el repo de la API, y ese es el agravante que T-67 ya reconoce
  - **Los tres topes tienen un número razonado**: 25 MB de audio y 8000 caracteres —los del sistema actual, y el texto se **corta** en vez de rechazarse— y 30 llamadas por asesor y día. El tope diario **es una barrera, no una contabilidad**: vive en memoria, es por instancia y se reinicia al desplegar; frena un bucle de reintentos y no a alguien decidido. Para control de gasto, la alerta de presupuesto del proveedor
  - **Lo que sí quedó hecho**: los puertos (`TranscriptionProvider`, `WritingAssistant`), sus implementaciones contra el servicio, los casos de uso y sus pruebas — incluido que un **503 es «esto no está encendido»** y **no es reintentable**, para que no se confunda con un fallo de red. Encenderlo cuando existan los endpoints es una bandera
  - **Las pruebas de inyección de prompt quedan pendientes con su motivo**: no hay dónde ejecutarlas todavía. Son requisito de los endpoints, y están anotadas como tal en el documento del servicio
  - **Guardar es local primero** (G-15), y hay una prueba que comprueba el **orden**: el borrador se escribe en el teléfono antes de intentar subir. Nació de una pérdida de datos — el asesor escribe en el estacionamiento de una sala, y si el guardado dependiera de que salga la petición, un día malo se lleva veinte minutos de escritura
  - **La clave de la cola es la fecha, y sale gratis**: la bitácora ya es única por día, así que guardar tres veces encola una sola operación con el último texto — que es justo lo que hace falta mientras se redacta

- [x] **T-54** — Interfaz de bitácora
  - Archivos a crear/modificar: `src/features/bitacora/ui/*.tsx`
  - Criterio de completitud: novedades, problemas, plan y texto libre con las salas mencionadas; dictado por voz y mejora de redacción; el estado de cumplimiento del día es visible (RF-14)
  - **Corrección al criterio.** «Novedades, problemas, plan y texto libre» **no son campos** en el sistema actual: son el marcador de posición de un único cuadro —«¿Qué pasó hoy? Novedades, gestiones, problemas, plan para mañana…»— y G-01 dice literalmente «texto libre, una por autor y por día». Partirlo en cuatro obligaría al asesor a clasificar al final de una jornada de terreno, que es cuando menos ganas tiene. El marcador se conserva. Verificado en `../garantimax` el 02-09-2026
  - **Y «las salas mencionadas» no existen**: ninguna versión del sistema actual extrae ni muestra las salas nombradas en el texto. Se descarta, no se implementa a ciegas
  - **El dictado funciona de punta a punta desde el 03-09-2026**: micrófono en `infrastructure/device` —junto a la geolocalización y con el mismo contrato de no fallar hacia arriba—, transcripción en el servicio y el texto de vuelta al cuadro. El botón es un **interruptor** con contador, porque grabar no es una llamada: se aprieta, se habla y se aprieta otra vez
  - **El micrófono se libera siempre.** Un `MediaStream` abierto deja el indicador de grabación encendido en el teléfono —el asesor lo ve y no sabe por qué— y consume batería. El sistema actual tuvo que añadir una limpieza al desmontar por esto mismo
  - **El formato se negocia**: `opus`/`webm` en Chrome y Firefox, `mp4` en Safari iOS. Un formato forzado que el dispositivo no soporta no graba **nada**, y eso dejaría sin dictado a la mitad de los teléfonos de terreno
  - **El tope de cinco minutos lo aplican los dos lados, y no es duplicación**: lo cumple de verdad quien tiene el micrófono —la pantalla puede desmontarse y entonces nadie pararía la grabación— y la pantalla lo pide igual porque seguir contando hasta 6:00 sería mentir sobre lo que se graba
  - **El texto transcrito se añade, no reemplaza**, y mientras graba no se puede mejorar la redacción: las dos cosas a la vez dejarían el texto mejorado con el dictado encima
  - **La pantalla distingue tres estados de guardado**, no dos: guardado, guardado en el teléfono pendiente de subir, y sin comprobar contra el servidor. Decir «guardado» a secas cuando está en la cola es la clase de mentira pequeña que hace que alguien descubra a fin de mes que faltaban tres bitácoras
  - **El aviso de atrasos se puede cerrar y no bloquea** (G-12): quien debe tres bitácoras necesita escribir la de hoy más que nadie. Lista los días concretos, porque «te faltan 3» obliga a ir día por día buscando. Y si la comprobación **falla no se muestra nada** (G-13): no se dice «estás al día», que sería afirmar algo sin comprobar

### Fase 3 — Gastos, boletas y rendiciones (P3)

- [x] **T-55** — Dominio de gasto y rendición
  - Archivos a crear/modificar: `src/features/gastos/domain/*.ts` + pruebas
  - Criterio de completitud: un gasto pertenece a un asesor y tiene categoría y asignación; **un gasto incluido en una rendición enviada no se modifica**; rendición `borrador → enviada → aprobada_jefe → aprobada_ops → pagada`, con `rechazada` desde cualquier estado de aprobación y reentrada por `reenviada`; el asesor solo transiciona `borrador → enviada` y `rechazada → reenviada`
  - **Las reglas que solo se entienden con el caso detrás quedaron con él escrito.** El umbral de 0,8 (E-09) y por qué no es un número al azar; cada dudoso con **su razón** (E-11), porque «no pudimos leer el total» y «esta fecha es de hace ocho meses» piden cosas distintas; el duplicado que se **marca y no se rechaza** (E-25), porque a veces son dos cafés idénticos; la sugerencia de miles que se **ofrece y no se aplica** (E-15), porque multiplicar por mil sin preguntar produce una rendición de un millón
  - **La máquina de estados se espeja a conciencia.** El servicio decide si **se puede**, el cliente decide si **se ofrece**: sin la del cliente la pantalla enseñaría botones que el servidor va a rechazar, y sin la del servicio la regla la gobernaría el teléfono. El sistema actual hacía lo mismo y su código decía que «espeja» al SQL. El precio es que pueden separarse, y por eso las pruebas **enumeran las transiciones exhaustivamente**

- [x] **T-56** — `GastoRepository` y `RendicionRepository`
  - Archivos a crear/modificar: `src/features/gastos/{ports,infrastructure}/*.ts` + pruebas de mapeo
  - Criterio de completitud: cubren `gastos`, `gasto_archivos`, `gasto_asignaciones`, `gasto_categorias`, `rendiciones`, `rendicion_eventos` y las RPCs `gasto_crear`, `gasto_fusionar`, `rendicion_enviar`, `rendicion_rechazar`, `rendicion_reenviar` (las de aprobación y pago quedan declaradas en el contrato pero no expuestas al asesor)
  - **El pipeline se acota con OData por defecto** (`State lt 4`), y el número sale del catálogo en vez de escrito a mano: si mañana se inserta un estado antes, el filtro cambia solo
  - **Un defecto que obligó a cambiar el servicio.** El gasto no traía coordenadas, y eso convertía E-27 —dos gastos a menos de 500 m y 6 horas son el mismo pago— en una **función muerta**: compila, las pruebas pasan si se escriben con la misma laguna, y la sugerencia de fusión nunca aparece. Corregido en `[repo api] cf32e63`, con una prueba que fija justo eso

- [x] **T-57** — Casos de uso de gasto
  - Archivos a crear/modificar: `src/features/gastos/application/{CapturarBoleta,LeerDatosDeBoleta,RegistrarGasto,AsignarGasto,FusionarGastos}.ts` + pruebas
  - Criterio de completitud: `LeerDatosDeBoleta` invoca `leer-boleta` desde infraestructura y **permite corregir los datos antes de guardar** (RF-16); la asignación admite sala, visita o proyecto (RF-18)
  - **Guardar un gasto NO exige que esté completo**, y es la decisión que sostiene el flujo: por completar es un estado legítimo (E-10). Exigir el total dejaría al asesor con una boleta en la mano y una pantalla que no le deja avanzar — y la boleta se pierde antes que la paciencia
  - **`LeerDatosDeBoleta` queda pendiente** con su motivo: el endpoint `leer-boleta` no está portado al servicio. Lo que **sí** está es el dominio completo de la extracción —umbral, dudosos con su razón, fecha plausible, sugerencia de miles, duplicados— así que cuando el endpoint exista solo hay que llamarlo. Y usa la **misma clave de Anthropic** que la ayuda de escritura
  - **Un 404 y un 409 llegan como `DomainError`** con la frase del servicio, y los dos son rechazos que no se arreglan reintentando

- [x] **T-58** — Decorador offline de gastos
  - Archivos a crear/modificar: `src/features/gastos/infrastructure/GastoRepositoryOffline.ts` + pruebas
  - Criterio de completitud: la boleta se guarda localmente **con su imagen** y se sincroniza al recuperar señal, con reintentos y **sin duplicar el gasto** (RF-17, RNF-09); reemplaza por completo a `useSincronizarBoletas` sin heredar su acoplamiento a `App.tsx`
  - El decorador offline con las cinco escrituras en **una sola cola** (ADR-009), que es lo que elimina la duplicación del sistema actual — tenía una cola **propia** para boletas además de la de visitas, y su código explicaba por qué. Las claves con su motivo: fusionar usa el **par ordenado**, porque fusionar A con B y B con A es la misma operación y encolar las dos borraría dos filas
  - **Cerrada el 04-09-2026 con el blob**, cuando las credenciales de S3 se pudieron probar. La decisión que la define: **los bytes no viajan en la cola.** `OfflineQueue.all()` se lee en cada cambio —lo hace el indicador de sincronización— así que un payload con la imagen cargaría en memoria todas las fotos pendientes, y el teléfono con menos memoria es justo el que más las acumula. La cola lleva el puntero; los bytes viven en `LocalFileStore`, con un manifiesto aparte para poder contar lo pendiente sin tocar un byte de imagen
  - **Hizo falta un puerto nuevo, `FileUploader`**, y el motivo es una regla del proyecto: `StorageProvider.upload` devuelve el archivo guardado, y `withOffline` solo envuelve métodos que devuelven `Promise<void>` porque una operación encolada no tiene resultado que devolver. La salida no fue debilitar la regla sino partir la operación en las dos cosas que es — los bytes (encolable) y la fila (ya lo era)
  - **Un blob que ya no está NO bloquea la cola.** Es lo más delicado del cambio: `DrainQueue` se detiene en el primer fallo para no romper el orden, así que una operación que falla siempre no retrasa una cosa — bloquea *todo* lo que venga detrás, indefinidamente. Se resuelve como completada y se reporta a monitoreo, el mismo criterio que un `kind` huérfano

- [x] **T-59** — Interfaz de captura y categorización
  - Archivos a crear/modificar: `src/features/expenses/ui/{CaptureReceiptPage,ExpenseDetailPage}.tsx`, `src/infrastructure/device/camera.ts`, `src/app/routes/ExpenseRoutes.tsx`
  - Criterio de completitud: captura desde cámara, corrección de los datos leídos, categoría y destino; operable con una sola mano (RNF-16); funciona sin señal indicando que quedó encolada
  - **El orden de E-02 está fijado por una prueba**: dispositivo → bucket → fila del gasto → fila del archivo. El levantamiento dice que ese orden «es la regla más importante del módulo» porque garantiza que la foto nunca se pierda, y se le añadió un paso delante que el sistema actual no tenía: **los bytes al dispositivo antes de tocar la red**. Sin él, una aplicación que muere entre la foto y la subida se lleva la boleta
  - **La frontera de E-04, traducida**: se falla duro solo antes de crear la fila. Si falla la fila del **archivo**, el gasto se conserva y la pantalla lo dice — perderlo por eso sería justo lo que la regla prohíbe. Si falla la subida, se limpia la copia local: un blob que nadie va a subir solo ocupa el tope hasta que el asesor se queda sin espacio por gastos que no existen
  - **Sin lectura de IA la captura funciona igual** (E-03): el gasto nace por completar con seis campos dudosos y la nota literal del sistema actual. `currency` no entra en esa lista porque la primera entrega es solo Chile, y esa exención está escrita en el dominio para que sea lo primero que se quite cuando entre otro país
  - **Se usa la cámara del sistema** (`capture="environment"`) y no un visor con `getUserMedia`: enfoca sola sobre un papel arrugado, tiene flash, respeta la orientación y **no pide un permiso nuevo** — quien una vez denegó la cámara al navegador no podría capturar nunca más, y no sabría por qué
  - **HEIC mejora sobre el sistema actual.** E-06 lo manda directo a «por completar» sin gastar una llamada a la IA condenada; pero el iPhone que produce HEIC sí lo decodifica, así que al comprimirlo sale un JPEG y sí se puede leer. Por eso `readable` se deduce del archivo que **sale**, no del que entró
  - **El acceso al dispositivo vive en la ruta, no en `ui/`.** Lo decidió el guardarrail 1 rechazando la primera versión, con el precedente del micrófono en `FieldLogRoute`
  - Se añadió `expenseCategories` al catálogo de referencia —sin categoría un gasto no se puede rendir— y las **dos** pruebas que enumeran los métodos del repositorio obligaron a justificar el sexto, que es exactamente para lo que están

- [x] **T-60** — Rendiciones
  - Archivos a crear/modificar: `src/features/gastos/application/{ArmarRendicion,EnviarRendicion}.ts` y la observación de estado + pruebas
  - Criterio de completitud: agrupa gastos, envía, y el asesor **observa** el avance por jefe, operaciones y pago; puede reenviar tras rechazo (RF-19). La aprobación se sigue operando en el sistema actual durante la Fase 1
  - **Enviar y reenviar son el mismo caso de uso**, y los distingue el estado de partida — igual que en el servicio. Preguntárselo al cliente dejaría que un reenvío llegara etiquetado como primer envío (E-34)
  - **La transición se comprueba antes de tocar la red.** El servicio la valida igual, pero pedirle que rechace lo que aquí ya se sabe imposible gasta una petición desde una sala con mala cobertura

- [x] **T-61** — Interfaz de rendiciones y trazabilidad
  - Archivos a crear/modificar: `src/features/gastos/ui/RendicionesPage.tsx`
  - Criterio de completitud: lista y detalle con la línea de tiempo de `rendicion_eventos`; cada transición queda registrada con actor, momento y resultado (RNF-13)
  - **Lo primero es quién tiene la pelota** (E-43): una rendición enviada es dinero que el asesor espera, y la pregunta que lo trae a esa pantalla es «¿en quién está detenido?». Lo calcula el servicio, porque depende de si tiene jefe en el organigrama (E-32)
  - **El motivo del rechazo va en la LISTA**, no solo en el detalle: es lo que decide si hay que abrirla
  - **La línea de tiempo se separa por envío** cuando hubo más de uno (E-34): mezclados deja una línea donde «rechazada» y «aprobada» se alternan sin explicación
  - **El comentario solo se pide en un reenvío**: en el primer envío no hay nada que contestar, y un campo vacío ahí hace dudar de si es obligatorio
  - **Un total sin ninguna conversión no muestra un cero** (E-23): manda a ver el detalle, porque un cero en una lista de rendiciones se lee como «no gastó nada»

### Fase 4 — Notificaciones, verificación, auditoría y corte

> **T-73 va primero de la fase, aunque su número sea el más alto**: se agregó
> después de cerrar la numeración (2026-09-02). T-19 entregó el sistema de
> componentes **base** —deliberadamente sobrio, sin identidad— y nunca se
> agregó la tarea que lo viste. Tiene que estar cerrada antes de T-65 (E2E) y
> de T-71 (piloto).

- [ ] **T-73** — Identidad visual y pasada de diseño
  - Archivos a crear/modificar: `src/shared/ui/tokens.css`, los 7 componentes de `src/shared/ui/`, `src/shared/layouts/*` (las dos barras de navegación), `src/shared/ui/SyncIndicator.tsx` y las pantallas de `src/features/identity/ui/*`
  - Criterio de completitud: **una sola paleta en todo el frontend**. Los colores, la tipografía y los espaciados de la marca viven en el bloque `@theme` de `tokens.css`, y las pantallas los nombran **por su papel** (`text-ink`, `bg-accent`, `border-border`) y no por su tono (`text-slate-900`). Quedan eliminadas las **58 clases de color escritas a mano** que sobreviven en **10 archivos**: las cinco pantallas de identidad —login, bienvenida, perfil y las dos de sesión—, los dos ficheros de rutas, **las dos barras de navegación** (`BottomNavigation`, `SideNavigation`) y el propio **`SyncIndicator`**. Los cuatro últimos son los graves, y no las pantallas: la navegación y el indicador de sincronización aparecen en **todas** las pantallas, y `SyncIndicator` vive dentro del sistema de diseño, que es el sitio donde menos debería haber un color a mano. Todos son anteriores a T-19 o se escribieron sin mirarlo: hoy se ven idénticas porque `slate-900` **es** `#0f172a`, el valor de `--color-ink`, y por eso el desajuste no lo detecta ni `tsc` ni el linter ni las pruebas; el día que la marca cambie el token, esas pantallas se quedarían atrás sin avisar
  - Criterio de completitud: el aspecto **replica el del sistema actual**, para que el asesor reconozca la aplicación en el corte y el reentrenamiento sea mínimo, pero **ordenado**: un solo botón, un solo campo, un solo espaciado entre tarjetas, en lugar de las variantes que el sistema actual acumuló entre su versión móvil y su versión de escritorio (A3: dos implementaciones de Mi Día, 972 líneas la móvil). Replicar el aspecto no es replicar el desorden
  - Restricción: **solo utilidades de Tailwind**. Sin CSS nativo, sin `@apply`, sin clases propias y sin `style` inline. El proyecto está hoy limpio de las cuatro cosas y la tarea lo mantiene así; la única excepción viva son las 4 líneas del `body` en `index.css`, que pintan el fondo y no pueden expresarse como utilidad. Cualquier excepción nueva va con el motivo escrito al lado. Nota: el bloque `@theme` **es** el mecanismo de tema de Tailwind v4, no CSS a mano — `--color-ink` es lo que genera la utilidad `text-ink`
  - Restricción: se conservan sin excepción los dos tokens que son **requisito y no gusto** — `--spacing-touch` de 44 px (RNF-17) y los pares de contraste ≥ 4.5:1, medidos y anotados en `tokens.css`. Si la paleta de marca no cumple contraste sobre alguna superficie, se ajusta el par y se registra, no se baja el umbral
  - Fuera de alcance: **no cambia la arquitectura de información**. Qué va primero en cada pantalla, qué es una hoja y qué una ruta propia, y cuántos toques cuesta cada flujo se decidieron tarea por tarea y están cubiertos por pruebas. Esta tarea viste las pantallas, no las reordena. Si el diseño exige mover estructura, es otra tarea con su propio criterio: lo cosmético cuesta días, reordenar flujos cuesta reescribir pantallas y pruebas
  - Prerequisito: **la fuente de la identidad**. Hace falta la paleta, la tipografía y el logo —del manual de marca o extraídos del sistema actual—; sin eso la tarea no arranca, porque no se inventa una identidad desde el código
  - Verificación: las pruebas existentes tienen que pasar **sin tocarlas**. Consultan por rol y por texto accesible, no por clase CSS, y esa propiedad es la que hace que un rediseño sea barato: de ~1000 pruebas, solo las 6 líneas de `components.test.tsx` miran una clase, y es `min-h-touch`, que esta tarea conserva. Si un cambio visual obliga a reescribir pruebas, es señal de que se está moviendo estructura y no aspecto

- [x] **T-62** — Notificaciones al asesor
  - Archivos a crear/modificar: `src/features/identidad/{ports,infrastructure,application,ui}/Notificacion*` + pruebas
  - Criterio de completitud: avisa de visitas abiertas sin cerrar, tareas atrasadas y bitácoras pendientes, leyendo `notificaciones` y respetando lo que producen `visitas-abiertas-cron` y `tareas-atrasadas-cron` (RF-20)
  - **Viven en su propio feature y no en identidad**, como decía el PLAN: **hablan de todo** —tareas, visitas abiertas, bitácoras— y metidos en identidad ese feature tendría que conocer los tres
  - **Cada aviso lleva a lo que anuncia**, y el destino lo decide el **dominio**: es una regla, no una decisión de navegación. Sin destino no se pinta un enlace muerto — mandar a Mi Día desde un aviso que hablaba de algo concreto es peor que no ofrecer nada
  - **Abrir es leer.** Un botón de «marcar leído» le pide al asesor confirmar algo que ya hizo. Y **marcar leído se encola**: sin eso, el aviso que leyó en una sala sin cobertura volvería como nuevo al recuperar señal, que es como se aprende a ignorar los avisos
  - **Los tres tipos periódicos están declarados aunque no lleguen todavía.** El orden del enum **es el contrato**: declararlos después obligaría a insertarlos en medio y el asesor vería un aviso con la etiqueta de otro
  - **Lo que falta no es código.** `visitas-abiertas-cron` y `tareas-atrasadas-cron` necesitan **dónde correr**, y el servicio no tiene planificador: un `BackgroundService` corre una vez **por instancia**, así que con dos tareas de ECS son dos avisos por asesor. Escrito en `[repo api] doc/los-dos-procesos-periodicos.md`
  - **La migración del `CHECK` ya está** (04-09-2026), y llegó de rebote: `ck_notificaciones_tipo` se **deriva del enum**, así que al generar la migración de los adjuntos de lobby EF la reconstruyó sola con los tres tipos nuevos. Es el diseño funcionando — la restricción no puede quedar desalineada. **Con un acoplamiento anotado:** el `Down()` de esa migración quita los tres tipos otra vez, así que revertir los adjuntos de lobby rompería también los avisos periódicos

- [x] **T-63** — Eventos de producto para BI
  - Archivos a crear/modificar: `src/shared/observability/eventos.ts` y su emisión desde los casos de uso + pruebas
  - Criterio de completitud: los eventos del PRD §11 se emiten **desde la capa de aplicación, nunca desde la UI**, con fecha, asesor, identificadores de negocio, resultado y motivo; escriben en `eventos_producto` (T-18)
  - **Se emiten desde la aplicación y no desde la UI, y eso cambia lo que miden.** Un evento disparado en un `onClick` cuenta **intenciones**: `visita_cerrada` en el botón se registra también cuando el cierre falla, y entonces el número de BI no cuadra con las filas de la base. Hay una prueba que fija justo eso — con una visita ya abierta, el check-in no ocurre y el evento tampoco
  - **El registrador nunca rompe nada.** No devuelve promesa —si la devolviera, algún caso de uso la esperaría y cerrar una visita tardaría lo que tarde un evento de BI—, atrapa el rechazo **y** las excepciones sincrónicas, y manda el fallo al monitoreo. La dependencia es **opcional** en todos los casos de uso, con un registrador vacío por defecto
  - **Cuatro de la lista del PRD NO los emite el cliente**, y leyendo solo el PRD se esperaría que sí: las tres transiciones de aprobación y el pago los produce **quien aprueba**, que no es el asesor (E-42), y `bitacora_incumplida` es un proceso periódico. El registrador los **descarta con aviso**, y la lista de los cinco se declara como **dato** para que una prueba lo compruebe: un comentario que dice «esto no se hace» no impide hacerlo
  - **Una excepción al criterio, con su motivo:** `operacion_encolada` sale del **decorador offline**, porque describe algo que decide el decorador — el caso de uso pidió guardar y no sabe si acabó en el servidor o en la cola
  - **Y la única recursión posible del cableado, cortada:** al sumidero de eventos no se le pasa el registrador. Si lo recibiera, un evento que no pudo salir se encolaría, el decorador emitiría `operacion_encolada`, ese tampoco saldría… hasta agotar el almacén del teléfono. Queda escrito junto al cableado para que nadie lo «arregle» después
  - **Solo identificadores** (A1 §11). El tipo del contenido es `Record<string, string | number | boolean>` y no `unknown` a propósito: obliga a escribir el valor a mano. Hay pruebas de lo que **no** viaja — las coordenadas de una visita que sí las tiene, el comentario que el asesor escribió

- [ ] **T-64** — Observabilidad y auditoría de operaciones críticas
  - Archivos a crear/modificar: `src/shared/observability/*` y la configuración de Sentry
  - Criterio de completitud: los errores no controlados llegan a Sentry con traza, versión, ruta, categoría e identificador de usuario y **sin datos personales**; nunca se registra contenido de bitácoras, imágenes de boletas ni ubicaciones exactas (A1 §11); apertura y cierre de visita, transiciones de rendición y envío de bitácora quedan auditados
  - **La mitad de Sentry ya está hecha**, cerrada con T-08 el 01-09-2026: `SentryMonitoringProvider` con `sendDefaultPii: false` y su trozo aparte para no precargarlo en el service worker. Lo que queda de T-64 es la **auditoría de operaciones críticas** — y las transiciones de rendición ya escriben su evento en la misma transacción que el cambio de estado (T-S09), así que esa parte también está cubierta del lado del servicio

- [ ] **T-65** — Pruebas de extremo a extremo de los cinco flujos críticos
  - Archivos a crear/modificar: `e2e/*.spec.ts`, `playwright.config.ts`, workflow de CI
  - Criterio de completitud: en verde (1) inicio de sesión y resolución de permisos, (2) visita completa check-in → captura → evidencia → cierre, (3) intento de segunda visita y descarte de la primera, (4) boleta sin señal con sincronización posterior sin duplicado, (5) bitácora con dictado y mejora (RNF-05)

- [ ] **T-66** — Pruebas de corte de red
  - Archivos a crear/modificar: `e2e/offline/*.spec.ts`, `docs/pruebas-offline.md`
  - Criterio de completitud: **0 operaciones perdidas y 0 duplicados** cortando la red en cada punto del ciclo de check-in, cierre de visita, avance de tarea, bitácora y boleta (RNF-08, RNF-09); incluye el escenario de tres horas sin señal

- [ ] **T-67** — Revisión de las reglas de autorización del servicio
  - Archivos a crear/modificar: `docs/autorizacion-fase1.md` y los documentos correspondientes en `[repo api] Services/GarantiMax/doc/`
  - Criterio de completitud: endpoint por endpoint, qué puede leer y escribir el asesor y **cómo lo garantiza el servicio**. La fuente de la especificación son las ~150 políticas RLS del sistema actual, leídas tabla por tabla. El modo demo queda respaldado por el servicio y no solo por el guard del cliente. Documento **firmado por TI** (A1 §15.11). Agravante que hay que compensar con revisión humana: el repo de la API **no tiene proyectos de test**

- [x] **T-68** — Lista de paridad funcional
  - Archivos a crear/modificar: `docs/paridad.md`
  - Criterio de completitud: cada funcionalidad de terreno del sistema actual con su equivalente verificado en el nuevo, probada por un asesor real, con estado y responsable; **firmada antes del corte** (RF-25). Sin el 100 %, el corte no se ejecuta
  - **No está firmada, y no puede estarlo:** RF-25 exige que un asesor real lo pruebe, y eso es el piloto. «Verificado» aquí significa contra el código, y el documento lo dice en su primera línea
  - **Se empezó ahora a propósito.** Construir cada vertical produjo **diez** discrepancias entre el plan y el sistema actual, y reconstruirlas en el corte sería releer los mismos archivos con menos tiempo y más presión — la situación exacta en la que una lista de paridad se firma sin verificarse
  - **Y encontró un hueco real el mismo día: T-47 estaba mal cerrada.** `tasks.create` estaba en el contrato y **ninguna pantalla lo llamaba**, así que el asesor no podía crear una tarea. Cerrado en el momento (`NewTaskSheet`, siete pruebas), porque era un hueco de pantalla y no de negocio
  - **El bucket de S3 bloquea cuatro filas** —evidencia de visita, adjuntos de lobby, foto del saludo y captura de boleta—: es el bloqueo más grande de la lista. Las claves de IA bloquean tres, los nombres de rol una, y el servicio de tasas una que **no impide rendir** (E-22: la conversión es *best-effort*)
  - **Dos pantallas sin decidir**: `PlanGrupoModal` y `ProyectoEncabezado`. Nadie ha dicho si entran al corte

- [ ] **T-69** — Despliegue y ambientes
  - Archivos a crear/modificar: `vercel.json`, configuración del proyecto Vercel, variables por ambiente
  - Criterio de completitud: proyecto Vercel nuevo con SPA y reescrituras a `/index.html`; ambientes de desarrollo, QA y producción con sus variables; dominio de transición operativo (ver §9); previews por PR funcionando

- [ ] **T-70** — Procedimiento de reversión
  - Archivos a crear/modificar: `docs/reversion.md`
  - Criterio de completitud: pasos, responsables, tiempos y criterio de decisión para devolver a los asesores al sistema actual **dentro de la misma jornada**; **ensayado en un simulacro real** antes del corte, con el resultado registrado (RNF-21)
  - Archivos creados: `docs/reversion.md`
  - **Queda ABIERTA a propósito, aunque el documento esté escrito.** El criterio pide «ensayado en un simulacro real», y marcarla cerrada sería afirmar que RNF-21 se cumple. Se cumple cuando haya un simulacro con su resultado registrado en §7 del documento
  - **El hallazgo que ordena todo el documento: revertir devuelve el acceso, no los datos.** Con las bases separadas (ADR-011), lo que un asesor haga en el sistema nuevo el día del corte es **invisible** para el actual. Devolverlos son quince minutos; decidir qué pasa con el trabajo de esa jornada es la parte difícil, y **hay que decidirla antes del corte**. Sin esa asimetría, revertir parecería un botón
  - **Los criterios son números y no juicios**: cuatro señales de reversión inmediata sin consultar a nadie —no se puede iniciar sesión, se pierde trabajo confirmado, el servicio cae más de 30 minutos, un dato de un asesor visible para otro— y tres umbrales con porcentaje para el mediodía. Un umbral que se discute a las once de la mañana con gente en terreno no es un criterio
  - **Y tres cosas por las que NO se revierte**, incluida una que parece razón: que falte una funcionalidad que `paridad.md` ya declaraba pendiente. Si estaba en la lista, se sabía antes del corte
  - **Decide una sola persona**, no un comité: revertir de más cuesta una jornada en el sistema viejo, revertir de menos cuesta una jornada de trabajo perdido
  - **El paso que se olvida: NO se apaga el sistema nuevo.** Se deja en pie y sin escrituras, porque es lo único que permite recuperar después el trabajo de la jornada — apagarlo convierte un problema de horas en una pérdida
  - **Una decisión abierta que no es del documento**: qué pasa con el trabajo de la jornada. Recomendación escrita —migrar visitas y boletas, perder el resto, porque una visita y una boleta no se pueden reconstruir— pero la decide el responsable con operaciones. Y la opción de migrar **solo existe si el guion está escrito y ensayado antes**
  - **Cuatro suposiciones declaradas** que hay que confirmar: si el corte cierra el acceso al sistema actual, el TTL del dominio, que exista un canal que los asesores lean en terreno, y que TI esté disponible el día del corte

- [ ] **T-71** — Piloto con un grupo reducido de asesores
  - Archivos a crear/modificar: `docs/piloto.md`
  - Criterio de completitud: grupo definido, período acotado, hallazgos registrados y **resueltos o aceptados explícitamente**; métricas de RNF-06 y de incidencias comparadas contra la línea base de T-17

- [ ] **T-72** — Corte único
  - Archivos a crear/modificar: `docs/corte.md` y la configuración de dominio
  - Criterio de completitud: ejecutado en un día de baja actividad, con paridad firmada (T-68), reversión ensayada (T-70) y piloto cerrado (T-71); doble acceso al sistema actual habilitado y **con fecha de vencimiento declarada** para Facturación, Salas y Cobertura; monitoreo reforzado y ventana de reversión activa durante la jornada

---

## 5. Cambios en base de datos

Los cambios ya **no** tocan la base del sistema actual: el servicio GarantiMAX tiene **base de datos propia y vacía** (ADR-011). Aquí se lista lo que hay que **crear** en ella. El modelo se diseña desde el dominio con claves de un solo tipo y FKs reales; **no se transcribe el esquema viejo**, que degradó sus claves por no poder migrar datos (A3 §3).

**Cobertura mínima de Fase 1:** identidad y perfil del asesor · visitas, lobbies, visitas abiertas y en curso · agenda, saludos de cumpleaños y feriados · tareas, avances y comentarios · bitácoras · gastos, archivos, asignaciones, categorías, rendiciones y sus eventos · notificaciones · y los catálogos de referencia (salas, vendedores de sala, clientes). El inventario de campos y reglas de cada uno sale del sistema actual: PRD §10 y A3 §3.

**Reglas transversales del modelo nuevo:**

| Regla | Aplica a | Por qué |
|---|---|---|
| **Clave de idempotencia** (`idempotency_key` + índice único parcial) | visitas, lobbies, eventos de agenda, avances de tarea, bitácoras y gastos | Un reintento de check-in, cierre o subida de boleta **no puede** crear un duplicado. Se garantiza **en la base**, no en el código, porque la cola offline reintenta (RNF-09) |
| **Unicidad por asesor y día** | bitácoras | Es una invariante del negocio, no una validación de formulario |
| **Columna de país** | toda tabla con dato operativo | La primera entrega opera solo Chile, pero el país no se hereda implícito como en el sistema viejo (moneda `CLP` por defecto, RUT sin contexto) |
| **Claves de un solo tipo y FKs reales** | todo el modelo | El esquema viejo usa `asesor_id text` («uuid en texto»), `sala_key` sin FK y vínculos blandos. Sin datos que conservar, esa deuda no se hereda |
| **Tabla de eventos de producto** | nueva | Eventos de BI del PRD §11: fecha y hora, asesor, identificadores de negocio, resultado y motivo |

> ⚠️ **La base del sistema actual no se toca, ni con cambios aditivos.** Sus 128 tablas, 364 migraciones y políticas RLS se leen como **documentación de las reglas** —son la mejor fuente que existe— y nada más. Ver A3 §3 para las trampas del esquema viejo: tablas recreadas a media historia, `salas` abandonada y claves degradadas.

---

## 6. Endpoints nuevos o modificados

**Se crea un servicio REST propio**: `Services/GarantiMax/` en el monorepo `gp_3.0_siga_api` (ADR-011, que supera a ADR-004). Estructura estándar de ese repositorio —`Controllers/` · `Services/` · `Interfaces/` · `DTOs/{Feature}/{Requests,Responses}/` · `Models/` · `Options/` · `doc/` · `Program.cs` · `Dockerfile`— y puerto **5006** por convención (5001 Authentication, 5002 Contracts, 5003 Catalogs, 5004 Claims, 5005 Reports).

Todos los endpoints exigen JWT válido. La autenticación **no se construye**: `Services/Authentication` ya emite el token con `Id`, `UserName`, nombre, correo y los roles como `ClaimTypes.Role`.

**Lo que había en Supabase y ahora hay que construir.** Estas siete piezas eran Edge Functions que el plan v0.1 daba por reutilizadas «tal como están». Su código actual es la especificación:

| Origen | Qué hace | Nota |
|---|---|---|
| `leer-boleta` | Extrae datos de la imagen de una boleta con IA | Credenciales de IA en servidor. Devuelve también los campos de baja confianza, que la UI resalta |
| `transcribir-bitacora` | Dictado por voz de la bitácora | |
| `mejorar-bitacora` · `mejorar-redaccion` | Mejora de redacción | |
| `notificar` | Avisos al asesor | |
| `visitas-abiertas-cron` · `tareas-atrasadas-cron` | Procesos programados que alimentan las notificaciones | Sobre ECS + Fargate hay que decidir cómo se programan (pregunta abierta del PRD §14) |

Y además: **almacenamiento de archivos** para evidencia de visitas y boletas, que Supabase Storage daba resuelto. Hay precedente en el ecosistema de la API — `Services/Claims/Services/S3Service.cs` y `Common/Storage` — así que el hueco es de contrato, no de tecnología.

**Reglas que hoy son funciones de base de datos y pasan a ser lógica del servicio.** Son la especificación de los endpoints con negocio dentro. Al leerlas en el repo actual, tomar la **última** redefinición de cada una: varias tienen tres o cuatro versiones en el histórico (`rendicion_rechazar` y `app_rol`, cuatro cada una).

| Grupo | Funciones | Qué encierra |
|---|---|---|
| Permisos | `puede`, `app_rol`, `app_tiene_capacidad`, `mis_capacidades` | **Ya no se portan**: los reemplazan los roles del JWT (ADR-011) |
| Tareas | `crear_tarea_sala`, `completar_tarea`, `set_tarea_completada`, `calificar_tarea`, `tarea_avance_crear` | Ciclo de vida y calificación de una tarea |
| Gastos y rendiciones | `gasto_crear`, `gasto_fusionar`, `rendicion_enviar`, `rendicion_aprobar_jefe`, `rendicion_aprobar_ops`, `rendicion_rechazar`, `rendicion_reenviar`, `rendicion_marcar_pagada` | **Máquina de estados completa**: `borrador → enviada → aprobada_jefe → aprobada_ops → pagada`, más `rechazada` y el contador de reenvíos. Es el bloque con más negocio del alcance |
| Vendedores | `vendedor_por_nombre`, `vendedor_inactivo_por_nombre`, `cumpleanos_vendedores` | El vendedor de sala se identifica **por nombre**, no por id — de ahí estas funciones |
| Calendario | `limite_habil` | Días hábiles y feriados |
| Perfil | `marcar_bienvenida_vista`, `marcar_induccion` | |
| Organización | `organigrama` | |

**Las ~150 políticas RLS de las tablas de Fase 1 son la especificación de la autorización.** No se portan como mecanismo, se leen como requisito, y la regla resultante se documenta en `Services/GarantiMax/doc/` — un archivo por pregunta, según la convención del repo de la API.

> **Paginación obligatoria.** El tope de 1000 filas de PostgREST desaparece, pero la regla que lo motivaba no: todo listado del asesor pagina o se acota por rango de fechas, y el contrato del endpoint lo declara. El dominio nunca asume que recibió todo.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `VITE_API_BASE_URL` | URL base del servicio GarantiMAX. En local, puerto **5006** por convención del repo de la API | Desarrollo / QA / Producción |
| `VITE_SENTRY_DSN` | Reporte de errores no controlados | QA / Producción (opcional en desarrollo) |
| `VITE_ENTORNO` | Identifica el ambiente en Sentry y en los eventos de producto | Desarrollo / QA / Producción |

Todas se leen y validan **exclusivamente** en `src/config/env.ts` (T-04); si falta una, la aplicación no arranca. Ninguna credencial de proveedor externo (IA, correo, mensajería) ni de base de datos existe en el cliente: viven en el servicio .NET, en `appsettings` bindeado a una clase de `Options/` según la convención de ese repositorio (RNF-11). Lo único que el frontend guarda es el token de sesión del usuario.

---

## 8. Consideraciones de seguridad

- **La autorización es del servidor.** Cada endpoint valida el JWT y comprueba que el recurso pertenece a quien lo pide; los controles de la interfaz son de usabilidad y **nunca** la única barrera (RNF-10).
- **El riesgo cambió de forma, no desapareció.** Antes: clave anónima pública sobre 128 tablas, con RLS como única defensa — una política mal escrita exponía el dato a cualquiera. Ahora: la clave pública desaparece, pero las ~150 reglas que RLS garantizaba hay que reescribirlas como código, **y el repo de la API no tiene proyectos de test**. Por eso la revisión de las reglas de autorización (T-67, reformulada) sigue siendo criterio de aceptación y no una tarea opcional.
- **Cuatro condiciones que exigen cuidado especial en un endpoint** (heredadas de ADR-004, ahora como criterio de diseño): (1) usa credenciales de un proveedor externo, (2) escribe algo que cruza la frontera del propio asesor —aprobaciones de rendición, notificaciones a terceros—, (3) es escritura masiva o proceso programado, (4) su regla de autorización no es un simple «es dueño del recurso». Cada una de estas se documenta en `Services/GarantiMax/doc/`.
- **Secrets fuera del código** (`rules/coding-guidelines.md` §11): en el frontend, solo variables de entorno; en el servicio, `appsettings` bindeado a `Options/` — nada hardcodeado, según la convención del repo de la API.
- **"Ver como" (impersonación)** deja de ser un guard disperso por la UI y pasa a ser **regla de dominio** (T-20, T-35, T-38): un usuario impersonado no puede descartar el borrador del asesor. Ya hubo incidencias por esto en el sistema actual.
- **Modo demo** respaldado por el servicio y no solo por el guard del cliente (T-67).
- **Inyección de prompt**: las funciones de IA reciben texto del usuario. Las pruebas del sistema actual se portan y se **extienden** a bitácora y lectura de boletas (T-53).
- **Datos personales**: nunca se registran contenido de bitácoras, imágenes de boletas, ubicaciones exactas ni datos de contacto — solo identificadores (T-64). Los mensajes de error jamás exponen nombres de tabla, SQL, rutas internas ni el mensaje original del proveedor (T-05).
- **Sin SQL en el cliente**: el frontend no conoce tablas ni consultas. En el servicio, todo acceso pasa por EF Core; nada de concatenación de SQL.

---

## 9. Consideraciones de infraestructura

- **Sí se crean recursos AWS**, y por eso el proyecto queda alineado con `rules/infraestructura.md`: el servicio `GarantiMax` se despliega en **ECS + Fargate** con su propio `Dockerfile`, contra una **base PostgreSQL propia**, con configuración por entorno en `Infrastructure/{local,qa,prod}/` del repo de la API. El almacenamiento de archivos usa S3, con precedente en `Services/Claims/Services/S3Service.cs`.
- **Vercel**: proyecto nuevo para `siga_alfa`, framework Vite, SPA con reescrituras a `/index.html`, previews automáticas por PR. Costo marginal: un proyecto adicional dentro del plan vigente.
- **Dominios (Cloudflare)**: durante el desarrollo y el piloto, la aplicación nueva vive en un subdominio de transición (propuesto: `app.garantimax.com`). **El día del corte** se decide entre apuntar `www.garantimax.com` a la aplicación nueva —dejando el sistema actual en un subdominio para el doble acceso de los demás roles— o mantener el subdominio y redirigir solo a los asesores. Es una pregunta abierta del PRD §14 y debe cerrarse antes de T-69.
- **Aislamiento, no convivencia**: los dos sistemas ya no comparten base de datos. Eso elimina el riesgo de invariantes divergentes y lo cambia por otro: **hay que poblar los catálogos** de referencia en la base nueva, porque sin ellos el asesor no puede registrar una visita. Las invariantes críticas se siguen garantizando en la base (índices únicos de idempotencia), no solo en el código.
- **Desviación restante del estándar Engine** (`rules/infraestructura.md`): solo el hospedaje del **frontend**, que se conserva en Vercel en lugar de S3 + CloudFront, por continuidad operativa y porque el PRD deja el cambio de proveedor fuera de alcance. **Requiere visto bueno de TI**; migrarlo sería un proyecto propio y de bajo costo de cambio. El backend ya cumple el estándar: ECS + Fargate.

---

## 10. Criterios de aceptación

**Arquitectónicos** — verificables automáticamente en CI:

> **Medidos el 04-09-2026** sobre 238 archivos fuente. Los seis primeros los
> comprueba `tools/metricas-arquitectura.mjs` en CI, y además los bloquean los
> guardarraíles de ESLint: no dependen de que alguien se acuerde de mirarlos.

- [x] Cero archivos de presentación importan el cliente HTTP o llaman a `fetch` (RNF-01; línea base del sistema actual: 447 queries en `.tsx`)
- [x] Cero archivos fuera de `infrastructure/api/` hablan con la red (RNF-02; línea base del sistema actual: 157 archivos con el SDK)
- [x] El dominio compila sin ninguna dependencia externa — guardarraíl 5
- [x] Ningún feature importa la `ui/` ni la `infrastructure/` de otro feature — guardarraíl 3. Comparten `domain/` a propósito, que es vocabulario, no implementación
- [x] Ningún componente accede a `matchMedia` ni a `navigator.standalone` — guardarraíl 4. Es lo que obliga a que los layouts adaptativos sean CSS, y por eso la agenda y la captura funcionan igual en teléfono y escritorio sin bifurcar
- [x] Cero referencias al tier legacy `CM` / `GTE` / `FARMER` en todo el repositorio
- [x] Las pruebas de dominio y de casos de uso corren **sin red ni servicio levantado** (RNF-03, meta 100 %) — 1 523 pruebas, ningún backend
- [x] Una sola implementación de Mi Día para escritorio y móvil (de 2 a 1) — cerrado con T-41/T-42

**Funcionales:**

- [ ] Cada invariante del dominio identificada en T-13…T-16 tiene al menos una prueba unitaria (RNF-04)
  - **Medido el 04-09-2026 y NO se cumple**, con un motivo concreto y una parte que no es nuestra. De las **196 reglas** catalogadas, **94 se citan en alguna prueba** y 138 en algún archivo fuente. El desglose señala el agujero sin ambigüedad:

    | Catálogo | Reglas | Citadas en prueba | Sin citar en ningún sitio |
    |---|---|---|---|
    | `gastos.md` | 55 | 36 | 9 |
    | `gestion.md` | 44 | 27 | 6 |
    | `visitas.md` | 55 | 28 | 13 |
    | `identidad.md` | **42** | **3** | **30** |

  - **La segunda medición, del mismo día, subió el denominador.** El manual
    maestro añadió cuatro reglas a `visitas.md` (V-54 a V-57) que la extracción
    original no tenía, porque no viven en ninguna migración. Es la forma correcta
    de que este número empeore: aparecen reglas que existían y no estaban
    escritas. **Leer el resto del anexo probablemente añada más**, y eso es
    bueno — una regla catalogada y sin probar es un riesgo conocido; una sin
    catalogar es un riesgo que nadie puede ver

  - **`identidad.md` es casi todo el hueco**, y no por descuido: cartera, alcance por asesor, «Ver como» y los permisos los hace cumplir el **servicio .NET**, donde **no hay proyecto de test**. Sus 42 reglas no se pueden probar desde aquí, y hoy nada las prueba en ninguna parte. Es el argumento más fuerte para añadir ese proyecto, que ya está en las decisiones abiertas
  - **Ojo con el número: contar citas no es medir cobertura.** Una regla puede estar probada sin que su identificador aparezca en el texto de la prueba, así que 89 es un **suelo**, no la cifra real. Lo que sí es firme es el otro extremo: las **59 reglas que no se citan en ningún archivo fuente** no las prueba nadie, porque nadie las ha escrito todavía
- [ ] Los cinco flujos críticos tienen prueba E2E en verde (RNF-05)
- [ ] Las pruebas de corte de red no pierden ninguna operación ni generan duplicados (RNF-08, RNF-09)
- [ ] Mi Día es interactivo en ≤ 2 s con conexión y ≤ 1 s desde snapshot local (RNF-06)
- [ ] Toda acción del asesor produce retroalimentación visible en ≤ 200 ms (RNF-07)
- [ ] La lista de paridad funcional está al 100 % y **firmada** antes del corte (RF-25)
- [x] La aplicación es instalable y su shell carga sin conexión (RNF-15) — cerrado con T-12; el build emite `sw.js` y precachea 36 entradas (552 KB), y `analiza-bundle` falla en CI si deja de emitirlas
- [ ] Contraste AA, objetivos táctiles ≥ 44 px y navegación por teclado en escritorio (RNF-17)
  - Los objetivos táctiles y el foco visible están puestos desde T-19 (`min-h-touch`, `focus-visible` en todo lo pulsable). **El contraste no se puede dar por bueno todavía porque la paleta va a cambiar en T-73**: medirlo ahora sería medir unos colores que no son los del corte. Se verifica *después* de T-73, no antes

**Operativos:**

- [ ] Revisión de las reglas de autorización de los endpoints, **firmada por TI** (T-67)
- [ ] Procedimiento de reversión documentado y **ensayado en un simulacro real** (RNF-21)
- [ ] Piloto completado con sus hallazgos resueltos o aceptados explícitamente
- [ ] Doble acceso a Facturación, Salas y Cobertura habilitado y **con fecha de vencimiento declarada**

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Reglas de negocio invisibles** que solo existen dentro de un `useEffect` y no se descubren hasta que un asesor reporta una regresión | Alta | Alto | T-13…T-16 son entregable propio y bloqueante: catálogo de reglas antes de escribir dominio. Cada regla, una prueba (RNF-04). El piloto (T-71) es la última red |
| **El corte único concentra el riesgo**: si falla, todos los asesores quedan afectados a la vez y en terreno | Media | Alto | Paridad firmada (T-68), reversión ensayada (T-70), piloto previo (T-71), corte en día de baja actividad (T-72). Antes del corte la decisión aún es reversible: se puede pasar a escalonado por país |
| **Meses sin entrega visible** al usuario; un malentendido se descubre tarde | Alta | Medio | Validaciones periódicas con asesores reales sobre versiones internas desde el final de la Fase 1, sin esperar al corte. La Fase 1 (P1) está diseñada como corte vertical demostrable: identidad + shell + offline + Mi Día + visitas |
| **Autorización mal traducida de RLS a código**: una regla omitida es un hueco de seguridad, y el repo de la API no tiene tests | Media | Alto | T-67 endpoint por endpoint, con las políticas del sistema actual como especificación y firma de TI; cada regla documentada en `Services/GarantiMax/doc/`; el modo demo deja de depender del guard del cliente |
| **Duplicados al sincronizar** operaciones encoladas | Media | Alto | Idempotencia obligatoria en el dominio (T-29) **y garantizada en la base** con índice único (T-18); pruebas de corte de red (T-66) |
| **Sobreingeniería**: capas, contratos y providers que no resuelven un problema real | Media | Medio | Cada abstracción declara en su ADR qué problema concreto resuelve. `RealtimeProvider` se queda en contrato sin implementación (ADR-005). Zustand solo cuando el estado cruza ramas del árbol |
| **El backend no llega a tiempo**: el frontend depende de endpoints que otro equipo construye | Media | Alto | Los contratos de los puertos se fijan primero (T-06) y el frontend avanza contra dobles de prueba (RNF-03); los endpoints se priorizan siguiendo el orden de las fases. Es riesgo de calendario, no de corrección |
| **Catálogos vacíos en la base nueva**: una visita es siempre a una sala, y sin migración no hay salas | Alta | Medio | **Para construir y probar, datos sembrados** (decisión del 26-08-2026): T-18 entrega el script de siembra junto con el esquema. La carga real la hace el responsable antes del piloto. Riesgo residual: el mecanismo de **actualización continua** de los catálogos en producción sigue sin definir, y su gestión es Fase 2 |
| **La estimación se desborda**: la Fase 1 del PRD equivale a reconstruir 7 módulos y ~35 mil líneas del sistema actual | Alta | Alto | Fases con corte vertical y estimación por rango (§13). Si el calendario aprieta, el recorte es por fase completa (P2 o P3 siguen temporalmente en el sistema actual), **nunca** relajando los guardarraíles arquitectónicos: eso reproduce el problema que motiva el proyecto |
| **Deriva del alcance hacia Fase 2** (la frontera entre "leer salas" y "gestionar salas" es delgada) | Alta | Medio | `ReferenciaRepository` **no expone ninguna escritura** (T-43); cualquier capacidad de gestión es Fase 2 por definición |
| **Dependencia de una sola persona** que conoce el sistema actual | Media | Alto | Los catálogos de reglas (T-13…T-16) son documentación permanente y reducen la dependencia; se producen al inicio, no al final |
| **Las siete Edge Functions hay que rehacerlas** — incluida `leer-boleta`, que lleva IA dentro | Alta | Alto | Es el mayor aumento de alcance de ADR-011 y está declarado como tal. El código actual es la especificación; se priorizan por fase, no todas al principio. `leer-boleta` es la más cara y la que más valor da al asesor |
| **Roles distintos del AF que hoy usan Mi Día** (10 tienen la capacidad) afectados por el corte sin haberlo planeado | Media | Medio | Verificar el uso real en producción antes de T-72 — pregunta abierta del PRD §14, se resuelve con una consulta de uso sobre la base del sistema actual |

---

## 12. Notas para el programador

**Decisiones tomadas durante la generación de este plan** (cierran preguntas abiertas del PRD §14):

1. **Dos repositorios propios**: `siga_alfa` para el frontend y `Services/GarantiMax/` dentro de `gp_3.0_siga_api` para el backend (ADR-011). Consecuencias que el plan asume: CI, hospedaje y variables se manejan por separado; el frontend **no** contiene esquema, SQL ni carpeta `supabase/`; y las tareas que producen especificación para el servicio (T-18, T-67) entregan documentos, no código de backend. El repositorio del sistema actual es **solo lectura**: es la fuente de las reglas.
2. **ADR-006 aprobado**: React Router, TanStack Query y Zustand entran como decisión cerrada (T-03). Regla que no se negocia: **la función que se le pasa a TanStack Query siempre invoca un caso de uso**, nunca un repositorio ni el SDK. Sin esa regla, Query se convierte en la nueva forma de meter queries en las vistas.
3. **La evidencia de visitas se encola sin señal**, igual que las boletas (T-39). El PRD lo dejaba abierto; encolarla es coherente con RNF-08 ("ninguna operación del asesor se pierde") y con la cola que T-30 ya construye para imágenes. Si la operación decide que la evidencia exige conexión, se simplifica T-39 — no al revés.
4. **Rama base `develop` del repositorio nuevo**, con la estructura Engine completa (`main`, `develop`, `pre-qa`, `qa`). El repositorio actual queda como está: normalizarlo obligaría a tocar un sistema en producción fuera de alcance.
5. **Una rama por fase**, todas desde `develop`, con el prefijo `feature/PJ4487-garantimax-refactor-`. Seis meses de trabajo en una sola rama funcional no es revisable.

**Preguntas abiertas del PRD §14 que siguen sin resolver y hay que cerrar antes de las tareas que dependen de ellas:**

| Pregunta | Bloquea |
|---|---|
| ¿Cuáles de los 10 roles que hoy tienen la capacidad `midia` entran al corte? | T-72 (y define qué roles hay que dar de alta en la API) |
| ¿El corte es simultáneo o escalonado por país (Chile / Perú / Argentina)? | T-71, T-72 |
| ¿Qué pasa con `www.garantimax.com` el día del corte? | T-69 |
| ~~¿Cuánto tiempo debe poder operar el asesor sin señal?~~ | **Resuelto en T-41:** el snapshot de Mi Día vale **el día que guarda**, no un plazo. Un plazo corto deja al asesor sin nada a media mañana en una sala sin señal; uno largo permitiría mostrarle el día de ayer. Las operaciones que él produce no caducan: la cola las guarda hasta enviarlas |
| ~~¿Se elimina el tier `CM/GTE/FARMER`?~~ | **Resuelto por ADR-011.** El sistema nuevo tiene identidad propia y no lee nada del actual. Deja de ser asunto de este proyecto |
| ¿Cuál es el nombre exacto del rol del Asesor Farmer en la API? | T-22, T-24 — el frontend necesita el identificador para resolver permisos en un solo punto |
| ~~¿Cómo se pueblan los catálogos?~~ | **Resuelto:** datos sembrados para construir y probar (T-18 entrega el script); carga real antes del piloto. Sigue abierto cómo se **actualizan** en producción — bloquea el cierre de Fase 2, no la Fase 1 |
| ¿Quién construye `Services/GarantiMax/` y con qué calendario? | El corte (T-72). El frontend avanza contra dobles de prueba, pero sin endpoints no hay corte |
| ¿Cómo se programan los procesos periódicos sobre ECS + Fargate? | T-62 (notificaciones) |
| ¿Qué hace el asesor si necesita corregir un dato de un vendedor durante una visita? | T-43 — hoy el plan asume que lo reporta y se corrige en el sistema actual (Fase 2) |
| ¿Quién revisa y firma las reglas de autorización del servicio? | T-67 |

**Detalles operativos que evitan errores conocidos:**

- **Validación antes de pedir review:** `npx tsc -b` y `npm run build`. **No** `tsc --noEmit` — con `tsconfig` tipo "solution" no chequea nada. Tests con `npm test`, lint con `npm run lint`.
- **La base del sistema actual es de solo lectura.** Nada de migraciones ahí. Si al leerla se ejecuta algo vía MCP, solo lecturas: **cualquier escritura** requiere OK explícito, mostrando antes qué hace, el SQL exacto y cuántas filas toca.
- **Leer el histórico de migraciones tiene trampas.** Tres tablas centrales fueron destruidas y recreadas con diseño distinto (`visitas`, `bitacoras`, `sala_vendedores`), la tabla `salas` está abandonada, y hay 15 números de migración duplicados entre 364. Vale la **última** definición de cada objeto, verificada contra el uso real en el código. Detalle en A3 §3.
- **No compiles ni arranques servicios del repo de la API por tu cuenta:** es regla explícita de ese repositorio. Se sugiere el comando y se espera.
- **Versión:** no se edita a mano; la inyecta el build. Si el repositorio nuevo replica ese mecanismo, replica también la regla.
- **Paginación:** el tope de PostgREST desaparece, la regla no. Todo listado del asesor pagina o acota por fecha, y el contrato del endpoint lo declara.
- **Idioma:** ojo, hay **dos convenciones distintas** según el repositorio. En el repo de la API el código va en **inglés** (es su `CODING_GUIDELINES.md`), con los mensajes al usuario final en español. En `siga_alfa` rige lo ratificado abajo. `rules/coding-guidelines.md` exige código en inglés. El sistema actual y todo el dominio de este PRD están en español (`visitas`, `rendiciones`, `bitacoras`), y las tablas y RPCs también. **Recomendación:** conservar el español en los nombres del dominio —renombrarlos rompería la correspondencia con la base y con el lenguaje del negocio— y usar inglés para lo técnico transversal. Es una desviación consciente que conviene ratificar con TI antes de T-02, porque después es cara de revertir. ~~**RATIFICADO (2026-08-25):** español en el dominio e inglés en lo técnico transversal.~~

  ⚠️ **REEMPLAZADO EL 2026-08-28 por Javier Antonio Oropeza Camacho: todo el código en inglés**, en los dos repositorios. Español queda solo en (1) tablas y columnas de la base, (2) mensajes al usuario final, (3) comentarios.

  **Por qué se revirtió.** La regla del 25-08 producía **tres nombres para el mismo concepto** —`Visita` en el frontend, `Visit` en el servicio, `visitas` en la tabla— y una traducción en cada frontera. Con todo en inglés son dos, y la segunda la hace el ORM en un solo lugar por entidad (`Property(x => x.Date).HasColumnName("fecha")`). Desaparece además la desviación de `rules/coding-guidelines.md`, que exigía inglés.

  **Costo pagado:** renombrado de las 7 carpetas de feature (con `git mv`, historial conservado) y de los identificadores de la capa transversal del frontend. Se hizo cuando había cero consumidores del cliente HTTP y de los errores; en dos semanas habrían sido veinte repositorios y cada pantalla.

  **Glosario obligatorio** antes de nombrar una entidad nueva: `[repo api] Services/GarantiMax/doc/nomenclatura.md`. El término resbaladizo es `sala → Showroom`, que **no** es `PointOfSale` — eso significa otra cosa en `Services/Catalogs`.

  **Lección operativa, aprendida a golpes:** al renombrar en bloque, **nada de reemplazo ciego de palabras cortas**. Cambiar `campo` → `field` sobre archivos completos destrozó la prosa de los comentarios («basta un field con el tipo equivocado») y **ni `tsc` ni el linter lo detectan**, porque son comentarios.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles**, para **un desarrollador a tiempo completo**. Los rangos salen de la complejidad de las tareas de cada fase, no de un objetivo de calendario.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Fundaciones, guardarraíles y extracción de reglas** | Repositorio con ramas Engine, andamiaje, librerías del ADR-006, configuración tipada, jerarquía de errores, contratos y providers, contenedor, 5 reglas de linter, métricas y CI, PWA, sistema de componentes, **catálogos de reglas del sistema actual**, línea base medida y **especificación del esquema para el servicio** | T-01 a T-19 | 30 – 40 días | 193 |
| **Fase 1 — Núcleo verificable del asesor (P1)** | Identidad, sesión y permisos por rol del JWT · shell adaptativo, rutas y bienvenida · motor offline completo (cola, idempotencia, decorador, estado observable) · Mi Día con snapshot · visitas con check-in, borrador, evidencia, aviso global y cierre · lobbies · catálogos de referencia en lectura | T-20 a T-43 | 40 – 52 días | 194 |
| **Fase 2 — Gestión del asesor (P2)** | Tareas y avances · agenda y días hábiles · cumpleaños y saludos · bitácora diaria con dictado y mejora de redacción | T-44 a T-54 | 20 – 26 días | 195 |
| **Fase 3 — Gastos y rendiciones (P3)** | Dominio de gasto y rendición · repositorios y RPCs · captura de boleta con lectura automática · decorador offline con imágenes · categorización y asignación · rendiciones y observación del flujo de aprobación | T-55 a T-61 | 20 – 27 días | 196 |
| **Fase 4 — Notificaciones, verificación, auditoría y corte** | Notificaciones · eventos de BI · observabilidad y auditoría · E2E de los 5 flujos críticos · pruebas de corte de red · revisión de la autorización de los endpoints · lista de paridad · despliegue · reversión ensayada · **identidad visual y pasada de diseño** · piloto · corte único | T-62 a T-73 | 35 – 47 días | 197 |
| **Total proyecto (P1+P2+P3+cierre)** | | **73 tareas** | **~145 – 192 días hábiles (≈ 29 – 39 semanas)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-43 | **~70 – 92 días hábiles (≈ 14 – 19 semanas)** | — |

> **Notas sobre la tabla:**
> - Las prioridades P1/P2/P3 son de este plan, no del PRD: el PRD entero es su Fase 1 de producto. **P1 es el corte vertical que demuestra la arquitectura completa** —de la ruta al dominio, con offline real— sobre el trabajo más crítico del asesor. Si algo se recorta, se recorta P3 o P2 completo (esos módulos siguen temporalmente en el sistema actual), **nunca** los guardarraíles de la Fase 0: sin ellos el proyecto reproduce el problema que lo motiva.
> - La Fase 4 **no es "pruebas al final"**: cada fase entrega sus propias pruebas de dominio y de casos de uso. La Fase 4 contiene lo que solo puede hacerse con el sistema completo (E2E, corte de red, paridad, auditoría, piloto y corte).
> - La Fase 0 parece cara para no entregar pantallas. Lo es a propósito: 12 de sus 30–40 días son la **extracción de reglas** (T-13…T-16), que el PRD identifica como el mayor riesgo del proyecto — reescribir sin encontrar las reglas invisibles produce regresiones sutiles que aparecen recién en terreno.

> **Riesgo de deadline.** **El PRD no fija fecha límite** («este PRD define qué y por qué; el plan de desarrollo se elabora aparte», §6 y §14), así que no hay días hábiles disponibles contra los cuales contrastar. Lo que sí puede afirmarse: con **un desarrollador**, el alcance completo son **~7 a 9 meses** de trabajo, y el corte único implica que **no hay entrega al usuario hasta el final**. Recomendaciones explícitas:
> 1. **Fijar la fecha objetivo antes de arrancar.** Sin ella, un proyecto de este tamaño y sin entregas intermedias no tiene forma de detectar que se está desviando.
> 2. **Sumar un segundo desarrollador** una vez cerrada la Fase 0. Las Fases 2 y 3 son paralelizables por feature (tareas/agenda/bitácora frente a gastos/rendiciones) y la Fase 1 admite dividir el motor offline del núcleo de visitas. La compresión esperada es de **~30 – 35 %** —no del 50 %: la Fase 0 es fundación compartida y no se paraleliza, y el trabajo conjunto añade coordinación—, lo que dejaría el total en **~100 – 130 días hábiles (≈ 20 – 26 semanas)**.
> 3. **Si el calendario no alcanza**, recortar por fase completa: entregar P1 (Fase 0 + Fase 1) y mantener temporalmente tareas, agenda, bitácora y gastos en el sistema actual, ampliando el doble acceso. Es un corte más caro operativamente pero **preserva la arquitectura**, que es el objetivo del proyecto.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-5 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
