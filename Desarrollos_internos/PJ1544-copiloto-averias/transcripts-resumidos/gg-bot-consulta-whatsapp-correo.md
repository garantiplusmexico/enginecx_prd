# Condensado — gg-bot-consulta-whatsapp-correo

Asistente de **solo lectura** para consultar el estado de un expediente y las coberturas de una
póliza. Dos canales (correo y WhatsApp) sobre el mismo núcleo de consulta.

## Decisiones
- **No crea ni edita nada.** Solo lee y responde.
- En coberturas, transcribe el **fragmento literal** del contrato relevante y **nunca concluye**
  si algo está cubierto.
- Control de acceso por **lista blanca** de personas autorizadas (por número y por correo).
  Quien no está en la lista es ignorado en silencio.
- El correo debe contener una palabra clave en el asunto para que el sistema lo procese; así no
  intenta interpretar cualquier correo interno.
- Los correos ya respondidos se archivan en una subcarpeta para no volver a procesarlos.

## Alcance / requerimientos
- Un comercial escribe una matrícula o un número de avería y recibe un resumen del estado y las
  observaciones del expediente, redactado por IA.
- Permite **repreguntar** en el mismo hilo (conversación con contexto).
- Consulta de coberturas: localizar el contrato del vehículo, leer el condicionado y devolver el
  extracto pertinente.
- Clasificar la pregunta libre del usuario en: estado / cobertura / ambas.

## Actores
- Comerciales y personal interno autorizado (~55 personas). Nadie más.

## Riesgos / pendientes
- El canal de WhatsApp está **parado a propósito** por un problema de infraestructura de la
  URL pública del webhook; el canal de correo sí opera.
- El webhook no verifica la firma del proveedor: cualquiera que descubra la URL podría suplantar
  a un usuario autorizado. Pendiente identificado.
- Dar de alta o baja a alguien de la lista blanca es manual y exige reiniciar el proceso.
