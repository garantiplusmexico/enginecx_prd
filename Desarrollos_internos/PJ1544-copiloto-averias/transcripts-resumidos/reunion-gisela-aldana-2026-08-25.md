# Condensado — Reunión con Gisela Aldana (Call center y averías, 2026-08-25)

Responsable de atención a clientes / call center. Sesión corta (8 min) para entender el filtro telefónico previo a la avería.

## Decisiones
- **El filtro de call center son tres validaciones, en este orden:** (1) que el contrato esté **vigente y pagado**; (2) que lo reportado no sea una **operación no incluida**; (3) que no sea una **exclusión del contrato**. Ese es el orden en que debe razonar el agente de IA.
- **Gisela pide explícitamente que las exclusiones y las operaciones no incluidas se carguen al agente de IA** como base de conocimiento: *"eso estaría muy bien que se le cargue a la inteligencia artificial… las exclusiones y las operaciones no incluidas, eso podría ser lo que puede validar"*.
- Confirmó el modelo de decisión objetivo: **si no procede, que la IA lo detecte; si genera duda, que lo vea una persona; si procede, que avance**.

## Alcance / requerimientos
- Tras el filtro, call center pide al cliente por **WhatsApp**: foto del **mantenimiento**, foto del **kilometraje** y foto del **DOT de la llanta**. Ese es el paquete mínimo de evidencia del canal telefónico.
- **Los umbrales de mantenimiento no son fijos:** varían por producto, marca y contrato. La validación siempre se resuelve contra el contrato concreto, nunca contra una regla general.
- **Lo que más tiempo le quita al área:** validar el reporte y esperar la documentación del cliente. Textual: *"el entrar a la consulta y eso, con eso yo ya me dedicaría mejor a otras cosas… es un proceso muy sencillo, nada más le hago tres preguntas"*.
- El canal telefónico **no cambia el proceso**: el cliente igual llega a la agencia y es la agencia quien registra la avería en SIGA. Lo que aporta la llamada es filtrar antes de que el cliente se mueva.

## Actores
- **Gisela Aldana** — responsable de call center / experiencia del cliente. Dos meses en el puesto; remite a David para el detalle de coberturas.
- **Agente de call center** — entra a SIGA, valida vigencia y pago, escucha el reporte y aplica el filtro.
- **Cliente / beneficiario** — origen del reporte en este canal; envía la evidencia por WhatsApp.

## Riesgos / pendientes
- Gisela no domina todavía el catálogo de exclusiones ni el de operaciones no incluidas; la fuente autorizada es **el contrato** y, en su defecto, David.
- **Pendiente de entrega:** los contratos de los productos vigentes, que quedó de solicitar y compartir.
- Riesgo de diseño: el filtro telefónico se apoya hoy en el criterio del agente humano, sin registro estructurado de por qué se descartó un caso. No hay línea base de cuántos reportes mueren en el teléfono.

## Fechas / hitos
- 2026-08-25 — sesión de descubrimiento.
