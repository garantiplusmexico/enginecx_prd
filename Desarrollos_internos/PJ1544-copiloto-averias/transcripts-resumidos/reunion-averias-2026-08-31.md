# Condensado — Proyecto de Averías, 2026-08-31 10:55 CST

**Asistentes:** David Simancas Estrada (Controller / Analista Técnico Regional de Averías LATAM), Eduardo Álvarez Narváez (técnico de averías, México), Miguel Ángel Rodríguez y Ruiz (técnico de averías, México), Omar André Lara Saldaña (EngineCX).

## Decisiones

- **El copiloto deja de ser un pipeline de un solo disparo.** Omar lo replanteó en sesión y el equipo lo confirmó: *"la idea sería que la IA fuera analizando cada alerta de correo que les va llegando… llegará un correo que ya tengamos suficiente información para deliberar y ya la IA pueda emitir su reporte preliminar"*. El flujo de n8n se ejecuta **a la recepción de cada correo**; por cada avería llegan varios (apertura + actualizaciones: la agencia subió un documento, hubo cambio de estatus, etc.). La dinámica es **llevar seguimiento de todas las averías en proceso y emitir la deliberación en el momento en que la información acumulada basta**; si no basta, esperar.
- **Se aprueba un reporte diario de estatus de averías.** Omar lo propuso —*"un mini reporte ejecutivo… qué casos llevamos activos, cómo vamos de información, qué tanta información falta para cada caso y cuáles ya están listos para procesar"*— y los tres lo aceptaron. Eduardo fijó la franja: **en la mañana**, porque las agencias suben evidencia hasta las 8, 9 y 11 de la noche y el equipo llega a un montón de correos sin procesar.
- **El área elabora un documento de requisitos mínimos de evidencia por sistema.** David se comprometió: *"déjanos armar un documento donde pongamos requisitos mínimos, evidencia mínima para poder evaluar transmisión, motor y demás"*. Primer borrador ofrecido para el día siguiente.
- **La IA debe tomar el caso desde `Validación`, no desde `Registrada`.** David: *"en registrado a veces no va a haber mucho sentido, pero desde que pasa validación desde ya pudiera tomarlo la inteligencia"*.

## Alcance / requerimientos

- **Suficiencia de evidencia, cuantificada.** Miguel: *"yo creo que el 5% de las averías ya con lo que mandan se puede evaluar. Es muy raro que desde que lo subieron ya sepamos, porque cada caso se evalúa de manera distinta"*. El paso a `Validación` **no** garantiza expediente completo, aunque en teoría implique presupuesto y evidencia cargados.
- **Evidencia mínima varía por sistema.** Ejemplo de transmisión dado por Miguel: estado del aceite, presencia de residuos, escaneo de la transmisión, fallos de la transmisión. Una foto suelta —caso típico de un compresor de A/C— no sustenta ni el pago ni el rechazo.
- **El conocimiento previo no sustituye a la evidencia.** Miguel sobre las transmisiones de Captiva: *"el 99% de los casos se rechaza, pero aún así necesitamos la evidencia para poder rechazar"*. El sustento documental es obligatorio incluso cuando el resultado se anticipa.
- **Dinámica real de solicitud de evidencia:** el equipo primero pide a la agencia que pase la avería a `Validación` (y comparte los pasos), y **solo entonces** solicita la evidencia necesaria para aprobar o rechazar. Cuando la agencia la comparte, se adjunta como sustento de la resolución.
- **Los casos fáciles son minoría.** Elementos excluidos directamente por la cobertura básica (`Expert`) o componentes fuera de cobertura —suspensión, amortiguador, soportes— se resuelven rápido, pero *"ya es la minoría de los contratos"* y *"son la minoría de los casos"*.
- **Nuevo estatus de falta de evidencia en SIGA** (ver también el condensado del proyecto de API). David: *"debería existir un estatus que es falta de evidencia o documentación incompleta… ese estatus no lo hemos desarrollado y creo que es muy importante hacerlo antes de que podamos continuar con estos flujos"*. Doble propósito: alertar al distribuidor y **medir tiempos reales por responsable**.

## Actores

- **Miguel Ángel Rodríguez y Eduardo Álvarez** — técnicos de averías de México; fuente del criterio operativo de dictamen y de qué evidencia hace falta por sistema. David los describe como *"expertos… ellos lo traen el día a día"*.
- **David Simancas** — responsable regional; aporta el marco (documento de evidencia mínima, propuesta de las 4 capas) y el argumento de medición de tiempos.
- **Agencia / distribuidor** — quien sube la evidencia por goteo y de quien depende que un caso llegue a ser deliberable.

## Riesgos / pendientes

- **El reloj no distingue quién debe.** David: *"Miguel tiene una avería en validación y todo el tiempo que esa avería esté en validación a él le cuentan sus medidores de tiempos… contesta a los 5 minutos pidiendo una foto más y a él no le contestan hasta dentro de dos o tres días, y ahí ya le afectó. A pesar de que no es culpa de él"*. Sin el estatus intermedio no se puede medir ni al técnico ni al distribuidor.
- **Medición del distribuidor como palanca comercial.** *"Este distribuidor siempre me dura en contestar 15 horas… y esto ayuda a que el equipo comercial diga: tenemos estos 15 distribuidores que no dan seguimiento en tiempo, visítalos"*.
- **Pendiente de entrega del área:** documento de requisitos mínimos de evidencia por sistema (transmisión, motor, compresor y demás).
- **Pendiente de Omar:** credenciales de los correos.

## Fechas / hitos

- **2026-08-31** — sesión.
- **2026-09-01** (ofrecido) — primer borrador del documento de evidencia mínima por sistema.

## Nota de contexto

David encuadró el proyecto: *"este es el proyecto más importante de Averías de lo que va de los años, porque es lo que queremos: migrar, la automatización. Cuenta con todo el apoyo de nosotros."*
