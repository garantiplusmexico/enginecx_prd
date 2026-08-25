# Informe diario de averias por tecnico - Garantia Global

> **Si eres nuevo y no sabes nada de este bot, lee esto primero.**
> Este bot NO tiene interfaz ni conversacion: es un script que se
> conecta solo a la intranet, genera un Excel y lo envia por Outlook.
> No hay que "hablarle" a nada; si funciona, no da ninguna senal salvo
> el correo que llega y el log del dia en `logs\`.

Genera y envia por correo, de lunes a viernes a las 8:00 y otra vez a las
14:00, un Excel con una pestana por tecnico (Jacobo, Laila, Alin, Raquel,
Francisco, Alejandro, + "Sin asignar" si aplica) con sus averias vivas
ordenadas de mas antigua a mas reciente: la primera fila de cada pestana
es por donde el tecnico tiene que empezar.

El correo sale con el asunto en mayusculas "TUS AVERIAS DIARIAS 1 ENVIO"
(a las 8:00) o "TUS AVERIAS DIARIAS 2 ENVIO" (a las 14:00), desde la
cuenta de Outlook `neurona@garantiaglobal.com` (`CUENTA_ENVIO_OUTLOOK` en
`config.py`).

### DONDE ESTAN LAS CONTRASEÑAS

Todo esta en texto plano en `config.py` (no hay `.env` ni gestor de
secretos en este bot):
- `GG_EMAIL` (linea 9) y `GG_PASSWORD` (linea 10) -> login de la intranet
  `intranet.garantiaglobal.com` (usuario `neurona@garantiaglobal.com`).
  **Son las mismas credenciales que usan `siniestros_bot` y
  `W.app averias`** — si se cambia la contraseña de esta cuenta en la
  intranet, hay que actualizarla en los tres sitios.
- No hay contraseña de correo: el envio no usa SMTP, controla por COM el
  Outlook de escritorio que ya este abierto y logueado en el PC (variable
  `CUENTA_ENVIO_OUTLOOK`, linea 14, solo identifica que cuenta buscar
  entre las ya abiertas, no autentica nada).
- `config.py` tambien tiene, sin ser contraseñas, los emails de los
  tecnicos (`MAPA_TECNICOS`) y de los que reciben copia (`DESTINATARIOS_CC`)
  — tratalos como datos de contacto internos, no los publiques fuera.

### ARCHIVOS DEL PROYECTO
- `config.py`            -> Credenciales, destinatarios y textos del correo
- `descargar_informe.py` -> Login en la intranet + descarga del export "Por Excel (piezas)"
- `generar_informe.py`   -> Deduplicado, calculo de dias sin actualizar y construccion del .xlsx formateado
- `enviar_email.py`      -> Envio por Outlook de escritorio
- `main.py`              -> Orquesta los 3 pasos anteriores (esto es lo que lanza la tarea programada)
- `programar_tareas.bat` -> Crea las tareas programadas de Windows (8:00 y 14:00)

---

### PASO 1 - Copiar la carpeta al PC donde va a correr
Copia `averias_bot\` completa al PC de produccion (el que tiene el
Outlook de `neurona@garantiaglobal.com` abierto). No hace falta tocar
nada de `config.py` salvo que cambien las credenciales de Garantia
Global o la lista de tramitadores; las rutas de `data\` y `logs\` se
calculan solas a partir de donde este la carpeta, no hay que editarlas.

**Importante:** las tareas de prueba que se crearon en este PC durante
el desarrollo ya se han borrado, para que el envio real solo salga
desde el PC de produccion (si las dos maquinas tuvieran la tarea activa
a la vez, los tramitadores recibirian el correo duplicado).

---

### PASO 2 - Instalar dependencias
```
pip install -r requirements.txt
playwright install chromium
```
`pywin32` (Outlook) y `openpyxl`/`playwright` ya estaban instalados en
este PC porque los usan los otros bots de esta carpeta (siniestros_bot,
Flotas_bot, W.app averias).

---

### PASO 3 - Prueba manual (con supervision)
Abre una consola en `averias_bot\` y ejecuta el flujo completo:
```
python main.py
```
La primera vez, si quieres ver el Excel generado antes de que se envie
el correo, usa:
```
python main.py --sin-envio
```
Y si ya tienes un `data\averias.xlsx` descargado y solo quieres probar el
formato del informe sin esperar la descarga (~1-2 min):
```
python main.py --sin-descarga --sin-envio
```
El resultado se guarda en `data\informe_averias_<fecha>_<hora>.xlsx`.
Cada ejecucion deja tambien un log en `logs\averias_bot_<fecha>.log`.

Tambien existe `--envio 1` / `--envio 2`, que fuerza el numero de envio
que aparece en el asunto ("1 ENVIO" o "2 ENVIO") en vez de deducirlo de
la hora del sistema (antes de las 12:00 -> 1, despues -> 2). Es lo que
usa la tarea programada; en pruebas manuales solo hace falta si quieres
forzar el asunto sin esperar a esa hora.

---

### PASO 4 - Programar las tareas (8:00 y 14:00, lunes a viernes)
Antes de nada, edita `programar_tareas.bat` y comprueba la linea
`set "PYEXE=..."`: debe apuntar al `python.exe` de ESE PC (ejecuta
`where.exe python` alli y copia la ruta que salga).

Despues, doble clic en `programar_tareas.bat` (acepta si pide
administrador). Esto crea dos tareas de Windows, `InformeAveriasGG_0800`
e `InformeAveriasGG_1400`, que ejecutan `python main.py --envio 1` (o
`--envio 2`) de lunes a viernes a esas horas. Sabados y domingos no se
ejecutan.

**Requisito:** el PC debe estar encendido, con la sesion de Windows
iniciada y **Outlook de escritorio abierto con la cuenta
`neurona@garantiaglobal.com`** a esas horas (igual que siniestros_bot).
Si esa cuenta esta anadida como buzon compartido en el Outlook de otra
persona en vez de tener sesion propia, el script sigue funcionando igual
(busca la cuenta por `SmtpAddress` entre todas las del perfil). Si no la
encuentra, lo avisa en el log y envia con la cuenta por defecto del
perfil en vez de fallar. Si se quiere evitar depender de que Outlook
este abierto, habria que migrar el envio a Microsoft Graph API (hablar
con IT).

Las tareas se crean con la opcion `StartWhenAvailable`: si el PC estaba
apagado o suspendido justo a las 8:00/14:00, Windows lanza la tarea en
cuanto el equipo vuelve a estar disponible en vez de saltarsela (se
retrasa, no se pierde el envio). Aun asi, Outlook debe estar abierto y
con la cuenta iniciada en el momento en que la tarea finalmente se
ejecute.

Para lanzar una prueba inmediata de la tarea ya programada:
```
schtasks /Run /TN "InformeAveriasGG_0800"
```

---

### LO QUE HACE EL SCRIPT (flujo completo)
1. Entra en `intranet.garantiaglobal.com` con las credenciales de `config.py`
   y descarga el export "Por Excel (piezas)" de `/averias/gestion` (sin
   filtrar por estado, para poder ver tambien la ultima actualizacion de
   averias que ya esten cerradas).
2. Lee todas las columnas como texto. Las averias vienen repetidas por
   Id. (una fila por cada cambio) -> se queda solo con la fila de "Fecha
   de ultima actualizacion" mas reciente de cada Id. Esa columna esta en
   formato ISO (`YYYY-MM-DD HH:MM:SS`) y se parsea tal cual, sin tocar los
   guiones ni asumir el orden dia/mes de otras columnas.
3. Descarta las averias en estado "Cerrada" o "Pte. liquidacion"; el resto
   se consideran vivas.
4. Agrupa por Tecnico (Jacobo, Laila, Alin, Raquel, Francisco, Alejandro;
   las averias sin tecnico asignado van a la pestana "Sin asignar", que
   se coloca siempre la ultima) y genera, por cada uno, una unica tabla
   con las columnas Id., Estado, Matricula, Fecha de ultima
   actualizacion, Dias sin actualizar y Gestionada, ordenada de la
   averia **mas antigua** (arriba, por donde hay que empezar) a la
   **mas reciente** (abajo). Cada fila lleva un color de fondo segun el
   Estado (diccionario `COLOR_ESTADO` en `generar_informe.py`), la
   columna de fecha tiene una escala de color rojo (mas antigua) a
   verde (mas reciente), y la columna "Gestionada" trae un desplegable
   Si/No (se pone verde al marcar "Si") para que el tecnico vaya
   marcando lo ya tramitado. Cada pestana tiene autofiltro, la fila 1
   fija (freeze panes) y un color de pestana distinto por tecnico.
5. Compara el numero de averias vivas de cada tecnico con el corte
   anterior (guardado en `data\ultimo_corte.json`) e incluye esa
   comparativa en el log y en el cuerpo del correo.
6. Envia un unico correo con el Excel adjunto a todos los tramitadores
   (lista `MAPA_TECNICOS` en `config.py`).

---

### SOLUCION DE PROBLEMAS

**"Login fallido en Garantia Global"**
-> Revisa `GG_EMAIL` / `GG_PASSWORD` en `config.py`.

**El export tarda mucho / timeout**
-> Con el volumen actual (~35.000 filas) el servidor tarda 1-2 minutos en
   generar el Excel. El timeout esta puesto a 5 minutos; si aun asi falla,
   revisa la conexion a `intranet.garantiaglobal.com`.

**"No se pudo enviar el correo" / Outlook**
-> Asegurate de que Outlook de escritorio esta abierto y con la sesion de
   la cuenta indicada en `CUENTA_ENVIO_OUTLOOK` (config.py) iniciada en
   el PC que ejecuta la tarea programada. Si Outlook no responde (error
   RPC tipico de cuando se acaba de abrir o esta ocupado), el script ya
   reintenta solo una vez tras esperar 5 segundos antes de darse por
   vencido; si sigue fallando, revisa que Outlook no este colgado o con
   un dialogo abierto esperando un clic.

**Faltan columnas en el export**
-> Si Garantia Global cambia el nombre de alguna columna (Id., Estado,
   Matricula, Fecha de ultima actualizacion, Tecnico), `generar_informe.py`
   lanzara un error indicando cual falta.
