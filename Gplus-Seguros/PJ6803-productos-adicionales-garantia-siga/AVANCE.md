# Registro de Avance — Productos Adicionales: Garantía SIGA en Omega

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/productos-adicionales-garantia-siga` (en `gp_seguros` y en `frontend-omega`) |
| Responsable actual | Alexis Salvador Herrera Garcia |
| Folio PRD | PJ6803 |
| ID plan (BD) | 48 |
| Última actualización | 2026-08-24 |
| Estado general | 🟡 En progreso |

---

## Resumen de estado

Se construyó un **corte vertical funcional** de la cotización de garantía: de la pantalla de cotización al endpoint propio, de ahí al login de SIGA y a `GetAvailableProducts`, y de regreso el nombre del producto y su precio en pantalla. Está commiteado y publicado en las ramas de los dos repos.

**La ejecución no siguió el orden de fases del plan.** Se priorizó validar el pipeline de punta a punta, y para lograrlo se implementó la consulta a SIGA de forma **síncrona dentro de un controller**, no con el worker NATS, la tabla propia y el endpoint de polling que define la §3 del `PLAN.md`. Ver "Decisiones tomadas durante la ejecución" — es la desviación más importante del proyecto y sigue abierta.

Lo verificado hoy contra `qa-siga-api.garantiplus.com`: el **Login responde 200** y **`GetAvailableProducts` devuelve producto y precio** con los parámetros configurados (`ProductTypeId=2`, `DealerId=1531`, `BrandId=24`, `Duration=12`, `TireCount=4`, `VehicleYear=2026`). Eso cierra la mayor parte del bloqueante de T-01: credenciales, perfil, distribuidor y marca funcionan.

**Falta para poder probar el flujo completo en QA:** compilar y desplegar `gp_seguros_clientes:v2.2`. La imagen desplegada seguía en v2.1, sin el campo nuevo, y por eso el check de empresa no guardaba y la garantía nunca se consultaba.

---

## Relación de tareas y tiempos (seguimiento)

Copia de la tabla **§13 del `PLAN.md`**, que Claude Code actualiza conforme ejecuta cada fase: registra fechas reales de inicio y fin, días ejecutados, días restantes y el estatus de cada fase.

- **Días est. (rango):** el rango estimado que venía del plan (no cambia).
- **Fecha inicio / Fecha fin:** fechas reales (días hábiles) en que arrancó y cerró la fase.
- **Días ejecutados:** días hábiles ya invertidos en la fase.
- **Días restantes:** días hábiles estimados que faltan para cerrarla (0 cuando está ✅).
- **Estatus:** ⏳ Pendiente · 🟡 En progreso · ✅ Completada · ⏸️ Pausada · 🔴 Bloqueada · ✖️ Cancelada. (En la BD, con la primera letra en mayúscula: `Pendiente` / `En progreso` / `Completado` / `Pausado` / `Bloqueado` / `Cancelado`. Ver `workflows/db-sync.md`.)
- **ID (BD):** `pm_plan_fase.id`. El flujo lo copia del `PLAN.md` y, cada vez que cambia el estatus de una fase aquí, refleja el cambio en la base de datos en automático. Ver `workflows/db-sync.md`.

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Habilitadores y cliente de SIGA (P1)** | 150 | T-01 a T-03 | 3 – 5 | 2026-08-24 | | 1 | 3 | 🟡 En progreso |
| **Fase 1 — Cotización de garantía · backend (P1)** | 151 | T-04 a T-10 | 6 – 9 | 2026-08-24 | | 1 | 8 | 🟡 En progreso |
| **Fase 2 — Cotización de garantía · frontend (P2)** | 152 | T-11 a T-13 | 3 – 4 | 2026-08-24 | | 1 | 3 | 🟡 En progreso |
| **Fase 3 — Emisión del contrato · backend (P2)** | 153 | T-14 a T-19 | 6 – 9 | | | 0 | 9 | ⏳ Pendiente |
| **Fase 4 — Emisión · frontend (P3)** | 154 | T-20 a T-21 | 2 – 3 | | | 0 | 3 | ⏳ Pendiente |
| **Fase 5 — Pruebas, observabilidad y despliegue (P3)** | 155 | T-22 a T-24 | 3 – 4 | | | 0 | 4 | ⏳ Pendiente |
| **Total proyecto (P1+P2+P3)** | — | 24 tareas | ~23 – 34 | 2026-08-24 | | 1 | 30 | 🟡 En progreso |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-10 | ~9 – 14 | 2026-08-24 | | 1 | 11 | 🟡 En progreso |

> Las tres fases en progreso avanzaron en paralelo, no en secuencia: el corte vertical tocó habilitadores, backend y frontend a la vez. Los días ejecutados se cuentan una sola vez en el total.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| — | Campo `permite_generar_contratos_garantias` a nivel empresa | Claude Code | 2026-08-24 | **Fuera del plan original.** Bandera que habilita la generación de contratos por empresa. Backend (`clientes`: modelo + controller), frontend (`Empresa.vue`: check) y DDL. Por defecto `false` para empresas nuevas y existentes |
| — | DDL aplicado en la base de pruebas | Alexis Herrera | 2026-08-24 | `ALTER TABLE empresa ADD COLUMN permite_generar_contratos_garantias` — script en `Actualizaciones seguros/20 Integracion siga/Actualización de campos.sql` |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| T-01 | Cerrar prerequisitos con Garantiplus y negocio | Alexis Herrera | 2026-08-24 | **Validado contra QA:** login 200, `GetAvailableProducts` 200 con producto y precio, usando `ProductTypeId=2`, `DealerId=1531`, `BrandId=24`, `Duration=12`, `TireCount=4`. Falta: credenciales de producción, y que negocio confirme duración y cantidad de llantas default (hoy 12 meses / 4 llantas por configuración) |
| T-02 | Cliente de la API de SIGA | Claude Code | 2026-08-24 | **Hecho de otra forma:** no se creó la librería `Common/SigaApiClient`; el login y la consulta viven dentro de `ControllerSiga`. Sin caché de token: se pide en cada consulta, por indicación del responsable |
| T-09 | Endpoint de consulta de la cotización de garantía | Claude Code | 2026-08-24 | `POST siga/productos-disponibles` en `cotizador_omega`, expuesto en KrakenD como `/api/v1/siga/productos-disponibles`. Valida empresa habilitada y unidad nueva antes de llamar a SIGA. **No lee de tabla: consulta a SIGA en vivo** |
| T-11 | Consulta de la garantía desde el frontend | Claude Code | 2026-08-24 | `_consultarGarantiaSiga` se dispara en `inicializarComponentes` junto con el polling de aseguradoras. **No es polling**, es una sola llamada |
| T-12 | Presentación del producto en pantalla | Claude Code | 2026-08-24 | Bloque arriba del carrusel con nombre y precio, más estados de carga y error. **Falta el check para incluir la garantía** |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-03 | Resolución y caché de catálogos SIGA | Hoy `BrandId` es fijo por configuración; falta el mapeo real marca/modelo |
| T-04 | Cambios de esquema en PostgreSQL para la cotización | — |
| T-05 | Modelo y `DbContext` de `cotizacion_garantia` en el cotizador | T-04 |
| T-06 | Nuevo worker `CotizadorGarantiaSIGA` | Depende de resolver la desviación de arquitectura (ver decisiones) |
| T-07 | Publicar la cotización de garantía desde `CreateCotizacionV2` | T-06 |
| T-08 | Persistir la respuesta en `ResponseListenerWorker` | T-05, T-06 |
| T-10 | Infraestructura del nuevo microservicio | T-06 |
| T-13 | Arrastrar la decisión a la emisión | T-12 (falta el check) |
| T-14 | Cambios de esquema para el contrato | — |
| T-15 | Modelo, `DbContext` y DTO de emisión | T-14 |
| T-16 | Servicio de creación de contrato | T-15 |
| T-17 | Enganche en `PolizasController.Emitir` | T-16 |
| T-18 | Descarga del certificado y reintento manual | T-16 |
| T-19 | Wire-up y configuración de emisiones | T-16 |
| T-20 | Check de garantía en la pantalla de emisión | T-13, T-17 |
| T-21 | Certificado en la vista de póliza | T-18 |
| T-22 | Pruebas end-to-end en QA | Despliegue de `clientes` v2.2 |
| T-23 | Eventos de BI y logging | Fases 1 y 3 |
| T-24 | Despliegue a QA y validación | T-22 |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-22 | Pruebas end-to-end en QA | La imagen `gp_seguros_clientes` desplegada en QA sigue en v2.1, sin el campo nuevo. Hasta que se compile y despliegue la v2.2, el check de empresa no guarda y la garantía no se consulta | Alexis Herrera (build + deploy) |

---

## Decisiones tomadas durante la ejecución

Registro de decisiones técnicas que no estaban en el plan original y que se tomaron durante la ejecución. Esto es crítico para que otro compañero entienda el contexto sin preguntar.

| Decisión | Justificación | Impacto |
|---|---|---|
| **La cotización de garantía se resuelve síncrona dentro de `ControllerSiga`, no por NATS con worker y tabla propia** | Indicación directa del responsable, para validar el pipeline de punta a punta antes de montar la infraestructura | **Contradice la §3 del `PLAN.md` y la arquitectura del repo.** Un SIGA lento agrega su latencia al request; no queda registro de la cotización de garantía en BD. Aceptable para validar, hay que revisarlo antes de producción. Deja T-04 a T-08 y T-10 sin ejecutar |
| Bandera `permite_generar_contratos_garantias` a nivel empresa | Solicitud del responsable. Habilita la feature empresa por empresa | Alcance nuevo, fuera del PRD v0.2. Se relaciona con la pregunta abierta de §12 del plan (`dealerId` único vs. por empresa): apunta a control por empresa |
| Se agrega también la validación de **unidad nueva** (`id_tipo_unidad = 1`) | Alineación con el PRD, que limita el MVP a autos nuevos | Las dos validaciones corren antes del login, así no se gastan llamadas a SIGA |
| El token de SIGA se pide en **cada** consulta, sin caché | Indicación explícita del responsable | Una llamada extra de login por cotización. El plan contemplaba caché de token en `SigaApiClient` |
| `RegistrationDate` se envía con la **fecha del día** | El responsable dio el formato pero no el origen del dato; no encaja en configuración fija ni venía de la cotización | Validado contra QA: SIGA lo acepta. Si debe ser `fecha_registro` de la cotización, es un cambio de una línea |
| Credenciales de SIGA en `appsettings.json` | Indicación del responsable de poner ahí todo lo que no venga de la cotización | Contradice el `CLAUDE.md` del repo, que prohíbe agregar secretos nuevos a esos archivos. Mitigación: se pueden sobrescribir con `SigaApi__Username` / `SigaApi__Password`, porque `Program.cs` ya llama a `AddEnvironmentVariables()` |
| Versiones de imagen subidas en uno y propagadas a build, deploy, task definitions y compose | Necesario para desplegar los cambios | `gp_seguros_cotizador` v2.6→v2.7, `gp_seguros_api_gateway` v2.1→v2.2, `gp_seguros_clientes` v2.1→v2.2. Las task definitions estaban desfasadas (v1.9, v0.97, v1.0) y quedaron sincronizadas |

---

## Archivos creados o modificados

Lista de archivos tocados durante la ejecución. Se actualiza automáticamente.

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `gp_seguros/Services/cotizador/cotizador_omega/Controllers/ControllerSiga.cs` | Creado | T-02, T-09 |
| `gp_seguros/Services/cotizador/cotizador_omega/Models/DTO/sigaDTO.cs` | Creado | T-02 |
| `gp_seguros/Services/cotizador/cotizador_omega/Models/empresa.cs` | Modificado | Campo de empresa |
| `gp_seguros/Services/cotizador/cotizador_omega/appsettings.json` | Modificado | Sección `SigaApi` |
| `gp_seguros/Services/clientes/Models/empresa.cs` | Modificado | Campo de empresa |
| `gp_seguros/Services/clientes/Controllers/EmpresasController.cs` | Modificado | Campo de empresa |
| `gp_seguros/Services/apigateway/krakend.json` | Modificado | Ruta del endpoint nuevo |
| `gp_seguros/Services/{apigateway,clientes,cotizador/cotizador_omega}/build.ps1` | Modificado | Versión de imagen |
| `gp_seguros/Infrastructure/{qa,prod}/deploy-services-v2.ps1` | Modificado | Versión de imagen |
| `gp_seguros/Infrastructure/{qa,prod}/{ApiGateway,Quoter,Clients}-task-definition.json` | Modificado | Versión de imagen |
| `gp_seguros/Infrastructure/local/docker-compose.yml` | Modificado | Versión de imagen |
| `frontend-omega/src/views/configuracion/empresas/Empresa.vue` | Modificado | Check de empresa |
| `frontend-omega/src/views/ventas/cotizaciones/Cotizacion.vue` | Modificado | T-11, T-12 |
| `frontend-omega/.env`, `.env.local`, `.env.qa`, `.env.production` | Modificado | Versión 1.1.29 → 1.1.30 |
| `Actualizaciones seguros/20 Integracion siga/Actualización de campos.sql` | Creado | DDL manual (fuera de los repos) |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `855d411` | frontend-omega — Subir version del frontend a 1.1.30 | 2026-08-24 |
| `25103a96` | gp_seguros — Agregar campo permite_generar_contratos_garantias en empresa | 2026-08-24 |
| `72c5cfb` | frontend-omega — Agregar check "Permite generar contratos de garantias" en empresa | 2026-08-24 |
| `924d2a14` | gp_seguros — Cotizacion de garantia SIGA: ControllerSiga, gateway y version de build | 2026-08-24 |
| `b59ccbf` | frontend-omega — Mostrar la garantia SIGA en la cotizacion | 2026-08-24 |
| `5d2ca8ec` | gp_seguros — Validar auto nuevo en la garantia y subir version de clientes | 2026-08-24 |
| `cf0756e` | frontend-omega — Consultar la garantia solo en unidades nuevas | 2026-08-24 |
| `738f526` | enginecx_prd — Marcar el plan como En curso | 2026-08-24 |
| `2890128` | enginecx_prd — Crear AVANCE.md inicial | 2026-08-24 |

Todos publicados en sus ramas remotas.

---

## Notas para quien retome el trabajo

- **Por dónde continuar:**
  1. Compilar y publicar `gp_seguros_clientes:v2.2` (`Services/clientes/build.ps1`) y desplegar `clients` en QA. Sin eso nada del flujo se puede probar.
  2. Prender el check en la empresa. El `ALTER TABLE` dejó todas en `false`, así que hay que marcarlo aunque se hubiera intentado antes.
  3. Cotizar una unidad nueva (`id_tipo_unidad = 1`) con esa empresa y confirmar que aparecen nombre y precio.
  4. Decidir qué hacer con la desviación de arquitectura (ver decisiones). De eso depende si T-04 a T-08 y T-10 se ejecutan como los define el plan.
- **Cómo diagnosticar en QA:** el log del cotizador está en CloudWatch, grupo `/ecs/qa/gp-omega-quoter`. Filtrar por `productos-disponibles` dice si el frontend disparó el POST. Si sale cero, el problema está en la condición del frontend, no en SIGA.
- **La API de SIGA no vive en la cuenta de AWS de Omega** (`322202710699`). `qa-siga-api.garantiplus.com` resuelve a un ALB de otra cuenta. En la cuenta de Omega solo están los clusters `qa-apiomega` y `prod-apiomega`.
- **Contexto importante:**
  - Son **dos repos, una feature**: `gp_seguros` (backend .NET 8) y `frontend-omega` (Vue 2.6). Las dos ramas avanzan juntas a `pre-qa` → `qa`.
  - El repo es **DB-first sin migraciones**: los cambios de esquema se aplican a mano y se reflejan en el modelo y el `DbContext`. **Agregar una propiedad a un modelo sin aplicar el DDL tumba todos los endpoints que leen esa tabla** — pasó con `GetCabeceraV2`, que consulta `empresa`.
  - Al cambiar código de un servicio hay que **subir su versión de imagen y desplegarlo**. Se perdió tiempo por no hacerlo con `clientes`.
  - `frontend-omega` requiere **Node 16.15.1** (`nvm use`). No hay pruebas automatizadas en ninguno de los dos repos: la verificación es `dotnet build` + `eslint` + prueba manual.
  - **No refactorizar** `CotizacionesController.cs` ni `PolizasController.cs`.
- **Decisiones pendientes que requieren input del equipo:**
  - ¿Se mantiene la consulta síncrona o se migra al patrón NATS del plan antes de producción?
  - ¿Un solo `dealerId` para todo Omega, o uno por empresa? La bandera nueva sugiere control por empresa.
  - Duración default de la garantía y cantidad de llantas (hoy 12 meses / 4 por configuración).

---

*Actualizado automáticamente por Claude Code — Engine CX*
