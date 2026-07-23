# Condensado — Notas: Documentos Obligatorios Posteriores a la Aprobacion de la Averia

## Decisiones
- Enviar notificaciones automáticas al taller con la lista de documentos requeridos tras cada aprobación / cambio de estatus.
- Reutilizar el mecanismo de correo por cambio de estatus (`NotificaCambioEstatus`) para incluir el listado de documentos necesarios del nuevo estatus.

## Alcance / requerimientos
- Definir la lista de documentos requeridos por cada estatus del proceso de avería **posterior a la aprobación**.
- Al ocurrir un cambio de estatus, enviar email al taller indicando el nuevo estatus y el listado de documentos que debe ingresar en ese estatus.

## Actores
- **Taller** (destinatario del correo / quien ingresa los documentos).
- Proceso de averías post-aprobación (SIGA).

## Riesgos / pendientes
- Falta definir la lista concreta de documentos por estatus.
- Falta identificar qué estatus del proceso post-aprobación disparan notificación.
- Confirmar el mecanismo/plantilla actual de `NotificaCambioEstatus`.

## Fechas / hitos
- (No especificadas)

## Importancia / impacto
- Importancia: **Media**.
- Impacto: fidelización de clientes y eficiencia operativa; reduce demoras en pago y mejora la claridad del proceso para el taller.
