# Plan de Desarrollo — Periodos de Gracia y Anulación de Contratos Colombia (PJ1910)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ1910-periodos-gracia-anulacion-colombia/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + AveriasBusinessRules + DataAccess/DataAccessColombia) |
| Rama base | `develop` |
| Rama | `feature/PJ1910-periodos-gracia-anulacion-colombia` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ1910` |
| Fecha de generación | 2026-07-23 |
| Estado | Borrador |
| ID plan (BD) | 21 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Habilitar en SIGA Web (Colombia) dos acciones de Operaciones en el **detalle de contrato**, exclusivas del rol **Administrador General**:

1. **Anulación definitiva** — reutilizar el patrón operativo de México (`Cancelacion` → `estatus = Cancelado` + `fecha_cancelacion`), endurecido con motivo obligatorio, traza y reglas de visibilidad (sin factura activa agregada y sin orden de pago activa).
2. **Periodo de gracia a nivel contrato** — capacidad **nueva** en Operaciones (no confundir con `averia_periodo_gracia`, que es extensión post-vigencia al registrar averías). Debe permitir cobertura pese a mora y ser reconocible por Averías.

- **Arquitectura:** modificación sobre monolito SIGA Web (EC2 + .NET 8 + Razor/MVC Areas) y librería `AveriasBusinessRules`. Sin microservicio nuevo ni API REST nueva.
- **Stack:** .NET 8 / C#, Razor Views + jQuery/modales, PostgreSQL (script DDL Colombia + espejo EF en ambos DataAccess).
- **Fuera del MVP:** integración con Facturación (Fase 2 del PRD).

**Hallazgos técnicos que cierran supuestos del PRD:**

| Expectativa PRD | Realidad en código (`develop`) | Decisión del plan |
|---|---|---|
| Botón Cancelación en detalle (México) | El botón está en **Edit**, no en Details; Details solo tiene “Modificar” | En COL el botón de Anulación va en **Details** (como pide Operaciones); no se mueve el de México |
| Reutilizar `fx_anulacion` | **No existe** como función/columna PG; es residual MySQL/PHP. Reportes vivos usan `fecha_cancelacion` / `estatus` | Mapear “`fx_anulacion`” → `fecha_cancelacion` + `estatus = Cancelado` + `causa_cancelacion`. No crear función SQL salvo que BI lo exija explícitamente |
| Solo Administrador General | `Cancelacion` hoy permite Admin General, Admin Externo y Gestor de Países | Endpoints COL: **solo** `Administrador General` (UI + `[Authorize]`) |
| Sin factura activa ni ODP activa | Edit solo checa factura Timbrada/Pagada, no Activo, pagos sellados y flag `Endosos:CancelacionContrato`. **No** checa ODP | Nueva regla COL: sin factura activa agregada **y** sin ODP activa; backend valida ambas |
| Anulación definitiva | Existe `Reactivar` en Details | En COL, ocultar/bloquear Reactivar para contratos anulados por este flujo (o todos Cancelado en COL — confirmar en T-02) |
| Gracia = `averia_periodo_gracia` | Esa tabla es 1:1 con avería y significa “días después de `fecha_final`” | Crear entidad **`contrato_periodo_gracia`** y que Averías la consulte para mora/cobertura |
| Motivo obligatorio | `Cancelacion` no setea `causa_cancelacion` | Nuevo endpoint/flujo COL exige motivo → `causa_cancelacion` + bitácora |

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (Operaciones Colombia)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local con `HubBaseCountryCode` / `CountryBase` = **COLOMBIA** y BD Colombia accesible
- [ ] Rol `Administrador General` disponible en el ambiente COL de prueba
- [ ] Contratos de prueba: (a) sin factura ni ODP, (b) con factura activa, (c) en ODP activa, (d) vigente con mora / vencido
- [ ] No se requieren secrets nuevos; posibles flags en `appsettings` (ver §7)

---

## 3. Arquitectura del cambio

Se respeta el monolito SIGA Web (`rules/arquitectura.md`): feature de UI + reglas de negocio sobre componentes existentes. Despliegue sigue en EC2 Colombia.

```
[Administrador General COL]
  → Details.cshtml (botones Anular / Periodo de gracia)
      → POST ContratosController (acciones COL, Authorize = Administrador General)
          → Validaciones: rol, factura activa, ODP activa, motivo, días
          → PostgreSQL:
                contrato (estatus, fecha_cancelacion, causa_cancelacion, bitacora)
                contrato_periodo_gracia (nueva)
          → AveriasBusinessRules / ClaimValidator
                reconoce gracia-contrato para cobertura pese a mora
  → Reportes existentes (fecha_cancelacion / estatus Cancelado)
```

**Decisiones de diseño:**

1. **Anulación COL ≠ mover México.** Nuevo flujo/acción (o sobrecarga condicionada por `codigo_pais == "COL"`) con reglas del PRD. El botón Edit de México permanece.
2. **`fx_anulacion` del PRD = campos vivos** `fecha_cancelacion`, `estatus`, `causa_cancelacion`. Reportes que ya filtran por cancelación siguen funcionando sin migración de reportería.
3. **Gracia de Operaciones ≠ gracia de Averías.** Nueva tabla `contrato_periodo_gracia`. Al aplicar gracia: registrar días, fechas inicio/fin, motivo, usuario, fecha. Averías consulta si hay gracia **vigente** para relajar el bloqueo por mora / contrato no Activo / sin pago (equivalente funcional a “cobertura pese a mora”), sin reutilizar `averia_periodo_gracia`.
4. **Validación de rol siempre en servidor** (`[Authorize(Roles = "Administrador General")]`), no solo ocultar botones.
5. **Transaccionalidad:** anulación y gracia en una sola unidad de trabajo (Update contrato + insert traza/gracia). Si falla Averías no aplica (la gracia se persiste; Averías solo lee).
6. **Facturación:** no tocar gRPC ni jobs de facturación en este MVP.
7. **No acoplar** al exe batch `CancelacionContratos/` (cancelación automática por vigencia).

**Alcance país:** UI y endpoints condicionados a Colombia (`HubBaseCountryCode` / `ViewBag.CodigoPais == "COL"`). Modelo EF se replica en `DataAccess` y `DataAccessColombia` por convención del monorepo; la UI/acción solo se expone en COL.

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación, rama y diseño de datos (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b feature/PJ1910-periodos-gracia-anulacion-colombia`
  - Criterio de completitud: rama local basada en `develop` actualizado

- [ ] **T-02** — Baseline COL: Cancelacion, Reactivar, factura activa, ODP
  - Verificar en código/ambiente: cómo se determina “factura activa agregada” en Details/Edit; estatus de ODP que cuentan como “activa” (`Registrada` / no `Cancelada`/`Pagada`/`Errores`)
  - Decidir con Operaciones (si hace falta): ¿Reactivar se oculta para todo Cancelado en COL o solo si hay `causa_cancelacion`?
  - Documentar hallazgo en `AVANCE.md`
  - Criterio de completitud: reglas de bloqueo y semántica de Reactivar cerradas por escrito

- [ ] **T-03** — Diseñar DDL y contrato de `contrato_periodo_gracia`
  - Campos mínimos: `id` (PK), `id_contrato` (FK), `dias_gracia`, `fecha_inicio`, `fecha_fin`, `motivo`, `usuario_registro`, `fecha_registro`; opcional `activo` / `vigente`
  - Definir si se permiten múltiples gracias históricas (sí, historial) y cuál es la “vigente” (fecha_fin >= hoy)
  - Criterio de completitud: script SQL + modelo EF acordados antes de codificar UI

### Fase 1 — Anulación Colombia (P1)

- [ ] **T-04** — Endpoint backend de anulación COL con motivo y validaciones
  - Archivos candidatos:
    - `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs` (nuevo action p.ej. `AnularContrato` o extensión condicionada de `Cancelacion`)
  - Comportamiento:
    - `[Authorize(Roles = "Administrador General")]`
    - Solo si país base COL (guard server-side)
    - Rechazar si ya Cancelado; si hay factura activa agregada; si hay ODP activa
    - Motivo obligatorio → `causa_cancelacion`
    - `fecha_cancelacion = Now`, `estatus = Cancelado`
    - Bitácora: usuario, fecha/hora, motivo
    - Cancelar productos adicionales asociados (igual que `Cancelacion` actual)
    - Respuesta JSON clara para UI (éxito / causa de bloqueo)
  - Criterio de completitud: POST bloquea sin rol/sin motivo/con factura/con ODP; anula y deja traza cuando procede

- [ ] **T-05** — UI Details: botón Anular + modal motivo (solo COL + Admin General)
  - Archivos:
    - `GarantiplusWeb/Areas/Contratos/Views/Contratos/Details.cshtml`
    - JS inline o partial modal (seguir patrón visual de botones danger existentes)
  - Visibilidad: `CodigoPais == "COL"` + `User.IsInRole("Administrador General")` + no Cancelado + flags de factura/ODP calculados en el GET Details
  - Criterio de completitud: botón visible solo en casos permitidos; modal exige motivo; mensaje si backend bloquea

- [ ] **T-06** — Ocultar/bloquear Reactivar en COL para anulación definitiva
  - Archivos: `Details.cshtml` + action `Reactivar` (guard COL → 403 / mensaje)
  - Criterio de completitud: un contrato anulado en COL no se puede reactivar desde UI ni endpoint

- [ ] **T-07** — Exponer indicadores de bloqueo en GET Details
  - Calcular y pasar a ViewBag: `PuedeAnular`, `MotivoBloqueoAnulacion` (factura activa / ODP activa)
  - Criterio de completitud: UI no adivina; backend y vista usan la misma regla

### Fase 2 — Periodo de gracia en Operaciones (P1)

- [ ] **T-08** — Persistencia: modelo EF + DbSet + script DDL
  - Archivos:
    - `DataAccessColombia/Models/.../contrato_periodo_gracia.cs` (y espejo en `DataAccess`)
    - Mapeo en `garantiplus_dbContext` (ambos)
    - Script en `GarantiplusWeb/BD/` (o carpeta de scripts del proyecto) para COL
  - Criterio de completitud: entidad consultable vía `_repo`; script aplicable en BD Colombia

- [ ] **T-09** — Endpoint backend aplicar gracia
  - Action en `ContratosController` (p.ej. `AplicarPeriodoGracia`)
  - `[Authorize(Roles = "Administrador General")]`, solo COL
  - Input: `id_contrato`, `dias` (> 0, sin tope de negocio), `motivo` (obligatorio)
  - Aplicable a vigentes y vencidos/caducos; **no** a Cancelado
  - Persistir fila + bitácora en contrato
  - Criterio de completitud: gracia guardada con usuario/fecha/días/motivo; rechaza sin rol/sin motivo/días inválidos/cancelado

- [ ] **T-10** — UI Details: acción Periodo de gracia + modal días/motivo
  - Misma vista Details; solo COL + Admin General
  - Criterio de completitud: flujo usable; muestra confirmación y deja evidencia en bitácora/UI

- [ ] **T-11** — Averías reconoce gracia-contrato (cobertura pese a mora)
  - Archivos:
    - `AveriasBusinessRules/.../ClaimValidator.cs` (y/o punto donde se bloquea por no pagado / no Activo)
    - Posible ajuste en `AveriasBusinessRules.cs` si el alta de avería también valida estatus
  - Regla: si existe `contrato_periodo_gracia` vigente para el contrato, permitir el camino de cobertura pese a mora (equivalente funcional al espíritu del PRD), **sin** reutilizar `averia_periodo_gracia` salvo que al registrar la avería se quiera marcar badge (opcional; documentar decisión)
  - Criterio de completitud: con gracia vigente se puede registrar avería que antes fallaba por mora/no Activo; sin gracia el comportamiento previo se conserva
  - Nota: `con_cobertura == 0` sigue siendo bloqueo de producto; la gracia no lo sobreescribe salvo decisión explícita en T-02

### Fase 3 — Trazas, eventos, pruebas y cierre (P1)

- [ ] **T-12** — Traza consultable y eventos BI (mínimo viable)
  - Bitácora de contrato + filas de gracia; si el proyecto ya tiene patrón de eventos/log de negocio, emitir `contrato_anulado`, `contrato_periodo_gracia_aplicado`, `anulacion_bloqueada` (PRD §11); si no hay bus de eventos, documentar bitácora + logs Serilog como fuente y dejar hook listo
  - Criterio de completitud: auditoría reconstruible (usuario, fecha, motivo, días)

- [ ] **T-13** — Pruebas funcionales COL (matriz)
  - Anular OK (sin factura/ODP) con motivo
  - Anular bloqueada (factura / ODP) + mensaje
  - Rol no Admin → sin botón / 403
  - Gracia en vigente y en vencido; Averías reconoce cobertura
  - Smoke: México no muestra botones nuevos; Cancelacion Edit MX intacta
  - Criterio de completitud: RF-01..RF-11 verificados; RNF de permisos/traza OK

- [ ] **T-14** — Commit y push de la feature
  - Mensaje estilo Engine: `[PJ1910-periodos-gracia-anulacion-colombia] Habilitar anulación y periodo de gracia en Contratos COL`
  - Criterio de completitud: cambios en rama remota; programador gestiona PR → `pre-qa`

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `contrato_periodo_gracia` | **Nueva** | Historial de gracias aplicadas desde Operaciones (días, fechas, motivo, usuario, fecha) |
| `contrato` | Uso existente | `estatus`, `fecha_cancelacion`, `causa_cancelacion`, `bitacora` — sin migración de columnas |
| `averia_periodo_gracia` | Sin cambio de esquema | No reutilizar para este feature; sigue siendo gracia post-vigencia al registrar avería |
| `orden_pago` / facturas | Solo lectura | Criterios de bloqueo de anulación |

Script DDL a aplicar en **BD Colombia** (y documentar espejo si QA MX comparte esquema). Sin drop de columnas.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta (MVC Area) | Descripción | Estado |
|---|---|---|---|
| POST | `/Contratos/Contratos/AnularContrato/{id}` (nombre final en implementación) | Anulación COL con motivo + validaciones | **Nuevo** (o extensión condicionada de `Cancelacion`) |
| POST | `/Contratos/Contratos/AplicarPeriodoGracia/{id}` | Aplica gracia (días + motivo) | **Nuevo** |
| GET | `/Contratos/Contratos/Details/{id}` | Flags `PuedeAnular` / bloqueos / evidencia de gracia | **Modificado** |
| POST | `/Contratos/Contratos/Reactivar/{id}` | Bloqueo en COL para anulación definitiva | **Modificado** |
| POST | `/Contratos/Contratos/Cancelacion/{id}` | Patrón México — **no romper** | Sin cambio funcional MX |

No hay endpoints REST nuevos en `gp_3.0_siga_api` para el MVP (Operaciones usa SIGA Web).

---

## 7. Variables de entorno y configuración

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `Hub:HubBaseCountryCode` | Debe ser `COL` en el ambiente de prueba Colombia | Dev / QA COL |
| `Endosos:CancelacionContrato` | Flag histórico del botón Edit MX; no sustituye las reglas COL | Existente |
| *(opcional)* `Contratos:AnulacionColombiaHabilitada` | Feature flag de despliegue gradual | Dev / QA / Prod COL |
| *(opcional)* `Contratos:GraciaOperacionesHabilitada` | Feature flag gracia | Dev / QA / Prod COL |

No hay secrets nuevos. Días de gracia: **sin tope** (validar solo `> 0` y tipo entero).

---

## 8. Consideraciones de seguridad

- Autorización **server-side** solo `Administrador General` en ambas acciones (RNF-01 / RF-11).
- No confiar en ocultar botones: validar rol, país, factura, ODP y estado en cada POST.
- Motivo obligatorio: sanitizar longitud y caracteres; no loguear PII innecesaria más allá de usuario Identity.
- Anulación definitiva: bloquear `Reactivar` en COL para evitar bypass.
- Secrets: ninguno nuevo; no hardcodear cadenas de conexión.

---

## 9. Consideraciones de infraestructura

- Sin recursos AWS nuevos. Despliegue SIGA Web Colombia en EC2 existente.
- Aplicar script DDL en RDS/PostgreSQL Colombia antes o junto al deploy.
- Costo incremental: nulo (solo columnas/tabla pequeña + UI).
- Facturación (ECS/gRPC) **no** se toca en este MVP — riesgo aceptado del PRD.

---

## 10. Criterios de aceptación

- [ ] RF-01: Botón anulación visible solo a Administrador General (COL, detalle)
- [ ] RF-02: Botón habilitado solo sin factura activa agregada y sin ODP activa
- [ ] RF-03: Anulación definitiva con motivo → `causa_cancelacion` + Cancelado + `fecha_cancelacion`
- [ ] RF-04: Traza de anulación (usuario, fecha/hora, motivo)
- [ ] RF-05: Reportes que usan cancelación (`fecha_cancelacion` / estatus) reflejan la anulación
- [ ] RF-06..RF-08: Acción de gracia con días (sin tope) y motivo; vigentes y vencidos
- [ ] RF-09: Averías reconoce cobertura pese a mora con gracia vigente
- [ ] RF-10: Traza de gracia (usuario, fecha, días, motivo)
- [ ] RF-11 / RNF-01: Backend rechaza sin rol aunque se invoque el POST
- [ ] RNF-03: Estado consistente contrato ↔ reportes ↔ Averías
- [ ] RNF-05: UX alineada a patrones existentes de SIGA (modales/botones)
- [ ] México/Chile: sin botones nuevos ni regresión del Cancelacion Edit MX
- [ ] Facturación: sin cambios (fuera de alcance MVP)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Confundir gracia-contrato con `averia_periodo_gracia` (semántica distinta) | Alta | Alto | Tabla nueva + tests Averías; documentar en §1 |
| Gracia sin tope sobre vencidos dispara averías / pérdidas | Media | Alto | Solo Admin General + traza; dejar alertas/tope como follow-up (pregunta abierta PRD) |
| Definición ambigua de “factura activa agregada” / “ODP activa” | Media | Alto | Cerrar en T-02 con Operaciones + código real de estatus |
| Anulación definitiva vs `Reactivar` existente | Alta | Medio | T-06: bloquear Reactivar en COL |
| Expectativa BI sobre literal `fx_anulacion` | Baja | Medio | Explicar mapeo a `fecha_cancelacion`; coordinar con BI si un reporte legacy aún filtra columna inexistente |
| Inconsistencia cobros (Facturación fuera de MVP) | Alta | Medio | Aceptado por PRD; registrar en AVANCE; Fase 2 |
| Espejo EF MX/CO olvidado | Media | Medio | T-08 obliga ambos DataAccess |

---

## 12. Notas para el programador

1. **No refactorizar** `Cancelacion` México ni el batch `CancelacionContratos/` salvo lo mínimo para no duplicar lógica (extraer helper privado compartido está OK si reduce riesgo).
2. **País:** condicionar UI y guards a `COL`. No habilitar en MEX/CHL en este folio.
3. **Código nuevo en inglés** (nombres de clases/métodos); mensajes UI/errores al usuario en **español** (convención SIGA / coding-guidelines Engine).
4. **Preguntas abiertas del PRD** que afectan implementación: tope de días (MVP = sin tope); efecto exacto sobre `con_cobertura`; proceso de reversa (MVP = no). Cerrar en T-02 lo que bloquee código.
5. El programador gestiona el PR (`feature/*` → `pre-qa` → `qa`); Claude Code no crea PRs.
6. Tras autorizar este plan: registrar en BD PM (`db-sync`) y luego “ejecuta el plan”.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y diseño (P1)** | Branch, baseline factura/ODP/Reactivar, DDL gracia | T-01 a T-03 | 0.5 – 1 días | 27 |
| **Fase 1 — Anulación COL (P1)** | Endpoint + UI Details + bloqueo Reactivar + flags | T-04 a T-07 | 1.5 – 2.5 días | 28 |
| **Fase 2 — Gracia Operaciones + Averías (P1)** | Tabla/EF, endpoint, UI, reconocimiento en ClaimValidator | T-08 a T-11 | 2 – 3.5 días | 29 |
| **Fase 3 — Traza, pruebas y cierre (P1)** | Eventos/bitácora, matriz pruebas COL+smoke MX, commit | T-12 a T-14 | 1 – 1.5 días | 30 |
| **Total proyecto (P1 = MVP PRD)** | | 14 tareas | **~5 – 8.5 días hábiles (≈ 1 – 2 semanas)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 + Fase 3 | T-01 a T-14 | **~5 – 8.5 días hábiles** | — |

> **Notas sobre la tabla:**
> - El MVP del PRD es Fase 1 de producto (gracia + anulación). En este plan eso cubre Fases 0–3 de ejecución; la Fase 2 de producto (Facturación) **no** está incluida.
> - No hay P2/P3 de código en este folio; Facturación sería un plan/PRD aparte.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** el PRD no fija fecha límite explícita. Con ~5–8.5 días hábiles el MVP cabe en un sprint de 2 semanas con un desarrollador. Si hubiera deadline &lt; 5 días hábiles, priorizar **Fase 0 + Fase 1 (anulación)** primero y diferir gracia/Averías, o sumar un segundo desarrollador (anulación ∥ gracia) con ~30–40 % de compresión del calendario.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
