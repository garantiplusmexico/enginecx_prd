# Condensado — gg-bot-siniestros

Automatización que convierte los correos entrantes de siniestros en expedientes de avería. Es
el núcleo funcional a tropicalizar.

## Decisiones
- La IA clasifica y extrae datos; **no decide cobertura ni importes**. Umbrales explícitos de
  confianza: apertura ≥70%, seguimiento y "otros" ≥62%. Por debajo, revisión humana.
- Antes de abrir una avería se exige **una sola póliza ACTIVA y vigente a la fecha del
  siniestro**. Varias pólizas activas a la vez = ambigüedad = no se crea nada.
- Una reclamación/queja sobre un caso ya cerrado **nunca** reabre ni duplica el expediente.
- Si no puede resolver un correo, **no avisa a nadie**: lo deja sin leer con una etiqueta de
  color para revisión manual. (Es su comportamiento esperado, y es el principal defecto a
  corregir en nuestra versión.)

## Alcance / requerimientos
- Leer el buzón de siniestros con una ventana de solape para no perder correos.
- Descartar ruido conocido (newsletters, rebotes) sin consumir IA.
- Extraer texto de adjuntos (PDF, Word, Excel) y descartar adjuntos decorativos (logos, firmas).
- Clasificar cada correo en: **apertura / seguimiento / otro**, con nivel de confianza.
- Extraer: matrícula o identificador del vehículo, número de avería si se menciona,
  interlocutor (nombre, email, teléfono), kilómetros, fechas, descripción, resumen redactado,
  tipo de cliente, etiqueta de urgencia (RECLAMACION, URGENTE, VEHICULO PARADO) y la
  clasificación de cada adjunto.
- **Apertura:** verificar que no exista ya una avería abierta para ese vehículo; localizar el
  contrato; validar vigencia; crear la avería con provisión inicial fija; rellenar la ficha de
  gestión; escribir una observación con el resumen; subir los adjuntos y el correo original;
  notificar por email al técnico asignado.
- **Seguimiento:** localizar la avería por número (preferente) o por vehículo; evitar duplicar
  la observación si ya existe una del sistema; añadir observación con resumen y datos clave;
  subir adjuntos nuevos; notificar al técnico.
- **Otros** con vehículo o número de avería: tratar como seguimiento pero con aviso distinto.
- Marcar el correo como resuelto solo si el caso quedó realmente resuelto.
- Catálogo de tipos de documento del expediente: Permiso de circulación, Ficha técnica, Foto
  kilómetros, Orden de entrada, Presupuesto, Factura de mantenimiento, Peritación, Factura de
  peritación, Resolución, Finiquito, Varios.
- Taxonomía de motivos de revisión manual (a conservar como estados de excepción):
  baja confianza · sin matrícula · sin contrato · póliza no activa · múltiples pólizas activas ·
  fuera de vigencia · avería cerrada · tipo desconocido · gestionado (éxito).
- Capacidad de **reprocesar correos atrasados desde una fecha** sin duplicar lo ya hecho.
- Capacidad de **reparación puntual**: reintentar solo la subida de adjuntos que falló, sin
  reescribir observaciones ni volver a notificar.

## Actores
- Buzón de siniestros (entrada). Técnico asignado (destinatario del aviso). Persona que revisa
  manualmente la cola de excepciones. Cliente y taller como remitentes.

## Riesgos / pendientes
- Fallo silencioso: si el proceso se detiene, nadie se entera; solo se nota porque los correos
  dejan de procesarse.
- La lista de técnicos y sus correos está duplicada en varios sitios: dar de alta o baja a un
  técnico exige editar varios lugares.
- El modo automático actúa sin confirmación humana; se recomienda operar primero en modo
  supervisado.
- Riesgo de doble procesamiento si dos procesos corren a la vez sobre el mismo buzón.
