# Plan de Desarrollo — Ajustes al módulo de Averías para Bridgestone (captura de llantas)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `SIGA/PJ0164-bridgestone-averias-refaccion-presupuesto/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web) |
| Rama base | `develop` (verificada y actualizada con `origin/develop` al generar el plan) |
| Rama a crear | `feature/ECX-0164-bridgestone-captura-refaccion-presupuesto` |
| Tipo | Feature sobre proyecto existente |
| Responsable | Javier Antonio Oropeza — TI Garantiplus México |
| Fecha de generación | 2026-08-18 |
| Estado | ✅ Finalizado — ejecutado, probado y liberado a producción el 2026-08-20 |
| ID plan (BD) | `50` (`pm_plan_desarrollo.id`) |

---

## 1. Resumen técnico

Se restringe la captura de refacciones y presupuesto del módulo de Averías **cuando la avería pertenece al proyecto Bridgestone** (`PaisMX.BridgestoneProjectId = 173`), reutilizando el mecanismo de configuración por proyecto que ya existe para BMW: `ClaimBudgetRequirements`, resuelto en `PaisMX.GetClaimBudgetRequirements(idProyecto)` y expuesto a las vistas por `ViewBag` (RNF-06).

**Componentes que se modifican** (no se crea ningún componente ni servicio nuevo):

| Componente | Cambio |
|---|---|
| `PaisesService` (librería de reglas de país/proyecto) | Se extiende el DTO de reglas de presupuesto y la resolución para MX |
| `GarantiplusWeb` — `AveriasController` | Exposición de la regla a la vista y refuerzo en las acciones de escritura |
| `GarantiplusWeb` — vistas del área Averías | Preselección + solo lectura + ocultamiento condicionado |
| `GarantiplusWeb/appsettings*.json` | Nuevos identificadores configurables por ambiente |

**Stack:** el existente de SIGA Web — .NET Core 8 / C#, Razor (MVC con partials), HTML + jQuery + jQuery Validate + Chosen, PostgreSQL vía `GarantiplusRepository`. Despliegue: EC2 (Ubuntu + Nginx), sin cambios. No se agrega ni se modifica infraestructura (`rules/stack.md`, `rules/infraestructura.md`).

**Arquitectura:** no cambia. Se respeta la arquitectura existente del monolito web de SIGA; el cambio es aditivo y condicionado por proyecto (`rules/arquitectura.md` — la arquitectura existente no se modifica salvo solicitud explícita). No se refactoriza código existente.

---

## 2. Prerequisitos

- [x] PRD validado por el responsable
- [x] Acceso al repositorio confirmado (`develop` actualizado)
- [x] `CLAUDE.md` presente en el repositorio
- [x] **`id_refaccion` del registro "Llanta" en el catálogo `refaccion` de MX** — resuelto: TI cargó el valor en la configuración de QA y de producción
- [x] **`id_impuesto` del registro "I.V.A. cero" en el catálogo `impuesto` de MX** — resuelto: mismo caso
- [x] Confirmar que ambos registros están activos y son únicos para `codigo_pais = 'MX'`
- [x] Confirmar el ticket real `ECX-XXX` — se quedó con `ECX-0164` (folio del PRD), que es el nombre con el que se liberó
- [x] Avería Bridgestone de prueba en QA, más una avería de un proyecto estándar y una de BMW (proyecto 206) para regresión

> El desarrollo **no se bloquea** por los dos IDs: la decisión tomada es parametrizarlos por configuración (ver §7), así que el código se implementa completo y los valores se llenan por ambiente antes de probar.

---

## 3. Arquitectura del cambio

Flujo de la regla, idéntico al que ya sigue BMW:

```
appsettings (Averias:Bridgestone:*)
        │
        ▼
PaisMX.GetClaimBudgetRequirements(idProyecto)  ──►  ClaimBudgetRequirements
        │                                                │
        │ (por proyecto de la avería)                     │
        ├────────────────────────────► AveriasController.Edit ──► ViewBag ──► _RefaccionesServiciosDealer
        │                                                                └──► _PresupuestoDealer
        │                                                                └──► Edit.cshtml (JS)
        │
        └────────────────────────────► AddSpareDealer / AddServiceDealer / UpdateTax / AssignBudget
                                              (refuerzo en servidor — RNF-02)
```

**Decisiones de diseño:**

1. **Un solo punto de verdad para la regla.** Todo (vista y servidor) se condiciona con `ClaimBudgetRequirements` resuelto **por el proyecto de la avería**, no por el proyecto de la sesión. Ya existe el helper `AveriasController.GetBudgetRequirementsForClaimAsync(idAveria)` para las acciones POST; se reutiliza sin cambios de criterio. El comentario que documenta por qué (la sesión puede caer al proyecto 3 por omisión) sigue aplicando.
2. **Banderas genéricas, no "IsBridgestone" en las vistas.** Se agregan `ViewBag.UsesFixedSpare`, `ViewBag.FixedSpareId`, `ViewBag.FixedTaxId`, `ViewBag.AllowsLaborCapture` y `ViewBag.BudgetConfigError`. La vista no sabe que el proyecto es Bridgestone: solo aplica la regla que recibe (RF-17). Esto evita una tercera bifurcación por nombre de cliente en una vista que ya bifurca por BMW.
3. **Validación del catálogo sin consultas extra en el render** (RNF-07): `Edit` ya carga `ViewBag.Piezas` y `ViewBag.Impuestos` filtrados por país en `SetupViewBags()`. La existencia de los IDs configurados se verifica **en memoria** sobre esas listas. Las acciones POST sí consultan, porque no tienen los catálogos cargados.
4. **Solo lectura que sí viaja** (RNF-03): en el formulario de refacciones los datos se arman a mano en JS (`agregaPrecioDistribuidor`) y `jQuery.val()` lee campos deshabilitados sin problema. En el formulario de presupuesto (`AssignBudget`) el POST **sí** es un submit real, así que un `<select disabled>` no viajaría: ahí se usa `select` bloqueado **más un `<input type="hidden">` con el mismo nombre**.

---

## 4. Tareas de desarrollo

### Fase 1 — Configuración y reglas por proyecto

> ID (BD): `162` — `pm_plan_fase.id`

- [ ] **T-01** — Extender `ClaimBudgetRequirements` con la regla de captura fija
  - Archivos a modificar: `PaisesService/Classes/ClaimBudgetRequirements.cs`
  - Campos nuevos: `UsesFixedSpare` (bool), `FixedSpareId` (int?), `FixedTaxId` (int?), `AllowsLaborCapture` (bool), `ConfigurationError` (string)
  - `Default` debe quedar con `UsesFixedSpare = false`, `AllowsLaborCapture = true`, IDs en `null` y `ConfigurationError = null` — para que ningún proyecto existente cambie de comportamiento (RF-18)
  - Documentar la clase en XML doc, en inglés (`coding-guidelines.md`)
  - Criterio de completitud: compila y `ClaimBudgetRequirements.Default.AllowsLaborCapture == true`

- [ ] **T-02** — Registrar los identificadores configurables
  - Archivos a modificar: `GarantiplusWeb/appsettings.json`, `GarantiplusWeb/appsettings.Development.json`
  - Sección: `Averias:Bridgestone:RefaccionLlantaId` y `Averias:Bridgestone:ImpuestoIvaCeroId` (la sección `Averias` ya existe)
  - Criterio de completitud: las claves existen en ambos archivos; los valores de QA/producción se cargan en el despliegue

- [ ] **T-03** — Resolver la regla de Bridgestone en `PaisMX`
  - Archivos a modificar: `PaisesService/Classes/MX/PaisMX.cs`
  - Guardar la configuración en el constructor (ya recibe `IConfiguration`) en dos campos privados `int?`
  - Reescribir `GetClaimBudgetRequirements(int idProyecto)` para atender los dos proyectos: la rama de `BmwProjectId` queda **exactamente** como está hoy; se agrega la de `BridgestoneProjectId`, que devuelve `UsesFixedSpare = true`, `AllowsLaborCapture = false` y los IDs configurados. Cualquier otro proyecto sigue devolviendo `Default`
  - Si falta cualquiera de los dos IDs en configuración: devolver la regla con `ConfigurationError` con un mensaje claro y los IDs en `null` (RNF-04). **No** devolver `Default`: eso reabriría la captura libre en Bridgestone
  - No consultar la base de datos en esta rama (RNF-07)
  - Criterio de completitud: con configuración presente devuelve los IDs; sin configuración devuelve `ConfigurationError` poblado; proyecto 206 sigue devolviendo `UsesUat = true`; proyecto arbitrario devuelve `Default`

### Fase 2 — Refuerzo en servidor (fuente de verdad — RNF-02)

> ID (BD): `163` — `pm_plan_fase.id`

- [ ] **T-04** — Forzar los valores de la refacción en `AddSpareDealer`
  - Archivos a modificar: `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` (acción `AddSpareDealer`, ~línea 2270)
  - Con `UsesFixedSpare == true`: si hay `ConfigurationError`, responder `{ success = false, errors = ... }` sin escribir nada; en caso contrario forzar `id_refaccion = FixedSpareId.Value`, `mano_obra = 0`, `no_parte = null`, ignorando lo recibido (RF-11, RF-14)
  - Reutilizar `GetBudgetRequirementsForClaimAsync(id)`, que ya se invoca en esta acción para BMW — no agregar una segunda resolución
  - Verificar que la refacción se registre con el ID forzado incluso si el cliente envió otro
  - Criterio de completitud: un POST manipulado con `id_refaccion` distinto, `mano_obra = 500` y `no_parte = "X"` guarda la refacción "Llanta" con `mano_obra = 0.00` y `no_parte` nulo

- [ ] **T-05** — Rechazar la captura de mano de obra en `AddServiceDealer`
  - Archivos a modificar: `AveriasController.cs` (acción `AddServiceDealer`, ~línea 2338)
  - Con `AllowsLaborCapture == false`: responder `{ success = false, errors = "El proyecto no permite capturar mano de obra" }` antes de cualquier escritura (RF-16)
  - Criterio de completitud: un POST directo a `AddServiceDealer` sobre una avería Bridgestone no inserta en `mano_obra_averia`

- [ ] **T-06** — Forzar el impuesto en `UpdateTax`
  - Archivos a modificar: `AveriasController.cs` (acción `UpdateTax`, ~línea 1135)
  - Con `UsesFixedSpare == true`: forzar `id_impuesto = FixedTaxId.Value` ignorando el recibido (o rechazar si viene distinto)
  - **Nota:** el PRD nombra solo `AssignBudget` (RF-15), pero `UpdateTax` es la acción que realmente persiste el impuesto cuando el usuario cambia el selector (`updateTaxDealer()` en `Edit.cshtml:1299`). Sin este refuerzo, RNF-02 queda incompleto
  - Criterio de completitud: un POST a `UpdateTax` con otro `id_impuesto` deja la avería en "I.V.A. cero"

- [ ] **T-07** — Forzar el impuesto en `AssignBudget` y calcular con el porcentaje correcto
  - Archivos a modificar: `AveriasController.cs` (acción `AssignBudget`, ~línea 3386)
  - Con `UsesFixedSpare == true`, después de `TryUpdateModelAsync(model)`: forzar `model.id_impuesto = FixedTaxId.Value` (RF-15)
  - **Cuidado (defecto latente):** la línea del cálculo usa `model.impuesto.porcentaje` (la navegación cargada antes del binding), mientras que la variable `imp` que se consulta justo arriba no se usa. Si se fuerza `id_impuesto` sin corregir esto, el total se calcularía con el porcentaje anterior. En la rama de Bridgestone el cálculo debe usar el porcentaje del impuesto realmente aplicado (`imp`, recargado después de forzar el ID). El comportamiento para los demás proyectos se deja intacto: corregirlo de forma general es un ajuste aparte
  - Criterio de completitud: al guardar el presupuesto de una avería Bridgestone, `presupuesto == importe_mo + importe_refacciones + importe_diversos` (I.V.A. cero, sin recargo)

- [ ] **T-08** — Corregir el impuesto por omisión en `UpdateBudgetDealer`
  - Archivos a modificar: `AveriasController.cs` (método privado `UpdateBudgetDealer`, ~línea 3272)
  - Hoy, si la avería no tiene impuesto, asigna `id_impuesto = 1`. En una avería Bridgestone recién creada eso fija un impuesto distinto de "I.V.A. cero" en el primer registro de refacción, antes de que el usuario toque el selector
  - Con `UsesFixedSpare == true`, el valor por omisión debe ser `FixedTaxId`; para el resto de los proyectos se conserva el `1` actual
  - Criterio de completitud: registrar la primera refacción en una avería Bridgestone sin impuesto previo deja `id_impuesto` en "I.V.A. cero" y el total sin I.V.A.

### Fase 3 — Vistas y comportamiento de pantalla

> ID (BD): `164` — `pm_plan_fase.id`

- [ ] **T-09** — Exponer la regla a las vistas
  - Archivos a modificar: `AveriasController.cs` (acción `Edit`, ~líneas 1774-1779)
  - Junto a las banderas de BMW ya existentes, publicar `ViewBag.UsesFixedSpare`, `ViewBag.FixedSpareId`, `ViewBag.FixedTaxId`, `ViewBag.AllowsLaborCapture` y `ViewBag.BudgetConfigError` (RF-01)
  - Validar **en memoria** contra `ViewBag.Piezas` y `ViewBag.Impuestos` que los IDs configurados existan en el catálogo del país; si no, poblar `ViewBag.BudgetConfigError`, registrar `Error` en el log y dejar los IDs en `null` (RNF-04, RNF-07)
  - Criterio de completitud: la vista de una avería Bridgestone recibe las cinco banderas; la de otro proyecto las recibe en su valor neutro

- [ ] **T-10** — Captura de refacciones: preselección, bloqueo y ocultamiento
  - Archivos a modificar: `GarantiplusWeb/Areas/Averias/Views/Averias/_RefaccionesServiciosDealer.cshtml`
  - Con `ViewBag.UsesFixedSpare == true`:
    - `tipo_costo`: renderizar con `Refacción` seleccionado y bloqueado (RF-02, RF-03)
    - `pieza`: renderizar con `FixedSpareId` seleccionado y bloqueado; al ser `chosen-select`, el bloqueo se aplica también sobre el control de Chosen (RF-05, RF-06)
    - Ocultar el bloque de `no_parte` (RF-07), el de `mano_obra` (RF-08) y el de `servicio` (RF-09)
    - Envolver el bloque "Servicios (Mano de obra)" (título + tabla) en un contenedor con id propio y renderizarlo oculto cuando `!Model.mano_obra_averia.Any()`; cuando hay registros, mostrarlo sin el botón de eliminar (consulta) (RF-10)
    - Si `ViewBag.BudgetConfigError` tiene valor: mostrar un `alert alert-danger` con el mensaje y deshabilitar el botón "Registrar"
  - Si `UsesFixedSpare != true`, el markup debe quedar **byte a byte equivalente** al actual, incluida la bifurcación de BMW (RF-18)
  - Los campos bloqueados deben verse claramente no editables (RNF-09)
  - Criterio de completitud: al abrir una avería Bridgestone los campos de refacción están visibles sin interacción (RF-04), con Tipo y Refacción fijos; en una avería de otro proyecto la pantalla es idéntica a hoy

- [ ] **T-11** — Presupuesto: impuesto preseleccionado y bloqueado
  - Archivos a modificar: `GarantiplusWeb/Areas/Averias/Views/Averias/_PresupuestoDealer.cshtml`
  - Con `ViewBag.UsesFixedSpare == true`: seleccionar `FixedTaxId` en el `DropDownListFor` de `id_impuesto`, bloquearlo, quitar el `onchange` y agregar un `hidden` con el mismo nombre y valor para que el POST de `AssignBudget` siga recibiendo el campo (RF-12, RF-13, RNF-03)
  - Criterio de completitud: en Bridgestone el selector no es editable y `AssignBudget` recibe `id_impuesto` con el valor fijo; en otros proyectos el selector y su `onchange` siguen operando igual

- [ ] **T-12** — Ajustar el JavaScript de la pantalla
  - Archivos a modificar: `GarantiplusWeb/Areas/Averias/Views/Averias/Edit.cshtml`
  - Publicar la bandera del lado cliente junto a `isBmwUat` (p. ej. `var usesFixedSpare = ...;`), con el mismo estilo de render de `ViewBag`
  - `limpiaFormularioRefacciones()` (~línea 1060): hoy limpia `tipo_costo` y `pieza` después de cada registro, lo que **rompería la preselección**. Con `usesFixedSpare` debe conservar los valores fijos y volver a dejar visible el bloque de refacción
  - `showHideTipoCosto()` debe ejecutarse al cargar también cuando `usesFixedSpare` (hoy solo se invoca si `isBmwUat`), para satisfacer RF-04
  - `agregaPrecioDistribuidor()`: con `usesFixedSpare`, no enviar `mano_obra` ni `no_parte` y omitir la ruta de `M.O.`
  - Reconstrucción de tablas en `updateBudgetDealer()` (~línea 742): al terminar, el contenedor de "Servicios (Mano de obra)" debe ocultarse o mostrarse según `data.servicios.length`, para que RF-10 se sostenga después del refresco AJAX y después de eliminar un servicio
  - Validación jQuery: al ocultar `mano_obra`, su regla `mayorACero` no debe bloquear el envío
  - Criterio de completitud: registrar dos refacciones seguidas en una avería Bridgestone funciona sin volver a elegir Tipo ni Refacción, y la tabla de servicios permanece oculta

- [ ] **T-13** — Revisión de no regresión en la vista compartida
  - Archivos a revisar (sin cambios esperados): `_RefaccionesServiciosAdmin`, `_RefaccionesServiciosDealerCOL.cshtml`, `_Edit.cshtml`
  - Confirmar que ninguna bandera nueva se filtra a esas vistas y que siguen leyendo únicamente lo que leen hoy (fuera de alcance del PRD, §6)
  - Criterio de completitud: `git diff` no toca esos archivos y la vista administrativa se abre igual que antes

### Fase 4 — Pruebas y validación

> ID (BD): `165` — `pm_plan_fase.id`

- [x] **T-14** — Pruebas funcionales sobre avería Bridgestone (proyecto 173)
  - Criterio de completitud: la matriz de RF-01 a RF-17 queda verificada en QA, incluido el caso de configuración faltante (RNF-04)

- [x] **T-15** — Pruebas de regresión obligatorias (RNF-01)
  - Avería de un **proyecto estándar**: Tipo, Refacción, No. Parte, M.O., Servicio, impuesto y presupuesto se comportan como hoy
  - Avería de **BMW (proyecto 206)**: la captura por UAT y el importe derivado siguen intactos
  - Avería con **mano de obra previa** en Bridgestone: la tabla de servicios se muestra en consulta y su monto sigue sumando al presupuesto
  - Criterio de completitud: los tres escenarios sin diferencias respecto al comportamiento previo

- [x] **T-16** — Pruebas de refuerzo en servidor (RNF-02)
  - Envío manipulado a `AddSpareDealer`, `AddServiceDealer`, `UpdateTax` y `AssignBudget` sobre una avería Bridgestone
  - Criterio de completitud: ninguno logra registrar mano de obra, refacción distinta a "Llanta", `no_parte` o un impuesto diferente

---

## 5. Cambios en base de datos

**No aplica.** No se crean ni modifican tablas, columnas ni índices. Se escribe sobre las mismas entidades que ya escribe el módulo (`averia`, `refaccion_averia`, `mano_obra_averia`) y se lee de los catálogos existentes (`refaccion`, `impuesto`, `proyecto`). No hay migración ni limpieza de datos históricos (fuera de alcance, PRD §6).

---

## 6. Endpoints nuevos o modificados

No se agregan endpoints. Se modifica el comportamiento interno de acciones MVC existentes del área Averías:

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `Averias/Averias/AddSpareDealer/{id}` | Fuerza refacción fija, `mano_obra = 0` y `no_parte` nulo en Bridgestone | Modificado |
| POST | `Averias/Averias/AddServiceDealer/{id}` | Rechaza la captura de mano de obra en Bridgestone | Modificado |
| POST | `Averias/Averias/UpdateTax/{id}` | Fuerza el impuesto fijo en Bridgestone | Modificado |
| POST | `Averias/Averias/AssignBudget/{id}` | Fuerza el impuesto fijo y calcula con su porcentaje real | Modificado |
| GET | `Averias/Averias/Edit/{id}` | Publica las banderas de captura fija a las vistas | Modificado |

> Las convenciones REST de `coding-guidelines.md` (§5: plural, `v1/[action]`, kebab-case) aplican a la API de SIGA. Estas son acciones MVC preexistentes de SIGA Web; se respeta su nomenclatura actual y **no** se renombran (no se refactoriza código existente).

---

## 7. Variables de entorno y configuración

| Clave | Descripción | Ambiente |
|---|---|---|
| `Averias:Bridgestone:RefaccionLlantaId` | `id_refaccion` del registro "Llanta" en el catálogo de MX | Desarrollo / QA / Producción |
| `Averias:Bridgestone:ImpuestoIvaCeroId` | `id_impuesto` del registro "I.V.A. cero" en el catálogo de MX | Desarrollo / QA / Producción |

**Decisión tomada (pregunta abierta del PRD, §14 "Parametrización"):** los identificadores van en `appsettings` por ambiente y `PaisMX` los lee del `IConfiguration` que ya recibe en su constructor. Se eligió sobre constantes en código porque los IDs de catálogo pueden diferir entre desarrollo, QA y producción, y un cambio de catálogo no debe exigir recompilar y desplegar; y sobre una tabla de configuración porque esta última agrega migración de BD y una consulta por render, en tensión con RNF-07 (un catálogo administrable de reglas por proyecto está fuera de alcance, PRD §6).

No son secretos, así que van en `appsettings` versionado y no en AWS Secrets Manager.

---

## 8. Consideraciones de seguridad

- **Sin cambios de permisos IAM ni de roles/policies de la aplicación** (RNF-08). Ningún usuario gana o pierde acceso.
- **El bloqueo de interfaz no es el control**: la integridad la garantizan T-04 a T-08 en el servidor (RNF-02). Esa es la razón por la que la Fase 2 va antes de la Fase 3.
- **Sin secrets nuevos**: las dos claves de configuración son identificadores de catálogo, no credenciales. Nada se agrega al código fuente (`coding-guidelines.md` §11).
- **Sin concatenación de SQL**: todo el acceso a datos sigue por `GarantiplusRepository` con expresiones tipadas.
- **Entrada de usuario**: los valores que antes elegía el usuario (`tipo_costo`, `id_refaccion`, `id_impuesto`) pasan a ser determinados por el servidor en Bridgestone, lo que reduce la superficie de captura inválida.
- **Logging**: el error de configuración faltante se registra con `Error`; no se registran datos personales ni montos sensibles más allá de lo que ya se registra (RNF-05).

---

## 9. Consideraciones de infraestructura

**No aplica.** Sin servicios AWS nuevos, sin cambios en EC2, RDS, S3, ECS, Cloudflare ni Route 53, sin impacto de costo. El despliegue es el habitual de SIGA Web sobre la instancia EC2 correspondiente a GarantiPlus México; los únicos artefactos nuevos son las dos claves de `appsettings` por ambiente.

---

## 10. Criterios de aceptación

- [ ] En una avería del proyecto 173, al abrir la pantalla: Tipo = "Refacción" (bloqueado), Refacción = "Llanta" (bloqueado), campos de refacción visibles sin interacción, y sin No. Parte, sin M.O. ni selector de Servicio
- [ ] La tabla "Servicios (Mano de obra)" está oculta si la avería no tiene mano de obra, y visible en modo consulta si la tiene
- [ ] El selector de impuesto de Presupuesto llega en "I.V.A. cero", bloqueado, y el campo sigue viajando en el POST
- [ ] El total del presupuesto de una avería Bridgestone equivale a la suma de refacciones y diversos, sin recargo de I.V.A.
- [ ] Las refacciones registradas en Bridgestone quedan con `no_parte` nulo/vacío y `mano_obra = 0.00`
- [ ] Envíos manipulados a `AddSpareDealer`, `AddServiceDealer`, `UpdateTax` y `AssignBudget` no logran registrar mano de obra, otra refacción ni otro impuesto
- [ ] Con configuración ausente o con IDs inexistentes en el catálogo, la pantalla no truena: muestra un mensaje claro, registra el error y no permite guardar un valor incorrecto
- [ ] Una avería de un proyecto estándar y una de BMW se comportan exactamente como antes del cambio
- [ ] La vista administrativa de aprobación y la variante de Colombia quedan sin modificar
- [ ] Commit en la rama funcional con el formato `[ECX-XXX] ...` y sin commits directos a `develop`

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| La vista es compartida y ya bifurca por BMW; una condición mal puesta afecta a otros proyectos | Media | Alto | Toda la lógica nueva va dentro de `if (UsesFixedSpare)`; las ramas existentes no se tocan; T-15 exige regresión explícita contra proyecto estándar y BMW |
| `limpiaFormularioRefacciones()` borra Tipo y Refacción después de cada registro y desarma la preselección | Alta | Medio | T-12 la condiciona; se prueba registrando dos refacciones consecutivas |
| `UpdateBudgetDealer` fija `id_impuesto = 1` cuando la avería no tiene impuesto | Media | Alto | T-08 lo condiciona al impuesto fijo del proyecto; se prueba con una avería Bridgestone nueva |
| `AssignBudget` calcula con `model.impuesto.porcentaje` (navegación previa al binding) y no con el impuesto recién asignado | Media | Alto | T-07 usa el porcentaje del impuesto realmente aplicado en la rama de Bridgestone; se verifica que el total no traiga recargo |
| Un `disabled` en el selector de impuesto haría que `AssignBudget` reciba el campo vacío | Media | Alto | T-11 acompaña el selector bloqueado con un `hidden` del mismo nombre (RNF-03) |
| `UpdateTax` queda sin refuerzo por no estar nombrada en el PRD | Media | Alto | T-06 la incluye; es la ruta real del `onchange` del selector |
| Los IDs de "Llanta" o "I.V.A. cero" difieren entre ambientes o cambian en catálogo | Media | Medio | Parametrización por ambiente (§7) + validación de existencia con mensaje claro (T-09) |
| Chosen mantiene visible el control aunque el `select` esté bloqueado | Media | Bajo | T-10 aplica el bloqueo sobre el control de Chosen y se valida visualmente (RNF-09) |
| Averías Bridgestone previas con mano de obra siguen sumando al presupuesto | Baja | Medio | RF-10 conserva la visibilidad en consulta; la corrección del histórico está fuera de alcance |

---

## 12. Notas para el programador

**Decisiones tomadas al generar el plan:**

1. **Fase 2 antes de Fase 3.** El refuerzo en servidor se implementa antes de la interfaz: es lo que sostiene RNF-02, y así la pantalla nunca queda como único control.
2. **Banderas de `ViewBag` genéricas** (`UsesFixedSpare`, no `IsBridgestone`), para no agregar una tercera bifurcación por nombre de cliente en una vista que ya bifurca por BMW.
3. **Dos hallazgos de código que el PRD no menciona y que el plan incorpora:** `UpdateTax` (T-06) es la acción que realmente persiste el impuesto al cambiar el selector, y `UpdateBudgetDealer` (T-08) fija `id_impuesto = 1` por omisión. Sin ambos, el impuesto de Bridgestone podría acabar distinto de "I.V.A. cero" sin que nadie manipule nada.
4. **Defecto latente en `AssignBudget`** (T-07): la variable `imp` se consulta y no se usa; el cálculo toma el porcentaje de la navegación cargada antes del binding. Se corrige solo en la rama de Bridgestone; arreglarlo para todos los proyectos es un cambio de comportamiento general que amerita su propio ticket.

**Pendientes de validar antes de ejecutar:**

- Los dos IDs de catálogo (§2). Sin ellos se puede desarrollar y compilar, pero no probar en QA.
- El ticket real `ECX-XXX` para nombrar la rama.
- Que la columna "M.O." de la **tabla** de refacciones se conserve mostrando `$0.00` en Bridgestone. El PRD pide ocultar el **campo de captura** (RF-08), no la columna, y su criterio para PDF y reportes es aceptar campos vacíos (§6); si operación prefiere ocultarla, es un ajuste menor en T-10 y T-12.

**Preguntas abiertas del PRD que este plan no resuelve** (siguen fuera de alcance, PRD §6): vista administrativa `_RefaccionesServiciosAdmin`, variante de Colombia, PDF y reportes, corrección del histórico, campo "Diversos" y alcance a otros países.

**Flujo de git** (`rules/version-control.md`): la rama funcional se crea desde `develop` actualizado; Claude Code hace los commits con formato `[ECX-XXX] ...`; los Pull Requests (`feature/*` → `pre-qa` → `qa`, y el paso a `release`/`main`) son responsabilidad del programador.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
