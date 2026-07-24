# Plan de Desarrollo — Estado Colonia Chile (PJ1894)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ1894-estado-colonia-chile/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + PaisesService) |
| Rama base | `develop` |
| Rama | `feature/PJ1894-estado-colonia-chile` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ1894` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | *(se asigna al autorizar commit)* |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Ajuste de **nomenclatura de presentación solo para Chile (`PaisCL`)**: renombrar etiquetas mexicanas en el export Excel de contratos y alinear helpers/vistas CHL que aún muestran "RFC" / "Estado" / "Colonia", sin tocar datos, SP ni MX/CO.

- **Arquitectura:** modificación puntual sobre monolito SIGA Web (EC2 + .NET 8) y reglas de país en `PaisesService` (`PaisCL`). Sin microservicio nuevo ni API.
- **Stack:** .NET 8 / C#, ClosedXML/EPPlus Excel export, Razor Views, recursos JSON de localización (`CHL.json`).
- **Sin cambios** en esquema BD, `sp_reporte_contratos` (solo alimenta datos; los encabezados Excel se fijan en C#), ni en `PaisMX` / `PaisCO`.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en código |
|---|---|
| ¿Headers del SP o de la app? | **Capa de aplicación.** `PaisCL.ExportContracts` asigna `worksheet.Cells[3, n].Value` a mano. El SP solo devuelve columnas técnicas (`rfc`, `nombre_estado`, `colonia`, …). |
| ¿RFC→RUT también en vistas? | **Sí conviene.** `CHL.json` ya tiene `datofiscalRFC: "RUT"`, pero `PaisCL.GetFiscalIdName` aún retorna `"RFC"` y alimenta `ViewBag.FiscalIdName` (Details, endosos, Upgrade, etc.). Cotizador `DetailsCHL.cshtml` hardcodea `"RFC"`. |
| ¿Qué pantallas? | Vistas que usan `Localizer` ya están bien vía `CHL.json` (`direccionEstado`→Región, `direccionMunicipio`→Comuna, `datofiscalRFC`→RUT). Gaps: export Excel CHL, `GetFiscalIdName`, `GetStateLabelName`, `localidades_neighborhood_label`, label hardcodeada en `DetailsCHL.cshtml`. |
| ¿Consumidores downstream? | No hay evidencia en repo de parsers por nombre de columna del Excel CHL. Riesgo residual a validar con Operaciones (supuesto del PRD: sin consumidores externos). |
| Fecha objetivo | No fijada en el PRD. |

**Mapeo concreto del export CHL hoy → objetivo PRD:**

| Columna Excel hoy (`PaisCL`) | Objetivo PRD |
|---|---|
| `R.F.C.` (col 12) | `RUT` |
| `Edo. Benef.` (col 43) | `Región Beneficiario` |
| `Colonia` (col 46) | `Comuna` |

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local / instancia Chile para exportar contratos y revisar vistas
- [ ] No se requieren secrets ni variables de entorno nuevas
- [ ] Confirmación de Operaciones Chile sobre posible impacto a parsers que lean el Excel por nombre de columna (ver §12)

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): cambio de presentación localizado en `PaisCL`, sin desplegar servicio nuevo.

```
[Admin Chile]
  → ContratosController.Exportar
      → _paisBaseHub.GetCountry("CHL").ExportContracts(...)
          → PaisCL: encabezados Excel localizados
          → sp_reporte_contratos (datos sin cambio)
  → Vistas contratos / endosos / cotizador
      → Localizer(CHL.json) + ViewBag.FiscalIdName (GetFiscalIdName)
      → AdditionalContractBeneficiaryVehicleElements (labels localidades)
```

**Decisión de diseño:**

1. **Centralizar en `PaisCL`** los strings de país (RNF-03): `GetFiscalIdName` → `"RUT"`, `GetStateLabelName` → `"Región"`, y encabezados del export. No hardcodear ifs de país en controladores compartidos.
2. **No modificar el SP** ni aliases SQL: los nombres de columna del resultset son internos; solo cambian celdas de encabezado Excel.
3. **No tocar `PaisMX` / `PaisCO` / resources MEX-COL** (RF-05 / RNF-01).
4. **`localidades_neighborhood_label`:** hoy es `"Colonia"` en `PaisCL`, mientras `CHL.json` usa `direccionColonia: "Provincia"` y `direccionMunicipio: "Comuna"`. El PRD pide Colonia→**Comuna**. Como `localidades_show_colonia_fields = false` en CHL, el impacto en UI de alta es bajo; aun así se alinea el label a **Comuna** según PRD. Si Operaciones prefiere mantener "Provincia" en ese eje, documentar excepción en AVANCE.
5. **Fuera de MVP:** renombrar `Mpio. Benef.` del export (no está en el PRD). Seguirá diciendo "Mpio. Benef." aunque en UI el municipio ya es "Comuna". Follow-up opcional.

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b feature/PJ1894-estado-colonia-chile`
  - Archivos: N/A
  - Criterio de completitud: rama local basada en `develop` actualizado

- [ ] **T-02** — Baseline: export y vistas CHL actuales
  - Descargar reporte de contratos en ambiente CHL y anotar encabezados de R.F.C. / Edo. Benef. / Colonia
  - Abrir Details de contrato y Cotizador DetailsCHL: anotar dónde aún aparece "RFC"
  - Archivos: nota en `AVANCE.md` (cuando exista)
  - Criterio de completitud: baseline documentado; sin bloqueos para Fase 1

### Fase 1 — Etiquetas PaisCL + export + vistas (P1)

- [ ] **T-03** — Renombrar encabezados del export de contratos en `PaisCL`
  - Archivos a modificar: `PaisesService/Classes/CL/PaisCL.cs` (método `ExportContracts`)
  - Cambios:
    - `worksheet.Cells[3, 12].Value = "RUT";` (antes `"R.F.C."`)
    - `worksheet.Cells[3, 43].Value = "Región Beneficiario";` (antes `"Edo. Benef."`)
    - `worksheet.Cells[3, 46].Value = "Comuna";` (antes `"Colonia"`)
  - Criterio de completitud: RF-01, RF-02, RF-03; el Excel CHL muestra los tres nuevos encabezados

- [ ] **T-04** — Alinear helpers de nomenclatura en `PaisCL`
  - Archivos a modificar: `PaisesService/Classes/CL/PaisCL.cs`
  - Cambios:
    - `GetFiscalIdName` → return `"RUT"` (hoy `"RFC"`)
    - `GetStateLabelName` → return `"Región"` (hoy `"Estado"`)
    - En `GetAdditionalContractBeneficiaryVehicleElements`: `localidades_neighborhood_label = "Comuna"` (hoy `"Colonia"`); `localidades_alternate_neighborhood_label` coherente (p. ej. `"Otra comuna"`)
  - Criterio de completitud: `ViewBag.FiscalIdName` en vistas compartidas muestra RUT en CHL; MX/CO sin cambio

- [ ] **T-05** — Corregir label hardcodeada en Cotizador CHL
  - Archivos a modificar: `GarantiplusWeb/Areas/Contratos/Views/Cotizador/DetailsCHL.cshtml`
  - Acción: cambiar `<label>RFC</label>` a `RUT` (o `@Localizer["datofiscalRFC"]` / `GetContractBeneficiaryTaxIdFieldLabel` si el partial ya tiene Localizer)
  - Criterio de completitud: RF-04 parcial; pantalla Cotizador CHL muestra RUT
  - Nota: **no** intercambiar valores Región/Comuna en esa vista aunque hoy parezcan invertidos en el binding — fuera de alcance del PRD (solo etiquetas pedidas)

### Fase 2 — Pruebas funcionales y cierre (P1)

- [ ] **T-06** — Prueba export CHL
  - Generar Excel de contratos en Chile; verificar encabezados Región Beneficiario, Comuna, RUT
  - Criterio de completitud: métrica “0 reportes CHL con Estado Beneficiario/Colonia/RFC (o R.F.C./Edo. Benef.)”

- [ ] **T-07** — Prueba vistas CHL
  - Details contrato / endosos / Upgrade: `FiscalIdName` = RUT
  - Cotizador DetailsCHL: label RUT
  - Criterio de completitud: RF-04 verificado en pantallas de contratos afectadas

- [ ] **T-08** — Smoke no-regresión MX (y COL si hay ambiente)
  - Export contratos MX: sigue "R.F.C." / "Estado" / "Colonia" (o equivalentes actuales de `PaisMX`)
  - Vistas MX: Localizer y FiscalIdName sin cambio
  - Criterio de completitud: RF-05 / RNF-01

- [ ] **T-09** — Commit y push de la feature
  - Mensaje al estilo Engine: `[PJ1894-estado-colonia-chile] Localizar etiquetas Estado/Colonia/RFC a Región/Comuna/RUT en Chile`
  - Criterio de completitud: cambios en rama remota; listo para PR del programador hacia `pre-qa`

---

## 5. Cambios en base de datos

| Tabla / objeto | Tipo de cambio | Descripción |
|---|---|---|
| `sp_reporte_contratos` | Ninguno | Solo provee datos; encabezados no salen del SP |
| Tablas de contratos / beneficiario | Ninguno | Sin alteración de columnas ni datos |

No hay migraciones EF ni scripts SQL.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | Sin endpoints nuevos. Se reutiliza `Contratos/Contratos/Exportar` → `PaisCL.ExportContracts` | Sin cambio de contrato HTTP; solo contenido del archivo |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No aplica | — |

Solo se requiere ambiente con `HubBaseCountryCode` / proyecto Chile para validar.

---

## 8. Consideraciones de seguridad

- Sin cambios de IAM, roles ni políticas.
- No se exponen secrets nuevos.
- Cambio solo de presentación; no altera lectura/escritura de PII más allá del nombre visible de columna en el Excel.

---

## 9. Consideraciones de infraestructura

- Sin recursos AWS nuevos. Despliegue como cualquier cambio de SIGA Web en EC2 (consola Garanti Chile, `sa-east-1`).
- Costo incremental: nulo.

---

## 10. Criterios de aceptación

- [ ] Export Excel CHL muestra **Región Beneficiario** donde antes decía Edo. Benef. / Estado Beneficiario (RF-01)
- [ ] Export Excel CHL muestra **Comuna** donde antes decía Colonia (RF-02)
- [ ] Export Excel CHL muestra **RUT** donde antes decía R.F.C. / RFC (RF-03)
- [ ] Vistas CHL de contratos afectadas muestran Región/Comuna/RUT según corresponda (RF-04)
- [ ] Exports y vistas MX/CO sin cambio de nomenclatura (RF-05, RNF-01)
- [ ] Sin cambios a datos, modelo ni SP (RNF-02)
- [ ] Strings de país centralizados en `PaisCL` / resources CHL (RNF-03)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Parsers/BI que lean el Excel por nombre de columna (`R.F.C.`, `Colonia`, `Edo. Benef.`) | Media | Alto | Confirmar con Operaciones/BI Chile antes de desplegar a prod; avisar del rename |
| Duplicidad semántica: export tendrá "Comuna" (ex-Colonia) y "Mpio. Benef." (municipio, ya "Comuna" en UI) | Media | Bajo (confusión operativa) | Documentar en §12; follow-up opcional para renombrar Mpio. Benef. |
| Desalineación `CHL.json` (`direccionColonia` = Provincia) vs `localidades_neighborhood_label` = Comuna | Baja | Bajo | Campos de colonia ocultos en CHL (`show_colonia_fields = false`); validar con solicitante si prefieren Provincia |
| Tocar export genérico en `ContratosController` (AMECAH) por error | Baja | Alto (afecta otros países) | Solo editar `PaisesService/Classes/CL/PaisCL.cs` |

---

## 12. Notas para el programador

1. **Respuestas a preguntas abiertas del PRD** — ver tabla en §1.
2. **No refactorizar** el export compartido ni unificar headers entre países; el patrón ya es un método por `PaisXX`.
3. **`GetContractBeneficiaryTaxIdFieldLabel`** en CHL ya retorna `"RUT"`; el gap real de vistas es `GetFiscalIdName` → `ViewBag.FiscalIdName`.
4. **`CHL.json`** ya localiza la mayoría de labels de UI; no hace falta cambiarlo para el MVP salvo que se decida alinear `direccionColonia` (hoy Provincia) con el PRD (Comuna).
5. **Cotizador `DetailsCHL`:** hay un posible swap de valores Región/Comuna en el markup (líneas ~187–192); **no corregir en este folio** salvo pedido explícito — el PRD es solo renombre de etiquetas listadas.
6. El programador gestiona el PR (`feature/*` → `pre-qa` → `qa`); Claude Code no crea PRs.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y rama (P1)** | Branch + baseline export/vistas CHL | T-01 a T-02 | 0.25 – 0.5 días | |
| **Fase 1 — Etiquetas + export + vista (P1)** | Headers Excel, helpers PaisCL, DetailsCHL | T-03 a T-05 | 0.25 – 0.5 días | |
| **Fase 2 — Pruebas y cierre (P1)** | Export CHL, vistas CHL, smoke MX/CO, commit | T-06 a T-09 | 0.25 – 0.5 días | |
| **Total proyecto (P1)** | | 9 tareas | **~0.75 – 1.5 días hábiles (≈ &lt; 1 semana)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-09 | **~0.75 – 1.5 días hábiles** | — |

> **Notas sobre la tabla:**
> - Todo el alcance del PRD es P1 (MVP de presentación). No hay P2/P3 en este folio.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite. Con ~0.75–1.5 días hábiles el cambio cabe en cualquier sprint corto. No se requiere segundo desarrollador ni recorte de alcance. El único bloqueo externo posible es la confirmación de BI/Operaciones sobre parsers del Excel.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
