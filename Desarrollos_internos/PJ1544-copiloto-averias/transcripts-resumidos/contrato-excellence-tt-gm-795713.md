# Condensado — Contrato Excellence TT GM nº 795713 (Garantiplus México)

Certificado de garantía mecánica de referencia, entregado por David Simancas como muestra del producto que cubre ~95% de la cartera de México. Es la **fuente normativa del dictamen**: el agente de IA debe razonar contra el condicionado del contrato concreto, no contra reglas generales.

## Alcance / requerimientos — estructura del condicionado

Datos de cabecera aprovechables por la automatización: nº de contrato, fecha de contrato, producto contratado, límite por avería y límite de contrato, marca / modelo / versión, **VIN**, nº de motor, cilindrada, **fecha de 1ª factura**, **kilómetros**, punto de venta, beneficiario y **periodo de vigencia (fecha inicio / fecha fin)**.

Cláusulas que alimentan directamente los criterios de dictamen:

| Cláusula | Contenido y uso en el dictamen |
| --- | --- |
| **1 — Definición de avería** | Avería es la **inutilidad operativa por rotura imprevista/fortuita**. Se excluye explícitamente la degradación gradual del rendimiento proporcional a antigüedad y kilometraje. Es la base del motivo *"daño por uso o degradación"*. Lista además **9 grupos de elementos excluidos de origen**: asientos y mecanismos, interiores de habitáculo, neumáticos y válvulas, carrocería completa, cristales y lunas, faros e intermitentes, molduras y espejos, **consumibles** (filtros, aceite, juntas, amortiguadores, escapes, discos y pastillas de freno, correas, servicios periódicos, lubricantes, combustibles, carga de a/c, bujías, batería, plumas) y elementos que perdieron su morfología inicial. |
| **3 — Duración** | Solo están cubiertas las averías ocurridas **dentro de la vigencia**. No hay prórroga tácita. → validación de vigencia. |
| **5 — Delimitación geográfica** | Cobertura limitada al territorio del país emisor. |
| **9 — Mantenimientos periódicos** | El criterio decisivo. **Vehículo nuevo:** plan del fabricante. **Seminuevo o con garantía de fábrica terminada: revisión cada 6 meses o 10 000 km, lo que ocurra antes** (o el intervalo del fabricante si es menor). Mantenimientos obligatoriamente en **distribuidor autorizado de la marca**. Prueba admisible: **carnet sellado + facturas**. *"El incumplimiento de cualquiera de los requisitos anteriores invalidará este contrato."* |
| **10 — Procedimiento en caso de avería** | Documentación exigible: orden de entrada con fecha y kilómetros, **presupuesto sin desmontar ni intervenir**, copia del libro de mantenimiento y facturas de inspecciones. Fija el **compromiso de resolver por escrito y motivadamente en 48 horas** (sin domingos ni festivos) desde la recepción de la documentación. El vehículo debe **permanecer inmovilizado** hasta la resolución. |
| **11 — Límites** | La valoración nunca puede superar el **valor de venta del vehículo** según Libro Azul. Se paga la menor de: límite por avería, límite de contrato, valor del vehículo. |
| **12 — Exclusiones generales (7 supuestos)** | Trabajo sobre el vehículo antes de la resolución; vehículo no inmovilizado; incumplimiento de mantenimientos; **documentación no aportada dentro de las 72 h tras ser requerida**; incoherencia entre los kilómetros de inicio de contrato y los de la avería; avería comunicada fuera de vigencia; cualquier incumplimiento del contratante o beneficiario. |
| **13 — Operaciones no incluidas (32 supuestos)** | Preexistencias y defectos previsibles; causa evidente durante la garantía de fábrica; mala reparación anterior; fin de vida útil natural; corrosión y oxidación; consumibles y **fugas de aceite, refrigerante o combustible**; actualizaciones de software de módulos electrónicos; costos de diagnóstico si no se cubre; **campañas y fallos epidémicos**; seguir circulando con el testigo de avería encendido; mal uso, negligencia, competición, sobrecarga, abrasivos; accidente, robo, incendio, vandalismo; grúa, estacionamiento, lucro cesante, daños a terceros; averías que corresponden a la garantía del fabricante; **ruidos, vibraciones y traqueteos** no derivados de rotura fortuita; elementos de propulsión eléctrica bajo cobertura de gasolina. |
| **19 — Protección de datos** | Los datos personales del contrato no pueden transferirse a terceros. Restringe qué puede salir del sistema hacia el agente de IA. |

## Riesgos / pendientes
- El certificado es **por contrato**: los umbrales, límites y exclusiones cambian entre productos (`Excellence` vs `Expert` nominado de 120 componentes) y entre países. Ninguna regla puede quemarse en el prompt como constante; hay que leer el condicionado del contrato de cada caso.
- Varios campos del ejemplar llegan **vacíos o con relleno** (nombre del beneficiario como "Contrato Desde API", RFC genérico `XAXX010101000`, teléfono `0000000000`). La calidad de los datos de beneficiario no es confiable para automatizar comunicaciones al cliente.
- La cláusula 9 exige que el mantenimiento se haya hecho en distribuidor autorizado: verificarlo exige leer facturas, no basta un flag del sistema.
