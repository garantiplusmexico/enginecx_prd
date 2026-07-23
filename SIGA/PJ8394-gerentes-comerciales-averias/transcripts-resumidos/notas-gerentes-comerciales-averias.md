# Condensado — notas-gerentes-comerciales-averias

## Decisiones
- Habilitar la consulta de averías para el rol **Gerente Comercial**.

## Alcance / requerimientos
- Que el rol Gerente Comercial pueda **consultar averías** (visibilidad de la experiencia de sus clientes).
- Verificar permisos actuales del rol en `AveriasController` (~85% ya autorizado).
- Revisar acciones puntuales: **aprobación**, **carga de documentos**, **export**.
- Filtro por `usuario_distribuidor` **ya implementado** (reutilizable para acotar a sus clientes).
- Validar/ajustar el **menú de navegación** para el rol.

## Actores
- **Gerente Comercial** (rol destino del cambio).
- Clientes/distribuidores cuyas averías consulta el gerente.

## Riesgos / pendientes
- Definir si las acciones aprobación / carga docs / export entran o quedan solo en consulta (lectura).
- Confirmar alcance del filtrado: ¿solo ve averías de sus clientes vía `usuario_distribuidor`?

## Fechas / hitos
- (No especificadas)

## Importancia / impacto
- Importancia: **Alta**. Impacto: fidelización de clientes y visibilidad comercial; actuar proactivamente ante problemas y fortalecer la relación comercial.
