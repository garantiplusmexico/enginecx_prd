# Registro de Avance — Omitir Datos Distribuidor Chile (PJ1796)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ1796-omitir-datos-distribuidor-chile` (base: `develop` @ `303817c`) |
| Responsable actual | Javier Antonio Oropeza Camacho |
| Última actualización | 2026-08-11 |
| Fecha de cierre | 2026-08-11 |
| Estado general | ✅ Completado — código y pruebas funcionales validadas |

---

## Resumen de estado

**Plan cerrado.** Se implementó el cambio de código completo: los campos **Cuenta bancaria** y **CLABE** ya no se renderizan en `_EditCHL.cshtml`, y las reglas jQuery de esos campos en `Create.cshtml` / `Edit.cshtml` quedaron condicionadas a que el input exista en el DOM (guard `.length`), evitando el error de `validator` en Chile sin tocar México/Colombia/Perú/Argentina.

El proyecto compila sin errores (`dotnet build GarantiplusWeb` → 0 errores). Las pruebas funcionales T-06, T-07 y T-08 fueron ejecutadas y validadas por el programador en ambiente el 2026-08-11 — no quedan tareas abiertas. No se requirió activar T-05 (ajuste server-side): T-07 confirmó que los valores previos de `cuenta_bancaria`/`clabe` se conservan.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Crear rama funcional desde `develop` | Claude Code | 2026-07-30 | `develop` actualizado (8 commits fast-forward) antes de ramificar |
| T-02 | Baseline del comportamiento actual | Claude Code (análisis de código) | 2026-07-30 | Verificado en código en lugar de ambiente: `Create`/`Edit` POST **no** consultan `ModelState.IsValid` (solo `ModelState.AddModelError` en `catch` y en validaciones fiscales/permisos). El `[Required]` de `cuenta_bancaria`/`clabe` en el modelo no bloquea el guardado. Confirma el hallazgo del PLAN §1 |
| T-03 | Quitar render de Cuenta bancaria y CLABE en `_EditCHL` | Claude Code | 2026-07-30 | Eliminadas las dos líneas `<form-text>` de la card "Información financiera"; se dejó comentario Razor con el folio |
| T-04 | Condicionar reglas jQuery en Create y Edit | Claude Code | 2026-07-30 | Guard por existencia en DOM (`if ($("#cuenta_bancaria").length)` / `if ($("#clabe").length)`) |
| T-05 | Ajuste server-side para CHL | — | 2026-07-30 | **N/A** — no se requiere (ver decisión abajo) |
| T-06 | Prueba Create CHL sin Cuenta bancaria/CLABE | Javier Antonio Oropeza Camacho | 2026-08-11 | Validada en ambiente Chile: el alta concluye y redirige a Details |
| T-07 | Prueba Edit CHL + conservación de datos (RF-04 / RF-05) | Javier Antonio Oropeza Camacho | 2026-08-11 | Validada en ambiente Chile: los valores previos de `cuenta_bancaria`/`clabe` se conservan. Confirma el análisis estático — **no fue necesario activar T-05** |
| T-08 | Smoke de no-regresión MEX (y COL) | Javier Antonio Oropeza Camacho | 2026-08-11 | Validado: ambos campos siguen visibles y validando en México; sin errores de jQuery Validate en consola |
| T-09 | Commit y push de la feature | Claude Code | 2026-07-30 | Commit y push hechos; el PR queda a cargo del programador |

---

## Tareas en progreso 🟡

Ninguna.

---

## Tareas pendientes ⏳

Ninguna — todas las tareas del plan quedaron cerradas.

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | — | Sin bloqueos | — |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Usar guard por existencia en DOM (`$("#campo").length`) en lugar de `if ('@ViewBag.CodigoPais' != "CHL")` | `Create.cshtml` y `Edit.cshtml` resuelven la parcial con `ViewBag.EditDistribuidorPartial` (`SetDistribuidorEditPartial`, `DistribuidoresController.cs:847`), no con `ViewBag.CodigoPais`; ese ViewBag no está garantizado en ambos GET. El guard por DOM es agnóstico de país y sigue funcionando si mañana otra parcial (`_EditPER`, `_EditARG`, …) quita esos campos | Cero riesgo de regresión: en MEX/COL/PER/ARG los inputs existen y las reglas se aplican igual que antes |
| No aplicar T-05 (ajuste server-side) | Se confirmó por código que `Create` y `Edit` POST no evalúan `ModelState.IsValid`; usan `TryUpdateModelAsync` y persisten directo. El `[Required]` del modelo compartido no bloquea | Se respeta la decisión de diseño §3.3 del plan: no se altera el contrato de validación de otros países |
| No tocar `_Edit.cshtml`, `_EditMEX`, `_EditCOL`, `_EditPER`, `_EditARG` ni `_GeneralesDistribuidor` | Fuera de alcance del PRD (§6) | Details de distribuidor sigue mostrando CLABE en grids — follow-up si negocio lo pide |
| Comentario Razor `@* PJ1796: ... *@` en `_EditCHL` | Deja rastro del porqué de la ausencia de los campos para quien lea la vista después | Documentación in-situ, sin salida en el HTML generado |

**Nota sobre RF-05 (conservación de datos):** en `Edit` POST (`DistribuidoresController.cs:1309`) se hace `TryUpdateModelAsync(model)` sobre la entidad ya cargada desde BD. El model binding de ASP.NET Core solo asigna propiedades presentes en el value provider, por lo que al no postearse `cuenta_bancaria`/`clabe` sus valores previos deberían conservarse. **Confirmado en T-07 contra la BD el 2026-08-11: los valores se conservan.**

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/_EditCHL.cshtml` | Modificado | T-03 |
| `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/Create.cshtml` | Modificado | T-04 |
| `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/Edit.cshtml` | Modificado | T-04 |

---

## Verificación realizada

| Verificación | Resultado |
|---|---|
| `dotnet build GarantiplusWeb/GarantiplusWeb.csproj` | ✅ 0 errores (1256 advertencias preexistentes, ninguna nueva). Las vistas Razor se compilan en build, por lo que la sintaxis de las tres vistas quedó validada |
| Grep de `cuenta_bancaria` / `clabe` en `Views/Distribuidores/` | ✅ Sin ocurrencias en `_EditCHL.cshtml`; intactas en `_Edit`, `_EditMEX`, `_EditCOL`, `_EditPER`, `_EditARG` y `_GeneralesDistribuidor` |
| T-06 — Alta de distribuidor CHL sin los campos (ambiente) | ✅ Validada por el programador — 2026-08-11 |
| T-07 — Edit CHL: conservación de `cuenta_bancaria`/`clabe` en BD (ambiente) | ✅ Validada por el programador — 2026-08-11 |
| T-08 — No-regresión MEX/COL: campos visibles y validando (ambiente) | ✅ Validada por el programador — 2026-08-11 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `e560f6e` | `[PJ1796-omitir-datos-distribuidor-chile] Ocultar cuenta bancaria y CLABE en formulario CHL` | 2026-07-30 |

---

## Notas de cierre

- **Plan cerrado el 2026-08-11.** Todas las tareas (T-01 a T-09) quedaron completadas o marcadas N/A con justificación. No hay trabajo abierto en este folio.
- **Siguiente paso de proceso:** merge de `feature/PJ1796-omitir-datos-distribuidor-chile` a `pre-qa` y PR `pre-qa → qa` — responsabilidad del programador. Claude Code no crea PRs.
- **Contexto importante para quien lea la vista después:** la parcial por país se resuelve en `SetDistribuidorEditPartial` (`DistribuidoresController.cs:847`) — `_Edit{codigoPais}` si la vista existe, si no `_EditMEX`. Chile usa `_EditCHL.cshtml`.
- **Cuidado:** existe otra `_EditCHL.cshtml` en el área de Órdenes de Pago. El cambio va solo en `Areas/Catalogos/Views/Distribuidores/`.
- **Follow-ups posibles (fuera de alcance de este PRD):** si se pide ocultar CLABE también en Details (`_GeneralesDistribuidor.cshtml`), abrir un folio nuevo.

---

*Actualizado automáticamente por Claude Code — Engine CX*
