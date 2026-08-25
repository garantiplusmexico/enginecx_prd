# Condensado — gg-bot-flotas-neurona

Automatización de altas y renovaciones de contratos a partir de correos de comerciales. **Es
otro dominio (venta/contratación), no averías**, pero aporta patrones de gestión de casos
incompletos que sí queremos heredar.

## Decisiones
- **Sin IA en el bucle**: la plantilla del correo se interpreta con reglas, no con modelo. Coste
  operativo por correo procesado, cero. Idea a conservar: no todo necesita IA.
- Se simplificó la plantilla que llena el comercial: solo pide lo mínimo y **el sistema intenta
  completar el resto** (buscando en el propio sistema y, si no está, leyendo por OCR los
  documentos adjuntos). Solo pide al humano lo que no logró resolver.
- Regla de negocio declarada: **no comprometer importes sin verificación humana**. La única
  excepción admitida es un caso donde la verificación *es* el correo de la persona responsable,
  y está autorizada nominalmente.
- Nunca borra correos: los archiva por resultado.

## Alcance / requerimientos — patrones reutilizables para averías
- **Gestión de expedientes incompletos:** si falta un dato o un documento, responde al
  solicitante **en el mismo hilo** pidiendo lo que falta y se queda vigilando; re-verifica cada
  ciclo si ya contestó.
- **Escalado con reloj:** si a las 2 horas no hay respuesta, avisa al responsable — y **siempre
  con copia** a operación, porque sin esa copia un caso puede quedar visto solo por una persona
  sin que el área se entere. Sigue vigilando el hilo, no abandona el caso.
- **Escalado en dos niveles:** ante un rechazo de negocio, primero pregunta al solicitante; si
  el problema persiste tras su respuesta, escala al área correspondiente y **espera un "OK"
  explícito en el mismo hilo** para dar el caso por cerrado, insistiendo con un recordatorio
  periódico configurable si no responde.
- **Contador de reintentos por caso:** cada expediente pendiente guarda cuántas veces se ha
  reclamado el dato y si ya se escaló.
- **Organización por resultado:** tramitado / pendiente de documentación / escalado / error.
- **Barrido de limpieza:** en cada ciclo revisa si hay correos de gestiones que el propio
  sistema ya cerró con éxito (confirmaciones tardías, copias) y los archiva, sin tocar un caso
  con un pendiente activo.
- **Convivencia entre automatizaciones:** reconoce los correos que pertenecen a otro proceso y
  los deja intactos en lugar de tratarlos como error.
- Registro de auditoría con una fila por correo procesado: fecha, identificador del mensaje,
  tipo, vehículo, solicitante, resultado y detalle.

## Riesgos / pendientes
- **Salvaguarda anti-duplicados desactivada:** tras un incidente en el que tres reintentos
  crearon tres contratos duplicados, se implementó la comprobación pero se dejó apagada mientras
  se estabilizaba otro flujo. Lección: la idempotencia no es opcional.
- **Falsos positivos y falsos negativos al confirmar un guardado:** varios incidentes reales
  porque el sistema daba por bueno un guardado que había fallado (o al revés). Lección: la
  verificación de que un cambio persistió debe releer el dato desde el origen, no mirar la
  pantalla.
- Reparto de nombre y apellidos, nombres abreviados, etiquetas sin dos puntos, identificadores
  con guiones: una lista larga de casos de datos sucios que hubo que ir cubriendo uno a uno.
