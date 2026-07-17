# Registro de Avance — Nuevo rol Usuario Distribuidor-Taller

> Este documento lo actualiza Claude Code conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ4981-usuario-distribuidor-taller` |
| Rama base | `develop` |
| Responsable actual | Alejandro Govea Hernández |
| Última actualización | 2026-07-16 |
| Estado general | 🟡 Core implementado y compilando — pendiente QA funcional con BD |

---

## Resumen de estado

Se implementó el rol combinado **Usuario Distribuidor-Taller** de punta a punta a nivel de código: alta del rol (seed SQL), alta/edición en el catálogo de usuarios con validación, **unión de permisos** (menús + `[Authorize]`) y **aislamiento de datos** (unión distribuidor + taller en averías y resolución de proyectos). **El proyecto compila (0 errores).**

**Decisión de arquitectura clave (ver sección de decisiones):** la unión de permisos NO se hizo editando 40 archivos uno por uno (enfoque quirúrgico del plan T-09/T-10). En su lugar se añadió una **transformación de claims** (`IClaimsTransformation`) que, **solo** para el rol combinado, le otorga en runtime los roles base "Usuario Distribuidor" y "Taller". Así, todos los `[Authorize]`, `profiles=` de menú y flags `IsInRole(...)` de scoping ya lo tratan como ambos roles. Esto es **más seguro** (cero regresión para roles existentes; sin riesgo de fuga por un check olvidado) y **más mantenible** (RNF-04).

Falta: **QA funcional contra BD** (T-15/T-16, no ejecutable aquí) y decidir/afinar puntos marcados abajo (precedencia de edición de averías; unión en reportes; países CO/CL).

---

## Tareas completadas ✅

| ID | Tarea | Fecha | Notas |
|---|---|---|---|
| T-01 | Nomenclatura + GUID fijo | 2026-07-15 | `Id=ead42fa6-dd6b-421b-8732-a3558691b234`, Name=`Usuario Distribuidor-Taller`, NormalizedName=`USUARIO DISTRIBUIDOR-TALLER` |
| T-02 | Seed SQL del rol | 2026-07-16 | `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/…sql`, idempotente, GUID fijo |
| T-03 | Rol en selector + poblar talleres | 2026-07-16 | Rol añadido al whitelist de Gestor de Países; `ViewBag.Talleres` ahora se puebla en `SetupViewBags` |
| T-04 | Visibilidad de campos | 2026-07-16 | GUID del rol añadido a `is-visible` de distribuidores y taller en `_Edit.cshtml` |
| T-05 | Validación obligatoria (RF-07) | 2026-07-16 | Server-side en Create/Edit POST (la validación cliente `#frmUsuarios` está muerta en la vista TagHelper) |
| T-06/T-07 | Persistencia de ligas | 2026-07-16 | **Sin cambios de código:** el flujo existente ya inserta `usuario_distribuidor` (else-if) + `usuario_taller` (if independiente). Verificado por lectura |
| T-08 | Ligas en lectura | 2026-07-16 | `Details` incluye `taller,taller.taller` y muestra el taller en la ficha |
| T-09/T-10 | Unión de permisos | 2026-07-16 | Resuelto vía transformación de claims (cubre menús MEX/COL/CHL y todos los `[Authorize]`) |
| T-11 | Helper de grupos de rol | 2026-07-16 | `RoleGroupExtensions` (ActsAsDistribuidor / ActsAsTaller / IsDistribuidorTaller) |
| T-12 | Resolución de proyectos combinada | 2026-07-16 | `GeneralController.ChangeProject`/`GetProjects` ahora ADITIVAS (unión). **Crítico:** sin esto el combinado no podía loguearse (NullRef) |
| T-13 | Filtrado en Averías | 2026-07-16 | Listados: `else if(Taller)`→`if`; Details/Edit: rama combinada OR; `GetAllAverias` (BR) aplica OR cuando llegan ambos scopes |

---

## Tareas en progreso / pendientes ⏳

| ID | Tarea | Estado |
|---|---|---|
| T-14 | Flags a otros consumidores | Parcial — cubierto por claims para la dimensión distribuidor (Contratos/OrdenesPago quedan correctamente scopeados, sin fuga). Ver "bloqueos/pendientes" para la dimensión taller en reportes |
| T-15 | Matriz de pruebas manual | 🔴 Pendiente — requiere app corriendo + BD (no ejecutable en esta sesión) |
| T-16 | Regresión de roles base | 🔴 Pendiente QA — el diseño (claims solo para el rol nuevo) hace improbable la regresión, pero debe verificarse |

---

## Tareas / puntos que requieren decisión o QA 🔴

| Tema | Detalle | Quién resuelve |
|---|---|---|
| Precedencia edición de averías | En `Averias/Edit` (AveriasController ~1597), un "Usuario Distribuidor" es redirigido a `Details`. Como el combinado también es distribuidor (vía claims), se redirige a Details en vez de usar la edición del taller. Es la "prioridad de opciones en conflicto" que el PRD §14 dejó abierta | Producto / Alexis |
| Unión en reportes | `Areas/Reportes/.../ExplotacionController` y otros reportes filtran por `usuario_distribuidor` con SQL crudo. Con claims el combinado se scopea por distribuidor (sin fuga), pero podría no incluir la dimensión taller. Revisar si los reportes deben unir taller | Dev + QA |
| Países CO/CL | Este trabajo se hizo para México. Para liberar CO/CL: ejecutar el seed en esas BD (`DataAccessColombia`). Los menús `_COL`/`_CHL` y `[Authorize]` ya quedan cubiertos por la transformación de claims (usan los mismos nombres de rol) | Dev |
| Seed en ambientes | Ejecutar `rol_usuario_distribuidor_taller.sql` en dev/QA/prod con el **GUID fijo** (necesario para que el `is-visible` por GUID del formulario funcione) | Dev/DBA |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| **Unión de permisos vía `IClaimsTransformation`** en lugar de editar cada menú/`[Authorize]`/flag (plan T-09/T-10) | (1) Seguridad: sólo se activa para el rol nuevo → cero regresión para roles existentes y sin riesgo de fuga por un check olvidado. (2) Mantenibilidad (RNF-04): un solo punto en vez de ~40 archivos. (3) Cubre también CO/CL sin tocar sus menús | Cambio central en `Program.cs` + clase nueva. El combinado hereda en runtime los roles "Usuario Distribuidor" y "Taller" |
| Unión de averías en el BR **sin cambiar la firma** de `GetAllAverias` | Cuando llegan a la vez `distribuidores` (no vacío) y `usuariotaller`, se aplica OR. Los roles base nunca envían ambos, así que no se afectan | Evita tocar todos los call-sites del BR |
| Validación RF-07 **en servidor** | La validación jQuery de `Create.cshtml` apunta a `#frmUsuarios`, que ya no existe en la vista TagHelper `data-form` (está en el bloque legacy comentado) | Garantía real de RF-07 aunque el cliente no valide |
| `ViewBag.Talleres` poblado en `SetupViewBags` | En la vista TagHelper el combo dependía de un AJAX que vivía en el JS legacy comentado → quedaba vacío | El combo de taller ahora funciona server-side |

---

## Archivos creados o modificados

| Archivo | Tipo | Tarea |
|---|---|---|
| `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/rol_usuario_distribuidor_taller.sql` | Creado | T-02 |
| `GarantiplusWeb/Helpers/RoleGroupExtensions.cs` | Creado | T-11 |
| `GarantiplusWeb/Helpers/CombinedRoleClaimsTransformation.cs` | Creado | T-09/T-10 |
| `GarantiplusWeb/Program.cs` | Modificado | Registro de la transformación de claims |
| `GarantiplusWeb/Controllers/GeneralController.cs` | Modificado | T-12 (resolución de proyectos aditiva) |
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | Modificado | T-13 (listados + Details/Edit unión) |
| `ArmadorasBusinessRules/ArmadorasGeneralBusinessRules.cs` | Modificado | T-13 (OR en `GetAllAverias`) |
| `GarantiplusWeb/Areas/Catalogos/Controllers/UsuariosController.cs` | Modificado | T-03/T-05/T-08 |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/_Edit.cshtml` | Modificado | T-04 |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/Details.cshtml` | Modificado | T-08 |

Nota: no se commitean los `appsettings.json` modificados localmente (config de entorno).

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| (ver git log) | `[PJ4981] Rol Usuario Distribuidor-Taller: seed, permisos, aislamiento y catálogo` | 2026-07-16 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** QA funcional con BD (crear un usuario combinado, ligar N distribuidores + 1 taller, loguearse, verificar menú/acciones = unión y datos = solo lo ligado). Ejecutar primero el **seed** con el GUID fijo.
- **Contexto clave:** el rol hereda la unión de permisos mediante la transformación de claims (`CombinedRoleClaimsTransformation`). Para la unión de **datos** (ver averías de distribuidores + taller) se tocó explícitamente `GeneralController`, `AveriasController` y el BR `GetAllAverias`. El helper `RoleGroupExtensions` centraliza la semántica.
- **Decisiones pendientes (input de negocio):** precedencia de edición de averías (distribuidor vs taller) y si los reportes deben unir la dimensión taller. Ver PRD §14.
- **Build:** `dotnet build GarantiplusWeb/GarantiplusWeb.csproj` → 0 errores (2026-07-16).

---

*Actualizado por Claude Code — Engine CX*
