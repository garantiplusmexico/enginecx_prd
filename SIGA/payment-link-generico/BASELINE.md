# Baseline — comportamiento actual de `payment-link` de BMW (T-01)

> Fase 0 del plan. Congela lo que hace HOY `POST /contracts/api/Bmw/v1/{projectId}/contracts/{contractId}/payment-link`,
> para poder comparar contra esto cuando BMW pase a ser wrapper del endpoint genérico (T-13).
>
> Levantado el 2026-08-31 **desde el código**, no desde QA, a propósito: ver "Por qué no se ejecutó
> contra QA".

## Por qué no se ejecutó contra QA

La ruta feliz de este endpoint **crea un cargo real en OpenPay** y, por la bandera `SendEmail`, la
pasarela **le manda un correo al beneficiario** con el link. Ejercerla "para tomar el baseline"
significa mover dinero y escribirle a un cliente.

El baseline se levantó entonces enumerando **todas** las rutas de salida del código, que es una red
más completa que una sola llamada viva: cubre los 6 códigos de estado, no solo el que toque ese día.
La validación del 200 se hace en T-13 con un contrato desechable y con Carlos presente.

## Contrato de entrada (no debe cambiar)

```http
POST /contracts/api/Bmw/v1/{projectId}/contracts/{contractId}/payment-link
Authorization: Bearer <jwt>
Content-Type: application/json

{ "paymentType": 1, "msi": 6 }
```

- `paymentType` — `[Range(1,2)]`. 1 = tarjeta, 2 = SPEI.
- `msi` — `[Range(3,12)]`, opcional. Si se omite, el tope sale de `producto_proyecto.max_msi`.
- Policy `ICanAccessBmw`, rate limit `Restrictive`.

**Respuesta 200:** `{ "paymentUrl": "<url de OpenPay>" }`

## Todas las salidas, con su mensaje textual

| # | Condición | Código | Mensaje exacto |
|---|---|---|---|
| 1 | `contractId < 1` | 400 | `Route parameter 'contractId' must be greater than 0.` |
| 2 | Body inválido (`paymentType` fuera de 1-2, `msi` fuera de 3-12) | 400 | `ModelState` de ASP.NET |
| 3 | `scope.Kind == Denied` | 403 | `Forbid()` del controlador (sin cuerpo) |
| 4 | `ByProjectIds` y el `projectId` no está en el scope | 403 | `Forbid()` del controlador (sin cuerpo) |
| 5 | Igual que 3 y 4, pero detectado dentro del servicio | 403 | `Forbidden.` |
| 6 | **No existe `bmw_registro` para ese (projectId, contractId)** | 403 | `El contrato no pertenece a este proyecto BMW o no está autorizado para su usuario.` |
| 7 | Rol por distribuidor y el dealer del contrato no está en su scope | 403 | *(el mismo mensaje que 6)* |
| 8 | El contrato no existe en `contrato` | 404 | `No existe el contrato solicitado.` |
| 9 | `contrato.estatus` es `Cancelado` o `Caduco` | 409 | `El contrato ya no tiene cobertura.` |
| 10 | `GetContractPaymentInfoAsync` dice `CanRegenerate == false` | 409 | El `BlockReason` que venga, o `No se puede generar un link de pago nuevo en este momento.` |
| 11 | La pasarela truena con "ya está pagado" o "ya se encuentra en una orden de pago" | 409 | El mensaje de la excepción, tal cual |
| 12 | La pasarela truena con "no se puede pagar por el beneficiario" | 422 | El mensaje de la excepción, tal cual |
| 13 | Cualquier otro error de la pasarela | 422 | El mensaje de la excepción, tal cual |
| 14 | Excepción no controlada | 500 | `An error occurred while generating the payment link.` |

> Los mensajes de 11 a 13 salen de recorrer las `InnerException` hasta la más profunda que traiga
> texto, no de la excepción de arriba.

## ⚠️ El punto más delicado del wrapper: la salida #6

`EnsureContractInScopeAsync` no solo valida el rol. También exige que **exista un `bmw_registro`
para ese `(projectId, contractId)`**: si el contrato es del proyecto BMW pero nunca pasó por la
landing, hoy devuelve **403**.

El endpoint genérico usa `IContractAccessService`, que deriva el proyecto de
`contrato.id_distribuidor → distribuidor.id_proyecto` y **no sabe nada de `bmw_registro`**. Si el
wrapper se limita a delegar, ese caso pasaría de **403 a 200**.

**Eso es un cambio de comportamiento, y del lado peligroso**: relajar quién puede generar un cargo.
El wrapper de BMW tiene que **conservar** la verificación del `bmw_registro` y la del `projectId` de
la ruta, aunque el servicio genérico ya no las haga. Es lo que cubren T-10 y T-11 del plan.

## Efectos colaterales de la ruta feliz (para no perderlos)

1. Crea un cargo nuevo en OpenPay y **sobreescribe** `contrato.link_pago_pasarela` y
   `contrato.uuid_pago_openpay`.
2. OpenPay **envía correo** al beneficiario con el link.
3. Si ya había un link previo, se registra la regeneración en bitácora
   (`RecordPaymentLinkRegenerationAsync`) con el link y el uuid anteriores.
4. El vencimiento del cargo sale de `distribuidor.dias_pago`; con 0 aplica el default
   `Facturas:Dias_Vencimiento` = 31 días.

## Guard anti doble cobro — no relajar

La salida #10 es la que impide que existan dos cargos pagables sobre el mismo contrato. Un cargo de
OpenPay es de **un solo uso**, así que regenerar sobre uno vivo deja dos links cobrables y dos
correos al cliente. Ya hubo una reversión por esto (ver `PJ9124`). Se porta tal cual.
