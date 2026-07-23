# Condensado — UsuariosDistribuidores

## Decisiones
- Tipo de proyecto: Feature web/API (B) sobre SIGA.
- Alcance: al consultar el detalle de un distribuidor, mostrar los usuarios relacionados a ese distribuidor.

## Alcance / requerimientos
- Extender `GetAllUsers` con join a `usuario_distribuidor`.
- Mostrar usuarios relacionados en el panel del distribuidor.
- Filtros y columnas en la vista de usuarios.
- Acceso restringido por rol: Admin / Gestor / Auditor.

## Actores
- Solicita: Operaciones.
- Revisión técnica: Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx).
- Usuarios del módulo: roles Admin / Gestor / Auditor.

## Riesgos / pendientes
- Definir con precisión qué roles ven la información.
- Confirmar columnas/filtros exactos de la vista de usuarios relacionados.

## Fechas / hitos
- (Sin fechas comprometidas por ahora.)

## Importancia / impacto
- Importancia: Media. Impacto: Administración comercial (gestión comercial interna; sin impacto directo en captación de clientes finales).
