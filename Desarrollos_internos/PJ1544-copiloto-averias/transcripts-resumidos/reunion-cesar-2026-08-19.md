# Condensado — reunion-cesar-2026-08-19

Reunión en la que el responsable del sistema de Garantía Global lo explica en vivo. Aporta el
"por qué" del negocio y las cifras del dolor operativo.

## Decisiones
- Distinción central: **una cosa son las automatizaciones y otra la herramienta de ayuda al
  tramitador**. Son dos productos con dos propósitos distintos.
- Todo el diseño está condicionado por que su aplicativo **no tiene API**, así que automatizan
  por encima simulando a un humano. Reconocen que con API lo harían de otra forma.
- El rehúse asistido está en producción pero **frenado antes de enviar al cliente**: un humano
  aprueba. El plan declarado es soltarlo cuando confíen en la detección.

## Alcance / requerimientos
- Canales de entrada de una avería: **formulario web** (se abre y se asigna sola),
  **correo** (lo procesa la automatización) y **teléfono**.
- Al abrir por formulario se asigna automáticamente a un tramitador.
- Se valida el contrato antes de levantar la avería: mantenimientos al día, foto del
  kilometraje, etc.
- El tramitador necesita apoyo porque **no tiene por qué saber de mecánica**: pega el
  expediente en el asistente y este le dice qué hacer, le redacta el correo al cliente o al
  taller, le prepara el guion para hablar por teléfono y le genera la resolución en PDF con la
  imagen corporativa.
- Existe un canal de consulta interno: cualquier persona autorizada escribe un correo con una
  palabra clave y pregunta "¿cómo está esta avería?"; el sistema entra, resume y responde, y
  admite repreguntas.
- Los umbrales de confianza de la IA se ajustan por caso de uso y sirven también para adaptar
  el sistema a variantes regionales de vocabulario.

## Actores
- Tramitadores/técnicos (usuarios del asistente). Aprobador de rehúses. Comerciales (canal de
  consulta). Cliente final. Talleres. Atención telefónica (2 personas).

## Riesgos / pendientes
- **El aplicativo no tiene alertas.** Se abre un siniestro y el tramitador no recibe ningún
  aviso. Señalado explícitamente como la mejora pendiente.
- **Casos huérfanos por ausencias:** una avería asignada a alguien de vacaciones se queda sin
  atender. Ocurrió en vivo durante la demostración.
- **El sistema es reactivo, nunca proactivo.** "En el journey del cliente hay cinco momentos de
  la verdad y no le estamos informando." No pueden construirlo sin API.
- Datos de contacto incompletos en el expediente: la automatización a veces no rellena el
  correo del cliente aunque el dato estuviera disponible, y entonces no se le puede contactar.
- Toda la operación depende de un solo buzón compartido por varios procesos: preocupación
  expresa de que se bloquee.

## Cifras del dolor (línea base de referencia, de su operación)
- 28.294 llamadas en el año; **67,7% contestadas → 32% abandonadas**.
- ~2.953 llamadas no contestadas en un mes; promedio 153/día; espera media antes de colgar 37 s.
- **~60% de los casos que entran por correo terminan además en llamada** porque el cliente no
  queda satisfecho con la respuesta.
- Ahorro estimado por la automatización de buzones: ~24 días de trabajo de una persona.
- Coste de IA declarado: bajo (del orden de decenas de euros al mes).
