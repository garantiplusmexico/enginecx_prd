# PRD — White-label por hostname y configuración por proyecto en SIGA

> Feature sobre sistema existente (SIGA Web). **P1 (entregado):** resolver la identidad de marca por `Request.Host` sin cambiar hub, país base ni base de datos. **P2 (esta versión):** configuración de marca y correo **por proyecto**, persistida en BD y aplicada al chrome y a todos los envíos de email cuando hay un `id_proyecto` explícito.
>
> Relacionado con `PJ9766-configuracion-marca-proyecto` (producto completo: aprobación, palabras prohibidas, plantillas). PJ9770 **no sustituye** PJ9766: cubre runtime por host (P1) + alta/edición de config por proyecto y su aplicación (P2). Quedan fuera de este folio el workflow de aprobación y las palabras prohibidas.

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | SIGA Web (`gp_4.0_siga` / GarantiplusWeb) + envíos de correo en PDFGenerator y Endosos cuando viajan con `id_proyecto` |
| Tipo | Feature / PoC ampliada |
| Área / empresa | GarantiPlus México — proyecto Argentina (Engine Warranties) |
| Folio | PJ9770 |
| Versión | v0.2 |
| Fecha | 2026-09-04 (v0.1: 2026-09-02) |
| Autores | Alejandro Govea Hernandez |
| Revisión / liderazgo | Aldo Álvarez (Director de TI) — por confirmar |
| Modelo de generación | Claude Opus 4.8 — esfuerzo normal (v0.1); ampliación v0.2 a partir de cierre con el desarrollador |

---

## 1. Resumen del cambio

SIGA Web es una sola aplicación. [intranet.garantiplus.mx](https://intranet.garantiplus.mx/) y [warranties.enginecx.com.ar](https://warranties.enginecx.com.ar/) apuntan a la misma instancia con `Hub:HubBaseCountryCode = MEX`. Argentina es país *hosted*, no hub. En Argentina la marca Garantiplus no puede usarse.

**P1** introduce white-label por hostname: login y chrome anónimo según el Host (`appsettings` `Branding`). Eso se mantiene.

**P2** añade una segunda capa **después del login**. El usuario ya elige proyecto con el selector de la barra (`SessionProjectId` / `Home/ChangeProject`). Ese proyecto puede tener una fila en `proyecto_configuracion` (nombre, logos, URL externa, cuenta de correo y archivos de Gmail). Al cambiar de proyecto la página se recarga y el chrome usa esa config. Si el proyecto no tiene fila (o campos vacíos), se usa el branding del host. Todo correo de la aplicación usa la cuenta del proyecto **solo si hay `id_proyecto` explícito**; si no hay (jobs, procesos sin contexto), **no se envía**.

No se convierte Argentina en hub. No se clona el producto.

---

## 2. Contexto del cambio

| Concepto | Qué es | Dónde aplica |
|---|---|---|
| Hub | País dueño de la instancia (`MEX`) | País operativo; no es marca |
| Host | URL de entrada | Login (anónimo): título, favicon, logo, banners, footer |
| Proyecto de sesión | `_IdProyecto` tras login / `ChangeProject` | Chrome autenticado + correo |
| `proyecto_configuracion` | Fila 1:1 opcional por `id_proyecto` | Overlay sobre el branding del host |

El selector de proyecto ya existe (`<project-selector>` en `_TopNavBar`, `Home/ChangeProject`). P2 no inventa otro flujo de “elegir proyecto al entrar”: usa el de hoy y recarga.

Precedente de *skin* por proyecto: `SessionProjectLayout` (Mitsubishi/Astara). P2 es marca/correo, no un layout distinto.

---

## 3. Alcance del cambio

**P1 (entregado — no reabrir salvo bugs):**

| Elemento | Descripción |
|---|---|
| Resolver de marca por host | Hostname → clave de marca desde `Branding`. |
| Login | Título, favicon, logo, banners, footer según host. |
| Chrome autenticado *hasta P1* | Top bar según marca del **host** (queda sustituido en P2 tras login). |

**P2 (entra ahora):**

| Elemento | Descripción |
|---|---|
| Tabla `proyecto_configuracion` | Nueva; `id_proyecto` + campos de marca y rutas de archivos. Réplica en DataAccess México y Colombia. |
| Pestaña Configuraciones | En catálogo de Proyectos (crear y editar): AppName, CompanyName, Logo, HeaderLogo, ExternalSiteUrl, email username, credentials y token. |
| Almacenamiento de archivos | Raíz configurable en `appsettings`; subcarpeta `{id_proyecto}`; nombres fijos de archivo. En BD se guarda la ruta (url + nombre), no el binario. |
| Overlay de branding | Autenticado: si hay config de proyecto, pinta chrome con esos valores; si no, host. Login sigue 100% por host. |
| Recarga al cambiar proyecto | `ChangeProject` recarga la página con la config del proyecto elegido. |
| Correo por proyecto | Cualquier envío en la app usa username + credentials + token del proyecto. Hace falta `id_proyecto` explícito. |
| PDFGenerator / Endosos | Si el envío nace de un flujo con contrato/proyecto, reciben `id_proyecto` y usan la misma fila. |
| Jobs / procesos sin proyecto | **No envían** correo hasta que exista `id_proyecto` explícito. No hay fallback silencioso a la cuenta MX del `appsettings`. |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Convertir ARG en hub | Fuera de identidad. |
| Aprobación, palabras prohibidas, catálogo de plantillas de PJ9766 | Otro folio. |
| Favicon, banners de login y footer legal por proyecto | El login no tiene proyecto; siguen por host. |
| `NavLogoPath` | No se usa en vistas; no se pide en el catálogo. |
| Asuntos/HTML de correo “Bienvenido a Garantiplus” | Fuera de este corte; P2 cambia la **cuenta From**, no las plantillas. |
| API SIGA (`gp_3.0_siga_api`) | El login y el catálogo de proyectos de esta PoC son SIGA Web. |
| Fork / segundo código SIGA | Descartado. |

---

## 4. Requerimientos funcionales

### P1 — Host (vigentes)

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Resolución por hostname | `Request.Host` (sin puerto, case-insensitive) → mapa `Hosts`. Sin match → `DefaultBrandKey`. |
| RF-02 | Login EngineCX | Host EngineCX: sin “Garantiplus” en title/H1/isotipo; banners y footer de esa marca. |
| RF-03 | Login Garantiplus intacto | Host Garantiplus/default: comportamiento actual. |
| RF-05 | Sin “Garantiplus” en login AR | Superficies de login del host `warranties.enginecx.com.ar`. |
| RF-06 | Misma app, mismo hub | `HubBaseCountryCode` = `MEX`. ARG hosted. |
| RF-07 | Hosts en configuración | No hardcodear hosts en vistas. |

### P2 — Proyecto

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-08 | Pestaña Configuraciones | Crear y editar proyecto: pestaña con AppName (texto), CompanyName (texto), Logo (archivo), HeaderLogo (archivo), ExternalSiteUrl (URL), Email username (email), CredentialsPath (archivo), TokenPath (archivo/carpeta token). |
| RF-09 | Persistencia | Una fila por proyecto en `proyecto_configuracion`. Los archivos se guardan en disco; las columnas de archivo almacenan ruta + nombre. |
| RF-10 | Carpetas | Raíz de assets y raíz de email se leen de `appsettings`. Dentro: carpeta `{id_proyecto}`. Nombres de archivo fijos (`Logo`, `HeaderLogo`, credentials y token según convención acordada en implementación). En **Create**, el `id_proyecto` se obtiene tras el INSERT; archivos y fila se escriben en ese mismo flujo. |
| RF-11 | Overlay post-login | Chrome autenticado (AppName/CompanyName donde aplique, Logo, HeaderLogo, ExternalSiteUrl) sale de `proyecto_configuracion` si existe; si no hay fila o el campo está vacío, el valor del **host**. |
| RF-12 | Recarga al cambiar proyecto | Al usar el selector (`ChangeProject`), se recarga la página y se aplica la config del `id_proyecto` nuevo. |
| RF-13 | Correo con `id_proyecto` | Todo `IEmailSender` / envío Gmail de la aplicación usa la cuenta de `proyecto_configuracion` de ese proyecto (username + credentials + token). |
| RF-14 | Sin `id_proyecto` no hay envío | Jobs Quartz, procesos batch u otros caminos sin `id_proyecto` explícito **no envían** correo. No usar la cuenta default de `EmailSettings` como atajo. |
| RF-15 | Servicios gRPC | PDFGenerator y Endosos, cuando envían correo de un flujo de contrato/endoso, reciben `id_proyecto` y resuelven la misma configuración (BD + rutas de archivo). |
| RF-04 (actualizado) | Chrome autenticado | Tras login, el chrome sigue al **proyecto** (RF-11), no al host. El host solo manda en login y como fallback. |

---

## 5. Requerimientos no funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Sin impacto en MX sin config | Un proyecto sin fila en `proyecto_configuracion` se ve y envía como el host (visual) y **no envía** correo de proyecto; los envíos requieren RF-14/RF-13. Aclaración: el chrome cae a host; el correo no cae a MX silencioso. |
| RNF-02 | Código nuevo en inglés | UI en español. |
| RNF-03 | Proxy / Host | `Request.Host` público o `X-Forwarded-Host` para P1. |
| RNF-04 | Credenciales de correo | `credentials.json` y token no se commitean. Viven en disco del servidor bajo la raíz configurada; `.gitignore` de esas carpetas. |
| RNF-05 | Sesiones por dominio | Sin cambio de cookies. |
| RNF-06 | DataAccess espejo | Modelo y `DbSet` iguales en México y Colombia. |
| RNF-07 | Recarga | El cambio de proyecto no deja chrome/correo de la sesión anterior en memoria de la request (scoped por request + reload). |

**Nota RNF-01 / correo:** el fallback a host es **solo visual**. El correo no usa `EmailSettings` global si falta config de proyecto: o hay fila completa de email en `proyecto_configuracion`, o no se envía (log en inglés del motivo).

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| `Branding` / `IBrandingContext` (P1) | Ya existe | Login y fallback visual. |
| DataAccess / DataAccessColombia | Nuevo | Entidad `proyecto_configuracion`, `DbSet`, FK a `proyecto`. |
| PostgreSQL | Nuevo | Tabla `proyecto_configuracion`. |
| `ProyectosController` + vistas | Modificación | Pestaña Configuraciones en Create/Edit (`Edit.cshtml` ya tiene tabs; Create hoy no). |
| `appsettings` web | Modificación | Raíces de carpetas de logos y de email por proyecto. |
| `ChangeProject` / `_TopNavBar` | Modificación | Recarga; chrome lee overlay. |
| `IEmailSender` factory (web) | Modificación | Resolver por `id_proyecto` de sesión; si no hay config de email, no construir envío / no enviar. |
| PDFGenerator / Endosos | Modificación | Recibir `id_proyecto`; resolver cuenta; no enviar si falta. |
| Jobs Quartz | Modificación | No enviar sin `id_proyecto` explícito. |
| API SIGA | Sin cambio | — |

**Campos de `proyecto_configuracion` (negocio):**

| Campo | Origen UI | Persistencia |
|---|---|---|
| `id_proyecto` | PK/FK | entero |
| `app_name` | AppName | texto |
| `company_name` | CompanyName | texto |
| `logo_path` | archivo Logo | ruta + nombre |
| `header_logo_path` | archivo HeaderLogo | ruta + nombre |
| `external_site_url` | ExternalSiteUrl | texto URL |
| `email_username` | EmailSettings username | texto email |
| `credentials_path` | archivo credentials | ruta + nombre |
| `token_path` | token Gmail | ruta |

---

## 7. Preguntas abiertas

| Tema | Estado |
|---|---|
| Recarga al cambiar proyecto | **Cerrado:** sí, recarga con la config del proyecto. |
| Fallback visual | **Cerrado:** sin fila → branding del host. |
| Correo | **Cerrado:** cuenta del proyecto en toda la app; sin `id_proyecto` explícito **no se envía**. |
| Nombre comercial EngineCX | Abierto (P1): Warranties EngineCX hasta confirmar. |
| Assets / footer legal AR | Abierto (P1): placeholders. |
| Host QA EngineCX | Abierto. |
| Relación merge vs PJ9766 | Abierto a nivel de release. |
| Nombres exactos de archivo en disco | A fijar en implementación (`Logo`, `HeaderLogo`, `credentials.json`, carpeta `token`). |
| Extensiones permitidas de logo | A fijar (p. ej. png/svg/jpg) y tamaño máximo. |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v0.2*
