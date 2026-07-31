# Archivos modificados — Feature Usuario Distribuidor-Taller (PJ4981)

| Campo | Detalle |
|---|---|
| Repositorio | `gp_4.0_siga` |
| Rama | `feature/PJ4981-usuario-distribuidor-taller` |
| Base | `develop` |
| Última actualización inventario | 2026-07-30 |

---

## 🆕 Archivos creados (3)

| Archivo | Rol en el feature |
|---|---|
| `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/rol_usuario_distribuidor_taller.sql` | Seed SQL del rol (GUID fijo `ead42fa6-dd6b-421b-8732-a3558691b234`) |
| `GarantiplusWeb/Helpers/RoleGroupExtensions.cs` | Helper: `ActsAsDistribuidor`, `ActsAsTaller`, `IsDistribuidorTaller` |
| `GarantiplusWeb/Helpers/CombinedRoleClaimsTransformation.cs` | Claims: otorga en runtime los roles base al rol combinado |

---

## ✏️ Archivos modificados — núcleo (2026-07-16)

| Archivo | Cambio |
|---|---|
| `GarantiplusWeb/Program.cs` | Registro de la `IClaimsTransformation` |
| `GarantiplusWeb/Controllers/GeneralController.cs` | Resolución de proyectos aditiva (unión) + fix ChangeProject |
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | Filtrado unión en listados y Details/Edit |
| `ArmadorasBusinessRules/ArmadorasGeneralBusinessRules.cs` | OR en `GetAllAverias` cuando llegan ambos scopes |
| `GarantiplusWeb/Areas/Catalogos/Controllers/UsuariosController.cs` | Rol en selector, combo taller, validación RF-07, include taller |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/_Edit.cshtml` | `is-visible` distribuidores/taller para el rol combinado |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/Details.cshtml` | Muestra el taller en la ficha |

---

## ✏️ Archivos modificados — paridad Averías / Taller (2026-07-29 / 30)

| Archivo | Cambio |
|---|---|
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | `ActsAsTaller`/`ActsAsDistribuidor`; Authorize con rol combinado; `canEditClaim` (no redirect a Details); filtro unión en Edit GET |
| `GarantiplusWeb/Areas/Averias/Controllers/TallerExternoController.cs` | `[Authorize(Roles = "Taller,Usuario Distribuidor-Taller")]` |
| `GarantiplusWeb/Areas/Averias/Views/Averias/_Edit.cshtml` | Paneles/acciones de taller con `ActsAsTaller()` |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Edit.cshtml` | Misma semántica `ActsAs*` |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Details.cshtml` | Misma semántica `ActsAs*` |
| `GarantiplusWeb/Areas/Averias/Views/Averias/Aprobacion.cshtml` | Misma semántica `ActsAs*` |
| `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_MEX.cshtml` | Averías + "Registrar avería" incluyen el rol combinado |
| `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_COL.cshtml` | Idem |
| `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_CHL.cshtml` | Idem |
| `GarantiplusWeb/Views/Shared/_NavigationGPMX.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_NavigationGPMX_MEX.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_NavigationGPMX_COL.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_NavigationGPMX_CHL.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_NavigationMitsu.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_NavigationAstara.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_TopNavbarMitsu.cshtml` | Legacy: `ActsAsTaller()` |
| `GarantiplusWeb/Views/Shared/_SeguimientoAveria.cshtml` | `ActsAsDistribuidor` / `ActsAsTaller` |
| `GarantiplusWeb/JsonStringLocalizer.cs` | Proyectos = unión distribuidor ∪ taller |
| `GarantiplusWeb/Areas/Contratos/Controllers/ContratosController.cs` | Authorize incluye `Usuario Distribuidor-Taller` donde había Taller |

---

## Notas

- Los `appsettings.json` con configuración local **no** forman parte del feature.
- `PLAN.md` / `AVANCE.md` / este archivo viven en `enginecx_prd`, no en el repo de código.
- Detalle de decisiones y estado: ver `AVANCE.md` (actualizado 2026-07-30).

---

## Commits de la rama (históricos)

| Hash | Mensaje |
|---|---|
| `59f32c8` | [PJ4981] Combo de taller muestra "id - nombre" para evitar ambiguedad |
| `972ccbc` | [PJ4981] Fix: ChangeProject sobrescribia proyectos de admin con lista vacia |
| `e384095` | [PJ4981] Rol Usuario Distribuidor-Taller: seed, permisos union y aislamiento |

*Generado / actualizado por Claude Code — Engine CX · 2026-07-30*
