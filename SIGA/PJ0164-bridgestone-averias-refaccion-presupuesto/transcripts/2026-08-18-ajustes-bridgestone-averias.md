# Solicitud del desarrollador — 2026-08-18

Bridgestone se encarga únicamente de llantas, por lo cual vamos a hacer solo unos ajustes
al módulo de averías cuando el proyecto seleccionado esté en Bridgestone.

En la sección de Refacciones y Mano de Obra, cuando estemos en Bridgestone:
- El campo "Tipo" siempre estará como "Refacción".
- El campo "Refacción" siempre estará como "Llanta".
- Son selectores: hay que preseleccionar esos valores y dejar los campos como solo lectura.
- "Refacción" se llena cuando se selecciona "Tipo".
- Adicional, se deben ocultar los campos "No. de parte" y "M.O.".

En la sección de Presupuesto:
- Hay un selector de presupuesto; este debe estar siempre seleccionado en "I.V.A. cero"
  y ser de solo lectura igual.
