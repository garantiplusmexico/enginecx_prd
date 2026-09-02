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
- [ ] **Repositorio nuevo `siga_alfa` creado** en la organización, con permisos para el responsable
- [ ] Acceso de **lectura** al repositorio actual `garantiplusmexico/garantiplus-dashboard`: es la fuente para extraer las reglas de negocio (migraciones, funciones y políticas RLS). **No se escribe nada ahí**
- [ ] Acceso de escritura al repositorio de la API `garantiplusmexico/gp_3.0_siga_api` y al entorno donde vive su base de datos
- [ ] **Servicio `Services/GarantiMax/` creado** en el monorepo de la API, con su base de datos aprovisionada y su `DbContext` propio
- [ ] `VITE_API_BASE_URL` definida para desarrollo, QA y producción (local: puerto 5006 por convención del repo de la API)
- [ ] Usuario de prueba con rol de Asesor Farmer dado de alta en la base de la API, y **nombre exacto del rol** comunicado al frontend (pregunta abierta del PRD §14)
- [ ] `VITE_SENTRY_DSN` disponible (proyecto Sentry nuevo o reutilizado)
- [ ] Proyecto Vercel nuevo creado y dominio de transición decidido (ver §9)
- [ ] `CLAUDE.md` presente en el repositorio nuevo (se genera en T-02; el del repo actual ya existe)
- [ ] ADR-006 ratificado por TI (librerías) — **aprobado en la generación de este plan**
- [ ] Disponibilidad confirmada de asesores reales para validaciones periódicas y para el piloto (supuesto del PRD §13)
- [ ] Definido quién revisa y **firma** las reglas de autorización de los endpoints del servicio, sustituto de la auditoría de RLS (pregunta abierta del PRD §14)
- [ ] Datos de prueba sembrados en las tablas de referencia (salas, vendedores de sala, clientes) para poder construir y probar — el script sale de T-18; la carga real la hace el responsable antes del piloto

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

- [ ] **T-S09** — Endpoints de gastos y rendiciones
  - Criterio de completitud: la **máquina de estados completa** (`borrador → enviada → aprobada_jefe → aprobada_ops → pagada`, más `rechazada` y el contador de reenvíos) con las transiciones válidas garantizadas en el servicio, no en la UI. Es el bloque con más negocio del alcance. La aprobación y el pago quedan **bloqueados** para el rol del asesor

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

- [~] **T-39** — Evidencia de visita *(parcial: falta la captura; el almacenamiento está listo salvo el bucket)*
  - Archivos creados: en la API, `Controllers/FilesController.cs`, `Interfaces/IFileStorage.cs`, `Services/S3FileStorage.cs`, `Options/FileStorageOptions.cs`, `doc/donde-viven-las-fotos.md`; en el frontend, `src/infrastructure/storage/ApiStorageProvider.ts` + pruebas
  - Criterio de completitud: captura desde cámara, subida a Storage y **encolado sin señal igual que las boletas**; ninguna imagen se pierde en las pruebas de corte de red
  - **Decidido el 31-08-2026: los blobs van a S3.** El bucket todavía no existe, así que el código está escrito y lo único que falta es crearlo y llenar la sección `FileStorage`. El servicio **arranca sin eso configurado a propósito**: validarlo al arrancar dejaría caído el servicio entero por una funcionalidad que nadie puede usar aún, así que los endpoints responden 503 con un mensaje utilizable —«registra la visita sin evidencia»— y el resto sigue trabajando
  - **La clave la propone el cliente y el servidor la acota.** `{prefix}/{advisorId}/{scope}/{path}`: el `path` es un uuid del teléfono y la subida sobreescribe (V-31), pero el asesor y el ámbito los pone el servidor desde el token. Por eso no hay consulta de «¿este archivo es mío?»: un archivo que no subió no tiene una clave que pueda nombrar
  - **Se corrigió el contrato `StorageProvider`**, que decía que la ruta la decide el servicio. Estaba mal: con una ruta del servidor, cada reintento de la cola habría creado un objeto nuevo y la fila se habría quedado apuntando al primero, el resto huérfano y pagándose en la factura de S3
  - **Falta**: la captura desde la cámara, la compresión (V-30) y el encolado del blob (V-31)

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

- [ ] **T-50** — Interfaz de agenda
  - Archivos a crear/modificar: `src/features/agenda/ui/*.tsx`
  - Criterio de completitud: calendario adaptativo; se agenda desde Mi Día; se marca realizado, cancelado o reagendado (RF-11)

- [ ] **T-51** — Cumpleaños y saludos
  - Archivos a crear/modificar: `src/features/agenda/application/{ObtenerCumpleanosDelDia,RegistrarSaludo}.ts`, `ui/` + pruebas
  - Criterio de completitud: usa `cumpleanos_vendedores` y `saludos_cumpleanos`; el saludo queda registrado como interacción y aparece en Mi Día (RF-13)

- [ ] **T-52** — Dominio de bitácora
  - Archivos a crear/modificar: `src/features/bitacora/domain/*.ts` + pruebas
  - Criterio de completitud: **una por asesor y día**; se considera cumplida con contenido en los campos obligatorios; el incumplimiento se evalúa al cierre del día hábil; las exenciones vigentes del sistema actual quedan reflejadas o descartadas explícitamente

- [ ] **T-53** — `BitacoraRepository` y casos de uso, incluidas las funciones de servidor
  - Archivos a crear/modificar: `src/features/bitacora/{ports,infrastructure,application}/*.ts` (`RegistrarBitacoraDelDia`, `TranscribirDictado`, `MejorarRedaccion`, `VerificarCumplimientoDiario`) + pruebas
  - Criterio de completitud: `transcribir-bitacora`, `mejorar-bitacora` y `mejorar-redaccion` se invocan **desde infraestructura**, reutilizadas tal cual; el cliente nunca maneja credenciales de los proveedores de IA (RF-15, RNF-11); las pruebas de inyección de prompt del sistema actual se portan y se extienden

- [ ] **T-54** — Interfaz de bitácora
  - Archivos a crear/modificar: `src/features/bitacora/ui/*.tsx`
  - Criterio de completitud: novedades, problemas, plan y texto libre con las salas mencionadas; dictado por voz y mejora de redacción; el estado de cumplimiento del día es visible (RF-14)

### Fase 3 — Gastos, boletas y rendiciones (P3)

- [ ] **T-55** — Dominio de gasto y rendición
  - Archivos a crear/modificar: `src/features/gastos/domain/*.ts` + pruebas
  - Criterio de completitud: un gasto pertenece a un asesor y tiene categoría y asignación; **un gasto incluido en una rendición enviada no se modifica**; rendición `borrador → enviada → aprobada_jefe → aprobada_ops → pagada`, con `rechazada` desde cualquier estado de aprobación y reentrada por `reenviada`; el asesor solo transiciona `borrador → enviada` y `rechazada → reenviada`

- [ ] **T-56** — `GastoRepository` y `RendicionRepository`
  - Archivos a crear/modificar: `src/features/gastos/{ports,infrastructure}/*.ts` + pruebas de mapeo
  - Criterio de completitud: cubren `gastos`, `gasto_archivos`, `gasto_asignaciones`, `gasto_categorias`, `rendiciones`, `rendicion_eventos` y las RPCs `gasto_crear`, `gasto_fusionar`, `rendicion_enviar`, `rendicion_rechazar`, `rendicion_reenviar` (las de aprobación y pago quedan declaradas en el contrato pero no expuestas al asesor)

- [ ] **T-57** — Casos de uso de gasto
  - Archivos a crear/modificar: `src/features/gastos/application/{CapturarBoleta,LeerDatosDeBoleta,RegistrarGasto,AsignarGasto,FusionarGastos}.ts` + pruebas
  - Criterio de completitud: `LeerDatosDeBoleta` invoca `leer-boleta` desde infraestructura y **permite corregir los datos antes de guardar** (RF-16); la asignación admite sala, visita o proyecto (RF-18)

- [ ] **T-58** — Decorador offline de gastos
  - Archivos a crear/modificar: `src/features/gastos/infrastructure/GastoRepositoryOffline.ts` + pruebas
  - Criterio de completitud: la boleta se guarda localmente **con su imagen** y se sincroniza al recuperar señal, con reintentos y **sin duplicar el gasto** (RF-17, RNF-09); reemplaza por completo a `useSincronizarBoletas` sin heredar su acoplamiento a `App.tsx`

- [ ] **T-59** — Interfaz de captura y categorización
  - Archivos a crear/modificar: `src/features/gastos/ui/{CapturaBoletaPage,DetalleGastoPage}.tsx`
  - Criterio de completitud: captura desde cámara, corrección de los datos leídos, categoría y destino; operable con una sola mano (RNF-16); funciona sin señal indicando que quedó encolada

- [ ] **T-60** — Rendiciones
  - Archivos a crear/modificar: `src/features/gastos/application/{ArmarRendicion,EnviarRendicion}.ts` y la observación de estado + pruebas
  - Criterio de completitud: agrupa gastos, envía, y el asesor **observa** el avance por jefe, operaciones y pago; puede reenviar tras rechazo (RF-19). La aprobación se sigue operando en el sistema actual durante la Fase 1

- [ ] **T-61** — Interfaz de rendiciones y trazabilidad
  - Archivos a crear/modificar: `src/features/gastos/ui/RendicionesPage.tsx`
  - Criterio de completitud: lista y detalle con la línea de tiempo de `rendicion_eventos`; cada transición queda registrada con actor, momento y resultado (RNF-13)

### Fase 4 — Notificaciones, verificación, auditoría y corte

- [ ] **T-62** — Notificaciones al asesor
  - Archivos a crear/modificar: `src/features/identidad/{ports,infrastructure,application,ui}/Notificacion*` + pruebas
  - Criterio de completitud: avisa de visitas abiertas sin cerrar, tareas atrasadas y bitácoras pendientes, leyendo `notificaciones` y respetando lo que producen `visitas-abiertas-cron` y `tareas-atrasadas-cron` (RF-20)

- [ ] **T-63** — Eventos de producto para BI
  - Archivos a crear/modificar: `src/shared/observability/eventos.ts` y su emisión desde los casos de uso + pruebas
  - Criterio de completitud: los eventos del PRD §11 se emiten **desde la capa de aplicación, nunca desde la UI**, con fecha, asesor, identificadores de negocio, resultado y motivo; escriben en `eventos_producto` (T-18)

- [ ] **T-64** — Observabilidad y auditoría de operaciones críticas
  - Archivos a crear/modificar: `src/shared/observability/*` y la configuración de Sentry
  - Criterio de completitud: los errores no controlados llegan a Sentry con traza, versión, ruta, categoría e identificador de usuario y **sin datos personales**; nunca se registra contenido de bitácoras, imágenes de boletas ni ubicaciones exactas (A1 §11); apertura y cierre de visita, transiciones de rendición y envío de bitácora quedan auditados

- [ ] **T-65** — Pruebas de extremo a extremo de los cinco flujos críticos
  - Archivos a crear/modificar: `e2e/*.spec.ts`, `playwright.config.ts`, workflow de CI
  - Criterio de completitud: en verde (1) inicio de sesión y resolución de permisos, (2) visita completa check-in → captura → evidencia → cierre, (3) intento de segunda visita y descarte de la primera, (4) boleta sin señal con sincronización posterior sin duplicado, (5) bitácora con dictado y mejora (RNF-05)

- [ ] **T-66** — Pruebas de corte de red
  - Archivos a crear/modificar: `e2e/offline/*.spec.ts`, `docs/pruebas-offline.md`
  - Criterio de completitud: **0 operaciones perdidas y 0 duplicados** cortando la red en cada punto del ciclo de check-in, cierre de visita, avance de tarea, bitácora y boleta (RNF-08, RNF-09); incluye el escenario de tres horas sin señal

- [ ] **T-67** — Revisión de las reglas de autorización del servicio
  - Archivos a crear/modificar: `docs/autorizacion-fase1.md` y los documentos correspondientes en `[repo api] Services/GarantiMax/doc/`
  - Criterio de completitud: endpoint por endpoint, qué puede leer y escribir el asesor y **cómo lo garantiza el servicio**. La fuente de la especificación son las ~150 políticas RLS del sistema actual, leídas tabla por tabla. El modo demo queda respaldado por el servicio y no solo por el guard del cliente. Documento **firmado por TI** (A1 §15.11). Agravante que hay que compensar con revisión humana: el repo de la API **no tiene proyectos de test**

- [ ] **T-68** — Lista de paridad funcional
  - Archivos a crear/modificar: `docs/paridad.md`
  - Criterio de completitud: cada funcionalidad de terreno del sistema actual con su equivalente verificado en el nuevo, probada por un asesor real, con estado y responsable; **firmada antes del corte** (RF-25). Sin el 100 %, el corte no se ejecuta

- [ ] **T-69** — Despliegue y ambientes
  - Archivos a crear/modificar: `vercel.json`, configuración del proyecto Vercel, variables por ambiente
  - Criterio de completitud: proyecto Vercel nuevo con SPA y reescrituras a `/index.html`; ambientes de desarrollo, QA y producción con sus variables; dominio de transición operativo (ver §9); previews por PR funcionando

- [ ] **T-70** — Procedimiento de reversión
  - Archivos a crear/modificar: `docs/reversion.md`
  - Criterio de completitud: pasos, responsables, tiempos y criterio de decisión para devolver a los asesores al sistema actual **dentro de la misma jornada**; **ensayado en un simulacro real** antes del corte, con el resultado registrado (RNF-21)

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

- [ ] Cero archivos de presentación importan el cliente HTTP o llaman a `fetch` (RNF-01; línea base del sistema actual: 447 queries en `.tsx`)
- [ ] Cero archivos fuera de `infrastructure/api/` hablan con la red (RNF-02; línea base del sistema actual: 157 archivos con el SDK)
- [ ] El dominio compila sin ninguna dependencia externa
- [ ] Ningún feature importa la `ui/` ni la `infrastructure/` de otro feature
- [ ] Ningún componente accede a `matchMedia` ni a `navigator.standalone`
- [ ] Cero referencias al tier legacy `CM` / `GTE` / `FARMER` en todo el repositorio
- [ ] Las pruebas de dominio y de casos de uso corren **sin red ni servicio levantado** (RNF-03, meta 100 %)
- [ ] Una sola implementación de Mi Día para escritorio y móvil (de 2 a 1)

**Funcionales:**

- [ ] Cada invariante del dominio identificada en T-13…T-16 tiene al menos una prueba unitaria (RNF-04)
- [ ] Los cinco flujos críticos tienen prueba E2E en verde (RNF-05)
- [ ] Las pruebas de corte de red no pierden ninguna operación ni generan duplicados (RNF-08, RNF-09)
- [ ] Mi Día es interactivo en ≤ 2 s con conexión y ≤ 1 s desde snapshot local (RNF-06)
- [ ] Toda acción del asesor produce retroalimentación visible en ≤ 200 ms (RNF-07)
- [ ] La lista de paridad funcional está al 100 % y **firmada** antes del corte (RF-25)
- [ ] La aplicación es instalable y su shell carga sin conexión (RNF-15)
- [ ] Contraste AA, objetivos táctiles ≥ 44 px y navegación por teclado en escritorio (RNF-17)

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
| **Fase 4 — Notificaciones, verificación, auditoría y corte** | Notificaciones · eventos de BI · observabilidad y auditoría · E2E de los 5 flujos críticos · pruebas de corte de red · revisión de la autorización de los endpoints · lista de paridad · despliegue · reversión ensayada · piloto · corte único | T-62 a T-72 | 32 – 42 días | 197 |
| **Total proyecto (P1+P2+P3+cierre)** | | **72 tareas** | **~142 – 187 días hábiles (≈ 28 – 37 semanas)** | — |
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
