# Condensado — reunion-gplus-modulo-cobranza-comisiones

## Decisiones
- Se tratarán como dos funciones dentro de un mismo desarrollo: (1) pago de comisiones a distribuidores (automatización del "cierre" mensual) y (2) cobro de comisiones a aseguradoras.
- Se prioriza primero la función (1), documentada casi completa en esta sesión. La función (2) queda con lo discutido, pendiente de que Juan Carlos piense cómo automatizarla.
- No se puede automatizar tomando como fuente única Omega porque solo ~20% de las pólizas se emiten ahí (limitantes: servicio público, motos, algunos modelos no soportados).

## Alcance / requerimientos
### Función 1 — Pago de comisiones a distribuidores (automatización del cierre)
- Cada negocio/distribuidor (Autocom/CAF, Misol, Roca, etc.) mantiene su propia base con datos de pólizas (número de póliza, aseguradora, cliente, vigencia, prima, recargos, derecho, IVA, prima total, clave especial/tradicional, zona/ejecutivo).
- Patricia valida pólizas de externas; Carlos valida si el pago está aplicado o no en Autocom/CAF; Deca genera sus propias bases.
- Al cierre, cada responsable carga su base al sistema; el sistema debe generar automáticamente: el cálculo de UDI (según % de aseguradora y % pactado con cada distribuidor, incl. reparto a Garanti Plus), el estado de cuenta por distribuidor, y el cierre/ganancia para Gplus.
- Contabilidad debe poder visualizar el cierre generado automáticamente, sin que el equipo se lo comparta manualmente por correo.
- Se deben enviar automáticamente correos a distribuidores con su estado de cuenta y monto a facturar, copiando a contabilidad, con fecha límite para facturar y reglas de reprogramación de pago si no facturan a tiempo (según comunicado oficial de contabilidad sobre tiempos de pago/provisión).
- Reduce el actual proceso 100% manual por correo (Patricia hoy manda entre 10-20 correos pidiendo facturas).
- Posible uso del bot de Omar: alimentar con número de póliza + aseguradora (idealmente también negocio/agencia para evitar cruces posteriores) para descargar póliza, factura y validar si el pago está aplicado, cargando el resultado a Omega/Sigma. Habilitaría una vista por agencia/negocio con permisos para agentes vendedores.
- Función adicional propuesta por Patricia: que Omega permita cargar de forma masiva toda la producción emitida por fuera (micrositios), para que distribuidores puedan autoconsultar/descargar reportes (hoy Patricia los atiende uno a uno por correo).
- Requerimientos adicionales identificados: extracción de bases de renovaciones desde la producción cargada, y alertas de pagos subsecuentes (pólizas semestrales/fraccionadas) configurables en días de anticipación — funcionalidad que Sigma sí tenía y Omega no.
- Riesgo señalado por Carlos: pagar comisiones semanales a Autocom probablemente no se pueda automatizar en esta fase porque interviene otra persona (Eric).

### Función 2 — Cobro de comisiones a aseguradoras (Juan Carlos)
- Se cobran tres montos mensuales (mes vencido): comisiones, rechazo de póliza, y derechos.
- La mayoría de aseguradoras mandan un reporte con el monto a facturar para el cobro de UDIS; se requiere automatizar: subir esa base, ligarla a contabilidad, y generar la factura para enviarla.
- Idea explorada (más incierta): un bot que entre a los portales de las aseguradoras a descargar la información de cobro — Juan Carlos lo ve complicado por temas de acceso/credenciales y manejo de dinero, y pidió tiempo para proponer cómo automatizarlo.

## Actores
- Daniela Carbajal Vega — PM, levantando el requerimiento.
- Norma Zacarias — dueña de negocio, articula la necesidad y propone el modelo de automatización del cierre.
- Patricia Ramirez Villegas — apoya cartera de externas; hoy hace el cierre/estado de cuenta manualmente en Excel.
- Juan Carlos Palafox Reyes — encargado de cobro de comisiones a aseguradoras (función 2) y de validar aplicación de pagos de Autocom/CAF.
- Omar (no presente) — dueño del bot de descargas; se recomienda invitarlo a una próxima sesión para conocer limitantes técnicas.
- Eric (mencionado) — interviene en pago de comisiones semanales a Autocom; posible bloqueo para automatizar esa parte.
- Contabilidad (no presente) — debe emitir comunicado oficial de tiempos de pago/provisión; sería consumidor del cierre automatizado.

## Riesgos / pendientes
- Solo ~20% de pólizas se emiten desde Omega; el resto vive en micrositios externos — limita qué tan lejos puede llegar la automatización sin antes resolver la cobertura de Omega.
- No está definido si el módulo vivirá dentro de Omega o como sistema aparte.
- Falta involucrar a Omar para validar si el bot actual puede conservar columnas de negocio/agencia y evitar cruces manuales posteriores.
- Función 2 (cobro a aseguradoras) quedó menos definida; Juan Carlos pidió espacio para pensar la automatización, especialmente el bot de portales de aseguradoras.
- Cada negocio/distribuidor tiene un proceso ligeramente distinto (Autocom/CAF vs. Misol/externas vs. otros), por lo que la configuración del cierre no puede ser 100% uniforme.

## Fechas / hitos
- No se definieron fechas comprometidas en esta sesión; Daniela cierra la reunión indicando que documentará el requerimiento y dará seguimiento.
