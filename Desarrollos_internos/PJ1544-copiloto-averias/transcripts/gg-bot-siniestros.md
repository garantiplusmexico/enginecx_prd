# Bot Siniestros - Garantia Global
## Instrucciones de instalacion y uso

> **Si eres nuevo y no sabes nada de este bot, lee esto primero.**
> Automatiza el ciclo completo de un siniestro: lee los correos que
> llegan al buzon `siniestros@garantiaglobal.com`, usa IA (Claude) para
> entender de que se trata, y segun el caso abre una averia nueva en la
> intranet o añade un seguimiento a una ya existente, subiendo los
> adjuntos y avisando por correo al tecnico asignado. No tiene pantalla
> ni interfaz: corre en segundo plano cada hora via tarea programada de
> Windows.
>
> **Regla de negocio critica (no es un bug, es el comportamiento
> esperado):** si el bot NO puede abrir o tramitar un correo (fallo
> tecnico, matricula no encontrada, contrato ambiguo, poliza no
> vigente...), **nunca envia un email automatico avisando del fallo a
> nadie**. Lo unico que hace es dejar ese correo **SIN LEER** en la
> bandeja de entrada (a veces con una categoria de Outlook en color
> para que se vea a simple vista) para que una persona lo revise a
> mano. Ver la seccion "CASOS QUE QUEDAN PARA REVISION MANUAL" mas
> abajo.

### OJO: hay tres scripts "bot_*.py" y NO son intercambiables

Han ido evolucionando y hoy conviven los tres en la carpeta, pero **el
que realmente se ejecuta en produccion es `bot_seguimiento.py`**, pese
a que su nombre sugiera que solo hace seguimientos:

- **`bot_seguimiento.py`** -> es el bot "completo" actual (su propio
  codigo lo dice: "BOT SINIESTROS (COMPLETO)"). Gestiona aperturas,
  seguimientos y correos "otros", con reconexion automatica si Outlook
  falla, filtro de duplicados, comprobacion de poliza activa/vigente,
  deteccion de reclamaciones, y categorias de Outlook para marcar casos
  que necesitan revision manual. **Es el que lanza la tarea programada
  `BotSiniestrosGG`.**
- **`bot_apertura.py`** -> variante que solo procesa aperturas; importa
  y reutiliza funciones de `bot_seguimiento.py` (no duplica su codigo,
  aunque si tiene copias propias, ligeramente mas simples, de
  `crear_averia_desde_contrato`/`rellenar_gestion`). Sirve para forzar
  la apertura de una matricula concreta paso a paso:
  `python bot_apertura.py --test MATRICULA`. No tiene tarea programada
  propia activa.
- **`bot_siniestros.py`** -> version antigua/standalone, la que
  describia originalmente este documento. **Le faltan las protecciones
  que si tiene `bot_seguimiento.py`**: no comprueba que la poliza este
  ACTIVA y en vigor antes de crear una averia, no distingue reclamacion
  de seguimiento real, no usa categorias de revision manual (si algo
  falla, el correo simplemente no se marca ni se mueve, sin quedar
  señalado), y no tiene la reconexion robusta a Outlook por hilos. Ya
  no la lanza ninguna tarea programada, pero se ha dejado en la
  carpeta. No la uses de referencia para replicar comportamiento.

Si vas a tocar el comportamiento del bot en produccion, **edita
`bot_seguimiento.py`**, no `bot_siniestros.py`.

### ARCHIVOS DEL PROYECTO

**Nucleo (produccion):**
- `config.py`            -> Credenciales y configuracion (ver mas abajo)
- `bot_seguimiento.py`   -> Script que realmente corre en produccion (ver arriba)
- `bot_apertura.py`      -> Solo aperturas, reutiliza bot_seguimiento.py
- `bot_siniestros.py`    -> Version antigua, ya no usada por las tareas programadas

**Instalacion / programacion:**
- `instalar_y_configurar.bat` -> Instalador inicial: instala dependencias y crea una
  tarea `BotSiniestrosGG` que en ese momento apunta a `bot_siniestros.py` (la version
  vieja). Hace falta ejecutar `programar_bot.bat` despues para corregirla.
- `programar_bot.bat`    -> Borra cualquier tarea `BotSiniestrosGG`/`BotSeguimientoGG`
  previa y crea `BotSiniestrosGG` apuntando a `bot_seguimiento.py --auto`, cada hora,
  usando la ruta COMPLETA del ejecutable de Python (necesario porque una tarea
  programada no hereda el PATH del usuario). **Es el script que hay que usar.**
- `programar_seguimiento.bat` -> Crea una tarea aparte, `BotSeguimientoGG`, tambien
  contra `bot_seguimiento.py --auto` pero invocando `python` sin ruta completa (puede
  no funcionar en el contexto de una tarea programada si no hay PATH configurado) y
  menciona ejecutar antes un `rematar_hoy.py` **que no existe en esta carpeta**. A dia
  de hoy esta tarea NO esta creada en este PC (solo existe `BotSiniestrosGG`). **No lo
  ejecutes** salvo que sepas que estas haciendo: si llegases a tener las dos tareas
  activas a la vez, cada correo se procesaria dos veces por hora.

**Recuperacion e incidencias:**
- `Errores\` (subcarpetas `APERTURAS\` y `SEGUIMIENTOS\`) -> Correos .msg guardados de
  casos reales donde el bot fallo; historial de incidencias para consultar a mano.
- `ultimo_checkpoint.txt` -> Nota de referencia con la fecha/hora del ultimo punto procesado.
- `recuperar_desde_fecha.py DD/MM/AAAA` -> Reprocesa (con el bot completo) todos los
  correos desde esa fecha que sigan en la bandeja, sin duplicar lo ya hecho.
- `recuperar_desde_viernes.py` -> Atajo del anterior con una fecha fija ya puesta.
- `resubir_documentos.py MATRICULA... | TODO` -> Reparacion puntual: solo vuelve a
  subir los adjuntos que fallaron (no escribe observaciones, no avisa a tecnicos, no
  marca ni mueve correos), por eso es seguro repetirlo.
- `revision_masiva_adjuntos.py`, `diagnosticar_pendientes.py`,
  `completar_4_pendientes.py`, `completar_ultimos_2.py`, `comprobar_sin_averia.py`,
  `listar_procesados_con_adjuntos.py` -> Scripts puntuales usados para arreglar
  incidencias concretas de agosto/2026 (ver sus cabeceras). No son de uso rutinario;
  quedan como referencia de como se resolvio cada caso.
- `_tmp_revision_masiva\`, `_tmp_1481MBY\` -> Carpetas temporales con adjuntos usados
  durante esas reparaciones puntuales; se pueden borrar sin riesgo.
- `PRUEBA_BOT.txt` -> Notas sueltas de pruebas manuales.

**Diagnostico (no tocan nada, solo inspeccionan):**
- `diag_contratos.py`, `diag_gestion.py`, `diag_bandeja.py`, `diag_buzones.py`,
  `diag_leidos.py`, `diag_estructura.py`, `_diagnostico_conteo_leidos.py`,
  `listar_carpetas_buzon.py`, `ver_archivos_averia.py`, `ver_html_subida.py`,
  `ver_contenedor_dropzone.py`, `ver_dropzone_api.py`, `probar_marcar_recibido.py`
  -> Exploran la pagina de la intranet o el buzon de Outlook para entender su
  estructura (selectores, carpetas, HTML). Utiles si algo deja de encontrar un boton
  o una carpeta tras un cambio en la web o en Outlook.
- `test_*.py` (`test_obs.py`, `test_buscar.py`, `test_subir.py`,
  `test_subir_multiple.py`, `test_apertura.py`, `test_carpeta.py`,
  `test_una_matricula.py`) -> Pruebas manuales sueltas de partes concretas del flujo.
- `ver_correo_1481MBY.py`, `subir_pendiente_1481MBY.py`, `subir_email_1481MBY.py` ->
  Scripts de un solo uso para arreglar el caso concreto de la matricula 1481MBY
  (agosto/2026); no son reutilizables tal cual para otro caso.
- `tras_click_subir_14021.png`, `verificacion_post_subida_14021.png`,
  `archivos_averia_14021.png`, `tras_marcar_recibido_14021.png`,
  `verificacion_email_subido_14021.png` -> Capturas de pantalla tomadas durante el
  diagnostico de esos casos concretos; se pueden borrar sin riesgo.
- **`test_login2.py.py`** -> **Script de prueba suelto, NUNCA se ejecuta en
  produccion.** Tiene un email y una contraseña **personales** de una persona del
  equipo escritos directamente en el codigo (no vienen de `config.py`). Ver aviso de
  seguridad en la seccion siguiente.

---

### DONDE ESTAN LAS CONTRASEÑAS Y CLAVES

Todo en texto plano en **`config.py`**, junto al resto de la configuracion:
- `GG_URL` -> URL de la intranet (`intranet.garantiaglobal.com`), no es secreta.
- `GG_EMAIL` / `GG_PASSWORD` -> login en la intranet de Garantia Global (mismas
  credenciales que usan `averias_bot` y `W.app averias`, proyectos hermanos).
- `BUZON_SINIESTROS` -> direccion del buzon compartido que se lee (no es secreta).
- `ANTHROPIC_API_KEY` -> clave real de la API de Claude (console.anthropic.com),
  usada para que la IA lea y clasifique cada email. **Es una clave de pago en uso.**
- `EJECUTAR_SIN_SUPERVISION` -> `True`/`False`, ver Paso 5 mas abajo.
- `HORAS_ATRAS_EMAILS` -> solo la usa la version antigua `bot_siniestros.py`;
  `bot_seguimiento.py` (la que corre en produccion) usa su propia constante interna
  `VENTANA_HORAS = 2` (definida arriba del todo del fichero), asi que cambiar este
  valor en `config.py` **no** afecta al bot que realmente se ejecuta.
- `CARPETA_ADJUNTOS_TEMP` -> carpeta temporal en disco donde se guardan los adjuntos
  mientras se procesan; se borra sola al final de cada ejecucion.

No hay contraseña de correo: el bot usa el Outlook de escritorio ya
abierto y logueado en el PC (via COM/`win32com`), no autentica por su
cuenta contra el correo. Por eso Outlook debe estar abierto y con la
sesion iniciada en el PC donde corre la tarea programada.

**Aviso de seguridad pendiente de resolver:** el archivo suelto
`test_login2.py.py` (nombre de archivo con doble extension `.py.py`,
tal cual) tiene escritos directamente en el codigo un email y una
contraseña **personales** de una persona del equipo (no de una cuenta
de servicio ni de `config.py`). No es parte del bot, es una prueba
manual de login que alguien dejo en la carpeta. Habria que:
1. Quitar esa credencial del archivo (o borrar el archivo, ya que su
   unico proposito era probar el login de forma manual).
2. Si esa contraseña personal sigue siendo valida, rotarla: no debe
   quedar en texto plano dentro de un script de prueba en una carpeta
   que puede compartirse o sincronizarse.

---

### PASO 1 - Copiar los archivos a tu PC

Para una instalacion nueva en otro PC, copia esta carpeta a una ruta
local estable, por ejemplo `C:\siniestros_bot\`.

> **Nota sobre la instalacion actual (este PC):** hoy en dia el bot
> corre directamente desde esta misma carpeta dentro de OneDrive
> (`...\OneDrive - GLOBARTIA\- CLAUDE\GGlobal\siniestros_bot\siniestros_bot\`),
> no desde `C:\siniestros_bot\`. Funciona, pero es fragil porque la
> tarea programada de Windows guarda la ruta COMPLETA y ABSOLUTA al
> `.py`: si esta carpeta se mueve, se renombra, o OneDrive deja algun
> archivo como "solo en la nube" (no descargado del todo), la tarea
> empieza a fallar en silencio (sin enviar ningun aviso, por la misma
> regla de "nunca email de fallo" — solo se veria como que los correos
> dejan de procesarse). Si reorganizas esta carpeta, actualiza la tarea
> con `programar_bot.bat` despues, y comprueba con
> `schtasks /Query /TN "BotSiniestrosGG" /V /FO LIST` que la ruta que
> aparece en "Tarea que se ejecutara" sigue existiendo de verdad.

---

### PASO 2 - Editar config.py

Abre `config.py` con el Bloc de notas y rellena:

```python
GG_EMAIL    = "tu_email@garantiaglobal.com"
GG_PASSWORD = "tu_password"
ANTHROPIC_API_KEY = "sk-ant-..."   # desde console.anthropic.com
```

---

### PASO 3 - Instalar dependencias

Doble clic en `instalar_y_configurar.bat`
(Si pide administrador, acepta)

Esto instala pywin32, playwright, pdfplumber y anthropic, y crea una
tarea programada inicial (`BotSiniestrosGG`, apuntando en ese momento a
`bot_siniestros.py`, la version vieja). **Para que la tarea use la
version buena (`bot_seguimiento.py`) con la ruta completa de Python,
ejecuta despues `programar_bot.bat`**, que la borra y la vuelve a crear
apuntando al script correcto, cada hora.

---

### PASO 4 - Prueba con supervision

Abre CMD y ejecuta:
```
cd C:\siniestros_bot
python bot_seguimiento.py
```
El script te mostrara cada email y pedira confirmacion antes de actuar
(`S`=Proceder, `N`=Saltar, `A`=Forzar Apertura, `G`=Forzar Seguimiento,
`E`=Editar matricula).

---

### PASO 5 - Modo automatico cada hora

Cuando estes satisfecho con los resultados, en `config.py` cambia:
```python
EJECUTAR_SIN_SUPERVISION = True
```
La tarea programada `BotSiniestrosGG` (ejecutando
`python.exe <ruta_completa> bot_seguimiento.py --auto` cada hora, con
la ruta completa del `python.exe`, no solo `python`) se encarga de ahi
en adelante. Outlook de escritorio debe estar abierto y con la sesion
iniciada en el PC donde corre.

Para comprobar el estado real de la tarea en cualquier momento:
```
schtasks /Query /TN "BotSiniestrosGG" /V /FO LIST
```
(muestra la ultima ejecucion, el resultado y la proxima hora prevista).
Solo debe existir esta tarea — no crees ademas `BotSeguimientoGG` con
`programar_seguimiento.bat` (ver aviso en "ARCHIVOS DEL PROYECTO").

---

### LO QUE HACE EL SCRIPT (flujo completo de `bot_seguimiento.py`)

1. **Lee emails** del buzon compartido `siniestros@garantiaglobal.com`
   recibidos en las ultimas 2 horas (ventana con margen sobre el ciclo
   de 1h). Descarta sin gastar IA el ruido conocido (newsletters,
   bounces ajenos) y los correos que el propio bot ya etiqueto en una
   pasada anterior (categoria `GG Bot - ...`).
2. **Extrae texto** de los adjuntos (PDF, Word, Excel) y filtra los
   adjuntos puramente decorativos (logos, firmas, iconos de correo).
3. **Claude IA analiza** el email + adjuntos y extrae: tipo
   (apertura/seguimiento/otro), confianza, matricula, numero de averia
   si se menciona, interlocutor (nombre/apellidos/email/telefono),
   kilometros, fechas, descripcion, un resumen redactado, tipo de
   cliente, una etiqueta de urgencia (RECLAMACION, URGENTE,
   VEHICULO PARADO, etc.) y la clasificacion de cada adjunto.
4. **Entra en `intranet.garantiaglobal.com`** con las credenciales de
   `config.py`.
5. **Si es APERTURA** (confianza > 70% y con matricula): comprueba que
   no exista ya una averia abierta para esa matricula (si existe, la
   trata como seguimiento en vez de duplicar); busca el contrato en
   `/contratos` y exige que haya **una unica poliza en estado ACTIVA**
   vigente en la fecha del siniestro. Si no hay contrato, ninguna
   poliza activa, varias polizas activas a la vez, o la poliza activa
   no cubre esa fecha, **no crea nada**: etiqueta el correo para
   revision manual (ver seccion siguiente). Si todo esta en orden,
   crea la averia (provision fija 591€), rellena Gestion, escribe la
   observacion, sube los adjuntos y el correo original, y avisa por
   email al tecnico asignado.
6. **Si es SEGUIMIENTO** (confianza >= 62%): localiza la averia por su
   numero (metodo mas fiable) o, si no hay numero, por matricula
   (priorizando la que este abierta). Si esa averia ya tiene una
   observacion del bot de cualquier fecha, se salta para no duplicar.
   Si no, añade una observacion con el resumen de la IA y los datos
   clave (telefono, interlocutor, km, fecha), sube los adjuntos nuevos
   y notifica al tecnico.
7. **Si es "OTRO" con matricula o nº de averia** (confianza >= 62%): se
   procesa igual que un seguimiento, pero el aviso al tecnico lleva un
   asunto informativo distinto. Si es una **reclamacion o queja** sobre
   una averia YA tramitada (la IA la marca con la etiqueta
   `RECLAMACION`), nunca se reabre ni se reutiliza automaticamente:
   si la averia esta cerrada, se etiqueta para revision manual en vez
   de crear una averia nueva. Un "otro" sin matricula ni numero de
   averia se salta sin tocar nada.
8. **Cierre del correo:** solo si el caso quedo resuelto de verdad se
   marca como leido (queda en la propia bandeja; el movido automatico
   a la carpeta "Leidos siniestros 2026" esta desactivado desde
   2026-07-17 tras detectar perdidas de correos al mover en un buzon
   compartido). Si el caso no se pudo resolver, o quedo etiquetado
   para revision manual, el correo se deja **SIN LEER** — nunca se
   envia un email automatico avisando del fallo.

---

### CASOS QUE QUEDAN PARA REVISION MANUAL (nunca aviso automatico)

Cuando el bot no puede decidir algo por si solo, aplica una categoria
de Outlook al correo (visible en color en la bandeja) y lo deja **sin
leer**, en vez de reintentarlo cada hora para siempre o de avisar por
email de que algo fallo:

| Categoria Outlook                         | Significa |
|--------------------------------------------|-----------|
| `GG Bot - Baja confianza`                   | La IA no esta segura del tipo/matricula |
| `GG Bot - Sin matricula`                    | No se detecto matricula en el correo |
| `GG Bot - Sin contrato`                     | La matricula no tiene contrato en el sistema |
| `GG Bot - Poliza no activa`                 | Hay contrato(s) pero ninguno en estado Activo |
| `GG Bot - Multiples polizas activas`        | Mas de una poliza Activa a la vez para la matricula (ambiguo) |
| `GG Bot - Fuera de vigencia`                | La poliza activa no cubria la fecha del siniestro |
| `GG Bot - Averia cerrada`                   | Ya existe una averia para la matricula pero esta cerrada, y no parece un problema nuevo |
| `GG Bot - Tipo desconocido`                 | La IA no devolvio un tipo gestionable |

Un correo resuelto con exito se etiqueta `GG Bot - Gestionado` y se
marca como leido (esta categoria es la que evita que se vuelva a
analizar con la IA en pasadas siguientes).

---

### RELACION CON EL PROYECTO "NOMINADAS" (revision de bugs 17/08/2026)

`bot_seguimiento.py` comparte estilo y patrones de robustez con el
proyecto Nominadas (mismo tipo de fallos vistos en produccion), pero
**no comparte modulo de codigo**: son ficheros independientes. De los 4
bugs corregidos el 17/08/2026 en esa revision:

- **Reclamacion que abria una averia nueva en vez de reutilizar la
  existente** -> **SI aplica aqui y ya esta corregido**: es la funcion
  `_parece_reclamacion()` en `bot_seguimiento.py`, que usa la etiqueta
  `RECLAMACION` de la IA para no reabrir/duplicar una averia cuando el
  correo es en realidad una queja sobre un caso ya cerrado.
- **Ambiguedad al identificar el contrato/poliza correcta** -> **SI
  aplica aqui y ya esta corregido**: `crear_averia_desde_contrato()`
  exige una unica poliza en estado ACTIVA y vigente en la fecha del
  siniestro; si hay varias polizas activas a la vez devuelve
  `MULTIPLES_POLIZAS_ACTIVAS` y no crea nada sin que una persona lo
  revise.
- **Timeout al generar un certificado** -> **NO aplica a este bot**:
  `bot_seguimiento.py` no genera certificados; esa funcionalidad es
  propia de Nominadas.
- **"Mecatronica" interpretado como parte del bloque de valvulas** ->
  **NO aplica a este bot**: no clasifica piezas ni coberturas de ese
  tipo; los tipos de documento que maneja son los de
  `TIPOS_ARCHIVO_GG` (Permiso de circulacion, Ficha Tecnica, Foto
  Kilometros, Orden de Entrada, Presupuesto, Fact Mantenimiento,
  Peritacion, Fact Peritacion, Resolucion, Finiquito, Varios).

---

### DONDE MIRAR SI ALGO FALLA

- **La propia bandeja de entrada del buzon `siniestros@`**: los casos
  que necesitan revision humana se quedan ahi mismo, SIN LEER, con una
  categoria en color (ver tabla de arriba). Es el primer sitio donde
  mirar, no una carpeta aparte.
- **Carpeta `Errores\`** (subcarpetas `APERTURAS\` y `SEGUIMIENTOS\`):
  correos `.msg` guardados de casos reales donde el bot fallo — es el
  historial de incidencias para consultar, no se genera solo, hay que
  revisarlo a mano cuando se detecta un problema.
- **`ultimo_checkpoint.txt`**: nota de referencia (fecha/hora) del ultimo
  punto procesado; sirve para saber desde cuando hay que recuperar
  correos atrasados si el bot estuvo parado.
- **Recuperar correos atrasados:** `python recuperar_desde_fecha.py DD/MM/AAAA`
  reprocesa todo lo pendiente desde esa fecha sin duplicar lo ya hecho.
  Antes de lanzarlo, desactiva la tarea programada para que no se pisen:
  `schtasks /Change /TN "BotSiniestrosGG" /DISABLE` (y reactivarla despues con `/ENABLE`).
- **Reparar solo adjuntos que fallaron:** `python resubir_documentos.py MATRICULA` (o `TODO`).
- **Comprobar si la tarea esta corriendo de verdad:**
  `schtasks /Query /TN "BotSiniestrosGG" /V /FO LIST` — mira "Ultimo
  resultado" (0 = bien) y que la ruta del script en "Tarea que se
  ejecutara" exista de verdad en disco.

---

### SOLUCION DE PROBLEMAS

**"No se encontro el buzon siniestros@..."**
-> Asegurate de que el buzon compartido aparece en el panel izquierdo de tu Outlook

**"Login fallido"**
-> Revisa `GG_EMAIL`/`GG_PASSWORD` en config.py

**"Error en boton fuego"**
-> La primera vez ejecuta en modo supervision (sin --auto) para ver que ocurre

**Outlook debe estar abierto**
-> El script usa Outlook de escritorio. Si quieres que funcione sin Outlook abierto,
   habla con IT para configurar acceso Azure (Microsoft Graph API)

**Llevan horas sin procesarse correos y no hay ningun error visible**
-> Recuerda que el bot NUNCA avisa por email si algo falla: comprueba primero
   `schtasks /Query /TN "BotSiniestrosGG" /V /FO LIST` (¿existe la tarea? ¿se ejecuto
   hace poco? ¿la ruta del script sigue existiendo?), luego que Outlook este abierto y
   con sesion iniciada, y por ultimo la propia bandeja de `siniestros@` por si los
   correos se estan quedando sin leer con categoria `GG Bot - ...`.

**Una averia se abrio pero con datos incompletos o en la poliza equivocada**
-> Revisa la observacion que dejo el bot (empieza por "INFORMACION RECIBIDA POR
   CORREO") y compara con el correo original guardado como adjunto en la pestaña
   Archivos de la propia averia.

---

### PENDIENTES / LIMITACIONES CONOCIDAS

- Depende de que Outlook de escritorio este abierto (no usa Microsoft
  Graph API); pasar a Graph requeriria configurarlo con IT.
- El bot corre desde una carpeta sincronizada con OneDrive, no desde
  una ruta local fija: la tarea programada guarda la ruta absoluta, asi
  que mover/renombrar esta carpeta (o que OneDrive no tenga el archivo
  totalmente descargado) puede romper la tarea sin ningun aviso visible
  (ver "PASO 1" y "DONDE MIRAR SI ALGO FALLA").
- Credenciales y clave de API en texto plano en `config.py` (y una
  credencial personal suelta en `test_login2.py.py`, ver aviso de
  seguridad mas arriba).
- La lista de tecnicos y sus emails esta repetida (hardcodeada) en los
  tres `bot_*.py` — dar de alta o baja a un tecnico exige editar varios
  archivos, no hay un unico sitio centralizado.
- `programar_seguimiento.bat` crea una segunda tarea (`BotSeguimientoGG`)
  redundante con `BotSiniestrosGG` y referencia un script
  (`rematar_hoy.py`) que no existe en la carpeta; no usarlo mientras no
  se corrija, para evitar procesar cada correo dos veces.
- El modo automatico actua sin confirmacion humana; probar siempre antes
  en modo supervisado (Paso 4).
