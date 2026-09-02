# Plan de Desarrollo — PoC white-label por hostname en SIGA

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ9770-poc-white-label-hostname/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ9770-poc-white-label-hostname` |
| Tipo | Feature / PoC sobre proyecto existente |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | PJ9770 |
| Fecha de generación | 2026-09-02 |
| Estado | Borrador |
| Modelo | Claude Opus 4.8 — esfuerzo normal |
| ID plan (BD) | 68 |

> **Rama local ya existente:** `feature/ag_siga_multibranding_prueba_concepto` (sin commits propios vs `develop`; solo `appsettings` locales). Al ejecutar el plan, crear/renombrar a `feature/PJ9770-poc-white-label-hostname` desde `develop` actualizado. No mezclar los cambios locales de conexión/país en el PR.

---

## 1. Resumen técnico

Se agrega un **contexto de marca por request** en GarantiplusWeb. El hostname (`Request.Host`) se mapea a una definición en `appsettings` (`Branding`). Las vistas de login y el chrome autenticado leen ese contexto en lugar de hardcodear Garantiplus o de usar `_hub.BaseCountry` (que en esta instancia es siempre `MEX`).

- **Arquitectura:** se mantiene el monolito SIGA Web en EC2 (`rules/arquitectura.md` §3 y §5). No hay microservicio nuevo ni cambio de hub.
- **Stack:** .NET 8 / C#, Razor Pages + MVC, JSON de banners, sin PostgreSQL nuevo.
- **BD:** sin cambios.
- **Código nuevo en inglés**; textos de UI en español.

El login hoy hace:

```
ViewData["CountryCode"] = _hub.BaseCountry.CountryCode;  // siempre MEX
LoadSlides() ← banner.json único
Layout: title "Garantiplus", favicon garantiplus.mx, _LoginFooter{CountryCode}
```

La PoC inserta una capa `IBrandingContext` **antes** de esas decisiones de UI, sin alterar `IPaisBaseHub`.

```
Request.Host → BrandingHostResolver → BrandingOptions
                                      → IBrandingContext (scoped)
                                      → Login + Layout + TopNav + menú
```

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] `CLAUDE.md` presente en el repositorio (existe)
- [ ] Rama `develop` actualizada al crear la rama funcional
- [ ] Assets de PoC: como mínimo reutilizar `~/Images/enginecx_logo.png` (ya referenciado en `_LoginLayout.cshtml`); banners EngineCX placeholder o los que entregue diseño
- [ ] Poder resolver en local un segundo hostname (archivo `hosts` o `launchSettings` con `warranties.localhost`)
- [ ] No se requieren secrets nuevos ni DNS de producción para desarrollar la PoC

---

## 3. Arquitectura del cambio

No se introduce un segundo deploy ni se cambia el hub. La marca es un **concern de presentación + config**, distinto de país (ARG) y de hub (MEX).

```
[navegador]
   Host: warranties.enginecx.com.ar     Host: intranet.garantiplus.mx
              \                              /
               \                            /
            [GarantiplusWeb — misma instancia, Hub=MEX]
                         |
                         v
              BrandingHostResolver
                         |
            +------------+------------+
            | enginecx-ar             | garantiplus (default)
            | banners propios         | banner.json actual
            | _LoginFooterARG         | _LoginFooterMEX
            | logos EngineCX          | logos Garantiplus
            +-------------------------+
                         |
              [resto SIGA: proyectos, PaisAR, BD MX]
```

**Por qué no Option B (segunda instancia / hub ARG):** ARG ya es país hosted con `PaisAR` y `Resources/ARG.json`. Convertirlo en hub implica `CountryBase`, jobs, correo y posiblemente BD; no hace falta para probar identidad visual.

**Forwarded headers:** en EC2 detrás de Nginx, `Request.Host` debe ser el Host público. Si hoy Nginx reescribe al interno, la T-03 documenta el check; no se asume cambio de infra en la PoC.

---

## 4. Tareas de desarrollo

### Fase 0 — Modelo de marca y resolución por host

- [ ] **T-01** — Definir opciones de branding
  - Archivos a crear: `GarantiplusWeb/Options/BrandingOptions.cs`, `GarantiplusWeb/Options/BrandDefinition.cs`
  - Criterio de completitud: clases bindeables desde sección `"Branding"`: `DefaultBrandKey`, diccionario `Hosts` (hostname → brand key), diccionario `Brands` (`AppName`, `CompanyName`, `LogoPath`, `FaviconPath`, `BannersFile`, `LoginFooterPartial`, `HeaderLogoPath`, `NavLogoPath`, `ExternalSiteUrl`). Código en inglés. Máximo ~200 líneas por archivo.

- [ ] **T-02** — Resolver e `IBrandingContext`
  - Archivos a crear: `GarantiplusWeb/Services/Branding/IBrandingContext.cs`, `BrandingContext.cs`, `IBrandingHostResolver.cs`, `BrandingHostResolver.cs`
  - Criterio de completitud: el resolver normaliza host (lowercase, sin puerto). Match exacto contra `Hosts`. Si no hay match → `DefaultBrandKey`. Contexto scoped con `BrandKey`, `Brand` (`BrandDefinition`) y `Is(string brandKey)`. Sin I/O de BD.

- [ ] **T-03** — Configuración y DI
  - Archivos a modificar: `GarantiplusWeb/appsettings.json`, `GarantiplusWeb/Program.cs`
  - Criterio de completitud: sección `Branding` con hosts `intranet.garantiplus.mx` → `garantiplus`, `warranties.enginecx.com.ar` → `enginecx-ar`, más hosts locales de T-12. `AddOptions<BrandingOptions>().Bind(...)`. `IBrandingHostResolver` y `IBrandingContext` registrados. Hub **no** se modifica.

### Fase 1 — Login white-label (P1)

- [ ] **T-04** — Banners por marca
  - Archivos a crear: `GarantiplusWeb/banner.enginecx-ar.json`
  - Archivos a modificar: `GarantiplusWeb/Areas/Identity/Pages/Account/Login.cshtml.cs`
  - Criterio de completitud: `LoadSlides()` lee `Brand.BannersFile` (fallback `banner.json`). El JSON EngineCX no incluye slides con alt/link de marcas Garantiplus / GPlus / Invarat; usa EngineCX (placeholder de imagen permitido). `banner.json` actual se deja para la marca default.

- [ ] **T-05** — Layout de login
  - Archivos a modificar: `GarantiplusWeb/Views/Shared/_LoginLayout.cshtml`, `GarantiplusWeb/Areas/Identity/Pages/Account/Login.cshtml`
  - Criterio de completitud: `<title>`, favicon, logo superior y H1 salen de `IBrandingContext` (inyectar en la vista). Host EngineCX no muestra “Garantiplus” en title ni isotipo Garantiplus. Host default conserva título/favicon/logo actuales. El bloque Place to Pay de Colombia (`CountryCode == COL`) no se toca: esa instancia es hub MEX.

- [ ] **T-06** — Footer de login EngineCX
  - Archivos a crear: `GarantiplusWeb/Views/Shared/_LoginFooterARG.cshtml` (nombre alineado a `LoginFooterPartial` de config; puede llamarse `_LoginFooterEnginecxAr.cshtml` si se prefiere no chocar con un futuro footer de país ARG del hub)
  - Archivos a modificar: `GarantiplusWeb/Views/Shared/_LoginLayout.cshtml` (elige partial por branding, **no** por `_hub.BaseCountry`)
  - Criterio de completitud: en host EngineCX el footer **no** carga aviso ARCO mexicano, domicilio CDMX, ni `garantiplus.mx`. Placeholder: nombre EngineCX, enlace `enginecx.com`, leyenda de que los textos legales definitivos están pendientes. En host default se sigue resolviendo `_LoginFooter{CountryCode}` como hoy (`MEX`).

### Fase 2 — Chrome autenticado (P1)

- [ ] **T-07** — Top bar y menú
  - Archivos a modificar: `GarantiplusWeb/Views/Shared/Remake/_TopNavBar.cshtml`; el partial de navegación que usa `logo_home.jpg` (p. ej. `Remake/_LeftMenuBar_mex.cshtml` y/o `_NavigationGPMX.cshtml` — el que realmente renderiza el layout actual)
  - Criterio de completitud: con host EngineCX, `garantiplus-logo-02.svg` y `logo_home.jpg` se sustituyen por `HeaderLogoPath` / `NavLogoPath`. Con host Garantiplus, sin cambio visual. No se crea un `_Layout` nuevo tipo Mitsubishi.

- [ ] **T-08** — Home: no contradecir el chrome
  - Archivos a modificar: `GarantiplusWeb/Views/Home/Index.cshtml`, `GarantiplusWeb/Views/Home/EcosistemaEngineCX.cshtml` **solo si** en host EngineCX todavía muestran `logo_interior.jpg` (Garantiplus) junto al título “Warranties EngineCX”
  - Criterio de completitud: en host EngineCX el encabezado del home no mezcla isotipo Garantiplus. No se amplia el `if (pais == Argentina)` a correos ni PDFs. Si el título ya dice EngineCX por localizer de proyecto ARG, se deja; el logo sí debe respetar branding de host.

### Fase 3 — Verificación local (P1)

- [ ] **T-09** — Doble host en desarrollo
  - Archivos a modificar: `GarantiplusWeb/Properties/launchSettings.json`; `GarantiplusWeb/appsettings.json` (hosts `127.0.0.1`, `localhost`, `warranties.localhost` u otro acordado)
  - Criterio de completitud: documentado en §12 cómo levantar dos URLs contra la misma app. Un hostname dispara `enginecx-ar` y el otro `garantiplus` sin recompilar.

- [ ] **T-10** — Checklist de verificación manual
  - Archivos: ninguno de producto (evidencia en ejecución / `AVANCE.md`)
  - Criterio de completitud: recorrido anotado: (1) host GP → login idéntico a hoy; (2) host EngineCX → login sin Garantiplus; (3) login real en ambos y chrome coherente; (4) cambio de proyecto a ARG/MEX **no** cambia la marca de esta PoC (solo el host). No hay suite de tests en el repo; la verificación es manual en browser.

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | Ninguno | La marca se configura en `appsettings`. Sin migraciones. |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | — | No hay API nueva. El login Identity (`/Identity/Account/Login`) no cambia de ruta; solo de vista. | — |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Branding:DefaultBrandKey` | Marca si el host no está en el mapa (`garantiplus`) | Todos |
| `Branding:Hosts` | Mapa hostname → brand key | Todos (valores distintos QA/Prod) |
| `Branding:Brands:{key}:*` | Rutas de logo, favicon, JSON de banners, partial de footer | Todos |
| Hosts locales sugeridos | `localhost` / `127.0.0.1` → `garantiplus`; `warranties.localhost` → `enginecx-ar` | Desarrollo |

No hay secrets. Hosts de producción conocidos: `intranet.garantiplus.mx`, `warranties.enginecx.com.ar`. Host de QA: pregunta abierta del PRD.

---

## 8. Consideraciones de seguridad

- No hay endpoints nuevos ni cambios de `[Authorize]`.
- El Host es un dato controlado por el cliente (o el proxy). **No** se usa para autorización ni para elegir BD/hub: solo assets y copy. Un Host falso solo cambia cosmética, no datos.
- No introducir un override tipo `?brand=` en producción (evita spoofing visual en demos compartidas). Si se necesita para QA, limitar a `Development`.
- Cookies siguen scoped al dominio; no compartir sesión entre `.mx` y `.com.ar`.
- Textos legales placeholder no deben fingir ser el aviso definitivo de Argentina.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- **Sin servicios AWS nuevos.** SIGA Web sigue en EC2 + Nginx.
- DNS y certificado de `warranties.enginecx.com.ar` ya existen (ambas URLs apuntan a la misma app).
- Verificar en el Nginx de esa instancia que el `Host` original llega a Kestrel (si no, el mapa de hosts no disparará `enginecx-ar` en prod). Eso es un check, no un ticket de infra nuevo, salvo que haya que añadir `X-Forwarded-Host`.
- No se pide segundo ECS ni segundo `appsettings` de hub.

---

## 10. Criterios de aceptación

- [ ] En `warranties.enginecx.com.ar` (o host local equivalente) el login no muestra la palabra “Garantiplus” ni su isotipo; usa título/logo/banners/footer EngineCX.
- [ ] En `intranet.garantiplus.mx` (o host local default) el login y el chrome son visualmente los de hoy.
- [ ] Tras autenticarse por el host EngineCX, top bar y menú no muestran logo Garantiplus.
- [ ] `Hub:HubBaseCountryCode` sigue `MEX`; ARG sigue en `HostedCountryCodes`.
- [ ] No hay cambios de esquema PostgreSQL ni de `CountryBase`.
- [ ] Hosts y assets salen de `appsettings`, no de `if (Request.Host == "...")` dispersos en vistas.
- [ ] El código nuevo (clases/métodos) está en inglés.
- [ ] Verificación manual T-10 ejecutada en los dos hosts.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Nginx no reenvía el Host público | Media | Alto (PoC funciona en local y falla en prod) | T-03/T-09: loguear `Request.Host` una vez; ajustar forwarded headers solo si hace falta |
| Assets EngineCX no entregados | Media | Medio | Placeholder `enginecx_logo.png` + banners locales; no bloquear código |
| Alcance se infla a correos/PDFs/`PJ9766` | Alta | Alto | Guardarraíl P1 = Fase 0+1+2+3 de este plan; correo/PDF fuera |
| `if (pais == Argentina)` en home choca con marca-por-host | Media | Medio | T-08: host manda sobre el logo; no ampliar ifs de país |
| Rama local `ag_siga_multibranding_*` + appsettings de país | Media | Bajo | Rama nueva desde `develop`; no commitear connection strings locales |

---

## 12. Notas para el programador

1. **No usar `siga-cambio-pais-base`.** Eso cambia BD/hub/correo MX↔CO↔CL, no la marca.
2. **No hacer ARG hub** para esta PoC.
3. Relación con **PJ9766**: el `IBrandingContext` es el runtime; el catálogo admin de PJ9766 podría más adelante llenar las mismas `BrandDefinition`. No diseñar ese admin aquí.
4. El layout de login hoy hace `@await Html.PartialAsync($"_LoginFooter{ViewData["CountryCode"]}")`. Hay `_LoginFooterMEX|COL|CHL` y un `_LoginFooter.cshtml` genérico. La PoC debe ramificar **primero** por branding y, para Garantiplus, conservar el footer por país de hub.
5. `Login.cshtml.cs` carga `banner.json` del working directory (`File.ReadAllText("banner.json")`). El archivo de marca debe resolverse igual (raíz del content root), no desde `wwwroot`, salvo que se decida mover ambos — no mover `banner.json` en esta PoC.
6. **Prueba local sugerida:** en `launchSettings` añadir `http://warranties.localhost:4006` y en `C:\Windows\System32\drivers\etc\hosts` la línea `127.0.0.1 warranties.localhost`. El perfil actual ya usa `http://127.0.0.1:4006`.
7. Código existente: no refactorizar Identity, hub ni localizer. Solo extraer lo mínimo para leer branding.
8. Al crear la rama: `git checkout develop && git pull origin develop && git checkout -b feature/PJ9770-poc-white-label-hostname`.
9. No commitear `appsettings.json` con connection strings ni passwords de la máquina local.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles**. PoC acotada; no hay fecha límite contractual (el PRD padre PJ9766 tampoco la fija). Un desarrollador.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Modelo y resolución (P1)** | Options, resolver, DI, appsettings | T-01 a T-03 | 0.5 – 1 día | 246 |
| **Fase 1 — Login (P1)** | Banners, layout, footer ARG | T-04 a T-06 | 1 – 1.5 días | 247 |
| **Fase 2 — Chrome (P1)** | Top bar, menú, home logo | T-07 a T-08 | 0.5 – 1 día | 248 |
| **Fase 3 — Verificación (P1)** | Dual host local + checklist | T-09 a T-10 | 0.5 – 1 día | 249 |
| **Total proyecto (P1)** | PoC completa de opción A (login + chrome) | 10 tareas | **~2.5 – 4.5 días hábiles (≈ 1 semana)** | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + 1 + 2 + 3 (todo el alcance de este PRD) | T-01 a T-10 | **~2.5 – 4.5 días hábiles** | — |

> En esta PoC **no hay P2/P3**. Correos, PDFs, catálogo admin y marca-por-país-de-proyecto quedan fuera y, si se retoman, deben ir a `PJ9766` o a un PRD de evolución.

> **Riesgo de deadline:** no hay fecha límite en el PRD. El rango cabe en una semana hábil de un desarrollador. Si se pide “cero Garantiplus” también en correos/PDFs, **no comprimir este plan**: abrir alcance nuevo. Un segundo desarrollador no reduce materialmente (el trabajo es secuencial sobre las mismas vistas).

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 — esfuerzo: normal*
