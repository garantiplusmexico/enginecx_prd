# Condensado — 2026-08-20-solicitud-inicial

## Decisiones
- Se replica el patrón YA EXISTENTE del catálogo de Proyectos (pestaña de configuración de envío de correo al beneficiario + texto del correo) hacia los catálogos de Distribuidores y Grupos.
- Orden de envío definido y secuencial: 1) beneficiario (ya existe), 2) distribuidor, 3) grupo.
- El envío a distribuidor y a grupo ocurre solo si cada uno tiene la opción habilitada en su configuración.
- El envío al grupo aplica únicamente si el contrato/distribuidor pertenece a un grupo.

## Alcance / requerimientos
- Actividad 1 — Configuración: nueva pestaña al editar un Distribuidor y al editar un Grupo, análoga a la de Proyectos, con: (a) switch de habilitar envío del contrato, (b) listado de correos destinatarios, (c) texto del email.
- Actividad 2 — Envío: al registrarse un contrato, enviar email con el PDF del contrato y los documentos adicionales generados, a los correos configurados en el distribuidor y en el grupo.
- El adjunto incluye "todos los documentos que el contrato haya generado", no solo el PDF principal.

## Actores
- Usuario administrador que configura los catálogos de Distribuidores y Grupos.
- Distribuidor (destinatarios configurados).
- Grupo (destinatarios configurados).
- Beneficiario (destinatario ya soportado hoy vía configuración de Proyecto).

## Riesgos / pendientes
- No se especifica límite ni validación del listado de correos.
- No se define comportamiento ante fallo de envío (reintentos, bitácora, notificación).
- No se define si el texto del email admite variables/placeholders ni formato (HTML vs texto plano).
- No se define si aplica a contratos creados por todos los canales (UI, carga masiva, API) ni a re-emisiones.
- No se define el asunto del correo ni el remitente.

## Fechas / hitos
- (No se mencionaron fechas en la solicitud inicial.)
