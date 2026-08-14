# Plan de Desarrollo — Visualización de averías para técnicos (PJ9626)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ9626-visualizacion-averias-tecnicos/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb + AveriasBusinessRules + ArmadorasBusinessRules) |
| Rama base | `develop` |
| Rama | `feature/PJ9626-visualizacion-averias-tecnicos` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ9626` |
| Fecha de generación | 2026-08-14 |
| Estado | Validado |
| ID plan (BD) | 37 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Permitir que el rol **`Tecnico`** consulte **todas las averías del hub/proyecto actual** en modo **solo lectura**, conservando la edición únicamente sobre las asignadas a él. El coordinador técnico **no se modifica**.

- **Arquitectura:** cambio sobre el monolito SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). Sin microservicio nuevo, sin API SIGA 3.0, sin migración de BD.
- **Stack:** .NET 8 / C#, Razor + TagHelper `datagrid` (DataTables server-side), PostgreSQL intacto.
- **Despliegue:** mismo binario de GarantiplusWeb en México, Colombia y Chile. El filtro vive en código compartido, no en config por país.

**Hallazgo técnico (cierra preguntas abiertas del PRD §13):**

| Pregunta PRD | Hallazgo en código (`develop`) |
|---|---|
| ¿"Todas" es cross-país? | **No.** Cada hub tiene su BD. El listado ya filtra por `GetCurrentProject()`. "Todas" = todas las averías del **proyecto/hub actual**, de cualquier técnico y de cualquier pestaña de estatus. Igual que ve hoy el Coordinador Técnico. |
| ¿Filtros extra (técnico, folio, estatus)? | Reutilizar el `datagrid` actual (búsqueda por columna + paginación). Añadir columna **Técnico** en la vista "Todas". No construir un módulo de filtros nuevo. |
| ¿Qué se muestra en el detalle de solo lectura? | Reutilizar `Details.cshtml` (ya muestra estatus, seguimiento, documentos, badge de técnico). El técnico hoy entra por `Edit`; si la avería no es suya se redirige a `Details`. |
| ¿Auditoría de consultas? | Fuera de alcance (PRD §6). No se implementa. |
| ¿El coordinador ya ve todas y reasigna? | **Sí.** `GetAllAverias` solo aplica `id_tecnico == …` cuando `usuariotecnico=true` (`User.IsInRole("Tecnico")`). El coordinador no pasa ese flag. La UI de reasignar está en `_Edit.cshtml` (roles Coordinador/Admin). |
| ¿Dónde se filtra hoy al técnico? | `GetAllAverias` en **dos copias**: `AveriasBusinessRules` y `ArmadorasGeneralBusinessRules`. Los listados POST instancian `ArmadorasGeneralBusinessRules` para activas/48h/taller; cerradas y exports usan `_br` (`IAveriasBusinessRules`). Hay que pasar el flag en **ambos** caminos. |
| ¿El técnico puede abrir una ajena por URL? | **No.** `Details` (L446-459) y `Edit` GET (L1658-1665) hacen 404 si `id_tecnico` no coincide. Levantar el listado **sin** abrir el detalle dejaría enlaces rotos. |
| ¿La escritura ya está bloqueada en backend? | **Parcial / insuficiente.** `Edit` GET sí filtra por asignado; `Edit` POST **no** comprueba `id_tecnico` (solo proyecto). `AddFiles` y `Assign` tampoco. Al ampliar visibilidad, **hay que añadir la guarda de escritura** (RF-05 / RNF-01). |

**Implicación:** el MVP no es solo un toggle de UI. Son tres piezas: (1) no filtrar el listado cuando el técnico pide "Todas", (2) permitir GET del detalle ajeno, (3) impedir POST de mutación si no es el asignado.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Usuario de prueba **Tecnico** (con `tecnico` ligado a `aspnetusers`) y al menos una avería asignada + averías de otros técnicos / de baja
- [ ] Usuario **Coordinador Tecnicos** para no-regresión de visibilidad y reasignación
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta el monolito SIGA Web (`rules/arquitectura.md`). Se reutiliza el listado existente (RNF-06).

```
[Técnico] → Averias/Index
              ├─ default: toggle "Mis averías"
              │     GetAllAverias(..., usuariotecnico: true)
              │     → solo id_tecnico del usuario
              └─ toggle "Todas"
                    GetAllAverias(..., usuariotecnico: false)
                    → mismo query que Coordinador (proyecto actual, tabs de estatus)
                    + columna Técnico

[Clic en fila]
  → GET Edit/{id}
        ├─ asignada al técnico → Edit (igual que hoy)
        └─ ajena               → Redirect Details (solo lectura)

[POST mutación: Edit, AddFiles, seguimiento, estatus, …]
  → EnsureTechnicianOwnsClaim(id)
        ├─ no es Tecnico → no aplica (otras reglas actuales)
        ├─ es asignado   → 200 / flujo actual
        └─ no asignado   → 403 (mensaje en español)
```

**Decisiones de diseño:**

1. **No unificar las dos copias de `GetAllAverias`.** El listado ya usa ambas; el cambio es pasar `usuariotecnico: User.IsInRole("Tecnico") && !verTodas`. Refactor de duplicado queda fuera (no pedido).
2. **No crear un listado paralelo ni un tab nuevo de estatus.** Las pestañas Activas / 48h / Taller / Cerradas se mantienen. "Todos los estatus" (RF-03) = el técnico puede usar esas pestañas con el toggle en "Todas", igual que el coordinador.
3. **Ámbito = hub + proyecto actual**, no cross-país ni todos los proyectos del usuario. Coincide con el coordinador.
4. **Detalle de ajenas = `Details`**, no un `Edit` deshabilitado campo a campo (menos riesgo de dejar un botón activo).
5. **Guarda de escritura en servidor**, no solo ocultar botones. Un helper único reutilizado en los POST que el técnico puede disparar.
6. **API Claims (`gp_3.0_siga_api`) y Mobile API fuera de alcance.** Los técnicos operan en SIGA Web.
7. **Proyectos armadoras/Mitsubishi:** `GetAllAveriasArmadora` no filtra por `id_tecnico`. Verificar en T-14; no reescribir ese query salvo que QA demuestre el mismo dolor ahí.
8. **No tocar reasignación del coordinador** salvo cerrar el hueco de que `Assign` POST no tiene `[Authorize]` de rol (el técnico del class-level podría invocarlo). Restringir `Assign` a Coordinador/Admin es coherente con RF-05 y no cambia la UI del coordinador.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — Crear la rama funcional desde `develop`
  - Archivos a crear/modificar: ninguno (solo git)
  - Criterio de completitud: existe `feature/PJ9626-visualizacion-averias-tecnicos` en origin, basada en `origin/develop`

### Fase 1 — Toggle y listado "Todas" (P1)

- [ ] **T-02** — Introducir el flag `verTodas` en los endpoints de listado y export
  - Archivos a crear/modificar: `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs`
  - Cambio: leer un bool del form/query (`verTodas`, default `false`). Calcular `bool filtrarPorTecnico = User.IsInRole("Tecnico") && !verTodas` y pasarlo a `GetAllAverias` en: `Listado48hrs`, `ListadoTaller`, `ListadoRegistradas`, `ListadoCerradas`, `ExportaAveriasActivas`, `ExportaAveriasCerradas`. Coordinador y resto de roles: comportamiento idéntico (siguen mandando `IsInRole("Tecnico")` que para ellos es false).
  - Criterio de completitud: con `verTodas=false` el técnico sigue viendo solo las suyas; con `true` el query no aplica `id_tecnico ==`. Otros roles no cambian.

- [ ] **T-03** — Toggle "Mis averías / Todas" en el listado estándar
  - Archivos a crear/modificar: `GarantiplusWeb/Areas/Averias/Views/Averias/Index.cshtml` (y partials `_ListadoAbiertas.cshtml`, `_ListadoCerradas.cshtml`, `_ListadoSinAtender.cshtml`, `_ListadoSinAtenderTaller.cshtml` si el `datagrid` necesita el extra-field)
  - Cambio: control visible **solo** para `Tecnico`. Default = Mis averías. Al cambiar, recargar los datagrid enviando `verTodas`. Reutilizar estilos Tailwind/TagHelpers existentes; no inventar un design system.
  - Criterio de completitud: el técnico ve el toggle; al cargar Index está en Mis averías; al activar Todas las tablas piden de nuevo con el flag.

- [ ] **T-04** — Columna "Técnico" en la vista Todas (RF-07)
  - Archivos a crear/modificar: los `_Listado*.cshtml` del listado estándar; payloads JSON de `ListadoRegistradas` / `ListadoCerradas` / `Listado48hrs` / `ListadoTaller` en `AveriasController.cs`; búsqueda en `AveriasBusinessRules.cs` y `ArmadorasGeneralBusinessRules.cs` (`case "tecnico"` sobre `tecnico.nombre_completo`)
  - Cambio: mostrar la columna cuando el usuario es Técnico **y** `verTodas` (o siempre para Técnico: más simple y evita desincronizar columnas del datagrid). Valor: `x.tecnico?.nombre_completo` o "Sin asignar".
  - Criterio de completitud: en Todas se ve a quién está asignada cada fila; la búsqueda por esa columna funciona; Coordinador no pierde ni gana columnas (RF-08). Si añadir la columna al coordinador implica tocar su grid, **no añadirla para él**.

- [ ] **T-05** — Replicar toggle en `IndexMitsu` solo si ese layout usa `GetAllAverias` (no armadora)
  - Archivos a crear/modificar: `IndexMitsu.cshtml` + `_Listado*Mitsu.cshtml` **si aplica**
  - Criterio de completitud: o bien el toggle está en Mitsu, o bien una nota en el PR/QA de que Mitsu/armadoras queda verificado como "ya ve todas" / fuera del dolor. No reescribir `GetAllAveriasArmadora`.

### Fase 2 — Detalle solo lectura (P1)

- [ ] **T-06** — Permitir a `Tecnico` el GET de `Details` de cualquier avería del ámbito
  - Archivos a crear/modificar: `AveriasController.Details`
  - Cambio: eliminar el `query.Where(id_tecnico == user.id_tecnico)` que provoca 404. Seguir exigiendo que exista el registro `tecnico` activo del usuario (si no hay ficha técnico, NotFound como hoy).
  - Criterio de completitud: un técnico abre `/Averias/Averias/Details/{idAjena}` y ve estatus, seguimiento y técnico asignado.

- [ ] **T-07** — `Edit` GET: si el técnico no es el asignado, redirigir a `Details`
  - Archivos a crear/modificar: `AveriasController.Edit` (GET)
  - Cambio: mantener el filtro actual para decidir *editable vs. ajena*; en ajena `RedirectToAction("Details", new { id })` en lugar de 404. Los enlaces del datagrid pueden seguir apuntando a `Edit` (comportamiento actual).
  - Criterio de completitud: clic en propia → Edit; clic en ajena → Details. Coordinador sigue entrando a Edit.

- [ ] **T-08** — Distinción visual de solo lectura (RNF-04)
  - Archivos a crear/modificar: `Details.cshtml` (y/o layout del detalle)
  - Cambio: banner o badge visible para `Tecnico` cuando `Model.id_tecnico` no es el suyo, p. ej. "Solo consulta — asignada a {nombre}". No rediseñar la ficha.
  - Criterio de completitud: queda inequívoco que no puede gestionar esa avería.

### Fase 3 — Bloqueo de escritura en backend (P1)

- [ ] **T-09** — Helper de autorización de escritura para técnico
  - Archivos a crear/modificar: `AveriasController.cs` (método privado) o clase pequeña junto al controller. **No** un framework de policies nuevo.
  - Contrato: si el usuario es `Tecnico`, la avería debe tener `id_tecnico` igual al del `tecnico` ligado al username; si no, `Forbid()` / JSON 403 con mensaje en español ("No puede modificar una avería que no tiene asignada"). Coordinador y demás roles no pasan por esta guarda (siguen sus reglas actuales).
  - Criterio de completitud: método único, testeable a mano con dos IDs (propia / ajena).

- [ ] **T-10** — Aplicar el helper en POST de mutación alcanzables por `Tecnico`
  - Archivos a crear/modificar: `AveriasController.cs`
  - Mínimo obligatorio (PRD: editar, estatus, documentos, seguimiento): `Edit` POST, `AddFiles`, y los POST de cambio de estatus / seguimiento / presupuesto / refacciones / resolución / taller que el técnico usa hoy desde `Edit` (`Validacion`, `InWorkshop`, `CarFixed`, `AprovedBudget`, `FixBudget`, `AddSpare`, `UpdateSpare`, `AsignaTallerReparador`, `Resolucion`, `AprobarRechazarAveria`, equivalentes).
  - No reordenar ni extraer el controller. Solo una llamada al helper al inicio de cada acción.
  - Criterio de completitud: POST a una ajena → 403; POST a una propia → igual que hoy. Coordinador no afectado.

- [ ] **T-11** — Cerrar `Assign` POST a roles que reasignan
  - Archivos a crear/modificar: `AveriasController.Assign`
  - Cambio: `[Authorize(Roles = "Coordinador Tecnicos,Administrador General,Administrador General Externo,Gestor de Países")]` (ajustar a los mismos roles que ya ven el bloque de reasignación en `_Edit.cshtml`). Hoy el POST hereda el authorize de clase, que incluye `Tecnico`.
  - Criterio de completitud: un técnico no puede reasignar por POST; el coordinador sí.

### Fase 4 — Validación (P1)

- [ ] **T-12** — Prueba funcional del técnico (RF-01 a RF-07)
  - Criterio de completitud: default = solo las suyas; Todas muestra ajenas (incl. asignadas a usuarios inactivos) en Activas y Cerradas; detalle ajeno solo lectura; propia editable desde ambas vistas; columna técnico visible en Todas.

- [ ] **T-13** — No-regresión coordinador y otros roles (RF-08)
  - Criterio de completitud: coordinador sigue viendo todas sin toggle (o el toggle no le aparece); reasigna igual; distribuidor/taller/admin sin cambios de menú ni de filtro.

---

## 5. Cambios en base de datos *(si aplica)*

No aplica. Se reutilizan `averia.id_tecnico` y `tecnico` ↔ `aspnetusers`.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | — | Sin migración ni seed |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

No hay rutas nuevas. Se modifican las existentes:

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Averias/Averias` | Toggle en Index (solo Técnico) | Modificado |
| POST | `/Averias/Averias/ListadoRegistradas` (y 48hrs, Taller, Cerradas) | Aceptan `verTodas`; relajan filtro de técnico | Modificado |
| POST | `/Averias/Averias/ExportaAverias*` | Mismo flag para no exportar un universo distinto al grid | Modificado |
| GET | `/Averias/Averias/Details/{id}` | Técnico puede leer ajenas | Modificado |
| GET | `/Averias/Averias/Edit/{id}` | Ajena → redirect Details | Modificado |
| POST | `/Averias/Averias/Edit` y demás mutaciones | 403 si técnico no asignado | Modificado |
| POST | `/Averias/Averias/Assign` | Authorize restringido | Modificado |

---

## 7. Variables de entorno y configuración *(si aplica)*

No aplica.

| Variable | Descripción | Ambiente |
|---|---|---|
| — | — | — |

---

## 8. Consideraciones de seguridad

- **RF-05 / RNF-01:** la ampliación de lectura no puede convertirse en ampliación de escritura. Hoy varios POST no validan `id_tecnico`; hay que añadir la guarda **antes** de dar por cerrado el MVP.
- **Assign** debe dejar de ser invocable por `Tecnico` (authorize de método).
- No loguear PII extra. No auditoría de lecturas (fuera de alcance).
- El 403 va con mensaje de usuario en español; logs técnicos en inglés.
- Anti-forgery ya existe en `Edit` POST; no quitarlo.
- "Todas" no cruza de hub: la cadena de conexión sigue siendo la del país compilado/configurado.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin servicios AWS nuevos. SIGA Web sigue en EC2.
- RNF-03: el `datagrid` ya pagina con `DTSettings.from` / `displayLength`. No cargar el universo en memoria. No añadir un export masivo nuevo.
- Sin cambios en ECS, RDS, S3, Cloudflare ni Route 53.

---

## 10. Criterios de aceptación

- [ ] **RF-01:** Al abrir Averías, el técnico ve solo las asignadas a él (mismo resultado que `develop` hoy).
- [ ] **RF-02:** Existe toggle Mis averías / Todas, usable en el listado reutilizado.
- [ ] **RF-03:** Con Todas, ve averías de otros técnicos en las pestañas existentes (activas y cerradas, todos los estatus de esas pestañas).
- [ ] **RF-04:** El detalle de una ajena es solo lectura (estatus y seguimiento visibles).
- [ ] **RF-05:** Un POST de edición/documentos/estatus sobre una ajena es rechazado en servidor (403), no solo oculto en UI.
- [ ] **RF-06:** Sobre una propia, el técnico edita igual que hoy, entre desde Mis averías o desde Todas.
- [ ] **RF-07:** En Todas se muestra el técnico asignado (o "Sin asignar").
- [ ] **RF-08:** Coordinador: visibilidad global y reasignación sin regresión.
- [ ] **RNF-04:** Distinción visual clara de solo lectura.
- [ ] **RNF-05:** Mismo código para los tres hubs (verificar al menos un hub + confirmar que no hay fork por `CountryBase` en este flujo).
- [ ] **RNF-06:** No hay módulo/listado paralelo.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Olvidar un POST de mutación | Alta | Alto | T-10: recorrer acciones `[HttpPost]` del controller usadas desde `_Edit.cshtml`; helper único |
| Duplicado `GetAllAverias` (Averias vs Armadoras) | Alta | Medio | T-02 pasa el flag en todos los call sites; no asumir que `_br` cubre los listados activos |
| Volumen en "Todas" | Media | Medio | Conservar paginación DataTables; no quitar `Skip/Take` |
| Enlaces del grid a `Edit` → 404 en ajenas | Alta | Alto | T-07 redirect a Details |
| `Edit` POST ya no filtra por técnico | Media | Alto | T-10 obligatorio, no "la UI basta" |
| Proyectos Mitsubishi/armadoras | Baja | Medio | T-05 / T-13: verificar, no reescribir `GetAllAveriasArmadora` salvo evidencia |
| Confusión mías vs ajenas | Media | Bajo | T-08 banner + columna técnico |

---

## 12. Notas para el programador

1. Nombre de rol exacto: **`Tecnico`** (sin acento). Coordinador: **`Coordinador Tecnicos`**.
2. Relación de asignación: `averia.id_tecnico` → `tecnico.id_tecnico` → `tecnico.aspnetusers.UserName`.
3. Averías de personal de baja: siguen teniendo `id_tecnico`; con Todas el técnico activo las verá. La reasignación sigue siendo del coordinador.
4. No mezclar en esta rama un cambio de país (`siga-cambio-pais-base`). Probar COL/CHL cambiando hub en local aparte, o en QA por país.
5. `AveriasController` supera ampliamente 200 líneas: **no** partirlo en `partial` salvo que el programador lo pida; el PRD pide no refactorizar.
6. Patrocinador formal (PRD §13): no bloquea el desarrollo.
7. Mensajes al usuario en español; código y logs en inglés (`coding-guidelines.md`).

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles**. El PRD no define P2/P3: **todo el alcance es P1**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama funcional | T-01 | 0.25 días | 93 |
| **Fase 1 — Toggle y listado (P1)** | Flag `verTodas`, UI toggle, columna Técnico, Mitsu si aplica | T-02 a T-05 | 1.5 – 2.5 días | 95 |
| **Fase 2 — Detalle solo lectura (P1)** | Details GET, redirect Edit, banner | T-06 a T-08 | 0.75 – 1.5 días | 94 |
| **Fase 3 — Escritura en backend (P1)** | Helper + POST + Assign | T-09 a T-11 | 1.5 – 2.5 días | 96 |
| **Fase 4 — Validación (P1)** | Técnico + no-regresión coordinador | T-12 a T-13 | 1 – 1.5 días | 97 |
| **Total proyecto (P1)** | | 13 tareas | ~5 – 8 días hábiles (≈ 1.5 – 2 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 4 | T-01 a T-13 | ~5 – 8 días hábiles (≈ 1.5 – 2 semanas) | — |

> **Notas sobre la tabla:**
> - No hay P2/P3. Fase 3 no es opcional: sin ella el MVP viola RF-05.
> - Los rangos salen de la dispersión de POST en `AveriasController` (~4000 líneas) y del duplicado `GetAllAverias`.
> - La columna **ID (BD)** la llena el flujo al registrar el plan; no editarla a mano.

> **Riesgo de deadline:** el PRD (2026-08-12) **no fija fecha límite**. Con un desarrollador, 5–8 días hábiles caben en dos semanas. No se recomienda recortar Fase 3. Un segundo desarrollador aportaría poco (el cuello es el mismo controller); no paralelizar.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
