# Condensado — PV-02-contexto-inicial

## Decisiones
- Técnicos y coordinadores técnicos podrán VER todas las averías, sin importar el asignado.
- Técnicos: solo pueden MODIFICAR/dar seguimiento a las averías asignadas a ellos; las demás son solo consulta (solo lectura).
- El listado sigue mostrando por defecto solo las averías propias del técnico; se agrega un mecanismo para consultar todas.

## Alcance / requerimientos
- Vista de "todas las averías" para técnicos (solo lectura sobre ajenas) y coordinadores técnicos.
- Coordinadores técnicos: consultar cualquier avería y (re)asignarla a otro técnico para que la continúe gestionando.
- Resolver casos de averías asignadas a personas que ya no están en la empresa (sin visibilidad actual).
- Alcance de negocio: SIGA en todos los países.

## Actores
- Técnico (dueño de sus averías; consulta de las demás).
- Coordinador técnico (consulta global + reasignación).

## Riesgos / pendientes
- Definir el mecanismo UI de "ver todas vs. solo las mías" (toggle/filtro/pestaña).
- Confirmar si la reasignación por coordinador ya existe o es parte de este alcance.
- Reglas de permiso solo-lectura sobre averías ajenas (qué campos/acciones se bloquean).

## Fechas / hitos
- (pendiente)
