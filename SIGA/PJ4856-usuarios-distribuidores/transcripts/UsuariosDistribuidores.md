# Notas — UsuariosDistribuidores

**Solicita:** Operaciones
**Revisión técnica:** Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx)
**Sistema:** SIGA · **Tipo:** Feature web/API

## Problema
Desde el panel del distribuidor no se visualizan todos los usuarios distribuidores asociados.

## Mejora propuesta
Cuando se consulte un distribuidor, exista la posibilidad de ver todos los usuarios relacionados a este distribuidor.

## Consideraciones para desarrollo
- Extender `GetAllUsers` con join a `usuario_distribuidor`.
- Mostrar usuarios relacionados en el panel del distribuidor.
- Definir roles con acceso (actualmente restringido a Admin / Gestor / Auditor).
- Filtros y columnas en la vista de usuarios.

## Importancia e impacto de negocio
- **Importancia:** Media
- **Impacto:** Administración comercial
- Visibilidad de usuarios por distribuidor; mejora la gestión comercial interna sin impacto directo en captación de clientes finales.
