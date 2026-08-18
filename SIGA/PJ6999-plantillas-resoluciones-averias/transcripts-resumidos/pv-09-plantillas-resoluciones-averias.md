# Condensado — PV-09: Plantillas para resoluciones de averías

## Decisiones
- Generar la resolución de avería **dentro de SIGA** (hoy se hace manual, por fuera).
- Usar una **plantilla** que se **prellena automáticamente** con los datos de la avería ya
  registrados en SIGA.
- Habilitar en **siga-averias** una sección para que el **técnico** escriba el **texto de la
  resolución**; ese texto alimenta el documento final.
- Generar **automáticamente el PDF** que se envía al cliente.
- Ofrecer una vía alterna: **descargar la plantilla prellenada**, completarla fuera (imágenes,
  tablas, detalle extra) y **volver a subirla** completa para enviarla al cliente.

## Alcance / requerimientos
- Plantilla de resolución aplicable a averías **procedentes y no procedentes**.
- Prellenado con datos de la avería desde SIGA.
- Campo/editor de texto de resolución capturado por el técnico.
- Generación de PDF automática a partir de plantilla + datos + texto.
- Descarga de plantilla prellenada + recarga del documento completado (flujo manual opcional).
- Envío del documento al cliente.

## Actores
- **Técnico** (redacta el texto de la resolución; opcionalmente completa el documento).
- **Cliente** (recibe la resolución en PDF).

## Riesgos / pendientes
- Definir si el envío al cliente es dentro de SIGA o externo, y por qué canal.
- Formato/branding de la plantilla y variantes (procedente vs. no procedente).
- Qué datos exactos de la avería se prellenan.
- Validaciones antes de enviar (aprobación, revisión).

## Fechas / hitos
- (Sin fechas provistas.)
