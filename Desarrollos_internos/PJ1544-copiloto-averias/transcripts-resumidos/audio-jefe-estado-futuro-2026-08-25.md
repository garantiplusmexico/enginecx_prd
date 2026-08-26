# Condensado — Audio del jefe directo, estado futuro del proceso de averías (2026-08-25)

Instrucción de reencuadre del proyecto. **Cambia el objetivo de negocio**, no solo el alcance técnico.

## Decisiones
- **El objetivo no es hacer más eficiente al equipo actual: es aumentar la capacidad por persona.** Textual: *"eso va a hacer que el equipo de técnicos, aunque sean dos, puedan incrementar el número de casos"*.
- **Se automatiza el proceso completo, incluidos los casos procedentes.** El agente debe *"recibir el caso, cargar la información, hacer una pre-evaluación y hacer validaciones de que el presupuesto cuadra, de que sí hay cobertura, y a veces generar el reporte"*. Queda atrás el alcance limitado a improcedencias.
- **Se diseña el estado futuro, no el as-is.** Textual: *"no es tanto el as-is… a Gisela y a David les gana mucho la operación, entonces tenemos que pensar en el estado futuro, cómo hacemos para automatizar el proceso para poder depender de menos gente"*.
- **México es el piloto, y lo es por una razón técnica:** *"porque la API está para México"*. Colombia y Chile entran cuando exista su API.
- **La consolidación regional es el propósito del proyecto,** no un efecto colateral: recortar la plantilla de Colombia (2 personas), recortar parte de la de Chile (3 personas), centralizar la operación en México y contratar un par de personas más allí.
- **La supervisión humana se conserva en la decisión final**, pero deja de ser caso por caso: el objetivo declarado es que la carga humana sea mínima y cada persona opere sobre un volumen mayor.

## Alcance / requerimientos
- Capacidades que el agente debe cubrir en el estado futuro: **recepción del caso · carga de información · pre-evaluación · validación de que el presupuesto cuadra · validación de cobertura · generación del reporte · comparativo**.
- La **validación del presupuesto** es un requerimiento nuevo y toca importes. Contradice el principio de las etapas iniciales de que el agente no calcula ni valora dinero, y obliga a levantar ese principio de forma explícita y acotada.
- El diseño debe soportar **tres países con tres APIs distintas** y enrutar por tipo de caso: *"dependiendo del caso que se genere, pues entra el bot, lo procesa y te hace la pre-evaluación, te hace el comparativo"*.

## Actores
- **Héctor** — nivel directivo. Origen de la intención de centralizar y de automatizar de punta a punta. Ya lo comunicó a Gisela.
- **Jefe directo del autor** — emisor del audio; traduce la intención directiva a instrucción de diseño. *(Falta confirmar si es Aldo Álvarez — ver preguntas abiertas.)*
- **David Simancas y Gisela Aldana** — fuente del as-is. El audio advierte explícitamente que su perspectiva es operativa y no debe fijar el estado futuro. Son, a la vez, responsables de las operaciones que se consolidan.

## Riesgos / pendientes
- **Los requerimientos levantados con David y Gisela describen el as-is de un proceso que se va a rediseñar.** Siguen siendo la mejor fuente del criterio técnico de dictamen —eso no cambia—, pero no pueden fijar el alcance ni el destino del proyecto.
- **Conflicto de interés estructural en la validación:** las personas que deben validar el criterio del agente y aprobar sus dictámenes son las de la operación que el proyecto reduce. Hay que decidir cómo se conduce esa conversación y quién la conduce.
- **Dependencia dura:** Colombia y Chile no tienen API. El alcance regional está condicionado a una entrega de TI que hoy no tiene fecha.
- **La automatización de casos procedentes tiene un perfil de riesgo distinto al de improcedentes:** un rechazo mal fundado se reclama; una autorización mal fundada se paga. Exige controles propios y no se puede tratar como una extensión del mismo diseño.
- Sin definir: qué se considera "que el presupuesto cuadra", y contra qué referencia se compara (baremo, Libro Azul, límite por avería, histórico).

## Fechas / hitos
- 2026-08-25 — audio con la instrucción de reencuadre.
- Sin fecha — disponibilidad de la API de escritura de México, y de las APIs de Colombia y Chile.
