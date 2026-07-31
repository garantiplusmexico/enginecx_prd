# Registro de Avance — Ocultar Código Postal (CP) en Chile (PJ2703)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `gp_4.0_siga` |
| Rama | `feature/PJ2703-ocultar-cp-en-chile` (desde `develop`) |
| Responsable actual | Javier Oropeza |
| Fecha de inicio | 2026-07-30 |
| Última actualización | 2026-07-30 |
| Estado general | ✅ Completado (código) — pendiente validación funcional en ambiente CHL |

---

## Resumen de estado

El baseline (T-02) confirmó que **la emisión CHL ya no muestra CP en `develop`**: `PaisCL` entrega `localidades_show_postal_code = false` y `_LocalidadesMEX` gatea el bloque de CP con ese flag, tanto en `Create` como en `EmisionEspecial`. Por eso T-03 y T-06 quedaron **N/A**.

El único hueco Chile-específico real era el **Cotizador CHL**, que renderizaba el campo CP explícitamente. Se eliminó (T-04). La solución compila sin errores. Falta únicamente la validación funcional en un ambiente con proyecto Chile (T-07 a T-10) y, si producción Chile aún muestra el CP en emisión, el despliegue de `develop`.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Crear rama funcional desde `develop` | Claude Code | 2026-07-30 | `develop` ya estaba up to date con `origin/develop`. Rama creada y pusheada al remoto |
| T-02 | Baseline CHL: comportamiento actual de Create / EmisionEspecial | Claude Code | 2026-07-30 | **Ya oculto.** Ver detalle abajo |
| T-03 | Corregir emisión Create/EmisionEspecial | Claude Code | 2026-07-30 | **N/A** — T-02 confirmó que el gate ya funciona correctamente |
| T-04 | Quitar CP del Cotizador Chile (`CreateCHL`) | Claude Code | 2026-07-30 | Eliminado el bloque label/input/validation de `beneficiario.cp` (líneas 252–258). Sin referencias JS huérfanas |
| T-05 | Confirmar que `PaisCL` no exige CP | Claude Code | 2026-07-30 | Verificado sin cambios: `beneficiario_cp_requerido = false` (línea 1571), `localidades_show_postal_code = false` (línea 1578) |
| T-06 | Ajuste server-side para no exigir/persistir CP | Claude Code | 2026-07-30 | **N/A** — `beneficiario_poliza.cp` no tiene `[Required]`; `CotizadorController` no referencia `cp` en ningún punto |
| T-09 | Smoke no-regresión MX/CO (revisión estática) | Claude Code | 2026-07-30 | El diff toca **un solo archivo exclusivo de CHL**. `_LocalidadesMEX`, `CreateMEX`, `PaisMX` y `PaisCO` sin modificar |
| T-10 | Smoke visual CHL | Claude Code | 2026-07-30 | Revisado el grid `tw-grid-cols-2`: al quitar CP el bloque queda telefonos/email → Región/Comuna → dirección (span 2). Sin labels ni huecos huérfanos (de hecho elimina un hueco que existía) |
| T-11 | Commit y push de la feature | Claude Code | 2026-07-30 | Ver sección Commits |

### Detalle del baseline T-02 (evidencia en código)

| Verificación | Resultado |
|---|---|
| `PaisCL.GetAdditionalContractBeneficiaryVehicleElements()` | `beneficiario_cp_requerido = false`, `localidades_show_postal_code = false` — `PaisesService/Classes/CL/PaisCL.cs:1571,1578` |
| `ContratosController.SetContractLocalidadesViewBag()` | Propaga `cfg.localidades_show_postal_code` a `ViewBag.LocalidadesShowPostalCode` — `ContratosController.cs:137` |
| ¿`Create` lo invoca? | Sí — `ContratosController.cs:1273` |
| ¿`EmisionEspecial` lo invoca? | Sí — `ContratosController.cs:1363` |
| `_LocalidadesMEX.cshtml` | El bloque de CP está envuelto en `@if (localidadesShowPostalCode)` — línea 16 |
| JS de `Create` / `EmisionEspecial` | Rules y `buscacp` condicionados por `localidadesShowPostalCode` |
| `_BeneficiarioCHL.cshtml` | **Sin ninguna referencia a CP** (confirma la corrección al PRD §12.1 del plan) |

**Conclusión:** el MVP de emisión CHL ya está resuelto en `develop`. Si Operaciones Chile aún ve el CP en producción, la causa es **despliegue pendiente**, no código.

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-07 | Prueba funcional: emisión Create CHL sin CP → contrato emitido, `beneficiario_poliza.cp` null/vacío | Requiere ambiente/proyecto con país CHL |
| T-08 | Prueba funcional: cotización CHL sin CP → OK, sin error JS | Requiere ambiente/proyecto con país CHL |
| T-09 | Smoke funcional MX (lookup de colonias por CP) y COL | Requiere ambiente MX/COL |

> Nota: T-09 quedó cubierto a nivel de revisión estática (el diff no toca nada compartido); la prueba en ambiente es confirmación adicional recomendada antes del PR a `pre-qa`.

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | — | Sin bloqueos | — |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| No crear `_LocalidadesCHL` | El flag `localidades_show_postal_code` ya es el patrón oficial de regionalización y funciona correctamente (T-02) | Cero código nuevo; se respeta RNF-03 |
| No tocar `_LocalidadesMEX.cshtml` | El gate ya existe y funciona; hardcodear ocultamiento rompería MX | Riesgo de regresión MX eliminado |
| T-04 ejecutado (no marcado N/A) | El Cotizador CHL es una vista **exclusiva de Chile** que sí mostraba el CP; es el único hueco real del folio | Si Operaciones confirma que el Cotizador está fuera de alcance, revertir es un solo commit |
| No añadir gate condicional en el Cotizador | `CreateCHL.cshtml` es exclusivo de CHL — no necesita flag; un `@if` sería complejidad sin uso | Menos código; MX usa `CreateMEX.cshtml`, intacto |
| No tocar endosos CHL | Fuera del alcance del PRD (habla de emisión). Documentado como follow-up | `_BeneficiaryEndorsementCHL`, `_TransferEndorsementCHL`, `_FullPackageAssignmentEndorsementCHL` siguen con `Cp` required |
| No tocar el modelo ni la BD | Fuera de alcance del PRD; protege MX/CO e históricos | `beneficiario_poliza.cp` intacto |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `GarantiplusWeb/Areas/Contratos/Views/Cotizador/CreateCHL.cshtml` | Modificado | T-04 |

Archivos **verificados sin necesidad de cambio**: `PaisesService/Classes/CL/PaisCL.cs` (T-05), `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs` (T-02/T-03), `GarantiplusWeb/Areas/Contratos/Views/Contratos/_LocalidadesMEX.cshtml` (T-03), `DataAccess/Models/beneficiario_poliza.cs` (T-06).

---

## Verificación de build

```
dotnet build GarantiplusWeb/GarantiplusWeb.csproj
→ 0 Errores, 65 Advertencias (todas preexistentes, ninguna en archivos tocados)
```

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| (ver rama) | `[PJ2703-ocultar-cp-en-chile] Ocultar código postal en cotizador Chile` | 2026-07-30 |

---

## Criterios de aceptación — estado

| Criterio | Estado |
|---|---|
| Emisión Create CHL no renderiza CP | ✅ Verificado en código (ya cubierto por flags en `develop`) — pendiente confirmar en ambiente |
| Emisión CHL concluye sin capturar/persistir CP | ⏳ Pendiente prueba funcional (T-07) |
| `PaisCL` no exige CP | ✅ Verificado |
| Formularios y reglas MX/CO sin cambios | ✅ Verificado (diff toca solo archivo exclusivo CHL) |
| Cotizador CHL sin CP | ✅ Implementado (T-04) |
| Sin migración ni drop de columnas | ✅ Cero cambios en BD |
| UI CHL sin labels/espacios huérfanos | ✅ Verificado en el grid |
| Endosos CHL documentados como fuera de alcance | ✅ Ver Decisiones + Notas |

---

## Notas para quien retome el trabajo

**¿Por dónde continuar?**
1. Levantar un ambiente/proyecto con país **CHL** y ejecutar T-07 y T-08 (emisión y cotización sin CP).
2. Smoke MX: confirmar que el lookup de colonias por CP sigue funcionando en `Create` MEX.
3. Merge de la rama a `pre-qa` y PR `pre-qa → qa` (responsabilidad del programador).

**Contexto importante:**
- **El PRD tiene una imprecisión:** RF-01 dice que el CP vive en `_BeneficiarioCHL`, pero ese partial nunca tuvo CP. El CP de emisión vive en el partial de localidades compartido (`_LocalidadesMEX` como fallback de CHL), gateado por flag de país. No buscar el campo en `_BeneficiarioCHL`.
- **Gran parte del MVP ya estaba resuelta en `develop`.** Si Operaciones Chile reporta que sigue viendo el CP en emisión, el siguiente paso es verificar **qué versión está desplegada en el ambiente Chile**, no volver a tocar código.

**Decisiones pendientes que requieren input del equipo o del solicitante:**
- **Cotizador:** el plan permitía marcar T-04 como N/A si negocio confirmaba que el Cotizador está fuera de alcance. Se optó por incluirlo (es vista exclusiva CHL y mostraba el campo). Si Operaciones dice que no aplica, revertir es un solo commit.
- **Endosos CHL:** `_BeneficiaryEndorsementCHL`, `_TransferEndorsementCHL` y `_FullPackageAssignmentEndorsementCHL` siguen mostrando CP como **required**. Está fuera del alcance de este folio. Si Operaciones Chile lo pide, abrir un PJ de follow-up.
- **Leads:** `Areas/Leads/Views/Leads/Contratar.cshtml` también referencia `beneficiario.cp`. No se tocó — fuera del alcance del PRD (emisión/cotizador). Evaluar si aplica a Chile en un follow-up.

---

*Actualizado automáticamente por Claude Code — Engine CX*
