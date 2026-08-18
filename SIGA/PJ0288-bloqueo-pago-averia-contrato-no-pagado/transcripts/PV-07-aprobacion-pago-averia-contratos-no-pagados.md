# PV-07: Aprobación de pago de avería a contratos aún no pagados

## Problema
Contratos en estado 'registrado' (sin pago confirmado) pueden avanzar hasta aprobación de
pago de avería, generando riesgo de pagos de averías de contratos aún no pagados.

## Solución
Considerando las averías que se generan en contratos no pagados (autorizados por el country
manager), si llega al proceso de pago y el contrato aún no ha sido pagado, avisar al country
manager para determinar si se le paga al taller o no.

Si el contrato no ha sido pagado, bloquear la aprobación de pago hasta que el country manager
autorice.
