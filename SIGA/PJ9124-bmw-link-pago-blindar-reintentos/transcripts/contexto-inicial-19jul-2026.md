# Contexto inicial — Link de pago + blindar reintentos (BMW)

Origen: acuerdo entre Carlos Castellanos y Claude el 19-jul-2026, durante el cierre de la feature
de precios Care Plus / estatus de pago. El tema se difirió al regreso de vacaciones de Carlos por
tratarse de zona de pagos sensible. Se retoma el 27-jul-2026.

## Problema

Los cargos de OpenPay son de **un solo uso**: un cargo denegado o cancelado no se puede reintentar
— reabrir su URL `card_capture` siempre muestra "Transacción denegada".

Hoy en la landing BMW, una vez que el contrato tiene guardado `contrato.link_pago_pasarela`, el
botón "Ir a pagar (tarjeta)" de `CreatedContractsView` **reabre ese link guardado** (el cargo viejo,
posiblemente muerto) → el cliente queda atorado, sin manera de generar un cargo nuevo.

Ocurrió en una demo real en PROD (contrato 796211).

En la sesión del 19-jul se implementó un "fix de reintento" interino (el modal generaba un cargo
nuevo en cada clic y lo abría), pero se **REVIRTIÓ** por decisión de Carlos: proliferaban links.
Por lo tanto nada cambió en el flujo de pago y el bug original sigue vivo.

## Lo que se quiere (UX estilo SIGA, pero mejor)

En SIGA existe un "Link de pago" en el detalle del contrato (muestra el link + copiar). Se quiere
replicar en la landing con mejor UI/UX:

- Mostrar el link de pago del contrato con botón **COPIAR** (para compartirlo al cliente) y
  **ABRIR / Ir a pagar** (nueva pestaña).
- **Reutilizar/persistir** el link: que no se genere uno nuevo en cada clic.
- **BLINDAR**: que al regenerar, el cargo anterior deje de ser pagable, para evitar cargos pagables
  duplicados y el riesgo de doble cobro (alguien pagando dos pestañas viejas).

## Decisión pendiente — nivel de blindaje

- **(A) Ligero — solo landing/API:** reusar el link vigente; regenerar solo con acción explícita;
  apoyarse en el endpoint `GetPaymentStatus` (ya desplegado) para saber si el cargo actual sigue
  pendiente (reusar) o fue rechazado/expiró (ofrecer regenerar). NO cancela en OpenPay: si el
  usuario regenera a propósito, el cargo anterior sigue vivo hasta expirar (borde: pagar dos
  pestañas). No toca `gp_4.0_siga`.
- **(B) Robusto — toca `gp_4.0_siga`/OpenpayGP:** antes de generar uno nuevo, **cancelar el cargo
  OpenPay anterior** (DELETE charge) → solo un cargo pagable a la vez. Requiere endpoint de cancel
  en OpenpayGP (que tiene las credenciales de OpenPay) y su deploy. Cierra el doble cobro por
  completo.

## Anclas técnicas conocidas

- **Landing (`bmw_landing`):** `src/components/BmwPaymentModal.tsx` (genera el link vía
  `bmwSiga.generatePaymentLink(contractId,{paymentType:1})`);
  `src/features/warranty-registration/views/CreatedContractsView.tsx` → `ContractPaymentCell`
  (el botón de Contado usa `row.paymentLink` = `contrato.link_pago_pasarela` para reabrir);
  `src/services/sigaService.ts` → `generatePaymentLink` y `getPaymentStatus(reference)`
  (este último ya existe y funciona).
- **API (`gp_3.0_siga_api`):** `BmwController.GeneratePaymentLink` →
  `BmwPaymentService.GeneratePaymentLinkAsync` → `_ventasBr.GetPaymentGatewayLink`.
- **`gp_4.0_siga`:** `PaisesService/Pasarela/Classes/PaymenGatewayOpenPay.cs` — `RequestPaymentLink`
  crea un cargo NUEVO en cada llamada (uuid de pasarela nuevo); `ValidateRequest` solo bloquea si ya
  está pagado o en orden de pago; `PersistPaymentLink` sobrescribe `contrato.uuid_pago_openpay` y
  `link_pago_pasarela`. Para cancelar: `PasarelaPagos/OpenpayGP` (servicio legacy en :5000, tiene las
  credenciales de OpenPay). El estatus de los cargos lo escribe `Pagos/Classes/WebhookOpenpay.cs` en
  `pago_pasarela` (Aprobado/Rechazado, por `referencia` = order_id = uuid).

## Restricciones acordadas

- Es zona de pagos: validar en QA antes de PROD, con Carlos presente.
- Rama `feature/cc_*` desde develop (`git fetch -p` + pull), sin commit hasta que Carlos revise.
- Claude no aprueba ni mergea PRs.
