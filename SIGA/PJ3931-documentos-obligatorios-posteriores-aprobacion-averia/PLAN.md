# Plan de Desarrollo — Documentos Obligatorios Posteriores a la Aprobación de la Avería (PJ3931)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ3931-documentos-obligatorios-posteriores-aprobacion-averia/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + AveriasBusinessRules) |
| Rama base | `develop` |
| Rama | `feature/PJ3931-documentos-obligatorios-posteriores-aprobacion-averia` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ3931` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | 25 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Incluir en la notificación al **taller**, en cada cambio de estatus **post-aprobación** que tenga documentos requeridos, el **listado de documentos obligatorios** del nuevo estatus. El MVP **solo informa** (no recibe, adjunta ni valida documentos).

- **Arquitectura:** modificación sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas + AveriasBusinessRules). No se crea microservicio ni endpoints REST nuevos.
- **Stack:** .NET 8 / C#, `IEmailSender`, PostgreSQL (sin migración de esquema en MVP), configuración vía `appsettings` / `IOptions`.
- **Alcance multi-país:** MEX, COL y CHL (misma lógica; textos/listados parametrizables por país donde ya exista divergencia).

**Hallazgo técnico (cierra pregunta abierta del PRD §14 — mecanismo de correo):**

| Pregunta PRD | Hallazgo en código |
|---|---|
| ¿`NotificaCambioEstatus` sirve para este fin? | **No tal cual.** Hoy notifica al **beneficiario** (`poliza.beneficiario.seguimiento_correo_dato`) con textos de `EstatusBeneficiario` en `appsettings.json`. No usa plantilla, no mira documentos y **no envía al taller**. |
| ¿Ya existe correo al taller con listado? | Sí, parcial: `NotificaDatosParaPagoTaller` (AveriasBusinessRules ~461–517) al pasar a **Aceptada**. MEX incluye listado de documentación 2025; COL/CHL validan/solicitan datos fiscales-bancarios. Deja traza en `seguimiento_averia`. |
| ¿Dónde están los “documentos por estatus”? | **No hay catálogo central.** Están dispersos: (1) opciones UI en `_Edit.cshtml` ~442–498 por `nombre_estatus` + rol; (2) texto hardcodeado en `NotificaDatosParaPagoTaller`; (3) validaciones puntuales (`CanAskForValidation`, `Payment` exige finiquito, etc.). |

**Decisión de diseño (MVP):**

1. **No reutilizar `NotificaCambioEstatus` como canal al taller** (evitar mezclar beneficiario y taller).
2. Crear un método dedicado (p. ej. `NotifyWorkshopRequiredDocumentsOnStatusChange`) en `AveriasBusinessRules`, invocado desde los mismos puntos post-aprobación donde ya hay cambio de estatus (o junto a ellos).
3. **Centralizar** la definición de documentos requeridos por estatus (y variante por país si aplica) en configuración/`IOptions` (fuente única mantenible), alineada con lo que hoy muestra `_Edit.cshtml` + el listado de `NotificaDatosParaPagoTaller` para Aceptada.
4. **Reutilizar** la resolución de correo del taller ya usada en `NotificaDatosParaPagoTaller` (usuario del taller / taller reparador; fallback a `EmailPagos` si no hay usuario).
5. Fallo de envío: **no bloquea** el cambio de estatus; log + traza en `seguimiento_averia` (mismo patrón que `NotificaDatosParaPagoTaller`).
6. Solo notificar si el estatus tiene lista no vacía (RF-05).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Operaciones / Averías; revisión Alexis Salvador Herrera García)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — ya up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] **Validar con operación** el listado exacto de documentos por estatus post-aprobación (Aceptada / Taller / Solucionada / Cerrada u otros) vs. lo que hoy refleja `_Edit.cshtml` y `NotificaDatosParaPagoTaller`
- [ ] Ambiente local con correo de prueba (Gmail MX / MS365 COL según país) y taller con usuario SIGA con email válido
- [ ] No se requieren secrets nuevos; sí configuración nueva en `appsettings` (listas por estatus / país)

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature sobre componente existente, sin desplegar servicio nuevo (`rules/infraestructura.md` — mantiene EC2).

```
[Cambio estatus post-aprobación]
  → AveriasController / AveriasBusinessRules (Resolucion, InWorkshop, CarFixed, Payment, …)
      → NotifyWorkshopRequiredDocumentsOnStatusChange(averia)
          → ¿estatus en RequiredDocumentsByStatus? (IOptions)
          → No  → no envía listado
          → Sí → resuelve email taller (mismo criterio NotificaDatosParaPagoTaller)
               → IEmailSender.SendEmailAsync(taller, asunto, HTML con listado)
               → seguimiento_averia (trazabilidad)
               → Log (éxito / error; error no aborta el flujo)
```

**Estatus post-aprobación de referencia (flujo actual):**

```
Validación → Resolucion → Aceptada (~id 10)
                → InWorkshop → Taller (~id 3)
                → CarFixed → Solucionada
                → Payment → Cerrada (~id 5)
```

**Relación con correo existente en Aceptada:**

- Hoy `NotificaDatosParaPagoTaller` ya manda instrucciones + listado en Aceptada (MEX).
- El plan debe **evitar doble correo redundante** en Aceptada: o bien (a) enriquecer/unificar ese envío para que sea la fuente del listado de Aceptada, o (b) dejar Aceptada cubierta solo por `NotificaDatosParaPagoTaller` y usar el método nuevo solo en estatus posteriores (Taller / Solucionada / …). **Decisión a confirmar en T-02** con operación; recomendación técnica: **opción (b)** para minimizar riesgo de regresión en el correo de pago ya conocido por talleres.

---

## 4. Tareas de desarrollo

### Fase 0 — Alineación funcional y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b feature/PJ3931-documentos-obligatorios-posteriores-aprobacion-averia`
  - Archivos: N/A
  - Criterio de completitud: rama local basada en `develop` actualizado

- [ ] **T-02** — Cerrar preguntas abiertas con operación + inventario de código
  - Confirmar estatus post-aprobación en alcance y documentos exactos por estatus (y por país si difieren).
  - Confirmar estrategia Aceptada: unificar vs. dejar `NotificaDatosParaPagoTaller` y notificar solo estatus posteriores (recomendación: posteriores).
  - Confirmar formato de correo (asunto, idioma, remitente vía canal existente, HTML simple con `<ul>`).
  - Documentar mapa `id_estatus` / `nombre_estatus` ↔ documentos.
  - Archivos: nota en `PLAN.md` §12 / `AVANCE.md`
  - Criterio de completitud: lista congelada para implementar; sin bloqueos abiertos para Fase 1

### Fase 1 — Catálogo central + notificación al taller (P1)

- [ ] **T-03** — Introducir configuración de documentos requeridos por estatus (y país si aplica)
  - Archivos a crear/modificar:
    - `GarantiplusWeb/Options/` (o clase Options en AveriasBusinessRules) p. ej. `ClaimRequiredDocumentsOptions`
    - `GarantiplusWeb/appsettings.json` (y variantes país/env si existen): sección tipo `ClaimRequiredDocumentsByStatus`
    - Registro DI en `Program.cs` si aplica
  - Contenido: mapa `estatus` → lista de nombres de documento (solo los que deben notificarse al taller). Partir de `_Edit.cshtml` (roles taller) + listado MEX de `NotificaDatosParaPagoTaller` para Aceptada si entra en alcance.
  - Criterio de completitud: se puede leer por código la lista de un estatus sin tocar la vista; lista vacía = no notificar

- [ ] **T-04** — Implementar resolución de lista + método de notificación al taller
  - Archivos a modificar:
    - `AveriasBusinessRules/.../IAveriasBusinessRules.cs`
    - `AveriasBusinessRules/.../AveriasBusinessRulesAbstract.cs`
    - `AveriasBusinessRules/.../AveriasBusinessRules.cs` (nuevo método; reutilizar lógica de email/taller de `NotificaDatosParaPagoTaller` sin copiar en exceso)
  - Comportamiento: si hay docs → enviar HTML con estatus + `<ul>` de documentos; si no hay → no-op; catch → `Log.Error` sin relanzar; añadir `seguimiento_averia` con resultado (enviado / sin usuario / error).
  - Criterio de completitud: método invocable unitariamente; fallo de correo no propaga excepción al caller

- [ ] **T-05** — Enganchar el método en transiciones post-aprobación
  - Archivos a modificar: `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` y/o puntos en `AveriasBusinessRules` (`Resolucion` / `InWorkshop` / `CarFixed` / `Payment` / otros que confirmen T-02)
  - Llamar **después** del cambio de estatus persistido, sin alterar la lógica de negocio existente.
  - Revisar bug conocido en `InWorkshop` (`id_estatus_anterior` igual a `id_estatus`) **solo si** el nuevo disparador depende de ese seguimiento; si el método nuevo recibe el estatus destino explícito, documentar y no refactorizar de más.
  - Criterio de completitud: en cada transición en alcance con docs configurados se dispara un intento de correo al taller

- [ ] **T-06** — Ajustar/documentar convivencia con `NotificaDatosParaPagoTaller` (Aceptada)
  - Según decisión T-02: no duplicar listado en Aceptada, o alinear textos si se unifica.
  - Archivos: `AveriasBusinessRules.cs` (solo si hace falta) + nota en §12
  - Criterio de completitud: un solo correo con listado al taller por cambio a Aceptada (si Aceptada está en alcance)

### Fase 2 — Multi-país, trazabilidad y verificación (P2)

- [ ] **T-07** — Variantes por país en configuración (si T-02 lo exige)
  - MEX: listado completo tipo documentación pago.
  - COL/CHL: alinear con lo que hoy pide `NotificaDatosParaPagoTaller` no-MEX y con opciones UI aplicables.
  - Criterio de completitud: mismo código; distinto listado vía config/`HubBaseCountryCode` o clave por país

- [ ] **T-08** — Pruebas manuales por estatus y país
  - Casos: estatus con docs → correo con listado; estatus sin docs → sin listado/sin correo de docs; taller sin usuario → fallback/`EmailPagos` o traza; fallo SMTP simulado → estatus cambia igual + log/seguimiento.
  - Verificar MEX y al menos un país no-MEX si hay ambiente.
  - Criterio de completitud: checklist de §10 marcado; evidencias en AVANCE

- [ ] **T-09** — Commit final de la feature en la rama funcional
  - Mensaje al estilo Engine: `[PJ3931-documentos-obligatorios-posteriores-aprobacion-averia] …`
  - Criterio de completitud: push a `origin` de la rama feature (sin crear PR — eso lo hace el programador)

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | Ninguno (MVP) | No hay migración. Trazabilidad reutiliza `seguimiento_averia` (inserts de observación). |
| `email_queue` | Sin cambio de esquema | Solo aplica si el sender SMTP clásico está activo; Gmail/MS365 actuales no siempre persisten ahí. |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | No hay API nueva. Se extiende el flujo MVC/BusinessRules interno de SIGA Web. | N/A |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable / sección | Descripción | Ambiente |
|---|---|---|
| `ClaimRequiredDocumentsByStatus` (nombre final a definir en T-03) | Mapa estatus → documentos obligatorios a notificar al taller | Desarrollo / QA / Producción (mismos archivos `appsettings` por país) |
| `EmailPagos` (existente) | Fallback cuando el taller no tiene usuario SIGA | Ya existente |
| `EstatusBeneficiario` (existente) | **No modificar** para este MVP (sigue siendo canal beneficiario) | — |
| `ContactoGarantiplus` / `WhatsappGarantiplus` | Opcional en pie del correo al taller si se desea consistencia | Existente |

Secrets: ninguno nuevo. Correo sigue el provider ya configurado por país (`EmailSenderGmail` / `EmailSenderMS365`).

---

## 8. Consideraciones de seguridad

- No exponer datos del beneficiario innecesarios en el correo al taller (solo id avería, estatus, listado de documentos).
- Destinatario = email del usuario del taller asociado (o `EmailPagos` en fallback operativo ya existente).
- No adjuntar archivos ni enlaces firmados en el MVP.
- Secrets de SMTP/MS365 siguen fuera del código.
- Fallo de envío no debe usarse para inferir PII en logs; loguear id avería, estatus, destinatario enmascarado si aplica, y resultado.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin servicios AWS nuevos. Despliegue habitual de SIGA Web en EC2 por país.
- Sin cambios en ECS, RDS esquema, S3, Cloudflare o Route 53.
- Costo: solo volumen adicional de correos (bajo; un correo por cambio de estatus con docs).

---

## 10. Criterios de aceptación

- [ ] Ante un cambio de estatus **post-aprobación** con documentos configurados, el taller recibe correo indicando el nuevo estatus y el listado de documentos (RF-01, RF-02, RF-03, RF-04).
- [ ] Si el estatus **no** tiene documentos requeridos, no se agrega listado ni se genera la notificación de documentos (RF-05).
- [ ] El cambio de estatus **no falla** si el correo falla; queda registro (log y/o `seguimiento_averia`) (RNF-01, RNF-02).
- [ ] La lista de documentos es mantenible desde configuración (no solo strings sueltos en la vista) (RNF-03).
- [ ] Comportamiento verificado o parametrizado para MEX / COL / CHL (RNF-05).
- [ ] No se implementa carga ni validación de documentos (fuera de alcance MVP).
- [ ] `NotificaCambioEstatus` al beneficiario permanece intacto (sin regresiones).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| PRD asumía reutilizar `NotificaCambioEstatus` pero ese canal es del beneficiario | Alta (confirmado) | Medio | Método dedicado al taller; documentado en §1 |
| Listado en código/UI desalineado con operación | Media | Alto | T-02 obligatorio con operación antes de congelar config |
| Doble correo en Aceptada (`NotificaDatosParaPagoTaller` + nuevo) | Media | Medio | Decisión explícita T-02; default: no duplicar |
| Taller sin email / usuario SIGA | Media | Medio | Reutilizar fallback `EmailPagos` + traza en seguimiento |
| Bug `InWorkshop` (estatus_anterior == estatus) | Media | Bajo–Medio | Disparar por estatus destino explícito; no depender solo de `NotificaCambioEstatus` |
| Fatiga de correos por muchos cambios de estatus | Baja–Media | Bajo | Solo estatus con docs; no notificar en cada micro-seguimiento sin cambio real |
| Diferencias MEX vs COL/CHL en textos | Media | Medio | Config por país (T-07) |

---

## 12. Notas para el programador

1. **Pregunta abierta del PRD resuelta en código:** no usar `NotificaCambioEstatus` para el taller. Crear canal dedicado (o extender el patrón de `NotificaDatosParaPagoTaller`).
2. **Fuente de verdad de documentos hoy:** `_Edit.cshtml` (UI por rol) + texto de `NotificaDatosParaPagoTaller` (MEX). El MVP debe **externalizar** esa definición a config; no es obligatorio refactorizar la vista en la misma entrega (puede seguir hardcodeada hasta una fase posterior de unificación UI↔config).
3. **Archivos clave:**
   - `AveriasBusinessRules/.../AveriasBusinessRules.cs` — `NotificaCambioEstatus` (~1146), `NotificaDatosParaPagoTaller` (~430+)
   - `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` — callers de cambio de estatus
   - `GarantiplusWeb/Areas/Averias/Views/Averias/_Edit.cshtml` (~442–498) — docs por estatus UI
   - `GarantiplusWeb/appsettings.json` — `EstatusBeneficiario`, `EmailPagos`
4. **No refactorizar** de forma amplia AveriasBusinessRules salvo lo necesario para el método nuevo y enganches.
5. Validar con operación si **Solucionada** y **Cerrada** deben notificar listado (UI de Solucionada/Taller muestra más opciones a roles internos que al taller).
6. El programador gestiona PRs (`feature` → `pre-qa` → `qa`); Claude no crea PRs (`rules/version-control.md`).

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Alineación y rama (P1)** | Rama feature, validación con operación, mapa estatus↔documentos, decisión Aceptada | T-01 a T-02 | 0.5 – 1.5 días | 43 |
| **Fase 1 — Catálogo + notificación (P1)** | Options/appsettings, método de correo al taller, enganches post-aprobación, convivencia con `NotificaDatosParaPagoTaller` | T-03 a T-06 | 2 – 3.5 días | 44 |
| **Fase 2 — Multi-país y verificación (P2)** | Variantes país, pruebas manuales, commit/push rama | T-07 a T-09 | 1 – 2 días | 45 |
| **Total proyecto (P1+P2)** | | 9 tareas | **~3.5 – 7 días hábiles (≈ 1 – 1.5 semanas)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-06 | **~2.5 – 5 días hábiles (≈ 0.5 – 1 semana)** | — |

> **Notas sobre la tabla:**
> - P1 entrega el MVP funcional (notificar listado en estatus post-aprobación con docs).
> - P2 endurece multi-país y verificación; si el deadline aprieta, P1 en un solo país (MEX) puede desplegarse primero con config mínima para COL/CHL.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite explícita. Con ~3.5–7 días hábiles el alcance completo es acotado. Si operación tarda en congelar el listado (T-02), ese es el único cuello crítico: sin lista validada no se debe implementar textos “inventados”. Un segundo desarrollador aporta poca compresión (trabajo mayormente secuencial en AveriasBusinessRules); priorizar T-02 temprano.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
