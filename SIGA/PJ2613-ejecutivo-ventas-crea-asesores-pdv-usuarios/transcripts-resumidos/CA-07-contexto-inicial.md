# Condensado — CA-07-contexto-inicial

## Decisiones
- Habilitar al rol **Ejecutivo de Ventas** la creación de **Asesores**, **Puntos de Venta** y **usuarios**.
- Los usuarios que puede crear el Ejecutivo de Ventas se limitan a los roles **Ejecutivo de Ventas** y **Usuario Distribuidor**.
- La funcionalidad se deja **preparada para todos los países**.
- Su habilitación/deshabilitación se controla por un **parámetro en settings** (por país).

## Alcance / requerimientos
- Alta de Asesores por el Ejecutivo de Ventas.
- Alta de Puntos de Venta por el Ejecutivo de Ventas.
- Alta de usuarios (solo roles Ejecutivo de Ventas y Usuario Distribuidor).
- Parámetro de settings que permita activar/desactivar la funcionalidad.

## Actores
- Ejecutivo de Ventas (nuevo permiso de creación).
- Asesor, Punto de Venta, Usuario Distribuidor (entidades/roles creados).

## Riesgos / pendientes
- Definir el alcance/nivel del parámetro de settings (global vs por país).
- Definir qué datos son obligatorios al crear cada entidad.
- Reglas de a quién/qué distribuidor o punto de venta quedan asociados los usuarios creados.

## Fechas / hitos
- (Sin fechas comprometidas en el contexto inicial.)
