# Registro de Avance — Ajustes al módulo de Averías para Bridgestone (captura de llantas)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/ECX-0164-bridgestone-captura-refaccion-presupuesto` |
| Responsable actual | Javier Antonio Oropeza |
| Última actualización | 2026-08-20 |
| Estado general | ✅ Finalizado — probado y liberado a producción el 2026-08-20 |
| ID plan (BD) | `50` (`pm_plan_desarrollo.id`) |

---

## Seguimiento de fases (BD)

| ID (BD) | Orden | Fase | Duración | Estatus | Fecha inicio | Fecha fin |
|---|---|---|---|---|---|---|
| `162` | 0 | Fase 1 — Configuración y reglas por proyecto | 1 | Completado | 2026-08-18 | 2026-08-18 |
| `163` | 1 | Fase 2 — Refuerzo en servidor (fuente de verdad) | 2 | Completado | 2026-08-18 | 2026-08-18 |
| `164` | 2 | Fase 3 — Vistas y comportamiento de pantalla | 2 | Completado | 2026-08-18 | 2026-08-18 |
| `165` | 3 | Fase 4 — Pruebas y validación | 2 | Completado | 2026-08-19 | 2026-08-20 |

---

## Resumen de estado

**Plan finalizado.** Las 16 tareas (T-01 a T-16) están completas: las 13 de desarrollo se entregaron el 2026-08-18 en cuatro commits y las 3 de prueba se ejecutaron el 2026-08-19. El cambio **se liberó a producción el 2026-08-20**.

**El bloqueo de configuración quedó resuelto:** TI / Catálogos Garantiplus México cargó los dos identificadores (`Averias:Bridgestone:RefaccionLlantaId` e `Averias:Bridgestone:ImpuestoIvaCeroId`) en la configuración de QA y de producción, así que la degradación segura de RNF-04 ya no se activa y la captura de Bridgestone opera normalmente.

**Pruebas ejecutadas:** funcionales sobre avería Bridgestone (T-14), regresión sobre proyecto estándar y BMW proyecto 206 (T-15) y refuerzo en servidor con envíos manipulados (T-16). Sin diferencias respecto al comportamiento previo en los proyectos no restringidos.

**Queda un punto abierto de operación**, no de código: la acumulación de refacciones en un solo renglón (ver más abajo). No bloquea la liberación.

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Extender `ClaimBudgetRequirements` | Claude Code | 2026-08-18 | Cinco campos nuevos. `AllowsLaborCapture` con inicializador `= true` para no romper BMW |
| T-02 | Registrar los identificadores configurables | Claude Code | 2026-08-18 | Solo en `appsettings.json`, con valor `null` (ver decisiones) |
| T-03 | Resolver la regla de Bridgestone en `PaisMX` | Claude Code | 2026-08-18 | Lee configuración en el constructor; sin consultas a BD (RNF-07) |
| T-04 | Forzar los valores de la refacción en `AddSpareDealer` | Claude Code | 2026-08-18 | Fuerza refacción configurada, `mano_obra` en 0 y `no_parte` nulo |
| T-05 | Rechazar la captura de mano de obra en `AddServiceDealer` | Claude Code | 2026-08-18 | Rechaza antes de escribir |
| T-06 | Forzar el impuesto en `UpdateTax` | Claude Code | 2026-08-18 | Hallazgo fuera del PRD; es la acción que realmente persiste el impuesto |
| T-07 | Forzar el impuesto y el porcentaje en `AssignBudget` | Claude Code | 2026-08-18 | Se corrigió el porcentaje usado en el cálculo solo para la rama restringida |
| T-08 | Corregir el impuesto por omisión en `UpdateBudgetDealer` | Claude Code | 2026-08-18 | Hallazgo fuera del PRD; el `1` fijo rompía el I.V.A. cero en la primera refacción |
| T-09 | Exponer la regla a las vistas | Claude Code | 2026-08-18 | Nuevo `SetFixedSpareViewBags`, con validación de catálogo en memoria |
| T-10 | Captura de refacciones: preselección, bloqueo y ocultamiento | Claude Code | 2026-08-18 | Tipo y refacción bloqueados; sin No. Parte, M.O. ni Servicio; tabla de servicios condicional |
| T-11 | Presupuesto: impuesto preseleccionado y bloqueado | Claude Code | 2026-08-18 | Select bloqueado + `hidden` con el mismo nombre (RNF-03) |
| T-12 | Ajustar el JavaScript de la pantalla | Claude Code | 2026-08-18 | Limpieza del formulario, envío de campos, visibilidad inicial y refresco de tablas |
| T-13 | Revisión de no regresión en la vista compartida | Claude Code | 2026-08-18 | Verificado: `_RefaccionesServiciosAdmin`, `_RefaccionesServiciosDealerCOL` y `_Edit` sin cambios |
| T-02 (valores) | Cargar `RefaccionLlantaId` e `ImpuestoIvaCeroId` | TI / Catálogos GP México | 2026-08-19 | Cargados en la configuración de QA y de producción; se levanta el bloqueo |
| T-14 | Pruebas funcionales sobre avería Bridgestone (proyecto 173) | Javier Antonio Oropeza | 2026-08-19 | Matriz RF-01 a RF-17 verificada en QA |
| T-15 | Pruebas de regresión (proyecto estándar y BMW 206) | Javier Antonio Oropeza | 2026-08-19 | Sin diferencias respecto al comportamiento previo (RNF-01) |
| T-16 | Pruebas de refuerzo en servidor | Javier Antonio Oropeza | 2026-08-19 | Envíos manipulados rechazados en las cuatro acciones (RNF-02) |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| — | — | — | — | Sin tareas de desarrollo en curso |

---

## Tareas pendientes ⏳

| ID | Bloqueada por (si aplica) |
|---|---|
| — | Ninguna. Todas las tareas del plan están completas |

---

## Tareas bloqueadas 🔴

| ID | Motivo del bloqueo | Resolución |
|---|---|---|
| — | Ninguna. Los tres bloqueos de QA y el de configuración se resolvieron el 2026-08-19 | — |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| `AllowsLaborCapture` se declara con inicializador `= true`, no solo en `Default` | La rama existente de BMW construye un `ClaimBudgetRequirements` con un literal que no fija el campo nuevo; un `bool` sin inicializador habría quedado en `false` y **le habría bloqueado la captura de mano de obra a BMW**. Con el inicializador, cualquier objeto que no opte por restringir conserva el comportamiento actual | Evita una regresión directa sobre BMW (RNF-01, RF-18) |
| Las claves de `appsettings` se registran con valor `null` | Los IDs reales son pregunta abierta del PRD. `null` activa la ruta de degradación segura de RNF-04 (aviso claro y captura bloqueada) en lugar de arriesgar un ID inventado que guardaría datos incorrectos en silencio | La captura de Bridgestone queda bloqueada hasta que TI cargue los dos IDs por ambiente |
| Las claves **no** se agregaron a `appsettings.Development.json` | Ese archivo solo contiene *overrides* puntuales (logging y correos de prueba); duplicar ahí las mismas claves en `null` no aporta y agrega ruido. El shape queda documentado en `appsettings.json` | Se desvía de la letra de T-02, que pedía ambos archivos |
| La configuración se lee con el indexador de `IConfiguration` + `int.TryParse` | No obliga a verificar la referencia al paquete `Configuration.Binder` en `PaisesService` y valida que el ID sea un entero positivo | Un valor mal escrito se trata igual que uno ausente: degradación segura, no excepción |
| El bloqueo de los selectores se hace con `disabled`, no con un `readonly` cosmético | En el formulario de refacciones el POST lo arma el JS a mano y `jQuery.val()` lee campos deshabilitados, así que el valor sí viaja. `disabled` además los muestra evidentemente no editables (RNF-09) | En el formulario de presupuesto, que sí hace submit real, el `disabled` se acompaña de un `hidden` con el mismo nombre (RNF-03) |
| El select bloqueado de impuesto se renombra a `id_impuesto_fijo` y el `hidden` conserva `id_impuesto` | Evita dos elementos con el mismo `id` en el DOM. El JS que recalcula el presupuesto sigue leyendo `#id_impuesto` y encuentra el hidden con el valor correcto | RF-13 se sostiene también al recalcular |
| El error de configuración en `AssignBudget` se lanza como excepción | Es la única forma de **no escribir** un presupuesto con impuesto incorrecto sin reescribir el manejo de errores de la acción. El `catch` existente lo convierte en 404 | Camino que no debería ocurrir: la pantalla ya bloquea el botón y avisa antes. En `UpdateTax` el mismo caso sí devuelve el mensaje al usuario, porque su `catch` responde JSON |
| ~~La columna "M.O." de la tabla de refacciones se conserva mostrando `$0.00`~~ **Revertida el 2026-08-18 a petición del solicitante**: la tabla de refacciones oculta también **No. Parte** y **M.O.** en Bridgestone | No tiene sentido mostrar dos columnas que siempre salen vacías. Se ocultan en el render del servidor y en el rearmado por AJAX, que reconstruye la tabla tras cada registro | Commit `ddbf633`. BMW conserva No. Parte y sigue sin M.O.; los demás proyectos conservan ambas |
| No se tocó el comportamiento de acumulación de `AddSpareDealer` | Es código existente y el PRD no lo menciona (ver punto abierto abajo) | En Bridgestone toda captura cae en el mismo renglón "Llanta": suma cantidades y conserva el primer precio |

---

## Punto abierto detectado durante la ejecución

`AddSpareDealer` ya funcionaba así: si la avería **ya tiene** esa refacción, solo acumula `cantidad` y **no** actualiza el precio. Como en Bridgestone la refacción siempre es la misma, **todas las capturas caen en un único renglón**: si el taller registra dos llantas con precios distintos, la segunda captura suma la cantidad y conserva el precio de la primera.

No se modificó porque es comportamiento existente y el PRD no lo cubre. **Requiere confirmación de operación**: si una avería Bridgestone puede tener llantas con precios distintos, hace falta un ajuste adicional (renglones separados o actualización del precio), que es un cambio de alcance sobre código compartido con los demás proyectos.

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `PaisesService/Classes/ClaimBudgetRequirements.cs` | Modificado | T-01 |
| `GarantiplusWeb/appsettings.json` | Modificado | T-02 |
| `PaisesService/Classes/MX/PaisMX.cs` | Modificado | T-03 |
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | Modificado | T-04 a T-09 |
| `GarantiplusWeb/Areas/Averias/Views/Averias/_RefaccionesServiciosDealer.cshtml` | Modificado | T-10 |
| `GarantiplusWeb/Areas/Averias/Views/Averias/_PresupuestoDealer.cshtml` | Modificado | T-11 |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Edit.cshtml` | Modificado | T-12 |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `d45d01e` | [ECX-0164] Agregar regla de captura fija por proyecto para Bridgestone | 2026-08-18 |
| `724727b` | [ECX-0164] Forzar refaccion, impuesto y sin mano de obra en Bridgestone | 2026-08-18 |
| `aa51333` | [ECX-0164] Restringir la captura de la averia en pantalla para Bridgestone | 2026-08-18 |
| `ddbf633` | [ECX-0164] Ocultar No. Parte y M.O. en la tabla de refacciones de Bridgestone | 2026-08-18 |

---

## Notas de cierre

**Estado final:** plan cerrado. No queda código ni pruebas pendientes. La funcionalidad está en producción desde el 2026-08-20 y los dos IDs de catálogo están cargados en QA y en producción.

**Cómo verificar rápido que la regla está activa:** abrir una avería del proyecto 173 y confirmar que el bloque de refacción se ve al cargar, con Tipo y Refacción bloqueados. Si en su lugar aparece un `alert` rojo, la configuración de IDs falta o los IDs no existen en el catálogo del país; el detalle queda en el log con nivel `Error`.

**Contexto clave:**
- La regla se resuelve **por el proyecto de la avería**, no por el de la sesión, tanto en la vista como en las acciones POST (`GetBudgetRequirementsForClaimAsync`). Si los dos lados se separan, el formulario y el servidor dejan de coincidir.
- Las vistas reciben la **regla** (`ViewBag.UsesFixedSpare`), no el nombre del proyecto. Al agregar otro proyecto con la misma restricción, basta con resolverlo en `PaisMX`; las vistas no se tocan.
- Las mismas vistas las usan todos los proyectos, incluido BMW con su variante UAT. Toda la lógica nueva vive dentro de una condición y las ramas existentes quedaron intactas; la regresión de T-15 lo confirmó antes de liberar. Cualquier cambio futuro sobre estas vistas debe repetir esa regresión.

**Único punto abierto que sobrevive al cierre:** la acumulación de refacciones en un solo renglón (ver arriba). Es comportamiento existente y fuera del alcance de este plan; si operación confirma que una avería Bridgestone puede llevar llantas con precios distintos, requiere un ticket propio porque toca código compartido con los demás proyectos.

**Si los IDs de catálogo cambian en algún ambiente**, basta con actualizarlos en la configuración del despliegue (`Averias:Bridgestone:RefaccionLlantaId` e `Averias:Bridgestone:ImpuestoIvaCeroId`); no requiere recompilar.

---

*Actualizado automáticamente por Claude Code — Engine CX*
