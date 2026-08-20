# Condensado — bs_fecha (análisis técnico previo, fecha de colocación BS)

> Origen: `bs_fecha.docx` en el escritorio del desarrollador; texto extraído y archivado como
> `manager/transcripts/bs_fecha.md` (el flujo de PRD no admite `.docx`).

## Decisiones
- El campo que representa la **fecha de colocación** (la que factura) es `StartDate`, hoy
  **hardcodeado a `DateTime.UtcNow.Date`** en `BridgestoneLandingContractRequestFactory.cs:193`
  (`BuildProduct`). Termina en `contrato.fecha_inicio` y `poliza.fecha_inicio`
  (`ContractCreationService.cs:258` y `:272`).
- **Descartados** como campo objetivo: `bs_registro.fecha_creacion` (default de BD, solo
  auditoría; el INSERT de `BridgestoneRegistrationService.cs:246` no lo lista) y
  `registrationDate` del front (`initialFormData.ts:29`, solo se imprime en el PDF local, no
  viaja a la API).
- La **fecha de colocación NO existe en el front**: hay que agregarla.
- Única validación dura que bloquea el pasado: `ContractCreationService.cs:427-431`
  (`request.Product.StartDate.Date < DateTime.Today` → "Contract start date cannot be in the
  past"). Se revisó el core (`gp_4.0_siga/VentasService`) y no hay otra validación de fecha
  pasada; lo único que usa `fecha_inicio` ahí es el traslape por VIN
  (`ValidacionVINDuplicado`), que no estorba al retroceder días.
- Precedente a reusar: **BMW ya expone la fecha** vía `ProductStartDate`
  (`CreateBmwLandingContractForm.cs:103`); existen `ParseLandingInvoiceDate` /
  `ParseRequiredDate` para el parseo.
- El `CLAUDE.md` del repo **exige que nada quede hardcodeado** → la ventana va a configuración.

## Alcance / requerimientos
**Backend (`gp_3.0_siga_api`, servicio Contracts):**
- `CreateBridgestoneLandingContractForm.cs` — agregar campo `ContractStartDate` (string,
  `yyyy-MM-dd`).
- `BridgestoneLandingContractRequestFactory.cs:190-196` — `BuildProduct` recibe la fecha en vez
  de hardcodearla.
- Mismo archivo, `BuildAsync` — validar la ventana (3 días + mismo mes) y devolver el error en
  `errors` (ahí ya se acumulan errores de negocio).
- `ContractCreationService.cs:429` — relajar la validación **con la bandera** (aquí va la
  bandera, no en el factory).
- `BridgestoneLandingContractDefaultsOptions.cs` + `appsettings.json:112` — nueva sub-sección
  con `MaxBackdateDays: 3` y `AllowCrossMonthBackdate: false`.
- `BridgestoneController.cs:537-563` — agregar el campo nuevo al `requestData` que se serializa
  a `LogRequestAsync` (auditoría).

**Frontend (repo del landing de BS):**
- `DateInput.tsx` — no expone `minDate`/`maxDate`; agregarlos como props (react-datepicker ya
  los soporta).
- `InvoicePurchaseSection.tsx:152` — nuevo `DateInput` "Fecha de colocación" junto a
  "Fecha Factura".
- `types.ts:23` + `initialFormData.ts` — campo `contractStartDate`, inicializado en hoy.
- `validation.ts` — espejo de la regla (el back sigue siendo la autoridad).
- `sigaService.ts:319` — `fd.append('ContractStartDate', ...)`. **Ojo:** el back espera
  `yyyy-MM-dd` y el front hoy manda `dd/MM/yyyy` para `InvoiceDate`.
- `sigaService.ts:419` — etiqueta ES en `SIGA_VALIDATION_FIELD_LABEL_ES`.

## Riesgos / pendientes
- **Bandera de BS.** `ContractCreationService` es compartido (BMW, financieras, WhatsApp), así
  que no se puede relajar la línea 429 en general. Dos opciones:
  1. Bandera en el request (`AllowBackdatedStartDate` en `CreateContractRequest`, la pone solo
     el factory de BS): simple, pero un consumidor externo podría mandarla.
  2. **(Recomendada)** Bandera por proyecto/canal: `ContractCreationService` ya recibe
     `projectId` y consulta `proyecto` (línea 73). Config con la lista de proyectos que permiten
     retroactividad y sus límites — no manipulable desde el request y sirve si mañana BMW lo pide.
- **Bug preexistente de zona horaria (agrava el problema de facturación).** El contenedor corre
  en `America/Mexico_City` (`Dockerfile:5`), pero `StartDate` usa `DateTime.UtcNow.Date` mientras
  la validación usa `DateTime.Today` (local). México es UTC-6 sin DST → de las 18:00 h en
  adelante `UtcNow.Date` ya es mañana. Un contrato colocado el **31 de enero a las 19:00 hoy ya
  se guarda con `fecha_inicio` = 1 de febrero** — exactamente el cruce de mes que se quiere
  evitar. Hay que unificar todo a hora local (`DateTime.Today`) como parte de este cambio.
- **Flujo de reanudación.** `RegeneratePendingContract` (`BridgestoneController.cs:720`)
  reconstruye el contrato desde `bs_registro` y llama al mismo `BuildProduct`, así que también
  se pone "hoy". Pero `bs_registro` **no guarda la fecha solicitada** (no hay columna) y
  `BridgestoneRegistroSnapshot` no la trae. Si un registro queda pendiente el 31 y se reanuda el
  2 del mes siguiente, la fecha original ya es inválida. **Pendiente de decidir:** ¿se agrega
  columna y se respeta la fecha original mientras siga en la ventana, o la reanudación siempre
  usa hoy?
