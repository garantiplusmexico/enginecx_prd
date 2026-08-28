# Registro de Avance — Reconstrucción de GarantiMAX · Fase 1: núcleo del Asesor Farmer

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `garantiplusmexico/siga_alfa` (frontend) · `garantiplusmexico/gp_3.0_siga_api` → `Services/GarantiMax/` (backend, ADR-011) |
| Rama | `feature/PJ4487-garantimax-refactor-nucleo-asesor` |
| Responsable actual | Javier Antonio Oropeza Camacho |
| Folio PRD | PJ4487 |
| ID plan (BD) | `56` (`pm_plan_desarrollo.id`) |
| Modelo / esfuerzo | `claude-sonnet-5` — esfuerzo alto |
| Última actualización | 2026-08-28 |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

Repositorio `siga_alfa` inicializado: ramas `main` (pendiente, ver nota), `develop`, `pre-qa`, `qa` creadas, y rama funcional `feature/PJ4487-garantimax-refactor-nucleo-asesor` abierta desde `develop`. T-01 a T-07 completadas: andamiaje base (Vite + React 19 + TypeScript + Tailwind v4), árbol completo de `src/` según A1 §3, librerías de ADR-006, configuración tipada y validada, jerarquía de errores, los seis contratos transversales y el contenedor de composición. **97 pruebas en verde**, `npx tsc -b` y `npm run build` limpios. Plan `56` marcado `En curso` en BD, Fase 0 (`id 193`) marcada `En progreso`.

**T-13 a T-16 y T-18 completadas:** las cinco especificaciones están en `docs/reglas/` (1.293 líneas). Son el insumo del backend y el camino crítico ya está despejado.

**El backend arrancó y va por T-S04.** `Services/GarantiMax/` existe en el monorepo de la API, con base propia `garantimax_db`: **24 tablas creadas y verificadas**, 22 restricciones `CHECK`, catálogos sembrados y el usuario de prueba ligado a su asesor. Ocho documentos en `Services/GarantiMax/doc/`.

**Se volvió al frontend, para cerrar el vertical de identidad.** Su mitad de backend está lista (T-S06), y seguir apilando endpoints acumulaba superficie que solo el autor ha visto funcionar — el repo de la API no tiene proyectos de test. El cliente HTTP ya está; falta `ApiAuthProvider`, el repositorio y los casos de uso de identidad (T-20 a T-22) y la pantalla de login (T-23, T-24). Al terminar eso: **abrir la aplicación, entrar con `SigaWeb` y ver el perfil llegando del servicio** — la primera cosa demostrable del proyecto.

**Pendiente del backend, para el vertical de visitas:** el borrador de visita en curso, los lobbies y `ApiStorageProvider` (que necesita un endpoint de archivos que aún no existe).

**Pendiente del frontend, sin dependencias:** T-12 (PWA), T-19 (componentes) y la mitad de T-08 que no necesita endpoints (`IndexedDBLocalStore`, `SentryMonitoringProvider`). T-17 (línea base sobre el sistema actual) sigue esperando acceso a producción, y **conviene no dejarla para el final: después del corte no hay con qué comparar**.

> ### 🔎 Dos catálogos que faltaban en todos los documentos
>
> La extracción de reglas destapó dos datos sin los cuales la Fase 1 no funciona, y que no estaban en ninguna lista de siembra ni de riesgos:
>
> 1. **Feriados.** `limite_habil` (límite de aceptación de tareas) y el conteo de días de bitácora los necesitan; sin ellos, un feriado cuenta como día hábil y el asesor recibe avisos por días que no trabajó.
> 2. **Organigrama.** La aprobación de rendiciones depende de quién es jefe de quién (`esJefeDelDueno`, `duenoSinJefe`). **Sin jerarquía poblada, ninguna rendición se puede aprobar.** Es el más serio de los dos: no se puede improvisar, porque define quién aprueba el dinero de quién.
>
> Ambos quedaron agregados a la lista de siembra de T-18 §8.

> ⚠️ **Corregido durante T-04:** el andamiaje de T-02 dejó TypeScript **sin `strict`**. Se agregó `strict` y `noUncheckedIndexedAccess` a `tsconfig.app.json` y `tsconfig.node.json`. Con el proyecto casi vacío costó cero; en seis meses no habría costado cero. Es un proyecto cuyo objetivo declarado es un dominio riguroso y probable, y sin `strict` esa promesa no se puede sostener.

> ### 🔄 **Cambio de rumbo del 2026-08-26: se abandona Supabase**
>
> Decisión del responsable, registrada en **ADR-011**. El backend pasa a un **servicio .NET propio** (`Services/GarantiMax/` en `gp_3.0_siga_api`) con base de datos PostgreSQL propia, **sin migración de datos** — borrón y cuenta nueva. La autenticación ya está resuelta en `Services/Authentication` y los permisos se resuelven con los **roles del JWT**, no con la matriz `roles × capacidades`. La primera entrega opera **solo Chile**, con el país modelado como dato. El login de Google queda fuera de alcance.
>
> **Lo que NO cambia:** la arquitectura. Dependencias hacia adentro, features con capas internas, repositorios por agregado, offline como decorador, layout adaptativo, corte único. El dominio, los casos de uso y los puertos no se tocan — el cambio se paga solo en `infrastructure/`. Es la propiedad que ADR-002 compró y que ahora se cobró.
>
> **Trabajo ya hecho que hubo que corregir:** `src/infrastructure/supabase/` renombrada a `src/infrastructure/api/`, `.env.example` reescrito (fuera `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY`, entra `VITE_API_BASE_URL`), comentario del `QueryProvider` ajustado, y `CLAUDE.md` reescrito en las secciones §1, §2, §3, §5, §6 y §9. `npx tsc -b` y `npm run build` en verde tras el cambio.
>
> **Documentos actualizados el 2026-08-26:** `PRD.md` (v0.2) · `PLAN.md` · `A1-arquitectura.md` · `A2-adrs.md` (v0.2, ADR-011 nuevo; ADR-002, ADR-004 y ADR-008 superados; ADR-005 modificado) · `A3-inventario.md` (v0.2, con §3.1 nueva y tres correcciones factuales).

> ⚠️ **Nota sobre `main`:** el repositorio tiene una regla de organización (`validate-main-source-branch`) que **bloquea cualquier push directo a `main`**, incluido el primer commit — solo acepta merges vía PR desde `release`. `main` **no existe todavía como rama** en el remoto (0 refs). Es consistente con `rules/version-control.md` ("main solo se actualiza desde release, nunca commits directos"), pero es más estricto que en otros repos Engine, donde el primer commit sí se sembró directo en `main` antes de aplicar la regla. `main` se creará más adelante, cuando exista una rama `release` y se abra el primer PR `release → main` (ver Fase 4, T-72). El workflow `validate-prod-source.yml` equivalente (visto en `gp_4.0_siga`/`gp_3.0_siga_api`) deberá añadirse al repo antes de ese primer PR — pendiente, no bloquea la Fase 0.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Fundaciones, guardarraíles y extracción de reglas** | 193 | T-01 a T-19 | 30 – 40 | 2026-08-25 | | 0 | 30 – 40 | 🟡 En progreso |
| **Fase 1 — Núcleo verificable del asesor (P1)** | 194 | T-20 a T-43 | 40 – 52 | | | 0 | 40 – 52 | ⏳ Pendiente |
| **Fase 2 — Gestión del asesor (P2)** | 195 | T-44 a T-54 | 20 – 26 | | | 0 | 20 – 26 | ⏳ Pendiente |
| **Fase 3 — Gastos y rendiciones (P3)** | 196 | T-55 a T-61 | 20 – 27 | | | 0 | 20 – 27 | ⏳ Pendiente |
| **Fase 4 — Notificaciones, verificación, auditoría y corte** | 197 | T-62 a T-72 | 32 – 42 | | | 0 | 32 – 42 | ⏳ Pendiente |
| **Total proyecto (P1+P2+P3+cierre)** | — | 72 tareas | ~142 – 187 | 2026-08-25 | | 0 | ~142 – 187 | 🟡 En progreso |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-43 | ~70 – 92 | 2026-08-25 | | 0 | ~70 – 92 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Crear el repositorio `siga_alfa` con la estructura de ramas Engine | Claude Code | 2026-08-25 | `develop`, `pre-qa`, `qa` creadas y en remoto. `main` pendiente — ver nota en "Resumen de estado". CODEOWNERS: `* @Javier-Oropeza`. Protección de `main` con 2 aprobaciones y bloqueo de commits directos a `develop` quedan a cargo del programador en la UI de GitHub |
| T-02 | Andamiaje base de la aplicación y estructura de carpetas de A1 §3 | Claude Code | 2026-08-25 | Árbol completo de `src/` (49 carpetas con `index.ts` marcador) + `package.json`, `vite.config.ts`, `tsconfig*`, `CLAUDE.md`. `npx tsc -b` y `npm run build` en verde; verificado además con dev server sirviendo HTTP 200. Sin script `lint` todavía (llega con `eslint.config.js` en T-09) |
| T-S05 | Autorización base y su documentación | Claude Code | 2026-08-27 | `IAdvisorContext` resuelve el asesor **del token y solo del token**. La pieza clave es que `GarantiMaxControllerBase` **no devuelve** el asesor: recibe un delegado al que se lo pasa, así que no hay camino de código que llegue al cuerpo de un endpoint sin un asesor resuelto. Un helper que hay que acordarse de llamar se rompe la primera tarde ocupada. `NotOwned()` responde **404 y no 403** cuando el recurso es de otro asesor: un 403 confirma que existe, y con eso cualquiera enumera las visitas de sus compañeros sin ver un dato. Cuatro estados de fallo distinguidos, no un 403 genérico. `doc/quien-puede-ver-que.md` con ejemplos que pasan y que no |
| T-S06 | Endpoints de identidad y perfil | Claude Code | 2026-08-28 | `GET /api/profile` + los dos POST idempotentes de bienvenida e inducción. **Destapó un hueco de mi propia especificación:** `identidad.md` I-39/I-40 exigen persistir esas dos marcas y `esquema-fase1.md` §3.1 no las listó, así que no llegaron al modelo. Corregidas las tres capas. Los roles **no** van en la respuesta: viajan en el token, y exponerlos otra vez sería una segunda fuente para el mismo hecho. **Verificado por el responsable con cuatro pruebas** — perfil, sin token 401, sin perfil 403, rol cambiado 403 |
| T-S07 | Endpoints de terreno — **parcial** | Claude Code | 2026-08-28 | `ReferenceController` (salas, vendedores, categorías, feriados) y `VisitsController` (guardar idempotente, historial, detalle). **No hay endpoint para "abrir" una visita**: mientras está abierta vive como borrador y llega completa al cerrarla, que es lo que permite trabajarla sin señal. El reintento se responde **antes** de validar, para que una visita ya guardada no falle porque una regla cambió entremedio. El borrador se borra en la **misma transacción** que crea la visita — en el sistema actual iba aparte y el aviso resucitaba sobre una visita ya guardada. Pendiente: borrador de visita en curso y lobbies, que van con el vertical de visitas |
| — | **OData aplicado a los listados**, por indicación del responsable | Claude Code | 2026-08-28 | Yo había dejado OData fuera argumentando que «permite al llamador ensanchar la consulta». **Era incorrecto:** el controlador construye la consulta **ya acotada**, la devuelve sin materializar, y `[AutoODataFilter]` aplica los parámetros **encima** — el llamador acota dentro de sus datos y no puede salirse. La preocupación que sí sobrevivía —listados sin límite— la resuelve el atributo mejor que mi rango obligatorio: sin `$top` aplica un tamaño de página, y el tope se controla en un solo lugar. Trampa documentada en los dos controladores: **materializar con un `ToList` desactiva OData en silencio** |
| T-S01 | Esqueleto del servicio .NET y su rama | Claude Code | 2026-08-27 | `Services/GarantiMax/` en `gp_3.0_siga_api`, rama `feature/PJ4487-garantimax-nucleo-asesor` desde `develop`, registrado en la solución bajo `Services`. Modelado sobre `Catalogs` con **tres ausencias deliberadas y comentadas**: sin `DataAccess`, sin `ConfigurePais()`, sin OData. Y una presencia deliberada: `FallbackPolicy` exige usuario autenticado en todo endpoint que no declare su política — un endpoint que nadie clasificó se **rechaza**, que es la traducción de `identidad.md` I-34 y la mitigación del riesgo de autorización del PRD §12. Dos endpoints de salud: `live` anónimo (lo llama el orquestador), `ready` con token porque informa base y país. Puerto 5006. Rol `IsFarmerAdvisor = "Asesor Farmer"` agregado a `Common/Policies/Policies.cs` |
| T-S02 | `DbContext` propio y base de datos | Claude Code | 2026-08-27 | `GarantiMaxDbContext` contra `garantimax_db`, base separada del core de SIGA. La creó el responsable (`garantiplus_udb` no tiene `CREATEDB` y solo `postgres` puede — se dejó recomendado **no** concederlo: ese usuario corre en producción). **Corrección de la justificación:** la primera versión del documento decía que `DataAccess` está congelado citando su README; el responsable advirtió que sí está vigente, y el historial lo confirma (entidades nuevas en julio de 2026, 143 modelos). Las razones reales son más fuertes: cada entidad nueva se duplica en dos contextos espejo (el commit de la última dice literal "(MEX/COL)"), y **todos los países comparten el contexto de México salvo Colombia**, con las diferencias como condicionales adentro |
| T-S03 | Modelo de datos de Fase 1 y migración inicial | Claude Code | 2026-08-27 | **24 entidades, 24 configuraciones, 13 enums**, dos migraciones aplicadas. Clases en inglés, tablas en español (decisión del responsable), con glosario de 16 términos en `doc/nomenclatura.md` — marcando `sala → Showroom` como el de más riesgo, porque `PointOfSale` significa otra cosa en `Services/Catalogs`. Verificado contra la base: 22 `CHECK` derivados de los `[DbValue]` de los enums, 34 índices únicos, los 3 parciales, y la PK de `visitas_en_curso` es `asesor_id` — esa línea **es** la invariante "una visita en curso por asesor". Se unificaron `visitas_en_curso` y `visitas_abiertas`, que compartían clave y ciclo de vida. `Task` se llama `PlanTask`: colisionaría con `System.Threading.Tasks.Task` en todo archivo que haga `await`. **Dos errores propios corregidos:** `Ignore(x => x.StateOn)` sobre un método (EF nunca mapea métodos), y `UserId` tipado `Guid` cuando `AspNetUsers.Id` es `text` — los 5.977 valores tienen forma de GUID, que era justo la trampa |
| T-S04 | Siembra de datos de prueba | Claude Code | 2026-08-27 | `Data/Seed/siembra-desarrollo.sql`, idempotente con UUID **fijos** (mismo dato, mismo id en toda máquina). Verificado corriéndolo tres veces: mismos números. 2 clientes, 4 salas, 3 asesores, 5 vendedores, 9 categorías, 1 proyecto y **27 feriados** de Chile. El usuario de prueba `SigaWeb` (`10af9d4a-…`) quedó como "Asesor de Prueba" con Sala Norte y Sala Centro, jefe asignado y obligación de bitácora **desde hoy**. Organigrama con un asesor **con** jefe y uno **sin**, para ejercitar la ruta normal y el atajo E-32. Los ficticios llevan `usuario_id` en `NULL` — se hizo nullable para eso, porque un id inventado es un id que alguien toma por real. Los cumpleaños se calculan sobre `CURRENT_DATE`, así el aviso aparece se corra cuando se corra |
| T-09 | Reglas de linter arquitectónicas (los 5 guardarrailes de A1 §15) | Claude Code | 2026-08-26 | ESLint 10 + typescript-eslint. **Seis** reglas: las cinco de A1 §15 más "`import.meta.env` solo en `src/config/`", que salió de T-04. Sin plugin propio: `no-restricted-globals` / `-imports` / `-properties` / `-syntax` alcanzan. 24 pruebas ejecutan ESLint de verdad sobre código en memoria, cada regla con **un caso que debe fallar y uno que debe pasar** — el segundo importa igual: una regla que rechaza todo se apaga en días. Hallazgo al escribirla: en la config plana de ESLint un bloque posterior **reemplaza** las opciones de una regla, no las suma, así que los bloques van de general a específico y cada uno repite lo que hereda |
| T-10 | Script de métricas arquitectónicas y línea base | Claude Code | 2026-08-26 | `tools/metricas-arquitectura.mjs` + `docs/linea-base.md`. Cuatro métricas, todas en cero, cada una impresa **junto a la cifra del sistema actual** para que el cero signifique algo ("eliminamos 447", no "no encontramos nada"). Verificado que falla: se introdujo una vista con `fetch` a propósito y salió con código 1 señalando el archivo. Las exenciones se declaran **en el script con su motivo**, nunca con un `eslint-disable` en el archivo infractor |
| T-11 | Integración continua | Claude Code | 2026-08-26 | `.github/workflows/ci.yml`: tipos → guardarrailes → pruebas → métricas → build, en PR hacia `develop`/`pre-qa`/`qa`/`release`/`main` y en push a `develop`. `concurrency` con `cancel-in-progress`. El build recibe variables de relleno porque T-04 no lo deja arrancar sin configuración válida. Los cinco pasos reproducidos localmente en verde |
| T-08 | Implementaciones de infraestructura transversal — **parcial** | Claude Code | 2026-08-26 | `RelojDelSistema` + `RelojFijo` (13 pruebas). **Se movió de `domain/shared/` a `infrastructure/`**: el PLAN la ubicaba junto al contrato, pero el guardarraíl 5 prohíbe leer el reloj dentro de `domain/` — y con razón, es la dependencia que `ClockProvider` existe para sacar de ahí. Dejarla en `domain/` habría obligado a exceptuar el archivo de su propia regla. `hoy()` resuelve el día en la zona del asesor con `Intl`, y hay una prueba que documenta el bug que evita: a las 22:30 en Santiago, `toISOString().slice(0,10)` devuelve el día siguiente y la bitácora se guardaría con la fecha de mañana. Pendiente de T-08: `IndexedDBLocalStore`, `SentryMonitoringProvider` (sin backend) y `ApiAuthProvider`/`ApiStorageProvider` (con backend) |
| T-13 | Extracción de reglas: Mi Día, visitas y lobbies | Claude Code | 2026-08-26 | `docs/reglas/visitas.md` — 52 reglas catalogadas con ubicación, decisión y capa destino. Documenta el borrador en tres capas (localStorage sincrónico / IndexedDB con blobs / servidor) explicando **qué modo de fallo cubre cada una**, la regla del usuario real vs. impersonado con la consecuencia que evita, y el tope de 12 reintentos que reporta el payload a monitoreo antes de descartar. 5 reglas descartadas con motivo. Deja 5 preguntas abiertas |
| T-14 | Extracción de reglas: tareas, agenda, cumpleaños y bitácora | Claude Code | 2026-08-26 | `docs/reglas/gestion.md` — 44 reglas. Incluye `limite_habil` completa (día hábil siguiente, zona `America/Santiago`, salta feriados), la máquina de negociación de tareas que vive **entera en triggers de PL/pgSQL**, y las seis exenciones de bitácora con su historia: cada una se agregó tras un aviso indebido, y la causa raíz es que la obligación cuelga del tier legacy. **Hallazgo: los feriados hay que sembrarlos** o el cálculo los trata como hábiles |
| T-15 | Extracción de reglas: gastos, boletas y rendiciones | Claude Code | 2026-08-26 | `docs/reglas/gastos.md` — 56 reglas. Máquina de estados de rendición completa y exhaustiva, con el atajo condicional `enviada → aprobada_ops` cuando el dueño no tiene jefe. Documenta el +10 % de conversión a favor del empleado, el umbral de confianza 0,8, y la regla de las **dos geolocalizaciones** (a la IA solo la del EXIF: la del navegador dejó una boleta argentina en pesos chilenos). **Hallazgo: el organigrama hay que poblarlo** o ninguna rendición se puede aprobar |
| T-16 | Extracción de reglas: identidad, permisos, "Ver como" y modo demo | Claude Code | 2026-08-26 | `docs/reglas/identidad.md` — 42 decisiones de acceso, **no** una matriz de capacidades (ADR-011). Mapa completo de reemplazo del tier legacy punto por punto. Formula «Ver como» como una sola regla de dominio en vez de cuatro guards dispersos. Rescata el **defecto cerrado** del `demoGuard` (una escritura nueva sin clasificar se bloquea sola) como mitigación del riesgo de autorización del PRD §12, y marca el fallback de permisos actual como el peor patrón encontrado: convierte un fallo de red en una concesión de permisos |
| T-18 | Especificación del esquema y del contrato de idempotencia | Claude Code | 2026-08-26 | `docs/reglas/esquema-fase1.md` — modelo tabla por tabla con invariantes y dueños. **Decisión de diseño: la clave primaria ES la clave de idempotencia.** El sistema viejo necesitaba dos columnas (`id` + `cliente_uuid`) porque no podía cambiar la PK de tablas con datos; con base vacía se colapsan en una `uuid` generada en el cliente, y el reintento lo resuelve la PK sin índice parcial ni captura de `23505`. Propone unificar `visitas_en_curso` y `visitas_abiertas`, y lista los 8 catálogos a sembrar — dos de los cuales (feriados y organigrama) no estaban identificados en ningún documento |
| T-08 | Implementaciones de infraestructura transversal — **cliente HTTP** | Claude Code | 2026-08-28 | `infrastructure/api/client.ts` + `errors.ts`. Único lugar que habla con la red, único que adjunta el token, y traduce todo fallo a la jerarquía de T-05 antes de devolverlo. **Tres cosas que NO hace, a propósito:** no reintenta (eso es de la cola offline, que sabe si la operación es encolable y cuántos intentos lleva — hay prueba de que `fetch` se llama una vez), no consulta `navigator.onLine` (es del `DeviceContextProvider`), no cachea. Tope de 20 s porque en terreno una petición colgada es indistinguible de no tener señal. Distingue los **dos 403** del backend: sin cuerpo es rol equivocado y cae al mensaje neutro; con mensaje es asesor sin dar de alta y ese gana. Traduce los parámetros de OData, así el dominio no aprende `$filter`. **26 pruebas**, incluida la que verifica que un `Npgsql: relation "gastos"...` no llega a la pantalla pero sí al log |
| T-04 | Configuración tipada y validada al arranque | Claude Code | 2026-08-26 | `src/config/env.ts` con `readConfig` **puro** (recibe la fuente como parámetro, se prueba sin Vite) y `src/config/index.ts` como único punto que lee `import.meta.env`. Acumula **todos** los problemas antes de fallar, en lugar de morir en el primero. Valida: URL absoluta http/https sin barra final y https obligatorio en producción; ambiente entre los tres válidos; DSN de Sentry obligatorio fuera de desarrollo. 22 pruebas. Se creó `.env.local` (ignorado por git) para que `npm run dev` arranque |
| T-05 | Jerarquía de errores tipificados y su traducción a mensajes | Claude Code | 2026-08-26 | Las 7 categorías de A1 §10 sobre una raíz `AppError` con **dos textos de público distinto**: `message` técnico para el log y `mensajeUsuario` para la pantalla. Añadido `esReintentable`, que la cola offline consulta para no reintentar lo que nunca va a pasar. `comoAppError` es la red de seguridad: lo que no fue traducido se envuelve en `InfrastructureError` en vez de llegar crudo a la UI. 66 pruebas, incluida una batería que verifica contra un mensaje sucio a propósito (tabla, SQL, ruta, correo, línea) que ningún `mensajeUsuario` filtra nada |
| T-06 | Contratos transversales (ports), sin implementación | Claude Code | 2026-08-26 | Los seis de A1 §8, **solo tipos**: ni una línea ejecutable, verificado por prueba. `AuthProvider` con `SessionState` como unión cerrada —«sin sesión» y «expirada» llevan a pantallas distintas y con `null` esa diferencia se pierde— y `currentSession()` que **no va a la red**, porque el asesor abre la app sin señal. `StorageProvider` devuelve URL temporal, no permanente. `LocalStore` garantiza orden de inserción: la cola se drena en el orden en que el asesor hizo las cosas. `MonitoringProvider` no acepta texto libre en el contexto, para que la regla de logging seguro la imponga el compilador. `ClockProvider` incluye `hoy()` porque «qué día es hoy» tiene consecuencia de negocio y con UTC se adelanta el día |
| T-07 | Contenedor de composición de dependencias | Claude Code | 2026-08-26 | `crearContainer` + `ContainerProvider`/`useContainer`. Sin librería de inyección: un objeto de seis campos. `realtime` es `RealtimeProvider | null` **no opcional**, para que el compilador obligue a decidir qué hacer cuando falta. Resultado congelado y copiado. 9 pruebas montan el contenedor completo con dobles sin tocar la red. El cableado de producción queda para T-08, cuando existan las implementaciones |
| T-03 | Instalar y configurar React Router, TanStack Query y Zustand (ADR-006) | Claude Code | 2026-08-25 | Dos rutas de prueba con `createBrowserRouter` (temporales, se reemplazan a partir de T-20/T-27); `QueryProvider` con `staleTime` 30s y reintentos documentados; store de Zustand vacío en `shared/sync/store.ts` con su regla de uso también en `CLAUDE.md`. `tsc -b`/`build` en verde y ambas rutas responden HTTP 200 en dev; navegación client-side en navegador real **no verificada** (sin uno disponible en este entorno) |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| | | | | |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-08 | Implementaciones de infraestructura transversal — resto | **Parcial ya hecho** (`RelojDelSistema`). Sin backend: `IndexedDBLocalStore`, `SentryMonitoringProvider`. Con backend: `ApiAuthProvider`, `ApiStorageProvider` |
| T-12 | PWA instalable con shell offline | Nada |
| T-17 | Línea base medida de las métricas de producto | Acceso al sistema actual **en producción** — hay que medir antes del corte o se pierde la comparación |
| T-19 | Sistema de componentes base adaptativo | Nada |
| T-S05 | Autorización base y su documentación | Nada — el rol `"Asesor Farmer"` ya existe en `AspNetRoles` y el usuario de prueba lo tiene |
| T-S06 a T-S09 | Endpoints de identidad, terreno, gestión y gastos | T-S05. **Alcance reducido en T-S09:** solo los endpoints del asesor (enviar, reenviar); aprobar, pagar y rechazar quedan en la fase del CM |
| T-20 en adelante | Fase 1 del frontend | Los endpoints de su vertical |

> **Nota sobre la tabla anterior.** Hasta el 26-08-2026 esta sección listaba T-09 a T-19 con bloqueos que ya no existen: dos filas decían "MCP de Supabase pendiente de autorización". Ese bloqueo desapareció con ADR-011 — el sistema actual está clonado en `../garantimax` y se lee del disco, sin MCP. Las filas obsoletas se eliminaron en lugar de dejarlas tachadas: una tabla de pendientes que miente es peor que no tenerla.

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| | | | |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Repositorio nuevo = `garantiplusmexico/siga_alfa` (no `garantimax-app` como nombraba el plan generado) | Repo ya creado por el responsable con ese nombre, vacío, remoto `origin` configurado | Se actualizó `PLAN.md` (6 referencias) para reflejar el nombre real |
| Plan pasado a estado `Validado` en el encabezado del `PLAN.md` | El responsable confirmó haberlo revisado y lo autorizó a arrancar | Ninguno funcional — es el semáforo de que el plan ya no es borrador |
| ~~Idioma: español en el dominio, inglés en lo técnico transversal~~ | Ratificada el 2026-08-25 | **REEMPLAZADA el 2026-08-28** — ver la fila de abajo |
| Modelo de ejecución: `claude-sonnet-5`, esfuerzo alto, para toda la Fase 0 (a reevaluar al entrar a Fase 1) | Decisión del responsable frente a la recomendación mixta (Opus solo para T-13…T-16/T-05/T-06/T-07/T-09); prioriza simplicidad de trazabilidad sobre el ahorro de costo de una mezcla de modelos | Todos los commits de la Fase 0 registran `claude-sonnet-5 — esfuerzo alto` |
| **Se abandona Supabase: el backend pasa a un servicio .NET propio** (ADR-011) | El estándar corporativo es la API .NET 8 que ya existe, con autenticación y roles resueltos. Mantener Supabase significaba sostener un segundo backend, una segunda autenticación y un segundo modelo de permisos para un solo actor. ADR-002 ya dejaba esta decisión enunciada como pendiente | Alto en documentación, **bajo en código**: solo `infrastructure/`. Se rehacen las 7 Edge Functions como endpoints (mayor aumento de alcance), desaparecen la matriz de capacidades y el riesgo de la clave anónima pública, y aparece la necesidad de **poblar los catálogos** de referencia |
| **Todo el código en inglés, en los dos repositorios** | La regla del 25-08 producía **tres nombres para el mismo concepto** —`Visita` en el frontend, `Visit` en el servicio, `visitas` en la tabla— y una traducción en cada frontera. Con todo en inglés son dos, y la segunda la hace el ORM. Desaparece además la desviación de `rules/coding-guidelines.md` | Renombradas las 7 carpetas de feature (con `git mv`, historial conservado) y los identificadores transversales del frontend. Español queda solo en tablas/columnas, mensajes al usuario y comentarios. Glosario compartido en `[repo api] doc/nomenclatura.md`. Se hizo con cero consumidores del cliente HTTP; más tarde habría costado veinte repositorios |
| **El mismo responsable construye frontend y servicio .NET** | Decisión del responsable el 26-08-2026. Evita el riesgo de calendario de esperar a otro equipo y garantiza que el contrato de los endpoints coincida con lo que el frontend necesita | El plan gana el bloque **T-S01 a T-S09** (Fase 0-B). A partir de la Fase 1 se trabaja por vertical: endpoints y luego frontend de cada feature |
| **Fase 0 reordenada: reglas y esquema primero** | Con Supabase las reglas ya estaban implementadas en la base y T-13…T-16 podían ir al final. Ahora son el insumo sin el cual el servicio no puede empezar: el camino crítico pasó a ser la especificación | Orden acordado documentado en `PLAN.md`, antes de la lista de la Fase 0. La numeración de las tareas **no** cambia |
| **La cadena de aprobación de rendiciones se queda en su fase** | ADR-011 cortó el flujo: A3 §3 decía que la aprobación "sigue operándose en el sistema actual", y eso solo era cierto compartiendo base. Con bases separadas, una rendición creada en el sistema nuevo es invisible para el actual. El responsable decidió **no adelantar** la bandeja de aprobación a Fase 1 | T-S09 construye solo los endpoints del asesor (enviar, reenviar). Las transiciones de prueba se hacen directo en la base con `doc/como-probar-sin-vistas.md`. **Queda abierto** qué pasa entre el corte y la fase del CM: ninguna rendición podrá aprobarse. Salidas posibles en `gastos.md` §6 |
| **Asignar y calificar tareas se queda en Fase 3** | Son del mandante, no del asesor | Durante la transición el asesor solo verá las tareas que él mismo cree. Si su carga diaria llega por tareas del jefe, hay que medir el impacto antes del corte |
| **`usuario_id` de `asesores` es nullable** | Un jefe del organigrama puede no usar GarantiMAX: existe como nodo para enrutar aprobaciones y como actor de auditoría, pero no inicia sesión | Índice único parcial. Alternativa descartada: inventarles un `usuario_id` falso, que es un id que alguien va a tomar por real |
| **Clases en inglés, tablas en español** | El repo de la API exige código en inglés; la base es el lenguaje compartido con el negocio, ratificado en español | Mapeo explícito con EF, un lugar por entidad. Glosario de 16 términos en `doc/nomenclatura.md` para no traducir la misma palabra de dos formas |
| **Catálogos: datos sembrados para construir y probar** | El responsable cargará los reales cuando tenga el conocimiento de la base vieja; esperar bloquearía el módulo de visitas sin necesidad | Deja de ser riesgo bloqueante. T-S04 entrega la siembra. Sigue abierto cómo se **actualizan** en producción — es Fase 2 |
| Base de datos propia del servicio, con **columna de país**, en lugar de una BD por país | `DataAccess` del repo hermano está congelado desde enero de 2025 y el patrón de contextos espejo (MEX/COL) obligaría a triplicar ~30 tablas para Hub Sur | Un solo `DbContext` en `Services/GarantiMax/`; el país es dato, no infraestructura |
| Primera entrega **solo Chile** | El sistema viejo ya tenía Chile implícito (moneda `CLP` por defecto, RUT en gastos y vendedores). Perú y Argentina exigirían moneda, identificador fiscal y feriados por país | El país se modela desde el día uno, pero no se opera; queda fuera de alcance en el PRD §6 |
| Autorización por **roles del JWT**, no por matriz `roles × capacidades` | El token de la API ya trae los roles como claims. Duplicar un modelo de permisos que la API resuelve no compra nada | ADR-008 queda superado; T-16, T-20, T-21, T-22 y T-24 reformuladas. El identificador de rol es nuevo y el frontend se ajusta |
| `main` no se siembra en T-01; queda para el primer PR `release → main` en Fase 4 | Regla de organización `validate-main-source-branch` rechaza cualquier push directo a `main`, incluido el primero — no hay forma de rodearla sin tocar el ruleset de GitHub, que es del responsable/TI | El criterio de completitud de T-01 ("existen main, develop, pre-qa, qa") se interpreta como: las 3 ramas de trabajo existen; `main` existe como convención/regla de la organización aunque su primer commit real llegue en el corte |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `README.md` (siga_alfa) | Creado | T-01 |
| `.gitignore` (siga_alfa) | Creado | T-01 |
| `.github/CODEOWNERS` (siga_alfa) | Creado | T-01 |
| `enginecx_prd/GarantiMAX/PJ4487-garantimax-refactor/PLAN.md` | Modificado (nombre de repo, estado, ratificación de idioma) | T-01 (previo a la ejecución) |
| `enginecx_prd/GarantiMAX/PJ4487-garantimax-refactor/AVANCE.md` | Creado | T-01 |
| `src/` (siga_alfa) — 49 carpetas con `index.ts`/`index.tsx` marcador, según A1 §3 | Creado | T-02 |
| `package.json`, `package-lock.json`, `vite.config.ts`, `tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json`, `index.html` (siga_alfa) | Creado | T-02 |
| `src/main.tsx`, `src/app/App.tsx`, `src/app/container.ts`, `src/index.css`, `src/vite-env.d.ts` (siga_alfa) | Creado | T-02 |
| `CLAUDE.md`, `.env.example` (siga_alfa) | Creado | T-02 |
| `src/app/providers/QueryProvider.tsx`, `src/shared/sync/store.ts` (siga_alfa) | Creado | T-03 |
| `src/app/App.tsx`, `src/app/providers/index.ts`, `src/app/routes/index.tsx`, `src/shared/sync/index.ts`, `package.json`, `CLAUDE.md` (siga_alfa) | Modificado | T-03 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `e4ec22e` (siga_alfa) | Andamiaje inicial del repositorio (T-01) | 2026-08-25 |
| `ad4ce83` (siga_alfa) | Andamiaje base de la aplicación y estructura de A1 §3 (T-02) | 2026-08-25 |
| `247908b` (siga_alfa) | Instalar y configurar React Router, TanStack Query y Zustand (T-03, ADR-006) | 2026-08-25 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** T-04, configuración tipada y validada al arranque (`src/config/env.ts`). Rama activa: `feature/PJ4487-garantimax-refactor-nucleo-asesor`, ya en el remoto.
- **Contexto importante:**
  - **No hay Supabase** (ADR-011). Aquí no se escribe SQL ni se define modelo de datos: el backend es `Services/GarantiMax/` en `../gp_3.0_siga_api`. El cliente de red vive solo en `src/infrastructure/api/`.
  - `main` de `siga_alfa` no existe aún — no intentar sembrarlo directo, ver nota en "Resumen de estado".
  - La variable que T-04 tiene que validar es `VITE_API_BASE_URL` (local: puerto 5006 por convención del repo de la API), no credenciales de Supabase.
  - **El repositorio del sistema actual es solo lectura.** Es la mejor especificación disponible de las reglas de negocio: sus 364 migraciones, sus ~25 funciones y sus ~150 políticas RLS. Antes de leerlo, ver **A3 §3.1** — el histórico tiene trampas (tablas recreadas a media historia, `salas` abandonada, 15 números duplicados).
  - Está clonado en `../garantimax` (remoto `garantiplus-dashboard`), así que no hace falta MCP para leerlo.
- **Decisiones pendientes que requieren input del responsable** (ninguna bloquea la Fase 0, pero todas bloquean el corte):
  1. **Nombre exacto del rol** del Asesor Farmer en la API — lo necesita el frontend para resolver permisos (T-22, T-24).
  2. **Cómo se pueblan los catálogos** de referencia en la base nueva. Bloquea el módulo de visitas: una visita es siempre a una sala.
  3. **Quién construye `Services/GarantiMax/` y con qué calendario.** El frontend avanza contra dobles de prueba, pero sin endpoints no hay corte.
  4. **Cómo se programan los procesos periódicos** sobre ECS + Fargate (sustituyen a los dos cron de Supabase).
  5. **Quién revisa y firma** las reglas de autorización de los endpoints (T-67, sustituye a la auditoría de RLS).
  6. **Cómo se mantienen actualizados los catálogos** de referencia en producción (su gestión es Fase 2).

- **Entorno verificado el 2026-08-26** para trabajar en el repo de la API: .NET SDK 8.0.418 · PostgreSQL 16.3 en `localhost:5432` · `GPProjectBasePath` y `GPProjectsPath` resueltas por variables de entorno. No falta nada para arrancar.

---

*Actualizado automáticamente por Claude Code — Engine CX*
