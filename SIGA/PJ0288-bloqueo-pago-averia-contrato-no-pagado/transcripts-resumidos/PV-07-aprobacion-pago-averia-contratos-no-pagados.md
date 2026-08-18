# Condensado — PV-07 Aprobación de pago de avería a contratos aún no pagados

## Decisiones
- Bloquear la aprobación de pago de una avería cuando el contrato asociado aún no ha sido pagado
  (contrato en estado 'registrado', sin pago confirmado).
- El bloqueo se levanta solo cuando el country manager autoriza el pago al taller.

## Alcance / requerimientos
- Al llegar una avería al proceso de pago, validar el estado de pago del contrato asociado.
- Si el contrato no está pagado: avisar al country manager para que decida si se paga al taller.
- Mientras no haya autorización del country manager, la aprobación de pago queda bloqueada.
- Contexto: existen averías legítimas generadas sobre contratos no pagados, autorizadas por el
  country manager; el flujo debe contemplarlas sin pagar automáticamente.

## Actores
- Country manager: autoriza (o no) el pago de la avería cuando el contrato no está pagado.
- Taller: destinatario del pago de la avería.
- Sistema SIGA: valida estado de pago del contrato y aplica el bloqueo.

## Riesgos / pendientes
- Riesgo actual: pagar averías de contratos aún no pagados.
- Pendiente definir: canal/forma del aviso al country manager, y mecanismo de autorización.

## Fechas / hitos
- (sin definir)
