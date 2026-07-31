# Registro de Avance — Nuevo rol Usuario Distribuidor-Taller

> Este documento lo actualiza Claude Code conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ4981-usuario-distribuidor-taller` |
| Rama base | `develop` |
| Responsable actual | Alejandro Govea Hernández |
| Última actualización | 2026-07-30 |
| Estado general | 🟡 Core + paridad Averías/Taller implementados — pendiente QA formal T-15/T-16 |

---

## Resumen de estado

Se implementó el rol combinado **Usuario Distribuidor-Taller** de punta a punta a nivel de código: alta del rol (seed SQL), alta/edición en el catálogo de usuarios con validación, **unión de permisos** (claims + refuerzo explícito en Averías/menús) y **aislamiento de datos** (unión distribuidor + taller). **El proyecto compila (0 errores).**

**Decisión de arquitectura clave (ver sección de decisiones):** la unión de permisos se resolvió con una **transformación de claims** (`IClaimsTransformation`) que, **solo** para el rol combinado, otorga en runtime los roles base "Usuario Distribuidor" y "Taller". Complemento (2026-07-29/30): paridad explícita en Averías con `ActsAsTaller()` / `ActsAsDistribuidor()`, menús y `[Authorize]`, y **precedencia de edición = taller** (el combinado permanece en `Edit`, no en `Details`).

Falta: **QA formal T-15/T-16**, unión en reportes (revisar), seed en ambientes, y liberación CO/CL si aplica.

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
| T-09/T-10 | Unión de permisos | 2026-07-16 / 2026-07-30 | Claims transform + refuerzo: menús Averías MEX/COL/CHL, navegación legacy, `[Authorize]` Averías/`TallerExterno`/`Contratos`, vistas Averías con `ActsAsTaller()` |
| T-11 | Helper de grupos de rol | 2026-07-16 | `RoleGroupExtensions` (`ActsAsDistribuidor` / `ActsAsTaller` / `IsDistribuidorTaller`) |
| T-12 | Resolución de proyectos combinada | 2026-07-16 / 2026-07-30 | `GeneralController` aditiva; `JsonStringLocalizer` también une proyectos distribuidor ∪ taller |
| T-13 | Filtrado en Averías | 2026-07-16 / 2026-07-30 | Listados/Details/Edit con unión; GET/POST `Edit` usa `canEditClaim` vía `ActsAsTaller()` (paridad UI con Taller) |

---

## Tareas en progreso / pendientes ⏳

| ID | Tarea | Estado |
|---|---|---|
| T-14 | Flags a otros consumidores | Parcial — claims + helpers cubren Averías/proyectos; reportes con SQL por `usuario_distribuidor` pendientes de revisar dimensión taller |
| T-15 | Matriz de pruebas manual | 🟡 En curso informal (registro/Edit con usuario combinado) — falta checklist formal |
| T-16 | Regresión de roles base | 🔴 Pendiente QA — el diseño (claims solo para el rol nuevo + `ActsAs*`) hace improbable la regresión, pero debe verificarse |

---

## Tareas / puntos que requieren decisión o QA 🔴

| Tema | Detalle | Quién resuelve |
|---|---|---|
| ~~Precedencia edición de averías~~ | **Resuelto 2026-07-30.** El combinado se queda en `Averias/Edit` (misma UX que Taller) cuando `ActsAsTaller()`. Ya no se redirige a `Details` por ser también distribuidor vía claims. | — |
| Unión en reportes | `Areas/Reportes/.../ExplotacionController` y otros reportes filtran por `usuario_distribuidor` con SQL crudo. Con claims el combinado se scopea por distribuidor (sin fuga), pero podría no incluir la dimensión taller. Revisar si los reportes deben unir taller | Dev + QA |
| Países CO/CL | Seed del rol en BD CO/CL si se liberan. Menús `_COL`/`_CHL` ya incluyen el rol en Averías (refuerzo 2026-07-30) además de claims | Dev |
| Seed en ambientes | Ejecutar `rol_usuario_distribuidor_taller.sql` en dev/QA/prod con el **GUID fijo** (necesario para `is-visible` por GUID) | Dev/DBA |
| Datos de prueba Averías | Para `TallerExterno/Registro`, el usuario combinado debe tener `usuario_taller` + `proyecto_taller` del proyecto actual; sin eso `ClaimValidator` responde "Usuario no válido para el proyecto seleccionado" | QA / datos |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| **Unión de permisos vía `IClaimsTransformation`** (plan T-09/T-10) | (1) Seguridad: sólo se activa para el rol nuevo. (2) Mantenibilidad (RNF-04). (3) Cubre CO/CL vía mismos nombres de rol | `Program.cs` + `CombinedRoleClaimsTransformation` |
| **Precedencia Edit Averías = Taller** (2026-07-30) | Con claims, el combinado también era "Usuario Distribuidor" y el GET/POST `Edit` lo mandaba a `Details` (solo lectura). Producto requiere **mismas funcionalidades de taller** al ver/operar una avería | `canEditClaim = ActsAsTaller() \|\| Tecnico \|\| Coordinador \|\| Agencia`; el combinado permanece en `Edit` |
| **Refuerzo explícito Averías/menús** (además de claims) | Garantiza menú "Registrar avería", paneles de `_Edit.cshtml` y `[Authorize]` de `TallerExterno` aunque falle o se quite la transformación | Menús Remake + vistas Averías + controllers |
| Unión de averías en el BR **sin cambiar la firma** de `GetAllAverias` | Cuando llegan `distribuidores` y `usuariotaller`, se aplica OR | Evita tocar todos los call-sites del BR |
| Validación RF-07 **en servidor** | La validación jQuery legacy apunta a `#frmUsuarios` inexistente en TagHelper | Garantía real de RF-07 |
| `ViewBag.Talleres` poblado en `SetupViewBags` | El AJAX del combo vivía en JS legacy comentado | Combo de taller server-side |

---

## Archivos creados o modificados

### Núcleo (2026-07-15 / 16)

| Archivo | Tipo | Tarea |
|---|---|---|
| `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/rol_usuario_distribuidor_taller.sql` | Creado | T-02 |
| `GarantiplusWeb/Helpers/RoleGroupExtensions.cs` | Creado | T-11 |
| `GarantiplusWeb/Helpers/CombinedRoleClaimsTransformation.cs` | Creado | T-09/T-10 |
| `GarantiplusWeb/Program.cs` | Modificado | Registro de la transformación de claims |
| `GarantiplusWeb/Controllers/GeneralController.cs` | Modificado | T-12 |
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | Modificado | T-13 |
| `ArmadorasBusinessRules/ArmadorasGeneralBusinessRules.cs` | Modificado | T-13 |
| `GarantiplusWeb/Areas/Catalogos/Controllers/UsuariosController.cs` | Modificado | T-03/T-05/T-08 |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/_Edit.cshtml` | Modificado | T-04 |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/Details.cshtml` | Modificado | T-08 |

### Paridad Averías / Taller (2026-07-29 / 30)

| Archivo | Tipo | Tarea |
|---|---|---|
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | Modificado | T-10/T-13 — `ActsAsTaller`/`ActsAsDistribuidor`, Authorize, `canEditClaim`, filtro unión en Edit |
| `GarantiplusWeb/Areas/Averias/Controllers/TallerExternoController.cs` | Modificado | T-10 — Authorize incluye `Usuario Distribuidor-Taller` |
| `GarantiplusWeb/Areas/Averias/Views/Averias/_Edit.cshtml` | Modificado | T-10 — paneles de taller vía `ActsAsTaller()` |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Edit.cshtml` | Modificado | T-10 |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Details.cshtml` | Modificado | T-10 |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Aprobacion.cshtml` | Modificado | T-10 |
| `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_MEX.cshtml` | Modificado | T-09 — Averías + Registrar avería |
| `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_COL.cshtml` | Modificado | T-09 |
| `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_CHL.cshtml` | Modificado | T-09 |
| `GarantiplusWeb/Views/Shared/_NavigationGPMX*.cshtml` / `_NavigationMitsu` / `_NavigationAstara` / `_TopNavbarMitsu` | Modificado | T-09 — legacy `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_SeguimientoAveria.cshtml` | Modificado | T-10 |
| `GarantiplusWeb/JsonStringLocalizer.cs` | Modificado | T-12 — proyectos unión |
| `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs` | Modificado | T-10 — Authorize con rol combinado donde había Taller |

Nota: no se commitean los `appsettings.json` modificados localmente (config de entorno).

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| (ver git log) | `[PJ4981] Rol Usuario Distribuidor-Taller: seed, permisos, aislamiento y catálogo` | 2026-07-16 |
| (pendiente) | Cambios Averías paridad Taller + documentación avance | 2026-07-30 |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** completar checklist T-15/T-16; revisar reportes (unión taller); seed en ambientes.
- **Contexto clave:** permisos = claims transform + refuerzo explícito en Averías. Datos = unión en `GeneralController`, `AveriasController`, `JsonStringLocalizer` y BR `GetAllAverias`. Semántica = `RoleGroupExtensions`.
- **Precedencia Edit:** resuelta — combinado edita como Taller (`Edit`), no solo lectura (`Details`).
- **Registro externo:** requiere liga `usuario_taller` + `proyecto_taller` del proyecto en sesión.
- **Build:** `dotnet build GarantiplusWeb/GarantiplusWeb.csproj` → 0 errores (verificado 2026-07-29).

---

*Actualizado por Claude Code — Engine CX · 2026-07-30*
