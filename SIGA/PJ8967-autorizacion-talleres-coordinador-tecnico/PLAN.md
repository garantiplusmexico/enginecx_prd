# Plan de Desarrollo — Autorización de talleres por Coordinador Técnico (PJ8967)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ8967-autorizacion-talleres-coordinador-tecnico/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web) + `gp_3.0_siga_api` (Claims / landings) |
| Rama base | `develop` |
| Rama | `feature/PJ8967-autorizacion-talleres-coordinador-tecnico` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ8967` |
| Fecha de generación | 2026-08-14 |
| Estado | Validado |
| ID plan (BD) | 39 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Ampliar el aviso de **solicitud de registro de taller** para que también lo reciban los usuarios con rol **`Coordinador Tecnicos`**, además de **`Administrador General`**. La aprobación/rechazo y la regla “primera acción decide” **ya existen** para el Coordinador Técnico en SIGA Web; el hueco real es el **correo** (y, en Chile, el ítem de menú).

- **Arquitectura:** feature sobre monolitos existentes (SIGA Web en EC2; API Claims en ECS). Sin servicio nuevo ni migración de BD.
- **Stack:** .NET 8 / C#, Razor, `IEmailSender` vigente. PostgreSQL intacto.
- **Rol exacto:** `Coordinador Tecnicos` (sin acento). Puesto de negocio: Gerente de Postventa.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| ¿El CT ya puede aprobar? | **Sí.** `TalleresController`: clase, `Solicitud` GET, `Solicitud` POST (aprobar) y `RechazarSolicitud` ya incluyen `Coordinador Tecnicos`. |
| ¿El CT ya ve Solicitudes en el menú? | **MX y COL sí.** **Chile no:** `_LeftMenuBar_CHL.cshtml` deja Solicitudes Talleres en `Administrador General\|Auditor`. |
| ¿Qué falta para RF-01? | `HomeController.EnviarCorreoSolicitudRegistroTallerAsync` solo consulta `Administrador General`. |
| ¿Primera acción decide? | **Ya.** Si `fecha_autorizacion_rechazo` tiene valor, GET/POST redirigen a `DetailsSolicitud` (liga “ya resuelta”). |
| ¿Tras la primera acción la liga caduca? | No caduca el token; muestra el detalle de solicitud ya resuelta. No rediseñar. |
| ¿Trazabilidad? | `registro_taller.usuario_autoriza_rechaza` + `fecha_autorizacion_rechazo` + `autorizado`. El rol se deduce de Identity; **no** hay columna de rol. |
| ¿Filtro por país/distribuidor? | Hoy AG se envía a **todos** los AG del hub (una BD = un país). Igual para CT. Cross-país no aplica: cada hub tiene su BD. Fuera de alcance filtrar por distribuidor. |
| ¿Hay otro alta de taller? | **Sí.** `gp_3.0_siga_api` `WorkshopsService.CreateWorkshopAsync` (landings) persiste `registro_taller` y **no envía correo**. Autorización “después en GarantiplusWeb”. Si Operaciones Colombia usa landing, hoy **nadie** recibe aviso. |

**Implicación:** el MVP de SIGA Web es un cambio pequeño de destinatarios (+ menú CHL). Completar RF-01 para landings implica el mismo aviso en Claims.

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] Acceso a `gp_4.0_siga` y, para T-05, `gp_3.0_siga_api`
- [ ] Rama `develop` actualizada (confirmado al generar el plan)
- [ ] `CLAUDE.md` presente en ambos repos ✅
- [ ] Usuario de prueba `Coordinador Tecnicos` con email real en el hub de prueba (idealmente COL)
- [ ] En local, `NotificacionesEmail:CorreosSolicitudRegistroTallerPruebas` vacío si se quiere probar destinatarios reales (si tiene valores, **sustituye** a AG y CT)
- [ ] No secrets nuevos en SIGA Web; Claims puede requerir URL pública de SIGA Web (T-05)

---

## 3. Arquitectura del cambio

```
[Taller se registra]
  ├─ SIGA Web  Home/RegistroTalleres
  │     → EnviarCorreoSolicitudRegistroTallerAsync
  │           destinatarios = AG ∪ Coordinador Tecnicos  (LockoutEnd == null)
  │           liga = /Averias/Talleres/Solicitud/{id}
  └─ API Claims  POST Workshops (landing)
        → mismo aviso (T-05) con SigaWeb:BaseUrl + misma liga

[AG o CT abre la liga]
  → TalleresController.Solicitud  [Authorize ya incluye Coordinador Tecnicos]
        ├─ pendiente → formulario Aprobar / Rechazar
        └─ ya resuelta → DetailsSolicitud

[POST Aprobar | Rechazar]
  → si fecha_autorizacion_rechazo tiene valor → DetailsSolicitud
  → si no → escribe usuario_autoriza_rechaza + timestamp (igual que hoy)
```

**Decisiones de diseño:**

1. **No reescribir** Aprobar/Rechazar ni la plantilla de correo (RNF-05). Solo ampliar el filtro de destinatarios.
2. **No filtrar por distribuidor** (PRD §6). Un hub = un país; “todos los CT” = todos los CT de esa BD.
3. **No añadir columna de rol** en `registro_taller`. RF-05 se cubre con username + fecha + `autorizado`; el rol se consulta en `AspNetUserRoles`.
4. **No tocar** la condición de carrera más allá de lo que ya hace AG (PRD: no cambiar la lógica de resolución).
5. **Chile:** añadir `Coordinador Tecnicos` al `profiles` de Solicitudes Talleres (y al padre Talleres si hace falta para ver el grupo).
6. **Landings:** T-05 en API Claims; si se recorta alcance, dejarlo explícito en el PR y el riesgo de solicitudes mudas.
7. **Override de pruebas:** si `CorreosSolicitudRegistroTallerPruebas` tiene emails, se sigue cortando el envío a roles (comportamiento actual). No “arreglarlo” en este folio.
8. **No incluir** `Administrador General Externo` en el correo (hoy tampoco está).

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — Crear `feature/PJ8967-autorizacion-talleres-coordinador-tecnico` desde `develop` en `gp_4.0_siga` (y la equivalente en `gp_3.0_siga_api` si se hace T-05)
  - Criterio de completitud: ramas en origin

### Fase 1 — Correo SIGA Web (P1)

- [ ] **T-02** — Incluir Coordinadores Técnicos en `EnviarCorreoSolicitudRegistroTallerAsync`
  - Archivos: `GarantiplusWeb/Controllers/HomeController.cs`
  - Cambio: la consulta de destinatarios debe incluir usuarios activos (`LockoutEnd == null`) con rol `Administrador General` **o** `Coordinador Tecnicos`. Deduplicar email (un usuario con ambos roles = un correo). Mismo `subject`, mismo cuerpo, misma liga, mismo `emailType: "Taller"`. Bucle actual (un Send por destinatario) se mantiene.
  - Criterio de completitud: con override de pruebas vacío, un alta por `/Home/RegistroTalleres` genera correos a AG y a CT del hub; con override lleno, el comportamiento de pruebas no cambia.

### Fase 2 — Menú Chile y verificación de autorización (P1)

- [ ] **T-03** — Menú Chile: Solicitudes Talleres visible para Coordinador Técnico
  - Archivos: `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_CHL.cshtml`
  - Cambio: añadir `Coordinador Tecnicos` al `profiles` de **Solicitudes Talleres**. Si el padre Averías ya lo incluye, basta el subítem. No tocar MX/COL (ya lo tienen).
  - Criterio de completitud: en hub CHL el CT ve Averías → Solicitudes Talleres.

- [ ] **T-04** — Verificar (sin ampliar de más) authorize de Aprobar/Rechazar
  - Archivos: `TalleresController.cs` (solo lectura / confirmación)
  - Criterio de completitud: CT puede abrir la liga, aprobar y rechazar; un rol no listado recibe 403; solicitud ya resuelta → `DetailsSolicitud`. No añadir roles nuevos.

### Fase 3 — Aviso en alta por landing / API (P1)

- [ ] **T-05** — Enviar el mismo correo al crear `registro_taller` desde Claims
  - Archivos: `gp_3.0_siga_api/Services/Claims/Services/WorkshopsService.cs`, `Program.cs` (DI si falta), `Options/` + `appsettings` (URL base de SIGA Web, sin hardcodear)
  - Cambio: tras `SaveChanges`, destinatarios AG ∪ CT (misma query). Liga `{SigaWeb:BaseUrl}/Averias/Talleres/Solicitud/{id}`. Reutilizar `IEmailSender` ya registrado. Mensajes de error de correo: log en inglés, no fallar el alta del taller si el mail falla (el registro ya quedó pendiente).
  - Criterio de completitud: POST anónimo de Workshops dispara correos a AG y CT; la liga abre SIGA Web.
  - Si se acuerda dejar landings fuera: tachar esta tarea en el plan y documentar el hueco. **Por defecto va en P1** porque RF-01 no distingue canal.

### Fase 4 — Validación (P1)

- [ ] **T-06** — Prueba COL (solicitante): registro web → CT recibe correo → aprueba; segundo usuario ve “ya resuelta”
- [ ] **T-07** — No-regresión: AG sigue recibiendo y pudiendo resolver; MX menú intacto; override de pruebas sigue cortocircuitando

---

## 5. Cambios en base de datos *(si aplica)*

No aplica.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `registro_taller` | Sin cambio | Ya tiene `usuario_autoriza_rechaza`, `fecha_autorizacion_rechazo`, `autorizado` |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/Home/RegistroTalleres` | Destinatarios AG + CT | Modificado (solo envío) |
| GET/POST | `/Averias/Talleres/Solicitud/{id}` | Ya autorizado para CT | Sin cambio de authorize |
| POST | `/claims/api/Workshops` (aprox.) | Aviso por correo tras el alta | Modificado si T-05 |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `NotificacionesEmail:EnviarCorreoSolicitudRegistroTallerAdministradores` | Flag existente; si `false` no se envía a nadie (AG ni CT) | Ya en SIGA Web |
| `NotificacionesEmail:CorreosSolicitudRegistroTallerPruebas` | Si hay valores, **reemplaza** destinatarios por rol | Dev; no commitear correos personales |
| `SigaWeb:BaseUrl` (Claims, T-05) | Origen de la liga (sin barra final), p. ej. URL de SIGA COL | local / QA / prod por país |

---

## 8. Consideraciones de seguridad

- La liga no es un token firmado: exige login y `[Authorize(Roles=…)]`. No abrir `Solicitud` a anónimos.
- No añadir otros roles al authorize de Aprobar/Rechazar.
- No loguear contraseñas del alta (el POST de aprobación ya genera pwd y la manda al taller; no tocar ese flujo).
- Claims: no hardcodear URL de SIGA; Options + appsettings.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin AWS nuevo. Correo = proveedor ya configurado por país (Gmail MX / MS365 CO).
- Claims T-05: solo config `SigaWeb:BaseUrl` en task definition / appsettings de cada ambiente.
- El mismo código SIGA Web aplica a MX/CO/CL; el menú CHL es el único diff de vistas.

---

## 10. Criterios de aceptación

- [ ] **RF-01:** Alta por formulario SIGA Web → correo a todos los AG **y** CT activos del hub.
- [ ] **RF-02:** Un CT puede Aprobar y Rechazar con la liga (misma pantalla que AG).
- [ ] **RF-03:** La primera resolución gana; la segunda llega a detalle “ya resuelta”.
- [ ] **RF-04:** MX y COL: menú ya OK; CHL: CT ve Solicitudes. Código de correo único para los tres hubs.
- [ ] **RF-05:** Queda `usuario_autoriza_rechaza` + fecha + `autorizado`.
- [ ] **RNF-01:** Otros roles no aprueban por la liga.
- [ ] **RNF-05:** Misma plantilla/asunto/`emailType`.
- [ ] **T-05 (si no se recorta):** alta por landing/API también avisa a AG y CT.
- [ ] AG no pierde el correo ni la capacidad de resolver.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `CorreosSolicitudRegistroTallerPruebas` en appsettings local/QA | Alta | Medio | Vaciar el array para la prueba; no commitear correos |
| Landings sin correo (hoy) | Alta | Alto | T-05 |
| Menú CHL sin CT | Alta | Medio | T-03 |
| Carrera entre dos clics simultáneos | Baja | Bajo | Ya existe para AG; PRD no pide rediseño |
| Muchos CT = muchos correos | Media | Bajo | Aceptado en MVP (igual que “todos los AG”) |
| CT sin usuarios en MX/CHL | Media | Bajo | Operación carga usuarios; el código no depende de eso |

---

## 12. Notas para el programador

1. Nombre de rol: **`Coordinador Tecnicos`**. Un typo deja el correo igual que hoy.
2. Deduplicar por email, no enviar dos veces al mismo buzón.
3. No refactorizar `TalleresController` (~500 líneas) ni el formulario de aprobación.
4. Independiente de PJ4197 / PJ9626 / PJ9159.
5. Mensajes de usuario existentes se dejan; logs nuevos en inglés.
6. **No** incluir cambios de `appsettings.json` con correos de personas.

---

## 13. Relación de tareas y tiempos

Todo el alcance es **P1**. No hay P2/P3 en el PRD.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Ramas feature | T-01 | 0.25 días | 103 |
| **Fase 1 — Correo SIGA Web (P1)** | Destinatarios AG ∪ CT | T-02 | 0.25 – 0.5 días | 104 |
| **Fase 2 — Menú CHL + verify (P1)** | Profiles Chile + authorize existente | T-03 a T-04 | 0.25 – 0.5 días | 107 |
| **Fase 3 — API landings (P1)** | Correo en Claims + `SigaWeb:BaseUrl` | T-05 | 0.75 – 1.5 días | 105 |
| **Fase 4 — Validación (P1)** | COL + no-regresión AG | T-06 a T-07 | 0.5 – 1 día | 106 |
| **Total proyecto (P1)** | | 7 tareas | ~2 – 4 días hábiles (≈ 0.5 – 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 4 | T-01 a T-07 | ~2 – 4 días hábiles | — |

> Si se recorta T-05 (landings), el total baja a **~1 – 2 días** (solo SIGA Web). El plan lo deja en P1 porque RF-01 no distingue el canal de registro.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre 2–4 días. El recorte natural si aprieta el tiempo es T-05, no el correo de SIGA Web.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
