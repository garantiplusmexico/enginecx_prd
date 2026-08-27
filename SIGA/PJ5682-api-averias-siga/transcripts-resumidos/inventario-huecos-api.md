# Condensado — Inventario de huecos de la API SIGA

Registro de la evidencia dura recogida contra los OpenAPI vivos el 2026-08-26. Es la base probatoria de cada petición del PRD: ningún hueco se afirma sin su evidencia.

## Decisiones
- **La evidencia se recoge por conteo exhaustivo de cadenas sobre el JSON completo del spec**, no por búsqueda manual. Así una ausencia es un hecho verificable y no una impresión.
- **Se documentan también las contradicciones del propio spec**, que son peticiones distintas —corregir documentación— y mucho más fáciles de aceptar que crear funciones.

## Alcance / requerimientos — la evidencia
- **Existen 4 microservicios y solo 4:** `authentication`, `catalogs`, `contracts`, `claims`. Se probaron y descartaron 15 nombres más, todos 404.
- **Ausencias confirmadas por conteo en el spec de `claims`:** `reason` **0 ocurrencias** (no existe el motivo de rechazo), `history` **0** (no hay historial de estatus), `followup`/`comment`/`seguimiento`/`observacion` **0** (el seguimiento no está expuesto, aunque SIGA lo tiene en la interfaz y notifica por correo), `labor` **0** y refacciones **0**, `budget` **1** y solo en prosa descriptiva. `odometer` aparece 9 veces, **todas en incidencias, ninguna en `ClaimResponse`**.
- **No existe `GetClaimById`.** Para incidencias sí hay singular; para averías solo la colección.
- **`ContractInfo` no trae límite por avería, límite de contrato ni valor de venta del vehículo.** Solo precio, impuestos y total del contrato.
- **`ClaimDocumentQueryResponse` no trae `documentTypeId`**, solo el nombre del tipo como texto.
- **Sí existe el texto del certificado:** `GetContractPdfDataById`. Es el habilitador de la etapa 1.
- **Sí se puede filtrar contrato por VIN** en principio: `ContractListResponse.vin` existe y el endpoint acepta OData.
- **Contradicción de nomenclatura OData:** los ejemplos documentados usan `IdAveria`, `VinOrPlate`, `IdDocumento`, `TipoDocumento`; los esquemas documentan `claimId` y no declaran `vinOrPlate`. Un filtro con el nombre equivocado **devuelve vacío en silencio**.
- **Autenticación:** `Login` con usuario y contraseña **de persona**. `LoginResponse` emite `refreshToken` **pero no hay endpoint donde canjearlo**. Los roles son de solo lectura, sin forma de crear ni asignar.
- **11 estatus reales de avería:** Registrada, Validación, Aceptada, No procede garantía, Taller, Solucionada, Cerrada, Cancelada, Prueba-QA, Excepción en revisión, Excepción no aprobada.
- **56 valores de motivo de rechazo con duplicados y variantes de mayúsculas** entre países.

## Actores
- Equipo de desarrollo de SIGA — destinatario de las 34 peticiones.

## Riesgos / pendientes
- **Tres argumentos a favor tomados de la documentación de la propia API**, que conviene usar al redactar: la API **ya está diseñada para un agente de IA** (`ConvertToClaim`: *"Human action — the agent never converts automatically"*); **multi-país ya es el plan declarado** (*"Multi-country support (currently MEX, expandable to other markets)"*); y **el servicio promete funciones que no entrega** —dice *"monitor claim status"*, *"resolutions"*, *"Claims tracking and reporting"*—, lo que hace del hueco una incoherencia con su propio enunciado de propósito.
- **11 puntos pendientes de verificación en runtime**, incluida la vía del puente incidencia → avería que podría eliminar un hueco.
- Las cuentas de prueba son de taller y distribuidor, no de técnico: **un 403 no prueba que algo no exista**.
