# Condensado — Reunión con David Simancas (Proceso de Averías, 2026-08-25)

Responsable del área de Averías para Latinoamérica. Sesión de descubrimiento del proceso real, con demo en pantalla de SIGA.

## Decisiones
- **El disparador del flujo es el correo de asignación que emite SIGA.** Cuando una agencia o taller registra una avería, el sistema la asigna a un técnico y le manda un correo a su cuenta nominal (`eduardo.alvarez@…`, `miguel.rodriguez@…`). Ese correo trae **folio de avería y VIN**, nada más.
- **El rastreo del caso es por VIN o por folio de avería, nunca por placa.** Textual: *"aquí no usamos la placa para nada"*. Queda cerrada la duda que traía el PRD v0.1.
- **La notificación del dictamen automático debe llegar al momento, no en un condensado diario.** Motivo: el reloj del compromiso de respuesta ya está corriendo; si el caso se descubre al día siguiente se pierden 8–9 horas.
- **Las averías resueltas automáticamente no se asignan a un técnico**, pero sí se le notifica. Motivo: agencias y clientes reclaman los rechazos y el técnico tiene que poder explicarlos sin haberlos trabajado.
- **No se quiere una página nueva.** Textual: *"lo ideal sería verlo en el SIGA para evitarnos todo este tema de que a nosotros nos llegue y retrabajar"*. La salida del desarrollo debe caer en el correo y en SIGA.
- **La resolución la revisa una persona antes de subirla.** Se acordó que el borrador llegue por correo, el técnico verifique texto y cifras, y él lo suba. David lo aceptó explícitamente sobre su propia preferencia inicial de que se subiera solo.
- **En los casos procedentes o dudosos la IA no redacta el dictamen**, solo llena los datos capturados; la síntesis la escribe el técnico. La captura de datos sí se automatiza en los tres casos.
- **Cualquier cambio debe homologarse a Chile y Colombia.** Se acordó probar primero en México y luego portarlo.

## Alcance / requerimientos
- **Ciclo de la avería y quién mueve cada estatus:** `Registrada` → `Validación` (ambos los mueve la agencia/taller) → **`Aceptada` o `No procede garantía` (único tramo que mueve el área técnica)** → `Taller` → `Solucionada` (los mueve la agencia) → `Cerrada`. El área técnica no puede mover nada fuera de ese tramo; para lo demás depende de TI.
- **El compromiso de respuesta es de 48 horas hábiles** y empieza a correr cuando la avería pasa a `Validación`, no cuando se registra.
- **Para pasar a validación la agencia debe subir tres tipos de documento** (evidencias, presupuesto, fotos de odómetro). El sistema no deja avanzar sin al menos uno de cada tipo. Es decir, **cuando llega el correo de asignación la evidencia ya existe**.
- **Criterios de dictamen, en el orden en que el equipo los aplica:** (1) mantenimientos en tiempo y forma —*"casi siempre un 30-40% de los rechazos recaen en que el cliente no trae sus mantenimientos"*—; (2) qué cubre el producto contratado; (3) revisión de la evidencia (fotos, video, códigos de escáner, diagnóstico).
- **Casos que David considera automatizables sin criterio humano:** intervalo de mantenimiento excedido, componente excluido, fuga excluida, multimedia fuera de cobertura. **Casos que exigen juicio:** uso y degradación, desgaste — *"ahí hay que evaluar, hay que ver evidencia, hay que ver en qué estado está el componente, es un poco más de ambigüedad"*.
- **Dolor central identificado por él mismo:** aun sabiendo de antemano que un caso no aplica, hay que crear la avería, bajar la información, generar la resolución y teclear los datos. *"Algo que creo que se pudiera automatizar"*.
- **Segundo dolor: la captura manual del documento de resolución.** El equipo transcribe a mano folio, contrato, fecha, marca y modelo en un machote de Word, desde datos que ya están en pantalla. Existen **dos formatos: Garantiplus México y Mitsubishi**.
- **La resolución es el entregable con valor legal.** Se sube a SIGA, la agencia la entrega al cliente. Todo debe vivir en SIGA para auditoría.
- **Propuesta de David sobre las plantillas:** tener borradores de resolución pre-redactados por motivo de rechazo (uno para mantenimientos, uno para fugas, uno para componentes excluidos) y que la IA solo inyecte los datos de la unidad.
- **Volumen:** ~14 averías/día en México (~291/mes entre Garantiplus y Mitsubishi), ~7/día en Chile, Colombia ~la mitad de México.
- **Asignación de técnicos:** round-robin configurado en SIGA entre los dos técnicos de México.
- **Un mismo producto cubre el 95% de la cartera de México:** el `Excellence`, de tipo "todo salvo lo excluido". El otro producto, `Expert`, es nominado con 120 componentes.

## Actores
- **David Simancas** — responsable de Averías LATAM. Sponsor operativo del desarrollo; se comprometió a facilitar formatos, datos y accesos.
- **Eduardo Álvarez y Miguel Ángel Rodríguez** — los dos técnicos de México; dictaminan y son los destinatarios de los correos de asignación.
- **Agencia / taller** — registra la avería, sube la evidencia y mueve los estatus posteriores a la aceptación.
- **Equipo de TI de SIGA (Alexis)** — único que puede cambiar el comportamiento de la plataforma y los estatus fuera del tramo técnico.

## Riesgos / pendientes
- **Pendiente de entrega:** los dos formatos de resolución (Garantiplus México y Mitsubishi) y los correos exactos de los técnicos. David quedó de mandarlos.
- **Antecedente que hay que evitar repetir:** SIGA ya rechaza automáticamente algunos casos (cuando el distribuidor solo captura refacciones no cubiertas) y lo hace **sin cargar resolución ni información alguna** — *"simplemente cierra la avería y la rechaza"*. Es exactamente el fallo silencioso que este desarrollo no debe reproducir.
- **Limitación conocida de SIGA:** no permite dos averías vigentes sobre el mismo VIN. Cuando llega un segundo fallo mientras el primero espera refacción, el equipo cierra y reabre expedientes a mano.
- **Se requiere acceso a los buzones de los técnicos** para poder disparar la automatización. Falta definir el mecanismo (delegación / cuenta de servicio / autorización OAuth).
- **David intentó este mismo desarrollo hace unos meses y no lo terminó por falta de tiempo.** El enfoque que traía era el mismo: resoluciones automáticas sobre mantenimientos y componentes excluidos.
- La automatización del llenado del documento *dentro de* SIGA queda fuera de este desarrollo: corresponde al equipo que desarrolla SIGA.

## Fechas / hitos
- 2026-08-25 — sesión de descubrimiento; entrega del tablero de averías LATAM y de un contrato Excellence de referencia.
- Pendiente sin fecha — segunda sesión de dudas una vez analizado el material.
