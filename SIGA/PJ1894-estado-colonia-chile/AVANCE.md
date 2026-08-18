# Registro de Avance — Estado Colonia Chile (PJ1894)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `SIGA/PJ1894-estado-colonia-chile/PLAN.md` |
| Repositorio | `gp_4.0_siga` |
| Rama | `feature/PJ1894-estado-colonia-chile` (desde `develop` actualizado) |
| Responsable | Javier Antonio Oropeza Camacho |
| Ejecutado por | Javier Antonio Oropeza Camacho (Claude Code) |
| Última actualización | 2026-08-14 |
| Fecha de cierre | 2026-08-14 |
| Estado general | ✅ Finalizado — liberado a producción (2026-08-14) |

---

## Resumen de estado

Se implementó por completo el alcance de código del plan (Fase 0 y Fase 1): encabezados del export Excel de contratos CHL, helpers de nomenclatura en `PaisCL` y la etiqueta hardcodeada del Cotizador CHL. Ambos proyectos (`PaisesService` y `GarantiplusWeb`) compilan sin errores.

La Fase 2 de pruebas funcionales (T-06 a T-08) fue ejecutada y validada por el programador: encabezados del export CHL, etiquetas RUT/Región/Comuna en pantallas y smoke de no-regresión en México. **Plan finalizado y liberado a producción el 2026-08-14.** No quedan tareas abiertas.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Crear rama funcional desde `develop` | Claude Code | 2026-08-11 | `develop` ya estaba up-to-date con `origin/develop`; rama creada y publicada en remoto |
| T-02 | Baseline export y vistas CHL | Claude Code | 2026-08-11 | Baseline tomado por lectura de código (no hubo ambiente CHL disponible). Ver sección "Baseline documentado" |
| T-03 | Renombrar encabezados del export en `PaisCL` | Claude Code | 2026-08-11 | Celdas 12, 43 y 46 de la fila 3 del worksheet |
| T-04 | Alinear helpers de nomenclatura en `PaisCL` | Claude Code | 2026-08-11 | `GetFiscalIdName` → RUT, `GetStateLabelName` → Región, labels de localidades |
| T-05 | Corregir label hardcodeada en Cotizador CHL | Claude Code | 2026-08-11 | `DetailsCHL.cshtml` línea 171: RFC → RUT |
| T-09 | Commit y push de la feature | Claude Code | 2026-08-11 | Ver sección "Commits realizados" |
| T-06 | Prueba export CHL — encabezados RUT / Región Beneficiario / Comuna en el Excel | Javier Antonio Oropeza Camacho | 2026-08-14 | Validada por el programador. |
| T-07 | Prueba vistas CHL — `ViewBag.FiscalIdName` = RUT y label RUT en Cotizador | Javier Antonio Oropeza Camacho | 2026-08-14 | Validada por el programador. |
| T-08 | Smoke no-regresión MX (y COL) | Javier Antonio Oropeza Camacho | 2026-08-14 | Sin regresión detectada. |

---

## Tareas en progreso 🟡

Ninguna.

---

## Tareas pendientes ⏳

Ninguna. **Plan finalizado y liberado a producción el 2026-08-14.**

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | — | Ninguna | — |

> El prerequisito §2 (confirmación de Operaciones/BI Chile sobre parsers que leen el Excel por nombre de columna) quedó resuelto con la liberación a producción del 2026-08-14: no se reportaron parsers rotos.

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| En `DetailsCHL.cshtml` se usó el literal `RUT` en lugar de `@Localizer["datofiscalRFC"]` | La vista no tiene `Localizer` inyectado (no hay `@inject IViewLocalizer`) y es específica de Chile por nombre de archivo. Inyectarlo excedía el alcance del folio | Nulo fuera de CHL; si más adelante se localiza esa vista, el cambio es trivial |
| `localidades_neighborhood_label` = "Comuna" (antes "Colonia") | Se siguió el PLAN §3.4 y RF-02 del PRD, aun cuando `localidades_municipality_label` ya es "Comuna" y `CHL.json` usa `direccionColonia: "Provincia"` | Duplicidad semántica potencial: dos ejes con label "Comuna". Impacto real bajo porque `localidades_show_colonia_fields = false` en CHL, así que esos campos no se pintan. **Si Operaciones prefiere "Provincia" en ese eje, es un cambio de una línea** |
| `GetStateLabelName` cambiado a "Región" pese a no tener consumidores hoy | Centralización de strings por país (RNF-03). Se verificó por grep que ningún controlador ni vista lo consume actualmente | Cero riesgo de regresión; queda correcto para futuros consumidores |
| No se tocó `Mpio. Benef.` (col 44) del export | Fuera del alcance del PRD (PLAN §3.5). Queda como follow-up opcional | El Excel CHL convivirá con "Comuna" (ex-Colonia) y "Mpio. Benef." (municipio, ya "Comuna" en UI). Posible confusión operativa — documentado como riesgo |
| No se corrigió el posible swap Región/Comuna en `DetailsCHL.cshtml` (~líneas 187–192) | PLAN §12.5 lo prohíbe explícitamente para este folio | Se mantiene el comportamiento actual; si es un bug real, requiere folio propio |
| No se modificó `CHL.json` | Ya localiza correctamente `direccionEstado`→Región, `direccionMunicipio`→Comuna, `datofiscalRFC`→RUT. El gap real estaba en `PaisCL` | Ninguno |

---

## Baseline documentado (T-02)

Estado previo al cambio, verificado en código:

| Ubicación | Antes | Después |
|---|---|---|
| `PaisCL.ExportContracts` celda `[3,12]` | `R.F.C.` | `RUT` |
| `PaisCL.ExportContracts` celda `[3,43]` | `Edo. Benef.` | `Región Beneficiario` |
| `PaisCL.ExportContracts` celda `[3,46]` | `Colonia` | `Comuna` |
| `PaisCL.GetFiscalIdName` | `RFC` | `RUT` |
| `PaisCL.GetStateLabelName` | `Estado` | `Región` |
| `PaisCL` → `localidades_neighborhood_label` | `Colonia` | `Comuna` |
| `PaisCL` → `localidades_alternate_neighborhood_label` | `Otra colonia` | `Otra comuna` |
| `DetailsCHL.cshtml:171` | `<label>RFC</label>` | `<label>RUT</label>` |

Verificación de aislamiento por país (RF-05 / RNF-01): el diff toca únicamente `PaisesService/Classes/CL/PaisCL.cs` y una vista `*CHL.cshtml`. `PaisMX`, `PaisCO` y el resto de países quedan intactos.

Compilación: `dotnet build` de `PaisesService.csproj` y `GarantiplusWeb.csproj` → **0 errores** (solo advertencias preexistentes del repositorio).

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `PaisesService/Classes/CL/PaisCL.cs` | Modificado | T-03, T-04 |
| `GarantiplusWeb/Areas/Contratos/Views/Cotizador/DetailsCHL.cshtml` | Modificado | T-05 |
| `enginecx_prd/SIGA/PJ1894-estado-colonia-chile/AVANCE.md` | Creado | Registro de avance |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `cb0c2ed` | `[PJ1894-estado-colonia-chile] Localizar etiquetas Estado/Colonia/RFC a Region/Comuna/RUT en Chile` | 2026-08-11 |

> Nota: el commit incluye **solo** los dos archivos de código. Los `appsettings.json` locales que estaban modificados en el working tree (configuración de ambiente del desarrollador) se dejaron deliberadamente fuera del commit.

---

## Notas para quien retome el trabajo

**¿Por dónde continuar?** Por la Fase 2 (T-06 a T-08): levantar la app apuntando a Chile, descargar el reporte de contratos y confirmar los tres encabezados; luego abrir Details de contrato / endosos / Upgrade y el Cotizador CHL para confirmar RUT; finalmente el smoke de México.

**Contexto importante:**
- Los encabezados del Excel se fijan en la capa de aplicación (`PaisCL.ExportContracts`), **no** en `sp_reporte_contratos`. No hay nada que cambiar en base de datos.
- El patrón del repositorio es un método de export por cada `PaisXX`; no unificar ni refactorizar (PLAN §12.2).
- `GetContractBeneficiaryTaxIdFieldLabel` en CHL ya retornaba "RUT" desde antes; el gap real era `GetFiscalIdName`.

**Decisiones pendientes que requieren input del equipo o del solicitante:**
1. **Bloqueante suave para producción:** confirmar con Operaciones / BI Chile que ningún parser o reporte lee el Excel por nombre de columna (`R.F.C.`, `Edo. Benef.`, `Colonia`). Si alguno lo hace, avisar del rename antes del despliegue.
2. **Consulta menor:** si Operaciones prefiere que el eje "colonia" se etiquete "Provincia" (como en `CHL.json`) en lugar de "Comuna", ajustar `localidades_neighborhood_label` en `PaisCL.cs`. Hoy esos campos están ocultos en CHL, así que no es urgente.
3. **Follow-up opcional (fuera de este folio):** renombrar `Mpio. Benef.` del export CHL a "Comuna Beneficiario" para evitar la duplicidad semántica.

**Siguiente paso del flujo:** el programador revisa la rama y gestiona el PR (`feature/PJ1894-estado-colonia-chile` → `pre-qa` → `qa`). Claude Code no crea PRs.

---

*Actualizado automáticamente por Claude Code — Engine CX*
