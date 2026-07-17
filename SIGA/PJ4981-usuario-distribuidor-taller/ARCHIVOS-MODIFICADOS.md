# Archivos modificados — Feature Usuario Distribuidor-Taller (PJ4981)

| Campo | Detalle |
|---|---|
| Repositorio | `gp_4.0_siga` |
| Rama | `feature/PJ4981-usuario-distribuidor-taller` |
| Base | `develop` |
| Resumen | 10 archivos · 261 inserciones · 38 eliminaciones |

---

## 🆕 Archivos creados (3)

| Archivo | Rol en el feature |
|---|---|
| `GarantiplusWeb/BD/2026-07-15_rol_usuario_distribuidor_taller/rol_usuario_distribuidor_taller.sql` | Seed SQL del rol (GUID fijo `ead42fa6-dd6b-421b-8732-a3558691b234`) |
| `GarantiplusWeb/Helpers/RoleGroupExtensions.cs` | Helper: semántica del rol combinado (`ActsAsDistribuidor`, `ActsAsTaller`, `IsDistribuidorTaller`) |
| `GarantiplusWeb/Helpers/CombinedRoleClaimsTransformation.cs` | Transformación de claims: otorga en runtime los roles base al rol combinado |

---

## ✏️ Archivos modificados (7)

| Archivo | Cambio |
|---|---|
| `GarantiplusWeb/Program.cs` | Registro de la `IClaimsTransformation` |
| `GarantiplusWeb/Controllers/GeneralController.cs` | Resolución de proyectos aditiva (unión) + fix del cambio de proyecto |
| `GarantiplusWeb/Areas/Averias/Controllers/AveriasController.cs` | Filtrado unión (distribuidores + taller) en listados y Details/Edit |
| `ArmadorasBusinessRules/ArmadorasGeneralBusinessRules.cs` | OR en `GetAllAverias` cuando llegan ambos scopes |
| `GarantiplusWeb/Areas/Catalogos/Controllers/UsuariosController.cs` | Rol en selector, combo de taller poblado (`id - nombre`), validación RF-07, include de taller |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/_Edit.cshtml` | Visibilidad de campos distribuidores/taller para el rol combinado |
| `GarantiplusWeb/Areas/Catalogos/Views/Usuarios/Details.cshtml` | Muestra el taller en la ficha |

---

## Notas

- Los `appsettings.json` con configuración local **no** forman parte del feature (quedaron fuera a propósito).
- `PLAN.md` / `AVANCE.md` viven en este repo (`enginecx_prd`), no en el repo de código.
- El `CLAUDE.md` generado está en el raíz del repo de código, pero el `.gitignore` lo excluye (regla `*.md`), por lo que no aparece en el diff.

---

## Commits de la rama

| Hash | Mensaje |
|---|---|
| `59f32c8` | [PJ4981] Combo de taller muestra "id - nombre" para evitar ambiguedad |
| `972ccbc` | [PJ4981] Fix: ChangeProject sobrescribia proyectos de admin con lista vacia |
| `e384095` | [PJ4981] Rol Usuario Distribuidor-Taller: seed, permisos union y aislamiento |

*Generado por Claude Code — Engine CX · 2026-07-16*
