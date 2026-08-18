# Condensado — resultado-fase-0-2026-08-17

## Decisiones
- La prueba se movió de **producción a local**, contra el validador de pruebas: mismas reglas estructurales, costo cero y sin emitir un comprobante fiscal irreversible.
- Se adopta la vía de **declarar el periodo** en el comprobante a público en general (escenario C). Es la fiscalmente correcta.
- El escenario A (identificador genérico con nombre real del cliente) queda como **respaldo documentado**, no como la vía preferente.
- La casilla "GENERAR FACTURA GLOBAL" del módulo de Órdenes de Pago **no resuelve el caso**: ahí "global" significa una sola factura para varios contratos, que es otro concepto.

## Alcance / requerimientos
- Confirmado que el comprobante a público en general **sí se puede emitir**: cae el bloqueo que condicionaba el bloque de facturación.
- Nuevo requerimiento: **verificar que el comprobante no quedó emitido antes de reintentar**. Un fallo posterior a la emisión no cuenta como fallo de timbrado.
- Nuevo requerimiento: **aislar los artefactos posteriores** (el PDF entregable) para que su fallo no interrumpa ni invalide la emisión.
- Nuevo requerimiento: **declarar el periodo** cuando el receptor sea el identificador genérico con nombre de público en general.

## Actores
- Sin actores nuevos. Contabilidad gana peso: debe avalar el comprobante global de una sola operación antes de producción.

## Riesgos / pendientes
- 🔴 **Se reabre la facturación de ~1,016 contratos** de la cartera Allianz: están en el estado exacto del escenario probado y ahora se pueden emitir. La decisión previa los descartó porque el comprobante global se creía imposible.
- 🔴 Falta el **aval contable** de un comprobante global que ampara una sola operación; la figura está pensada para agregar un periodo.
- El **comportamiento actual no documentado**: el portal ya emite hoy con identificador genérico y nombre real del cliente cuando faltan datos fiscales. Habría que decidir si se corrige y si hay comprobantes ya emitidos así que revisar.
- Lo verificado fue contra el **validador de pruebas**; que producción se comporte igual es un supuesto razonable pero no una certeza.
- Los intentos rechazados **acumulan registros incompletos**; el reintento automático duplica ese volumen.

## Fechas / hitos
- 17-ago-2026: Fase 0 completada. Tres escenarios probados; dos comprobantes emitidos en pruebas y un rechazo reproducido.
- Entregable: rama `feature/PJ4793-cfdi-publico-en-general`, commit `8d25819`, pendiente de revisión y despliegue.
