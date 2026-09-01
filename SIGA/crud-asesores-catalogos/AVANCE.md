# Registro de Avance — CRUD de asesores en el servicio Catalogs

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/crud-asesores-catalogos` (creada desde `develop` en `55f8ea0`) |
| Responsable actual | Juan Carlos Castellanos Solis |
| Folio PRD | `PJ5478` (provisional e inventado — no hay PRD) |
| ID plan (BD) | `67` |
| Última actualización | 2026-08-31 |
| Estado general | 🟡 En progreso — **código completo, SIN COMMIT, pendiente de revisión de Carlos** |

---

## Resumen de estado

Las 9 tareas de código del plan (T-01 a T-09) están implementadas: la policy de escritura, el
servicio con sus validaciones, los tres endpoints y las rutas de KrakenD. **Nada está commiteado**:
Carlos pidió explícitamente revisar el código antes de que se suba, así que la rama existe solo en
local y tampoco se hizo push.

**Falta compilar.** Por convención del equipo, Carlos compila y levanta los servicios; este flujo no
corrió `dotnet build`.

Las tres tareas restantes (T-10, T-11, T-12) son pruebas contra QA y despliegue: requieren ambiente
y credenciales que este flujo no tiene, y T-11 además depende de que Omega esté dado de alta en QA
(T-017 del tablero).

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Cimientos del servicio** | 242 | T-01 a T-03 | 1 – 2 | 2026-08-31 | 2026-08-31 | <1 | 0 | ✅ Completada |
| **Fase 1 — Validaciones compartidas** | 243 | T-04 a T-05 | 1 – 2 | 2026-08-31 | 2026-08-31 | <1 | 0 | ✅ Completada |
| **Fase 2 — Las tres operaciones** | 244 | T-06 a T-08 | 2 – 3 | 2026-08-31 | 2026-08-31 | <1 | 0 | ✅ Completada |
| **Fase 3 — Exposición y validación** | 245 | T-09 a T-12 | 2 – 3 | 2026-08-31 | | <1 | 2 – 3 | 🟡 En progreso |
| **Total proyecto** | — | 12 tareas | ~6 – 10 | 2026-08-31 | | <1 | 2 – 3 | 🟡 En progreso |

> El tiempo ejecutado real (<1 día) está muy por debajo del rango estimado porque el plan traía el
> análisis del código ya hecho y las decisiones cerradas. Lo que resta —validación en QA y
> despliegue— sí depende de tiempo de calendario y de disponibilidad del ambiente.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Estructura de carpetas de `Catalogs` | Claude Code | 2026-08-31 | Se crearon `Interfaces/` y `Services/`, que el servicio nunca tuvo |
| T-02 | Policy de escritura `ICanManageAdvisors` | Claude Code | 2026-08-31 | Constante en `Policies.cs` + registro en `Catalogs/Program.cs`. Ver decisión D-1 |
| T-03 | `IAdvisorService` | Claude Code | 2026-08-31 | Tupla `(Result, ErrorMessage, StatusCode)`, igual que los servicios de escritura de `Contracts` |
| T-04 | Validación de scope del distribuidor | Claude Code | 2026-08-31 | Mismo switch por rol que ya aplica la lectura; se valida en servidor |
| T-05 | Validación de RFC único por distribuidor | Claude Code | 2026-08-31 | Trim + lower, acotada al dealer, excluye el propio id al actualizar |
| T-06 | `POST CreateAdvisor` | Claude Code | 2026-08-31 | 201; nace activo; `Rfc` documentado por país |
| T-07 | `PUT UpdateAdvisor/{id}` | Claude Code | 2026-08-31 | Valida scope del dealer actual **y** del destino; permite reactivar |
| T-08 | `DELETE DeactivateAdvisor/{id}` | Claude Code | 2026-08-31 | Borrado lógico; ver decisión D-3 |
| T-09 | Rutas en KrakenD | Claude Code | 2026-08-31 | 3 rutas nuevas; JSON validado, 128 endpoints en total |

---

## Tareas en progreso 🟡

Ninguna. El código está completo y detenido a propósito, esperando revisión.

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| — | **Compilar el servicio** | Lo hace Carlos, por convención del equipo |
| T-10 | Matriz de pruebas de autorización y scope en QA | Requiere ambiente y usuarios de QA |
| T-11 | Prueba e2e con Omega | Requiere QA **y** T-017 (alta de Omega) ejecutada |
| T-12 | Despliegue a QA y PROD | Requiere T-10 y T-11 |

---

## Tareas bloqueadas 🔴

Ninguna.

---

## Decisiones tomadas durante la ejecución

| # | Decisión | Justificación | Impacto |
|---|---|---|---|
| D-1 | `ICanManageAdvisors` quedó con **los mismos 8 roles** que `ICanReadProductTypes`, no "esos menos Auditor" como decía el plan | Al implementar se verificó que `ICanReadProductTypes` **ya excluye a `Auditor`** en `Catalogs/Program.cs`. Auditor hoy ni siquiera puede leer asesores por API | Ninguno funcional: Auditor sigue sin acceso. La policy se declara aparte de todos modos, para que leer nunca implique escribir y para que ambas listas puedan divergir |
| D-2 | Los cinco endpoints viven en **un solo `AdvisorController.cs`** | Primero se separaron en un partial `AdvisorController.Write.cs` por el límite de 200 líneas; **Carlos pidió unificarlos** para tener todos los endpoints en un mismo lugar. Su criterio manda sobre la guía | El archivo queda en 410 líneas sin blancos, por encima del límite de `coding-guidelines.md`. Es una desviación **deliberada y autorizada**. La lógica sigue fuera, en `AdvisorService` |
| D-7 | Documentación XML recortada en todos los archivos nuevos, y de paso en dos constantes preexistentes de `Policies.cs` | Feedback explícito de Carlos: la documentación estaba de más. Se conservó solo lo que un dev no puede deducir del código (el porqué), y se quitó lo que repetía la firma | `IAdvisorService` pasó de 69 a 32 líneas; los DTOs perdieron la tabla de países de 9 renglones, que ahora es una frase. Se recortaron también `ICanManageAdvisors` e `IsDistributorWorkshopUser` |
| D-3 | En `DeactivateAsync` el scope se valida **antes** que el estado `activo` | Con el guard de `activo` dentro del lookup (como lo hace BMW), un llamador fuera de scope recibía 403 para un asesor activo y 404 para uno inactivo, lo que permite distinguirlos. Ahora fuera de scope siempre responde igual | Corrige una fuga de información que el patrón original de BMW sí tiene |
| D-4 | Los timestamps se escriben con `DateTime.UtcNow` desde EF, no con `NOW()` de SQL | `Catalogs` es EF puro; los servicios que usan `NOW()` (BMW) son de SQL crudo. Meter SQL crudo aquí solo por el timestamp sería inconsistente con el resto del servicio | ⚠️ **A validar por Carlos**: los valores históricos de `asesor.created_at` parecen hora local. Si se prefiere consistencia con `NOW()`, es un cambio de 3 líneas |
| D-5 | La unicidad del RFC **incluye a los asesores inactivos** | Es lo que hace SIGA (`CheckRFC` no filtra por `activo`): un asesor desactivado sigue siendo la misma persona, así que su identificador queda reservado | Para "revivir" a alguien hay que reactivarlo con el `PUT`, no crear un duplicado. Documentado en el XML doc del método |
| D-6 | `created_at` se puebla en el alta | SIGA dejó de escribir esa columna en 2020 (de 19,725 asesores, solo 3,100 la tienen). Poblarla en los nuevos no rompe nada y da trazabilidad | Los asesores creados por API sí traerán fecha de alta; los de SIGA seguirán en NULL |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `Common/Policies/Policies.cs` | Modificado | T-02 |
| `Services/Catalogs/Program.cs` | Modificado | T-02, T-03 |
| `Services/Catalogs/Interfaces/IAdvisorService.cs` | Creado | T-03 |
| `Services/Catalogs/Services/AdvisorService.cs` | Creado | T-06, T-07, T-08 |
| `Services/Catalogs/Services/AdvisorService.Validation.cs` | Creado | T-04, T-05 |
| `Services/Catalogs/DTOs/Advisors/CreateAdvisorRequest.cs` | Creado | T-06 |
| `Services/Catalogs/DTOs/Advisors/UpdateAdvisorRequest.cs` | Creado | T-07 |
| `Services/Catalogs/DTOs/Advisors/AdvisorDeactivationResponse.cs` | Creado | T-08 |
| `Services/Catalogs/Controllers/AdvisorController.cs` | Modificado | T-06 a T-08 (inyección del servicio + los 3 endpoints nuevos; la lectura no se tocó) |
| `Services/ApiGateway/krakend.json` | Modificado | T-09 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| — | **Ninguno.** Carlos pidió revisar el código antes de commitear. La rama existe solo en local, sin push | — |

---

## Notas para quien retome el trabajo

**Por dónde continuar:** el código está completo y sin commitear en `feature/crud-asesores-catalogos`
(local, sin push). El siguiente paso es compilar y, si pasa, ejecutar T-10 a T-12.

**Contexto importante:**

- **La tabla es `asesor`, no `bmw_asesor`.** Es el error más caro posible aquí: un asesor escrito en
  `bmw_asesor` es invisible para el alta de contrato.
- **El `DELETE` nunca borra la fila.** Los asesores están referenciados por `contrato.id_asesor`.
- **Una desviación deliberada del estándar:** `AdvisorController.cs` tiene 410 líneas sin blancos,
  contra el límite de 200 de `coding-guidelines.md`. Es decisión explícita de Carlos tener los cinco
  endpoints en un mismo archivo (ver D-2). La lógica no vive ahí: está en `AdvisorService`, que sí
  respeta el límite (137 y 121 líneas sus dos partials).

**Decisiones que requieren input:**

- **D-4 (timestamps `UtcNow` vs `NOW()`)** es la única que conviene que Carlos confirme. No bloquea.

**Al desplegar:** hay que redesplegar **ApiGateway** además de `Catalogs`, o las tres rutas nuevas
dan 404 aunque el servicio esté bien.

---

*Actualizado automáticamente por Claude Code — Engine CX*
