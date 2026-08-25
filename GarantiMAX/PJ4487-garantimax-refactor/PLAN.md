# Plan de Desarrollo — Reconstrucción de GarantiMAX · Fase 1: núcleo del Asesor Farmer

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/GarantiMAX/PJ4487-garantimax-refactor/PRD.md` (+ anexos A1 arquitectura, A2 ADRs, A3 inventario) |
| Repositorio | **Nuevo** — `garantimax-app` (a crear). Repo del sistema actual: `garantiplusmexico/garantiplus-dashboard` (lectura para extracción de reglas; escritura solo para migraciones aditivas) |
| Rama | `feature/PJ4487-garantimax-refactor-nucleo-asesor` (Fase 0) · una rama por fase con el mismo prefijo, todas desde `develop` |
| Tipo | Proyecto nuevo (re-arquitectura sobre base de datos existente) |
| Responsable | Javier Antonio Oropeza Camacho |
| Folio PRD | PJ4487 |
| Fecha de generación | 2026-08-25 |
| Estado | Borrador |
| ID plan (BD) | `56` (`pm_plan_desarrollo.id`) |

**Rama base:** `develop` del repositorio nuevo `garantimax-app`.

> ⚠️ **Nota sobre la rama base.** El repositorio del sistema actual (`garantiplus-dashboard`) **no tiene `develop` ni `main`**: trabaja sobre `master` con ramas `feat/` y `fix/`, y no cumple el estándar de `rules/version-control.md`. Como la aplicación nueva vive en un repositorio propio (decisión tomada en la generación de este plan), **el repositorio nuevo nace ya con la estructura Engine completa** — `main`, `develop`, `pre-qa`, `qa` — y este plan se ejecuta desde `develop`. El repositorio actual se deja como está: normalizarlo obligaría a tocar un sistema en producción que está fuera del alcance de este PRD.

---

## 1. Resumen técnico

Se **reconstruye desde cero la aplicación de terreno del Asesor Farmer** en un repositorio nuevo, sobre el **mismo esquema de datos en producción** (26 de las 128 tablas) y reutilizando las **6 Edge Functions** que la Fase 1 consume. No hay migración de datos: ambos sistemas leen y escriben la misma base durante toda la transición.

**Qué se crea.** Una SPA React 19 + TypeScript + Vite + Tailwind v4, organizada por **feature de dominio con capas internas** (ADR-001): `domain` · `application` · `ports` · `infrastructure` · `ui` dentro de cada feature (`identidad`, `visitas`, `tareas`, `agenda`, `bitacora`, `gastos`, `referencia`), más `app/` (composición y rutas), `shared/` (sistema de componentes, layouts, errores, sincronización, observabilidad), `infrastructure/` transversal y `config/`. El SDK de Supabase queda confinado a `infrastructure/`; ninguna vista consulta la base.

**Qué se rediseña frente al sistema actual.** La navegación (de `useState<Tab>` en un `App.tsx` de 916 líneas a rutas reales con React Router), el acceso a datos (de 447 queries dentro de `.tsx` a repositorios por agregado detrás de casos de uso), la experiencia web/móvil (de dos aplicaciones a **un layout adaptativo** — ADR-007), la detección de PWA (de `if (isPWA)` distribuido a un único `DeviceContextProvider`), el manejo de errores (de improvisado a jerarquía tipificada) y el soporte offline (de parches en `App.tsx` a un **decorador de repositorio** — ADR-009).

**Qué se elimina y no se traslada.** El tier legacy `CM/GTE/FARMER` (ADR-008: el sistema nuevo resuelve permisos **solo** contra la matriz `roles × capacidades`), las carpetas vacías `farmer/` y `bitacora/`, `MiDiaMovilPreview` y el parámetro `?midia`, y el drenaje de cola offline desde `App.tsx`.

**Stack.** React 19 + Vite 8 + TypeScript + Tailwind v4 (continuidad con el sistema actual, PRD §6) · **React Router** (navegación), **TanStack Query** (datos de servidor), **Zustand** acotado (estado de UI transversal) — ADR-006, aprobadas como decisión cerrada en la generación de este plan · Vitest (unitarias e integración) + **Playwright** (E2E, nuevo) · Supabase (Postgres con RLS, Auth, Storage, Edge Functions) · Sentry · Vercel.

> **Desviación declarada frente a `rules/stack.md` e `rules/infraestructura.md`.** El estándar Engine para backend nuevo es .NET Core 8 sobre ECS + Fargate, y para SPA estática, S3 + CloudFront. Aquí **no se construye backend** (ADR-004: acceso directo cliente→Supabase con RLS y lista cerrada de excepciones) y el hospedaje **se conserva en Vercel** porque el PRD deja explícitamente fuera de alcance el cambio de stack y de proveedor (§6). La decisión de plataforma —migrar o no al estándar corporativo— corresponde al análisis técnico en curso (PJ3896) y este proyecto la **habilita** encapsulando Supabase, no la ejecuta (ADR-002). Requiere visto bueno de TI; ver §9 y §12.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable (PJ4487, v0.1) y anexos A1/A2/A3 leídos por quien ejecuta
- [ ] **Repositorio nuevo `garantimax-app` creado** en la organización, con permisos para el responsable
- [ ] Acceso de lectura al repositorio actual `garantiplusmexico/garantiplus-dashboard` (extracción de reglas) y de escritura para las migraciones aditivas
- [ ] Credenciales del proyecto Supabase `jrykbalmnpymeyzdhsam` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`) para desarrollo, QA y producción
- [ ] `VITE_SENTRY_DSN` disponible (proyecto Sentry nuevo o reutilizado)
- [ ] Proyecto Vercel nuevo creado y dominio de transición decidido (ver §9)
- [ ] `CLAUDE.md` presente en el repositorio nuevo (se genera en T-02; el del repo actual ya existe)
- [ ] ADR-006 ratificado por TI (librerías) — **aprobado en la generación de este plan**
- [ ] Disponibilidad confirmada de asesores reales para validaciones periódicas y para el piloto (supuesto del PRD §13)
- [ ] Definido quién ejecuta y **firma** la auditoría de RLS de las 26 tablas (pregunta abierta del PRD §14)

---

## 3. Arquitectura del cambio

Arquitectura aplicada: **Frontend + Backend separados** en la clasificación de `rules/arquitectura.md`, donde el "backend" es Supabase gestionado (Postgres con RLS + Auth + Storage + Edge Functions) y **no se construye un servicio propio**. La complejidad no justifica microservicios ni un BFF (ADR-004), y el dominio es único: el trabajo de terreno del asesor.

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
   Infraestructura                       │ SupabaseXRepository       │
   (infrastructure/)                     │ XRepositoryOffline (deco) │
                                         │ Auth·Storage·Local·Sentry │
                                         └───────────┬───────────────┘
                                                     │
                              ┌──────────────────────┴──────────────┐
                              ▼                                     ▼
              Supabase (Postgres+RLS · Auth ·                 IndexedDB
              Storage · Edge Functions) · Sentry        (snapshot + cola offline)
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
├─ infrastructure/ supabase/ · auth/ · storage/ · realtime/ (solo contrato) · local/
└─ config/         variables de entorno tipadas y validadas al arrancar
```

---

## 4. Tareas de desarrollo

> Convención: cada tarea es atómica, se prueba sola y se integra a `develop` por PR desde su rama de fase.
> Las rutas de archivo son del **repositorio nuevo** salvo que se indique `[repo actual]`.

### Fase 0 — Fundaciones, guardarraíles y extracción de reglas

- [ ] **T-01** — Crear el repositorio `garantimax-app` con la estructura de ramas Engine
  - Archivos a crear/modificar: `README.md`, `.gitignore`, `.github/CODEOWNERS`
  - Criterio de completitud: existen `main`, `develop`, `pre-qa`, `qa`; `main` protegida con 2 aprobaciones; `develop` sin commits directos; el responsable tiene acceso

- [ ] **T-02** — Andamiaje base de la aplicación y estructura de carpetas de A1 §3
  - Archivos a crear/modificar: `package.json`, `vite.config.ts`, `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`, configuración de Tailwind, `src/main.tsx`, `src/app/App.tsx`, árbol completo de `src/` con un `index.ts` por capa, `CLAUDE.md`
  - Criterio de completitud: `npx tsc -b` y `npm run build` pasan en verde sobre un esqueleto que renderiza una ruta vacía; el árbol de carpetas coincide con A1 §3

- [ ] **T-03** — Instalar y configurar React Router, TanStack Query y Zustand (ADR-006)
  - Archivos a crear/modificar: `package.json`, `src/app/providers/QueryProvider.tsx`, `src/app/routes/index.tsx`, `src/shared/sync/store.ts`
  - Criterio de completitud: router montado con dos rutas de prueba y navegación con URL e historial; `QueryClient` configurado con política de reintentos y `staleTime` documentados; store de Zustand creado vacío con su regla de uso escrita en `CLAUDE.md`

- [ ] **T-04** — Configuración tipada y validada al arranque
  - Archivos a crear/modificar: `src/config/env.ts`, `src/config/env.test.ts`, `.env.example`
  - Criterio de completitud: si falta o es inválida una variable requerida, la aplicación falla al arrancar con un mensaje claro; ninguna variable se lee con `import.meta.env` fuera de `config/` (verificado por linter en T-09)

- [ ] **T-05** — Jerarquía de errores tipificados y su traducción a mensajes
  - Archivos a crear/modificar: `src/shared/errors/*.ts`, `src/shared/errors/traducir.ts`, `src/shared/errors/*.test.ts`
  - Criterio de completitud: existen las 7 categorías de A1 §10 (`DomainError`, `ValidationError`, `AuthenticationError`, `AuthorizationError`, `NetworkError`, `ProviderError`, `InfrastructureError`); pruebas que verifican que ningún mensaje al usuario contiene nombre de tabla, SQL, ruta interna ni el mensaje original del proveedor

- [ ] **T-06** — Contratos transversales (ports), sin implementación
  - Archivos a crear/modificar: `src/shared/observability/MonitoringProvider.ts`, `src/infrastructure/auth/AuthProvider.ts`, `src/infrastructure/storage/StorageProvider.ts`, `src/infrastructure/local/LocalStore.ts`, `src/infrastructure/realtime/RealtimeProvider.ts`, `src/domain/shared/ClockProvider.ts`
  - Criterio de completitud: los seis contratos compilan sin ninguna importación de Supabase; `RealtimeProvider` queda **documentado y sin implementación** (ADR-005), con comentario que registra sus futuros consumidores (War Room, Post-Venta, Call Center)

- [ ] **T-07** — Contenedor de composición de dependencias
  - Archivos a crear/modificar: `src/app/container.ts`, `src/app/providers/ContainerProvider.tsx`, `src/app/container.test.ts`
  - Criterio de completitud: un único punto decide qué implementación satisface cada contrato; una prueba monta el contenedor completo con dobles y no toca la red

- [ ] **T-08** — Implementaciones de infraestructura transversal
  - Archivos a crear/modificar: `src/infrastructure/supabase/cliente.ts`, `src/infrastructure/supabase/errores.ts`, `src/infrastructure/auth/SupabaseAuthProvider.ts`, `src/infrastructure/storage/SupabaseStorageProvider.ts`, `src/infrastructure/local/IndexedDBLocalStore.ts`, `src/shared/observability/SentryMonitoringProvider.ts`, `src/domain/shared/RelojDelSistema.ts` + pruebas de cada uno
  - Criterio de completitud: `errores.ts` traduce todo fallo de Supabase a las categorías de T-05 antes de salir de infraestructura; `IndexedDBLocalStore` se prueba sin navegador con doble de IndexedDB; el cliente de Supabase se instancia **una sola vez** y solo aquí

- [ ] **T-09** — Reglas de linter arquitectónicas (los 5 guardarraíles automáticos de A1 §15)
  - Archivos a crear/modificar: `eslint.config.js`, `tools/eslint-rules/*.js` + pruebas de cada regla
  - Criterio de completitud: fallan la compilación (1) importar el SDK de Supabase o llamar `.from()`/`.rpc()` desde `ui/`, (2) importar el SDK fuera de `infrastructure/`, (3) importar `ui/` o `infrastructure/` de otro feature, (4) usar `matchMedia` o `navigator.standalone` fuera del `DeviceContextProvider`, (5) importar cualquier dependencia externa desde `domain/`. Cada regla tiene una prueba con un caso que debe fallar y uno que debe pasar

- [ ] **T-10** — Script de métricas arquitectónicas y línea base
  - Archivos a crear/modificar: `tools/metricas-arquitectura.mjs`, `docs/linea-base.md`
  - Criterio de completitud: el script cuenta queries en vistas, archivos que importan el SDK fuera de infraestructura y componentes de terreno duplicados, y falla si alguno es distinto de 0 en el repo nuevo. Deja registrada la línea base **medida** del sistema actual (a 2026-08-25: 840 llamadas `.from()/.rpc()`, 447 dentro de `.tsx`, 157 archivos con el SDK, `App.tsx` de 916 líneas)

- [ ] **T-11** — Integración continua
  - Archivos a crear/modificar: `.github/workflows/ci.yml`
  - Criterio de completitud: en cada PR corren `npx tsc -b`, `npm run lint` (incluye T-09), `npm test` y `npm run build`, más el script de T-10; un PR que viole un guardarraíl no puede mergearse

- [ ] **T-12** — PWA instalable con shell offline
  - Archivos a crear/modificar: `vite.config.ts` (vite-plugin-pwa), `public/` (manifiesto e iconos), `src/app/providers/ActualizacionProvider.tsx`
  - Criterio de completitud: la aplicación se instala en Android e iOS, su shell carga sin conexión (RNF-15) y avisa cuando hay versión nueva

- [ ] **T-13** — Extracción de reglas del sistema actual: Mi Día, visitas y lobbies
  - Archivos a crear/modificar: `docs/reglas/visitas.md` · fuentes `[repo actual] src/features/visitas/` (70 archivos, 14.245 líneas) y `src/App.tsx`
  - Criterio de completitud: catálogo con cada regla encontrada, su ubicación actual, si se conserva o se descarta y a qué capa va. Incluye obligatoriamente: una visita en curso por asesor, el aviso global ligado al **usuario real** y no al impersonado por "Ver como", el borrador en tres capas (servidor, local, marca de visita abierta) y el cronómetro

- [ ] **T-14** — Extracción de reglas: tareas, agenda, cumpleaños y bitácora
  - Archivos a crear/modificar: `docs/reglas/gestion.md` · fuentes `[repo actual] src/features/visitas/` y las migraciones de `plan_tareas`, `agenda_eventos`, `feriados`, `bitacoras`
  - Criterio de completitud: catálogo equivalente al de T-13, incluyendo el cálculo de días hábiles (`limite_habil`), la evaluación de cumplimiento diario de bitácora y las exenciones vigentes

- [ ] **T-15** — Extracción de reglas: gastos, boletas y rendiciones
  - Archivos a crear/modificar: `docs/reglas/gastos.md` · fuentes `[repo actual] src/features/gastos/` (26 archivos, 8.779 líneas) y las RPCs `gasto_*` y `rendicion_*`
  - Criterio de completitud: catálogo equivalente, con la máquina de estados de rendición completa (incluidos rechazo y reenvío) y las reglas de la cola de boletas actual (`useSincronizarBoletas`, `idbStore.ts`)

- [ ] **T-16** — Extracción de reglas: identidad, capacidades, "Ver como" y modo demo
  - Archivos a crear/modificar: `docs/reglas/identidad.md` · fuentes `[repo actual] src/App.tsx`, `src/features/auth/`, `src/types/index.ts`, `demoGuard.ts` y las migraciones de `rol_capacidades` y `usuario_roles`
  - Criterio de completitud: matriz de capacidades del AF verificada contra la base (`facturacion`, `salas`, `midia`, `cobertura`, `datos:operativo`); lista de todos los puntos donde el tier legacy decide algo, con la decisión de qué lo reemplaza; "Ver como" formulado como **regla de dominio**, no como guard de UI

- [ ] **T-17** — Línea base medida de las métricas de producto
  - Archivos a crear/modificar: `docs/linea-base.md`
  - Criterio de completitud: tiempo de apertura de Mi Día en el sistema actual (con y sin señal, en dispositivo y red representativos) e incidencias por asesor y por semana del último mes. Sin esto, RNF-06 y la métrica de incidencias del PRD §12 no son verificables

- [ ] **T-18** — Migraciones aditivas en el repositorio actual: idempotencia y eventos de producto
  - Archivos a crear/modificar: `[repo actual] supabase/migrations/NNNN_*.sql` (número asignado por `npm run migracion`, **nunca a mano**)
  - Criterio de completitud: columna `idempotency_key text` nullable con índice único parcial en `visitas`, `lobbies`, `agenda_eventos`, `tarea_avances`, `bitacoras` y `gastos`; tabla nueva `eventos_producto` con RLS. **Todo aditivo y compatible hacia atrás** (RNF-19): el sistema actual sigue funcionando sin conocerlas, verificado ejecutándolo contra la base migrada

- [ ] **T-19** — Sistema de componentes base adaptativo
  - Archivos a crear/modificar: `src/shared/ui/*` (botón, campo, selector, lista, tarjeta, hoja inferior, modal, estado vacío, cargando, error), `src/shared/ui/tokens.css`
  - Criterio de completitud: cada componente funciona en pantalla ancha y estrecha sin bifurcación en el consumidor; objetivos táctiles ≥ 44 px y contraste AA verificados (RNF-16, RNF-17); ninguno consulta `matchMedia`

### Fase 1 — Núcleo verificable del asesor: identidad, shell, offline, Mi Día y visitas (P1)

- [ ] **T-20** — Dominio de identidad
  - Archivos a crear/modificar: `src/domain/identidad/*.ts` + pruebas
  - Criterio de completitud: `Usuario`, `Rol`, `Capacidad`; invariantes «las capacidades son la unión de las de todos sus roles» y «un usuario sin perfil no puede operar»; regla de identidad efectiva vs. real para "Ver como". Todas con prueba unitaria y **sin Supabase**

- [ ] **T-21** — Repositorios de identidad y capacidades
  - Archivos a crear/modificar: `src/features/identidad/ports/UsuarioRepository.ts`, `CapacidadRepository.ts`, `src/features/identidad/infrastructure/Supabase*.ts` + pruebas de mapeo
  - Criterio de completitud: leen `usuarios`, `usuario_roles`, `rol_capacidades`, `usuario_areas`, `asesores`, `areas` y las funciones `puede`, `app_rol`, `app_tiene_capacidad`, `mis_capacidades`; el dominio nunca ve una fila; errores del proveedor traducidos

- [ ] **T-22** — Casos de uso de sesión
  - Archivos a crear/modificar: `src/features/identidad/application/{IniciarSesion,CerrarSesion,ResolverSesionActual,ResolverCapacidades,MarcarBienvenidaVista}.ts` + pruebas con repositorios falsos
  - Criterio de completitud: cada uno devuelve resultado tipificado y no lanza excepciones de infraestructura; la resolución de capacidades ocurre **una sola vez** y se cachea; si la matriz no carga es un error de infraestructura, **nunca** un permiso adivinado (ADR-008)

- [ ] **T-23** — Interfaz de autenticación
  - Archivos a crear/modificar: `src/features/identidad/ui/{LoginPage,SinPerfilPage}.tsx` y sus hooks de UI
  - Criterio de completitud: correo/contraseña y Google funcionando; la sesión persiste entre aperturas y se renueva sola; el caso "cuenta sin perfil" se informa y ofrece cerrar sesión (RF-01)

- [ ] **T-24** — Autorización de rutas por capacidad
  - Archivos a crear/modificar: `src/app/routes/guards.tsx`, `src/features/identidad/ui/useCapacidades.ts` + pruebas
  - Criterio de completitud: la UI recibe una decisión ya tomada; ningún componente consulta permisos por su cuenta (RF-02); **cero** referencias al tier `CM/GTE/FARMER` en todo el repositorio, verificado en CI

- [ ] **T-25** — Proveedor único de contexto de dispositivo
  - Archivos a crear/modificar: `src/app/providers/DeviceContextProvider.tsx` + pruebas
  - Criterio de completitud: resuelve en un solo lugar tamaño de pantalla, instalación como PWA, cámara, geolocalización y estado de conexión, y **expone una decisión, no datos crudos**; la regla de linter (T-09.4) impide cualquier acceso directo desde componentes

- [ ] **T-26** — Layout adaptativo y app shell
  - Archivos a crear/modificar: `src/shared/layouts/{LayoutAdaptativo,NavegacionLateral,NavegacionInferior,AppShell}.tsx`
  - Criterio de completitud: pantalla ancha con navegación lateral y densidad alta; estrecha con navegación inferior, una tarea por pantalla y acciones al alcance del pulgar; **mismas rutas y mismo estado en ambos** (RF-22, RNF-16)

- [ ] **T-27** — Mapa de rutas con carga bajo demanda
  - Archivos a crear/modificar: `src/app/routes/*.tsx`
  - Criterio de completitud: cada pantalla tiene URL propia, navegable, compartible y con historial funcional (RF-23); cada ruta carga su código bajo demanda y la carga inicial no incluye módulos que el asesor no usa (RNF-20), verificado con el análisis del bundle en CI

- [ ] **T-28** — Bienvenida y perfil
  - Archivos a crear/modificar: `src/features/identidad/ui/BienvenidaPage.tsx` y el caso de uso `MarcarBienvenidaVista` (RPC `marcar_bienvenida_vista`)
  - Criterio de completitud: pantalla descartable por el usuario y persistente por perfil; muestra datos básicos del asesor y su asignación

- [ ] **T-29** — Dominio de operación encolada
  - Archivos a crear/modificar: `src/domain/shared/OperacionEncolada.ts` + pruebas
  - Criterio de completitud: estados `pendiente → sincronizando → completada | fallida`; identificador de idempotencia obligatorio; política de reintentos con espera creciente hasta un tope y luego acción manual, **única para toda la aplicación**; todo probado con `ClockProvider` simulado

- [ ] **T-30** — Cola offline sobre `LocalStore`
  - Archivos a crear/modificar: `src/shared/sync/ColaOffline.ts`, `src/infrastructure/local/IndexedDBLocalStore.ts` (extensión para blobs) + pruebas
  - Criterio de completitud: persiste operaciones **con sus imágenes**, conserva el orden, sobrevive al cierre de la aplicación y se prueba sin navegador

- [ ] **T-31** — Decorador offline genérico y casos de uso de sincronización
  - Archivos a crear/modificar: `src/shared/sync/conOffline.ts`, `src/shared/sync/application/{EncolarOperacion,DrenarCola,ReintentarOperacion,ObtenerEstadoDeSincronizacion}.ts` + pruebas
  - Criterio de completitud: el decorador implementa la misma interfaz del repositorio (ADR-009); **ningún caso de uso contiene `if (online)`**; un `NetworkError` en una operación encolable se traduce en encolamiento y no en error visible (A1 §10, regla 2); el drenaje **no vive en el árbol de componentes** ni depende de qué pantalla esté montada

- [ ] **T-32** — Estado de sincronización observable
  - Archivos a crear/modificar: `src/shared/sync/store.ts` (Zustand), `src/shared/ui/IndicadorSincronizacion.tsx`
  - Criterio de completitud: el asesor ve pendiente / en curso / fallida y puede reintentar manualmente desde cualquier pantalla (RF-21)

- [ ] **T-33** — Dominio de visita
  - Archivos a crear/modificar: `src/features/visitas/domain/*.ts` + pruebas
  - Criterio de completitud: `planificada → en_curso → cerrada | descartada`; **una visita en curso por asesor** como invariante del dominio (RF-06); una visita en curso exige sala, hora de inicio y ubicación; no se cierra sin registro de lo observado; un usuario impersonado no puede descartar. Cada regla de `docs/reglas/visitas.md` (T-13) tiene su prueba

- [ ] **T-34** — `VisitaRepository` por agregado
  - Archivos a crear/modificar: `src/features/visitas/ports/VisitaRepository.ts`, `src/features/visitas/infrastructure/SupabaseVisitaRepository.ts` + pruebas de mapeo
  - Criterio de completitud: una sola interfaz cubre `visitas`, `visitas_abiertas` y `visitas_en_curso` (ADR-003); la interfaz habla en lenguaje de negocio (`obtenerVisitaEnCursoDe(asesor)`); el dominio no sabe que hay tres tablas

- [ ] **T-35** — Casos de uso de visita
  - Archivos a crear/modificar: `src/features/visitas/application/{IniciarVisita,GuardarBorradorVisita,CerrarVisita,DescartarVisitaEnCurso,ObtenerVisitaEnCurso}.ts` + pruebas
  - Criterio de completitud: `DescartarVisitaEnCurso` verifica identidad efectiva vs. real y limpia las tres capas (servidor, borrador local, marca de visita abierta) en orden, devolviendo resultado tipificado; todas las pruebas corren sin Supabase

- [ ] **T-36** — Decorador offline de visitas
  - Archivos a crear/modificar: `src/features/visitas/infrastructure/VisitaRepositoryOffline.ts` + pruebas
  - Criterio de completitud: check-in, guardado de borrador y cierre se encolan sin señal con idempotencia; el borrador sobrevive al cierre de la app y a la falta de señal (RF-07); reintentar no duplica la visita (RNF-09)

- [ ] **T-37** — Interfaz de visita
  - Archivos a crear/modificar: `src/features/visitas/ui/{CheckInPage,VisitaEnCursoPage,CierreVisitaPage}.tsx` + hooks de UI
  - Criterio de completitud: check-in con sala, hora y ubicación; cronómetro de duración; captura de lo observado; cierre (RF-05, RF-08); toda acción produce retroalimentación visible en ≤ 200 ms aunque la operación siga en curso (RNF-07)

- [ ] **T-38** — Aviso global de visita en curso
  - Archivos a crear/modificar: `src/features/visitas/ui/AvisoVisitaEnCurso.tsx` y su estado transversal
  - Criterio de completitud: visible desde cualquier pantalla con las opciones continuar o descartar; **de solo lectura con "Ver como" activo**; la regla vive en el dominio y el aviso solo la refleja (RF-06)

- [ ] **T-39** — Evidencia de visita
  - Archivos a crear/modificar: `src/features/visitas/infrastructure/EvidenciaVisita.ts` (usa `StorageProvider`) y la UI de captura
  - Criterio de completitud: captura desde cámara, subida a Storage y **encolado sin señal igual que las boletas** (decisión tomada en este plan; ver §12); ninguna imagen se pierde en las pruebas de corte de red

- [ ] **T-40** — Lobbies y otros eventos
  - Archivos a crear/modificar: `src/features/visitas/domain/Lobby.ts`, `src/features/visitas/application/{RegistrarLobby,RegistrarOtroEvento}.ts`, `ui/` + pruebas
  - Criterio de completitud: comparten el ciclo de la visita **sin exigir sala**; tienen detalle e historial propios (RF-09)

- [ ] **T-41** — Casos de uso de Mi Día y snapshot
  - Archivos a crear/modificar: `src/features/visitas/application/{ObtenerMiDia,SincronizarMiDia}.ts`, `src/shared/sync/Snapshot.ts` + pruebas
  - Criterio de completitud: compone agenda del día, tareas pendientes, visitas planificadas y cumpleaños; el snapshot se persiste con su marca de tiempo y **caducidad explícita**; sin conexión devuelve el último snapshot indicando su antigüedad (RF-03, RF-04)

- [ ] **T-42** — Interfaz de Mi Día
  - Archivos a crear/modificar: `src/features/visitas/ui/MiDiaPage.tsx` + componentes
  - Criterio de completitud: una sola implementación para escritorio y móvil (la métrica del PRD §12: de 2 a 1); acceso directo a registrar cada cosa; interactivo en ≤ 2 s con conexión y ≤ 1 s desde snapshot (RNF-06), medido contra la línea base de T-17

- [ ] **T-43** — Catálogos de referencia en solo lectura
  - Archivos a crear/modificar: `src/features/referencia/{ports,infrastructure,application}/*` + pruebas
  - Criterio de completitud: lectura de `salas`, `sala_vendedores`, `vendedores`, `clientes`, `proyectos`, `feriados` y del historial de sala; **ninguna operación de escritura expuesta** (RF-24); la frontera con Fase 2 queda declarada en el propio contrato

### Fase 2 — Gestión del asesor: tareas, agenda, cumpleaños y bitácora (P2)

- [ ] **T-44** — Dominio de tarea
  - Archivos a crear/modificar: `src/features/tareas/domain/*.ts` + pruebas
  - Criterio de completitud: `abierta → en_progreso → completada | cancelada`; los avances son **inmutables** una vez registrados; solo una tarea completada admite calificación; se conserva el vínculo con la sala o el plan que la originó

- [ ] **T-45** — `TareaRepository`
  - Archivos a crear/modificar: `src/features/tareas/{ports,infrastructure}/*.ts` + pruebas de mapeo
  - Criterio de completitud: cubre `plan_tareas`, `tarea_avances`, `tarea_comentarios` y las RPCs `crear_tarea_sala`, `completar_tarea`, `set_tarea_completada`, `calificar_tarea`, `tarea_avance_crear`, todas detrás del contrato

- [ ] **T-46** — Casos de uso de tareas y su decorador offline
  - Archivos a crear/modificar: `src/features/tareas/application/{CrearTarea,RegistrarAvance,CompletarTarea,CalificarTarea,ListarMisTareas}.ts`, `src/features/tareas/infrastructure/TareaRepositoryOffline.ts` + pruebas
  - Criterio de completitud: registrar un avance sin señal se encola y no se pierde (RNF-08); reintentar no duplica el avance

- [ ] **T-47** — Interfaz de tareas
  - Archivos a crear/modificar: `src/features/tareas/ui/*.tsx`
  - Criterio de completitud: lista, detalle, avances comentados, calificación y cierre, adaptativa en ambos contextos (RF-10)

- [ ] **T-48** — Dominio de agenda y días hábiles
  - Archivos a crear/modificar: `src/domain/agenda/*.ts` + pruebas con `ClockProvider` simulado
  - Criterio de completitud: `agendado → realizado | reagendado | cancelado`; un evento no se agenda en día inhábil salvo marca explícita; el cálculo de días hábiles y feriados se prueba **sin base de datos** contra los casos de `docs/reglas/gestion.md` (RF-12)

- [ ] **T-49** — `AgendaRepository` y casos de uso
  - Archivos a crear/modificar: `src/features/agenda/{ports,infrastructure,application}/*.ts` + pruebas
  - Criterio de completitud: cubre `agenda_eventos`, `feriados` y la función `limite_habil`; casos de uso `AgendarEvento`, `MarcarEventoRealizado`, `ReagendarEvento`, `CancelarEvento`, `ObtenerAgendaDelDia`

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
  - Criterio de completitud: en verde (1) inicio de sesión y resolución de capacidades, (2) visita completa check-in → captura → evidencia → cierre, (3) intento de segunda visita y descarte de la primera, (4) boleta sin señal con sincronización posterior sin duplicado, (5) bitácora con dictado y mejora (RNF-05)

- [ ] **T-66** — Pruebas de corte de red
  - Archivos a crear/modificar: `e2e/offline/*.spec.ts`, `docs/pruebas-offline.md`
  - Criterio de completitud: **0 operaciones perdidas y 0 duplicados** cortando la red en cada punto del ciclo de check-in, cierre de visita, avance de tarea, bitácora y boleta (RNF-08, RNF-09); incluye el escenario de tres horas sin señal

- [ ] **T-67** — Auditoría de políticas RLS de las 26 tablas
  - Archivos a crear/modificar: `docs/auditoria-rls.md`, `[repo actual] supabase/migrations/NNNN_*.sql` si hay correcciones
  - Criterio de completitud: tabla por tabla, qué puede leer y escribir el asesor y con qué política lo garantiza; se porta y extiende la prueba `rlsLaxa.test.ts` del sistema actual; el modo demo queda **respaldado por RLS** y no solo por el guard del cliente; documento **firmado por TI** (A1 §15.11)

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

Todos los cambios son **aditivos y compatibles hacia atrás** (RNF-19): el sistema actual sigue en producción para los demás roles y no debe enterarse. Se crean en el **repositorio actual** con `npm run migracion -- <descripción>` — el número **nunca se elige a mano** (hay 15 duplicados históricos entre 364 migraciones; el test `migracionesUnicas.test.ts` es la red).

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `visitas` | Modificación | Columna `idempotency_key text` nullable + índice único parcial. Garantiza **en la base** que un reintento de check-in o cierre no cree un duplicado (RNF-09) |
| `lobbies` | Modificación | Ídem |
| `agenda_eventos` | Modificación | Ídem |
| `tarea_avances` | Modificación | Ídem |
| `bitacoras` | Modificación | Ídem, además de la unicidad por asesor y día si no existe ya |
| `gastos` | Modificación | Ídem — es el caso de mayor exposición: la boleta se encola con imagen y se reintenta |
| `eventos_producto` | **Nueva** | Eventos de BI del PRD §11: fecha y hora, asesor, identificadores de negocio, resultado y motivo. RLS: el asesor inserta solo los suyos; lectura para los roles de análisis |
| *(las 26 tablas de Fase 1)* | Revisión de políticas | La auditoría de RLS (T-67) puede producir **correcciones** de políticas. Toda corrección es una migración propia y se valida contra el sistema actual antes de aplicarse |

> ⚠️ **No se rediseña el esquema.** Las 128 tablas, las 364 migraciones y las políticas existentes se conservan. Cualquier cambio que no sea aditivo queda **fuera de este plan** y exige volver al PRD.

---

## 6. Endpoints nuevos o modificados

**No se crean endpoints REST ni backend propio** (ADR-004). La aplicación consume directamente Supabase con RLS, más las Edge Functions ya existentes, que **se reutilizan tal como están** — no se reescriben en este proyecto.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `functions/v1/leer-boleta` | Extracción de datos de la imagen de una boleta (credenciales de IA en servidor) | Existente, sin cambios |
| POST | `functions/v1/transcribir-bitacora` | Dictado por voz de la bitácora | Existente, sin cambios |
| POST | `functions/v1/mejorar-bitacora` | Mejora de redacción de la bitácora | Existente, sin cambios |
| POST | `functions/v1/mejorar-redaccion` | Mejora de redacción de texto libre | Existente, sin cambios |
| POST | `functions/v1/notificar` | Notificaciones al asesor | Existente, sin cambios |
| — | `visitas-abiertas-cron` · `tareas-atrasadas-cron` | Procesos programados que alimentan las notificaciones | Existentes, sin cambios |

**Funciones de base de datos que la Fase 1 consume** (todas detrás de repositorios, ninguna invocada desde la UI): `puede`, `app_rol`, `app_tiene_capacidad`, `mis_capacidades` · `crear_tarea_sala`, `completar_tarea`, `set_tarea_completada`, `calificar_tarea`, `tarea_avance_crear` · `gasto_crear`, `gasto_fusionar`, `rendicion_enviar`, `rendicion_aprobar_jefe`, `rendicion_aprobar_ops`, `rendicion_rechazar`, `rendicion_reenviar`, `rendicion_marcar_pagada` · `vendedor_por_nombre`, `vendedor_inactivo_por_nombre`, `cumpleanos_vendedores` · `limite_habil` · `marcar_bienvenida_vista`, `marcar_induccion` · `organigrama`.

> **Tope de PostgREST:** 1000 filas por resultado. Todo listado del asesor debe paginar o acotar por rango de fechas dentro del repositorio; el dominio nunca asume que recibió todo.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `VITE_SUPABASE_URL` | URL del proyecto Supabase (`jrykbalmnpymeyzdhsam`) | Desarrollo / QA / Producción |
| `VITE_SUPABASE_ANON_KEY` | Clave anónima. **Pública por diseño**; su contención es RLS. Nunca la `service_role` en el cliente | Desarrollo / QA / Producción |
| `VITE_SENTRY_DSN` | Reporte de errores no controlados | QA / Producción (opcional en desarrollo) |
| `VITE_ENTORNO` | Identifica el ambiente en Sentry y en los eventos de producto | Desarrollo / QA / Producción |

Todas se leen y validan **exclusivamente** en `src/config/env.ts` (T-04); si falta una, la aplicación no arranca. Ninguna credencial de proveedor externo (IA, correo, mensajería) existe en el cliente: viven dentro de las Edge Functions (RNF-11).

---

## 8. Consideraciones de seguridad

- **La autorización es del servidor.** RLS es la única defensa real; los controles de la interfaz son de usabilidad y **nunca** la única barrera (RNF-10). Con acceso directo desde el cliente y clave anónima pública, una política mal escrita en cualquiera de las 26 tablas expone el dato a cualquiera. Por eso la auditoría de RLS (T-67) es criterio de aceptación, no una tarea opcional.
- **Lista cerrada de operaciones que obligatoriamente pasan por función de servidor** (ADR-004): (1) las que usan credenciales de un proveedor externo, (2) las que escriben algo que cruza la frontera del propio asesor —aprobaciones de rendición, notificaciones a terceros—, (3) las escrituras masivas o procesos programados, (4) aquellas cuya regla de autorización no puede expresarse íntegramente como política RLS. **Cualquier adición a esta lista requiere revisión de TI.**
- **Secrets fuera del código** (`rules/coding-guidelines.md` §11): solo variables de entorno; las claves de IA permanecen dentro de las Edge Functions.
- **"Ver como" (impersonación)** deja de ser un guard disperso por la UI y pasa a ser **regla de dominio** (T-20, T-35, T-38): un usuario impersonado no puede descartar el borrador del asesor. Ya hubo incidencias por esto en el sistema actual.
- **Modo demo** respaldado por RLS y no solo por el guard del cliente (T-67).
- **Inyección de prompt**: las funciones de IA reciben texto del usuario. Las pruebas del sistema actual se portan y se **extienden** a bitácora y lectura de boletas (T-53).
- **Datos personales**: nunca se registran contenido de bitácoras, imágenes de boletas, ubicaciones exactas ni datos de contacto — solo identificadores (T-64). Los mensajes de error jamás exponen nombres de tabla, SQL, rutas internas ni el mensaje original del proveedor (T-05).
- **Consultas parametrizadas**: no hay concatenación de SQL en el cliente; todo pasa por el SDK o por RPC.

---

## 9. Consideraciones de infraestructura

- **No se crean recursos AWS.** No hay ECS, ni Fargate, ni RDS, ni S3 en este proyecto: la persistencia es el proyecto Supabase existente y el hospedaje es Vercel.
- **Vercel**: proyecto nuevo para `garantimax-app`, framework Vite, SPA con reescrituras a `/index.html`, previews automáticas por PR. Costo marginal: un proyecto adicional dentro del plan vigente.
- **Dominios (Cloudflare)**: durante el desarrollo y el piloto, la aplicación nueva vive en un subdominio de transición (propuesto: `app.garantimax.com`). **El día del corte** se decide entre apuntar `www.garantimax.com` a la aplicación nueva —dejando el sistema actual en un subdominio para el doble acceso de los demás roles— o mantener el subdominio y redirigir solo a los asesores. Es una pregunta abierta del PRD §14 y debe cerrarse antes de T-69.
- **Convivencia**: ambas aplicaciones escriben la misma base de datos durante toda la transición. Las invariantes críticas se garantizan en la base (índices únicos de idempotencia, RPC), no solo en el código nuevo.
- **Desviación del estándar Engine** (`rules/infraestructura.md`): el árbol de decisión llevaría una SPA a S3 + CloudFront y un backend nuevo a ECS + Fargate. Aquí no hay backend nuevo y el hospedaje se conserva en Vercel por continuidad operativa, porque el PRD deja el cambio de proveedor fuera de alcance. **Requiere visto bueno de TI**; migrar el hospedaje sería un proyecto propio y de bajo costo de cambio (A1 §13 lo clasifica como riesgo de lock-in bajo).

---

## 10. Criterios de aceptación

**Arquitectónicos** — verificables automáticamente en CI:

- [ ] Cero archivos de presentación importan el SDK de Supabase o ejecutan `.from()` / `.rpc()` (RNF-01; línea base actual: 447 en `.tsx`)
- [ ] Cero archivos fuera de `infrastructure/` importan el SDK de Supabase (RNF-02; línea base actual: 157)
- [ ] El dominio compila sin ninguna dependencia externa
- [ ] Ningún feature importa la `ui/` ni la `infrastructure/` de otro feature
- [ ] Ningún componente accede a `matchMedia` ni a `navigator.standalone`
- [ ] Cero referencias al tier legacy `CM` / `GTE` / `FARMER` en todo el repositorio
- [ ] Las pruebas de dominio y de casos de uso corren **sin red ni instancia de Supabase** (RNF-03, meta 100 %)
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

- [ ] Auditoría de políticas RLS de las 26 tablas, **firmada por TI** (T-67)
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
| **RLS incompleta con clave anónima pública**: una política mal escrita expone el dato | Media | Alto | T-67 tabla por tabla, con firma de TI; se porta y extiende `rlsLaxa.test.ts`; el modo demo deja de depender del guard del cliente |
| **Duplicados al sincronizar** operaciones encoladas | Media | Alto | Idempotencia obligatoria en el dominio (T-29) **y garantizada en la base** con índice único (T-18); pruebas de corte de red (T-66) |
| **Sobreingeniería**: capas, contratos y providers que no resuelven un problema real | Media | Medio | Cada abstracción declara en su ADR qué problema concreto resuelve. `RealtimeProvider` se queda en contrato sin implementación (ADR-005). Zustand solo cuando el estado cruza ramas del árbol |
| **Convivencia sobre la misma base**: dos aplicaciones escribiendo las mismas tablas con invariantes distintas | Media | Alto | Las invariantes críticas se garantizan en la base, no solo en el código nuevo; todo cambio de esquema es aditivo (RNF-19); T-18 se valida ejecutando el sistema actual contra la base migrada |
| **La estimación se desborda**: la Fase 1 del PRD equivale a reconstruir 7 módulos y ~35 mil líneas del sistema actual | Alta | Alto | Fases con corte vertical y estimación por rango (§13). Si el calendario aprieta, el recorte es por fase completa (P2 o P3 siguen temporalmente en el sistema actual), **nunca** relajando los guardarraíles arquitectónicos: eso reproduce el problema que motiva el proyecto |
| **Deriva del alcance hacia Fase 2** (la frontera entre "leer salas" y "gestionar salas" es delgada) | Alta | Medio | `ReferenciaRepository` **no expone ninguna escritura** (T-43); cualquier capacidad de gestión es Fase 2 por definición |
| **Dependencia de una sola persona** que conoce el sistema actual | Media | Alto | Los catálogos de reglas (T-13…T-16) son documentación permanente y reducen la dependencia; se producen al inicio, no al final |
| **Las Edge Functions son lock-in real** y quedan fuera de toda abstracción | Baja *(en Fase 1)* | Alto *(a futuro)* | Fase 1 consume 6 de 46 y las reutiliza tal cual. Se deja señalado como el mayor costo de una salida futura de Supabase; su análisis es un proyecto propio |
| **Roles distintos del AF con capacidad `midia`** (10 roles) afectados por el corte sin haberlo planeado | Media | Medio | Verificar el uso real en producción antes de T-72 — pregunta abierta del PRD §14, se resuelve con una consulta de uso sobre la base |

---

## 12. Notas para el programador

**Decisiones tomadas durante la generación de este plan** (cierran preguntas abiertas del PRD §14):

1. **Repositorio propio nuevo** (`garantimax-app`). Consecuencias que el plan ya asume: CI, Vercel y variables de entorno se duplican; **las migraciones y las Edge Functions siguen viviendo en el repositorio actual** y desde ahí se operan (T-18, T-67). No dupliques `supabase/` en el repo nuevo: se convertiría en dos fuentes de verdad sobre la misma base.
2. **ADR-006 aprobado**: React Router, TanStack Query y Zustand entran como decisión cerrada (T-03). Regla que no se negocia: **la función que se le pasa a TanStack Query siempre invoca un caso de uso**, nunca un repositorio ni el SDK. Sin esa regla, Query se convierte en la nueva forma de meter queries en las vistas.
3. **La evidencia de visitas se encola sin señal**, igual que las boletas (T-39). El PRD lo dejaba abierto; encolarla es coherente con RNF-08 ("ninguna operación del asesor se pierde") y con la cola que T-30 ya construye para imágenes. Si la operación decide que la evidencia exige conexión, se simplifica T-39 — no al revés.
4. **Rama base `develop` del repositorio nuevo**, con la estructura Engine completa (`main`, `develop`, `pre-qa`, `qa`). El repositorio actual queda como está: normalizarlo obligaría a tocar un sistema en producción fuera de alcance.
5. **Una rama por fase**, todas desde `develop`, con el prefijo `feature/PJ4487-garantimax-refactor-`. Seis meses de trabajo en una sola rama funcional no es revisable.

**Preguntas abiertas del PRD §14 que siguen sin resolver y hay que cerrar antes de las tareas que dependen de ellas:**

| Pregunta | Bloquea |
|---|---|
| ¿Cuáles de los 10 roles con capacidad `midia` entran al corte? | T-72 (y define si la matriz de capacidades necesita ajuste) |
| ¿El corte es simultáneo o escalonado por país (Chile / Perú / Argentina)? | T-71, T-72 |
| ¿Qué pasa con `www.garantimax.com` el día del corte? | T-69 |
| ¿Cuánto tiempo debe poder operar el asesor sin señal? | T-41 — define tamaño y caducidad del snapshot; hasta entonces se implementa con un valor configurable |
| ¿Se elimina el tier `CM/GTE/FARMER` del sistema actual o solo se ignora? | Nada en este plan: el sistema nuevo simplemente no lo lee (ADR-008). La eliminación en el actual queda diferida |
| ¿Qué hace el asesor si necesita corregir un dato de un vendedor durante una visita? | T-43 — hoy el plan asume que lo reporta y se corrige en el sistema actual (Fase 2) |
| ¿Quién ejecuta y firma la auditoría de RLS? | T-67 |

**Detalles operativos que evitan errores conocidos:**

- **Validación antes de pedir review:** `npx tsc -b` y `npm run build`. **No** `tsc --noEmit` — con `tsconfig` tipo "solution" no chequea nada. Tests con `npm test`, lint con `npm run lint`.
- **Migraciones:** siempre `npm run migracion -- <descripción>` **en el repositorio actual**. El número lo asigna el script mirando también `origin/master`; elegirlo a ojo ya produjo 15 duplicados entre 364 migraciones.
- **MCP de Supabase:** las lecturas se ejecutan libremente; **cualquier escritura** (INSERT/UPDATE/DELETE/DDL/migración) requiere OK explícito, mostrando antes qué hace, el SQL exacto y cuántas filas toca.
- **Versión:** no se edita a mano; la inyecta el build. Si el repositorio nuevo replica ese mecanismo, replica también la regla.
- **Tope de PostgREST:** 1000 filas por resultado. Todo listado del asesor pagina o acota por fecha.
- **Idioma:** `rules/coding-guidelines.md` exige código en inglés. El sistema actual y todo el dominio de este PRD están en español (`visitas`, `rendiciones`, `bitacoras`), y las tablas y RPCs también. **Recomendación:** conservar el español en los nombres del dominio —renombrarlos rompería la correspondencia con la base y con el lenguaje del negocio— y usar inglés para lo técnico transversal. Es una desviación consciente que conviene ratificar con TI antes de T-02, porque después es cara de revertir.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles**, para **un desarrollador a tiempo completo**. Los rangos salen de la complejidad de las tareas de cada fase, no de un objetivo de calendario.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Fundaciones, guardarraíles y extracción de reglas** | Repositorio con ramas Engine, andamiaje, librerías del ADR-006, configuración tipada, jerarquía de errores, contratos y providers, contenedor, 5 reglas de linter, métricas y CI, PWA, sistema de componentes, **catálogos de reglas del sistema actual**, línea base medida y migraciones aditivas | T-01 a T-19 | 30 – 40 días | 193 |
| **Fase 1 — Núcleo verificable del asesor (P1)** | Identidad, sesión y capacidades sin tier legacy · shell adaptativo, rutas y bienvenida · motor offline completo (cola, idempotencia, decorador, estado observable) · Mi Día con snapshot · visitas con check-in, borrador, evidencia, aviso global y cierre · lobbies · catálogos de referencia en lectura | T-20 a T-43 | 40 – 52 días | 194 |
| **Fase 2 — Gestión del asesor (P2)** | Tareas y avances · agenda y días hábiles · cumpleaños y saludos · bitácora diaria con dictado y mejora de redacción | T-44 a T-54 | 20 – 26 días | 195 |
| **Fase 3 — Gastos y rendiciones (P3)** | Dominio de gasto y rendición · repositorios y RPCs · captura de boleta con lectura automática · decorador offline con imágenes · categorización y asignación · rendiciones y observación del flujo de aprobación | T-55 a T-61 | 20 – 27 días | 196 |
| **Fase 4 — Notificaciones, verificación, auditoría y corte** | Notificaciones · eventos de BI · observabilidad y auditoría · E2E de los 5 flujos críticos · pruebas de corte de red · auditoría de RLS de las 26 tablas · lista de paridad · despliegue · reversión ensayada · piloto · corte único | T-62 a T-72 | 32 – 42 días | 197 |
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
