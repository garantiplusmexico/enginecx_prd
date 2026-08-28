# Condensado — 2026-08-28-brief-inicial-omar

## Decisiones
- API abierta de bitácora: cada request POST = una línea escrita al archivo de logs.
- Dos entidades de datos: (1) el archivo de logs (la principal), (2) un folder de JSON con la metadata de cada proyecto registrado.
- Alta de proyecto PRIMERO: al completarse, el sistema asigna un ID único de 4 dígitos y lo devuelve al cliente; con ese ID el cliente manda sus logs.
- Metadata del proyecto es de estructura LIBRE salvo tres campos fijos: `id`, `nombre`, `path`. El resto es abierto (qué hace, si usa AWS/GCP, cada cuándo se ejecuta, en qué máquina corre, etc.).
- Estatus permitidos en la línea de log: `error`, `success`, `warning`, `test`, `urgent`.
- Corte = función, NO endpoint: un script ejecutable `python3 corte.py`, sin sobre-ingeniería. Rota el log principal a `archive/log_{date}_c{n}.txt` (n inicia en 0 por día) y deja vacío el archivo activo. El histórico completo se reconstruye uniendo los archivos de archive en orden.
- Fase 2 = análisis con IA: rutina de Claude Code que ejecuta un corte, lee el corte del día y lo analiza.
- El análisis por ahora solo ALERTA y REPORTA (ninguna otra acción).
- Reporte ejecutivo en correo HTML con tabla: qué se ejecutó correctamente, qué dio error, warnings, pruebas, etc.
- Envío de correo vía webhook de n8n ya existente y ya preparado para mandar mails.
- Endpoint de chat con el agente, con streaming, "como si fuera mi Claude Code". Puede leer todos los cortes de archive y crear cortes a petición.
- La API corre como servicio del sistema operativo, enabled para arrancar con la computadora. El plan de desarrollo debe contemplar los preparativos del alta como servicio.
- Documentación OpenAPI servida desde el propio subdominio, autodescubrible: basta decirle a Claude Code "manda las logs a logs.larasalab.com" para que indague solo cómo funciona.
- La documentación debe cubrir tipos de estado, metadatos, todas las posibilidades y cómo hacer las requests, con ejemplos de todo.
- `logs.larasalab.com` apunta a la máquina Linux mediante un túnel de Cloudflare.

## Alcance / requerimientos
- Endpoint de alta de proyecto (devuelve ID de 4 dígitos).
- Endpoint de ingesta de log: mensaje + project_id + estatus + campos adicionales de diagnóstico (a definir; el solicitante pide sugerencias).
- Script `corte.py` de rotación con nomenclatura `log_{date}_c{n}.txt`.
- Rutina de análisis con IA + reporte HTML por correo vía n8n.
- Endpoint de chat con streaming contra el agente, con acceso a archive y a crear cortes.
- Servicio de sistema operativo habilitado al arranque.
- Documentación OpenAPI autodescubrible en el subdominio.

## Actores
- Analista de datos: lector principal de las líneas de log y del reporte ejecutivo; se basa en ellas periódicamente para saber qué está pasando.
- Claude Code de cada proyecto dado de alta: cliente que descubre la API y manda los logs.
- Agente de IA: ejecuta cortes, analiza, alerta y reporta; también atiende el chat.
- Omar Lara: solicitante, autor y revisión del PRD; operador de la máquina Linux.

## Riesgos / pendientes
- Pendiente: qué campos adicionales llevará la línea de log (se solicitan sugerencias orientadas a diagnóstico para un analista de datos).
- "API abierta" sin autenticación definida: pendiente el esquema de acceso.
- Espacio en disco y crecimiento del archive sin política de retención definida.

## Fechas / hitos
- Corte automático: 1 al día, a las 11:00.
- Fase 1: API + alta de proyectos + ingesta + corte + servicio + docs OpenAPI.
- Fase 2: análisis con IA, reporte por correo y endpoint de chat.
