# Plan de Desarrollo — BMW: Uso del CFDI capturable en la landing

> Generado por Claude Code. Se cuelga del PRD **PJ4793 (BMW — paquete de cambios ago-2026)**, bloque de
> facturación: es la continuación natural del pendiente que el propio código dejaba anotado
> (*"elegir el uso según el régimen del receptor para que el cliente pueda deducir"*).

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ4793-bmw-cambios-ago-2026/PRD.md` |
| Repositorios | `bmw_landing` (front) · `gp_3.0_siga_api` (Contracts, Catalogs, ApiGateway) |
| Rama | `feature/PJ4793-bmw-uso-cfdi` (creada en ambos repos, derivada de `develop`) |
| Tipo | Feature |
| Responsable | Juan Carlos Castellanos Solis *(a confirmar)* |
| Folio PRD | PJ4793 |
| Fecha de generación | 2026-08-20 |
| Estado | En ejecución — implementado, pendiente de pruebas del programador |
| ID plan (BD) | *(sin registrar: el plan no se ha commiteado ni autorizado)* |

---

## 1. Resumen técnico

Hoy la landing BMW captura **CP fiscal** y **régimen fiscal**, pero el **uso del CFDI** es fijo: sale de
`BmwBilling:<Modalidad>:UsoCfdiClave` en el `appsettings` de Contracts (`S01` en las tres modalidades) y el
cliente no puede elegirlo, así que nunca puede deducir la garantía. Este cambio lo vuelve capturable
punta a punta.

Componentes tocados:

- **Front (`bmw_landing`)** — tercer campo en el bloque de datos fiscales de *Datos del Cliente*. La lista de
  usos se pide al API según el régimen capturado, con espejo estático de respaldo.
- **API Catalogs** — endpoint público nuevo `GetCfdiUses`, que lee la matriz del SAT que **ya existe en la
  BD** (`uso_cfdi_regimen_fiscal`) — la misma que usa SIGA en su pantalla de captura
  (`ContratosController.BuscaUSOCFDI`).
- **API Contracts** — el uso viaja en el multipart, se guarda en `bmw_registro.uso_cfdi` y sustituye la clave
  fija de la modalidad al escribir `fiscales_poliza.uso_cfdi` (lo que se timbra). También alinea el
  `orden_pago.id_usocfdi` de la ODP, que estaba desfasado.
- **ApiGateway (KrakenD)** — alta del endpoint nuevo; sin esto responde 404 en QA/PROD.
- **BD** — una columna nueva en `bmw_registro`.

**Decisión de diseño central:** el uso NO se ofrece libre. El SAT valida la pareja (uso, régimen) y el PAC
rechaza con `CFDI40161`; ya pasó una vez al intentar `G03` con régimen 605. Como la matriz del SAT ya está en
la BD, se reutiliza en lugar de inventarla: el desplegable solo ofrece lo que el régimen admite, y el API
revalida la pareja antes de escribirla (el multipart se puede postear directo).

---

## 2. Prerequisitos

- [x] `CLAUDE.md` presente en ambos repos
- [x] Matriz `uso_cfdi_regimen_fiscal` poblada en la BD (19 regímenes verificados)
- [x] Ramas `feature/PJ4793-bmw-uso-cfdi` derivadas de `develop` actualizado
- [ ] Script `db_bmw/20_uso_cfdi_bmw_registro.sql` aplicado en QA y PROD (ya aplicado en local)
- [ ] Redeploy de **Catalogs** y **ApiGateway** en QA y PROD (endpoint nuevo)

---

## 3. Arquitectura del cambio

```
[Landing /registro]
   │  GET  /catalogs/api/TaxCatalogs/v1/GetCfdiUses?taxRegime=605   (público)
   │        └── uso_cfdi_sat ⨝ uso_cfdi_regimen_fiscal   ← matriz SAT ya existente
   │
   └─ POST /contracts/api/Bmw/v1/206/contracts  (multipart, campo FiscalCfdiUse)
          │
          ├── bmw_registro.uso_cfdi              ← snapshot de lo capturado
          ├── fiscales_poliza.uso_cfdi           ← lo que se TIMBRA (revalidado vs la matriz)
          └── orden_pago.id_usocfdi              ← ODP, traducido clave → id del catálogo
```

Precedencia al escribir `fiscales_poliza.uso_cfdi`:

1. Público en general → `S01` forzado (regla del SAT, no se toca).
2. Uso capturado, **si** la pareja (uso, régimen) existe en la matriz.
3. Clave de la modalidad en `BmwBilling` (queda como *fallback*, ya no como valor único).

---

## 4. Tareas de desarrollo

### Fase 1 — Catálogo y contrato de datos (API)

- [x] **T-01** — Endpoint público `GetCfdiUses`
  - `Services/Catalogs/DTOs/CfdiUses/CfdiUseResponse.cs` (nuevo)
  - `Services/Catalogs/Controllers/TaxCatalogsController.cs`
  - SQL crudo (la matriz no tiene entidad EF; mapearla obligaría a tocar `DataAccess` **y** espejarla en
    `DataAccessColombia` por una tabla de dos columnas). Parámetro `@regimen` **tipado** (`NpgsqlDbType.Integer`):
    un `DBNull` sin tipo en un `@p IS NULL` truena con `42P08`.
  - Criterio: `?taxRegime=605` devuelve solo `S01`; `?taxRegime=612` devuelve `G01..I08 + S01`, con `S01` primero.

- [x] **T-02** — Alta del endpoint en KrakenD
  - `Services/ApiGateway/krakend.json`
  - Criterio: el JSON sigue siendo válido y el endpoint responde 200 tras el redeploy.

- [x] **T-03** — Columna en BD
  - `bmw_landing/db_bmw/20_uso_cfdi_bmw_registro.sql` (nuevo, idempotente)
  - `bmw_registro.uso_cfdi varchar(5)` nullable, sin FK (mismo criterio que `cp_fiscal` / `regimen_fiscal`:
    es una foto de lo capturado y no debe romperse si el catálogo cambia).
  - Criterio: aplicado en local ✅; pendiente QA y PROD.

### Fase 2 — Persistencia y facturación (API Contracts)

- [x] **T-04** — El campo entra por el multipart
  - `DTOs/Bmw/Requests/CreateBmwLandingContractForm.cs`, `DTOs/Bmw/BmwRegistrationPayload.cs`,
    `Services/Bmw/BmwLandingContractRequestFactory.cs`
  - Criterio: `FiscalCfdiUse` llega normalizado (trim + mayúsculas) o `null`.

- [x] **T-05** — Guardar el snapshot
  - `Services/Bmw/BmwRegistrationService.cs` (INSERT de `bmw_registro`)
  - Criterio: un alta con datos fiscales deja `uso_cfdi` poblado; sin datos fiscales, `NULL`.

- [x] **T-06** — Resolver el uso al facturar, con revalidación contra la matriz
  - `Services/Bmw/BmwPaymentService.Billing.cs` → `ResolveCfdiUseClaveAsync` + `IsCfdiUseValidForRegimeAsync`
  - `Services/Bmw/BmwPaymentService.cs` (Contado), `Interfaces/IBmwPaymentService.cs`
  - Una pareja incongruente **se descarta con warning** y se conserva la clave de la modalidad: escribirla
    dejaría el contrato sin comprobante por rechazo del PAC.
  - Criterio: las tres modalidades (Contado, Enganche, Financiado/Financiamiento externo) escriben el uso
    capturado cuando aplica.

- [x] **T-07** — Alinear la ODP
  - `Controllers/BmwController.cs` + `ResolveContractCfdiUseIdAsync`
  - La ODP guarda el **id** del catálogo, no la clave. Cierra el desfase que había: `fiscales_poliza` decía
    `S01` y la ODP `G03` (id 3) por `appsettings`.
  - El uso de la ODP se lee de `fiscales_poliza` (fuente de verdad del receptor) y se resuelve DESPUÉS de
    facturar. La primera implementación traducía la clave capturada y dejaba la ODP desalineada cuando el
    receptor acababa siendo el público en general — ver §12-bis, defecto encontrado en pruebas.
  - Criterio: con uso capturado, `orden_pago.id_usocfdi` coincide con `fiscales_poliza.uso_cfdi` **en todos**
    los caminos, incluido el reintento a público en general.

- [x] **T-08** — Actualizar la documentación del `appsettings`
  - `Options/BmwBillingOptions.cs`: `UsoCfdiClave` pasa de valor único a *fallback*, y se cierra el
    "PENDIENTE" que el propio comentario dejaba anotado.

### Fase 3 — Captura en la landing

- [x] **T-09** — Espejo estático del catálogo (respaldo del endpoint)
  - `src/constants/satUsoCfdi.ts` (nuevo), mismo patrón que `satRegimenFiscal.ts`
- [x] **T-10** — Cliente del endpoint
  - `src/services/sigaService.ts` → `fetchCfdiUses` + `CfdiUseItem`
- [x] **T-11** — Campo en la UI
  - `src/features/warranty-registration/sections/ClientDataSection.tsx`
  - Arranca **vacío** (igual que CP y régimen), deshabilitado hasta que haya régimen, con `S01 - Sin efectos
    fiscales` primero en la lista y anunciado como sugerido en el placeholder y en la nota del bloque.
  - Se limpia solo si cambia el régimen (o el tipo de persona tumba el régimen) y el uso ya no aplica.
- [x] **T-12** — Validación y envío
  - `validation.ts` (trío todo-o-nada + red de congruencia uso/régimen), `types.ts`, `initialFormData.ts`,
    `lib/buildBmwContractFormData.ts`
- [x] **T-13** — Bump de versión: `v1.0.15` → `v1.0.16` en `.env`, `.env.qa`, `.env.production`

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `bmw_registro` | Modificación | `+ uso_cfdi varchar(5)` nullable, con `COMMENT`. Script `db_bmw/20_uso_cfdi_bmw_registro.sql`, idempotente. Solo México. |
| `uso_cfdi_sat` | **Ninguno** | Decisión explícita: sembrar los usos de deducciones personales (D01–D10) afectaría a **todos** los proyectos, no solo a BMW. Es decisión de Contabilidad. |
| `uso_cfdi_regimen_fiscal` | **Ninguno** | Ya existe y ya está poblada; solo se lee. |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/catalogs/api/TaxCatalogs/v1/GetCfdiUses?taxRegime={clave}` | Usos del CFDI que admite un régimen. Público (`AllowAnonymous`), rate limit `Heavy`. | Nuevo |
| POST | `/contracts/api/Bmw/v1/{projectId}/contracts` | Acepta el campo `FiscalCfdiUse` (opcional) en el multipart. | Modificado |

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `VITE_APP_VERSION` | `v1.0.15` → `v1.0.16` | Local / QA / Producción |
| `BmwBilling:*:UsoCfdiClave` | Sin cambio de valor; cambia de rol: ahora es *fallback*. | Local / QA / Producción |

---

## 8. Consideraciones de seguridad

- El endpoint nuevo es **público** igual que `GetTaxRegimes` (alimenta un desplegable de la landing, que se
  usa antes de autenticarse). No expone datos de clientes: solo el catálogo del SAT. Lleva rate limit `Heavy`.
- El uso capturado **no se confía**: el API lo revalida contra la matriz del SAT antes de escribirlo, porque
  el multipart se puede postear directo saltándose la UI.
- SQL parametrizado en las dos consultas crudas nuevas.

---

## 9. Consideraciones de infraestructura

- Redeploy de **Catalogs** (endpoint) y **ApiGateway** (KrakenD) en QA y PROD; sin el segundo, 404.
- Redeploy de **Contracts** (persistencia + facturación).
- ⚠️ Al reetiquetar imágenes, revisar que la etiqueta de ECR no sobreescriba la de QA
  (`git diff --stat release origin/pre-qa -- Services/<X>/`).
- Sin servicios AWS nuevos, sin costo adicional.

---

## 10. Criterios de aceptación

- [ ] Con régimen **605**, el desplegable ofrece únicamente `S01`.
- [ ] Con régimen **612** o **626**, ofrece `G01..I08 + S01`, con `S01` primero.
- [ ] Cambiar el régimen a uno que no admite el uso elegido lo limpia (no queda una pareja inválida).
- [ ] Enviar solo CP, solo régimen o solo uso marca error en los otros dos (trío todo-o-nada).
- [ ] Alta de **Contado** con `G03` + régimen 612 → `fiscales_poliza.uso_cfdi = 'G03'`, timbra, y el CFDI trae
      `UsoCFDI="G03"`.
- [ ] La ODP de ese mismo contrato queda con `id_usocfdi = 3` (G03), no desfasada.
- [ ] Alta **sin** datos fiscales → público en general con `S01`, comportamiento idéntico al actual.
- [ ] Alta de **Enganche** y **Financiado** con uso capturado → mismo resultado que Contado.
- [ ] `bmw_registro.uso_cfdi` guarda lo capturado; los registros históricos siguen en `NULL`.
- [ ] Si Catalogs no responde, el desplegable sigue funcionando con el catálogo estático.
- [ ] `pnpm lint` limpio (✅ verificado) y `dotnet build` limpio en los 3 servicios (pendiente: lo compila el
      programador).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El endpoint no se registra en KrakenD → 404 y el desplegable queda vacío | Media | Medio | Alta ya incluida en `krakend.json`; además hay espejo estático que cubre el fallo |
| El script no se aplica en QA/PROD → el INSERT de `bmw_registro` truena y no se pueden dar altas | Media | **Alto** | Está en los prerequisitos y en la cabecera del `.sql`; verificar antes del redeploy de Contracts |
| Régimen 605 solo puede facturar con `S01` (D01–D10 no sembrados) | Alta | Bajo | Es correcto para el SAT; si negocio quiere deducciones personales, es un cambio de catálogo global aparte |
| El espejo estático se desincroniza de la matriz de la BD | Baja | Bajo | El endpoint manda; el estático solo actúa si el API falla. La revalidación del API es la que decide |
| Público en general: la ODP sigue cayendo al default `G03` mientras `fiscales_poliza` queda en `S01` | Media | Bajo | Desfase **preexistente**, fuera de este alcance. Anotado abajo |

---

## 12. Notas para el programador

1. **Sobre el valor por defecto.** El pedido original decía *"el valor por defecto sugerido debe ser sin
   efectos fiscales"* y luego se pidió *"déjalo vacío, que siga el mismo comportamiento que los otros"*. Se
   resolvió así: el campo **arranca vacío** y es obligatorio solo cuando se capturan los otros dos datos
   fiscales, y `S01 - Sin efectos fiscales` va **primero en la lista**, anunciado como sugerido en el
   placeholder y en la nota del bloque. Si prefieres que venga preseleccionado con `S01`, es un cambio de una
   línea en `initialFormData.ts`.
2. **Sin datos fiscales no cambia nada.** El camino de público en general sigue forzando `S01` porque lo exige
   el SAT para el RFC genérico. El uso capturado solo aplica cuando el receptor es el cliente.
3. **Desfase preexistente que NO se tocó:** cuando el comprobante sale a público en general,
   `fiscales_poliza.uso_cfdi = S01` pero la ODP se queda con el default `G03` de
   `BmwBilling:PaymentOrder:UsoCfdiId`. Con uso capturado ya quedan alineados; sin captura, el desfase sigue.
   Alinearlo es un cambio de configuración (id 12 = `S01`), no de código.
4. **No compilé los servicios** (lo haces tú). El typecheck del front sí: `pnpm lint` limpio.
5. **Nada commiteado.** Ambas ramas están creadas y con los cambios en el working tree, sin commit y sin push.
6. La columna ya está aplicada en la **BD local** para que puedas probar de inmediato.

---

## 12-bis. Resultados de pruebas (2026-08-20, entorno local con BD restaurada de PROD)

### Matriz de altas reales — 10/10 concluyentes

Evidencia clave: el RFC de prueba es falso, así que el PAC **siempre** rechaza el primer intento y entra el
reintento a público en general. Por eso el uso capturado se comprueba en la fila de `factura` del PRIMER
intento (receptor = el cliente), no en `fiscales_poliza` al final. Cada variante llevó RFC único para poder
atribuir su factura sin ambigüedad.

| # | Modalidad | Régimen | Uso enviado | `bmw_registro.uso_cfdi` | Uso en el CFDI al cliente | Resultado |
|---|---|---|---|---|---|---|
| 1 | Financiado | 612 | `G03` | `G03` | **`G03`** | ✅ |
| 21 | Contado | 612 | `I03` | `I03` | **`I03`** + ODP `id_usocfdi=5` | ✅ |
| 22 | Enganche | 612 | `I03` | `I03` | **`I03`**, sin ODP | ✅ |
| 13 | Financiamiento externo | 626 | `G01` | `G01` | **`G01`** | ✅ |
| 14 | Financiado (P. Moral) | 601 | `G03` | `G03` | **`G03`** | ✅ |
| 15 | Financiado | 605 | `G03` | `G03` | `S01` (descartado) | ✅ |
| 16 | Financiado | 616 | `G03` | `G03` | `S01` (descartado) | ✅ |
| 17 | Financiado | *(sin CP/régimen)* | `G03` | `G03` | público general `S01` | ✅ |
| 18 | Financiado | 612 | `g03` minúsculas | `G03` | **`G03`** | ✅ |
| 19 | Financiado | 612 | `ZZZ` | `ZZZ` | `S01` (fallback) | ✅ |
| 20 | Financiado | *(nada)* | — | `NULL` | público general `S01` | ✅ |

Contraste antes/después: los 9 CFDI de BMW que ya existían en la BD de producción traen **todos** `S01`, el
valor fijo del `appsettings`.

### Casos de interfaz — 10/10 (2026-08-21, Playwright sobre `localhost:5173`)

| # | Caso | Resultado observado |
|---|---|---|
| 1 | El campo nace vacío y bloqueado | `react-select__control--is-disabled`, placeholder «Elige primero el régimen fiscal…» |
| 2 | Se habilita con el régimen | 11 opciones con `S01` primero; placeholder «Sugerido: S01 - Sin efectos fiscales…» |
| 3 | Régimen 605 | una sola opción: `S01` |
| 4 | Régimen 616 | `S01` y `G02` |
| 5 | Cambiar régimen limpia un uso incompatible | `G03` + cambio a 605 → el uso se vacía solo |
| 6 | Cambiar tipo de persona | Moral/601/`G03` → Física deja régimen **y** uso vacíos, y el uso vuelve a bloquearse |
| 7 | Trío todo-o-nada | solo CP → «Selecciona el régimen fiscal para poder facturar»; CP+régimen sin uso → «Selecciona el uso del CFDI (si no aplica, usa S01 - Sin efectos fiscales)»; los tres vacíos → pasa sin error |
| 8 | Llamada al catálogo | `GET /catalogs/api/TaxCatalogs/v1/GetCfdiUses?taxRegime=612` → 200, una vez por cambio de régimen y **siempre** con el parámetro |
| 9 | Respaldo estático | con `GetCfdiUses` interceptado y fallando, el desplegable sigue ofreciendo los 11 correctos |
| 10 | Alta completa desde la UI | contrato 821803 (Care Plus, Financiamiento externo, 24 meses, régimen 626, uso `G01`): `bmw_registro.uso_cfdi = G01` y la factura al cliente salió con `G01/626` |

Línea base también desde la UI (contrato 821802, sin datos fiscales): `uso_cfdi` NULL y receptor público
general `S01`/616 — comportamiento previo intacto.

Nota menor, preexistente y ajena al cambio: la consola tira un warning de React por el prop `countryIso`
que `PhoneInput` reenvía al DOM. No afecta nada, pero está ahí.

### Otras verificaciones

- **Endpoint `GetCfdiUses`**: 605→`S01`; 616→`S01,G02`; 601/612/626→`S01` primero + `G01,G02,G03,I02..I08`;
  régimen inexistente→`[]` sin error. CORS `*` presente.
- **Espejo estático vs BD**: 19/19 regímenes coinciden **exactamente** (verificado en local).
- **Lógica pura del front**: 25/25 (trío todo-o-nada, pareja incongruente, minúsculas, espacios, clave
  inexistente, persona moral).
- **Guard de longitud**: un uso de 6 caracteres devuelve `400` con el mensaje del DTO y **sin** dejar fila en
  `bmw_registro`.
- `pnpm lint` limpio.

### 🔴 Defecto encontrado en pruebas y CORREGIDO

**La ODP se quedaba con el uso capturado aunque el receptor terminara siendo el público en general.**

Reproducido en la variante 21 (Contado, régimen 612, uso `I03`): el PAC rechazó el primer intento, el
reintento reescribió `fiscales_poliza` a `S01`/616/`XAXX010101000`, pero `orden_pago.id_usocfdi` se quedó en
`5` (`I03`). El 616 **no admite** `I03`, y la factura de la ODP se construye con su propio uso —
`FacturacionGarantiplus/Infrastructure/Data/Classes/RepositoryMX.cs:1170` hace
`INNER JOIN uso_cfdi_sat ucf ON (op.id_usocfdi=ucf.id_usocfdi)` y **no lee `fiscales_poliza`** — así que esa
ODP, al facturarse, habría nacido con la pareja que el PAC rechaza con `CFDI40161`. Alcanzable desde la
landing: basta cualquier rechazo del PAC.

**Corrección aplicada:** se eliminó `ResolveCfdiUseIdAsync(clave, régimen)` y se sustituyó por
`ResolveContractCfdiUseIdAsync(contractId)`, que lee el uso **ya escrito en `fiscales_poliza`** y lo traduce a
id de catálogo. Se invoca justo antes de crear la ODP (después de facturar), no al inicio del bloque, de modo
que refleja todas las reescrituras. Efecto colateral bueno: también corrige el desfase **preexistente** en el
que un Contado sin datos fiscales generaba la ODP con `G03` (default del `appsettings`) contra un receptor 616.

✅ **Verificado tras recompilar Contracts** (2026-08-20 21:34). Mismo escenario, mismos insumos:

| | contrato | `fiscales_poliza` | `orden_pago.id_usocfdi` |
|---|---|---|---|
| Antes del fix | 821798 | `S01` / 616 | `5` = `I03` ❌ |
| Después del fix | 821800 | `S01` / 616 | `12` = `S01` ✅ |

El `12` tampoco es el default del `appsettings` (`3`), así que no está cayendo al fallback: leyó la tabla.
Junto con la corrida previa —que probó la traducción clave→id con una clave distinta del default (`I03`→5)—
queda demostrado que el id sale de `fiscales_poliza`, bien traducido, y no es ni el capturado ni el default.
Traza de facturas: `I03/612(rechazada) → S01/616(SELLADA)`.

Smoke posterior de la ruta de facturación (contrato 821801, Financiado, régimen 626, uso `G01`): el CFDI al
cliente salió con `G01/626` y sin ODP, o sea el refactor no tocó el camino de facturación.

### Hallazgos que NO son de este cambio (preexistentes)

1. **`DiscardPendingRegistrationAsync` reutiliza el `CancellationToken` ya cancelado**
   (`BmwRegistrationService.cs:270`), así que la compensación falla justo en el único escenario para el que
   existe. Se reprodujo con 6 altas concurrentes: 8 contratos quedaron partidos en dos mitades
   (`bmw_registro.id_contrato` NULL + contrato invisible para la landing, que nunca se facturará). El rollback
   debería correr con `CancellationToken.None` o un token con deadline propio.
2. **Con `ContadoEnableOpenPay=false`** —el estado acordado para PROD antes de la carga Allianz—
   `ApplyContadoBeneficiaryBillingAsync` no se llama, y es la única ruta que escribe CP fiscal, régimen y uso
   para Contado. O sea: en PROD tal como está decidido, el uso capturado **no tendrá efecto en Contado**.
   Aplica igual al CP y al régimen, que ya estaban antes. Es decisión de negocio, no defecto del cambio.
3. **La modalidad fuera de la whitelist** (`BmwController.cs:1916`, sin `else`) crea el contrato con 201 sin
   facturar y sin ODP, en silencio. Relevante para la carga Allianz, donde `PaymentModality` viene de un Excel.
4. **La validación de congruencia ignora el tipo de persona.** `CFDI40161` depende de (uso, régimen, tipo de
   persona) y sólo se valida la pareja (uso, régimen). Desde la landing lo tapa el filtro de régimen por tipo
   de persona; por POST directo no.

### Decisión pendiente para el programador

Una clave inexistente (`ZZZ`) hoy se acepta con 201 y se persiste en `bmw_registro.uso_cfdi`, degradando el
comprobante a `S01` en silencio. Conviene distinguir dos casos: pareja *existente pero incompatible* (degradar
es defendible) vs **clave que no existe en `uso_cfdi_sat`**, que sólo puede venir de un bug del front o de una
integración mal armada y que quizá debería ser `400`. Queda a tu criterio.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 1 — Catálogo y contrato de datos** | Endpoint `GetCfdiUses`, alta en KrakenD, columna en BD | T-01 a T-03 | 0.5 – 1 día | |
| **Fase 2 — Persistencia y facturación** | Multipart, `bmw_registro`, resolución del uso con revalidación, ODP alineada | T-04 a T-08 | 1 – 1.5 días | |
| **Fase 3 — Captura en la landing** | Espejo estático, cliente del endpoint, campo, validación, bump | T-09 a T-13 | 0.5 – 1 día | |
| **Total proyecto** | | 13 tareas | ~2 – 3.5 días hábiles (≈ 0.5 semana) | — |
| **Solo P1** | Fase 1 + Fase 2 + Fase 3 | T-01 a T-13 | ~2 – 3.5 días hábiles | — |

> **Notas sobre la tabla:** el alcance completo es P1 — el cambio no se puede partir: sin el front no hay
> captura, sin el back no se procesa y sin la columna no se guarda. La implementación ya está hecha; los
> rangos de arriba reflejan el esfuerzo total incluyendo pruebas en QA.
>
> **Riesgo de deadline:** ninguno. Este plan se cuelga del bloque de facturación de PJ4793, que ya está
> desplegado; el cambio es aditivo y no bloquea nada del paquete original. Un solo desarrollador es
> suficiente.

---

*Generado por Claude Code — Engine CX*
