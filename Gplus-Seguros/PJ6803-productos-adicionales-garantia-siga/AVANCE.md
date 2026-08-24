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
| Estado general | 🟡 En progreso — ejecución iniciada, sin tareas ejecutadas |

---

## Resumen de estado

Ejecución abierta el 2026-08-24. Hasta ahora solo se hizo la preparación: el plan quedó marcado como `En curso` en la BD (plan 48) y las ramas `feature/productos-adicionales-garantia-siga` están creadas y publicadas en los dos repos, con la versión del frontend subida a 1.1.30.

**Ninguna tarea del plan (T-01 a T-24) se ha ejecutado.** Todas las fases siguen en `Pendiente`.

La Fase 0 no puede cerrarse sin dos entregables externos de Garantiplus (credenciales QA/PROD con `projectId` y perfil de permisos; e ids de canal `dealerId` / `salesChannelId` / `pointOfSaleId` / `advisorId` / `productTypeId`) más dos definiciones de negocio (duración default de la garantía y cantidad de llantas default). Sin eso, T-01 no se puede verificar contra `qa-siga-api.garantiplus.com`.

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
| **Fase 0 — Habilitadores y cliente de SIGA (P1)** | 150 | T-01 a T-03 | 3 – 5 | | | 0 | 5 | ⏳ Pendiente |
| **Fase 1 — Cotización de garantía · backend (P1)** | 151 | T-04 a T-10 | 6 – 9 | | | 0 | 9 | ⏳ Pendiente |
| **Fase 2 — Cotización de garantía · frontend (P2)** | 152 | T-11 a T-13 | 3 – 4 | | | 0 | 4 | ⏳ Pendiente |
| **Fase 3 — Emisión del contrato · backend (P2)** | 153 | T-14 a T-19 | 6 – 9 | | | 0 | 9 | ⏳ Pendiente |
| **Fase 4 — Emisión · frontend (P3)** | 154 | T-20 a T-21 | 2 – 3 | | | 0 | 3 | ⏳ Pendiente |
| **Fase 5 — Pruebas, observabilidad y despliegue (P3)** | 155 | T-22 a T-24 | 3 – 4 | | | 0 | 4 | ⏳ Pendiente |
| **Total proyecto (P1+P2+P3)** | — | 24 tareas | ~23 – 34 | | | 0 | 34 | ⏳ Pendiente |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-10 | ~9 – 14 | | | 0 | 14 | ⏳ Pendiente |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| — | *(ninguna todavía)* | | | |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| — | *(ninguna todavía)* | | | |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-01 | Cerrar prerequisitos con Garantiplus y negocio | Garantiplus (credenciales, `projectId`, ids de canal) y negocio (duración y cantidad de llantas default) |
| T-02 | Crear la librería `Common/SigaApiClient` | Construible contra la doc; no verificable sin T-01 |
| T-03 | Resolución y caché de catálogos SIGA | T-01 (requiere llamadas reales a catálogos) |
| T-04 | Cambios de esquema en PostgreSQL para la cotización | — |
| T-05 | Modelo y `DbContext` de `cotizacion_garantia` en el cotizador | T-04 |
| T-06 | Nuevo worker `CotizadorGarantiaSIGA` | T-02, T-03 |
| T-07 | Publicar la cotización de garantía desde `CreateCotizacionV2` | T-06 |
| T-08 | Persistir la respuesta en `ResponseListenerWorker` | T-05, T-06 |
| T-09 | Endpoint de consulta de la cotización de garantía | T-05 |
| T-10 | Infraestructura del nuevo microservicio | T-06 |
| T-11 | Polling de la cotización de garantía | T-09 |
| T-12 | Tarjeta de garantía con costo y check | T-11 |
| T-13 | Arrastrar la decisión a la emisión | T-12 |
| T-14 | Cambios de esquema para el contrato | — |
| T-15 | Modelo, `DbContext` y DTO de emisión | T-14 |
| T-16 | Servicio de creación de contrato | T-02, T-15 |
| T-17 | Enganche en `PolizasController.Emitir` | T-16 |
| T-18 | Descarga del certificado y reintento manual | T-16 |
| T-19 | Wire-up y configuración de emisiones | T-16 |
| T-20 | Check de garantía en la pantalla de emisión | T-13, T-17 |
| T-21 | Certificado en la vista de póliza | T-18 |
| T-22 | Pruebas end-to-end en QA | Fases 1 a 4 |
| T-23 | Eventos de BI y logging | Fases 1 y 3 |
| T-24 | Despliegue a QA y validación | T-22 |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | *(ninguna en ejecución todavía; la dependencia externa de T-01 está anotada en la tabla de pendientes)* | | |

---

## Decisiones tomadas durante la ejecución

Registro de decisiones técnicas que no estaban en el plan original y que se tomaron durante la ejecución. Esto es crítico para que otro compañero entienda el contexto sin preguntar.

| Decisión | Justificación | Impacto |
|---|---|---|
| — | *(ninguna todavía)* | |

---

## Archivos creados o modificados

Lista de archivos tocados durante la ejecución. Se actualiza automáticamente.

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| — | *(ninguno todavía)* | |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| — | *(ninguno de tareas del plan todavía)* | |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** por T-01. Es una dependencia externa, no de desarrollo. Mientras no lleguen las credenciales y los ids de canal de Garantiplus, lo único avanzable sin bloqueo es T-02 (`Common/SigaApiClient`) contra el contrato documentado en `gp_seguros/AI/docs/api-siga-integracion-contratos.md`, más los cambios de esquema T-04 y T-14.
- **Contexto importante:**
  - Son **dos repos, una feature**: `gp_seguros` (backend .NET 8) y `frontend-omega` (Vue 2.6). Las dos ramas avanzan juntas a `pre-qa` → `qa`; el frontend sin el backend no sirve y viceversa.
  - El repo es **DB-first sin migraciones**: los cambios de esquema se aplican con SQL en la BD y se reflejan a mano en el modelo y el `DbContext`.
  - `frontend-omega` requiere **Node 16.15.1** (`nvm use`) y `npm run build <env>` con argumento obligatorio. No hay suite de tests automatizados en ninguno de los dos repos.
  - **No refactorizar** `CotizacionesController.cs` ni `PolizasController.cs` (~4,700 líneas): es deuda conocida y fuera del PRD.
- **Decisiones pendientes que requieren input del equipo:** ¿un solo `dealerId` para todo Omega, o uno por agencia/empresa? El plan asume uno solo por configuración; si negocio quiere trazabilidad por agencia hace falta una tabla de mapeo `empresa` → `dealerId` y la Fase 0 sube ~2 días.

---

*Actualizado automáticamente por Claude Code — Engine CX*
