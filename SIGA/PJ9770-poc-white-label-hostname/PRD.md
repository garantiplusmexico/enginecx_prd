# PRD — PoC white-label por hostname en SIGA

> Feature sobre sistema existente (SIGA Web). Prueba de concepto de la opción A: resolver la identidad de marca por `Request.Host` sin cambiar hub, país base ni base de datos.
>
> Relacionado con `PJ9766-configuracion-marca-proyecto` (producto completo: catálogo por proyecto, aprobación, palabras prohibidas, correo y plantillas). Esta PoC **no sustituye** ese PRD: valida el mecanismo de runtime (host → marca) que un catálogo futuro podría alimentar.

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | SIGA Web (`gp_4.0_siga` / GarantiplusWeb) |
| Tipo | Feature / PoC |
| Área / empresa | GarantiPlus México — proyecto Argentina (Engine Warranties) |
| Folio | PJ9770 |
| Versión | v0.1 |
| Fecha | 2026-09-02 |
| Autores | Alejandro Govea Hernandez (a partir de análisis técnico 2026-09-02) |
| Revisión / liderazgo | Aldo Álvarez (Director de TI) — por confirmar |
| Modelo de generación | Claude Opus 4.8 — esfuerzo normal |

---

## 1. Resumen del cambio

SIGA Web es una sola aplicación. Hoy [intranet.garantiplus.mx](https://intranet.garantiplus.mx/) y [warranties.enginecx.com.ar](https://warranties.enginecx.com.ar/) apuntan a la misma instancia con `Hub:HubBaseCountryCode = MEX`. El login toma el país del **hub**, no del host: título `Garantiplus`, favicon de `garantiplus.mx`, un único `banner.json` con imágenes Garantiplus y footer legal mexicano (`_LoginFooterMEX`). Argentina es un país *hosted* (`HostedCountryCodes`), no un hub.

El problema de negocio: en Argentina la marca Garantiplus no puede usarse (conflicto legal previo; ver `PJ9766`). El mercado opera como Engine Warranties / Warranties EngineCX. Quien entra por la URL argentina debe ver esa identidad **antes de autenticarse**.

Esta PoC introduce un **white-label por hostname**: un `IBrandingContext` resuelto por request a partir del Host, con un catálogo en `appsettings`. En `warranties.enginecx.com.ar` el login y el chrome (logo, título, favicon, banners, footer) usan la marca EngineCX. En `intranet.garantiplus.mx` no cambia el comportamiento actual.

No se convierte Argentina en hub, no se toca DataAccess ni `CountryBase`, no se clona el producto.

---

## 2. Contexto del cambio

Hoy hay tres conceptos mezclados:

| Concepto | Qué es | Qué usa el login hoy |
|---|---|---|
| Hub | País dueño de la instancia (`MEX`) | `_hub.BaseCountry` → siempre MEX |
| País del proyecto | ARG/PER/… en sesión **después** del login | No disponible en páginas anónimas |
| Marca | No existe | Hardcode Garantiplus |

Ya hay atisbos post-login (`Views/Home/Index.cshtml` cambia títulos si `Localizer["pais"] == "Argentina"`), pero el menú sigue con `logo_home.jpg` / `garantiplus-logo-02.svg`, los banners de login son únicos y el legal del footer es mexicano. No existe `_LoginFooterARG`.

Precedente de *skin* (no de marca por URL): layouts Mitsubishi/Astara por proyecto (`SessionProjectLayout`).

---

## 3. Alcance del cambio

**Qué entra (PoC / P1):**

| Elemento | Descripción |
|---|---|
| Resolver de marca por host | Mapear hostname → clave de marca (`garantiplus` / `enginecx-ar`) desde configuración. |
| Contexto de marca por request | `IBrandingContext` scoped, consumible en Razor y page models. |
| Login | Título, favicon, logo, banners (`banner.{marca}.json`) y footer según marca. |
| Chrome autenticado | Logo del top bar y del menú lateral según marca del host. |
| Footer ARG | Partial `_LoginFooterARG` sin textos legales de Garantiplus México (placeholder EngineCX hasta que Legal entregue textos AR). |
| Prueba local | Segundo binding HTTP y/o hosts file para simular ambos dominios contra la misma app. |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Convertir ARG en hub (`HubBaseCountryCode`, `CountryBase`, DataAccess) | Fuera de identidad; es cambio operativo de país. |
| Correos (From, asuntos, HTML, logos absolutos) | Requiere buzón `@enginecx.com.ar` / SPF-DKIM; va en evolución post-PoC o en `PJ9766`. |
| PDFs, contratos, ODP | Motor `PDFGenerator`; no es necesario para validar el enfoque. |
| Catálogo admin, aprobación, palabras prohibidas | Alcance de `PJ9766`, no de esta PoC. |
| Marca por país de proyecto si se entra por `.mx` | PoC discrimina **solo por host**. Un usuario ARG en `intranet.garantiplus.mx` sigue viendo Garantiplus. |
| Textos legales argentinos definitivos (Ley 25.326) | Dependencia de Legal; PoC usa placeholder sin mencionar Garantiplus. |
| Fork / segundo código SIGA | Descartado. |
| Cambios de BD | La marca vive en `appsettings` en esta PoC. |

---

## 4. Requerimientos funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Resolución por hostname | Dada una request, la app determina la marca comparando `Request.Host` (sin puerto, case-insensitive) con el mapa de hosts. Si no hay match, usa la marca default (`garantiplus`). |
| RF-02 | Login EngineCX | En host EngineCX: título de página y H1 sin “Garantiplus”; favicon y logo EngineCX; banners del JSON de esa marca; footer `_LoginFooterARG`. |
| RF-03 | Login Garantiplus intacto | En host Garantiplus (y default): comportamiento actual (banners `banner.json`, `_LoginFooterMEX` cuando el hub es MEX, título Garantiplus). |
| RF-04 | Chrome autenticado | Tras login en host EngineCX, top bar y menú lateral no muestran el logo Garantiplus; usan el logo de la marca del host. |
| RF-05 | Sin “Garantiplus” en superficies PoC del host AR | En las superficies de esta PoC (login + chrome) el host `warranties.enginecx.com.ar` no muestra la palabra ni el isotipo Garantiplus. |
| RF-06 | Misma app, mismo hub | `Hub:HubBaseCountryCode` permanece `MEX`. ARG sigue hosted. No hay segundo deploy para la PoC. |
| RF-07 | Configuración, no hardcode de hosts | Hosts y rutas de assets viven en `appsettings` (sección `Branding`). |

---

## 5. Requerimientos no funcionales *(solo los que apliquen a este cambio)*

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Sin impacto en MX | Quien entra por el host Garantiplus no percibe cambio de marca. |
| RNF-02 | Código nuevo en inglés | Clases, miembros y comentarios técnicos en inglés (`coding-guidelines.md`). Textos de UI en español. |
| RNF-03 | Proxy / Host | Documentar que detrás de Nginx el Host debe ser el público (o `X-Forwarded-Host` / Forwarded Headers). La PoC local usa Host directo. |
| RNF-04 | Sin secrets nuevos | No hay credenciales de correo ni DNS en esta PoC. |
| RNF-05 | Sesiones por dominio | Cookies de sesión no se comparten entre `.mx` y `.com.ar` (dominios distintos). No se cambia el esquema de cookies. |

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| GarantiplusWeb — Options + DI | Nuevo | `BrandingOptions`, resolver, `IBrandingContext`, registro en `Program.cs`. |
| `GarantiplusWeb/appsettings.json` | Modificación | Sección `Branding` (hosts + definiciones de marca). |
| Login (`Login.cshtml` / `.cs`) | Modificación | Carga de banners y ViewData desde branding, no solo hub. |
| `_LoginLayout.cshtml` | Modificación | Título, favicon, logo según contexto. |
| `_LoginFooterARG.cshtml` | Nuevo | Footer legal placeholder EngineCX. |
| `banner.enginecx-ar.json` | Nuevo | Slides de login para la marca AR. |
| Remake `_TopNavBar.cshtml` | Modificación | Logo según marca. |
| Navegación / `logo_home.jpg` | Modificación mínima | Logo lateral según marca (partial existente, sin nuevo layout Mitsubishi-style). |
| `launchSettings.json` | Modificación | Segundo `applicationUrl` para probar dos hosts en local. |
| Hub / DataAccess / BD | Sin cambio | — |
| PDFGenerator / Emailing | Sin cambio | Fuera de PoC. |
| API SIGA (`gp_3.0_siga_api`) | Sin cambio | El login de SIGA Web no pasa por la API. |

---

## 7. Preguntas abiertas

| Tema | Pregunta abierta |
|---|---|
| Nombre comercial | ¿“Engine Warranties”, “Warranties EngineCX” u otro? El home actual usa “Warranties EngineCX”; `PJ9766` usa “Engine Warranties”. La PoC usará **Warranties EngineCX** hasta que se confirme. |
| Assets | ¿Hay logo, favicon y banners definitivos para AR, o se reutiliza `enginecx_logo.png` y banners placeholder? |
| Footer legal | ¿Legal entrega textos AR para la PoC o basta un placeholder explícito “textos pendientes de Legal”? |
| Post-PoC vs `PJ9766` | ¿Esta PoC se fusiona a `develop` como base del catálogo de `PJ9766`, o permanece como rama de experimentación? |
| Host QA | ¿Cuál será el hostname de QA para EngineCX (además de producción `warranties.enginecx.com.ar`)? |
| Entrada cruzada | Confirmado para PoC: marca **solo por host**. ¿En una fase posterior también se aplica marca EngineCX si `codigo_pais == ARG` aunque se entre por `.mx`? |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v0.1*
