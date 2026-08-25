# Condensado — gg-bot-nominadas

Circuito de rehúse asistido con aprobación humana explícita. Es el mejor patrón de
"humano en el bucle" de todo el sistema y conviene heredarlo tal cual.

## Decisiones
- **"Decide flujo, nunca decide dinero ni cobertura."** La IA solo informa un dato objetivo
  (si la pieza figura o no en el listado de bienes asegurados) con su nivel de confianza.
- Solo aplica a productos con **cobertura nominada** (lista mantenida como documento de
  negocio editable, no en código). Si el producto no está en la lista, el caso se descarta.
- Umbral de confianza para proponer un rehúse: **75%**. Por debajo, revisión manual.
- Umbral para interpretar una instrucción humana que no sea un "Ok" seco: **85%**.
- Si el vehículo tiene más de una póliza activa, o no se encuentra el contrato: revisión
  manual. **Nunca se adivina cuál es la póliza correcta.**
- El texto legal que recibe el cliente es un documento fijo aprobado; la IA **nunca lo
  reescribe**, solo inserta nombre y número de expediente.
- Si un dato no consta en la documentación, el campo se rellena con "No consta en la
  documentación": está prohibido inventarlo.
- La generación del documento se **aborta** si queda algún campo sin sustituir.
- Ventana de silencio con el aprobador (viernes tarde a lunes por la mañana): las propuestas se
  siguen generando y se entregan al reabrir la ventana. Caduca sola en una fecha configurada.

## Alcance / requerimientos
- Revisar periódicamente las averías en estado "pendiente de revisión".
- Identificar el producto y la póliza del vehículo; descargar el certificado.
- Leer la declaración del cliente/taller y los adjuntos (presupuestos, fotos, órdenes de
  trabajo) e identificar **qué pieza se pide reparar**.
- Comprobar si esa pieza figura en el artículo de bienes asegurados del certificado.
- Si no figura y hay confianza suficiente: generar la resolución en PDF a partir de un molde
  por compañía aseguradora, **fusionada con el presupuesto del taller**.
- Enviar la propuesta al aprobador con: el documento, el razonamiento de la IA y el texto
  exacto que recibiría el cliente.
- Recoger la respuesta del aprobador con un ciclo corto e independiente. "Ok" seco = aprobación
  directa sin pasar por IA; respuesta elaborada = interpretar la instrucción (cerrar o no,
  avisar o no al cliente) con umbral alto.
- Con la aprobación: ejecutar la secuencia de cierre del expediente **verificando de verdad**
  cada paso (recargando y comprobando el resultado, no asumiendo el éxito); escribir una
  observación resumen; subir el PDF al expediente; enviar el correo final al cliente; guardar
  copia del envío como prueba; archivar el hilo.
- Informe de cierre de ciclo al aprobador: propuestas, descartes, cierres y **el backlog
  completo de lo que sigue en revisión manual** (no solo lo nuevo del día).
- No reprocesar ni reenviar nada dos veces: cada caso guarda su fase.

## Actores
- Director/aprobador de prestaciones (única persona en el bucle; aprueba por correo).
- Cliente (destinatario del rehúse). Taller (aporta presupuesto).

## Riesgos / pendientes
- Ya ocurrió un envío duplicado al cliente por dos ejecuciones solapadas.
- Si un paso del cierre no se confirma, el caso se queda pendiente y se reintenta; hay que
  revisarlo a mano antes del reintento.
- Objetivo declarado a futuro: que el sistema rehúse solo, sin aprobación, cuando se compruebe
  que identifica bien los casos. Decisión de negocio pendiente.
