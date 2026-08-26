# Condensado — Tablero de Averías LATAM (corte 14/08/2026)

Tablero operativo que David Simancas mantiene para los tres países. Aporta la **línea base cuantitativa** que al PRD v0.1 le faltaba y define qué parte del proceso vale la pena automatizar primero.

## Decisiones
- **El objetivo del MVP se dimensiona con datos, no con intuición.** En México, 2026 (ene–jul): **1 582 averías, de las que 604 (38.2%) terminaron en "No procede garantía"**. Rechazar es el desenlace más frecuente del área.
- **Los cuatro motivos de rechazo mecanizables concentran el 54.6% de los rechazos de México:** intervalo de mantenimiento excedido (29.1%), componente excluido (15.7%), fuga excluida (6.8%) y sin vigencia (3.0%). Eso equivale a **~21% de todas las averías del país**: el techo realista de improcedencias que el MVP puede dictaminar con alta confianza.
- **El segundo motivo, "daño por uso o degradación" (24.8%), no es automatizable** y coincide exactamente con lo que David describió como ambiguo. Es el caso típico que debe salir como *duda*.
- **La línea base de tiempo de respuesta ya existe** y se puede medir contra ella: mediana 4.1 días y p90 50.1 días en México.

## Alcance / requerimientos
- **Volumen a soportar:** ~226 averías/mes en México (~11 por día hábil), ~74/mes en Chile, ~107/mes en Colombia. Carga muy baja: el diseño no necesita optimizarse para volumen, sino para exactitud y trazabilidad.
- **Los estatus reales son 11**, tres más de los que se ven en el flujo normal: `Prueba-QA`, `Excepción en revisión` y `Excepción no aprobada`. Estos dos últimos aparecen solo en Chile y Colombia.
- **El catálogo de motivos de rechazo tiene 56 valores con duplicados y variantes de mayúsculas** entre países. El agente debe emitir un motivo de un catálogo normalizado, no texto libre; normalizarlo es prerrequisito para medir.
- El tablero registra el componente reclamado por avería, dato que **la API de SIGA no expone**.
- Solo dos técnicos absorben el 94% de la carga de México (Eduardo Álvarez 759, Miguel Ángel Rodríguez 735).

## Actores
- **David Simancas** — dueño del tablero y de la data de rechazos.
- **Eduardo Álvarez / Miguel Ángel Rodríguez** — los dos dictaminadores de México.

## Riesgos / pendientes
- **No está claro qué mide exactamente el campo de tiempo de respuesta** (¿registro→cierre o validación→dictamen?). La diferencia importa: el compromiso contractual es de 48 horas hábiles desde el paso a validación, y una mediana de 4.1 días no es comparable con él. Hay que confirmarlo antes de fijar la métrica de éxito.
- **Chile y Colombia usan catálogos de motivos distintos a México**, con nomenclatura propia. La homologación que pidió David exige normalizar el catálogo antes de portar el desarrollo.
- El tablero se alimenta de una extracción manual, no de la API. No sirve como fuente en tiempo real.
- Colombia rechaza el 45.9% y Chile solo el 17.5%: diferencia grande que puede ser de producto, de criterio o de calidad del dato. Sin explicar.
