# Plan de Desarrollo — Valores de moneda sin separadores de miles en Averías (PJ6579)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ6579-valores-moneda-sin-separadores-de-miles-en-averias/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ6579-valores-moneda-sin-separadores-averias` |
| Tipo | Feature (ajuste acotado) |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ6579` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | *(pendiente de registro)* |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

En el módulo de **Averías** (captura de presupuesto por taller), los montos se ingresan en inputs de texto y se parsean con `parseFloat` / model binding sin normalizar separadores de miles. Eso corrompe valores según el *locale* del país (MX: miles `,` / decimal `.`; CO/CL: miles `.` / decimal `,`).

- **Arquitectura:** modificación puntual sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). Sin microservicio nuevo ni API externa.
- **Stack:** .NET 8 / C#, Razor Views + jQuery, PostgreSQL (sin migración de esquema).
- **MVP:** (1) instrucción visible “sin IVA y sin separadores de miles”, (2) normalización automática por *locale* al capturar/enviar, (3) validación de montos antes de persistir (incl. coherencia de `impuestos_mano_obra` / `impuestos_piezas` recalculados).
- **Sin cambios** en lógica de pagos, corrección histórica ni detección automática de IVA.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en código |
|---|---|
| ¿Dónde vive el formulario? | `Areas/Averias/Views/Averias/_Edit.cshtml` carga `_RefaccionesServiciosDealer` + `_PresupuestoDealer`. JS de envío en `Edit.cshtml` (`agregaPrecioDistribuidor`, `updateOthersDealer`, etc.). |
| ¿Qué campos captura el taller? | Editables: `precio`, `mano_obra` (refacción), `precio` (servicio M.O.), `importe_diversos`, y `uat` (BMW). `importe_mo` / `importe_refacciones` / `presupuesto` son **readonly** (calculados). |
| ¿`impuestos_mano_obra` / `impuestos_piezas` son inputs? | **No.** Existen en `DataAccess` y `DataAccessColombia` (`averia`), pero se **recalculan en servidor** en `UpdateBudgetDealer` (`AveriasController.cs` ~3168–3169) como `importe * (1 + tax%)`. No hay `TextBox` de captura. RF-03 se interpreta como validar que, tras normalizar inputs, el recálculo produzca decimales válidos y no se persista basura. |
| ¿Capa de validación? | Hoy: cliente con `parseFloat` + jQuery validate; servidor recibe `decimal` por model binding (cultura de `CultureMiddleware` / sesión `_Culture`). Plan: **ambos** (cliente UX + servidor defensivo). |
| ¿Locale disponible? | Sí: `Session["_Culture"]` (`es-MX`, `es-CO`, `es-CL`, …) vía `CultureMiddleware` y ya usado en `Edit.cshtml` (`currencyCulture` / `decimalFormatter`). |
| ¿Vista COL distinta? | Existe `_RefaccionesServiciosDealerCOL.cshtml` pero **no se referencia**; `_Edit.cshtml` siempre usa `_RefaccionesServiciosDealer`. Un solo punto de UI + JS compartido cubre multi-país. |

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Operaciones-Averías · revisión técnica Alexis Salvador Herrera García)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — already up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local para al menos un país (ideal: probar MX y CO o CL cambiando `Hub:HubBaseCountryCode` / `_Culture`)
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de UI + helpers sobre componente existente, sin desplegar servicio nuevo.

```
[Taller captura precio / mano_obra / diversos]
  → JS: instrucción visible + normalizeMoneyInput(locale)
  → AJAX AddSpareDealer / AddServiceDealer / UpdateOthersDealer
  → Server: parse defensivo por CultureInfo de la instancia
  → UpdateBudgetDealer (recalcula impuestos_* + presupuesto)
  → PostgreSQL.averia / refaccion_averia / mano_obra_averia
```

**Decisiones de diseño:**

1. **Helper JS centralizado** en `Edit.cshtml` (o archivo `wwwroot/js` compartido si ya hay patrón; preferir lo mínimo: funciones junto a `currencyCulture` existente) que:
   - Detecta separador de miles/decimal del *locale* (`es-MX` vs `es-CO`/`es-CL`).
   - Elimina separador de miles, normaliza decimal a `.` para `parseFloat` / envío.
   - Si el valor es ambiguo o no numérico → alerta y **no envía**.
2. **Instrucción visible** (`alert alert-info`) en `_RefaccionesServiciosDealer.cshtml` y refuerzo breve en `_PresupuestoDealer.cshtml` (ya tiene un alert; ampliar texto). Mensaje único en español (idioma UI actual); no i18n nueva.
3. **Servidor defensivo:** helper C# (p.ej. en Averias o Common helper) que parsea string con `CultureInfo` de la request/sesión; usarlo en puntos de entrada donde el valor llega como string/form, o validar `decimal` ya bindeado rechazando valores absurdos solo si el binding falla. Preferir: normalizar en cliente y, si el binding falla (400/model state), devolver mensaje claro en JSON.
4. **`impuestos_*`:** no crear inputs. Tras `UpdateBudgetDealer`, asegurar que `impuestos_mano_obra` / `impuestos_piezas` / `presupuesto` son finitos y ≥ 0; si el input normalizado no es válido, no llamar al update.
5. **No refactor** del cálculo de IVA ni de pagos. No tocar datos históricos.
6. **Admin (opcional P2):** campos `aceptado_*` / `servicio_aceptado_*` en `_RefaccionesServiciosAdmin.cshtml` usan el mismo `parseFloat` — incluir normalización en la misma helper para consistencia, sin rediseñar pantallas.

**Locale (RNF-01 / RNF-04):**

| País | Culture típica | Miles | Decimal |
|---|---|---|---|
| México | `es-MX` | `,` | `.` |
| Colombia | `es-CO` | `.` | `,` |
| Chile | `es-CL` | `.` | `,` |

Fuente única: `Session["_Culture"]` (ya centralizada). No hardcodear por pantalla más allá del mapa culture → separadores.

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Archivos: N/A (git)
  - Criterio: rama `feature/PJ6579-valores-moneda-sin-separadores-averias` publicada en origin

- [ ] **T-02** — Confirmar matriz de campos editables y endpoints de persistencia (smoke de código en rama)
  - Archivos a revisar: `Edit.cshtml`, `_RefaccionesServiciosDealer.cshtml`, `_PresupuestoDealer.cshtml`, `AveriasController` (`AddSpareDealer`, `AddServiceDealer`, `UpdateOthersDealer`, `UpdateBudgetDealer`)
  - Criterio: lista cerrada de inputs a normalizar documentada en nota de commit / §12 si hay desviación

### Fase 1 — Instrucción + normalización cliente (P1)

- [ ] **T-03** — Agregar mensaje/instrucción visible (RF-01)
  - Archivos: `_RefaccionesServiciosDealer.cshtml`, `_PresupuestoDealer.cshtml`
  - Criterio: el taller ve texto claro: capturar **sin IVA** y **sin separadores de miles**; no rompe layout existente

- [ ] **T-04** — Implementar `normalizeMoneyInput` / `parseMoneyInput` por *locale* (RF-02, RNF-01, RNF-04)
  - Archivos: `Edit.cshtml` (junto a `currencyCulture` / `decimalFormatter`); opcionalmente extraer a `wwwroot/js/averias-money.js` si el bloque crece
  - Criterio: casos MX `1,234.50` → `1234.50`; CO/CL `1.234,50` → `1234.50`; `1234.50` / `1234,50` según locale; valor inválido → `null` + mensaje

- [ ] **T-05** — Aplicar normalización en flujos de captura taller (RF-02, RF-05)
  - Archivos: `Edit.cshtml` (`agregaPrecioDistribuidor`, `updateOthersDealer`, reglas jQuery `mayorACero`/`mayorOCero` sobre montos, blur opcional en `#precio`, `#mano_obra`, `#importe_diversos`, `#uat`)
  - Criterio: al registrar refacción/servicio/diversos, nunca se envía un `parseFloat` crudo con separadores; si es inválido, alert y no AJAX

### Fase 2 — Validación servidor e impuestos (P1)

- [ ] **T-06** — Validación/parse defensivo en endpoints de captura (RF-03, RF-05, RNF-05)
  - Archivos: `AveriasController.cs` (`AddSpareDealer`, `AddServiceDealer`, `UpdateOthersDealer`); helper nuevo acotado (p.ej. `MoneyParseHelper` o método privado)
  - Criterio: si el valor no se puede interpretar como decimal válido para la cultura de la instancia, respuesta JSON `{ success:false, errors:"..." }` en español; no persistir

- [ ] **T-07** — Asegurar recálculo coherente de `impuestos_mano_obra` / `impuestos_piezas` (RF-03)
  - Archivos: `AveriasController.cs` (`UpdateBudgetDealer`)
  - Criterio: tras inputs válidos, ambos campos y `presupuesto` quedan ≥ 0 y finitos; no se altera la fórmula existente salvo guard clauses

### Fase 3 — Consistencia admin + multi-país y cierre (P2 / verificación)

- [ ] **T-08** — Reutilizar helper en aceptación admin (`aceptado_*`, `servicio_aceptado_*`) (RF-04)
  - Archivos: `Edit.cshtml` (funciones de aceptar/rechazar piezas/servicios), `_RefaccionesServiciosAdmin.cshtml` si hace falta clase CSS
  - Criterio: mismos separadores no corrompen montos autorizados

- [ ] **T-09** — Prueba manual multi-país (RF-04, RNF-01)
  - Archivos: N/A (QA manual)
  - Criterio checklist: MX + (CO o CL) — capturar con y sin separadores; inválido bloquea; instrucción visible; BMW UAT sin regresión

- [ ] **T-10** — Commit final en rama funcional
  - Archivos: todos los del cambio
  - Criterio: push a origin de la feature branch; programador gestiona PR según `version-control.md`

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | Ninguno | Sin migración. Se reutilizan columnas `averia.impuestos_mano_obra`, `averia.impuestos_piezas`, montos de `refaccion_averia` / `mano_obra_averia`. |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `Averias/Averias/AddSpareDealer/{id}` | Parse/validación defensiva de `precio` / `mano_obra` | Modificado (comportamiento) |
| POST | `Averias/Averias/AddServiceDealer/{id}` | Idem para `precio` | Modificado |
| POST | `Averias/Averias/UpdateOthersDealer/{id}` | Idem para `importe_diversos` | Modificado |

Sin endpoints nuevos ni cambio de contrato público hacia APIs externas.

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| — | Ninguna nueva. Se usa `Hub:HubBaseCountryCode` + sesión `_Culture` existentes | Todos |

---

## 8. Consideraciones de seguridad

- No secrets nuevos.
- Validar entrada monetaria en servidor (no confiar solo en JS).
- Mensajes de error al usuario en español; logs técnicos en inglés si se agregan.
- No ampliar roles ni permisos; mismos `[Authorize(Roles=...)]` actuales.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin recursos AWS nuevos. Despliegue estándar SIGA Web en EC2 por país (mismo artefacto / build por `CountryBase`).
- El cambio es de código compartido: una vez desplegado en cada instancia (MX/CO/CL), el *locale* de sesión selecciona el comportamiento.

---

## 10. Criterios de aceptación

- [ ] Instrucción visible en captura de presupuesto/refacciones del taller: sin IVA y sin separadores de miles (RF-01)
- [ ] Al capturar con separador de miles del país, el valor almacenado conserva el decimal correcto (RF-02, RF-04)
- [ ] Valor no interpretable: aviso al usuario y no se guarda (RF-05, RNF-05)
- [ ] Tras guardar, `impuestos_mano_obra` e `impuestos_piezas` quedan coherentes con el recálculo actual (RF-03)
- [ ] Funciona en instancias MX, CO y CL según su *locale* (RF-04, RNF-01)
- [ ] Sin cambios en pagos, sin migración, sin corrección histórica
- [ ] Flujo BMW UAT (si aplica en el proyecto) no se rompe

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Confundir miles con decimal al normalizar | Media | Alto | Basar separadores solo en `_Culture`; casos de prueba MX vs CO/CL; rechazar ambiguos |
| `UpdateOthersDealer` tipado como `int` hoy | Media | Medio | Revisar firma actual (`importe_diversos`); normalizar y castear con cuidado o alinear a `decimal` solo si ya es necesario para el bug |
| Talleres siguen incluyendo IVA | Alta | Medio | Solo instrucción (fuera de alcance detección IVA); documentar en notas |
| `decimalFormatter.format` al mostrar totales vs input crudo | Baja | Medio | Normalizar en blur o no reintroducir miles en inputs editables |
| Vista COL huérfana genera divergencia futura | Baja | Bajo | No reactivar `_RefaccionesServiciosDealerCOL` en este MVP; un solo partial |

---

## 12. Notas para el programador

1. **RF-03 reinterpretado:** el PRD nombra `impuestos_*` como campos a “validar”; en código no son captura. Validar = inputs de origen + integridad post-`UpdateBudgetDealer`.
2. **No detectar IVA** automáticamente (fuera de alcance PRD §6).
3. **`parseFloat` es el bug raíz** en cliente; el model binder ASP.NET también depende de `CultureInfo.CurrentCulture` — ambos lados importan.
4. Respetar código existente: no refactorizar `AveriasController` más allá de helpers y guard clauses.
5. Mensajes UI en español; nombres de helpers nuevos en inglés (`NormalizeMoneyInput`, etc.) según `coding-guidelines.md`.
6. Tras validar este plan: `ejecuta el plan` para crear rama y desarrollar.
7. Preguntas del PRD aún abiertas solo para producto (rango máximo de impuestos, alerta proactiva de IVA): **no bloquean** el MVP; default = numérico ≥ 0, finito, sin tope artificial.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y rama (P1)** | Branch + matriz de campos/endpoints | T-01 a T-02 | 0.5 – 1 día | |
| **Fase 1 — Instrucción + normalización cliente (P1)** | Alert UI + helper locale + wiring taller | T-03 a T-05 | 1 – 2 días | |
| **Fase 2 — Validación servidor e impuestos (P1)** | Parse defensivo + integridad `impuestos_*` | T-06 a T-07 | 1 – 1.5 días | |
| **Fase 3 — Admin + QA multi-país (P2)** | Aceptación admin + pruebas MX/CO/CL + commit | T-08 a T-10 | 1 – 1.5 días | |
| **Total proyecto (P1+P2)** | | 10 tareas | ~3.5 – 6 días hábiles (≈ 1 – 1.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-07 | ~2.5 – 4.5 días hábiles (≈ 0.5 – 1 semana) | — |

> **Notas sobre la tabla:**
> - P1 = instrucción + normalización taller + validación servidor (MVP del PRD).
> - P2 = consistencia en pantallas de aceptación admin y batería multi-país formal.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite numérica. Con un desarrollador, el alcance completo (~3.5–6 días hábiles) es realista en una sprint corta. Si hubiera urgencia operativa &lt; 3 días hábiles, priorizar **Solo P1** (T-01–T-07) y diferir T-08 (admin). Un segundo desarrollador aporta poca compresión (&lt;20%) por el cuello de botella en el mismo `Edit.cshtml`/`AveriasController`.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
