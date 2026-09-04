# Registro de Avance — Versión del Vehículo en Reporte de Contratos (PJ1357)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ1357-version-vehiculo-reporte` |
| Repositorio | `gp_4.0_siga` (base: `develop`) |
| Responsable actual | Javier Antonio Oropeza |
| Última actualización | 2026-08-12 |
| Estado general | 🟡 En progreso — código y scripts listos; falta ejecución en BD |

---

## Resumen de estado

Se confirmó el hallazgo del plan: la columna «Versión» ya existe en los tres
países del MVP y el C# ya mapea `version_auto`; el problema es únicamente la
fuente del dato en el SP (`veh.version`, texto libre). Se generaron los scripts
SQL versionados con el `COALESCE` + `LEFT JOIN version_vehiculo` para la
definición genérica (MX y las demás plazas) y para la variante Chile, más el
procedimiento de extracción/parcheo para Colombia (SP no versionado en el repo).

**No se requirió ningún cambio en C#** — se verificó el mapeo país por país.

Queda pendiente todo lo que exige acceso a base de datos: deploy en QA,
extracción de la definición de Colombia y prueba funcional del Excel.

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Confirmar fuente real del dato por país | Claude Code | 2026-08-12 | Confirmado por código: `vehiculo.id_version` está mapeado en `DataAccess/AjustesHub/vehiculo.cs` (no `[NotMapped]`) y las vistas de alta MEX/CHL/COL usan el select `vehiculo.id_version`. Definición: catálogo `nombre_version` con fallback a texto libre; ausencia = celda vacía; encabezado «Versión» sin reordenar columnas. La verificación cuantitativa en BD quedó en `00_verificacion_previa.sql` |
| T-02 | Inventario de SPs y exports afectados | Claude Code | 2026-08-12 | Ver tabla «Inventario» abajo |
| T-03 | Actualizar `sp_reporte_contratos` (genérico/MX) | Claude Code | 2026-08-12 | `01_sp_reporte_contratos_version.sql` |
| T-04 | Actualizar variante Chile del SP | Claude Code | 2026-08-12 | `02_sp_reporte_contratos_version_chile.sql`. Se verificó que las dos copias en el repo (`2025_05_26 Contratos - Listado.sql` y `script_hub_chile.sql`) son idénticas → un solo script |
| T-07 | Verificar exports C# MX / CL / CO | Claude Code | 2026-08-12 | **Sin cambios en C#.** Ver tabla «Verificación C#» abajo |
| T-10 | Documentar deploy y rollback por país | Claude Code | 2026-08-12 | `GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/README.txt` |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| T-05 | `sp_reporte_contratos_facturas` (Colombia) | Javier Antonio Oropeza | 2026-08-12 | Script con el procedimiento de extracción + los dos cambios exactos ya está en el repo (`03_...colombia.sql`). Falta pegar la definición real extraída de la BD de CO |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-06 | Desplegar SPs en QA (MX, CL, CO) | Acceso a BD de QA por país |
| T-08 | Prueba funcional del export Excel (3 países) | T-06 |
| T-09 | Smoke de no regresión del export | T-06 |
| T-11 | Cierre del plan | T-08, T-09 |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-05 (parcial) | Definición de `sp_reporte_contratos_facturas` de Colombia | El SP no está versionado en el repo; solo existe en la BD de CO y esta sesión no tiene acceso a base de datos | Programador / DBA con acceso a la BD de Colombia — el paso a paso está en `03_sp_reporte_contratos_facturas_colombia.sql` |
| T-06, T-08, T-09 | Deploy y prueba funcional | Requieren BD de QA y sesión de la UI de Contratos | Programador |

---

## Inventario de SPs y exports (T-02)

| País | Clase | SP invocado | Columna Excel | Script en repo |
|---|---|---|---|---|
| MX | `PaisesService/Classes/MX/PaisMX.cs` | `sp_reporte_contratos` | col. 18 «Versión» | ✅ `01_...` |
| CL | `PaisesService/Classes/CL/PaisCL.cs` | `sp_reporte_contratos` (variante CL) | col. 18 «Versión» | ✅ `02_...` |
| CO | `PaisesService/Classes/CO/PaisCO.cs` | `sp_reporte_contratos_facturas` | col. 25 «Versión» | ⚠️ `03_...` (pendiente extraer de BD) |
| AR, CR, EC, GT, PA, PE | `PaisesService/Classes/{AR,CR,EC,GT,PA,PE}/Pais*.cs` | `sp_reporte_contratos` | «Versión» | ✅ `01_...` (misma definición genérica) |

Base de las definiciones tomadas del repo:
`GarantiplusWeb/BD/Etiquetas.sql` (genérica, la más reciente: incluye promociones
y upgrades) y `GarantiplusWeb/BD/2025-05-08_hub_chile/2025_05_26 Contratos - Listado.sql` (CL).

---

## Verificación C# (T-07)

| País | Header «Versión» | Mapeo `version_auto` | DTO | Cambio requerido |
|---|---|---|---|---|
| MX | `PaisMX.cs:1212` (col. 18) | `PaisMX.cs:1421` | `ContractsReportOneTax.cs:26` | Ninguno |
| CL | `PaisCL.cs:1242` (col. 18) | `PaisCL.cs:1363` | `ContractsReportOneTaxCL.cs:26` | Ninguno |
| CO | `PaisCO.cs:1281` (col. 25) | `PaisCO.cs:1395` | `ContractsReportManyTaxContract.cs:33` | Ninguno |

Los tres leen la columna por nombre (`GetOrdinal("version_auto")`) y devuelven
`string.Empty` cuando viene NULL, lo que cumple RF-04 (celda vacía) sin tocar
código. **Diff de C# vacío**, como anticipaba el plan.

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Publicar el cambio como carpeta fechada nueva (`GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/`) en lugar de editar `Etiquetas.sql` y los scripts de Chile | Es la convención vigente del repo: los scripts existentes vienen de la carga inicial del monorepo y nunca se editan; los cambios posteriores al SP se publicaron como script nuevo (precedente: `2024-10-24_promociones/03Querysdespuesdetablas.sql`, que ya redefinía este mismo SP) | Los archivos `Etiquetas.sql` y los de `2025-05-08_hub_chile/` quedan intactos. Desviación respecto a la redacción literal de T-03/T-04 del plan |
| Agregar cast explícito `::varchar` al `COALESCE` | `TRIM()` devuelve `text` y `RETURN QUERY EXECUTE` valida el tipo contra el `character varying` declarado en `RETURNS TABLE`; sin el cast el SP falla en ejecución | Evita un error de tipos en el deploy |
| Usar `CREATE OR REPLACE` sin `DROP FUNCTION` previo | La firma no cambia (a diferencia de `Etiquetas.sql`, que sí dropea porque cambió el `RETURNS TABLE`) | Deploy sin ventana en la que el SP no exista; rollback inmediato |
| Agregar `00_verificacion_previa.sql` (no estaba en el plan) | El `LEFT JOIN version_vehiculo` falla en tiempo de ejecución si alguna plaza no tiene `vehiculo.id_version` o el catálogo; también cubre la parte cuantitativa de T-01 y captura la definición previa como rollback | Convierte T-01/T-06 en un procedimiento reproducible por plaza |
| Los scripts genéricos cubren también AR, CR, EC, GT, PA, PE | Todas invocan `sp_reporte_contratos` con la misma firma | El MVP (CL, MX, CO) no cambia; el resto puede aplicarse en la misma ventana |
| El runbook se publicó como `README.txt` y no como `README.md` | El `.gitignore` de `gp_4.0_siga` ignora `*.md` en todo el repo (línea 5), así que un `.md` no se habría versionado | El runbook queda dentro del repo junto a los scripts |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/00_verificacion_previa.sql` | Creado | T-01, T-06 |
| `GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/01_sp_reporte_contratos_version.sql` | Creado | T-03 |
| `GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/02_sp_reporte_contratos_version_chile.sql` | Creado | T-04 |
| `GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/03_sp_reporte_contratos_facturas_colombia.sql` | Creado | T-05 |
| `GarantiplusWeb/BD/2026-08-12_version_vehiculo_reporte/README.txt` | Creado | T-10 |

Sin cambios en C# (T-07).

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `cf26671` | `[PJ1357-version-vehiculo-reporte] Poblar la version del vehiculo en el reporte de contratos desde el catalogo` | 2026-08-12 |

---

## Notas para quien retome el trabajo

**Por dónde continuar:**

1. Ejecutar `00_verificacion_previa.sql` en QA de CL, MX y CO. Guardar la salida
   de `pg_get_functiondef` — es el rollback.
2. Aplicar `01_` (MX) y `02_` (CL) en QA.
3. Colombia: seguir el paso a paso de `03_...colombia.sql` para extraer la
   definición viva, aplicarle los dos cambios y **guardar el script completo en
   ese mismo archivo** antes de commitear (es lo que cierra T-05 y RNF-03).
4. Probar el export desde la UI (IndexCHL / IndexMEX / IndexCOL) con los 4 casos
   del README y dejar evidencia aquí (T-08, T-09).

**Contexto importante:**

- El cambio es **solo de base de datos**. No hay redeploy de la aplicación.
- La prioridad del `COALESCE` es texto libre primero, catálogo después, tal como
  lo fijó el plan (§3 y criterio de aceptación §10). Si Operaciones Chile
  esperaba lo contrario (catálogo siempre gana), es un cambio de una línea en los
  tres scripts — confirmarlo en la validación de T-08.
- No confundir con el área `Reportes`: este export vive en Contratos → Exportar
  vía `IPaisBusinessRules.ExportContracts`.

**Decisiones pendientes de input:**

- Confirmar con el solicitante que el problema reportado era la celda vacía y no
  la ausencia de la columna (riesgo #1 del plan, §11). La consulta 3 de
  `00_verificacion_previa.sql` da la evidencia cuantitativa para esa charla.

---

*Actualizado automáticamente por Claude Code — Engine CX*
