# Plan de Desarrollo — Ejecutivo de Ventas: dejar contrato sin cobertura (PJ1255)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ1255-ejecutivo-ventas-anular-cobertura-contrato/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — Contratos) |
| Rama base | `develop` |
| Rama | `feature/PJ1255-ejecutivo-ventas-anular-cobertura-contrato` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ1255` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 44 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

La acción **"dejar sin cobertura"** ya existe: botón **Sin Cobertura** en `Contratos/Details`, modal con **causa obligatoria** (textarea, no catálogo), `POST Contratos/Contratos/SinCobertura` pone `poliza.con_cobertura = 0` y guarda `causa_sin_cobertura`, `registra_sin_cobertura` (username) y `fecha_registro_sin_cobertura`. Hoy el `[Authorize]` y el `IsInRole` del botón **no incluyen** `Ejecutivo de Ventas`. El Ejecutivo **sí** entra al listado y a Details (menú Chile y `GetAllContratos` con `solodistribuidores`).

Este cambio **solo otorga el permiso** de esa acción al Ejecutivo, acotado a **Chile** (RNF-05) y a **distribuidores asignados** (`usuario_distribuidor`). No se toca el efecto de negocio ni se habilita reactivar cobertura (de hecho **no hay** endpoint que vuelva `con_cobertura` a 1).

- **Arquitectura:** feature sobre el monolito SIGA Web. Sin API, sin PDFGenerator, sin BD.
- **Stack:** .NET 8, Razor, Identity roles, `appsettings` por país.

**Hallazgo técnico (cierra las preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| Nombre del rol | **`Ejecutivo de Ventas`** (Identity). |
| ¿Dónde está el botón? | `GarantiplusWeb/Areas/Contratos/Views/Contratos/Details.cshtml` (~L103-106). Visible si estatus **Activo o Registrado**, `con_cobertura != 0`, y rol AG / Gestor / **Coordinador Tecnicos**. `Edit.cshtml` tiene el JS/modal pero **no** el botón; Edit es solo AG/AGE/Gestor. |
| ¿Endpoint? | `POST /Contratos/Contratos/SinCobertura/{id}` + `causa_sin_cobertura`. `[Authorize(Roles = "Administrador General,Administrador General Externo,Gestor de Países,Coordinador Tecnicos")]`. AGE puede el POST pero **no** ve el botón. |
| Motivo | Textarea `causa_sin_cobertura` + jQuery Validate `required`. **No** es un catálogo. |
| Trazabilidad | Campos en `poliza`: causa, `registra_sin_cobertura`, `fecha_registro_sin_cobertura`. Se muestran en Details cuando ya está sin cobertura. |
| Ámbito de consulta | Listado: `solodistribuidores` → `usuario_distribuidor` (`PaisCL.GetAllContratos`). **Details no filtra** asignación (`GetContractById` ignora ese flag). El POST `SinCobertura` tampoco. |
| ¿Se puede reactivar cobertura? | **No existe** acción que ponga `con_cobertura = 1`. El botón **Reactivar** de Details es para contratos **Cancelados** (`POST Reactivar`, AG/Gestor) — otra cosa. RF-05 ya se cumple si no se toca `Reactivar`. |
| Contratos no suspendibles | Ya: `Cancelado`, `Caduco` o `con_cobertura == 0`. No hay chequeo de avería abierta. No añadir reglas. |
| Confirmación extra | Ya hay `swal` (“¿Está seguro(a) de quitar la cobertura…?”). No hay correo. No inventar notificación. |
| Chile vs otros hubs | Mismo binario; país = `GetCountryCodeForCurrentProject()` (`CHL` → `PaisCL`). Si solo se agrega el rol al `[Authorize]`, **México y Colombia** también lo habilitarían. |

**Implicación:** no crear flujo nuevo. Ampliar rol + **flag por país** (CHL on) + **validar asignación en el POST** (no confiar solo en ocultar el botón).

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] `develop` actualizado; `CLAUDE.md` presente ✅
- [ ] Usuario **Ejecutivo de Ventas** en hub **Chile** con ≥1 dealer en `usuario_distribuidor` y un contrato Activo/Registrado con cobertura
- [ ] Un contrato de un dealer **no** asignado (probar 403/error)
- [ ] Usuario AG/Gestor/Coordinador Tecnicos (no-regresión del botón)
- [ ] No commitear `appsettings.json` sucio; **sí** se puede añadir solo la sección del flag

---

## 3. Arquitectura del cambio

```
[Ejecutivo CHL] Contratos → Listado (ya filtrado por dealer)
        → Details (consulta)
             ├─ flag CHL ON + asignado + Activo/Registrado + con cobertura
             │     → botón Sin Cobertura → modal causa → swal → POST SinCobertura
             │           servidor: rol + flag país + asignación + reglas actuales
             └─ flag OFF (MEX/COL) o no asignado → sin botón; POST 403
```

**Decisiones de diseño:**

1. **No** cambiar `con_cobertura = 0` ni los tres campos de auditoría.
2. **No** abrir `Edit` ni `Reactivar` al Ejecutivo.
3. Flag: `Contratos:EjecutivoVentasSinCobertura:{CHL\|MEX\|COL\|…}` bool. Si falta la key → **false**. Primer release: **CHL = true**; MEX/COL false.
4. Ejecutivo en Chile: botón en Details con los mismos `IsInRole` actuales **más** `Ejecutivo de Ventas` **y** el flag. Roles ya habilitados **no** dependen del flag.
5. `SinCobertura`: añadir `Ejecutivo de Ventas` al `[Authorize]`. Si el usuario es Ejecutivo: exigir flag del país actual **y** que el `id_distribuidor` del contrato esté en `usuario_distribuidor` de su username. Si no → 403 / `{ success:false }` (no suspender).
6. Helper chico `IsSalesExecutiveLeaveWithoutCoverageEnabled(countryCode)` (mismo estilo que PJ3423, **sin** compartir código salvo que ya exista al ejecutar).
7. Motivo: reutilizar el textarea; no crear catálogo.
8. Sin correo, sin doble confirmación extra, sin cambios en averías (`ClaimValidator` ya respeta `con_cobertura==0`).
9. No “arreglar” AGE (POST sí / botón no) ni typos de roles.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — `feature/PJ1255-ejecutivo-ventas-anular-cobertura-contrato` desde `develop`
  - Criterio de completitud: rama en origin

### Fase 1 — Permiso Chile (P1)

- [ ] **T-02** — Setting por país
  - Archivos: sección nueva en `appsettings` (solo esa clave); helper de lectura
  - Clave: `Contratos:EjecutivoVentasSinCobertura`
  - Criterio de completitud: sin key o `false` → Ejecutivo no actúa; `CHL=true` en el hub Chile

- [ ] **T-03** — `POST SinCobertura`
  - Archivos: `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs` (~L1831-1864)
  - Añadir `Ejecutivo de Ventas` al `[Authorize]`
  - Si es Ejecutivo: flag on + asignación `usuario_distribuidor`; si falla → no actualizar
  - AG/Gestor/Coordinador/AGE: mismo comportamiento de hoy (sin flag)
  - Criterio de completitud: Ejecutivo CHL asignado suspende; no asignado o flag off no cambia `con_cobertura`

- [ ] **T-04** — Botón en Details
  - Archivos: `Areas/Contratos/Views/Contratos/Details.cshtml` (~L103)
  - Condición actual + `User.IsInRole("Ejecutivo de Ventas")` + ViewBag/flag Chile
  - Reutilizar modal, validate, swal (sin copiar flujo)
  - Criterio de completitud: Ejecutivo CHL ve el botón en Activo/Registrado con cobertura; no lo ve si ya está SIN COBERTURA

### Fase 2 — No-regresión (P1)

- [ ] **T-05** — No habilitar reactivación ni Edit
  - `Reactivar` sigue AG/AGE/Gestor; botón Reactivar igual
  - No añadir Ejecutivo a `Edit`
  - Criterio de completitud: Ejecutivo no ve Reactivar; POST Reactivar → 403

- [ ] **T-06** — MEX/COL y roles actuales
  - Ejecutivo MX/COL: sin botón y POST rechazado (flag false)
  - AG / Gestor / Coordinador Tecnicos: botón y POST iguales
  - Criterio de completitud: un Ejecutivo MEX no suspende aunque conozca la URL

### Fase 3 — Validación (P1)

- [ ] **T-07** — Hub CHL: asignado + causa + confirmación → badge SIN COBERTURA, usuario y fecha
- [ ] **T-08** — Causa vacía sigue bloqueada en UI; Cancelado/Caduco/ya sin cobertura → error existente

---

## 5. Cambios en base de datos *(si aplica)*

No aplica. Se reutilizan columnas de `poliza` (`con_cobertura`, `causa_sin_cobertura`, `registra_sin_cobertura`, `fecha_registro_sin_cobertura`).

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/Contratos/Contratos/SinCobertura/{id}` | Añade Ejecutivo + flag CHL + asignación | Modificado |
| GET | `/Contratos/Contratos/Details/{id}` | Botón visible para Ejecutivo si flag | Modificado (vista) |
| POST | `/Contratos/Contratos/Reactivar/{id}` | Sin Ejecutivo | Sin cambio |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Contratos:EjecutivoVentasSinCobertura:CHL` | `true` en hub Chile (primer release) | QA/prod CL |
| `Contratos:EjecutivoVentasSinCobertura:MEX` | `false` | hub MX |
| `Contratos:EjecutivoVentasSinCobertura:COL` | `false` | hub CO |
| (otro código) | Ausente = apagado | — |

Administración = TI edita appsettings del host. Sin pantalla de negocio.

---

## 8. Consideraciones de seguridad

- Assignment y flag en **servidor** (el POST no puede fiarse del Razor). Details hoy no filtra dealer; este POST **sí** debe filtrar para Ejecutivo.
- No relajar `Reactivar` ni `Edit`.
- Causa viaja en el POST; no loguear PII extra. Username ya se guarda en `registra_sin_cobertura`.
- IDOR: Ejecutivo + id de contrato ajeno → rechazo.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin AWS nuevo. Tres hubs: el mismo código; el flag cambia por `appsettings` (CHL on).
- No desplegar PDFGenerator ni API.

---

## 10. Criterios de aceptación

- [ ] **RF-01 / RNF-04:** Ejecutivo CHL ve y usa **Sin Cobertura** en Details (mismo modal/flujo).
- [ ] **RF-02:** Sin causa no confirma (validación existente).
- [ ] **RF-03:** Solo contratos que el rol lista (dealers asignados); sin regla extra de sucursal.
- [ ] **RF-04 / RNF-02:** Quedan usuario, causa y fecha/hora en `poliza` (visibles en el badge).
- [ ] **RF-05:** No Reactivar cobertura ni Reactivar contrato cancelado.
- [ ] **RNF-01:** Solo se suma el Ejecutivo; AG/Gestor/Coordinador intactos.
- [ ] **RNF-03:** Mismos efectos (`con_cobertura=0`; averías siguen bloqueadas por `ClaimValidator`).
- [ ] **RNF-05:** MEX/COL apagado.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Añadir el rol sin flag enciende MX/COL | Alta | Alto | Flag default false; solo CHL true |
| POST sin chequeo de dealer (Details no filtra) | Alta | Alto | T-03: `usuario_distribuidor` |
| Confundir Reactivar (cancelado) con reponer cobertura | Media | Medio | No tocar `Reactivar`; documentar que no hay restore de `con_cobertura` |
| Causa vacía en POST directo | Baja | Bajo | UI required; no cambiar lógica de AG |
| Independiente de PJ3423 (precios) | Baja | Bajo | No mezclar flags ni helpers salvo que ya exista uno genérico |

---

## 12. Notas para el programador

1. Rol exacto: **`Ejecutivo de Ventas`**. País: **`CHL`** (`PaisCL`).
2. Botón visible hoy: AG, Gestor, **Coordinador Tecnicos** (sin acento). POST también AGE. No “alinearlos”.
3. Independiente de PJ3423 / PJ4197 / PJ0288 / PJ9159.
4. Código nuevo en inglés; textos de UI ya están en español (no reescribir el modal).
5. No refactorizar `ContratosController` (~7k líneas) más de `SinCobertura` + ViewBag para el flag.
6. El comentario TODO “mover a Averías / endoso” **no** se implementa en este folio.
7. No commitear `appsettings.json` locales.

---

## 13. Relación de tareas y tiempos

Todo el PRD es **P1**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 132 |
| **Fase 1 — Permiso Chile (P1)** | Flag + POST + botón Details | T-02 a T-04 | 0.5 – 1 día | 133 |
| **Fase 2 — No-regresión (P1)** | Reactivar/Edit + MEX/COL off | T-05 a T-06 | 0.25 – 0.5 días | 134 |
| **Fase 3 — Validación (P1)** | CHL feliz / causa / estados | T-07 a T-08 | 0.5 – 1 día | 135 |
| **Total proyecto (P1)** | | 8 tareas | ~1.5 – 2.75 días hábiles (≈ 0.5 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 3 | T-01 a T-08 | ~1.5 – 2.75 días hábiles | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre ~2–3 días. No hay recorte P2. El único riesgo es validar en hub Chile con un ejecutivo real y dealers asignados.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
