# Condensado — Proyecto de Mesa de Control - 2026_07_22 12_00 CST - Transcript

**Asistentes:** Keynor Armando Rivas Ortega (Mesa de Control, operación), Norma Zacarias (responsable del área), Omar André Lara Saldaña (TI / Engine).
**Fecha de la sesión:** 22 de julio de 2026. Duración ~31 min.

## Decisiones
- El proyecto se **parte en dos frentes**: (1) una vista de trabajo caso por caso donde se concentre toda la información de una petición (datos del formulario + conversación de correo + notas); (2) el reporteo, que se atiende después.
- **El Google Sheets actual se mantiene como fuente única de datos**: todo cambio o anotación hecho en la nueva herramienta debe reflejarse en ese mismo Sheets, para no tener dos fuentes de verdad y para no romper el proceso de tabla dinámica con el que Keynor genera sus reportes.
- **No se toca el reporteo en esta primera entrega.** Keynor seguirá exportando a Excel y armando su tabla dinámica; optimizar el reporte se ve después.
- **No se crean formularios separados.** Se descarta dividir el formulario de Google (uno para Mesa de Control y otro para siniestros de Juan/Juanjo): los clientes ya se acostumbraron a un solo formulario y cambiarlo generaría fricción.
- **Siniestros (Juan) queda fuera de este primer desarrollo.** Si la mesa de control funciona para Keynor, después se adapta o se hace otro desarrollo para el caso de Juan.
- Los **reportes de la plataforma Sigma** (desglose por aseguradora, día por día) **no los desarrolla Engine**: hay que solicitárselos al proveedor externo que lleva esa plataforma; una vez habilitado el reporte, Omar construiría la descarga/integración (mismo patrón que ya usa para pólizas). Esto **alarga el tiempo** de ese frente.
- Omar formulará la propuesta con Aldo y avisará a Norma si toma el proyecto.

## Alcance / requerimientos
- **Situación actual:** los clientes (agencias) levantan peticiones vía un **formulario de Google** muy extenso; las respuestas caen en un **Google Sheets con ~100+ columnas** donde Mesa de Control da seguimiento. Los archivos adjuntos se cargan en **Google Drive** y se referencian desde celdas del Sheets.
- **Volumen:** ~10-15 peticiones por día. El archivo acumula años de histórico.
- **Vista por caso (ticket/folio):** poder trabajar una petición a la vez, viendo solo los campos que aplican a ese tipo de trámite, sin la información de los demás casos ni las columnas irrelevantes.
- **Consolidación de canales:** en la misma vista debe estar la conversación de correo del caso, las notas/observaciones internas y los datos que llegaron del formulario. Hoy hay que saltar entre Sheets, correo, WhatsApp y Drive.
- **Navegación entre casos:** poder cambiar de caso/pendiente sin perder el contexto.
- **Campos que hoy llena la mesa (no vienen del formulario):** quién tomó la petición, proceso/estatus del trámite (atendida-concluida, en trámite con aseguradora, devuelta por falta de requisitos, en validación con área técnica, no procede), semáforo, responsable (Keynor / Pati / Norma / siniestros), aseguradora, si el solicitante podía hacerlo por su cuenta, motivo de la petición a mesa, folio generado, y un campo de observaciones donde se registra el avance para que otra persona pueda continuar el caso.
- **Campos que llegan del formulario:** fecha y hora de la petición, tipo de trámite (cotización, emisión, endoso, alta de versión…), adjuntos (una celda distinta por tipo de trámite), nombre y correo del solicitante, agencia/línea de negocio (financiera de Autocom / externas, crédito / leasing), texto con el motivo de la solicitud, número de folio con el que llegó.
- **Reportes (frente 2, diferido):** hoy Keynor filtra el mes, borra las columnas que no usa y arma una tabla dinámica para medir peticiones por solicitante, agencia, línea de negocio y tipo de trámite. La nueva herramienta no debe complicarle ese reporteo; idealmente debe generar algo equivalente. Al equipo completo le piden **reporteo semanal**.

## Actores
- **Keynor Rivas** — Mesa de Control, usuario principal: atiende las peticiones diarias, da seguimiento por correo/WhatsApp y genera los reportes de comité (p. ej. con CAF).
- **Pati** — Mesa de Control, atiende peticiones y continúa casos que Keynor dejó en curso (de ahí la importancia del campo de observaciones y de saber quién tomó cada petición).
- **Norma Zacarias** — responsable del área; solicita el proyecto y pone como condición que se facilite el trabajo diario sin dificultar el reporteo.
- **Juan / Juanjo** — siniestros; usa el mismo formulario con muy pocas peticiones. Fuera del alcance inicial, pero su presencia obliga a mantener visibles las columnas de siniestros en el Sheets.
- **Agencias / clientes solicitantes** — llenan el formulario y responden por correo o WhatsApp.
- **Aseguradoras** (Quálitas, Latino, entre otras) — destino de los trámites; determinan tiempos de respuesta.
- **Omar Lara / Aldo Álvarez (TI Engine)** — desarrollo y dirección técnica.
- **Proveedor externo de la plataforma Sigma** — dueño del desarrollo de esa plataforma; debe habilitar el reporte solicitado.

## Riesgos / pendientes
- **Dolor principal:** con 100+ columnas se pierde el cursor y hay riesgo real de **escribir la información de un caso en la fila de otro**. Norma ya ocultó columnas vacías, pero siguen existiendo y reaparecen al exportar.
- **Adjuntos inconsistentes:** algunos enlaces de Drive no abren directo; hay que copiar la liga, pegarla en WhatsApp y desde ahí abrir el archivo.
- **Documentación incompleta del solicitante:** casi siempre falta el checklist, la factura, el código postal o algún documento, o viene el equivocado. Eso obliga a 2-3 idas y vueltas por correo/WhatsApp antes de poder cerrar el caso.
- **Dependencia externa:** los reportes de Sigma dependen del proveedor de esa plataforma; sin su desarrollo no hay integración posible.
- **Riesgo de romper el reporteo:** si la nueva herramienta deja de alimentar el Sheets, Keynor pierde su método de reportes.
- **Pendiente de definir:** qué tipo de reporte exacto se necesita y cómo replicar/agilizar la tabla dinámica; cómo y cuándo se incorpora el caso de siniestros de Juan; si el seguimiento por WhatsApp también debe consolidarse en la vista del caso o solo el correo.

## Fechas / hitos
- **22-jul-2026:** segunda sesión de descubrimiento (esta reunión). Ya existe un **estimado preliminar** que Omar dio a Norma el día anterior (21-jul-2026) para el frente de reportes.
- **Siguiente paso (sin fecha comprometida):** Omar formula la propuesta con Aldo Álvarez y avisa a Norma "en estos días" si toma el proyecto.
- **Reporteo semanal** ya es una obligación vigente del equipo.
