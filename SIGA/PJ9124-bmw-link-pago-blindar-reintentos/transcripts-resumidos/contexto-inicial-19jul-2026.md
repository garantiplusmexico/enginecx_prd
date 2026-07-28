# Condensado — contexto-inicial-19jul-2026

## Decisiones
- El "fix de reintento" interino (generar un cargo nuevo en cada clic) se implementó y se REVIRTIÓ: proliferaban links. No re-implementarlo sin acordar.
- La mejora se difirió al regreso de vacaciones de Carlos (27-jul-2026) por ser zona de pagos sensible.
- Validar en QA antes de PROD, con Carlos presente. Rama `feature/cc_*` desde develop, sin commit hasta que él revise.

## Alcance / requerimientos
- Mostrar el link de pago del contrato en la landing con botón COPIAR (compartir al cliente) y ABRIR (nueva pestaña).
- Reutilizar/persistir el link: no generar uno nuevo en cada clic.
- Blindar contra cargos pagables duplicados (riesgo de doble cobro).
- Referencia de UX: el "Link de pago" del detalle de contrato en SIGA, pero con mejor UI/UX.

## Actores
- Carlos Castellanos (solicita e implementa).
- Cliente final BMW (paga con tarjeta desde el link).
- Vendedor/asesor del distribuidor (comparte el link con el cliente desde la landing).

## Riesgos / pendientes
- DECISIÓN PENDIENTE: nivel de blindaje A (ligero, solo landing/API, apoyado en `GetPaymentStatus`; no cancela en OpenPay → borde de dos pestañas pagables) vs B (robusto, cancela el cargo OpenPay anterior; toca `gp_4.0_siga`/OpenpayGP y su deploy).
- Los cargos de OpenPay son de un solo uso: un cargo denegado no se puede reintentar (`card_capture` da "Transacción denegada").
- Bug vivo hoy: la landing reabre `contrato.link_pago_pasarela` (cargo posiblemente muerto) → cliente atorado. Ocurrió en PROD, contrato 796211.
- Riesgo de doble cobro si quedan varios cargos pagables simultáneos.

## Fechas / hitos
- 19-jul-2026: se acuerda la mejora y se difiere; se revierte el fix interino.
- 27-jul-2026: se retoma y se arranca el PRD.
