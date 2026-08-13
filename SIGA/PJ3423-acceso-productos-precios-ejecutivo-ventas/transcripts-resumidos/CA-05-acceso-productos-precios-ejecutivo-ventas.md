# Condensado — CA-05 Acceso a distribuidores, productos y precios para Ejecutivo de Ventas

## Decisiones
- El acceso del Ejecutivo de Ventas a productos y precios será **solo lectura** (no editar, no actualizar).
- La funcionalidad se desarrolla **preparada para todos los países**, pero su habilitación queda **gobernada por un parámetro en settings** (on/off).

## Alcance / requerimientos
- Ampliar permisos del rol **Ejecutivo de Ventas** para **ver** productos y precios de sus **distribuidores asignados**.
- Restricciones explícitas: **no** actualizar datos, **no** descargar reportes.
- Nuevo **parámetro en settings** que indica si la funcionalidad se permite o no (por país / configuración).

## Actores
- **Ejecutivo de Ventas** (rol que gana el nuevo acceso de lectura).
- Distribuidores asignados a ese ejecutivo (dueños de los productos/precios que se visualizan).

## Riesgos / pendientes
- Definir el **nivel/granularidad** del parámetro de settings (global, por país, por distribuidor).
- Confirmar cómo se determina la relación "distribuidores asignados" al Ejecutivo de Ventas.
- Precisar qué pantallas/menús exponen productos y precios y cómo se ocultan las acciones de edición/descarga.

## Fechas / hitos
- (Sin fechas comprometidas en el insumo.)
