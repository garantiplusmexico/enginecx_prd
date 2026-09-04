# Plan de Desarrollo — White-label por hostname y configuración por proyecto en SIGA

> Generado a partir del PRD v0.2. P1 (Fases 0–3) ya ejecutada en código. P2 (Fases 4–7) es el alcance nuevo.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ9770-poc-white-label-hostname/PRD.md` (v0.2) |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb; PDFGenerator y Endosos en correo P2) |
| Rama base | `develop` |
| Rama | `feature/PJ9770-poc-white-label-hostname` |
| Tipo | Feature / PoC sobre proyecto existente |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | PJ9770 |
| Fecha de generación | 2026-09-02; ampliación P2 2026-09-04 |
| Estado | P1 en verificación; P2 pendiente de ejecutar |
| Modelo | Claude Opus 4.8 — esfuerzo normal |
| ID plan (BD) | 68 |

> **Rama local ya existente:** `feature/ag_siga_multibranding_prueba_concepto` (sin commits propios vs `develop`; solo `appsettings` locales). Al ejecutar el plan, crear/renombrar a `feature/PJ9770-poc-white-label-hostname` desde `develop` actualizado. No mezclar los cambios locales de conexión/país en el PR.

---

## 1. Resumen técnico

**P1:** contexto de marca por request a partir del Host (`Branding` en `appsettings`) → login.

**P2:** overlay por `id_proyecto` de sesión (`proyecto_configuracion` + archivos en disco). Chrome autenticado y correo usan esa fila. Sin fila visual → host. Sin `id_proyecto` explícito en un envío → **no se manda correo**.

- **Arquitectura:** monolito SIGA Web en EC2. PDFGenerator y Endosos siguen procesos gRPC; P2 les pasa `id_proyecto` cuando el flujo tiene contrato/proyecto.
- **Stack:** .NET 8 / C#, Razor, EF Core, PostgreSQL (tabla nueva).
- **BD:** tabla `proyecto_configuracion` en MX y CO.
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

**P2 — overlay (tras login):**

```
Session [_IdProyecto]  →  proyecto_configuracion
        │                      │
        │                      ├─ hay fila → chrome (AppName, logos, URL)
        │                      │            + email (username, credentials, token)
        │                      └─ no hay fila → chrome = Branding del host
        │                                       email = no enviar si faltan credenciales de proyecto
        │
ChangeProject(id) → set session → reload página
Jobs / gRPC sin id_proyecto → no SendEmail*
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

- [ ] **T-10** — Checklist de verificación manual (P1)
  - Archivos: ninguno de producto (evidencia en ejecución / `AVANCE.md`)
  - Criterio de completitud P1: (1) host GP → login idéntico a hoy; (2) host EngineCX → login sin Garantiplus; (3) login real en ambos y chrome coherente **por host**. El punto (4) original (“cambio de proyecto no cambia marca”) **queda anulado por P2** (RF-12). Completar T-10 de P1 antes o en paralelo a P2; el checklist P2 es T-20.

### Fase 4 — Persistencia y almacenamiento (P2)

- [ ] **T-11** — Tabla `proyecto_configuracion`
  - Archivos: entidad EF en `DataAccess` y **la misma** en `DataAccessColombia`; `DbSet` + FK a `proyecto`; script SQL en `GarantiplusWeb/BD/` (fecha + nombre descriptivo).
  - Criterio de completitud: columnas de RF-09. 1:1 con `id_proyecto` (unique). Código de entidad en inglés (`ProjectConfiguration` / mapeo a tabla `proyecto_configuracion` en snake_case de SIGA).

- [ ] **T-12** — Raíces en `appsettings`
  - Archivos: `GarantiplusWeb/Options/` (p. ej. `ProjectBrandingStorageOptions`), `GarantiplusWeb/appsettings.json`.
  - Criterio de completitud: dos raíces configurables (assets visuales y archivos de email). No hardcodear `C:\`. Las carpetas de runtime en `.gitignore`.

### Fase 5 — Catálogo Proyectos (P2)

- [ ] **T-13** — Pestaña Configuraciones
  - Archivos: `Areas/Catalogos/Views/Proyectos/Edit.cshtml` (cuarta tab junto a Proyecto / Correo bienvenida / Correo registro); `Create.cshtml` (tabs equivalentes); partial nuevo `_ProjectConfiguration.cshtml`; `ProyectosController.cs`.
  - Criterio de completitud: campos RF-08. Create: tras INSERT se crea carpeta `{id}` y la fila. Edit: carga valores y previews de archivos ya guardados. Roles iguales al catálogo actual (`Administrador General, Gestor de Países, Auditor`). Mensajes de error al usuario en español.

- [ ] **T-14** — Upload de archivos
  - Criterio de completitud: Logo y HeaderLogo con extensión/tamaño validados. Credentials y token se escriben en la raíz de email. BD guarda ruta relativa o absoluta resoluble + nombre. Reemplazar archivo = sobrescribir el mismo nombre fijo. No commitear binarios ni `credentials.json`.

### Fase 6 — Overlay de chrome (P2)

- [ ] **T-15** — Resolver de proyecto
  - Archivos: extender `IBrandingContext` / nuevo `IProjectBrandingOverlay` scoped que lee sesión `_IdProyecto` y `proyecto_configuracion`.
  - Criterio de completitud: campo a campo, valor de proyecto si no vacío; si no, `Brand` del host. Sin proyecto en sesión (login) → solo host.

- [ ] **T-16** — Recarga en `ChangeProject`
  - Archivos: `GeneralController.ChangeProject` / JS en `_Layout.cshtml` (ya llama `~/Home/ChangeProject/`).
  - Criterio de completitud: tras cambiar proyecto, full reload de la página actual. Chrome ( `_TopNavBar` HeaderLogo, home logos) refleja RF-11. AppName/CompanyName/ExternalSiteUrl donde ya se leen de branding.

### Fase 7 — Correo por proyecto (P2)

- [ ] **T-17** — Web `IEmailSender`
  - Archivos: factory en `GarantiplusWeb/Program.cs`; resolver que carga `proyecto_configuracion` por sesión. **No** usar `EmailSettings` global como fallback de envío.
  - Criterio de completitud: si hay `id_proyecto` y la fila tiene username + credentials + token válidos → `EmailSenderGmail` con esas rutas. Si falta cualquiera → no enviar; log técnico en inglés.

- [ ] **T-18** — PDFGenerator y Endosos
  - Archivos: clientes gRPC web (pasar `id_proyecto` en header o campo proto); servicios leen BD o ruta acordada y construyen `EmailSettings`.
  - Criterio de completitud: correo de bienvenida / endoso usa la cuenta del proyecto del contrato. Sin `id_proyecto` en la llamada → no enviar. Incluir el `new EmailSender(...)` de `PDFResolucionAutomatica` si ese flujo tiene avería/proyecto.

- [ ] **T-19** — Jobs sin proyecto
  - Archivos: jobs Quartz que hoy envían correo (p. ej. `CutBillJob` si aplica).
  - Criterio de completitud: sin `id_proyecto` explícito en el job **no** llaman `SendEmail*`. Log del skip. No reintroducir cuenta MX default.

- [ ] **T-20** — Checklist P2
  - Criterio de completitud: (1) proyecto sin config → chrome = host; intento de correo no sale si no hay credenciales de proyecto; (2) proyecto con config → chrome y From de un envío de prueba; (3) `ChangeProject` recarga y cambia logos; (4) login sigue por host; (5) job sin id no envía.

---

## 5. Cambios en base de datos *(si aplica)*

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `proyecto_configuracion` | Nueva | 1:1 con `proyecto`. Textos de marca + rutas de Logo, HeaderLogo, credentials, token. Script en `GarantiplusWeb/BD/`. Aplicar en MX y CO. |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| — | `/Identity/Account/Login` | Sin cambio de ruta (P1). | Hecho |
| POST | `Catalogos/Proyectos/Create` y `Edit` | Multipart: datos de proyecto + pestaña Configuraciones. | P2 |
| GET | `Home/ChangeProject/{id}` | Ya existe; P2 exige reload con overlay. | P2 |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Branding:DefaultBrandKey` | Marca si el host no está en el mapa (`garantiplus`) | Todos |
| `Branding:Hosts` | Mapa hostname → brand key | Todos (valores distintos QA/Prod) |
| `Branding:Brands:{key}:*` | Rutas de logo, favicon, JSON de banners, partial de footer | Todos |
| Hosts locales sugeridos | `localhost` / `127.0.0.1` → `garantiplus`; `warranties.localhost` → `enginecx-ar` | Desarrollo |

P2 (adicionales):

| Variable | Descripción | Ambiente |
|---|---|---|
| Raíz assets por proyecto | Carpeta base de Logo / HeaderLogo | Todos |
| Raíz email por proyecto | Carpeta base de credentials/token | Todos |

No commitear esas carpetas ni `credentials.json`. Hosts de producción conocidos: `intranet.garantiplus.mx`, `warranties.enginecx.com.ar`. Host de QA: pregunta abierta del PRD.

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

**P1**

- [ ] En host EngineCX el login no muestra “Garantiplus” ni su isotipo.
- [ ] En host Garantiplus el login es el de hoy.
- [ ] `Hub:HubBaseCountryCode` sigue `MEX`.
- [ ] Hosts y assets de P1 salen de `appsettings`.
- [ ] Código nuevo en inglés. Verificación T-10.

**P2**

- [ ] Pestaña Configuraciones en crear/editar proyecto persiste `proyecto_configuracion` y archivos bajo `{id_proyecto}`.
- [ ] Sin fila: chrome autenticado = branding del host.
- [ ] Con fila: chrome usa logos/nombres/URL del proyecto; `ChangeProject` recarga y actualiza.
- [ ] Login sigue solo por host (favicon/banners/footer).
- [ ] Un envío con `id_proyecto` y credenciales de proyecto usa esa cuenta From.
- [ ] Un job o llamada sin `id_proyecto` explícito **no envía** correo.
- [ ] Modelo/tabla replicados en DataAccess MX y CO. `CountryBase` no se usa para este cambio.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Nginx no reenvía el Host público | Media | Alto (PoC funciona en local y falla en prod) | T-03/T-09: loguear `Request.Host` una vez; ajustar forwarded headers solo si hace falta |
| Assets EngineCX no entregados | Media | Medio | Placeholder `enginecx_logo.png` + banners locales; no bloquear código |
| Alcance se infla a PJ9766 (aprobación, palabras prohibidas) | Media | Alto | P2 = catálogo + overlay + correo por `id_proyecto`; nada más |
| Job sigue mandando con EmailSettings MX | Alta | Alto | T-19: skip explícito; sin fallback |
| Create sin id aún | Media | Medio | T-13: INSERT primero, luego carpeta y fila |
| `if (pais == Argentina)` en home choca con marca-por-host | Media | Medio | T-08: host manda sobre el logo; no ampliar ifs de país |
| Rama local `ag_siga_multibranding_*` + appsettings de país | Media | Bajo | Rama nueva desde `develop`; no commitear connection strings locales |

---

## 12. Notas para el programador

1. **No usar `siga-cambio-pais-base`.** Eso cambia BD/hub/correo MX↔CO↔CL, no la marca.
2. **No hacer ARG hub** para esta PoC.
3. Relación con **PJ9766**: P2 es el admin mínimo (pestaña + tabla + runtime). Aprobación y palabras prohibidas siguen en PJ9766.
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
| **Fase 4 — Persistencia (P2)** | Tabla + raíces settings | T-11 a T-12 | 1 – 1.5 días | por asignar |
| **Fase 5 — Catálogo (P2)** | Pestaña + uploads | T-13 a T-14 | 1.5 – 2.5 días | por asignar |
| **Fase 6 — Overlay chrome (P2)** | Resolver proyecto + ChangeProject | T-15 a T-16 | 1 – 1.5 días | por asignar |
| **Fase 7 — Correo (P2)** | Web + gRPC + jobs + checklist | T-17 a T-20 | 2 – 3 días | por asignar |
| **Total P1** | Login + chrome por host | T-01 a T-10 | **~2.5 – 4.5 días** | — |
| **Total P2** | Config por proyecto + correo | T-11 a T-20 | **~5.5 – 8.5 días** | — |

> P1 no se reabre salvo bugs. P2 no incluye PJ9766 (aprobación / palabras prohibidas) ni reescribir plantillas HTML de correo.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 — esfuerzo: normal*
