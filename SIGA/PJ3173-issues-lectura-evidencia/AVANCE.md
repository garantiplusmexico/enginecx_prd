# Registro de Avance — Cierre de huecos del servicio de Issues (API SIGA)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ3173-issues-lectura-evidencia` |
| Responsable actual | Javier Antonio Oropeza Camacho |
| Folio PRD | PJ3173 |
| ID plan (BD) | 54 |
| Última actualización | 2026-08-21 |
| Estado general | 🟡 En progreso |
| Modelo | `claude-sonnet-5` — esfuerzo: alto |

---

## Resumen de estado

**Alcance acotado a P1 (Fase 0 + Fase 1, T-01 a T-14)** por decisión del responsable el 2026-08-21.
Las Fases 2, 3 y 4 quedan fuera de esta ejecución y se retomarán en un ciclo posterior.

La **Fase 0 está completa**: la rama funcional existe en `origin`, el rol del panel quedó confirmado como
Administrador General (cierra el riesgo bloqueante del PRD §14) y las tres decisiones de diseño abiertas
fueron ratificadas sin cambios. **No hay nada bloqueado.** Sigue la Fase 1 con T-04 (script SQL del catálogo
de estatus).

Dos desviaciones respecto al `PLAN.md` original, ambas por decisión del responsable: **Colombia se incluye
igual que México** (el plan contemplaba aplicar los scripts solo en MEX) y los **DTOs nuevos van planos**
en `DTOs/Issues/`, sin subcarpeta `Responses/`. Ver la tabla de decisiones.

---

## Relación de tareas y tiempos (seguimiento)

- **Días est. (rango):** el rango estimado que venía del plan (no cambia).
- **Fecha inicio / Fecha fin:** fechas reales (días hábiles) en que arrancó y cerró la fase.
- **Días ejecutados:** días hábiles ya invertidos en la fase.
- **Días restantes:** días hábiles estimados que faltan para cerrarla (0 cuando está ✅).
- **Estatus:** ⏳ Pendiente · 🟡 En progreso · ✅ Completada · ⏸️ Pausada · 🔴 Bloqueada · ✖️ Cancelada.
- **ID (BD):** `pm_plan_fase.id`, reflejado en la base de datos en cada cambio de estatus.

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Rama base y cierre de supuestos** | 181 | T-01 a T-03 | 0.5 – 1 | 2026-08-21 | 2026-08-21 | 0.5 | 0 | ✅ Completada |
| **Fase 1 — Lectura de evidencia y estatus confiable (P1)** | 182 | T-04 a T-14 | 4 – 6 | 2026-08-21 | | 0 | 4 – 6 | 🟡 En progreso |
| **Fase 2 — Anotaciones de incidencia (P2)** | 183 | T-15 a T-22 | 4 – 6 | | | 0 | 4 – 6 | ⏳ Pendiente *(fuera de alcance de esta ejecución)* |
| **Fase 3 — Observaciones de avería y gateway (P3)** | 184 | T-23 a T-25 | 2 – 3 | | | 0 | 2 – 3 | ⏳ Pendiente *(fuera de alcance de esta ejecución)* |
| **Fase 4 — Habilitación a producción** | 185 | T-26 a T-28 | 1 – 2 | | | 0 | 1 – 2 | ⏳ Pendiente *(fuera de alcance de esta ejecución)* |
| **Total proyecto (P1+P2+P3+F4)** | — | 28 tareas | ~12 – 18 | 2026-08-21 | | 0.5 | ~11.5 – 17.5 | 🟡 En progreso |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-14 | ~4.5 – 7 | 2026-08-21 | | 0.5 | ~4 – 6.5 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Crear la rama funcional desde `develop` | Claude Code | 2026-08-21 | `develop` estaba actualizado y sin cambios pendientes. Rama creada y publicada en `origin` con tracking. Working tree limpio |
| T-02 | Verificar el rol con que el panel y el agente llaman a Issues | Javier Antonio Oropeza Camacho | 2026-08-21 | **Cerrada por confirmación del responsable, no por sonda empírica contra QA.** El panel llama como Administrador General → satisface `ICanManageIssues` ([Program.cs:235-236](../../../gp_3.0_siga_api/Services/Claims/Program.cs#L235-L236)). El riesgo bloqueante del PRD §14 queda cerrado y **no se amplía la policy** |
| T-03 | Confirmar con el responsable las tres decisiones de diseño | Javier Antonio Oropeza Camacho | 2026-08-21 | Las tres ratificadas **sin cambios** respecto al plan. No aplica el escenario de "+2 días por FK" |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| T-04 | Script SQL del catálogo `estatus_incidencia` | Claude Code | 2026-08-21 | Se entrega en carpeta para ejecución manual. **Dos versiones: MEX y COL** |

---

## Tareas pendientes ⏳

Alcance de esta ejecución: **solo hasta T-14**.

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-05 | Entidad y mapeo de `estatus_incidencia` en `DataAccess` y `DataAccessColombia` | — |
| T-06 | DTOs de lectura de documentos de incidencia | — |
| T-07 | Contrato de servicio: métodos de lectura en `IIssuesService` | — |
| T-08 | Implementación de la lectura de documentos (`IssuesService.Documents.cs`) | T-07 |
| T-09 | Resultados tipados y mapeo de errores de lectura | — |
| T-10 | Endpoints de lectura de evidencia en `IssuesController` | T-08, T-09 |
| T-11 | Catálogo de estatus consultable (`IssuesService.Status.cs`) | T-05 |
| T-12 | Validación y normalización de estatus en `UpdateIssue` | T-11 |
| T-13 | Carpeta `Services/Claims/doc/` + las 3 entradas de la Fase 1 | — |
| T-14 | Verificación empírica de la Fase 1 contra QA | T-04 (ejecución de scripts por el responsable), T-10, T-12 |
| T-15 a T-28 | Fases 2, 3 y 4 | **Fuera de alcance de esta ejecución** (decisión del responsable) |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | — | Ninguna | — |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| **Alcance acotado a P1** (Fase 0 + Fase 1, T-01 a T-14) | Es el guardarraíl que declara el propio PRD: desbloquea la pestaña de Evidencia, que hoy tiene costo operativo real, y no requiere coordinar con ningún otro repositorio | Fases 2, 3 y 4 quedan en `Pendiente`. La Fase 2 (anotaciones) sigue dependiendo de la ventana coordinada con el panel y el agente |
| **Catálogo `estatus_incidencia` como tabla sin FK** desde `incidencia`; validación y normalización en la API | El PRD §6 declara explícitamente fuera de alcance romper el contrato de `status` por nombre, y los dos consumidores en vivo lo mandan así. Una FK obligaría a migrar la columna a entero y a romperlos | La columna `incidencia.estatus` sigue siendo `VARCHAR(80)`. La protección contra basura la da la API, no el motor. Escrituras directas a la base pueden seguir metiendo valores fuera de catálogo |
| **Casing del gateway: se declara, no se normaliza** | Normalizar exige un inventario completo de consumidores del gateway que **no existe** (pregunta abierta del propio PRD). Romper a un consumidor no inventariado produce un `401` inexplicable, el peor síntoma posible de diagnosticar | La trampa del `301` que descarta el header `Authorization` deja de ser conocimiento oral y queda en `doc/` y en Swagger. Es tarea de Fase 3 (fuera de este alcance) |
| **Fechas: se fija el `Kind` en el mapeo, no se migra la columna** | RF-17 es un requisito de superficie de API y el mapeo lo satisface por completo. Migrar `fecha_registro` a `timestamptz` toca a todo consumidor de la columna dentro y fuera del repo, y agrava la divergencia entre bases de país | Deuda consciente y documentada, no un descuido. Migrar es un proyecto aparte con su propia ventana |
| **Colombia se incluye igual que México** ⚠️ *desviación del plan* | Decisión del responsable. El `PLAN.md` §5 contemplaba entregar los scripts para las tres bases pero **ejecutarlos solo en MEX** | Los scripts de T-04 se entregan en **dos versiones (MEX y COL)**. La verificación de T-14 debería correrse también contra la QA de Colombia — pendiente de confirmar si hay acceso; si no lo hay, se verifica contra MEX y COL queda para su ventana |
| **DTOs nuevos planos** en `DTOs/Issues/`, sin subcarpeta `Responses/` ⚠️ *desviación del plan* | Decisión del responsable (`PLAN.md` §12.3 la dejaba abierta). Prioriza consistencia con los DTOs de Issues existentes, que están planos, por encima de la guideline de carpetas | `DTOs/Issues/` queda homogéneo. Se aparta de la guideline `DTOs/{Feature}/{Requests,Responses}/`, que sí respeta `DTOs/Workshops/` |
| **Scripts SQL se entregan, no se ejecutan** | Decisión del responsable: él los aplica en QA | T-14 no puede cerrarse hasta que los scripts estén aplicados. Es una dependencia explícita, no un bloqueo |
| **La batería de sondas de Pedro no existe** | El PRD la daba por existente; ni el responsable ni el equipo la ubican | La verificación empírica de T-14 se arma desde cero en este proyecto y se documenta con sus resultados aquí |
| **T-02 cerrada por confirmación, no por sonda** | El responsable confirmó que el panel opera como Administrador General | Coherente con lo que exige `ICanManageIssues` en código. Si en producción apareciera un `403`, el primer sospechoso es este supuesto |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| *(ninguno todavía — Fase 0 solo produjo la rama)* | — | — |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| *(pendiente — el primer commit se solicita al cerrar la Fase 1)* | | |

---

## Notas para quien retome el trabajo

**¿Por dónde continuar?** Por **T-04**: el script SQL del catálogo `estatus_incidencia`, en versión MEX y COL.
La Fase 0 está cerrada y no hay nada bloqueado.

**Contexto importante:**

- **El riesgo caro de este proyecto no es funcional, es de fuga de datos.** Los documentos de incidencia
  (`documento_incidencia`) y los de avería (`documento_averia`) son espacios de ids **distintos** y jamás se
  deben cruzar. En pruebas ya ocurrió: al resolver la evidencia de una incidencia salieron PDFs de taller de
  un claim de 2020, de otro cliente. El criterio de completitud de T-08 es verificable con `grep`: el archivo
  `IssuesService.Documents.cs` **no debe contener ninguna referencia** a `documento_averia` ni a `averia`.
- **El error natural de T-12** es insertar la validación de estatus en un método que ya asigna campos y
  guarda. Si un `PUT` con estatus inválido persiste la descripción o el odómetro antes de devolver el 400,
  la tarea está mal. La validación va **antes** de aplicar cualquier campo y antes de cualquier
  `SaveChangesAsync`.
- **Regla del repositorio:** todo modelo, `DbSet` y mapeo nuevo se replica **igual** en `DataAccess` (MEX) y
  `DataAccessColombia` (COL). El repo hermano correcto es **`gp_4.0_siga`** — ojo, `gpmx_3.0` también tiene
  una carpeta `DataAccess` y **no es esa**.
- **No hay proyectos de test en el repositorio.** Toda verificación es empírica contra QA. Un cambio futuro
  en la validación de estatus o en los permisos de lectura puede regresar sin que nada lo detecte.
- **Claude Code no compila.** El responsable ejecuta `dotnet build` desde `Services/Claims/`.

**Decisiones pendientes de input del equipo:**

- ¿Hay acceso a la QA de **Colombia** para ejecutar los scripts y verificar allá, o se aplican en su
  propia ventana? (afecta el cierre de T-14)
- Fase 2: disponibilidad del panel y del agente para la ventana coordinada (se resolverá al iniciarla)
- Siguen abiertas y son de JC / TI: si `ConvertToClaim` debe migrar la evidencia, quién actualiza
  `api-contract.md`, y los permisos exactos de la cuenta de servicio del agente en producción

---

*Actualizado automáticamente por Claude Code — Engine CX*
