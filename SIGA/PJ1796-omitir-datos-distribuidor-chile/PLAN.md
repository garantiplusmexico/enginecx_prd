# Plan de Desarrollo — Omitir Datos Distribuidor Chile (PJ1796)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ1796-omitir-datos-distribuidor-chile/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ1796-omitir-datos-distribuidor-chile` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ1796` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | 19 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Ocultar en la UI de Chile los campos **Cuenta bancaria** y **CLABE** del formulario de distribuidores (`_EditCHL`), usados en Create y Edit, sin tocar esquema de BD ni formularios de México/Colombia.

- **Arquitectura:** modificación puntual sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). No hay microservicio nuevo ni API.
- **Stack:** .NET 8 / C#, Razor Views, jQuery Validate (cliente), PostgreSQL (sin migración).
- **Alcance de código:** vista parcial `_EditCHL.cshtml` + ajuste de reglas JS compartidas en `Create.cshtml` / `Edit.cshtml` para no fallar cuando los inputs no existen en CHL.
- **Sin cambios** en `DataAccess` esquema EF, ni en `_EditMEX` / `_EditCOL` / `_Edit` genérico.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en código |
|---|---|
| ¿Son obligatorios server-side? | En `DataAccess/Models/distribuidor.cs`, `cuenta_bancaria` y `clabe` tienen `[Required]`. Sin embargo, `Create`/`Edit` POST usan `TryUpdateModelAsync` y **no consultan `ModelState.IsValid`** antes de persistir; el bloqueo real hoy es principalmente **cliente** (jQuery rules de formato, no `required`). |
| ¿`_EditCHL` es exclusiva? | Sí. `Create.cshtml` / `Edit.cshtml` cargan `@await Html.PartialAsync($"_Edit{ViewBag.codigopais}", Model)` → para Chile renderiza solo `_EditCHL.cshtml`. |
| ¿BD admite null/vacío? | EF mapea `cuenta_bancaria` (max 50) y `clabe` (max 18) **sin `IsRequired()`**; columnas permiten vacío/null. Sin migración. |

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — ya up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local con `HubBaseCountryCode` / proyecto Chile para probar Create/Edit de distribuidor CHL
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de UI sobre componente existente, sin desplegar servicio nuevo.

```
[Admin Chile]
  → Create.cshtml / Edit.cshtml
      → Partial _EditCHL.cshtml  (sin cuenta_bancaria / clabe)
      → scripts jQuery (rules solo si el input existe o país ≠ CHL)
  → DistribuidoresController.Create/Edit (TryUpdateModelAsync → BD)
      → PostgreSQL.distribuidor (columnas intactas)
```

**Decisión de diseño:**

1. **Ocultar = no renderizar** los dos `form-text` en `_EditCHL` (no `display:none`). Cumple RF-01/RF-02 y RNF-04.
2. **Aislar validación JS** en `Create.cshtml` y `Edit.cshtml`: no aplicar `$("#cuenta_bancaria")` / `$("#clabe").rules(...)` cuando el país es `CHL` (o cuando el elemento no existe). Evita errores JS al desaparecer los inputs.
3. **No quitar `[Required]` del modelo compartido** en el MVP, para no alterar el contrato de validación de otros países. El POST actual no bloquea por `ModelState.IsValid`; si en el futuro se habilita, reevaluar con `ModelState.Remove` condicional por país (fuera de alcance salvo que la prueba CHL demuestre bloqueo).
4. **Conservación en Edit (RF-05):** al no enviar los campos, `TryUpdateModelAsync` no debería sobrescribir `cuenta_bancaria`/`clabe` ya cargados desde BD. Se valida explícitamente en pruebas.

**Fuera de alcance (confirmado):** Details/`_GeneralesDistribuidor` (listados que aún muestran CLABE), limpieza de datos, cambios MEX/COL, migración BD.

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b feature/PJ1796-omitir-datos-distribuidor-chile`
  - Archivos: N/A
  - Criterio de completitud: rama local (y remote tras primer push) basada en `develop` actualizado

- [ ] **T-02** — Confirmar en ambiente CHL el comportamiento actual de Create/Edit con campos vacíos (baseline)
  - Verificar que hoy, con campos visibles, el guardado no exige CLABE/cuenta como `required` en cliente (solo formato si hay valor)
  - Anotar resultado en AVANCE si hay sorpresa (p. ej. validación adicional no vista en código)
  - Archivos: nota en `AVANCE.md` (cuando exista)
  - Criterio de completitud: baseline documentado; sin bloqueos abiertos para Fase 1

### Fase 1 — UI Chile + validación cliente (P1)

- [ ] **T-03** — Quitar render de Cuenta bancaria y CLABE en `_EditCHL`
  - Archivos a modificar: `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/_EditCHL.cshtml`
  - Acción: eliminar las líneas `<form-text for="cuenta_bancaria" …>` y `<form-text for="clabe" …>` dentro de la card "Información financiera"; dejar el resto (días de pago, margen, comisión, impuestos, etc.)
  - Criterio de completitud: en Create/Edit CHL esos dos campos no aparecen en el HTML generado

- [ ] **T-04** — Condicionar reglas jQuery de `cuenta_bancaria` / `clabe` en Create y Edit
  - Archivos a modificar:
    - `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/Create.cshtml`
    - `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/Edit.cshtml`
  - Acción: envolver los `$("#cuenta_bancaria").rules('add', …)` y `$("#clabe").rules('add', …)` para que **no se ejecuten en CHL** (preferible: `if ('@ViewBag.CodigoPais' != "CHL") { … }`, o guard `if ($("#cuenta_bancaria").length)` / `if ($("#clabe").length)`). No tocar reglas de MEX/otros países.
  - Criterio de completitud: consola del navegador sin errores de validator al abrir Create/Edit CHL; MEX sigue validando formato de CLABE/cuenta

- [ ] **T-05** — (Solo si T-06 lo exige) Ajuste mínimo server-side para CHL
  - Archivos candidatos: `DistribuidoresController.cs` (Create/Edit POST) — p. ej. `ModelState.Remove("cuenta_bancaria")` / `Remove("clabe")` cuando `codigo_pais == "CHL"`, **solo si** aparece bloqueo real
  - Criterio de completitud: Create/Edit CHL guardan sin error; MEX/COL sin cambio de comportamiento
  - Nota: tarea condicional — marcar N/A en AVANCE si las pruebas de T-06 pasan sin ella

### Fase 2 — Pruebas funcionales y cierre (P1)

- [ ] **T-06** — Prueba Create CHL
  - Alta de distribuidor Chile sin Cuenta bancaria/CLABE → redirect a Details, registro en BD con columnas null/vacías
  - Criterio de completitud: RF-03 cumplido; 0 errores de guardado

- [ ] **T-07** — Prueba Edit CHL + conservación de datos (RF-04 / RF-05)
  - Editar un distribuidor CHL que **ya tenga** valores en `cuenta_bancaria`/`clabe` → guardar otros campos → verificar en BD que esos valores **no se limpian**
  - Editar uno sin valores → guarda OK
  - Criterio de completitud: RF-04 y RF-05 verificados

- [ ] **T-08** — Smoke de no-regresión MEX (y COL si hay ambiente)
  - Abrir Create/Edit distribuidor México: campos Cuenta bancaria y CLABE visibles; reglas de dígitos/longitud siguen aplicando
  - Criterio de completitud: RNF-01 / métrica “sin regresión en otros países”

- [ ] **T-09** — Commit y push de la feature
  - Mensaje al estilo Engine: `[PJ1796-omitir-datos-distribuidor-chile] Ocultar cuenta bancaria y CLABE en formulario CHL`
  - Criterio de completitud: cambios en rama remota; listo para que el programador gestione PR hacia `pre-qa`

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `distribuidor` | Ninguno | Columnas `cuenta_bancaria` / `clabe` se conservan; altas nuevas CHL pueden quedar null/vacías |

No hay migraciones EF ni scripts SQL.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | Sin endpoints nuevos. Se reutilizan POST existentes `Catalogos/Distribuidores/Create` y `Edit` | Sin cambio de contrato |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No aplica | — |

Solo se requiere ambiente/proyecto con país Chile para validar UI.

---

## 8. Consideraciones de seguridad

- Sin cambios de IAM, roles ni políticas: mismos roles actuales de administración de distribuidores.
- No se exponen secrets nuevos.
- Datos bancarios: al ocultar campos no se eliminan valores históricos; no se agrega logging de esos campos.

---

## 9. Consideraciones de infraestructura

- Sin recursos AWS nuevos. Despliegue como cualquier cambio de SIGA Web en EC2 (Chile).
- Costo incremental: nulo.

---

## 10. Criterios de aceptación

- [ ] En Create CHL no se renderizan Cuenta bancaria ni CLABE (RF-01, RF-02)
- [ ] En Edit CHL no se renderizan Cuenta bancaria ni CLABE (RF-01, RF-02)
- [ ] Alta CHL se completa sin esos campos (RF-03)
- [ ] Edición CHL se guarda sin exigirlos ni mostrarlos (RF-04)
- [ ] Valores previos de Cuenta bancaria/CLABE en BD se conservan al editar (RF-05)
- [ ] Formularios MEX (y COL) sin cambio visual ni de validación de esos campos (RNF-01)
- [ ] Sin migración ni drop de columnas (RNF-02)
- [ ] Comportamiento Create y Edit alineado (RNF-03)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| jQuery `.rules('add')` falla si el input ya no existe en DOM CHL | Alta | Medio (rompe Submit en CHL) | T-04: condicionar por país o por existencia del elemento |
| `TryUpdateModelAsync` en Edit limpia propiedades no posteadas | Baja | Alto (pierde datos RF-05) | T-07: verificar en BD; si ocurre, excluir propiedades del bind o reasignar valores previos antes de `UpdateAsync` (T-05) |
| Algún filtro/`[ApiController]` futuro empieza a respetar `[Required]` del modelo | Baja | Medio | Documentado; no quitar `[Required]` global en MVP; T-05 condicional solo para CHL |
| Confundir `_EditCHL` de OrdenesPago con la de Distribuidores | Baja | Bajo | Tocar solo `Areas/Catalogos/Views/Distribuidores/_EditCHL.cshtml` |

---

## 12. Notas para el programador

1. **Respuestas a preguntas abiertas del PRD** (cerradas en análisis de código): ver tabla en §1. Si la prueba T-06/T-07 contradice el hallazgo, activar T-05.
2. **No refactorizar** el formulario completo ni unificar parciales por país.
3. **Chile y DataAccess:** `CountryBase` CHILE referencia el mismo modelo `distribuidor` que México (`DataAccess`); el aislamiento es por vista `_EditCHL`, no por modelo separado.
4. **Details:** `_GeneralesDistribuidor` puede seguir mostrando CLABE en grids; queda fuera del PRD. Si negocio pide ocultarlo también en Details, abrir follow-up.
5. El programador gestiona el PR (`feature/*` → `pre-qa` → `qa`); Claude Code no crea PRs.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y rama (P1)** | Branch + baseline CHL | T-01 a T-02 | 0.25 – 0.5 días | 21 |
| **Fase 1 — UI + validación JS (P1)** | Quitar campos CHL + rules Create/Edit (+ server opcional) | T-03 a T-05 | 0.25 – 0.5 días | 22 |
| **Fase 2 — Pruebas y cierre (P1)** | Create/Edit CHL, RF-05, smoke MEX, commit | T-06 a T-09 | 0.25 – 0.5 días | 23 |
| **Total proyecto (P1)** | | 9 tareas (1 condicional) | **~0.75 – 1.5 días hábiles (≈ &lt; 1 semana)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-09 | **~0.75 – 1.5 días hábiles** | — |

> **Notas sobre la tabla:**
> - Todo el alcance del PRD es P1 (MVP UI). No hay P2/P3 en este folio.
> - T-05 es condicional y no suma tiempo salvo que las pruebas lo activen (~+0.25 día).
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite. Con ~1–1.5 días hábiles el cambio cabe en cualquier sprint corto. No se requiere segundo desarrollador ni recorte de alcance.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
