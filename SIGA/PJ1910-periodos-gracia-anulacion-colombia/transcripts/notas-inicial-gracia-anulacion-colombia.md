# Notas: Periodo Gracia y Anulacion Colombia

## Problema
Operaciones no puede gestionar periodos de gracia ni anulaciones (Cancelaciones de Contratos); genera dependencia innecesaria de otras areas.

## Mejora propuesta
Habilitar la gestion de periodos de gracia permitidas solo para los usuarios con rol Administrador General. Mostrar el boton de Cancelación (en la vista de Contratos al ver el detalle del contrato, actualmente este boton existe para México) de contratos para los usuarios con rol Administrador General, siempre y cuando: no tenga factura activa agregada, no se encuentre en una orden de pago activa.

## Consideraciones para desarrollo
Definir quien autoriza periodos de gracia y anulaciones (riesgo averias con contratos vencidos); periodo de gracia existe en averias (averia_periodo_gracia) pero no en Operaciones/contratos; fx_anulacion usado en reportes; impacto en facturacion e integraciones.

## Importancia e impacto de negocio
- Importancia: Alta
- Impacto: Administracion operativa
- Autonomia: Gracia y anulaciones en Operaciones; da autonomia al area y reduce dependencia, con riesgo a controlar en contratos vencidos.
