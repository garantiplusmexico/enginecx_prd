# Registro de Avance — PoC white-label por hostname en SIGA

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/PJ9770-poc-white-label-hostname` |
| Responsable actual | Alejandro Govea Hernandez |
| Folio PRD | PJ9770 |
| ID plan (BD) | 68 |
| Última actualización | 2026-09-04 |
| Estado general | 🟡 En progreso (P1); P2 documentado, no ejecutado |
| Modelo | Claude Sonnet 5 — esfuerzo: normal |

---

## Resumen de estado

Rama `feature/PJ9770-poc-white-label-hostname` creada desde `develop`. Ejecución con **Claude Sonnet 5 / esfuerzo normal**. Los `appsettings` locales de conexión/país del desarrollador están en stash; no se mezclaron.

Fases 0, 1 y 2 commiteadas en `gp_4.0_siga`. Queda T-09 (`launchSettings.json`) sin commitear y T-10 (checklist P1). El 2026-09-04 el PRD pasó a **v0.2** (configuración por proyecto + correo con `id_proyecto` explícito; jobs sin id **no envían**). Fases 4–7 del PLAN pendientes; no ejecutar hasta que el programador lo pida. El intento de correo por host en PDF/Endosos se revirtió a propósito para redefinir en P2.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Modelo y resolución (P1)** | 246 | T-01 a T-03 | 0.5 – 1 | 2026-09-02 | 2026-09-02 | 0.5 | 0 | ✅ Completada |
| **Fase 1 — Login (P1)** | 247 | T-04 a T-06 | 1 – 1.5 | 2026-09-02 | 2026-09-02 | 0.5 | 0 | ✅ Completada |
| **Fase 2 — Chrome (P1)** | 248 | T-07 a T-08 | 0.5 – 1 | 2026-09-02 | 2026-09-02 | 0.5 | 0 | ✅ Completada |
| **Fase 3 — Verificación (P1)** | 249 | T-09 a T-10 | 0.5 – 1 | 2026-09-02 | | 0.2 | 0.8 | 🟡 En progreso |
| **Total proyecto (P1)** | — | 10 tareas | ~2.5 – 4.5 | 2026-09-02 | | 1.7 | 0.8 | 🟡 En progreso |
| **Solo P1 (guardarraíl del PRD)** | — | T-01 a T-10 | ~2.5 – 4.5 | 2026-09-02 | | 1.7 | 0.8 | 🟡 En progreso |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Definir opciones de branding | Claude Code | 2026-09-02 | `BrandingOptions` + `BrandDefinition` |
| T-02 | Resolver e `IBrandingContext` | Claude Code | 2026-09-02 | Host normalizado (lowercase, sin puerto) |
| T-03 | Configuración y DI | Claude Code | 2026-09-02 | Sección `Branding` + registro en `Program.cs`. Hub sin cambios. `ForwardedHeaders` ya incluye `XForwardedHost`. |
| T-04 | Banners por marca | Claude Code | 2026-09-02 | `banner.enginecx-ar.json` + `LoadSlides()` lee `Brand.BannersFile` |
| T-05 | Layout de login | Claude Code | 2026-09-02 | Title/favicon/logo desde `IBrandingContext`; Place to Pay COL no se tocó |
| T-06 | Footer de login EngineCX | Claude Code | 2026-09-02 | `_LoginFooterEnginecxAr.cshtml`; default sigue `_LoginFooter{CountryCode}` |
| T-07 | Top bar y menú | Claude Code | 2026-09-02 | `_TopNavBar` usa `HeaderLogoPath`. El layout actual (`_Layout` → Remake) no renderiza `logo_home.jpg`; `_LeftMenuBar_MEX` no tiene logo. No se tocó `_NavigationGPMX_*` (`_LayoutOld`). |
| T-08 | Home: no contradecir el chrome | Claude Code | 2026-09-02 | `Index` y `EcosistemaEngineCX`: en host EngineCX se sustituye `logo_interior.jpg` |
| T-09 | Doble host en desarrollo | Claude Code | 2026-09-02 | Perfil `WarrantiesEngineCX` con `launchUrl` `http://warranties.localhost:4006`. Requiere línea en `hosts`. |

---

## Tareas en progreso 🟡

| ID | Tarea | Responsable | Iniciada | Notas |
|---|---|---|---|---|
| T-10 | Checklist de verificación manual | Alejandro Govea Hernandez | 2026-09-02 | Falta recorrido en browser (login + chrome en ambos hosts). Requiere `hosts` + usuario SIGA. |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| | | |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| | | | |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| Footer EngineCX se llamará `_LoginFooterEnginecxAr` (no `_LoginFooterARG`) | Evita chocar con un futuro footer de país ARG del hub (`_LoginFooter{CountryCode}`) | Config `LoginFooterPartial` apunta a ese nombre |
| Marca default conserva el logo actual de login (`enginecx_logo.png`) | El login Garantiplus hoy ya usa ese archivo; no cambiar el look de `.mx` | Solo cambian title/favicon/banners/footer en host AR |
| No se tocó `ForwardedHeaders` | Ya tiene `XForwardedHost` y `KnownNetworks/Proxies` vacíos | PoC en prod debería ver el Host público si Nginx lo reenvía |
| `_NavigationGPMX_*` no se modifica | El layout autenticado actual es Remake (`_TopNavBar` + `_LeftMenuBar_{hub}`); `logo_home.jpg` solo está en el layout viejo | Menú lateral Remake no tenía isotipo Garantiplus que sustituir |
| Perfil `WarrantiesEngineCX` reutiliza el mismo `applicationUrl` (`127.0.0.1:4006`) | Evita bind duplicado de puerto; el Host lo resuelve `hosts` | Hay que agregar `127.0.0.1 warranties.localhost` (admin) |
| `EmailSettings` por marca (pedido en ejecución) | Argentina puede usar otro buzón Gmail sin cambiar el hub | `Username` vacío en `enginecx-ar` cae al `EmailSettings` global. Jobs Quartz siguen con el global (no hay Host). Asuntos/HTML con “Garantiplus” siguen fuera de alcance. |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea relacionada |
|---|---|---|
| `GarantiplusWeb/Options/BrandDefinition.cs` | Creado | T-01 |
| `GarantiplusWeb/Options/BrandingOptions.cs` | Creado | T-01 |
| `GarantiplusWeb/Services/Branding/IBrandingHostResolver.cs` | Creado | T-02 |
| `GarantiplusWeb/Services/Branding/BrandingHostResolver.cs` | Creado | T-02 |
| `GarantiplusWeb/Services/Branding/IBrandingContext.cs` | Creado | T-02 |
| `GarantiplusWeb/Services/Branding/BrandingContext.cs` | Creado | T-02 |
| `GarantiplusWeb/Program.cs` | Modificado | T-03 |
| `GarantiplusWeb/appsettings.json` | Modificado | T-03 (solo sección `Branding`; no se tocó connection string) |
| `GarantiplusWeb/banner.enginecx-ar.json` | Creado | T-04 |
| `GarantiplusWeb/Areas/Identity/Pages/Account/Login.cshtml.cs` | Modificado | T-04 / T-05 |
| `GarantiplusWeb/Areas/Identity/Pages/Account/Login.cshtml` | Modificado | T-05 |
| `GarantiplusWeb/Views/Shared/_LoginLayout.cshtml` | Modificado | T-05 / T-06 |
| `GarantiplusWeb/Views/Shared/_LoginFooterEnginecxAr.cshtml` | Creado | T-06 |
| `GarantiplusWeb/Views/Shared/Remake/_TopNavBar.cshtml` | Modificado | T-07 |
| `GarantiplusWeb/Views/Home/Index.cshtml` | Modificado | T-08 |
| `GarantiplusWeb/Views/Home/EcosistemaEngineCX.cshtml` | Modificado | T-08 |
| `GarantiplusWeb/Properties/launchSettings.json` | Modificado | T-09 |
| `GarantiplusWeb/Options/BrandEmailSettings.cs` | Creado | Extra (email por marca) |
| `GarantiplusWeb/Services/Branding/BrandEmailSettingsResolver.cs` | Creado | Extra (email por marca) |

---

## Commits realizados

| Hash | Mensaje | Fecha |
|---|---|---|
| `87e3e9b` | `[PJ9770-poc-white-label-hostname] Fase 0 - Modelo de marca y resolución por host` | 2026-09-02 |
| `f364caf` | `[PJ9770-poc-white-label-hostname] Fase 1 - Login white-label por marca` | 2026-09-02 |
| `8f5feea` | `[PJ9770-poc-white-label-hostname] Fase 2 - Chrome autenticado por marca` | 2026-09-02 |

---

## Notas para quien retome el trabajo

- **Commit por fase.** Fases 0 (`87e3e9b`), 1 (`f364caf`) y 2 (`8f5feea`) ya en remoto. Queda T-09 (`launchSettings`).
- Los `appsettings` locales de conexión/país del desarrollador están en stash; no mezclarlos ni commitear connection strings.
- Hosts: `127.0.0.1`/`localhost` → `garantiplus`; `warranties.localhost` → `enginecx-ar`. En Windows (admin): `127.0.0.1 warranties.localhost` en `C:\Windows\System32\drivers\etc\hosts`.
- T-10: levantar perfil `GarantiplusMX` y `WarrantiesEngineCX` (mismo puerto; el segundo abre `warranties.localhost:4006`). Verificar login + chrome; cambiar proyecto ARG/MEX no debe cambiar la marca.

---

*Actualizado automáticamente por Claude Code — Engine CX*
