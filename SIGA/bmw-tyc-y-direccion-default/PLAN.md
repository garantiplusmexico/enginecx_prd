# Plan de Desarrollo — BMW: quitar el T&C de carátula negra y neutralizar la dirección por defecto del contrato

> Generado por Claude Code. **Este cambio no tiene PRD**: la fuente de requerimiento es el correo
> "Modificación BMW" de Aldo Álvarez del 26-ago-2026, decisión tomada explícitamente por el
> responsable al generar el plan (el alcance es demasiado acotado para justificar un PRD propio).
> El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | *(ninguno)* — Fuente: correo **"Modificación BMW"**, Aldo Álvarez → Carlos Castellanos, 26-ago-2026 14:30 (seguimiento de Alexis Herrera, 15:26) |
| Repositorio | **Dos**: `bmw_landing` (cambio 1) y `gp_3.0_siga_api` (cambio 2) |
| Rama | `bugfix/bmw-tyc-y-direccion-default` (mismo nombre en ambos repos) |
| Tipo | Bugfix |
| Responsable | Juan Carlos Castellanos Solis |
| Folio PRD | *(sin asignar — ver §12, nota 1)* |
| Fecha de generación | 2026-08-27 |
| Estado | Borrador |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |
| Tablero | Tarea **T-003** en `carlos_tareas/TAREAS.md` |
| Modelo / esfuerzo | `claude-opus-5` — esfuerzo normal |

---

## 1. Resumen técnico

Son **dos cambios independientes** que el correo agrupa en una sola solicitud. Viven en repos
distintos, así que van en **ramas y commits separados** (decisión del responsable: una sola tarea,
commits separados).

**Cambio 1 — Quitar el documento de T&C (landing).**
El listado de contratos creados muestra tres enlaces por registro: *Contrato (PDF)*, *T&C (PDF)* y
*ODP (PDF)*. El T&C es un PDF estático de 5 MB (`Terminos y condiciones BMW.pdf`) servido desde
`public/docs/`, no viene del API. BMW decidió apegarse únicamente al contrato, así que se elimina el
enlace, la entrada del catálogo y el archivo. Frontend puro: React 19 + TS + Vite, sin backend.

**Cambio 2 — Neutralizar la dirección por defecto del beneficiario (API de SIGA).**
La landing **no captura** el domicilio del beneficiario; el backend lo rellena siempre desde
`BmwLandingContractDefaults:BeneficiaryDefaults` en `Services/Contracts/appsettings.json`, donde hoy
está horneada una dirección real de GarantiPlus (*Sierra Candela 80, Lomas de Chapultepec I Sección,
CP 11000*). Esa dirección se imprime en el contrato y el cliente la reportó. Es un cambio de
**configuración**, no de código, siempre que se respete la restricción del DTO (ver §11, R-1).

**Arquitectura:** ninguna. Ambos cambios son sobre componentes existentes (landing estática en S3 y
microservicio `Contracts` en ECS+Fargate). No se crean componentes, endpoints, tablas ni servicios.

---

## 2. Prerequisitos

- [ ] ~~PRD validado~~ → **Correo de Aldo como fuente**, ya leído y transcrito en este plan
- [ ] **Aldo confirma el alcance del cambio 2** (ver T-01) — es la única decisión de negocio abierta
- [ ] Acceso a los dos repositorios: `bmw_landing` y `gp_3.0_siga_api` ✅
- [ ] `CLAUDE.md` presente en ambos repos ✅
- [ ] Acceso a la task definition de ECS del servicio `Contracts` en QA y PROD (para verificar que no
      haya override de la variable, ver T-02)
- [ ] ⚠️ **Deploy de `gp_3.0_siga_api` a QA en curso** (checklist `gp_3.0_siga_api-qa-2026-08-27`,
      bloqueado esperando aprobación de la PR #283). No crear la rama en ese repo hasta cerrarlo o
      confirmar que no interfiere — ver §11, R-4

---

## 3. Arquitectura del cambio

No aplica arquitectura nueva. Se respeta la existente (`rules/arquitectura.md` §5):

```
[bmw_landing]  React SPA en S3  ──► (cambio 1: se elimina un enlace y un PDF estático)
       │
       │ llamada directa (CORS)
       ▼
[gp_3.0_siga_api / Contracts]  ECS + Fargate
       │  BmwLandingContractRequestFactory.BuildBeneficiary()
       │      └─ rellena el domicilio desde appsettings  ◄── (cambio 2: solo valores de config)
       ▼
[gp_4.0_siga]  crea el contrato y genera el PDF que ve el cliente
```

Punto clave del cambio 2: el valor viaja
`appsettings.json` → `LandingContractBeneficiaryDefaultsOptions` → `BeneficiaryInfoRequest.Address`
→ contrato SIGA → **PDF del contrato**. No hay ningún otro origen para ese dato.

---

## 4. Tareas de desarrollo

### Fase 0 — Confirmaciones previas (bloquean el cambio 2, no el cambio 1)

- [ ] **T-01** — Confirmar con Aldo el alcance exacto de la "dirección por defecto"
  - Archivos: ninguno (correo, respondiendo el hilo "Modificación BMW")
  - Qué preguntar, concretamente:
    1. El domicilio por defecto **no es solo la calle**: son 6 valores (`Address`, `Colony`,
       `PostalCode`, `StateId`, `MunicipalityId`, `ColonyId`). ¿Se neutraliza **todo el domicilio**
       o **solo la calle** "Sierra Candela 80"?
    2. `StateId`, `MunicipalityId` y `ColonyId` son **llaves de catálogo obligatorias**: no pueden ir
       en blanco. En el mejor caso el contrato dirá "CDMX / Miguel Hidalgo". ¿Es aceptable?
    3. Blanco **no es viable** tal cual (ver R-1). Propuesta: `Address = "NO APLICA"` y
       `Colony = "NO APLICA"`, que es texto genérico, legible en español y cumple la longitud mínima.
       "FPO" no cabe (3 caracteres, el mínimo es 5) y además es jerga que el cliente final no entiende.
  - Criterio de completitud: Aldo responde por escrito en el hilo con el texto exacto a usar
  - **Este plan asume, si Aldo no responde a tiempo: `Address` y `Colony` = `"NO APLICA"`, ids de
    catálogo intactos.** Es reversible con un solo cambio de configuración.

- [ ] **T-02** — Verificar que `appsettings.json` es realmente la fuente efectiva en QA y PROD
  - Archivos: ninguno (task definitions de ECS del servicio `Contracts`)
  - Buscar overrides tipo `BmwLandingContractDefaults__BeneficiaryDefaults__Address` en variables de
    entorno / secrets de la task def
  - Criterio de completitud: confirmado que el valor no está sobrescrito en ningún ambiente **o**
    identificados los lugares adicionales a cambiar
  - Por qué es una tarea y no un supuesto: si hay override, el cambio en `appsettings.json` no surte
    efecto y el defecto se daría por corregido sin estarlo

### Fase 1 — Cambio 1: quitar el T&C de la landing (`bmw_landing`) → **commit 1**

- [ ] **T-03** — Eliminar el enlace "T&C (PDF)" del listado de contratos
  - Archivos a modificar: `src/lib/registrationDocuments.tsx`
  - Quitar el `<li>` del enlace T&C y el import de `MOCK_CONTRACT_PDF` / `mockContractPdfHref` si
    queda sin uso; actualizar el comentario de `RegistrationDocumentLinks` (línea 57), que hoy
    describe el T&C
  - Criterio de completitud: el listado muestra solo *Contrato (PDF)* y, cuando aplica, *ODP (PDF)*

- [ ] **T-04** — Limpiar el catálogo de PDFs estáticos y borrar el archivo
  - Archivos a modificar: `src/constants/mockContractDocuments.ts`
  - Archivos a eliminar: `public/docs/Terminos y condiciones BMW.pdf` (5 MB)
  - Quitar la entrada `terminos`. Las entradas `contrato` y `odp` ya están marcadas como "solo
    referencia" (el API real las provee): si tras quitar `terminos` el módulo completo queda sin
    consumidores, **eliminar el archivo entero** en lugar de dejar código muerto
  - Criterio de completitud: `pnpm lint` (typecheck) pasa sin errores ni imports huérfanos, y
    `dist/docs/` ya no contiene el PDF tras un build

- [ ] **T-05** — Subir la versión de la landing
  - Archivos a modificar: `.env`, `.env.qa`, `.env.production` (los tres, en sync)
  - `VITE_APP_VERSION`: `v1.0.19` → `v1.0.20`
  - Criterio de completitud: los tres archivos con el mismo valor; la versión se ve en la UI
    (`components/VersionInfo.tsx`)
  - Regla del repo: el bump viaja **en el mismo commit** que el bugfix

- [ ] **T-06** — Commit 1 y push
  - `[bmw-tyc-y-direccion-default] Quitar el documento de T&C del listado de contratos`
  - Criterio de completitud: rama `bugfix/bmw-tyc-y-direccion-default` empujada a `origin`

### Fase 2 — Cambio 2: neutralizar la dirección por defecto (`gp_3.0_siga_api`) → **commit 2**

- [ ] **T-07** — Cambiar los valores del domicilio por defecto de BMW
  - Archivos a modificar: `Services/Contracts/appsettings.json` — **solo el bloque
    `BmwLandingContractDefaults` (línea ~162)**
  - ⚠️ **No tocar `BridgestoneLandingContractDefaults` (línea ~119)**, que tiene exactamente la misma
    dirección horneada. Aldo pidió el cambio para BMW; Bridgestone no está en el alcance
  - `Services/Contracts/publish/appsettings.json` está en `.gitignore` (`**/publish/`): es salida de
    build, **no se edita**
  - Criterio de completitud: solo el bloque BMW modificado; `git diff` con exactamente las líneas
    esperadas y ninguna de BS

- [ ] **T-08** — Verificar que ningún otro punto del código hornee la dirección
  - Archivos a revisar: `Services/Contracts/Services/Bmw/BmwLandingContractRequestFactory.cs`
    (`BuildBeneficiary`, líneas 213-266) y `Options/LandingContractSharedDefaultsOptions.cs`
  - Confirmado en el análisis: el único origen es el default de configuración, vía
    `ResolveLandingString(null, defaults.Address)` — el `null` es literal, la landing nunca envía
    domicilio. Esta tarea es la verificación explícita de que sigue siendo así
  - Criterio de completitud: sin literales de dirección en código C#; el flujo depende solo de config

- [ ] **T-09** — Subir la versión del servicio `Contracts`
  - Usar la skill `actualizar-version-servicio-gp` (4 lugares: `build.ps1`, docker-compose local y el
    `ImageVersion` de los `deploy-services-v2.ps1` de QA y de prod)
  - ⚠️ `build.ps1` ya tiene `v0.26 → v0.27` preparado por el deploy en curso: **coordinar** para no
    pisar ese bump ni reusar la etiqueta (ver §11, R-4). Un cambio en `appsettings.json` va horneado
    en la imagen, así que **exige imagen nueva**: no basta con reiniciar la tarea
  - Criterio de completitud: versión nueva y coherente en los 4 lugares, sin colisionar con la del
    deploy abierto

- [ ] **T-10** — Commit 2 y push
  - `[bmw-tyc-y-direccion-default] Neutralizar la dirección por defecto del beneficiario BMW`
  - Criterio de completitud: rama `bugfix/bmw-tyc-y-direccion-default` empujada a `origin`

### Fase 3 — Validación en QA

- [ ] **T-11** — Validar el cambio 1 en QA
  - Entrar al listado de contratos creados de la landing en QA: no aparece "T&C (PDF)"; *Contrato* y
    *ODP* siguen descargando; la versión en pantalla dice `v1.0.20`
  - Criterio de completitud: verificado en el ambiente, no solo en local

- [ ] **T-12** — Validar el cambio 2 de punta a punta en QA
  - Dar de alta un contrato BMW completo y **abrir el PDF generado**
  - Criterio de completitud: el contrato **ya no dice "Sierra Candela 80"** y muestra el texto
    acordado. El alta **no falla** (ver R-1: si alguna validación aguas abajo rechaza el valor, el
    fallo aparece aquí, no antes)
  - Probar **Física y Moral**: son dos ramas distintas de `BuildBeneficiary`, ambas usan el default

- [ ] **T-13** — Responder el hilo de correo
  - Contestar a Aldo y Alexis en "Modificación BMW" con lo entregado y en qué ambiente está
  - Criterio de completitud: correo enviado; la tarea T-003 del tablero pasa a cerrada

---

## 5. Cambios en base de datos

**No aplica.** Ninguno de los dos cambios toca esquema ni datos. El cambio 2 altera el *valor* que se
graba en el domicilio de los contratos **nuevos**; los contratos ya emitidos conservan la dirección
anterior (ver §12, nota 2).

---

## 6. Endpoints nuevos o modificados

**No aplica.** Ningún contrato de API cambia. `POST /contracts/api/Bmw/v1/{projectId}/contracts` sigue
recibiendo exactamente los mismos campos: el domicilio nunca fue parte del request.

---

## 7. Variables de entorno y configuración

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `VITE_APP_VERSION` | `v1.0.19` → `v1.0.20` en `.env`, `.env.qa`, `.env.production` | Los tres |
| `BmwLandingContractDefaults:BeneficiaryDefaults:Address` | `"Sierra Candela 80"` → texto genérico | Desarrollo / QA / Producción |
| `BmwLandingContractDefaults:BeneficiaryDefaults:Colony` | `"Lomas de Chapultepec I Sección"` → texto genérico *(sujeto a T-01)* | Desarrollo / QA / Producción |

No se crean secrets ni variables nuevas. Ningún valor sensible está involucrado.

---

## 8. Consideraciones de seguridad

- **Sin cambios de permisos ni de autorización.** No se tocan endpoints, roles ni IAM.
- **Efecto positivo de privacidad:** se deja de imprimir en documentos de cliente una dirección física
  real de GarantiPlus que no corresponde al beneficiario. Es justamente la confusión que reportó el
  cliente.
- **Sin secrets en el código.** Los valores que cambian son texto de catálogo, no credenciales.
- Al borrar el PDF de T&C se elimina un documento público de 5 MB: verificar que no esté enlazado
  desde fuera de la landing (correos, materiales de BMW) antes de darlo por muerto — ver §11, R-3.

---

## 9. Consideraciones de infraestructura

- **`bmw_landing`:** build estático → S3. Sin costo ni servicio nuevo. Borrar el PDF **reduce** el
  tamaño del bundle desplegado en ~5 MB.
- **`gp_3.0_siga_api`:** el servicio `Contracts` requiere **imagen nueva** (el `appsettings.json` se
  hornea en la imagen) y redeploy de la task definition en QA y PROD. Sin recursos AWS nuevos.
- **Sin cambios** en Cloudflare, Route 53, RDS ni KrakenD (no hay endpoints nuevos).

---

## 10. Criterios de aceptación

- [ ] El listado de contratos de la landing **no muestra** el enlace "T&C (PDF)"
- [ ] Los enlaces *Contrato (PDF)* y *ODP (PDF)* siguen funcionando sin cambios
- [ ] El PDF `Terminos y condiciones BMW.pdf` ya no se publica en `dist/docs/`
- [ ] `pnpm lint` pasa limpio en `bmw_landing` (es el único typecheck del repo; no hay tests)
- [ ] La landing muestra `v1.0.20` y los tres `.env` están en sync
- [ ] Un contrato BMW **nuevo** creado en QA **no contiene** "Sierra Candela 80" en el PDF
- [ ] El alta de contrato BMW funciona en **Física y Moral**, sin errores de validación
- [ ] El bloque `BridgestoneLandingContractDefaults` quedó **intacto**
- [ ] Los dos cambios están en **commits separados** y ambos en `bugfix/bmw-tyc-y-direccion-default`
- [ ] Aldo y Alexis tienen respuesta en el hilo "Modificación BMW"

---

## 11. Riesgos técnicos identificados

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **R-1 — El blanco literal rompe el alta.** `BeneficiaryInfoRequest.Address` es `[Required]` con `MinimumLength = 5`. En la ruta BMW el DTO se construye en código (no por model binding), así que hoy esas anotaciones probablemente **no se ejecutan**, pero SIGA aguas abajo puede validar o el campo puede ser `NOT NULL`. Blanco ⇒ riesgo de altas rotas en producción; "FPO" (3 chars) tampoco cumple el mínimo | Media | **Alto** | Usar texto genérico de ≥5 caracteres (`"NO APLICA"`). Cero cambios de código, cero riesgo de validación. Si Aldo exige blanco de verdad, se vuelve un cambio de código con su propia validación |
| **R-2 — Override en la task definition.** Si el valor está sobrescrito por variable de entorno en ECS, cambiar `appsettings.json` no surte efecto y el defecto parecería corregido sin estarlo | Media | Medio | **T-02** lo verifica antes de tocar nada |
| **R-3 — El T&C está enlazado desde fuera.** Si BMW o algún correo apuntan a `/docs/Terminos y condiciones BMW.pdf`, borrarlo deja un 404 | Baja | Bajo | Confirmar con Aldo en T-01; si hay dudas, quitar el enlace de la UI y **conservar** el archivo un ciclo |
| **R-4 — Colisión con el deploy de `gp_3.0_siga_api` en curso.** Hay un checklist de QA abierto y bloqueado en la PR #283, y `build.ps1` ya trae `v0.27` preparado. Reusar esa etiqueta **sobrescribe la imagen de QA en silencio** | **Alta** | **Alto** | Cerrar o desbloquear ese deploy primero; si no, etiqueta **nueva**, nunca la que ya está en vuelo |
| **R-5 — Neutralizar solo la calle no resuelve la queja.** Si el contrato sigue imprimiendo "Lomas de Chapultepec I Sección, CP 11000, CDMX", el cliente puede volver a reportarlo | Media | Medio | **T-01** define el alcance con Aldo antes de implementar |
| **R-6 — El merge dropea archivos en silencio.** Documentado en el `CLAUDE.md` de `bmw_landing`; el borrado de un archivo binario es especialmente propenso a perderse | Baja | Medio | Verificar el diff contra la rama feature después de cada merge, en particular que el PDF siga borrado |

---

## 12. Notas para el programador

1. **No hay folio PRD, y no existe generador.** El paso de registro en BD (`db-sync.md`) usa
   `folio_prd` como llave, y en todo el flujo ese folio es siempre un dato que **"lo indica el
   programador"**: ningún workflow ni script lo genera. En `pm_projects` vive como `prd_id`, cuatro
   dígitos **sin el prefijo `PJ`** y sin secuencia visible (`0164`, `1027`, `4793`, `9626`…), y es el
   mismo número que prefija la carpeta del PRD. Para tener uno real hay que **pedirlo a gestión**.
   **No inventarlo**: el `PJ5120` improvisado para el plan de contratos por distribuidor quedó
   registrado como fila de prueba (unidad "Prueba", nombre "Prueba Juan Carlos") y es exactamente el
   tipo de basura que cuesta rastrear después.
2. **Alcance temporal del cambio 2.** Solo afecta contratos **nuevos**. Los ya emitidos siguen
   diciendo "Sierra Candela 80". Si BMW quiere corregir los existentes, eso es otro trabajo (endoso o
   corrección masiva) y **no está en este plan** — conviene decirlo explícitamente en la respuesta a
   Aldo para no generar expectativa.
3. **Por qué dos ramas con el mismo nombre.** Son dos repos; Git no las relaciona. Se usa el mismo
   nombre para que sean rastreables como un solo cambio, y cada una nace de **su propio `develop`**
   (regla de Engine: nunca desde `pre-qa` ni `qa`).
4. **Orden recomendado:** la Fase 1 (landing) **no depende de nadie** — se puede entregar hoy mismo,
   que es lo que Alexis pidió. La Fase 2 depende de T-01 (respuesta de Aldo) y de R-4 (deploy en
   curso). No retener el cambio 1 esperando el cambio 2.
5. **Urgencia real.** Alexis pidió el 26-ago que se hiciera "el día de hoy". El plan ya arranca con
   un día de retraso: conviene acusar recibo en el hilo hoy mismo, aunque solo entregue la Fase 1.
6. **Sin tests.** `bmw_landing` no tiene suite; la única verificación automática es `pnpm lint`
   (typecheck). Toda la validación real es manual en QA (Fase 3).

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Confirmaciones previas** | Alcance con Aldo + verificación de overrides en ECS | T-01 a T-02 | 0.5 – 1 día *(mayormente espera de un tercero)* | |
| **Fase 1 — Landing: quitar el T&C** | Enlace, catálogo, PDF, bump de versión, commit 1 | T-03 a T-06 | 0.5 día | |
| **Fase 2 — API: dirección por defecto** | `appsettings.json` BMW, verificación de código, versión del servicio, commit 2 | T-07 a T-10 | 0.5 día | |
| **Fase 3 — Validación en QA** | Alta de contrato Física y Moral, PDF, respuesta al correo | T-11 a T-13 | 0.5 – 1 día | |
| **Total proyecto** | | 13 tareas | **~2 – 3 días hábiles** (≈ media semana) | — |
| **Solo P1 (mínimo entregable)** | Fase 1 completa | T-03 a T-06 | **~0.5 día** | — |

> **Notas sobre la tabla:**
> - No hay PRD, así que no hay prioridades P1/P2/P3 heredadas. Se marca como "P1 / mínimo entregable"
>   la Fase 1, que es la única que no depende de terceros y responde sola a la mitad del correo.
> - El rango de la Fase 0 es casi todo **espera**, no trabajo: depende de cuándo conteste Aldo.
> - El esfuerzo neto de desarrollo es de **horas**, no de días. El rango lo dominan las esperas (la
>   respuesta de Aldo) y las validaciones en QA, no la codificación.

> **Riesgo de deadline:** el correo pidió entrega **el 26-ago** y hoy es **27-ago**: el plazo ya
> venció. El alcance completo cabe holgadamente en 2–3 días hábiles con un solo desarrollador —
> **sumar un segundo recurso no comprimiría nada**, porque el camino crítico es la respuesta de Aldo
> (T-01) y el deploy de `gp_3.0_siga_api` que está en vuelo (R-4), no la capacidad de desarrollo.
> **Recomendación: entregar hoy la Fase 1 y acusar recibo en el hilo**, dejando la Fase 2 sujeta a la
> confirmación de alcance. Es lo que convierte un retraso en un avance visible.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
