# Plan de Desarrollo — Rangos de dígitos de cédula (Colombia) (PJ3976)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ3976-rangos-digitos-cedula-colombia/PRD.md` |
| Repositorio | `gp_4.0_siga` (`PaisesService` + GarantiplusWeb + Endosos) |
| Rama base | `develop` |
| Rama | `feature/PJ3976-rangos-digitos-cedula-colombia` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ3976` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 46 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Hoy Colombia configura longitudes de documento en **`PaisCO`**, el mismo patrón que el RUT de Chile (`PaisCL` 8–12). El front consume eso vía `CountryConfiguration` (contratos) y `GetAdditionalDealerElements` (distribuidores). El problema: los min/max de Colombia están en **caracteres del valor formateado** (puntos/guion) y el mensaje dice “10 a 11”, mientras la cédula se captura en `#cedula_id.ced-col` (no en `#beneficiario_rfc`). No hay `PadLeft` en código: **el usuario** rellena ceros para llegar al mínimo. El formateador de cédula ya admite hasta 10 dígitos y **no** exige 10.

El cambio: en **solo `PaisCO`**, cédula **7–10 dígitos** (contando solo `[0-9]`), NIT **10 dígitos**; mensajes acordes; las reglas jQuery sobre los campos COL reales; `EndosoRFC` alineado. Sin migración histórica. Sin tocar `PaisMX` / `PaisCL`.

- **Arquitectura:** ajuste de config por país en la librería existente + consumidores ya cableados.
- **Stack:** .NET 8, Razor, jQuery Validate.

**Hallazgo técnico (cierra las preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| ¿Dónde vive la longitud? | **`PaisCO.GetAdditionalDealerElements`**: `rfc_longitud_min/max = 10/11`, mensaje “RUC/Cédula … 10 y 11 caracteres”. **`GetAdditionalContractBeneficiaryVehicleElements`**: `beneficiario_rfc_min/max = 11/13` (desalineado del mensaje 10–11). Chile equivalente: `PaisCL` 8–12 + `rut-chl.js`. |
| ¿El front usa PaisesService? | Contratos: `GET Contratos/Contratos/CountryConfiguration` → `$("#beneficiario_rfc").rules('rangelength')`. **COL Natural no usa ese id**: usa `#cedula_id.ced-col`. COL Jurídica: `.nit-col` (máscara 10 dígitos + formato `XXX.XXX.XXX-Y`). Distribuidores: `$("#rfc").rangelength` con 10–11 **caracteres**. Asesores cédula: solo `required`. |
| ¿Relleno con ceros en código? | **No.** El formateador `.ced-col` quita no-dígitos, recorta a 10 y pone puntos. El mínimo 10 se siente en **distribuidores** (rangelength de caracteres: `1.234.567` = 9 chars → falla) y en **endoso** (`EndosoRFC`: COL solo 10 u 11). |
| ¿Backend duro? | `Endosos/Beneficiario/EndosoRFC.cs`: COL `_newValue.Length != 10 && != 11`. El modelo `beneficiario_poliza.rfc` **no** tiene `[MinLength]`. |
| Otros tipos (CE, pasaporte) | No hay captura aparte. **Fuera de alcance.** |
| NIT y DV | El input NIT ya toma **10 dígitos** y formatea el último como DV visual. No hay algoritmo de DV. **No validar DV.** |
| Conteo | `rangelength` cuenta **caracteres con puntos**. Hay que validar **solo dígitos**. |
| Histórico | Fuera de alcance. |

**Implicación:** no basta con bajar `rfc_longitud_min` a 7 en caracteres (un `1.234.567` tiene 9 chars). Hace falta regla de **longitud en dígitos** y aplicarla a `#cedula_id` / `.ced-col` y NIT, no solo a `#beneficiario_rfc`.

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] `develop` actualizado; `CLAUDE.md` presente ✅
- [ ] Hub **Colombia** (`HubBaseCountryCode` COL / `CountryBase` COLOMBIA)
- [ ] Probar: contrato persona Natural (cédula 7 y 10), Jurídica (NIT 10); alta distribuidor/asesor Natural; endoso de RFC
- [ ] Hub MX o CHL para no-regresión (no cambiar esos `Pais*`)

---

## 3. Arquitectura del cambio

```
PaisCO (única fuente COL)
  ├─ dealer: NIT 10 dígitos (mensaje NIT); cédula dealer si Natural → 7–10
  └─ contrato: cédula 7–10 dígitos; NIT 10 dígitos
        ↓
CountryConfiguration / GetAdditionalDealerElements
        ↓
Create.cshtml / Distribuidores / Asesores  → validador "digitlength"
EndosoRFC (COL) → 7–10 (cédula) / 10 (NIT) o 7–10 dígitos sin DV
```

**Decisiones de diseño:**

1. **Solo `PaisCO`.** No tocar MX/CL/otros.
2. Longitudes = **número de dígitos** (`value.replace(/\D/g,'').length`), no el string con puntos.
3. Cédula (Natural): min 7, max 10. NIT (Jurídica): exactamente 10 dígitos.
4. Mensajes en español: “La cédula debe tener entre 7 y 10 dígitos” / “El NIT debe tener 10 dígitos”. Quitar el texto “RUC/Cédula … 10 y 11 caracteres”.
5. Validador jQuery `digitlength` (min, max) reutilizable; Chile sigue en `rangelength` de caracteres/RUT.
6. Aplicar reglas a **`#cedula_id` / `.ced-col`** y **`.nit-col` / `#rfc`** en COL. No asumir `#beneficiario_rfc` en Create COL.
7. Formateador `.ced-col`: no rellenar ceros; el tope 10 se queda. No exigir 10 en el input handler.
8. `EndosoRFC` COL: aceptar 7–10 dígitos (solo `[0-9]`, ignorar puntos). No ampliar CRI/MEX.
9. No migrar históricos. No validar dígito de verificación.
10. Corregir el desfase actual 11–13 vs mensaje 10–11 **solo en CO**.

Si hace falta distinguir Natural/Jurídica en el DTO: propiedades extra opcionales en `AdditionalContractBeneficiaryVehicleElements` (default = el par único, para no rellenar los 10 `Pais*.cs`). Preferible: el JS COL elige el par según `tipo_persona` leyendo dos pares que `PaisCO` ya puede devolver (cédula vs NIT) vía CountryConfiguration ampliado **solo si el JSON actual no alcanza**.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — `feature/PJ3976-rangos-digitos-cedula-colombia` desde `develop`
  - Criterio de completitud: rama en origin

### Fase 1 — Config País CO (P1)

- [ ] **T-02** — Ajustar `PaisCO`
  - Archivos: `PaisesService/Classes/CO/PaisCO.cs` (`GetAdditionalDealerElements`, `GetAdditionalContractBeneficiaryVehicleElements`)
  - Cédula 7–10; NIT 10; mensajes nuevos; dealer alineado (Natural vs Jurídica si el combo ya existe en `_EditCOL`)
  - Criterio de completitud: MX/CL sin diff; CO expone 7–10 y 10

- [ ] **T-03** — Validador de dígitos + cablear front COL
  - Archivos: `Create.cshtml` (y Edit/EmisiónEspecial si copian las mismas rules); `Distribuidores/Create.cshtml` + `Edit.cshtml`; `Asesores/Create.cshtml` + `Edit.cshtml` si aplica
  - `digitlength` sobre `#cedula_id` / `.ced-col` (7–10) y NIT (10)
  - `CountryConfiguration`: no reventar si no existe `#beneficiario_rfc`; aplicar al campo COL real
  - Criterio de completitud: cédula 7 dígitos pasa; 6 falla; NIT 9 falla; puntos no cuentan

### Fase 2 — Backend y no-regresión (P1)

- [ ] **T-04** — `EndosoRFC` COL
  - Archivos: `Endosos/Beneficiario/EndosoRFC.cs`
  - Longitud sobre dígitos 7–10 (o 10 si el endoso es NIT y se puede saber tipo; si no, 7–10 dígitos numéricos)
  - Criterio de completitud: endoso con cédula de 7 dígitos no lanza; MX 12–13 igual

- [ ] **T-05** — MX/CL intactos
  - Criterio de completitud: RFC 12–13 y RUT 8–12 sin cambio de mensaje ni reglas

### Fase 3 — Validación (P1)

- [ ] **T-06** — COL: contrato Natural 7 y 10; Jurídica NIT 10; dealer/asesor; sin ceros añadidos al guardar
- [ ] **T-07** — Mensajes nuevos visibles; 6 dígitos rechazado; histórico con ceros sigue consultable (no se reescribe)

---

## 5. Cambios en base de datos *(si aplica)*

No aplica. `beneficiario_poliza.rfc` / `distribuidor.rfc` / `asesor.rfc` sin `[MinLength]`.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Contratos/Contratos/CountryConfiguration` | Puede devolver pares cédula/NIT si se amplía el JSON | Modificado si hace falta |
| GET | (dealer elements, ya usado por Distribuidores) | min/max CO | Modificado (origen PaisCO) |
| * | Endoso cambio RFC | Validación COL | Modificado |

---

## 7. Variables de entorno y configuración *(si aplica)*

No. Las longitudes viven en `PaisCO` (código), no en `appsettings`.

---

## 8. Consideraciones de seguridad

- Seguir aceptando solo dígitos en COL (EndosoRFC ya exige `All(char.IsDigit)` sobre el valor crudo; al quitar puntos hay que validar el **string limpio**).
- No relajar MX/CL.
- No loguear documentos completos.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Desplegar SIGA Web (referencia `PaisesService`) y el servicio **Endosos** si corre aparte (misma validación `EndosoRFC`).
- No API SIGA 3.0 (no valida estas longitudes).
- Hub Colombia.

---

## 10. Criterios de aceptación

- [ ] **RF-01:** Cédula COL 7–10 dígitos en captura (contrato y catálogos que pidan cédula).
- [ ] **RF-02:** No se insertan ceros a la izquierda.
- [ ] **RF-03:** NIT sigue en 10 dígitos.
- [ ] **RF-04 / RNF-02:** Rangos en `PaisCO` (mismo patrón que RUT).
- [ ] **RF-05 / RNF-03:** Front y `EndosoRFC` aceptan lo mismo.
- [ ] **RF-06 / RNF-04:** Mensajes hablan de 7–10 / 10 dígitos, no de “mínimo 10 caracteres”.
- [ ] **RF-07 / RNF-01:** MX y CHL sin cambio.
- [ ] **RNF-05:** Se guarda el número capturado (con o sin puntos de UI; **sin** ceros extra). Histórico no se toca.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Cambiar solo `beneficiario_rfc_min` y las rules siguen en `#beneficiario_rfc` | Alta | Alto | T-03: cablear `#cedula_id` |
| `rangelength` cuenta puntos (`1.234.567` = 9) | Alta | Alto | `digitlength` |
| `getElementById("beneficiario_rfc")` null en COL | Media | Medio | Guard / campo correcto |
| Endoso sigue en 10/11 y el alta ya acepta 7 | Alta | Alto | T-04 |
| Búsquedas: `001234567` vs `1234567` | Media | Bajo | Fuera de alcance (histórico) |
| NIT formateado 13 chars vs 10 dígitos | Media | Medio | Contar dígitos en `.nit-col` |

---

## 12. Notas para el programador

1. País: **`COL`** / `PaisCO`. Tipos de persona contrato: **`Natural` / `Juridica`**.
2. Independiente de PJ2613 / PJ1255 / PJ3423.
3. Código nuevo en inglés; mensajes al usuario en español.
4. No “arreglar” el formateador de NIT ni el RUT de Chile.
5. No implementar DV ni extranjería.
6. Espejo `DataAccess` / `DataAccessColombia` **no** aplica (sin modelo nuevo).
7. Compilar/probar en hub Colombia; no commitear `appsettings` locales.

---

## 13. Relación de tareas y tiempos

Todo el PRD es **P1**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 141 |
| **Fase 1 — Config y front COL (P1)** | PaisCO + digitlength + campos reales | T-02 a T-03 | 0.75 – 1.5 días | 142 |
| **Fase 2 — Backend (P1)** | EndosoRFC + no-regresión MX/CL | T-04 a T-05 | 0.25 – 0.75 días | 143 |
| **Fase 3 — Validación (P1)** | Contrato / catálogos / mensajes | T-06 a T-07 | 0.5 – 1 día | 144 |
| **Total proyecto (P1)** | | 7 tareas | ~1.75 – 3.5 días hábiles (≈ 0.5 – 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 3 | T-01 a T-07 | ~1.75 – 3.5 días hábiles | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre ~2–4 días. No hay recorte P2. Lo crítico es validar en hub COL con cédula de 7 dígitos real, no solo bajar un entero en `PaisCO`.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
