# Plan de Desarrollo — Bloqueo de pago de avería a contratos aún no pagados (PJ0288)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ0288-bloqueo-pago-averia-contrato-no-pagado/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web + AveriasBusinessRules + DataAccess / DataAccessColombia) |
| Rama base | `develop` |
| Rama | `feature/PJ0288-bloqueo-pago-averia-contrato-no-pagado` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ0288` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 41 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Insertar un **control en el paso de liquidación/pago de avería** (`POST Averias/Averias/Payment`, botón **Factura liquidada**): si el contrato asociado **no está pagado**, SIGA bloquea solo ese paso, marca la avería, avisa por correo al Country Manager del hub y exige autorización con motivo. Si el contrato se paga después, el mismo `Payment` **revalida** y libera solo.

- **Arquitectura:** feature sobre el monolito SIGA Web (EC2) + librería `AveriasBusinessRules`. Sin microservicio nuevo. La API Claims **no** cierra/liquida averías; queda fuera.
- **Stack:** .NET 8 / C#, Razor, `IEmailSender`, PostgreSQL. Scripts SQL en `GarantiplusWeb/BD/` replicados en cada hub (MX / COL / CHL).
- **“Pagado” en SIGA:** no existe un estatus literal `Pagado`. Alta = `contrato.estatus = "Registrado"`; al cobrar se pone `poliza.fecha_pago` y `contrato.estatus = "Activo"`. Reusar la regla de `ClaimValidator`: **no pagado** = `!poliza.fecha_pago.HasValue` (y estatus distinto de Activo/Caduco), **excepto** `id_momento_facturacion == 4` (factura por corte: el contrato se espera sin pago).

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| ¿Dónde está el paso de pago? | `AveriasController.Payment` (POST). UI: `_Edit.cshtml` botón **Factura liquidada** (estatus Solucionada; roles Taller / Usuario Agencia / Ejecutivo de Ventas). Pasa a estatus **Cerrada** si hay documento `finiquito`. **Hoy no mira** el pago del contrato. |
| ¿Rol Country Manager en Identity? | **No existe.** El flujo de “avería en contrato inactivo” ya llama “Country Manager” a los **emails** de `AutorizacionAverias:{codigo_pais}` (`AprobarRechazarAveria`, correo en `AveriasBusinessRules`). El rol Identity más cercano es `Gestor de Países` (no es el filtro de ese flujo). |
| ¿De dónde sale el correo del CM? | `AutorizacionAverias` en `appsettings` (lista `;` por país: MEX, COL, CHL, …). Un hub = un país. |
| ¿Hay que crear el rol? | **No en el MVP.** Reutilizar `AutorizacionAverias` para destinatarios **y** para quién puede autorizar (igual que la aprobación de registro). No sembrar `Country Manager` en `AspNetRoles`. |
| ¿Gestor de Países puede autorizar? | Solo si su email está en `AutorizacionAverias` de ese país. Ese rol, al abrir una avería, cae en **Details** (Edit redirige a quien no es taller/técnico/agencia). La UI de autorización va en **Details** (y banner también en Edit). |
| ¿Bitácora existente? | `seguimiento_averia` (visible en la avería) + `log_averia`. No hace falta tabla de auditoría nueva: columnas de autorización en `averia` + una fila de seguimiento. |
| ¿API Claims liquida? | No. Fuera de alcance. |
| ¿Por qué existen averías de contratos Registrado? | Flag `distribuidor.averias_en_contratos_no_activos`: permite **registrar** la avería (a veces estatus 12 En Aprobación). El pago al taller no estaba controlado. Este folio cierra esa fuga. |

**Implicación:** el cambio cabe en SIGA Web + script SQL + EF en ambos DataAccess. No rediseñar el flujo de avería ni el de cobro del contrato.

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] Acceso a `gp_4.0_siga`; rama `develop` actualizada (confirmado al generar el plan)
- [ ] `CLAUDE.md` presente ✅
- [ ] Permiso para correr el SQL en los hubs de prueba (idealmente COL, que es el caso de uso)
- [ ] `AutorizacionAverias` del hub de prueba con el email real del CM (no commitear correos personales)
- [ ] Contrato de prueba **Registrado** (`fecha_pago` null) con distribuidor `averias_en_contratos_no_activos = true`, avería en **Solucionada** con finiquito
- [ ] Contrato gemelo que se pueda pasar a Pagado (fecha_pago + Activo) para probar auto-liberación
- [ ] Usuario CM (email en `AutorizacionAverias`) y usuario taller/agencia que **no** esté en esa lista

---

## 3. Arquitectura del cambio

```
[Taller/Agencia]  "Factura liquidada"  →  POST /Averias/Averias/Payment
                                              │
                                              ▼
                                    ¿Contrato pagado?  (fecha_pago / ClaimValidator)
                                      │ sí                         │ no
                                      ▼                            ▼
                               Cierra (Cerrada)          ¿pago_autorizado_cm?
                                                           │ sí          │ no
                                                           ▼             ▼
                                                      Cierra      400 + marca
                                                                  correo CM (1 vez)
                                                                  resto del flujo intacto

[CM en Details]  motivo obligatorio  →  POST AuthorizeUnpaidContractPayment
                         guarda usuario/fecha/motivo + seguimiento
                         desbloquea Payment (no cierra la avería)

[Contrato se cobra]  →  siguiente Payment revalida fecha_pago → auto-libera (RF-09)
```

**Decisiones de diseño:**

1. **Punto único de bloqueo:** `Payment`. No tocar `CarFixed`, cambio de estatus, carga de documentos ni cierre por `_CerrarAveria`.
2. **Fuente de verdad del bloqueo:** se **calcula** en el momento (contrato actual + `pago_autorizado_cm`). No un estatus nuevo de avería (eso congelaría el flujo, contra RF-02).
3. **Columnas en `averia`:** autorización persistida (`pago_autorizado_cm`, usuario, fecha, motivo) + `notificacion_cm_pago_enviada` (un solo correo, RNF-04).
4. **Country Manager = `AutorizacionAverias:{codigo_pais}`**, mismo patrón que `AprobarRechazarAveria`. No rol Identity nuevo.
5. **Excepción momento 4:** no bloquear (misma regla que el alta). Si negocio pide bloquear también corte, se documenta como recorte/ampliación; el default es no romper hubs de factura por corte.
6. **Email:** fallar el send no desbloquea; log Serilog + `log_averia`; no reintentos automáticos (fuera de alcance).
7. **Liga del correo:** `/Averias/Averias/Details/{id}` (el CM no entra a Edit).
8. **No** filtrar por distribuidor más allá del contrato de la avería. Un hub = un país.
9. **EF en `DataAccess` y `DataAccessColombia`** con el mismo esquema.
10. Extraer la regla a una clase nueva en `AveriasBusinessRules` (inglés). No inflar más `AveriasController` (~4k líneas) salvo orquestar.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — Crear `feature/PJ0288-bloqueo-pago-averia-contrato-no-pagado` desde `develop`
  - Criterio de completitud: rama en origin

### Fase 1 — Persistencia (P1)

- [ ] **T-02** — Script SQL de columnas en `averia`
  - Archivos: `GarantiplusWeb/BD/2026-08-17_bloqueo_pago_averia_contrato/01_averia_autorizacion_pago.sql`
  - Columnas: `pago_autorizado_cm bool NOT NULL DEFAULT false`, `usuario_autoriza_pago varchar(256)`, `fecha_autorizacion_pago timestamp`, `motivo_autorizacion_pago text`, `notificacion_cm_pago_enviada bool NOT NULL DEFAULT false`
  - Criterio de completitud: script idempotente (`ADD COLUMN IF NOT EXISTS`); listo para MX, COL y CHL

- [ ] **T-03** — Modelos EF MX y COL
  - Archivos: `DataAccess/Models/averia.cs`, `DataAccess/garantiplus_dbContext.cs`, espejo en `DataAccessColombia/`
  - Criterio de completitud: propiedades mapeadas; sin migración EF (el SQL se aplica a mano, como el resto de SIGA)

### Fase 2 — Regla de bloqueo (P1)

- [ ] **T-04** — Helper `ClaimPaymentGuard` (nombre en inglés)
  - Archivos: `AveriasBusinessRules/src/AveriasBusinessRules/Classes/ClaimPaymentGuard.cs` (+ interfaz si el proyecto ya inyecta así)
  - Métodos: `IsContractPaid(poliza)`, `CanApproveWorkshopPayment(averia)`, `IsCountryManager(email, countryCode)`, destinatarios CM
  - Pagado = misma semántica que `ClaimValidator` (fecha_pago + Activo/Caduco; skip momento 4)
  - Criterio de completitud: tests unitarios en `AveriasBusinessRules.Tests` para pagado / no pagado / autorizado / momento 4

- [ ] **T-05** — Enforzar en `POST Payment`
  - Archivos: `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs`
  - Includes: `poliza`, `poliza.contrato`, `poliza.contrato.distribuidor`, `taller`
  - Si no pagado y no `pago_autorizado_cm` → no cambiar estatus; JSON `{ success:false, errors:"…" }` en español; disparar marca/correo si aplica
  - Si pagado ahora → auto-liberar (log + seguimiento) y cerrar como hoy
  - Si `pago_autorizado_cm` → cerrar como hoy
  - Criterio de completitud: un POST de taller no puede cerrar una avería de contrato Registrado sin autorización

### Fase 3 — UI y autorización CM (P1)

- [ ] **T-06** — Marca visible y mensaje al operador
  - Archivos: `_Edit.cshtml` (ocultar/deshabilitar **Factura liquidada** si bloqueado), `Edit.cshtml`, `Details.cshtml` (badge + alerta: pendiente de autorización del country manager + motivo)
  - Criterio de completitud: el taller ve el bloqueo y no el botón activo; el resto del Edit sigue usable (documentos, estatus Taller/Solucionada)

- [ ] **T-07** — Acción autorizar (solo CM) con motivo obligatorio
  - Archivos: nuevo POST `AuthorizeUnpaidContractPayment(int id, string motivo)` en `AveriasController`; modal en `Details.cshtml` (y Edit si el CM pudiera editar)
  - Authorize: email del usuario actual ∈ `AutorizacionAverias[codigo_pais]` (mismo split `;` que `AprobarRechazarAveria`). Motivo trim no vacío. No cierra la avería; solo setea `pago_autorizado_cm` + campos + `seguimiento_averia`
  - Criterio de completitud: un no-CM recibe error en español; un CM sin motivo no pasa; con motivo, el siguiente Payment del taller sí cierra

### Fase 4 — Correo, bitácora y eventos (P1)

- [ ] **T-08** — Correo al CM (una vez)
  - Archivos: helper o método en `AveriasBusinessRules` (reutilizar `IEmailSender`, `emailType` existente p.ej. `"Autorización"`)
  - Contenido (español): contrato, avería, taller, monto (`total_indemnizacion` / `importe_indemnizacion`), país/hub, liga a Details. Si `AutorizacionAverias` vacío: bloquear igual, log de warning (riesgo del PRD §13)
  - Criterio de completitud: primer intento de pago (o primer GET en estatus liquidable) envía; el segundo no duplica (`notificacion_cm_pago_enviada`); fallo de SMTP no abre el pago

- [ ] **T-09** — Bitácora + logs BI
  - `seguimiento_averia` en bloqueo, autorización y auto-liberación (usuario, fecha, observaciones con motivo/contrato/avería)
  - `log_averia.log_type` alineado a los eventos del PRD: `pago_averia_bloqueado_contrato_no_pagado`, `notificacion_country_manager_enviada`, `pago_averia_autorizado_country_manager`, `pago_averia_liberado_automatico_contrato_pagado`
  - Serilog en inglés para técnicos
  - Criterio de completitud: Details muestra el seguimiento; `log_averia` tiene la fila del evento

### Fase 5 — Validación (P1)

- [ ] **T-10** — COL (solicitante): avería Solucionada + contrato Registrado → bloqueo + correo CM → CM autoriza con motivo → taller liquida
- [ ] **T-11** — Auto-liberación: mismo escenario, se paga el contrato, Payment cierra sin CM
- [ ] **T-12** — No-regresión: contrato Activo/con fecha_pago liquida como hoy; momento 4 no se bloquea; `AprobarRechazarAveria` (estatus 12) intacto; MX/CHL mismo código

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `averia` | Modificación | 5 columnas de autorización/notificación (T-02). Sin índice extra (acceso por PK). |
| `estatus_averia` | Sin cambio | No hay estatus nuevo |
| `seguimiento_averia` / `log_averia` | Sin esquema | Se insertan filas |

Aplicar el SQL **a mano** en cada hub (MX, COL, CHL). Espejar modelos EF.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/Averias/Averias/Payment/{id}` | Bloquea si contrato no pagado y no hay autorización CM; auto-libera si ya pagó | Modificado |
| POST | `/Averias/Averias/AuthorizeUnpaidContractPayment/{id}` | Solo emails `AutorizacionAverias`; motivo obligatorio | Nuevo |
| GET | `/Averias/Averias/Edit/{id}` y `Details/{id}` | Banner / badge / modal CM | Modificado (vista) |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `AutorizacionAverias:{MEX\|COL\|CHL\|…}` | Ya existe. Destinatarios y quién autoriza. Vacío = nadie autoriza ni recibe correo; el bloqueo se mantiene | Por hub |
| *(ninguna key nueva)* | Reutilizar `IEmailSender` / proveedor por país | — |

No commitear correos de personas en `appsettings.json`.

---

## 8. Consideraciones de seguridad

- El botón se oculta, pero el control real es el **POST**: `Payment` no tiene `[Authorize]` propio (solo el de clase). Cualquier rol del controller podría llamarlo; la guarda va en servidor.
- Autorizar **no** usa solo `Gestor de Países`: ese rol es más amplio. Misma lista de emails que la aprobación de registro.
- Motivo obligatorio; no autorizar con string vacío.
- No abrir `Payment` ni la autorización a anónimos.
- No loguear el cuerpo completo de correos con PII innecesaria en Serilog.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin AWS nuevo. Correo = Gmail (MX) / MS365 (CO) ya cableado en `Program.cs`.
- SQL manual en RDS/PostgreSQL de cada hub antes del deploy de la Web.
- Mismo binario SIGA Web para MX/CO/CL.

---

## 10. Criterios de aceptación

- [ ] **RF-01 / RF-02:** `Payment` consulta el contrato; si no está pagado, no pasa a Cerrada; Taller/Solucionada y documentos siguen.
- [ ] **RF-03:** Badge/alerta “pendiente de autorización del country manager” con el motivo del bloqueo.
- [ ] **RF-04:** Un correo al CM del hub (contrato, avería, taller, monto, país, liga a Details).
- [ ] **RF-05 / RNF-01:** Solo emails de `AutorizacionAverias` autorizan; otro rol no.
- [ ] **RF-06 / RF-07 / RF-08:** Motivo obligatorio; queda usuario, fecha, motivo, contrato, avería; después el pago procede.
- [ ] **RF-09 / RNF-03:** Si aparece `fecha_pago` (estatus Activo), el siguiente Payment cierra sin CM.
- [ ] **RF-10 / RNF-05:** Mismo código en todos los hubs; CM por `codigo_pais`.
- [ ] **RNF-04:** Falla de correo ≠ desbloqueo.
- [ ] **RNF-06 / RNF-07:** Logs de los 4 eventos; mensaje claro al operador.
- [ ] Contrato ya pagado: liquidación igual que hoy.
- [ ] Momento de facturación 4: no se bloquea (salvo que negocio lo revierta antes de ejecutar).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `AutorizacionAverias` vacío o emails de prueba | Alta | Alto | Bloquear igual; log; validar config por hub antes de prod |
| Definición “Pagado” distinta entre hubs | Media | Alto | Reusar `ClaimValidator`; excepción momento 4 explícita |
| CM entra a Details, no a Edit | Alta | Medio | UI y liga de correo en Details |
| AveriasController enorme / conflictos de merge | Alta | Medio | Lógica en `ClaimPaymentGuard`; toques mínimos al controller |
| SQL no aplicado en un hub | Media | Alto | Checklist de deploy; la Web fallaría al leer columnas |
| Carrera: dos clics de Payment | Baja | Bajo | El segundo ve Cerrada o el mismo bloqueo; no se pide lock extra |
| Momento 4 bloqueado por error | Media | Alto | Tests + T-12 |

---

## 12. Notas para el programador

1. **No confundir** este folio con el flujo estatus 12 **En Aprobación** (`Aprobacion.cshtml` / `AprobarRechazarAveria`): ese es el **alta** de avería en contrato inactivo. Este es el **pago al taller**. No mezclar pantallas ni estatus.
2. Botón de negocio: **Factura liquidada**, no un texto “Aprobar pago”.
3. Nombre Identity: no inventar `Country Manager`. Config: `AutorizacionAverias`.
4. Código nuevo en inglés; mensajes al usuario en español; logs técnicos en inglés.
5. Espejar **siempre** `DataAccess` y `DataAccessColombia`.
6. No refactorizar `AveriasController` ni `_Edit.cshtml` más de lo necesario.
7. Independiente de PJ4197 / PJ9626 / PJ9159 / PJ8967.
8. No commitear `appsettings.json` locales.

---

## 13. Relación de tareas y tiempos

Todo el alcance del PRD es **P1**. No hay P2/P3 (recordatorios, tablero BI, topes por monto: fuera de alcance).

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 115 |
| **Fase 1 — Persistencia (P1)** | SQL + EF MX/COL | T-02 a T-03 | 0.5 – 1 día | 118 |
| **Fase 2 — Regla de bloqueo (P1)** | Helper + POST Payment | T-04 a T-05 | 1 – 1.5 días | 116 |
| **Fase 3 — UI y autorización CM (P1)** | Banner, botón, POST CM | T-06 a T-07 | 1 – 1.5 días | 117 |
| **Fase 4 — Correo y bitácora (P1)** | Mail 1 vez + seguimiento/logs | T-08 a T-09 | 0.75 – 1.5 días | 120 |
| **Fase 5 — Validación (P1)** | COL + auto-liberación + no-regresión | T-10 a T-12 | 1 – 1.5 días | 119 |
| **Total proyecto (P1)** | | 12 tareas | ~4.5 – 7.5 días hábiles (≈ 1 – 1.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 5 | T-01 a T-12 | ~4.5 – 7.5 días hábiles (≈ 1 – 1.5 semanas) | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre ~5–8 días. No hay recorte P2: si aprieta el tiempo, lo último en recortar sería T-04 tests (no el bloqueo en servidor). El SQL debe existir en el hub **antes** de desplegar la Web.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
