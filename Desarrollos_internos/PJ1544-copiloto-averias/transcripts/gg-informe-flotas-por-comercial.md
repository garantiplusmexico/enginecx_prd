# Informe diario de flotas por comercial - Garantia Global

> **Si eres nuevo y no sabes nada de este bot, lee esto primero.**
> Este bot NO tiene interfaz ni conversacion: es un script que lee los
> logs que ya genera `Flotas_bot` (carpeta hermana, dentro de `GGlobal\`),
> genera un Excel y lo envia por Outlook. No procesa correos ni toca GES
> ni la intranet - solo lee el CSV de auditoria de Flotas_bot. Si funciona,
> no da ninguna senal salvo el correo que llega a Miriam y el log del dia
> en `logs\`.

Genera y envia por correo, de lunes a viernes a las 7:00, un Excel con
cuantas flotas ha solicitado cada una de las 7 comerciales el dia
anterior (altas, altas partners, renovaciones, activaciones, altas
broker), a partir del registro de gestiones que ya escribe `Flotas_bot`
en `GGlobal\Flotas_bot\data\logs\neurona_YYYY-MM-DD.csv`.

El correo sale con el asunto "INFORME DIARIO DE FLOTAS POR COMERCIAL -
<fecha>", desde la cuenta de Outlook `neurona@garantiaglobal.com`
(`CUENTA_ENVIO_OUTLOOK` en `config.py`), a **miriam.ortiz@garantiaglobal.com**
(sin copia a nadie mas).

### DONDE ESTAN LOS DATOS Y QUIEN LOS PIDE

Este bot **no tiene credenciales propias**: no entra a GES ni a la
intranet ni al correo, solo lee un CSV que ya existe. Lo unico "sensible"
en `config.py` son los emails internos:
- `MAPA_COMERCIALES` (comercial -> nombre a mostrar).
- `DESTINATARIO` / `DESTINATARIOS_CC` (quien recibe el informe).

Trata esos emails como datos de contacto internos, no los publiques
fuera de Garantia Global.

### ARCHIVOS DEL PROYECTO
- `config.py`            -> Comerciales, tipos validos, rutas y textos del correo
- `generar_informe.py`   -> Lectura del log de Flotas_bot, deduplicado y construccion del .xlsx
- `enviar_email.py`      -> Envio por Outlook de escritorio
- `main.py`              -> Orquesta los 2 pasos anteriores (esto es lo que lanza la tarea programada)
- `programar_tareas.bat` -> Crea la tarea programada de Windows (7:00, L-V)

---

### CRITERIO DE CONTEO (importante para interpretar el informe)

1. Solo cuentan los tipos de gestion real: `ALTA FLOTA`, `ALTA FLOTA
   PARTNERS`, `RENOVACION`, `ACTIVACION FLOTA`, `ALTA FLOTA BROKER`. Se
   ignora `DESCONOCIDO` (correos que Flotas_bot no reconocio como una
   gestion de flotas).
2. Una misma matricula+tipo puede aparecer varias veces el mismo dia en
   el log (reintento tras ERROR, PENDIENTE_DOC, AVISO de recordatorio,
   OK final...). Este bot las agrupa como **una sola solicitud**: el
   comercial es el de la primera fila del grupo (por orden de hora), y
   el resultado que se muestra en la hoja "Detalle" es el de la ultima
   fila que no sea un `AVISO`.
3. Solo entran en el informe (tabla "Resumen" y hoja "Detalle") las
   solicitudes cuyo `email_comercial` sea una de las 7 comerciales de
   `MAPA_COMERCIALES`. El resto (tramitacion, Miriam, otro personal de
   GG, brokers externos como GES Partners...) se excluye del detalle,
   pero se cuenta y se avisa en una linea del cuerpo del correo
   ("Se han excluido N gestiones que no correspondian a ninguna
   comercial") para que el total se pueda cuadrar si hace falta.
4. Si una comercial no aparece con ninguna solicitud un dia, sale en la
   tabla con 0 - es un dato valido (no pidio nada ese dia), no un fallo
   del bot.

---

### PASO 1 - Instalar dependencias
```
pip install -r requirements.txt
```
`pywin32` y `openpyxl` ya estaban instalados en este PC porque los usan
los otros bots de `GGlobal\` (Flotas_bot, averias_bot, siniestros_bot).

---

### PASO 2 - Prueba manual (con supervision)
Genera el informe de un dia concreto sin enviarlo, para revisar el Excel:
```
python main.py --fecha 2026-08-18 --sin-envio
```
El resultado se guarda en `data\informe_comerciales_<fecha>.xlsx`. Cada
ejecucion deja tambien un log en `logs\informe_comerciales_<fecha>.log`.

Cuando el Excel se vea bien, prueba el envio real una vez (con Outlook de
escritorio abierto):
```
python main.py --fecha 2026-08-18
```

Sin argumentos, `main.py` procesa **el dia de ayer** - es lo que hace la
tarea programada cada mañana:
```
python main.py
```

---

### PASO 3 - Programar la tarea (7:00, lunes a viernes)
Antes de nada, edita `programar_tareas.bat` y comprueba la linea
`set "PYEXE=..."`: debe apuntar al `python.exe` de ESE PC (ejecuta
`where.exe python` alli y copia la ruta que salga).

Despues, doble clic en `programar_tareas.bat` (acepta si pide
administrador). Esto crea la tarea de Windows `InformeComercialesGG_0700`,
que ejecuta `python main.py` de lunes a viernes a las 7:00. Sabados y
domingos no se ejecuta (tampoco hace falta: el dia de ayer de un lunes
seria domingo, sin actividad comercial).

**Requisito:** el PC debe estar encendido, con la sesion de Windows
iniciada y **Outlook de escritorio abierto con la cuenta
`neurona@garantiaglobal.com`** a esa hora (igual que averias_bot y
siniestros_bot). Si esa cuenta esta anadida como buzon compartido en el
Outlook de otra persona, el script sigue funcionando igual (busca la
cuenta por `SmtpAddress` entre todas las del perfil); si no la
encuentra, avisa en el log y envia con la cuenta por defecto en vez de
fallar.

Para lanzar una prueba inmediata de la tarea ya programada:
```
schtasks /Run /TN "InformeComercialesGG_0700"
```

---

### LO QUE HACE EL SCRIPT (flujo completo)
1. Calcula la fecha a procesar (ayer, o la que se pase con `--fecha`) y
   busca `GGlobal\Flotas_bot\data\logs\neurona_<fecha>.csv`. Si no
   existe, asume que Flotas_bot no gestiono nada ese dia (no es un
   error).
2. Se queda con las filas de tipo real (ver "Criterio de conteo") y las
   agrupa por matricula+tipo en solicitudes unicas.
3. Descarta las solicitudes que no sean de una de las 7 comerciales.
4. Genera un `.xlsx` con dos hojas: "Resumen" (tabla comercial x tipo,
   con totales por fila y columna) y "Detalle" (una fila por solicitud:
   comercial, tipo, matricula, resultado, hora).
5. Envia un unico correo a Miriam con el Excel adjunto y un resumen en
   texto en el cuerpo (total por comercial + total del dia).

---

### SOLUCION DE PROBLEMAS

**"No existe ...neurona_<fecha>.csv"**
-> No es un error: significa que Flotas_bot no registro ninguna gestion
   ese dia (recuerda que Flotas_bot solo crea el CSV con la primera fila
   del dia). El informe sale con todo a 0.

**"No se pudo enviar el correo" / Outlook**
-> Igual que en averias_bot: asegurate de que Outlook de escritorio esta
   abierto y con la sesion de `CUENTA_ENVIO_OUTLOOK` iniciada en el PC
   que ejecuta la tarea. El script reintenta una vez tras 5 segundos si
   Outlook da un error RPC (tipico justo al abrirse).

**Una comercial nueva no aparece / hay que quitar a alguna**
-> Edita `MAPA_COMERCIALES` en `config.py` (email -> nombre). No hace
   falta tocar nada mas.
