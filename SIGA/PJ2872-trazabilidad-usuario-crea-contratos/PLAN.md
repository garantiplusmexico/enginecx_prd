# Plan de Desarrollo — Trazabilidad de usuario que crea contratos (PJ2872)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ2872-trazabilidad-usuario-crea-contratos/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ2872-trazabilidad-usuario-crea-contratos` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ2872` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | *(pendiente de registro tras autorización)* |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Exponer el campo ya existente `contrato.registra_contrato` (login Identity guardado al crear la garantía) como **"Usuario creador"** en las superficies de consulta del MVP, **sin capturar, calcular ni alterar** flujos de creación.

- **Arquitectura:** modificación puntual sobre monolito SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). Sin microservicio nuevo, sin API nueva, sin migración de BD.
- **Stack:** .NET 8 / C#, Razor Views, SQL inline Npgsql (Producción), EPPlus (Excel), PostgreSQL (solo lectura del campo).
- **Alcance de código (P1):** reporte Producción (query + modelo + datagrid + Excel) + pantalla `Details` de contrato. Código compartido → MX/CO/CL con un solo despliegue por país.
- **Explotación (hallazgo crítico):** el reporte actual es de **KPIs agregados** (primas, importes, % maduración), **no** un listado por contrato. No hay columna natural donde colgar "Usuario creador" sin rediseñar el reporte. Queda como **decisión de alcance** (ver §3 y Fase 2).

**Hallazgos técnicos (cierran preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en código |
|---|---|
| Inventario Producción / Explotación / SPs | **Producción** y **Explotación** usan SQL **inline** en controllers (`ProduccionController.FiltraResultados`, `ExplotacionController.DatosReporte*`). **No hay SP** que alimentar para estos dos reportes. |
| ¿`registra_contrato` ya se selecciona? | En Producción/Explotación: **no**. En detalle: la entidad EF **sí** trae el campo; la vista **no** lo pinta. |
| Formato del dato | Es el **username** Identity (`VentasBusinessRules` asigna `registra_contrato = username`). En Excel de listado contratos MX/CL ya sale como **"Usuario registra"**. |
| Naming MX/CO vs CL | Listado Excel contratos ya usa **"Usuario registra"** (MX/CL). COL no lo incluye en `sp_reporte_contratos_facturas`. El PRD pide etiqueta **"Usuario creador"** en las superficies nuevas. |
| `usuario_creador` vs creador del contrato | **Corrección al PRD RF-07:** la tabla `usuario_creador` **no** filtra por quien registró el contrato; solo limita combos de gerentes/grupos para roles Auditor / Gestor de Países. El valor a mostrar es **`contrato.registra_contrato`**. |
| Export Excel Producción | La acción POST del controller **sí** genera Excel (EPPlus), pero en `Produccion/Index.cshtml` el branch que hacía `frm_filtros.submit()` cuando `salida=2` está **comentado**; `getReport()` solo recarga el datagrid. Hay que **reactivar** el camino Excel al añadir la columna. |
| Export Excel Explotación | `ExplotacionController.Exportar` está **comentado** (no operativo). |
| Chile "Usuario registra" | Ya existe en **Excel del listado de contratos** (`PaisCL.ExportContracts` / `sp_reporte_contratos`), **no** en Producción, Explotación ni Details. |

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local con datos de contratos que tengan `registra_contrato` poblado (y al menos uno vacío para RF-08)
- [ ] **Decisión de negocio sobre Explotación** (ver §3 / T-02) antes de implementar Fase 2
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de presentación sobre componentes existentes.

```
[Operaciones / Auditoría]
  → Reportes/Produccion (SQL inline + datagrid + Excel EPPlus)
      → SELECT c.registra_contrato  →  columna "Usuario creador"
  → Contratos/Details.cshtml
      → Model.registra_contrato (ya cargado por EF)
  → Reportes/Explotacion  ⚠ hoy solo agregados
      → (opción A) fuera de alcance MVP / equivalencia vía Producción+Details
      → (opción B) rediseño: listado detalle por contrato (alcance ampliado)
  → PostgreSQL.contrato.registra_contrato  (sin escritura nueva)
```

**Decisiones de diseño (P1):**

1. **Solo lectura/presentación** del valor tal cual en BD (RNF-03). Vacío → celda/campo vacío, sin error (RF-08). Sin "N/D" salvo que negocio lo pida después.
2. **Etiqueta UI:** usar **"Usuario creador"** en Producción y Details (según PRD). No unificar a la fuerza con "Usuario registra" del Excel de listado (fuera de alcance naming).
3. **Sin SP nuevos** para Producción. Ampliar SELECT + GROUP BY existentes.
4. **Multi-país:** el código de `GarantiplusWeb/Areas/Reportes` y `Areas/Contratos` es compartido; un cambio cubre MX/CO/CL al desplegar en cada instancia.
5. **No tocar** flujo de creación ni `VentasBusinessRules` salvo hallazgo de no-población (fuera de MVP; riesgo documentado).

**Explotación — opciones (elegir en T-02):**

| Opción | Qué implica | Recomendación |
|---|---|---|
| **A — Equivalencia MVP** | Declarar Explotación fuera de alcance del MVP; la trazabilidad por contrato queda cubierta por Producción + Details (+ Excel listado contratos ya existente en MX/CL). Actualizar criterio RF-02/RF-03 del PRD. | **Recomendada** (mínimo cambio, alinea con la UI real) |
| **B — Rediseño Explotación** | Añadir sección/listado por contrato con `registra_contrato` (y posiblemente reactivar export). Es feature nueva, no “añadir columna”. | Solo si Operaciones insiste; suma ~2–4 días |

**Fuera de alcance confirmado (salvo follow-up):** backfill históricos, edición del creador, resolución a nombre completo, unificación naming, paridad COL en `sp_reporte_contratos_facturas` (opcional P2).

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación, rama y decisión Explotación (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b feature/PJ2872-trazabilidad-usuario-crea-contratos`
  - Criterio de completitud: rama local basada en `develop` actualizado

- [ ] **T-02** — Confirmar con solicitante/Operaciones el alcance de **Explotación** (opción A vs B de §3)
  - Adjuntar captura o descripción: Explotación = tablas de totales, no grid por contrato
  - Registrar decisión en `AVANCE.md`
  - Criterio de completitud: decisión A o B documentada; si es A, Fase 2 se marca N/A

- [ ] **T-03** — Baseline de datos: muestrear contratos con y sin `registra_contrato` en el ambiente de prueba
  - Criterio de completitud: IDs de ejemplo anotados para RF-08 y pruebas de Fase 3

### Fase 1 — Producción + Detalle contrato (P1)

- [ ] **T-04** — Extender modelo `ReporteProduccion` con propiedad del creador
  - Archivos: `GarantiplusWeb/Areas/Reportes/Models/ReporteProduccion.cs`
  - Añadir p. ej. `public string registra_contrato { get; set; }` (o nombre alineado al binding del datagrid)
  - Criterio de completitud: propiedad disponible para mapear desde el reader

- [ ] **T-05** — Incluir `c.registra_contrato` en SQL de `FiltraResultados` (SELECT + GROUP BY) y mapear en el reader
  - Archivos: `GarantiplusWeb/Areas/Reportes/Controllers/ProduccionController.cs`
  - Cuidar índices de columnas del `NpgsqlDataReader` al insertar el campo
  - Criterio de completitud: la consulta lista el valor (o vacío) por fila sin error SQL

- [ ] **T-06** — Columna "Usuario creador" en datagrid / headers de Producción
  - Archivos: `GarantiplusWeb/Areas/Reportes/Views/Produccion/Index.cshtml`
  - Actualizar atributos `columns` / `header` del tag helper de listado y cualquier tabla/JS columns alineada
  - Criterio de completitud: la grilla muestra la columna nueva; filas sin dato quedan vacías (RF-01, RF-08)

- [ ] **T-07** — Incluir columna en export Excel EPPlus de Producción + reactivar disparo UI
  - Archivos:
    - `GarantiplusWeb/Areas/Reportes/Controllers/ProduccionController.cs` (header + celdas; ajustar merges `A1:N*` → nueva última columna)
    - `GarantiplusWeb/Areas/Reportes/Views/Produccion/Index.cshtml` (`getReport`: si `salida==2` hacer submit del form; si no, reload grid)
  - Criterio de completitud: elegir salida Excel descarga `Produccion_*.xlsx` con columna "Usuario creador" (RF-03 para Producción)

- [ ] **T-08** — Mostrar usuario creador en detalle de contrato
  - Archivos: `GarantiplusWeb/Areas/Contratos/Views/Contratos/Details.cshtml`
  - Ubicación sugerida: card "Canal de contratación", junto a Asesor / Fecha registro
  - Bind: `Model.registra_contrato` (sin transformación)
  - Criterio de completitud: Details muestra el valor o vacío (RF-04, RF-08); sin error si null/empty

### Fase 2 — Explotación (condicional) (P2 si opción B; N/A si opción A)

- [ ] **T-09** — (Solo opción B) Diseñar e implementar listado/detalle por contrato en Explotación con `registra_contrato`
  - Archivos candidatos: `ExplotacionController.cs`, modelos `ReporteExplotacion*`, vistas partials bajo `Views/Explotacion/`
  - Criterio de completitud: RF-02 cumplido con filas por contrato

- [ ] **T-10** — (Solo opción B) Export Excel de Explotación con la columna (reactivar o reimplementar `Exportar`)
  - Criterio de completitud: RF-03 cumplido para Explotación

- [ ] **T-11** — (Si opción A) Documentar en AVANCE/PRD follow-up que RF-02/RF-03 Explotación se cubren por equivalencia Producción+Details; no código
  - Criterio de completitud: nota explícita de alcance cerrado sin código en Explotación

### Fase 3 — Pruebas multi-país y cierre (P1)

- [ ] **T-12** — Prueba Producción: grid + Excel con contratos con/sin `registra_contrato`
  - Criterio: RF-01, RF-03 (Producción), RF-08, RNF-04 (sin degradación perceptible)

- [ ] **T-13** — Prueba Details: creador visible; consistente con valor en BD
  - Criterio: RF-04, RNF-01, RNF-03

- [ ] **T-14** — Smoke multi-país (al menos un ambiente CHL o COL además de MEX, según disponibilidad)
  - Verificar que el mismo binario/código muestra la columna; en CHL no romper pantallas existentes
  - Criterio: RF-06, RNF-05

- [ ] **T-15** — (Opcional P2) Paridad COL en export listado contratos: añadir `registra_contrato` a `sp_reporte_contratos_facturas` + header en `PaisCO.ExportContracts`
  - Solo si negocio lo pide; **no** es bloqueante del MVP de Producción/Details
  - Criterio: Excel COL incluye "Usuario registra"/"Usuario creador" alineado a MX/CL

- [ ] **T-16** — Commit y push de la feature
  - Mensaje estilo Engine: `[PJ2872-trazabilidad-usuario-crea-contratos] Exponer usuario creador en Producción y detalle de contrato`
  - Criterio: cambios en rama remota; programador gestiona PR → `pre-qa`

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `contrato` | Ninguno (solo lectura) | Se usa `registra_contrato` existente (`varchar`, default `''`) |
| SPs Producción/Explotación | N/A | No existen; SQL inline |
| `sp_reporte_contratos_facturas` (COL) | Opcional P2 | Solo si se ejecuta T-15 |

No hay migraciones EF ni scripts DDL en el MVP.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET/POST | `/Reportes/Produccion` (Listado / Index) | Añade campo en JSON del listado y en Excel | Modificado (mismo contrato HTTP) |
| GET | `/Contratos/Contratos/Details/{id}` | Misma action; cambio solo en vista | Sin cambio de contrato |
| — | Explotación | Sin cambio si opción A; nuevo listado/export si opción B | Condicional |

Sin endpoints REST nuevos en API SIGA.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No aplica | — |

Solo se requiere `HubBaseCountryCode` / conexión del país bajo prueba.

---

## 8. Consideraciones de seguridad

- Sin cambios de IAM, roles ni policies: el dato hereda el acceso actual de Producción y Details (RNF-02).
- Operación de **solo lectura**; no se escribe `registra_contrato`.
- El valor es un **username** (identificador de usuario interno). No agregar logging extra del campo.
- Mantener consultas parametrizadas existentes al extender filtros; no concatenar el nuevo campo desde input de usuario.

---

## 9. Consideraciones de infraestructura

- Sin recursos AWS nuevos. Despliegue como cambio de SIGA Web en EC2 (MX, CO, CL).
- Costo incremental: nulo.
- No tocar ECS/API SIGA para este folio.

---

## 10. Criterios de aceptación

- [ ] Reporte Producción muestra columna "Usuario creador" con `contrato.registra_contrato` (RF-01)
- [ ] Export Excel de Producción incluye la misma columna y es descargable desde la UI (RF-03 Producción)
- [ ] Details de contrato muestra el usuario creador (RF-04)
- [ ] Garantías sin dato muestran vacío sin error (RF-08)
- [ ] Valor mostrado = valor en BD, sin transformación (RNF-01, RNF-03)
- [ ] Mismo comportamiento en instancias MX/CO/CL al desplegar el build (RF-06, RNF-05)
- [ ] Explotación: o bien (A) documentada como equivalencia / fuera de alcance MVP, o (B) listado+export con la columna (RF-02/RF-03)
- [ ] Sin cambios en creación de contratos ni backfill
- [ ] Permisos existentes sin ampliación de superficie (RNF-02)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| PRD asume Explotación como listado; en código son agregados | Alta | Alto (malentendido de alcance) | T-02 obligatorio antes de Fase 2; opción A por defecto |
| Índices del `DataReader` de Producción se desalían al insertar columna | Media | Medio | T-05: revisar mapping ordinal; prueba con filas reales |
| Excel Producción “roto” en UI (submit comentado) | Alta | Medio (RF-03 incompleto) | T-07 reactiva camino `salida==2` |
| Históricos / flujos sin `registra_contrato` | Media | Bajo (celdas vacías) | RF-08; sin backfill; comunicar a auditoría |
| Confusión `usuario_creador` vs `registra_contrato` | Media | Bajo (doc) | Clarificado en §1; no implementar filtro nuevo |
| GROUP BY omite `registra_contrato` → error SQL PostgreSQL | Media | Alto | Incluir en GROUP BY junto a `c.id_contrato` (T-05) |

---

## 12. Notas para el programador

1. **Respuestas a preguntas abiertas del PRD** — ver tabla §1. La decisión pendiente real es **Explotación A vs B** (T-02).
2. **No refactorizar** Producción/Explotación más allá de lo necesario para la columna.
3. **Referencia de naming/formato:** Excel listado MX/CL (`PaisMX` / `PaisCL`, col "Usuario registra") muestra el mismo username; las superficies nuevas del MVP usan la etiqueta del PRD **"Usuario creador"**.
4. **COL export listado** (`sp_reporte_contratos_facturas`) es gap histórico distinto al reporte Producción; T-15 es opcional.
5. El programador gestiona el PR (`feature/*` → `pre-qa` → `qa`); Claude Code no crea PRs.
6. Tras opción A, conviene que PM actualice el PRD (RF-02/RF-03) o abra follow-up explícito para Explotación.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y decisión (P1)** | Branch, decisión Explotación, baseline datos | T-01 a T-03 | 0.25 – 0.5 días | |
| **Fase 1 — Producción + Details (P1)** | Modelo, SQL, grid, Excel+UI, Details | T-04 a T-08 | 0.75 – 1.5 días | |
| **Fase 2 — Explotación (P2 condicional)** | Opción A doc N/A, o opción B listado+export | T-09 a T-11 | 0.1 días (A) / 2 – 4 días (B) | |
| **Fase 3 — Pruebas y cierre (P1)** | Pruebas Producción/Details, smoke países, commit (+ T-15 opcional) | T-12 a T-16 | 0.5 – 1 día | |
| **Total proyecto (opción A — recomendada)** | | 14 tareas activas (+2 N/A) | **~1.5 – 3 días hábiles (≈ &lt; 1 semana)** | — |
| **Total proyecto (opción B)** | | 16 tareas | **~3.5 – 7 días hábiles (≈ 1–1.5 semanas)** | — |
| **Solo P1 (guardarraíl)** | Fase 0 + Fase 1 + Fase 3 (+ T-11 si A) | T-01 a T-08, T-11–T-14, T-16 | **~1.5 – 3 días hábiles** | — |

> **Notas sobre la tabla:**
> - P1 = trazabilidad usable vía Producción + Details (+ Excel Producción).
> - P2 = Explotación rediseñada (opción B) y/o paridad COL en export listado (T-15, ~0.5 día extra).
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite contractual; importancia media. Con opción A el cambio cabe en un sprint corto (~2–3 días). Si Operaciones exige opción B, planificar ~1 semana y no comprimir P1. Un segundo desarrollador no aporta mucho (trabajo muy localizado en pocos archivos).

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
