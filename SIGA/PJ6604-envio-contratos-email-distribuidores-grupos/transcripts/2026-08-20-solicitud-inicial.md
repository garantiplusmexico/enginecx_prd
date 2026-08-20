# Solicitud inicial — Enviar contratos vía Email a Grupos y Distribuidores configurados
Fecha: 2026-08-20
Origen: prompt del desarrollador (Alejandro Govea Hernández) al iniciar /pm-prd

Enviar contratos via Email a Grupos y Disrtibuidores configurados

Para esta nueva funcionalidad se observan dos actividades, una la configuración de esta funcionalidad tanto en distribuidores como en grupos, y la siguiente al momento de generarse el contrato que sería el envío de correos a los email configurados en distribuidores y grupos.

Actualmente en el catálogo de proyectos, al editar un proyecto se habilita una pestaña donde se puede configurar si se permite el envío de correo a los beneficiarios y también el texto que se enviaría en el correo.

Tomando como base lo anterior se deberá implementar algo similar en el catalogo de distribuidores y el catalogo de grupos, en ambos se deberá al editar la información se deberá incluir una pestaña similar a la de proyectos en donde deberá habilitar si se permite el envío del contrato (con todos los documentos que este haya generado), también deberá indicar un listado de correos a los que se le deberá enviar así como la posibilidad de escribir el texto del email.

Con la configuración anterior cuando se registre un contrato, se enviará un email (con el pdf del contrato así como de los documentos adicionales generados) al listado de correos que tiene configurado el distribuidor, y de la misma manera a los registrados en el grupo (en caso de pertenecer a algún grupo y que tenga configurado esta opción).

De acuerdo a lo anterior después de enviarle el correo al beneficiario, se deberá enviar el correo a los datos registrador en el distribuidor, y por ultimo al grupo siempre y cuando tengan configurado esta opción.
