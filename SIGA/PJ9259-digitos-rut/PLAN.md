# Plan de Desarrollo — Dígitos RUT (Chile)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ9259-digitos-rut/PRD.md` |
| Repositorio | `gp_4.0_siga` |
| Rama base | `develop` |
| Rama | `feature/PJ9259-digitos-rut` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ9259` |
| Fecha de generación | 2026-07-24 |
| Estado | Validado |
| ID plan (BD) | 32 |
| Modelo | Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal |

---

## 1. Resumen técnico

Ajuste acotado a **Garantiplus Chile** en SIGA Web (`GarantiplusWeb` + librería `PaisesService`) para flexibilizar longitudes de validación de **RUT** (8–12 caracteres) y **HP** (1 o más dígitos, incluido 0), sin validación de dígito verificador ni cambios en México/Colombia.

**Componentes a tocar:**
- `PaisesService` — configuración por país de Chile (`PaisCL`): rangos y mensajes de RUT (beneficiario y dealer).
- `GarantiplusWeb` — máscaras/inputs que fuerzan longitud fija (RUT con `data-mask="99.999.999-w"`; HP con `data-mask="999"` en emisión especial Chile) y pantallas de catálogo de distribuidores que consumen los rangos.
- Consistencia front ↔ back: verificar que `IsEnabledFiscalIdValidation()` / flujos asociados no bloqueen valores válidos en Chile.

**Arquitectura:** feature sobre monolito SIGA Web existente (EC2 + .NET 8 + Razor/jQuery). Sin microservicio nuevo ni cambio de despliegue.

**Stack:** .NET 8 / C#, Razor Pages + jQuery Validate, PostgreSQL (sin cambios de esquema).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Ambiente local con país base **Chile** (`CountryBase=CHILE`, `Hub:HubBaseCountryCode=CHL`) para probar emisión
- [ ] Confirmación de Operaciones/negocio sobre conteo de caracteres del RUT (con/sin puntos y guion) — ver §12
- [ ] `CLAUDE.md` presente en el repositorio ✅

---

## 3. Arquitectura del cambio

Se respeta la arquitectura existente de SIGA Web: la configuración de validación por país vive en `PaisesService` y el frontend la aplica vía AJAX (`CountryConfiguration` / endpoints de elementos adicionales). No se crea servicio nuevo ni se altera el cálculo de precio que usa HP.

```
[GarantiplusWeb Create / Emisión especial / Distribuidores]
        │  consume rangos/mensajes
        ▼
[PaisesService → PaisCL]
        │  GetAdditionalContractBeneficiaryVehicleElements()
        │  GetAdditionalDealerElements()
        ▼
[Validación jQuery (rangelength) + máscaras inputmask]
```

**Decisión técnica (descubrimiento previo al plan):**
- RUT fijo en 12: confirmado en `PaisesService/Classes/CL/PaisCL.cs` (beneficiario y dealer).
- HP con longitud fija: ubicado en `GarantiplusWeb/Areas/Contratos/Views/Contratos/_DatosVehiculoEmEspecialCHL.cshtml` (`data_mask="999"` → exactamente 3 dígitos). En `Create` normal el campo solo usa regla `entero` (permite ≥ 0).
- `ValidateRFC` en `PaisCL` lanza `NotImplementedException` y **no** se invoca desde el flujo de emisión; `IsEnabledFiscalIdValidation()=true` habilita `calculaRFC()` (flujo pensado para México). Mitigación: desactivar el flag en Chile o asegurar que no se dispare en pantallas CHL.

---

## 4. Tareas de desarrollo

### Fase 0 — Descubrimiento y decisiones abiertas

- [ ] **T-01** — Confirmar regla de conteo de RUT (8–12) con/sin formato y alcance de pantallas
  - Archivos a crear/modificar: ninguno (análisis + nota en PRD/plan)
  - Criterio de completitud: decisión documentada en §12 del plan (conteo, máscara, campos beneficiario+dealer, y si cotizador/endosos/asesores entran en MVP)

- [ ] **T-02** — Inventario de puntos de validación/máscara RUT y HP en Chile
  - Archivos a revisar (sin cambiar aún): `PaisCL.cs`, `_BeneficiarioCHL.cshtml`, `CreateCHL.cshtml` (cotizador), `_EditCHL.cshtml` (distribuidores), endosos CHL, `_DatosVehiculoEmEspecialCHL.cshtml`, `Create.cshtml` / `EmisionEspecial.cshtml`
  - Criterio de completitud: lista cerrada de archivos a modificar en Fases 1–2

### Fase 1 — RUT flexible solo Chile (P1)

- [ ] **T-03** — Ajustar rangos y mensajes de RUT en `PaisCL`
  - Archivos a crear/modificar: `PaisesService/Classes/CL/PaisCL.cs`
  - Cambio: `beneficiario_rfc_min/max = 8/12`, `rfc_longitud_min/max = 8/12`, mensajes tipo *"El RUT debe tener entre 8 y 12 caracteres"*
  - Criterio de completitud: solo `PaisCL` cambia; `PaisMX` / `PaisCO` intactos

- [ ] **T-04** — Alinear máscaras/inputs de RUT en emisión de contrato Chile
  - Archivos a crear/modificar: `GarantiplusWeb/Areas/Contratos/Views/Contratos/_BeneficiarioCHL.cshtml` (y cotizador/endosos CHL si T-01 los incluye en MVP)
  - Cambio: relajar o reemplazar `data-mask="99.999.999-w"` para permitir RUTs más cortos sin forzar 12 caracteres; mantener UX usable
  - Criterio de completitud: se pueden capturar RUT de 8, 9, 10, 11 y 12 caracteres y la validación `rangelength` del front acepta el rango

- [ ] **T-05** — Verificar catálogo de distribuidores (RFC/RUT Chile)
  - Archivos a crear/modificar: `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/Create.cshtml`, `Edit.cshtml`, `_EditCHL.cshtml` (solo si la máscara fija bloquea el nuevo rango)
  - Criterio de completitud: alta/edición de dealer Chile acepta RUT 8–12 con mensaje acorde; MX/CO sin regresión

- [ ] **T-06** — Consistencia flag fiscal / backend Chile
  - Archivos a crear/modificar: `PaisesService/Classes/CL/PaisCL.cs` (`IsEnabledFiscalIdValidation` → `false` recomendado, salvo que T-01 indique lo contrario); verificar que no se llame `ValidateRFC` en emisión
  - Criterio de completitud: emisión Chile no dispara cálculo/validación estructural de RFC; valores 8–12 aceptados end-to-end en post del contrato

### Fase 2 — HP flexible (P1)

- [ ] **T-07** — Eliminar longitud fija de HP en emisión especial Chile
  - Archivos a crear/modificar: `GarantiplusWeb/Areas/Contratos/Views/Contratos/_DatosVehiculoEmEspecialCHL.cshtml`
  - Cambio: quitar o ampliar `data_mask="999"`; permitir 1+ dígitos incluido `0`; conservar validación numérica entera
  - Criterio de completitud: se aceptan HP `0`, `5`, `99`, `450` (y valores de 1+ dígitos); no se exige exactamente 3

- [ ] **T-08** — Verificar Create / cotizador Chile para HP
  - Archivos a revisar/modificar si hace falta: `Create.cshtml` (regla `entero` en `#vehiculo_hp`), `Cotizador/CreateCHL.cshtml` (`#potencia_vehiculo`), partials `_DatosVehiculoCHL.cshtml`
  - Criterio de completitud: misma regla de longitud flexible en flujos de emisión normales; sin tocar lógica de pricing

### Fase 3 — Pruebas y no-regresión multi-país

- [ ] **T-09** — Prueba manual Chile (casos RUT/HP)
  - Criterio de completitud: matriz mínima pasada (ver §10): RUT 8–12 (válidos), RUT &lt;8 y &gt;12 (rechazo + mensaje nuevo), HP 0 / 1 dígito / varios dígitos

- [ ] **T-10** — Smoke MX y CO (no regresión)
  - Criterio de completitud: rangos/mensajes de RFC/NIT y comportamiento de HP sin cambios observables en México y Colombia

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | N/A | Sin migraciones ni cambios de esquema. Solo validación de UI/configuración por país. |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | No hay endpoints nuevos. Se reutilizan los existentes que exponen `GetAdditional*Elements` vía `ContratosController` / `DistribuidoresController`. | Sin cambio de contrato |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Hub:HubBaseCountryCode` | Debe ser `CHL` para probar el cambio | Desarrollo local Chile |
| `CountryBase` (csproj) | `CHILE` al compilar para ambiente Chile | Build local / EC2 Chile |

No se agregan secrets ni variables nuevas.

---

## 8. Consideraciones de seguridad

- No hay endpoints nuevos ni cambios IAM.
- RUT es dato personal/fiscal: no registrar valores completos en logs nuevos.
- No introducir validación estructural falsa; el MVP solo relaja longitud (evitar dar sensación de “RUT verificado” si no lo está).
- Secrets: no aplica.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin recursos AWS nuevos.
- Despliegue: mismo pipeline/EC2 de SIGA Web Chile; cambio de configuración en librería referenciada por `GarantiplusWeb`.
- Coordinar despliegue en instancia Chile; México/Colombia no requieren redeploy salvo build compartido (verificar proceso de release multi-país).

---

## 10. Criterios de aceptación

- [ ] En Chile, RUT de beneficiario acepta **8 a 12** caracteres en emisión de contrato
- [ ] En Chile, RUT de dealer acepta **8 a 12** caracteres (si está en alcance confirmado)
- [ ] Mensaje de error refleja el rango (ya no *"El RUT debe tener 12 caracteres"*)
- [ ] HP acepta **1 o más dígitos**, incluido **0**, sin exigir longitud fija (máscara `999` eliminada/relajada)
- [ ] Frontend y backend aceptan los mismos valores válidos (sin rechazo indebido post-submit)
- [ ] México y Colombia mantienen sus rangos/mensajes actuales
- [ ] No se implementa validación de dígito verificador / `ValidateRFC` estructural

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Máscara `99.999.999-w` sigue forzando 12 chars aunque PaisesService diga 8–12 | Alta | Alto | Incluir T-04 explícita; probar captura real, no solo el JSON de rangos |
| Conteo 8–12 ambiguo (con/sin puntos y guion) | Media | Medio | Cerrar en T-01 antes de codificar; documentar decisión |
| HP bloqueado solo en Emisión especial y se “arregla” Create pero no el flujo real de Operaciones | Media | Alto | T-07 priorizada; confirmar con Operaciones qué pantalla usan |
| `IsEnabledFiscalIdValidation=true` dispara lógica MX en Chile | Baja | Medio | T-06: desactivar flag o acotar `calculaRFC` por país |
| Regresión multi-país por editar archivo compartido | Baja | Alto | Solo tocar `PaisCL` y vistas `*CHL*`; smoke MX/CO en T-10 |

---

## 12. Notas para el programador

**Hallazgos de código (pre-plan):**
1. `PaisCL.GetAdditionalDealerElements` / `GetAdditionalContractBeneficiaryVehicleElements`: `min=max=12`, mensaje fijo 12.
2. `_BeneficiarioCHL.cshtml` y varias pantallas CHL: `data-mask="99.999.999-w"` + `maxlength="12"` en dealers → formato fijo.
3. HP longitud fija: `_DatosVehiculoEmEspecialCHL.cshtml` → `data_mask="999"`.
4. `ValidateRFC` no implementado; el flag fiscal en Create controla `calculaRFC()` (RFC México), no una validación de estructura RUT.

**Preguntas abiertas del PRD — recomendaciones para T-01:**
| Tema | Recomendación técnica provisional |
|---|---|
| RUT conteo 8–12 | Contar **caracteres del valor capturado** (como hoy con formato). Si se mantiene máscara con puntos/guion, el mínimo efectivo suele ser ~11–12; si se necesita aceptar RUTs cortos reales, relajar máscara o usar máscara opcional/flexible. |
| HP máximo | Sin máximo de longitud de dígitos en MVP (solo entero ≥ 0, al menos 1 carácter cuando el campo es requerido). No tocar pricing. |
| Backend / flag fiscal | Preferir `IsEnabledFiscalIdValidation() => false` en Chile. |
| Alcance campos | MVP: beneficiario + dealer (ambos usan 12 hoy). Cotizador/endosos/asesores: incluir si usan la misma máscara fija y Operaciones los usa en el dolor reportado. |

**Fuera de alcance (no implementar):** dígito verificador, cambios MX/CO, redesign UI, cambios de pricing por HP.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Descubrimiento** | Decisiones de conteo RUT, inventario de máscaras/pantallas | T-01 a T-02 | 0.5 – 1 día | 69 |
| **Fase 1 — RUT Chile (P1)** | PaisesService + máscaras + dealers + flag fiscal | T-03 a T-06 | 1 – 2 días | 70 |
| **Fase 2 — HP Chile (P1)** | Quitar máscara fija HP + verificar Create/cotizador | T-07 a T-08 | 0.5 – 1 día | 71 |
| **Fase 3 — Pruebas** | Matriz Chile + smoke MX/CO | T-09 a T-10 | 0.5 – 1 día | 72 |
| **Total proyecto (P1)** | | 10 tareas | ~2.5 – 5 días hábiles (≈ 0.5 – 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 (MVP funcional) | T-01 a T-08 | ~2 – 4 días hábiles | — |

> **Notas sobre la tabla:**
> - Alcance MVP = P1 completo (RUT + HP). No hay P2/P3 en el PRD.
> - La columna **ID (BD)** la llena el flujo al registrar el plan en la base de datos (`pm_plan_fase.id`); no editarla a mano.

> **Riesgo de deadline:** el PRD no define fecha límite explícita. Con ~2.5–5 días hábiles el alcance cabe cómodo en una semana de un desarrollador. Si Operaciones urge desbloqueo, priorizar **T-03 + T-04 + T-07** (mínimo que desbloquea captura) y dejar T-05/T-06/smoke como cierre inmediato después.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
