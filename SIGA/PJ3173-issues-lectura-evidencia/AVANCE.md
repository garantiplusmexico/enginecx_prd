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

La **Fase 0 está completa** y la **Fase 1 está escrita al 100%**: T-01 a T-13 terminadas. Quedan los 4
endpoints nuevos, el catálogo de estatus con su validación, las entidades espejo en los dos contextos EF, el
script SQL y la carpeta `doc/` con sus 3 entradas.

**El proyecto compila** (verificado por el responsable el 2026-08-21; el único error fue un `using` faltante
de `Claims.Models.Issues` en `IssuesService.cs`, corregido). Código commiteado y subido a `origin`.

**Falta T-14: nada se ha probado en ejecución.** El script SQL no consta aplicado en QA y la batería de
`Services/Claims/doc/verificacion-fase-1.http` no se ha corrido. Hasta entonces, la lectura de evidencia y la
validación de estatus **no están verificadas**: compilar no prueba que la consulta de OData se traduzca a SQL,
ni que el aislamiento de espacios de ids se sostenga. **No hay nada bloqueado.**

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
| T-04 | Script SQL del catálogo `estatus_incidencia` | Claude Code | 2026-08-21 | Un solo script idempotente aplicable a MEX y COL, siguiendo la convención del script `2026-07-17_incidencias`. Ids fijos (no `BIGSERIAL`) para que sean iguales en las tres bases. `GRANT` solo de `SELECT` |
| T-05 | Entidad y mapeo de `estatus_incidencia` en los dos contextos espejo | Claude Code | 2026-08-21 | Entidad y mapeo **idénticos** en `DataAccess` y `DataAccessColombia`, verificado con `diff`. `OnModelCreatingIncidencias` ya se invoca en ambos |
| T-06 | DTOs de lectura de documentos y de estatus | Claude Code | 2026-08-21 | Planos en `DTOs/Issues/` por decisión del responsable. `StatusId` **no** se replicó: `documento_incidencia` no tiene estatus por documento |
| T-07 | Contrato de servicio en `IIssuesService` | Claude Code | 2026-08-21 | 4 métodos nuevos con XML docs. Además cambió la firma de `UpdateIssue` a resultado tipado |
| T-08 | Implementación de la lectura de documentos | Claude Code | 2026-08-21 | `IssuesService.Documents.cs`. **Criterio de aislamiento verificado con `grep`: cero referencias a `documento_averia` o `averia`** |
| T-09 | Resultados tipados y mapeo de errores | Claude Code | 2026-08-21 | `IssueDocumentReadStatus`, `IssueDocumentListResult`, `IssueDocumentDownloadResult`, `IssueUpdateResult` + `MapDocumentRead` y `MapInvalidStatus` en español |
| T-10 | Endpoints de lectura de evidencia | Claude Code | 2026-08-21 | En un `partial` nuevo del controller (ya tenía 501 líneas). Los 4 con `LogRequestAsync` de 3 argumentos por ser GET |
| T-11 | Catálogo de estatus consultable | Claude Code | 2026-08-21 | `IssuesService.Status.cs`, leído de la tabla y no de una constante |
| T-12 | Validación y normalización de estatus en `UpdateIssue` | Claude Code | 2026-08-21 | Validación **antes** de asignar cualquier campo y antes de cualquier `SaveChangesAsync`. Normaliza acentos y mayúsculas, persiste la forma canónica, registra el rechazo en `Warning` |
| T-13 | Carpeta `doc/` de Claims + 3 entradas | Claude Code | 2026-08-21 | La carpeta no existía en este microservicio. `README.md` con índice + 3 entradas con el formato de `Services/Authentication/doc/` |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| T-14 | Verificación empírica de la Fase 1 contra QA | Javier Antonio Oropeza Camacho | 2026-08-21 | Batería de llamadas escrita y lista en `doc/verificacion-fase-1.http`. **Falta ejecutarla**: requiere compilar, aplicar el script en QA y correr los 6 bloques |

---

## Tareas pendientes ⏳

Alcance de esta ejecución: **solo hasta T-14**.

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
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
| **Permisos de lectura: espejo de `GetIssues`, NO de `UploadIssueDocument`** ⚠️ *se aparta de la letra de T-08* | T-08 pedía las dos cosas y **no son equivalentes**: la regla interna del upload concede a admin externo, gerente de país y taller acceso a **cualquier** incidencia, mientras que `GetIssues` los acota a sus distribuidores / a lo que registraron. Copiar la del upload habría hecho que el listado ocultara una incidencia y el endpoint de detalle entregara sus fotos | Decisión del responsable el 2026-08-21. La lectura queda **más estricta** que la escritura, que es lo que RNF-01 persigue, y lista y detalle coinciden. Documentado en `doc/incidencias-quien-puede-leer-la-evidencia.md` |
| **`CreationDate` es `DateTime` con Kind=Utc, no `DateTimeOffset`** ⚠️ *se aparta de T-06* | T-06 pedía `DateTimeOffset`, pero construirlo dentro de la proyección LINQ (`DateTime.SpecifyKind` / `new DateTimeOffset(...)`) **no tiene traducción a SQL**, y esa proyección alimenta el `IQueryable` que compone OData: `GetIssueDocuments` habría reventado en ejecución. El Kind se fija con un value converter en el mapeo EF, que sí se aplica en proyecciones | Se cumple RF-17 igual: el JSON sale como `2026-08-21T20:04:53.356Z`, con marca de zona y misma forma en todos los endpoints. Entregar `DateTimeOffset` de verdad exigiría migrar la columna a `timestamptz`, que es justo lo que la decisión §12.2 descartó |
| **Los 4 endpoints nuevos van en un `partial` del controller** | `IssuesController.cs` ya tenía 501 líneas; agregarle ~250 más lo llevaría a 750. `CLAUDE.md` pide dividir por encima de ~200 | Se agregó la palabra `partial` a la declaración de la clase (cambio de una palabra, sin refactorizar lo existente) y los endpoints viven en `IssuesController.Documents.cs` |
| **El `GRANT` del catálogo es solo `SELECT`** | La API lee el catálogo y nunca lo escribe; agregar un estatus es una migración, no una operación de la aplicación. Se aparta de la convención del repo, que otorga los cuatro permisos | Si algún día el catálogo se administra desde el sistema, hay que ampliar el `GRANT`. Anotado en el encabezado del script |

---

## Archivos creados o modificados

Repo `gp_3.0_siga_api`, rama `feature/PJ3173-issues-lectura-evidencia`:

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `Services/Claims/DTOs/Issues/IssueDocumentQueryResponse.cs` | Creado | T-06 |
| `Services/Claims/DTOs/Issues/IssueStatusResponse.cs` | Creado | T-06 |
| `Services/Claims/Interfaces/IIssuesService.cs` | Modificado | T-07, T-12 |
| `Services/Claims/Models/Issues/IssueResult.cs` | Modificado | T-09, T-12 |
| `Services/Claims/Services/IssuesService.Documents.cs` | Creado | T-08 |
| `Services/Claims/Services/IssuesService.Status.cs` | Creado | T-11, T-12 |
| `Services/Claims/Services/IssuesService.cs` | Modificado | T-12 |
| `Services/Claims/Services/IssueResultMapper.cs` | Modificado | T-09, T-12 |
| `Services/Claims/Controllers/IssuesController.Documents.cs` | Creado | T-10 |
| `Services/Claims/Controllers/IssuesController.cs` | Modificado | T-10, T-12 |
| `Services/Claims/doc/README.md` | Creado | T-13 |
| `Services/Claims/doc/incidencias-quien-puede-leer-la-evidencia.md` | Creado | T-13 |
| `Services/Claims/doc/incidencias-ids-no-se-cruzan-con-averias.md` | Creado | T-13 |
| `Services/Claims/doc/incidencias-estatus-validado-por-nombre.md` | Creado | T-13 |
| `Services/Claims/doc/verificacion-fase-1.http` | Creado | T-14 |

Repo hermano `gp_4.0_siga`, rama `feature/PJ3173-issues-lectura-evidencia`:

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `GarantiplusWeb/BD/2026-08-21_estatus_incidencia/estatus_incidencia.sql` | Creado | T-04 |
| `DataAccess/Models/estatus_incidencia.cs` | Creado | T-05 |
| `DataAccessColombia/Models/estatus_incidencia.cs` | Creado | T-05 |
| `DataAccess/IncidenciasExtensions/garantiplus_dbContext.cs` | Modificado | T-05, T-08 |
| `DataAccessColombia/IncidenciasExtensions/garantiplus_dbContext.cs` | Modificado | T-05, T-08 |

---

## Commits realizados

| Hash | Repo | Mensaje | Fecha |
|---|---|---|---|
| `9150dee` | `enginecx_prd` | `[PJ3173] Fase 0 - Rama base y cierre de supuestos` | 2026-08-21 |
| `15e7ada` | `gp_4.0_siga` | `tablas requeridas para estatus de incidencias` (commiteado por el responsable) | 2026-08-21 |
| `2c722fd` | `gp_3.0_siga_api` | `[PJ3173] Fase 1 - Lectura de evidencia y estatus confiable` | 2026-08-21 |

`2c722fd` depende de `15e7ada`: sin la tabla y las entidades espejo del repo hermano, el servicio no compila.

---

## Notas para quien retome el trabajo

**¿Por dónde continuar?** Por **T-14**, la única tarea de P1 que falta. Todo el código está escrito pero
**no compilado ni probado**. En orden:

1. `dotnet build` desde `Services/Claims/` — el responsable compila, Claude Code no.
2. Aplicar `2026-08-21_estatus_incidencia/estatus_incidencia.sql` en la QA de México y, si hay acceso, en la
   de Colombia.
3. Correr los 6 bloques de `Services/Claims/doc/verificacion-fase-1.http` y anexar resultados aquí.
4. Confirmar con el panel que la pestaña de Evidencia ya muestra contenido.

Los bloques 2.2/2.3 (el 400 no persiste nada) y 4 (aislamiento de espacios de ids) son los que de verdad
importan; el resto es cobertura.

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
