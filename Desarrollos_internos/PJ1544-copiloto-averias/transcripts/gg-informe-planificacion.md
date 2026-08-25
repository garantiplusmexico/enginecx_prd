# Bot de planificacion de averias - Garantia Global

> **Si eres nuevo y no sabes nada de este bot, lee esto primero.**
> Este bot NO tiene interfaz ni conversacion: es un script que se
> conecta solo a la intranet, genera un Excel multi-hoja y lo envia por
> Outlook. No hay que "hablarle" a nada; si funciona, no da ninguna
> senal salvo el correo que llega y el log del dia en `logs\`.

Genera y envia por correo, de lunes a viernes (08:00 hasta el
13/09/2026, 09:00 a partir del 14/09/2026), el informe completo de
planificacion de averias (`PLANIFICACION_<fecha>_<hora>.xlsx`):
resumen ejecutivo, entradas diarias, rezagadas, indemnizaciones y
provisiones, coste medio por comercial/producto/cliente, segmentacion
de tiempos de cierre, analisis por tecnico, tiempos de cierre
avanzados (triangulo de desarrollo, WIP aging, cierres por antiguedad),
pendientes de liquidacion y cerradas que aun conservan provision.

El cuerpo del correo incluye ademas un resumen diario automatico
(`resumen_diario.py`): cerradas vs nuevas entradas de ayer y del dia
anterior con su tendencia, y el tecnico "foco" (el que mas averias
activas lleva sin actualizar por encima de 7/14/30 dias).

El correo sale con el asunto "PLANIFICACION DE AVERIAS - <fecha>",
desde la cuenta de Outlook `neurona@garantiaglobal.com`
(`CUENTA_ENVIO_OUTLOOK` en `config.py`).

### DONDE ESTAN LAS CONTRASEÑAS

Todo esta en texto plano en `config.py` (no hay `.env` ni gestor de
secretos en este bot, igual que en `averias_bot`):
- `GG_EMAIL` y `GG_PASSWORD` -> login de la intranet
  `intranet.garantiaglobal.com` (usuario `neurona@garantiaglobal.com`).
  **Son las mismas credenciales que usan `averias_bot`, `siniestros_bot`
  y `W.app averias`** — si se cambia la contraseña de esta cuenta en la
  intranet, hay que actualizarla en los cuatro sitios.
- No hay contraseña de correo: el envio no usa SMTP, controla por COM el
  Outlook de escritorio que ya este abierto y logueado en el PC
  (variable `CUENTA_ENVIO_OUTLOOK`, solo identifica que cuenta buscar
  entre las ya abiertas, no autentica nada).
- `config.py` tambien tiene, sin ser contraseñas, la lista `DESTINATARIOS`
  del informe — tratala como dato de contacto interno, no la publiques
  fuera.

### ARCHIVOS DEL PROYECTO
- `config.py`               -> Credenciales, destinatarios y textos del correo
- `descargar_informe.py`    -> Login en la intranet + descarga del export "Por Excel (provisiones)"
- `planificacion_completo.py` -> Genera el Excel multi-hoja a partir del export (acepta `SRC` y `OUT` por linea de comandos)
- `resumen_diario.py`       -> Calcula el parrafo de resumen (cerradas vs nuevas, tecnico foco) que se incluye en el cuerpo del correo; independiente de `planificacion_completo.py`, lee el mismo export crudo
- `enviar_email.py`         -> Envio por Outlook de escritorio
- `main.py`                 -> Orquesta los pasos anteriores (esto es lo que lanza la tarea programada)
- `programar_tarea.bat` / `programar_tarea.ps1` -> Crean la tarea programada de Windows (L-V, 08:00 hasta 13/09/2026 y 09:00 despues)

---

### PASO 1 - Copiar la carpeta al PC donde va a correr
Copia `Planificacion_bot\` completa al PC de produccion (el que tiene el
Outlook de `neurona@garantiaglobal.com` abierto — el mismo PC-servidor
que ya usan los otros bots). No hace falta tocar nada de `config.py`
salvo que cambien las credenciales de Garantia Global o la lista de
destinatarios; las rutas de `data\` y `logs\` se calculan solas a
partir de donde este la carpeta.

---

### PASO 2 - Instalar dependencias
```
pip install -r requirements.txt
playwright install chromium
```
`pywin32`, `openpyxl`, `pandas`, `numpy` y `playwright` ya estaban
instalados en el PC-servidor porque los usan los otros bots de esta
carpeta.

---

### PASO 3 - Prueba manual (con supervision)
Abre una consola en `Planificacion_bot\` y ejecuta el flujo completo:
```
python main.py
```
La primera vez, si quieres ver el Excel generado antes de que se envie
el correo, usa:
```
python main.py --sin-envio
```
Y si ya tienes un `data\averias.xlsx` descargado y solo quieres probar
la generacion del informe sin esperar la descarga (~1-2 min):
```
python main.py --sin-descarga --sin-envio
```
Para probar el envio real sin mandarlo a toda la lista de `DESTINATARIOS`,
usa `--destinatario` (repetible) para sobreescribirla solo en esa ejecucion:
```
python main.py --sin-descarga --destinatario tu.correo@garantiaglobal.com
```
El resultado se guarda en `data\PLANIFICACION_<fecha>_<hora>.xlsx`.
Cada ejecucion deja tambien un log en `logs\planificacion_bot_<fecha>.log`.

---

### PASO 4 - Programar la tarea (de lunes a viernes)
Antes de nada, edita `programar_tarea.bat` y comprueba la linea
`set "PYEXE=..."`: debe apuntar al `python.exe` de ESE PC (ejecuta
`where.exe python` alli y copia la ruta que salga).

Despues, doble clic en `programar_tarea.bat` (acepta si pide
administrador). Esto crea la tarea de Windows `PlanificacionAveriasGG_Diaria`,
que ejecuta `python main.py` **de lunes a viernes** (NO sabado ni domingo;
`programar_tarea.ps1` fija `$dias = Monday..Friday`), con dos disparadores:
- **08:00**, desde que se crea la tarea hasta el 13/09/2026 (inclusive).
- **09:00**, a partir del 14/09/2026 en adelante (sin fecha de fin).

Los dos disparadores viven dentro de la misma tarea (`programar_tarea.ps1`
crea un `EndBoundary` en el primero y un `StartBoundary` futuro en el
segundo), asi que el cambio de horario de septiembre ocurre solo,
sin tener que volver a tocar nada ese dia.

**Requisito:** el PC debe estar encendido, con la sesion de Windows
iniciada y **Outlook de escritorio abierto con la cuenta
`neurona@garantiaglobal.com`** a esa hora (igual que averias_bot). Si
esa cuenta esta anadida como buzon compartido en el Outlook de otra
persona en vez de tener sesion propia, el script sigue funcionando
igual (busca la cuenta por `SmtpAddress` entre todas las del perfil).
Si no la encuentra, lo avisa en el log y envia con la cuenta por
defecto del perfil en vez de fallar.

Para lanzar una prueba inmediata de la tarea ya programada:
```
schtasks /Run /TN "PlanificacionAveriasGG_Diaria"
```

---

### LO QUE HACE EL SCRIPT (flujo completo)
1. Entra en `intranet.garantiaglobal.com` con las credenciales de
   `config.py` y descarga el export **"Por Excel (provisiones)"** de
   `/averias/gestion` (distinto del "Por Excel (piezas)" que descarga
   `averias_bot`; trae las columnas de Comercial, Producto, Compraventa,
   Tecnico, Perito enviado, Indemnizacion, Provision, Presupuesto,
   Importe Mano de Obra/Pieza, etc. que necesita `planificacion_completo.py`).
2. Ejecuta `planificacion_completo.py` sobre ese export (como subproceso
   aparte, `SRC`/`OUT` por linea de comandos): parsea fechas e importes
   en formato espanol, deduplica por `Id.` (se queda con la fila de
   ultima actualizacion mas reciente de cada averia, sumando Mano de
   Obra + Pieza de todas sus filas) y construye el Excel multi-hoja
   completo.
3. Calcula el resumen diario (`resumen_diario.py`, sobre el mismo
   export crudo, con su propio deduplicado por `Id.`): cerradas
   (Cerrada + Pte. liquidacion) vs nuevas entradas de ayer y del dia
   anterior, tendencia, y el tecnico "foco" con mas averias activas
   rezagadas. Si falla, se avisa en el log y el correo se envia igual
   sin ese parrafo.
4. Envia un unico correo (con ese resumen en el cuerpo) y el Excel
   adjunto a la lista `DESTINATARIOS` de `config.py` (o a los
   `--destinatario` indicados a mano en una prueba).

---

### SOLUCION DE PROBLEMAS

**"Login fallido en Garantia Global"**
-> Revisa `GG_EMAIL` / `GG_PASSWORD` en `config.py`.

**"No se encontro la opcion 'Por Excel (provisiones)'..."**
-> Garantia Global ha cambiado el texto de esa opcion en el desplegable
   Salida de `/averias/gestion`; entra manualmente y mira como se llama
   ahora, luego ajusta el texto buscado en `descargar_informe.py`.

**El export tarda mucho / timeout**
-> El timeout esta puesto a 5 minutos; si aun asi falla, revisa la
   conexion a `intranet.garantiaglobal.com`.

**"No se pudo enviar el correo" / Outlook**
-> Asegurate de que Outlook de escritorio esta abierto y con la sesion
   de `neurona@garantiaglobal.com` iniciada en el PC que ejecuta la
   tarea programada.

**Error dentro de `planificacion_completo.py` (columna que falta, etc.)**
-> El script imprime avisos si descarta fechas con año corrupto; si
   falta una columna esperada (ver `FECHA_COLS`/`IMPORTE_COLS` al
   principio del propio script), es que el export de Garantia Global ha
   cambiado el nombre de esa columna.

**El correo llega sin el parrafo de resumen diario**
-> `main.py` captura cualquier fallo de `resumen_diario.py` (columna
   que falta, export vacio, etc.), imprime `[AVISO]` + el traceback en
   el log del dia y envia el correo igualmente sin ese parrafo. Revisa
   `logs\planificacion_bot_<fecha>.log` para ver el error concreto;
   `resumen_diario.py` usa nombres de columna fijos (`COL_ID`,
   `COL_ESTADO`, `COL_FECHA_AVERIA`, etc. al principio del propio
   fichero) que hay que ajustar si Garantia Global cambia el export.
