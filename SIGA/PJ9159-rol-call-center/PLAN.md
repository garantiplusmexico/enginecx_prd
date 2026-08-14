# Plan de Desarrollo — Rol Call Center (PJ9159)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ9159-rol-call-center/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ9159-rol-call-center` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ9159` |
| Fecha de generación | 2026-08-14 |
| Estado | Validado |
| ID plan (BD) | 38 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Crear el rol Identity **`Call Center`**: **solo lectura** del módulo de averías (listado, detalle, documentos, historial, búsqueda). Sin crear/editar/estatus/aprobar/adjuntar/comentar/exportar. El Administrador General reasigna usuarios a mano (sin migración automática).

- **Arquitectura:** monolito SIGA Web (EC2 + .NET 8). Sin microservicio, sin API SIGA 3.0, sin cambio de esquema más allá de un `INSERT` en `"AspNetRoles"`.
- **Stack:** C# / Razor, `[Authorize(Roles=…)]` hardcodeado, menú Remake `profiles="…"`. PostgreSQL por hub.
- **Patrón de referencia:** el rol **`Auditor`** ya entra a Averías por `Details` (Edit GET lo redirige) y `GetAllAverias` **no** le aplica filtro `id_tecnico`. Call Center debe copiar esa vía de **lectura**, recortando catálogos, reportes y **exportación** (Auditor sí exporta; Call Center no).

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo / decisión de plan |
|---|---|
| ¿Nombre del rol? | **`Call Center`**. `NormalizedName = CALL CENTER`. Rol actual de esos usuarios: **`Tecnico`**. |
| ¿Exclusivo o reutilizable? | Catálogo Identity reutilizable; el alcance de menú/authorize es **solo Averías → Listado**. Otras áreas no se habilitan. |
| ¿México o también CO/CL? | El código es único. El seed SQL hay que aplicarlo en **cada BD de hub** (MX, CO, CL). Unidad del PRD = México primero; el mismo binario sirve a los tres. |
| ¿API SIGA 3.0? | **Fuera.** Call Center opera en SIGA Web. Claims API es para landings/WhatsApp. |
| ¿Reporte para Auditoría? | El catálogo de Usuarios ya lista el rol y el Excel de usuarios ya incluye roles. No se construye un reporte nuevo en el MVP (RNF-02 cubierto con lo existente). |
| ¿Visibilidad = la del Técnico (solo asignadas)? | **No.** El condensado PV-03 pide **ver todas las averías**. Un Call Center sin ficha `tecnico` vería lista vacía si se copiara el filtro de `Tecnico`. Decisión: visibilidad tipo **Auditor** = todas las averías del **proyecto/hub actual**, sin filtro `id_tecnico`. |

**Modelo de permisos (igual que PJ4981):** SIGA no tiene ACL data-driven. Hay que (a) sembrar el rol, (b) sumarlo a menú, (c) sumarlo a `[Authorize]` de **lectura**, (d) **no** sumarlo a POST de escritura ni a export, (e) ocultar botones en UI.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / Auditoría (criterio de cierre del hallazgo)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan)
- [ ] `CLAUDE.md` presente ✅
- [ ] Acceso a BD de dev/QA (al menos México; CO/CL para el seed)
- [ ] Un usuario de prueba al que el Admin General pueda asignar el rol (sin fila `tecnico`)
- [ ] Lista operativa de usuarios Call Center a migrar (fuera de código; la hace Admin General)
- [ ] No secrets nuevos

---

## 3. Arquitectura del cambio

```
[Admin General] → Catalogos/Usuarios (Create/Edit)
                    → AspNetUserRoles (Name = "Call Center")
                    → (sin usuario_tecnico, sin usuario_taller)

[Call Center] → Login → IsInRole("Call Center")
                    ├── Menú: Averías → Listado (solo)
                    ├── GET Index + Listado* + Details + descarga docs
                    ├── GetAllAverias(..., usuariotecnico: false)  // ve todas del proyecto
                    └── POST mutación / Export → 403 (no está en [Authorize])
```

**Decisiones de diseño:**

1. **Nombre técnico:** `Call Center` / `CALL CENTER`. GUID fijo en el SQL (como PJ4981), no `uuid_generate_v4()` suelto, para poder referenciarlo si una vista usa Id.
2. **No clonar Tecnico.** No requiere registro en `tecnico`. No entra a `Edit` editable.
3. **Lectura = Auditor en Averías; menos superficie.** Sin Catálogos, Contratos, Reportes, Técnicos, Talleres, Refacciones.
4. **Exportación:** no añadir el rol a `ExportaAveriasActivas` / `ExportaAveriasCerradas` y ocultar `export-button` en los `_Listado*`.
5. **Assign / Create / AddFiles / Edit POST:** no incluir el rol. `Edit` GET: incluirlo en el mismo `if` que Auditor (`RedirectToAction("Details")`).
6. **Details estatus 12/13** hoy redirige a `Aprobacion`. Para Call Center **no redirigir** (esa pantalla es de operación). Quedarse en Details.
7. **Gestor de Países** tiene whitelist de roles (L146-153) **sin** Call Center. Dejarlo así: RF-09 reserva la asignación al Administrador General (rama `else` de `SetupViewBags` ya lista todos menos `Taller`).
8. **No migrar usuarios en código.** Script SQL solo del rol; Admin cambia el combo en Usuarios.
9. **No modificar el rol Tecnico** (fuera de alcance). Independiente de PJ9626.
10. **API / Mobile:** fuera.

---

## 4. Tareas de desarrollo

### Fase 0 — Rol en BD y rama

- [ ] **T-01** — Crear rama `feature/PJ9159-rol-call-center` desde `develop` y fijar GUID del rol
  - Criterio de completitud: rama en origin; GUID anotado en el script de T-02

- [ ] **T-02** — Script SQL idempotente de alta del rol
  - Archivos a crear: `GarantiplusWeb/BD/2026-08-14_rol_call_center/rol_call_center.sql`
  - Patrón: `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/` (INSERT con Id fijo + `WHERE NOT EXISTS` / `ON CONFLICT DO NOTHING`)
  - Columnas: `"Id"`, `"Name" = 'Call Center'`, `"NormalizedName" = 'CALL CENTER'`
  - Criterio de completitud: el rol aparece en `"AspNetRoles"` al ejecutarlo en MX (y queda listo para CO/CL); reejecutar no duplica

### Fase 1 — Menú (P1)

- [ ] **T-03** — Exponer Averías → Listado al rol en los tres hubs
  - Archivos: `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_MEX.cshtml`, `_LeftMenuBar_COL.cshtml`, `_LeftMenuBar_CHL.cshtml`
  - Cambio: añadir `Call Center` al `profiles` del **padre Averías**. El subítem Listado no tiene `profiles` (lo hereda). **No** añadirlo a Registrar avería, Técnicos, Talleres, Refacciones, Reportes, Contratos ni Catálogos.
  - Criterio de completitud: Call Center solo ve Dashboard + Averías/Listado. Otros roles intactos.

### Fase 2 — Lectura en backend (P1)

- [ ] **T-04** — Autorizar listado y detalle
  - Archivos: `AveriasController.cs`
  - Incluir `"Call Center"` en: authorize de **clase**; `Index` (vía clase); `Listado48hrs`, `ListadoTaller`, `ListadoRegistradas` (si tiene), `ListadoCerradas`; `Details`; `DownloadAllDocuments` y cualquier GET de descarga de adjunto de avería (no facturación/pago).
  - `GetAllAverias`: **no** pasar `usuariotecnico: true` para este rol (`IsInRole("Tecnico")` sigue siendo el flag). Call Center ve el universo del proyecto como Auditor.
  - Datagrid: puede seguir `to=Edit`; T-06 redirige a Details.
  - Criterio de completitud: Call Center carga Index, las pestañas, busca/filtra (DataTables) y abre una avería ajena a cualquier técnico.

- [ ] **T-05** — Details: historial, documentos y no caer en Aprobacion
  - Archivos: `AveriasController.Details`, `Details.cshtml` si hace falta ocultar acciones
  - Cambio: Call Center cae en el `else` de visibilidad (como Auditor). Si `id_estatus` es 12/13, **no** `RedirectToAction("Aprobacion")` cuando el rol es Call Center.
  - Criterio de completitud: ve seguimiento/bitácora y documentos; descarga funciona; no entra a la pantalla de aprobación/rechazo.

### Fase 3 — Bloqueo de escritura y exportación (P1)

- [ ] **T-06** — Edit GET → Details; POST de mutación sin el rol
  - Archivos: `AveriasController.cs`, `_Edit.cshtml` / `Edit.cshtml` / `Index.cshtml` solo si hay botones visibles por clase (p. ej. `reporteTiempos` ya excluye a quien no está en la lista)
  - `Edit` GET: añadir Call Center al `if` que redirige a Details (junto a Auditor).
  - **No** añadir Call Center a: `Edit` POST, `AddFiles`, `Assign`, `Create`, `Resolucion`, `AprobarRechazarAveria`, `Validacion`, `InWorkshop`, `CarFixed`, `AprovedBudget`, `UpdateWorkshop*`, `TallerExterno`, etc.
  - Criterio de completitud: POST a Edit/AddFiles/Assign con usuario Call Center → 403. GET Edit → Details.

- [ ] **T-07** — Sin exportación (RF-08)
  - Archivos: `_ListadoAbiertas.cshtml`, `_ListadoCerradas.cshtml` (y Mitsu si aplica); **no** tocar el `[Authorize]` de `ExportaAverias*` salvo para **confirmar que Call Center no está**
  - Ocultar `export-button` / formularios de export cuando `User.IsInRole("Call Center")`.
  - Criterio de completitud: no hay botón Descargar; POST directo a Exporta* → 403.

- [ ] **T-08** — UI de solo lectura coherente (RNF-05)
  - Archivos: `Index.cshtml` (ocultar bloques de reportes Excel de tiempos si el rol los viera), `Details.cshtml` (sin botones de gestión; Auditor ya ve Details relativamente limpio — revisar y quitar lo que quede clicable)
  - Criterio de completitud: ningún control de escritura visible para Call Center.

### Fase 4 — Asignación y validación (P1)

- [ ] **T-09** — Verificar alta/edición de usuarios
  - Archivos: `UsuariosController.cs` (solo si el rol no aparece; la rama Admin General ya lista todos menos Taller)
  - Criterio de completitud: Admin General ve "Call Center" en el combo, guarda, y el usuario queda con ese único rol. Gestor de Países **no** lo ve en su whitelist (aceptable y alineado a RF-09).

- [ ] **T-10** — Prueba funcional Call Center (RF-01 a RF-09)
  - Criterio de completitud: ve todas las averías del proyecto; detalle + docs + historial + filtros; no crea/edita/exporta; Admin asigna el rol.

- [ ] **T-11** — No-regresión Tecnico, Coordinador, Auditor
  - Criterio de completitud: Tecnico sigue editando las suyas; Coordinador reasigna; Auditor sigue como hoy (incluido export).

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `"AspNetRoles"` | Alta (seed SQL, no migración EF) | Fila `Call Center` / `CALL CENTER`, Id GUID fijo, idempotente |
| `"AspNetUserRoles"` | Manual (operación) | Admin General reasigna usuarios; no hay script de migración masiva |

El script se ejecuta **por hub** (cada PostgreSQL). No hay columnas nuevas.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

No hay rutas nuevas.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Averias/Averias` | Index autorizado para Call Center | Modificado (authorize) |
| POST | `/Averias/Averias/Listado*` | Listados autorizados; sin filtro técnico | Modificado |
| GET | `/Averias/Averias/Details/{id}` | Lectura completa; sin redirect a Aprobacion | Modificado |
| GET | `/Averias/Averias/Edit/{id}` | Redirect a Details | Modificado |
| GET | descarga documentos | Permitida | Modificado |
| POST | Edit / AddFiles / Assign / Exporta* | Call Center **fuera** del authorize | Sin cambio de lista (explícito) |

---

## 7. Variables de entorno y configuración *(si aplica)*

No aplica.

---

## 8. Consideraciones de seguridad

- **RNF-01:** no basta ocultar botones. El rol no debe estar en `[Authorize]` de POST de escritura ni de export.
- **Mínimo privilegio:** no copiar el authorize de Tecnico (escribiría) ni el de Auditor entero (exporta y ve catálogos/reportes).
- **Asignación:** solo Admin General (whitelist de Gestor sin Call Center).
- **Trazabilidad:** `AspNetUserRoles` + listado/export de Usuarios. Identity no versiona el historial de cambios de rol; si Auditoría exige log de *quién cambió el rol y cuándo*, queda como fase futura (no hay tabla de auditoría de roles hoy).
- Mensajes 403 en español.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin AWS nuevo. Seed SQL en cada RDS/PostgreSQL de hub.
- Despliegue: binario GarantiplusWeb + ejecutar SQL en MX (y CO/CL cuando corresponda).
- Orden: SQL del rol **antes** de asignar usuarios; el código puede ir antes o después (si el código llega sin SQL, el combo no muestra el rol).

---

## 10. Criterios de aceptación

- [ ] **RF-01:** Existe el rol `Call Center` en `"AspNetRoles"` (al menos MX).
- [ ] **RF-02 / RF-06:** El usuario ve el listado de **todas** las averías del proyecto, con búsqueda/filtros DataTables.
- [ ] **RF-03 / RF-05:** Abre detalle con seguimiento/bitácora.
- [ ] **RF-04:** Ve y descarga adjuntos de la avería.
- [ ] **RF-07:** No puede crear, editar, cambiar estatus, aprobar/rechazar, adjuntar ni comentar (UI + 403 en POST).
- [ ] **RF-08:** No puede exportar (sin botón + 403).
- [ ] **RF-09:** Admin General asigna/cambia el rol en Usuarios; no hay job de migración.
- [ ] **RNF-03:** No ve Contratos/Catálogos/Reportes/Técnicos/Talleres.
- [ ] **RNF-05:** Interfaz de consulta sin botones de gestión.
- [ ] El rol **Tecnico** no se altera.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Olvidar un `[Authorize]` de POST | Alta | Alto | T-06: grep de `Authorize`/`HttpPost` en Averias; lista blanca de lectura |
| Copiar visibilidad de Tecnico (lista vacía) | Media | Alto | T-04: no usar `usuariotecnico` para Call Center |
| Redirect a Aprobacion (estatus 12/13) | Media | Medio | T-05 |
| Auditor/export confundidos con Call Center | Media | Medio | T-07: no heredar authorize de Auditor en Exporta* |
| Seed solo en MX | Media | Medio | T-02 documenta ejecutar en cada hub |
| Usuarios Call Center siguen como Tecnico | Alta (operación) | Alto | Fuera de código; checklist para Admin General |
| Solape con PJ9626 (toggle Todas del Técnico) | Baja | Bajo | Roles distintos; no acoplar ramas |

---

## 12. Notas para el programador

1. **No** añadir `Call Center` con un replace-all de `Tecnico` ni de `Auditor`.
2. `_LeftMenuBar_*` Listado de Averías no tiene `profiles`: basta el padre. Si se añade `profiles` al Listado, incluir Call Center ahí y no romper a los demás.
3. Datagrid enlaza a `Edit`; el redirect de T-06 es el camino (igual que Auditor).
4. Prueba local: crear el rol en BD, asignar a un usuario **sin** registro `tecnico`, entrar a Averías.
5. Independiente de PJ4197 y PJ9626.
6. Mensajes de usuario en español; código/logs en inglés.

---

## 13. Relación de tareas y tiempos

El PRD no define P2/P3. **Todo el alcance es P1.**

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rol en BD** | Rama + SQL `AspNetRoles` | T-01 a T-02 | 0.25 – 0.5 días | 98 |
| **Fase 1 — Menú (P1)** | `_LeftMenuBar` MX/CO/CL | T-03 | 0.25 – 0.5 días | 100 |
| **Fase 2 — Lectura (P1)** | Authorize listado/detalle/docs | T-04 a T-05 | 1 – 2 días | 99 |
| **Fase 3 — Escritura/export (P1)** | Redirect Edit, 403 POST, ocultar export | T-06 a T-08 | 1.5 – 2.5 días | 101 |
| **Fase 4 — Asignación y QA (P1)** | Combo usuarios + pruebas | T-09 a T-11 | 1 – 1.5 días | 102 |
| **Total proyecto (P1)** | | 11 tareas | ~4 – 7 días hábiles (≈ 1 – 1.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 4 | T-01 a T-11 | ~4 – 7 días hábiles (≈ 1 – 1.5 semanas) | — |

> **Notas sobre la tabla:**
> - Fase 3 no es opcional (RNF-01 / hallazgo de Auditoría).
> - La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre 4–7 días hábiles. El cuello de botella posterior es **operación** (reasignar usuarios Técnico → Call Center), no el código.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
