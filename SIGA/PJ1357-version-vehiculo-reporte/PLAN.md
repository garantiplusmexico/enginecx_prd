# Plan de Desarrollo — Versión del Vehículo en Reporte de Contratos (PJ1357)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ1357-version-vehiculo-reporte/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + PaisesService) |
| Rama base | `develop` |
| Rama | `feature/PJ1357-version-vehiculo-reporte` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ1357` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | *(pm_plan_desarrollo.id — lo escribe el flujo al registrar el plan)* |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Asegurar que el export Excel de contratos emitidos muestre el **nombre de versión del vehículo** poblado desde la fuente correcta del dominio, en todos los países donde se genera el reporte (MX, CL, CO y demás plazas que usan el mismo SP).

**Hallazgo de análisis (código en `develop`):**
- La columna Excel **«Versión» ya existe** (header en col. 18 MX/CL, col. 25 CO).
- El DTO ya mapea `version_auto` y el reader lo lee del SP.
- El SP `sp_reporte_contratos` expone `version_auto` desde **`veh.version`** (texto libre en `vehiculo`), **sin** `LEFT JOIN` a `version_vehiculo`.
- En CL/CO (y alta con dropdown) el dato vive típicamente en **`vehiculo.id_version` → `version_vehiculo.nombre_version`**, por lo que `veh.version` puede estar vacío y el Excel sale sin versión aunque el contrato sí la tenga en catálogo.

El trabajo real del MVP es **corregir la fuente del dato en el SP** (y en CO el SP hermano `sp_reporte_contratos_facturas`), no inventar una columna nueva en C# salvo que la verificación demuestre lo contrario en algún país.

- **Arquitectura:** modificación sobre monolito existente SIGA Web (EC2 + .NET 8). Sin microservicio nuevo.
- **Stack:** .NET 8 / C#, PostgreSQL, EPPlus ya usado en `PaisesService`.
- **Despliegue:** cambio de SP en BD por país + redeploy SIGA solo si hubiera ajuste C# (poco probable).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Operaciones Chile; revisor técnico Alexis Salvador Herrera Garcia)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada ✅ (completado al generar este plan)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Acceso de lectura/escritura a scripts SQL / BD de QA por país (MX, CL, CO) para desplegar el SP
- [ ] Confirmar en BD de cada plaza que existen `vehiculo.id_version` y `version_vehiculo.nombre_version` (supuesto del PRD)
- [ ] Contrato(s) de prueba en Chile (solicitante) con `id_version` poblado y `vehiculo.version` vacío — para validar el COALESCE
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature aditiva sobre componente existente.

```
[Usuario Admin/Reportes]
  → [ContratosController.Exportar]
    → [IPaisBusinessRules.ExportContracts]  (PaisMX / PaisCL / PaisCO / …)
      → [PostgreSQL: sp_reporte_contratos | sp_reporte_contratos_facturas]
           JOIN vehiculo → modelo_vehiculo → marca_vehiculo
           + LEFT JOIN version_vehiculo (NUEVO)
      → [DTO version_auto] → [Excel columna «Versión»]
```

**Decisión de diseño:**
1. Preferir **solo cambio de SP** manteniendo el alias `version_auto`, para no tocar DTOs ni headers C#.
2. Expresión propuesta (equivalente):
   `COALESCE(NULLIF(TRIM(veh.version), ''), vv.nombre_version)` AS `version_auto`
   con `LEFT JOIN version_vehiculo vv ON vv.id_version = veh.id_version`.
3. Si tras el SP algún país aún no muestra la columna (código divergente), ajustar solo ese `Pais*.ExportContracts` — no refactorizar los demás.

---

## 4. Tareas de desarrollo

### Fase 0 — Diagnóstico y alineación (P1)

- [ ] **T-01** — Confirmar pregunta abierta del PRD: fuente real del dato por país
  - Validar en BD MX/CL/CO: contratos con `id_version` y/o `veh.version`; proporción de cada caso.
  - Confirmar definición: «Versión» = `version_vehiculo.nombre_version` (catálogo), con fallback a `vehiculo.version`.
  - Confirmar representación de ausencia: **celda vacía** (alineado a RF-04 y comportamiento actual del reader).
  - Confirmar encabezado: mantener **«Versión»** (ya usado); no reordenar columnas.
  - Archivos: nota en `PLAN.md` §12 / `AVANCE.md` (sin código aún)
  - Criterio de completitud: respuestas cerradas; sin bloqueos para Fase 1

- [ ] **T-02** — Inventario de SPs y exports afectados
  - Documentar por país: nombre del SP (`sp_reporte_contratos` vs `sp_reporte_contratos_facturas`), versión del script en repo vs BD desplegada, y clase `Pais*`.
  - Países mínimos MVP: **CL (solicitante), MX, CO**. Resto (EC/CR/GT/PA/PE/AR) si comparten el mismo SP script.
  - Archivos a revisar (solo lectura):  
    `GarantiplusWeb/BD/Etiquetas.sql`,  
    `GarantiplusWeb/BD/2025-05-08_hub_chile/*.sql`,  
    `PaisesService/Classes/{MX,CL,CO}/Pais*.cs`
  - Criterio de completitud: lista explícita de SPs a modificar y BDs donde aplicarlos

### Fase 1 — Corrección de fuente en SP + scripts en repo (P1)

- [ ] **T-03** — Actualizar `sp_reporte_contratos` (script canónico MX / genérico)
  - Agregar `LEFT JOIN version_vehiculo` y `COALESCE` para `version_auto`.
  - Archivos a modificar: `GarantiplusWeb/BD/Etiquetas.sql` (y/o script de migración nuevo bajo `GarantiplusWeb/BD/` con fecha, si el equipo versiona cambios así)
  - Criterio de completitud: script listo; `CREATE OR REPLACE` reproducible; alias `version_auto` sin cambio de firma que rompa el reader C#

- [ ] **T-04** — Actualizar scripts Chile del SP en el repo
  - Aplicar el mismo cambio en variantes Chile del SP.
  - Archivos:  
    `GarantiplusWeb/BD/2025-05-08_hub_chile/2025_05_26 Contratos - Listado.sql`,  
    `GarantiplusWeb/BD/2025-05-08_hub_chile/script_hub_chile.sql`  
    (y cualquier copia vigente que el equipo use para deploy CL)
  - Criterio de completitud: scripts CL alineados con T-03

- [ ] **T-05** — Actualizar `sp_reporte_contratos_facturas` (Colombia)
  - El SP **no está versionado en el repo** (solo se invoca desde `PaisCO.ExportContracts`). Extraer definición desde BD CO, aplicar el mismo `COALESCE`/`JOIN`, guardar script en `GarantiplusWeb/BD/` (nuevo archivo fechado) y dejar listo el deploy.
  - Archivos a crear: p. ej. `GarantiplusWeb/BD/YYYY-MM-DD_sp_reporte_contratos_facturas_version.sql`
  - Criterio de completitud: script CO en repo + instrucción de deploy documentada en §12

- [ ] **T-06** — Desplegar SPs en ambiente(s) de prueba (QA / local)
  - Ejecutar `CREATE OR REPLACE` en BD de prueba MX, CL y CO.
  - Criterio de completitud: `\df sp_reporte_contratos*` refleja la nueva definición; query manual de muestra muestra `nombre_version` cuando `veh.version` es null

### Fase 2 — Verificación C# multi-país y no regresión (P1)

- [ ] **T-07** — Verificar exports C# MX / CL / CO (sin cambio si ya mapean)
  - Confirmar headers «Versión» y mapeo `version_auto` en:  
    `PaisesService/Classes/MX/PaisMX.cs`,  
    `PaisesService/Classes/CL/PaisCL.cs`,  
    `PaisesService/Classes/CO/PaisCO.cs`  
    y DTOs `ContractsReportOneTax.cs`, `ContractsReportOneTaxCL.cs`, `ContractsReportManyTaxContract.cs`
  - Solo modificar C# si algún país no expone la columna o el ordinal falta.
  - Criterio de completitud: checklist país→columna→propiedad documentado; diff C# vacío o mínimo justificado

- [ ] **T-08** — Prueba funcional del export Excel
  - Generar export desde UI Contratos (IndexCHL / IndexMEX / IndexCOL) con filtros acotados.
  - Casos: (a) con `nombre_version` vía `id_version` y `veh.version` vacío → celda con nombre; (b) con `veh.version` texto → celda con ese texto; (c) sin ambos → celda vacía; (d) columnas vecinas (Marca/Modelo/H.P. o Año) intactas.
  - Criterio de completitud: evidencia en AVANCE (captura o nota) de los 3 países MVP; RF-01..RF-04 cumplidos

- [ ] **T-09** — Smoke de no regresión
  - Verificar que el export abre en Excel, no rompe filas, y el tiempo no degrada de forma perceptible (RNF-02).
  - Criterio de completitud: OK documentado; sin incidencias abiertas P1

### Fase 3 — Cierre y handoff

- [ ] **T-10** — Documentar deploy a producción por país
  - Orden sugerido: QA → validación Operaciones Chile → deploy SP en prod CL/MX/CO (y restantes si aplica).
  - Incluir rollback: script con definición previa del SP.
  - Archivos: nota en `AVANCE.md` / §12
  - Criterio de completitud: runbook corto listo para el programador/ops

- [ ] **T-11** — Cierre del plan
  - Actualizar AVANCE, criterios de aceptación marcados, commit final en rama feature.
  - Criterio de completitud: plan en estado Completado a nivel P1

---

## 5. Cambios en base de datos

| Objeto | Tipo de cambio | Descripción |
|---|---|---|
| `sp_reporte_contratos` | Modificación (CREATE OR REPLACE) | `LEFT JOIN version_vehiculo`; `version_auto` = COALESCE texto libre / `nombre_version` |
| `sp_reporte_contratos_facturas` (CO) | Modificación | Mismo criterio de versión |
| Tablas `vehiculo` / `version_vehiculo` | Ninguno | Solo lectura; no hay migración de esquema ni backfill |

> No hay cambio de esquema. El riesgo es solo de definición de función en PostgreSQL por plaza.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `~/Contratos/Contratos/Exportar` | Sin cambio de contrato HTTP; mismo endpoint, datos enriquecidos vía SP | Sin cambio de firma |

No hay API REST nueva en `gp_3.0_siga_api`.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No aplica | — |

---

## 8. Consideraciones de seguridad

- Solo lectura adicional sobre catálogo `version_vehiculo`; sin escritura.
- El export sigue sujeto a la autorización existente del módulo Contratos (roles actuales); no se amplían permisos.
- No hay secrets nuevos.
- Scripts SQL: usar solo `CREATE OR REPLACE FUNCTION` versionado; no ejecutar DDL destructivo.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos. SIGA Web permanece en EC2.
- El cambio crítico es **deploy del SP en RDS/PostgreSQL de cada país**.
- Redeploy de la app solo si T-07 obliga a tocar C#.

---

## 10. Criterios de aceptación

- [ ] El Excel de contratos emitidos incluye la columna **«Versión»** en MX, CL y CO (RF-01, RF-02).
- [ ] El valor proviene del SP (`version_auto`), priorizando `vehiculo.version` y, si falta, `version_vehiculo.nombre_version` (RF-03, RNF-01).
- [ ] Contratos sin versión muestran celda vacía y el export no falla (RF-04).
- [ ] Columnas existentes y orden relativo de Marca/Modelo/restantes no se alteran de forma regresiva (RNF-02).
- [ ] Scripts del SP quedan versionados en el repo para MX/CL/CO (RNF-03).
- [ ] Operaciones Chile puede validar un export de muestra con versión poblada desde catálogo.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| PRD pide “agregar columna” pero ya existe; expectativa de negocio distinta (p. ej. otra columna o otro reporte) | Media | Medio | T-01: validar con solicitante/revisor que el problema es dato vacío vs columna ausente |
| `sp_reporte_contratos_facturas` (CO) no versionado / divergente | Alta | Medio | T-05: extraer de BD real antes de editar |
| `id_version` nulo y `veh.version` vacío → celdas vacías (dato origen) | Media | Bajo | RF-04 acepta vacío; fuera de alcance poblar histórico |
| Firma del SP cambia y rompe ordinales del reader Npgsql | Baja | Alto | Mantener alias `version_auto` y orden de columnas RETURNS TABLE |
| Scripts en repo desactualizados vs BD prod | Media | Medio | Comparar definición live antes de REPLACE; guardar rollback |

---

## 12. Notas para el programador

1. **No confundir** el área `Reportes` (producción/explotación) con este export: vive en **Contratos → Exportar** vía `IPaisBusinessRules.ExportContracts`.
2. Preguntas abiertas del PRD (§14) — resolución propuesta en este plan:
   - Disponibilidad: el SP **sí** expone `version_auto`, pero desde `veh.version` incompleto → ajustar JOIN/COALESCE.
   - Definición: catálogo `nombre_version` (+ fallback texto libre).
   - Ubicación/encabezado: mantener columna y título **«Versión»** actuales.
   - Países: MVP CL + MX + CO; resto si comparten SP.
   - Sin versión: celda vacía.
3. Si Operaciones insiste en que “no ven la columna”, capturar el Excel real de prod antes de T-03: podría ser archivo antiguo, otro reporte, o filtro de columnas en Excel.
4. Coding guidelines: código nuevo en inglés; mensajes UI/headers de usuario pueden permanecer en español (ya existentes).
5. No refactorizar `PaisCL`/`PaisMX` más allá de lo necesario (copy-paste legacy a propósito).

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Diagnóstico (P1)** | Fuente del dato, inventario SP/exports | T-01 a T-02 | 0.5 – 1 día | |
| **Fase 1 — SP + scripts (P1)** | COALESCE/JOIN, scripts MX/CL/CO, deploy QA | T-03 a T-06 | 1 – 2 días | |
| **Fase 2 — Verificación (P1)** | Check C#, export Excel 3 países, no regresión | T-07 a T-09 | 0.5 – 1 día | |
| **Fase 3 — Cierre** | Runbook deploy/rollback, cierre AVANCE | T-10 a T-11 | 0.5 día | |
| **Total proyecto** | | 11 tareas | **~2.5 – 4.5 días hábiles (≈ 0.5 – 1 semana)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-09 | **~2 – 4 días hábiles** | — |

> **Notas sobre la tabla:**
> - El PRD declara MVP autocontenido sin fases posteriores de producto; P1 = alcance completo útil.
> - La complejidad real está en **BD multi-país** (sobre todo CO sin script en repo), no en C#.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite. Con ~2.5–4.5 días hábiles el alcance completo cabe en una semana de un desarrollador. Si solo hay ventana de 1–2 días, priorizar **CL (solicitante) + script SP** (T-01, T-03, T-04, T-06, T-08 acotado a CL) y diferir CO/MX al día siguiente.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo normal*
