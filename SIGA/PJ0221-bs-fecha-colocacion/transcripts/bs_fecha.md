
La fecha de colocación no existe en el front: se pone automáticamente y hardcodeada en el back.
El punto exacto — BridgestoneLandingContractRequestFactory.cs:193:
private static ProductInfoRequest BuildProduct(LandingContractProductDefaultsOptions p)
{
    return new ProductInfoRequest
    {
        ...
        StartDate = DateTime.UtcNow.Date,   // ← fecha de colocación, fija a "hoy"
        DurationMonths = p.DurationMonths,
    };
}
Ese StartDate es lo que termina en contrato.fecha_inicio y poliza.fecha_inicio (ContractCreationService.cs:258 y :272) — es decir, la fecha que factura. El registrationDate del front (initialFormData.ts:29) solo se imprime en el PDF local, no viaja a la API. El fecha_creacion de bs_registro lo pone el default de la BD (el INSERT en BridgestoneRegistrationService.cs:246 no lo lista) y es solo auditoría.
La regla que bloquea el pasado — ContractCreationService.cs:427-431:
// Validate start date is not in the past
if (request.Product.StartDate.Date < DateTime.Today)
{
    result.AddError("Contract start date cannot be in the past");
}
Es la única puerta dura. Revisé el core (gp_4.0_siga/VentasService) y no hay otra validación de fecha pasada: lo único que usa fecha_inicio ahí es el traslape de duplicados por VIN (ValidacionVINDuplicado), que no estorba al retroceder días.
2. Los puntos a tocar
Backend (gp_3.0_siga_api, servicio Contracts):
Punto
Qué
CreateBridgestoneLandingContractForm.cs
Agregar campo ContractStartDate (string, yyyy-MM-dd). Precedente exacto: BMW ya lo hace con ProductStartDate (CreateBmwLandingContractForm.cs:103).
BridgestoneLandingContractRequestFactory.cs:190-196
BuildProduct recibe la fecha en vez de hardcodear. Ya existe ParseLandingInvoiceDate / ParseRequiredDate para reusar.
Mismo archivo, BuildAsync
Validar la ventana (3 días + mismo mes) y devolver error en errors — es el lugar natural, ahí ya se acumulan errores de negocio.
ContractCreationService.cs:429
Relajar con la bandera. Aquí va la bandera, no en el factory.
BridgestoneLandingContractDefaultsOptions.cs + appsettings.json:112
Nueva sub-sección con MaxBackdateDays: 3 y AllowCrossMonthBackdate: false. El CLAUDE.md del repo exige que nada quede hardcodeado.
BridgestoneController.cs:537-563
Agregar el campo nuevo al requestData que se serializa a LogRequestAsync (auditoría).
Frontend (este repo):
Punto
Qué
DateInput.tsx
No expone minDate/maxDate. Hay que agregarlos como props — react-datepicker ya los soporta.
InvoicePurchaseSection.tsx:152
Nuevo DateInput "Fecha de colocación" junto a "Fecha Factura".
types.ts:23 + initialFormData.ts
Campo contractStartDate, inicializado en hoy.
validation.ts
Espejo de la regla (el back sigue siendo la autoridad).
sigaService.ts:319
fd.append('ContractStartDate', ...) — ojo: el back espera yyyy-MM-dd, el front hoy manda dd/MM/yyyy para InvoiceDate.
sigaService.ts:419
Etiqueta ES en SIGA_VALIDATION_FIELD_LABEL_ES.
3. Sobre la bandera de BS
ContractCreationService es compartido (BMW, financieras, WhatsApp), así que no puedes relajar la línea 429 en general. Dos opciones:
		Bandera en el request: propiedad AllowBackdatedStartDate en CreateContractRequest, que solo el factory de BS pone en true. Simple, pero un consumidor externo podría mandarla.
		Bandera por proyecto/canal (la que recomiendo): ContractCreationService ya recibe projectId y consulta proyecto (línea 73). Una opción de config con la lista de proyectos que permiten retroactividad y sus límites — no es manipulable desde el request y sirve igual si mañana BMW lo pide.
4. Dos cosas que hay que decidir antes de codear
a) Bug preexistente de zona horaria — relevante justo para tu problema de facturación. El contenedor corre en America/Mexico_City (Dockerfile:5), pero StartDate se calcula con DateTime.UtcNow.Date mientras la validación usa DateTime.Today (local). México está en UTC-6 sin DST, así que de las 18:00 h en adelante UtcNow.Date ya es mañana. Un contrato colocado el 31 de enero a las 19:00 hoy ya se está guardando con fecha_inicio = 1 de febrero — exactamente el cruce de mes que quieren evitar. Hay que unificar todo a hora local (DateTime.Today) como parte de este cambio.
b) El flujo de reanudación. RegeneratePendingContract (BridgestoneController.cs:720) reconstruye el contrato desde bs_registro y llama al mismo BuildProduct, así que también se pone hoy. Pero bs_registro no guarda la fecha solicitada (no hay columna) y BridgestoneRegistroSnapshot no la trae. Si un registro queda pendiente el 31 y se reanuda el 2 del mes siguiente, la fecha original ya es inválida. Hay que definir: ¿se agrega columna y se respeta la fecha original mientras siga en la ventana, o la reanudación siempre usa hoy?

