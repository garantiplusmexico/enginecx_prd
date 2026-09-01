# Condensado — Proyecto de Averías, 2026-08-31 10:55 CST *(lo relevante para SIGA)*

**Asistentes:** David Simancas Estrada (Controller / Analista Técnico Regional de Averías LATAM), Eduardo Álvarez Narváez y Miguel Ángel Rodríguez y Ruiz (técnicos de averías, México), Omar André Lara Saldaña (EngineCX).

> Este condensado recoge **solo** lo que toca a la plataforma SIGA. El resto de la sesión —el modelo de seguimiento del copiloto y el reporte diario— está condensado en `Desarrollos_internos/PJ1544-copiloto-averias`.

## Decisiones

- **Se pide un nuevo estatus de avería para la falta de evidencia.** David lo planteó como bloqueante de todo lo demás: *"debería existir un estatus que es falta de evidencia o documentación incompleta o un término así, pero que pueda diferenciar entre ese proceso… ese estatus no lo hemos desarrollado y creo que es muy importante hacerlo antes de que podamos continuar con estos flujos"*.
- **Es un cambio intentado y nunca desarrollado.** David: *"dentro del flujo, para que funcione, que es algo que hemos intentado cambiar, no se ha desarrollado, es este cambio de estatus"*.

## Alcance / requerimientos

- **El problema concreto: la avería no se mueve de `Validación`.** *"Sí lo mandaste a evaluación, está bien, pero te falta evidencia. De ahí la avería no se mueve. A pesar de que Miguel pida más evidencia o pida algo adicional, la avería sigue en validación."*
- **Propósito 1 — medir tiempos reales por responsable.** *"Miguel tiene una avería en validación y todo el tiempo que esa avería esté en validación a él le cuentan sus medidores de tiempos, y en ocasiones Miguel contesta a los 5 minutos pidiendo una foto más o un documento más y a él no le contestan hasta dentro de dos días, tres días, y ahí a él ya le afectó. A pesar de que no es culpa de él… y el distribuidor pues tampoco lo medimos."*
- **Propósito 2 — medir al distribuidor.** *"Es importante empezar a medir a ellos: oye, este distribuidor siempre me dura en contestar 15 horas, 20 horas; este distribuidor contesta muy rápido. Ir midiendo la velocidad o lo bien que responde cada distribuidor."*
- **Propósito 3 — palanca comercial.** *"Esto ayuda a que hoy el equipo comercial diga: tenemos estos 15 distribuidores que no dan seguimiento en tiempo, visítalos y ajústalos. De ahí salen muchas cosas."*
- **Propósito 4 — reasignar la responsabilidad.** *"Se agiliza esto y también cargamos la obligación y la responsabilidad hacia la agencia."*
- **Automatización de alertas al distribuidor** como uso derivado del estatus: *"nos va a servir para automatización de alertas hacia el distribuidor… le manda la alerta de que se regresó la avería porque hace falta evidencia"*. **Fuera del alcance del PRD por decisión de Omar (2026-09-01):** se pide el estatus, la bitácora y la medición; la alerta se solicitará por separado si se decide construirla.

## Actores

- **Técnico de averías** — quien detecta que falta evidencia y necesita poder marcarlo.
- **Distribuidor / agencia** — quien sube la evidencia faltante; sujeto de la medición nueva.
- **Equipo comercial** — consumidor final de la métrica de respuesta por distribuidor.
- **Equipo de desarrollo de SIGA** — destinatario del PRD.

## Riesgos / pendientes

- Sin el estatus intermedio, **ninguna métrica de tiempo de respuesta es interpretable**: no se puede distinguir el tiempo imputable al técnico del imputable al distribuidor.
- El cambio se declara **precondición de los flujos de automatización** del copiloto, no una mejora opcional.

## Fechas / hitos

- **2026-08-31** — sesión donde se pide el cambio. Sin fecha comprometida por parte de SIGA.
