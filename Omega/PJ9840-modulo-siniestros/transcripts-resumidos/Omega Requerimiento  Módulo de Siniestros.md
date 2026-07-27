# Condensado — Omega Requerimiento Módulo de Siniestros.txt

## Decisiones
- Necesidad #1 (prioridad explícita de José Juan): que el sistema capte automáticamente los avisos de siniestro que llegan por correo de las aseguradoras, en vez de que él los transcriba manualmente a Excel. Esto es "lo primordial"; el resto se puede ir trabajando poco a poco.
- El Excel que hoy usa José Juan (bitácora única con hojas: avisos, pérdidas totales, devoluciones de primas) también alimenta reportes a un tercero ("CAF") y reportes internos; el nuevo sistema debe darle esa misma funcionalidad de reporteo sin obligarlo a generar reportes adicionales.
- Se agrega un campo de seguimiento libre (notas/comentarios) y un campo de estatus por siniestro; José Juan propone que exista tanto un campo abierto de comentarios como un estatus (abierto/cerrado, o más granular tipo "concluido satisfactoriamente"/"procedió o no procedió").
- Gestión documental: los expedientes de siniestro (obligatorio guardarlos por ley mínimo 10 años) deben poder cargarse al sistema; la carga debe ser masiva por nombre/caso (no un campo por cada tipo de documento), porque los documentos requeridos varían por aseguradora.
- Vinculación con pólizas: si la póliza fue emitida en Omega, el siniestro se debe poder vincular buscándola; si no fue emitida en Omega (cartera de micrositios/externa), igual se debe poder registrar el siniestro solo con el número de póliza, marcado como "no vinculado a Omega". Esto también serviría como métrica de uso de Omega para el equipo comercial.
- Visión de reportes: poder descargar/filtrar un Excel de los avisos capturados (incluyendo los no vinculados a Omega, identificados como tales).
- Daniela aclara el proceso: esta sesión es fase de "discovery" (entendimiento de la necesidad); después sigue análisis técnico (con Alexis y desarrolladores) para decidir si el desarrollo es interno o requiere ayuda externa, lo cual definirá fechas. No hay fechas comprometidas todavía.
- Se prioriza una solución global/integral en vez de "parchecitos" puntuales (ya se había intentado antes un robot aislado solo para avisos, con "Aldo", que no se concretó).

## Alcance / requerimientos
- Automatización de captura de avisos de siniestro desde correos de las aseguradoras (multi-formato: PDF, imagen, texto en el cuerpo del correo; algunos correos traen varios avisos en CC). No se puede resolver con fórmulas de Excel porque los datos vienen en PDF/imagen; requiere un proceso más avanzado (tipo robot/OCR).
- Cada aseguradora usa su propio formato/nomenclatura de correo y de campos (ej. Potosí, HDI, Chubb/"Chup", Qualitas, Latino, GNP; TNP/ANA casi ya no envían). El sistema debe aceptar múltiples formas de entrada, no cerrarse a un solo formato.
- Campos que hoy captura José Juan manualmente (reducidos de un set más amplio "en vidas pasadas" a 8 esenciales): número de siniestro, número de póliza, serie, teléfono de contacto, tipo de siniestro, nombre del asegurado/contacto, causa de siniestro, y estatus — más los campos de seguimiento (comentarios/estatus) que se agregan como necesidad nueva.
- Registro de siniestro debe permitir asociar/cargar documentación de forma masiva (por caso/nombre), sin desglosar por tipo de documento individual, ya que los requisitos documentales varían por aseguradora.
- Consulta de póliza: al buscar una póliza, mostrar su histórico de siniestros asociados (ejemplo visto en un portal externo: tipo de evento — asistencia vial, choque, grúa — vinculado a los avisos de la aseguradora).
- Visión a futuro (no prioritaria ahora, mencionada como "hacia allá tendríamos que ir"): un módulo de cobranza relacionado a la póliza que muestre cuánto se cobró/pagó por siniestro.
- Visión a largo plazo (fuera de prioridad actual): que las solicitudes de seguimiento de un siniestro —que hoy llegan a José Juan vía formulario, WhatsApp, correo o llamada de los distribuidores— lleguen directamente a Omega como una especie de "ticket" que le genere una alerta, y que él dé seguimiento desde ahí. Los distribuidores ya tienen usuario de Omega pero no lo usan para esto actualmente.
- Integración bidireccional con el sistema propio de siniestros de un socio externo ("la financiera") es una posibilidad de largo plazo, mencionada como desarrollo conjunto complejo y NO prioritaria — la prioridad es el negocio completo, no un solo cliente/financiera.

## Actores
- **Daniela Carbajal Vega** — TI/PM, conduce el levantamiento, no conoce el área de siniestros, arma el requerimiento y lo escalará a análisis técnico (Alexis + desarrolladores).
- **Norma Zacarias** — negocio, conoce Omega, traduce/representa la necesidad de José Juan, aporta la visión de vinculación con pólizas y de documentación regulatoria.
- **José Juan Mendoza Díaz** — dueño operativo del proceso de siniestros, no usa Omega actualmente, hoy captura todo manualmente en Excel; da el detalle del proceso AS-IS y la prioridad #1 (automatizar avisos).
- Mencionados sin ser asistentes: Aldo (a quien antes se le pidió un robot externo de avisos, no concretado), Alexis (análisis técnico/desarrollo), distribuidores/agencias con usuario en Omega (solicitantes de seguimiento), "la financiera" (cliente/socio con su propio portal y módulo de siniestros).

## Riesgos / pendientes
- No toda la cartera está en Omega (existen micrositios/cartera externa) — el vínculo póliza↔siniestro no puede ser 100% automático; se necesita soportar siniestros sin póliza emitida en Omega.
- Automatizar la lectura de avisos requiere OCR/robot dado que llegan en PDF/imagen con formato variable por aseguradora; un intento previo de robot externo (con Aldo) quedó pendiente/no se concretó.
- Integración con el sistema de siniestros de "la financiera" es de largo plazo, no prioritaria, y depende de un desarrollo conjunto con terceros.
- Pendiente accionable: José Juan reenviará a Daniela un correo de aviso de ejemplo por cada aseguradora (Potosí, HDI, Chubb, Qualitas, Latino, GNP) para mapear los distintos formatos/campos de entrada.
- Pendiente accionable: dar acceso de solo lectura a Daniela a la bitácora Excel (hojas: avisos, pérdidas totales, devoluciones de primas) en vez de reenviarla.
- Pendiente de definición técnica: si el desarrollo será interno o requerirá proveedor externo (lo decide dirección/Alexis tras el análisis técnico); de eso dependen las fechas.
- Mesa (otra área) tiene una necesidad similar (automatizar un formulario manual) ya en radar de Omar — posible sinergia a considerar, mencionada solo de pasada.

## Fechas / hitos
- Sin fechas comprometidas: el proyecto está en fase de discovery (entendimiento de la necesidad).
- Daniela dará seguimiento a inicios de la semana siguiente a la sesión (idealmente al día siguiente) con el requerimiento armado, para validación ágil de negocio antes de pasar a análisis técnico.
- Ejemplo ilustrativo (no comprometido) que dio Daniela sobre cómo se dan los desarrollos: ~3 meses de desarrollo + 1 mes de pruebas antes de salir a producción, una vez que se tenga fecha de inicio definida.
