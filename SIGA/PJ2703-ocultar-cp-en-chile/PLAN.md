# Plan de Desarrollo — Ocultar Código Postal (CP) en Chile (PJ2703)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ2703-ocultar-cp-en-chile/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + PaisesService) |
| Rama base | `develop` |
| Rama | `feature/PJ2703-ocultar-cp-en-chile` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ2703` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | 22 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Asegurar que el **Código Postal (CP)** no se muestre ni se capture en el flujo de emisión de contratos de **Chile**, sin afectar México ni Colombia, y sin migrar ni eliminar la columna en BD.

- **Arquitectura:** cambio puntual sobre monolito SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). Sin microservicio nuevo ni API.
- **Stack:** .NET 8 / C#, Razor Views, jQuery Validate (cliente), PostgreSQL (sin migración).
- **Mecanismo existente de regionalización:** el CP de emisión no vive en `_BeneficiarioCHL`, sino en el partial de localidades (`_LocalidadesMEX` como fallback de CHL), controlado por `ViewBag.LocalidadesShowPostalCode` ← `PaisCL.localidades_show_postal_code`.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en código (`develop`) |
|---|---|
| ¿Hay CP en `_BeneficiarioCHL`? | **No.** Ese partial solo trae persona, RUT, teléfonos, email. El CP está en `_LocalidadesMEX` (fallback porque no existe `_LocalidadesCHL`). |
| ¿`PaisCL` exige CP? | **No.** Ya tiene `beneficiario_cp_requerido = false` y `localidades_show_postal_code = false`. |
| ¿Create emisión CHL debería mostrar CP hoy? | **No en `develop`.** `Create` y `EmisionEspecial` llaman `SetContractLocalidadesViewBag`; con el flag en `false` el bloque CP de `_LocalidadesMEX` no se renderiza. JS ya condiciona `buscacp` / rules con `localidadesShowPostalCode`. |
| ¿Modelo obliga CP? | `beneficiario_poliza.cp` tiene `[Display(Name="C.P.")]` **sin** `[Required]`. BD admite null. |
| ¿Partials exclusivos CHL? | `_BeneficiarioCHL` sí. Localidades es compartido vía flag (no partial CHL). |
| ¿Dónde sí sigue el CP en UI CHL? | **Cotizador** `CreateCHL.cshtml` (campo explícito). **Endosos** CHL (`_BeneficiaryEndorsementCHL`, `_TransferEndorsementCHL`, `_FullPackageAssignmentEndorsementCHL`) con `Cp` required — **fuera del alcance de emisión del PRD**. |

**Implicación del hallazgo:** el MVP de emisión Create/EmisionEspecial en `develop` **parece ya cubierto** por flags. El plan prioriza (1) verificar en ambiente CHL, (2) cerrar el hueco Chile-específico que aún muestra CP en Cotizador si Operaciones lo usa como parte del flujo, (3) no tocar MX/CO ni endosos en este folio.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local o QA con proyecto Chile (`HubBaseCountryCode` / país CHL) para probar Create (y Cotizador si aplica)
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de UI/reglas por país sobre componente existente.

```
[Operador Chile]
  → Contratos/Create (o EmisionEspecial)
      → Partial _BeneficiarioCHL   (sin CP — ya)
      → Partial _LocalidadesMEX   (CP gated por LocalidadesShowPostalCode)
      → JS: rules/buscacp solo si localidadesShowPostalCode
  → PaisCL.GetAdditionalContractBeneficiaryVehicleElements()
      → localidades_show_postal_code = false
      → beneficiario_cp_requerido = false
  → POST → beneficiario.cp null / vacío
  → PostgreSQL.beneficiario_poliza.cp (columna intacta)

[Cotizador Chile — hueco detectado]
  → Cotizador/CreateCHL.cshtml  (aún renderiza beneficiario.cp)
```

**Decisiones de diseño:**

1. **No inventar `_LocalidadesCHL`** solo para ocultar CP: el flag `localidades_show_postal_code` ya es el patrón oficial (misma vía que labels Región/Comuna).
2. **No quitar la columna ni el property `cp` del modelo** (fuera de alcance PRD; protege MX/CO e históricos).
3. **Endosos CHL fuera de MVP:** el PRD habla de emisión; documentar como follow-up si Operaciones lo pide.
4. **Cotizador CreateCHL:** incluir en Fase 1 porque es vista exclusiva CHL que aún muestra CP; si negocio confirma que Cotizador no aplica, marcar T-04 como N/A en AVANCE.
5. **Código existente:** no refactorizar Create compartido ni PaisMX/PaisCO.

**Fuera de alcance (confirmado):** migración/limpieza histórica, drop de columna, cambios MX/CO, endosos (salvo follow-up).

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b feature/PJ2703-ocultar-cp-en-chile`
  - Archivos: N/A
  - Criterio de completitud: rama local (y remote tras primer push) basada en `develop` actualizado

- [ ] **T-02** — Baseline CHL: confirmar comportamiento actual de emisión Create / EmisionEspecial
  - Abrir Create con proyecto Chile: verificar si el input `#beneficiario_cp` / label C.P. aparece en el HTML
  - Confirmar en Network/JSON de `CountryConfiguration` (o equivalente) que `beneficiario_cp_requerido === false`
  - Anotar en AVANCE: **ya oculto** vs **aún visible** (si visible, documentar causa: flag no aplicado, país incorrecto, build desactualizado, etc.)
  - Archivos: nota en `AVANCE.md` (cuando exista)
  - Criterio de completitud: baseline documentado; decide si T-03 es N/A o requiere fix

### Fase 1 — Ajustes Chile (P1)

- [ ] **T-03** — (Condicional) Corregir emisión Create/EmisionEspecial si T-02 muestra CP
  - Candidatos según causa:
    - Asegurar `SetContractLocalidadesViewBag` / `localidades_show_postal_code = false` en `PaisCL`
    - Revisar que `codigo_pais` del proyecto sea `CHL`
    - Evitar default `?? true` mal aplicado si ViewBag no se setea en algún path
  - Archivos candidatos:
    - `PaisesService/Classes/CL/PaisCL.cs`
    - `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs`
    - `GarantiplusWeb/Areas/Contratos/Views/Contratos/_LocalidadesMEX.cshtml` (solo si el gate falla; no romper MX)
  - Criterio de completitud: Create/EmisionEspecial CHL sin campo CP en DOM; MX/CO sin cambio
  - Nota: marcar N/A en AVANCE si T-02 confirma que ya está oculto

- [ ] **T-04** — Quitar CP del Cotizador Chile (`CreateCHL`)
  - Archivos a modificar: `GarantiplusWeb/Areas/Contratos/Views/Cotizador/CreateCHL.cshtml`
  - Acción: eliminar el bloque de label/input/validation de `beneficiario.cp` (líneas ~252–258); dejar Región/Comuna/dirección; revisar JS del mismo archivo por referencias a `#beneficiario_cp` / `buscacp` y condicionar o retirar si quedan huérfanas
  - Criterio de completitud: Cotizador CHL no renderiza CP; cotización se guarda sin el dato (null/vacío)
  - Nota: si Operaciones confirma que Cotizador está fuera de alcance, marcar N/A

- [ ] **T-05** — Confirmar que `PaisCL` no exige CP (sin cambio si ya correcto)
  - Archivo: `PaisesService/Classes/CL/PaisCL.cs` — `GetAdditionalContractBeneficiaryVehicleElements`
  - Verificar permanecen: `beneficiario_cp_requerido = false`, `localidades_show_postal_code = false`
  - Criterio de completitud: RF-04 satisfecho; sin tocar `PaisMX` / `PaisCO`

- [ ] **T-06** — (Solo si prueba lo exige) Ajuste server-side mínimo para no persistir/exigir CP en CHL
  - Candidatos: binding en Create POST / validaciones que lean `cp` vacío
  - Criterio de completitud: emisión CHL sin CP concluye OK; MX/CO intactos
  - Nota: condicional — N/A si T-07 pasa sin ella

### Fase 2 — Pruebas funcionales y cierre (P1)

- [ ] **T-07** — Prueba emisión Create CHL sin CP
  - Emitir contrato Chile sin capturar CP → éxito; en BD `beneficiario_poliza.cp` null/vacío
  - Criterio de completitud: RF-01/02/03; 0 bloqueos por falta de CP

- [ ] **T-08** — Prueba Cotizador CHL (si T-04 no es N/A)
  - Crear cotización sin CP → OK
  - Criterio de completitud: formulario limpio; sin error JS

- [ ] **T-09** — Smoke no-regresión MX (y COL si hay ambiente)
  - Create MX: CP visible y usable (lookup colonias); Create COL: CP según reglas actuales
  - Criterio de completitud: RF-05 / RNF-01

- [ ] **T-10** — Smoke visual CHL (RNF-04)
  - Tras quitar CP, el bloque Región/Comuna/dirección queda sin huecos/labels huérfanos
  - Criterio de completitud: UI coherente

- [ ] **T-11** — Commit y push de la feature
  - Mensaje al estilo Engine: `[PJ2703-ocultar-cp-en-chile] Ocultar código postal en emisión/cotizador Chile`
  - Criterio de completitud: cambios en rama remota; listo para PR hacia `pre-qa` (lo gestiona el programador)

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `beneficiario_poliza` | Ninguno | Columna `cp` se conserva; emisiones nuevas CHL pueden quedar null/vacías |

No hay migraciones EF ni scripts SQL.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | Sin endpoints nuevos. Se reutilizan Create / Cotizador / `CountryConfiguration` / `FindCP` existentes | Sin cambio de contrato |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No aplica | — |

Solo se requiere ambiente/proyecto con país Chile para validar UI.

---

## 8. Consideraciones de seguridad

- Sin cambios de IAM, roles ni políticas.
- No se exponen secrets nuevos.
- CP no es dato sensible crítico aquí; al dejar de capturarlo no se agregan logs del campo.

---

## 9. Consideraciones de infraestructura

- Sin recursos AWS nuevos. Despliegue como cualquier cambio de SIGA Web en EC2 (Chile).
- Costo incremental: nulo.
- Si T-02 confirma que `develop` ya oculta CP en Create pero producción Chile aún lo muestra, el “fix” puede ser **despliegue** además del hueco Cotizador — coordinar con TI.

---

## 10. Criterios de aceptación

- [ ] En emisión Create CHL no se renderiza el campo Código Postal / C.P. (RF-01 reinterpretado: localidades; RF-02)
- [ ] Emisión CHL concluye sin capturar/persistir CP (RF-03)
- [ ] `PaisCL` no exige CP (`beneficiario_cp_requerido` / `localidades_show_postal_code` en false) (RF-04)
- [ ] Formularios y reglas MX/CO de CP sin cambios (RF-05 / RNF-01)
- [ ] Cotizador CHL sin CP **o** explícitamente N/A por decisión de negocio
- [ ] Sin migración ni drop de columnas
- [ ] UI CHL sin labels/espacios huérfanos tras el retiro (RNF-04)
- [ ] Endosos CHL documentados como fuera de alcance / follow-up (no regresan MX/CO)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Ambiente Chile en prod aún no tiene el gate de `localidades_show_postal_code` | Media | Medio (ops sigue viendo CP pese a `develop`) | T-02 + coordinar deploy; T-03 si falta wiring |
| Operaciones reporta “emisión” pero el dolor real es Cotizador o Endosos | Media | Medio (cierre incompleto percibido) | T-04 Cotizador en P1; endosos como follow-up explícito |
| JS Cotizador referencia `#beneficiario_cp` tras quitar el input | Media | Medio (rompe submit) | Revisar scripts en CreateCHL al hacer T-04 |
| Consumidores aguas abajo asumen CP en Chile | Baja | Medio | RNF-02: smoke impresión/PDF si aplica; no limpiar históricos |
| Tocar `_LocalidadesMEX` rompe MX | Baja | Alto | Preferir flags en `PaisCL`; no hardcodear ocultar en partial compartido sin gate |

---

## 12. Notas para el programador

1. **Corrección al PRD:** RF-01 habla de `_BeneficiarioCHL`, pero el CP de emisión está en localidades (`_LocalidadesMEX` + flag). No buscar el campo dentro de `_BeneficiarioCHL`.
2. **Mucho del MVP Create ya está en `develop`.** No “reimplementar” flags que ya existen; verificar y solo parchear gaps.
3. **Endosos CHL** (`_BeneficiaryEndorsementCHL`, etc.) siguen mostrando CP required — **fuera de este folio**. Si Operaciones lo pide, abrir PJ/follow-up.
4. **No refactorizar** partials compartidos ni unificar cotizador con emisión.
5. El programador gestiona el PR (`feature/*` → `pre-qa` → `qa`); Claude Code no crea PRs salvo que se pida.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y rama (P1)** | Branch + baseline Create CHL | T-01 a T-02 | 0.25 – 0.5 días | 31 |
| **Fase 1 — Ajustes Chile (P1)** | Fix condicional Create + Cotizador CHL + confirmar PaisCL (+ server opcional) | T-03 a T-06 | 0.25 – 0.75 días | 32 |
| **Fase 2 — Pruebas y cierre (P1)** | Emisión, Cotizador, smoke MX/CO, UI, commit | T-07 a T-11 | 0.25 – 0.5 días | 33 |
| **Total proyecto (P1)** | | 11 tareas (varias condicionales/N/A) | **~0.75 – 1.75 días hábiles (≈ &lt; 1 semana)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-11 | **~0.75 – 1.75 días hábiles** | — |

> **Notas sobre la tabla:**
> - Todo el alcance del PRD es P1 (MVP UI emisión CHL). No hay P2/P3 formales; endosos serían follow-up fuera de tabla.
> - T-03 y T-06 son condicionales; T-04/T-08 pueden ser N/A. Si Create ya está OK y solo se toca Cotizador, el total tiende al piso (~0.75 día).
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite. Con ~1–2 días hábiles el cambio cabe en cualquier sprint corto. No se requiere segundo desarrollador ni recorte de alcance. Si solo falta deploy de `develop` a Chile + Cotizador, el esfuerzo es aún menor.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
