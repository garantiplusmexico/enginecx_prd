# Plan de Desarrollo — Ayuda contextual al subir documentos en averías (PJ7245)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ7245-ayuda-contextual-al-subir-documentos-en-averias/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + AveriasBusinessRules) |
| Rama base | `develop` |
| Rama | `feature/PJ7245-ayuda-contextual-al-subir-documentos-en-averias` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ7245` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | 29 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Mejorar la UX de la vista **Edit** de averías (estatus `Registrada`, roles Taller / Usuario Agencia) para que el taller vea en todo momento qué le falta para solicitar validación: ayudas contextuales por tipo de documento, checklist de pendientes en vivo y botón sticky "Solicitar validación" habilitado solo cuando todo está completo. Alinear y endurecer la validación de completitud en **frontend y backend** con una única fuente de verdad.

- **Arquitectura:** modificación puntual sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas + AveriasBusinessRules). Sin microservicio nuevo ni API REST nueva.
- **Stack:** .NET 8 / C#, Razor Views, jQuery + Dropzone, Tailwind utilitario ya presente (`tw-sticky`), PostgreSQL (sin migración).
- **Alcance de código:** `AveriasBusinessRules` (criterio unificado + validación en `AskForClaimReview`) + vistas/JS del Area Averias (`Edit`, `_Edit`, `_SolicitarValidacion`).
- **Sin cambios** en catálogo de tipos de documento del `<select>`, storage S3/`AddFiles`, flujo humano procede/cancela (`ClaimResolver`), ni BI/notificaciones.

**Hallazgo técnico (cierra supuestos del PRD):**

| Tema | Hallazgo en código |
|---|---|
| Criterio “puede solicitar” hoy | `CanAskForValidation`: docs `presupuesto` + `evidencia` + `sum(refaccion_averia) > 0` + estatus Registrada. |
| Criterio al enviar hoy | `AskForClaimReview`: solo `id_estatus == 1` y `documento_averia.Count > 0` (cualquier tipo). **Desalineado** vs el botón (rompe RNF-01). |
| km | Solo validado en JS `solicitarValidacion()`; **no** en BR al enviar. |
| Síntomas | Instrucciones UI; **no** bloquean envío ni `CanAskForValidation`. |
| Tipos requeridos | Hardcode en `CanAskForValidation` (`["presupuesto","evidencia"]`); options UI en `_Edit.cshtml`. |
| Sticky / checklist / tooltips | No existen en Edit; hay patrón `tw-sticky` en `Details.cshtml` reutilizable. |
| Botón hoy | Show/hide del panel `#_SolicitarValidacionPanel` (clase `hide`), no `disabled` sticky. |

**Decisión de diseño (MVP):**

1. **Fuente de verdad única** en AveriasBusinessRules: método que evalúe completitud y devuelva faltantes estructurados; lo usan el endpoint de checklist y `AskForClaimReview`.
2. **Criterio unificado MVP** = el de `CanAskForValidation` actual + **km > 0** (ya exigido en front). Síntomas **no** se agregan como bloqueantes salvo que Operaciones lo pida (fuera del criterio actual de código).
3. **UI mínima invasión:** barra sticky con checklist + botón; ayudas no invasivas junto al select de tipo; no rediseñar el resto de Edit.
4. **No parametrizar** el catálogo de tipos en BD (explícitamente fuera de alcance del PRD).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Operaciones / revisión técnica Alexis Herrera)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local con usuario rol **Taller** o **Usuario Agencia** y avería en estatus **Registrada**
- [ ] Confirmar con negocio (si hay duda): ¿km debe seguir siendo obligatorio? (recomendación del plan: **sí**, alinear front/back). ¿Síntomas deben bloquear? (recomendación: **no** en MVP)
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de UI + reglas de negocio sobre componentes existentes; despliegue sigue en EC2 (sin recurso AWS nuevo).

```
[Taller / Usuario Agencia]
  → GET Edit (AveriasController)
      → _Edit.cshtml (docs + ayudas) + barra sticky (checklist + botón)
      → JS refresca checklist tras docs / refacciones / km
  → GET CanAskForValidation (o extensión) → GetValidationCompleteness
  → POST Validacion → AskForClaimReview (misma completitud + log de faltantes)
      → AveriasBusinessRules (fuente de verdad)
      → PostgreSQL (averia, documento_averia, refaccion_averia) — sin cambio de esquema
```

**Contrato propuesto de completitud** (interno BR, expuesto al controller como JSON):

```text
{
  canSubmit: bool,
  missing: [
    { code: "document_presupuesto", label: "Documento: Presupuesto" },
    { code: "document_evidencia", label: "Documento: Evidencias de fallo" },
    { code: "budget", label: "Presupuesto / refacciones con importe" },
    { code: "km", label: "Kilometraje" }
  ]
}
```

Códigos estables en inglés; `label` en español para UI y mensajes de error (coding-guidelines: mensajes de usuario en español).

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Archivos: N/A (git)
  - Comando: `git checkout develop && git pull && git checkout -b feature/PJ7245-ayuda-contextual-al-subir-documentos-en-averias`
  - Criterio de completitud: rama local y remota creada; working tree limpio sobre `develop` actualizado

- [ ] **T-02** — Confirmar criterio de negocio de “requeridos” con el hallazgo técnico
  - Archivos: N/A (nota en AVANCE / comentario en PR interno)
  - Criterio de completitud: acuerdo documentado de que MVP = docs Presupuesto+Evidencia + budget>0 + km>0; síntomas no bloquean

### Fase 1 — Fuente de verdad y backend (P1)

- [ ] **T-03** — Introducir modelo de resultado de completitud
  - Archivos a crear: p.ej. `AveriasBusinessRules/.../Models/ClaimValidationCompleteness.cs` (o carpeta Classes existente del proyecto BR)
  - Criterio de completitud: tipo con `CanSubmit` + lista de faltantes (`Code`, `Label`); compilable; sin lógica aún

- [ ] **T-04** — Implementar `GetValidationCompletenessAsync` (o nombre alineado al estilo del proyecto) en AveriasBusinessRules
  - Archivos a modificar:
    - `AveriasBusinessRules.cs`
    - `AveriasBusinessRulesAbstract.cs`
    - `IAveriasBusinessRules.cs`
  - Lógica: estatus Registrada; docs `presupuesto`/`evidencia` (case-insensitive, igual que hoy); `budget = sum(refaccion)` > 0; `km > 0`; devolver faltantes
  - Criterio de completitud: `CanAskForValidation` puede delegar a este método (`return result.CanSubmit`); un solo array de tipos requeridos

- [ ] **T-05** — Endurecer `AskForClaimReview` con la misma completitud
  - Archivos: `AveriasBusinessRules.cs` (`AskForClaimReview`)
  - Si faltan requisitos: lanzar excepción (o resultado controlado) con mensaje claro en español listando faltantes; **no** cambiar a estatus Validación
  - Criterio de completitud: ya no basta “cualquier documento”; pasa solo si `GetValidationCompleteness` indica completo

- [ ] **T-06** — Observabilidad de rechazos (RNF-05)
  - Archivos: `AveriasController.Validacion` y/o BR
  - Log en inglés a nivel Warning/Error: id avería, usuario, códigos de faltantes (sin PII innecesaria)
  - Criterio de completitud: al forzar POST incompleto, el log contiene id + faltantes

- [ ] **T-07** — Exponer completitud al frontend
  - Archivos: `AveriasController.cs` — extender `CanAskForValidation` para devolver JSON rico `{ success, canSubmit, missing[] }` **o** acción nueva `ValidationCompleteness` manteniendo compatibilidad con callers actuales
  - Preferencia: extender respuesta de `CanAskForValidation` si el JS actual solo usa boolean; adaptar JS en Fase 2
  - Criterio de completitud: GET con avería incompleta/completa refleja la misma lista que usaría el POST

### Fase 2 — UI: ayudas, checklist y botón sticky (P1)

- [ ] **T-08** — Ayudas contextuales por tipo de documento (RF-01)
  - Archivos: `_Edit.cshtml` (sección `#documentacion_holder` / `#tipo_documento`)
  - Mapa estático de textos (español) para Presupuesto / Evidencia / Varios (y, si aplica, solo mostrar ayuda del tipo seleccionado o `title`/popover Bootstrap no invasivo)
  - **No** indicar formato/peso (fuera de alcance PRD)
  - Criterio de completitud: al elegir cada tipo (al menos Presupuesto y Evidencia), el taller ve descripción del contenido esperado sin modal bloqueante

- [ ] **T-09** — Barra sticky con checklist y botón (RF-02, RF-03, RF-04)
  - Archivos a modificar/crear:
    - `_SolicitarValidacion.cshtml` (o partial nuevo `_ClaimValidationSticky.cshtml` incluido desde Edit/`_Edit`)
    - `_Edit.cshtml` / `Edit.cshtml` (ubicación del panel; quitar dependencia de solo show/hide por `presupuesto_registrado` si choca con “siempre visible”)
  - Usar patrón `tw-sticky tw-top-[50px] tw-z-10` (como `Details.cshtml`)
  - Checklist renderiza `missing[]`; botón siempre visible, `disabled` / sin onclick efectivo hasta `canSubmit`
  - Criterio de completitud: con scroll en Edit, checklist+botón permanecen visibles; no tapan Dropzone ni otras acciones críticas (ajustar top/z-index)

- [ ] **T-10** — JS: refresco en vivo y validación al enviar (RF-05, RNF-01)
  - Archivos: `Edit.cshtml` (scripts `canAskForValidation`, `solicitarValidacion`, callbacks post-upload / refacciones / km)
  - Tras cambios relevantes → GET completitud → pintar checklist + enable/disable botón
  - En `solicitarValidacion`: si incompleto, mostrar faltantes y no POST; si completo, confirm + POST como hoy
  - Criterio de completitud: completar/quitar requisitos actualiza checklist sin recargar página; front y back rechazan el mismo set

- [ ] **T-11** — Mensajes de error claros cuando el backend rechaza (RNF-04)
  - Archivos: JS de respuesta de `Validacion` + mensaje desde BR
  - Criterio de completitud: POST incompleto (p.ej. bypass del disabled) muestra en pantalla la lista de faltantes legible

### Fase 3 — Verificación y no-regresión (P1)

- [ ] **T-12** — Prueba manual rol Taller / Usuario Agencia, estatus Registrada
  - Escenarios: incompleto (faltan docs / budget / km); completo; intento de POST forzado incompleto; happy path → estatus Validación
  - Criterio de completitud: checklist de §10 (criterios de aceptación) marcado

- [ ] **T-13** — No-regresión roles Técnico / Coordinador y otros estatus
  - Verificar que Edit en Validación/Taller, resolución, upload de otros tipos y Details no se rompen; sticky solo donde aplica (Registrada + Taller/Agencia)
  - Criterio de completitud: sin regresiones obvias en flujos no-taller

- [ ] **T-14** — Commit final en rama funcional (cuando el programador lo pida / al cerrar ejecución del plan)
  - Mensaje según `version-control.md`: `[PJ7245-ayuda-contextual-al-subir-documentos-en-averias] …`
  - Criterio de completitud: push a `origin/feature/PJ7245-ayuda-contextual-al-subir-documentos-en-averias`

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | Ninguno | Sin migraciones. Se reutilizan `averia`, `documento_averia`, `refaccion_averia`, `estatus`. |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta (MVC Area Averias) | Descripción | Estado |
|---|---|---|---|
| GET | `Averias/Averias/CanAskForValidation/{id}` | Extender respuesta JSON con `canSubmit` + `missing[]` (o acción hermana) | Modificado / posible nuevo |
| POST | `Averias/Averias/Validacion/{id}` | Misma ruta; rechazo por completitud alineada + log | Modificado (comportamiento) |
| — | REST API SIGA (`gp_3.0_siga_api`) | No aplica en este MVP | — |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No se requieren variables nuevas | — |

Textos de ayuda contextual: constantes/mapa en vista o partial (español). Si crecen, opcional mover a resource/static dict en el mismo proyecto — no a `appsettings` salvo preferencia del programador.

---

## 8. Consideraciones de seguridad

- Respetar `[Authorize(Roles = "Taller, Usuario Agencia")]` en `CanAskForValidation` / `Validacion`; no ampliar permisos.
- Antiforgery en POST se mantiene.
- Logs: id avería + username + códigos de faltantes; no loguear contenido de documentos ni datos personales del cliente.
- No secrets nuevos.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos. Despliegue del cambio con el release habitual de SIGA Web en EC2.
- Sin cambios S3 / Cloudflare / Route 53.
- Impacto de costo: nulo (solo código de aplicación).

---

## 10. Criterios de aceptación

- [ ] En Edit (Registrada, Taller/Agencia), hay ayudas contextuales no invasivas para al menos Presupuesto y Evidencia
- [ ] Checklist siempre visible lista los pendientes (docs requeridos, presupuesto/refacciones, km) y se actualiza en vivo
- [ ] Botón "Solicitar validación" siempre visible (sticky), deshabilitado si hay pendientes y habilitado solo cuando no hay faltantes
- [ ] Al intentar enviar incompleto (front), no se hace POST y se muestran faltantes
- [ ] Backend rechaza incompleto con mensaje claro aunque se omita la validación de front
- [ ] Backend acepta y pasa a “en validación” cuando el criterio unificado se cumple (mismo que checklist)
- [ ] Rechazo por completitud queda en log con id de avería, usuario y faltantes
- [ ] No se alteró el flujo humano de procede/cancela ni el catálogo de tipos del select
- [ ] Otras funciones de la vista Edit no se rompen (RF-07)
- [ ] Frontend y backend usan el mismo criterio (RNF-01)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Desincronía front/back si se duplican listas de requisitos | Media | Alto | Una sola función BR; UI solo consume su JSON |
| Sticky tapa controles (Dropzone, combos) | Media | Medio | Ajustar `top`/`z-index`; probar viewport móvil/desktop |
| Endurecer `AskForClaimReview` rompe talleres que hoy envían con “cualquier doc” | Media | Medio | Esperado por el PRD; comunicar a Operaciones; mensaje claro de faltantes |
| km no estaba en BR: talleres sin km no podrán enviar | Baja | Medio | Alinear con JS actual; confirmar en T-02 |
| Edit.cshtml muy cargado de JS → regresiones | Media | Medio | Cambios localizados; pruebas T-12/T-13; no refactor amplio |
| Rendimiento por polling de completitud | Baja | Bajo | Refrescar solo en eventos (upload, refacción, km), no interval |

---

## 12. Notas para el programador

1. **No refactorizar** AveriasController ni Edit completo; solo lo necesario para completitud + UI del MVP.
2. El código existente mezcla español/inglés en nombres; **código nuevo** preferir inglés (`ClaimValidationCompleteness`, `missing` codes); mensajes UI en español.
3. `CanAskForValidation` hoy compara `tipo_documento` en minúsculas contra `"presupuesto"`/`"evidencia"`; el select guarda `Presupuesto`/`Evidencia` — mantener esa comparación.
4. El panel actual se oculta con `presupuesto_registrado`; el sticky “siempre visible” debe dejar de depender solo de ese flag para **ocultar** el botón (puede usarse como hint en checklist).
5. Revisar si `mano_obra_averia` (servicios) debería sumar al budget en una fase futura; hoy `CanAskForValidation` solo suma `refaccion_averia` — **no cambiar** esa fórmula en el MVP (respetar criterio de negocio en código).
6. API SIGA / Claims microservice: fuera de alcance salvo que más adelante se exponga el mismo flujo a landings.
7. Tras validar este plan: `ejecuta el plan` para Fase 0+.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y rama (P1)** | Rama desde develop + acuerdo de criterio requerido | T-01 a T-02 | 0.5 – 1 días | 56 |
| **Fase 1 — Fuente de verdad y backend (P1)** | Modelo completitud, BR unificado, AskForClaimReview, log, endpoint JSON | T-03 a T-07 | 1.5 – 2.5 días | 57 |
| **Fase 2 — UI sticky / checklist / ayudas (P1)** | Tooltips, sticky, JS en vivo, mensajes error | T-08 a T-11 | 1.5 – 2.5 días | 58 |
| **Fase 3 — Verificación (P1)** | Pruebas manuales taller + no-regresión + commit | T-12 a T-14 | 0.5 – 1 días | 59 |
| **Total proyecto (alcance único MVP)** | | 14 tareas | ~4 – 7 días hábiles (≈ 1 – 1.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 + Fase 3 (MVP completo; el PRD no define P2/P3) | T-01 a T-14 | ~4 – 7 días hábiles (≈ 1 – 1.5 semanas) | — |

> **Notas sobre la tabla:**
> - El PRD declara **alcance único (sin fases de producto)**; las fases del plan son solo de ejecución técnica. Todo el entregable es P1.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite explícita. Con un desarrollador a tiempo parcial en SIGA Web, el rango de **4–7 días hábiles** es realista. Si hubiera deadline &lt; 3 días hábiles, priorizar Fase 1 (alineación back) + sticky/checklist mínimo (T-09/T-10) y diferir pulido de ayudas (T-08) — no recomendado: las ayudas son RF-01 del MVP. Un segundo desarrollador en paralelo (UI vs BR) comprimiría ~30–40% el calendario de Fases 1–2.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
