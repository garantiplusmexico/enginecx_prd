# Bot de averías - Garantia Global (WhatsApp + correo)

> **Si eres nuevo y no sabes nada de este bot, lee esto primero.**
> Es un asistente de **solo lectura** para comerciales: escriben una matrícula
> o un número de avería (por WhatsApp o por correo), el bot entra en la
> intranet, lee el estado y las observaciones, y responde con un resumen
> hecho con IA (Claude). Por correo además puede consultar **coberturas de
> póliza** (lee el PDF del contrato y transcribe el fragmento literal
> relevante, nunca concluye si algo está cubierto). **No crea ni edita nada**
> en la intranet ni en la póliza.
>
> Son **dos canales independientes que comparten el mismo núcleo de lectura**
> (`core_gg.py`): el canal de **WhatsApp** (`whatsapp_gg.py`, necesita el
> túnel de Cloudflare) y el canal de **correo** (`email_gg.py`, usa Outlook
> de escritorio, no necesita túnel). Pueden arrancarse y pararse por
> separado. **Estado a 18/08/2026: el canal de correo está funcionando, el
> canal de WhatsApp está parado a propósito** (ver más abajo el porqué).
>
> **Ruta del proyecto:** `...\CLAUDE\GGlobal\W.app averias\` (el 18/08/2026
> se movió aquí desde `...\CLAUDE\W.app averias\`, que era la ruta directamente
> bajo la carpeta raíz "CLAUDE"; si encuentras esa ruta antigua en algún
> script, atajo o documento suelto, está obsoleta).
>
> Para el histórico completo de la migración a producción, decisiones y
> lecciones aprendidas del canal de WhatsApp, ver `resumen_bot_averias.txt`
> en esta misma carpeta (diario de continuidad hasta el 21/07/2026; no
> recoge todavía el canal de correo ni el estado posterior). Este `LEEME.md`
> es la referencia rápida y actualizada de "qué es esto y cómo lo arranco".

---

### ARCHIVOS DEL PROYECTO

- `config.py`            -> Credenciales, listas blancas de autorizados y tokens de ambos canales (ver abajo)
- `core_gg.py`           -> Login en la intranet (Playwright) y consulta del estado de una avería + resumen con Claude (lo usan los dos canales)
- `certificado_gg.py`    -> Consulta de coberturas: busca el contrato/póliza de una matrícula, descarga el PDF, extrae el texto y pide a Claude el extracto literal relevante (solo canal de correo)
- `whatsapp_gg.py`       -> Servidor Flask del canal de WhatsApp: recibe los webhooks de Meta, filtra por `NUMEROS_AUTORIZADOS`, responde por WhatsApp
- `email_gg.py`          -> Bucle del canal de correo: lee el buzón compartido con Outlook, filtra por `EMAILS_AUTORIZADOS` y asunto, clasifica la pregunta con Claude (estado/cobertura/ambos) y responde en el mismo hilo
- `outlook_client_gg.py` -> Cliente de Outlook local vía COM (pywin32): listar correos, leer remitente/cuerpo, responder, mover a la carpeta "INFORMACION" (usado solo por `email_gg.py`)
- `buzon_lock.py`        -> Mutex de sistema para no chocar con otros bots (Flotas_bot, Nominadas) que tocan el mismo buzón compartido a la vez (ver más abajo)
- `consultar.py`         -> Script de prueba/consulta manual desde consola (sin pasar por WhatsApp ni correo)
- `iniciar_bot.ps1`      -> Arranca los tres procesos: servidor Flask, túnel de Cloudflare y bot de correo
- `cloudflared.exe`      -> Binario del túnel, descargado como standalone dentro de la propia carpeta (no vía winget)
- `requirements.txt`     -> Dependencias Python (playwright, anthropic, flask, requests, pywin32, pymupdf)
- `users GG.xlsx`        -> Excel de la plantilla completa de la empresa, usado para generar `NUMEROS_AUTORIZADOS` y `EMAILS_AUTORIZADOS` (datos personales — no lo compartas fuera)
- `resumen_bot_averias.txt` / `RESUMEN - Bot WhatsApp de consulta.txt` / `PROMPT_SERVIDOR.txt` -> diario histórico y prompt usado en la migración a este servidor (contexto, no hace falta para operar el bot día a día)

---

### ESTADO ACTUAL (18/08/2026) Y POR QUÉ

**Canal de correo (`email_gg.py`): FUNCIONANDO.** Corre como proceso en
bucle (sin túnel, sin dependencias externas de red entrante) mientras haya
sesión de Outlook iniciada en este PC.

**Canal de WhatsApp (`whatsapp_gg.py` + `cloudflared.exe`): PARADO A
PROPÓSITO.** El túnel de Cloudflare usado (`cloudflared tunnel --url ...`,
"quick tunnel" gratuito y anónimo) genera una **URL nueva cada vez que
arranca**. La URL que hay configurada ahora mismo como webhook en Meta for
Developers (App "Neurona") ya no coincide con ninguna URL de túnel viva, así
que Meta no puede entregar mensajes aunque el número siga activo. Para
reactivarlo hace falta:
1. Volver a arrancar el servidor Flask + el túnel (ver más abajo), **y**
2. Copiar la URL nueva que salga en `cf_stderr.log` + `/webhook` y pegarla
   en developers.facebook.com > App "Neurona" > Casos de uso > WhatsApp >
   Configuración > Webhook > URL de devolución de llamada > Verificar y
   guardar.

La alternativa de fondo (montar un túnel fijo de Cloudflare, con URL
estable, para no tener que repetir el paso 2 cada vez) está **bloqueada**
porque requiere una cuenta de Cloudflare (y posiblemente mover el DNS de
`garantiaglobal.com`), decisión que no se toma sin hablarlo antes. Hasta que
se resuelva eso, o se decida reactivar el quick tunnel actualizando Meta
cada vez, el canal de WhatsApp se deja parado deliberadamente para no
generar confusión (comerciales escribiendo y sin respuesta).

También sigue **pendiente y aplazada a propósito** una tarea programada de
Windows que arrancase `iniciar_bot.ps1` solo, tras un reinicio no
planeado del PC-servidor — no está implementada.

---

### CÓMO SE EJECUTA

**Importante — Python correcto:** todos los procesos de este bot deben
lanzarse con la ruta fija:
```
C:\Users\Hp\AppData\Local\Python\pythoncore-3.14-64\python.exe
```
**No usar** el `python` del PATH del sistema: otro proyecto en este mismo PC
(`Flotas_bot\.venv`) puede anteponerse en el PATH, y ese entorno no tiene
instaladas las dependencias de este bot (`anthropic`, `flask`, `playwright`,
`pymupdf`, `pywin32`). El síntoma es que el proceso arranca y muere al
instante con `ModuleNotFoundError`, sin dejar rastro visible salvo en el
`.log` correspondiente. `iniciar_bot.ps1` ya usa esta ruta fija.

**`iniciar_bot.ps1` arranca los TRES procesos (WhatsApp + correo) a la
vez.** Si el canal de WhatsApp sigue parado a propósito (ver arriba), NO
ejecutes este script tal cual sin querer reactivarlo — o coméntale las
líneas del servidor Flask/túnel, o simplemente mata esos dos procesos otra
vez después (dejando vivo solo el de correo).

Lo que hace el script, en orden:
1. Lanza `python -u whatsapp_gg.py` (servidor Flask en `0.0.0.0:5000`), en
   segundo plano, guardando el PID en `webhook_pid.txt` y la salida en
   `webhook_stdout.log` / `webhook_stderr.log`.
2. Lanza `cloudflared.exe tunnel --url http://localhost:5000` (túnel público
   gratuito de Cloudflare), guardando el PID en `cf_pid.txt` y la salida en
   `cf_stdout.log` / `cf_stderr.log`.
3. Lanza `python -u email_gg.py` (bucle del canal de correo, sin servidor ni
   túnel), guardando el PID en `email_pid.txt` y la salida en
   `email_stdout.log` / `email_stderr.log`.
4. Busca en `cf_stderr.log` la URL nueva (`https://xxxx.trycloudflare.com`)
   y la muestra por pantalla, recordando el paso manual de pegarla en Meta.

**Para arrancar SOLO el canal de correo** (el caso normal mientras WhatsApp
siga parado), desde la carpeta del proyecto:
```powershell
$python = "C:\Users\Hp\AppData\Local\Python\pythoncore-3.14-64\python.exe"
Start-Process -FilePath $python -ArgumentList "-u","email_gg.py" `
    -RedirectStandardOutput "email_stdout.log" -RedirectStandardError "email_stderr.log" `
    -PassThru -WindowStyle Hidden | ForEach-Object { $_.Id | Out-File -Encoding utf8 email_pid.txt }
```

**Para reactivar el canal de WhatsApp** (cuando se decida hacerlo): ejecutar
`iniciar_bot.ps1` completo (o solo sus dos primeros bloques) y, en cuanto
salga la URL nueva por pantalla / en `cf_stderr.log`, pegarla + `/webhook` en
Meta for Developers > App "Neurona" > Casos de uso > WhatsApp > Configuración
> Webhook > URL de devolución de llamada > Verificar y guardar. **La URL
cambia en cada arranque del túnel**, así que este paso hay que repetirlo
siempre que se reinicie `cloudflared`.

**Para parar cada pieza**, usando el PID guardado (o comprobando primero
cuál sigue vivo, con `Get-Content webhook_pid.txt` etc.):
```powershell
Stop-Process -Id (Get-Content webhook_pid.txt) -Force   # servidor Flask (WhatsApp)
Stop-Process -Id (Get-Content cf_pid.txt) -Force        # túnel Cloudflare
Stop-Process -Id (Get-Content email_pid.txt) -Force     # bot de correo
```
Un PID en el `.txt` que ya no corresponde a un proceso vivo simplemente
significa que ese proceso ya está parado (se sobrescribe solo en el próximo
arranque).

Hay restos de una fase anterior con `ngrok` (`ngrok_pid.txt`, `ngrok_stdout.log`,
`ngrok_stderr.log`, del 12/07/2026) — ya no se usa, el flujo actual del canal
de WhatsApp es solo con `cloudflared`.

---

### DÓNDE ESTÁN LAS CONTRASEÑAS Y TOKENS

Todo en texto plano en **`config.py`**, sin `.env` ni gestor de secretos:

| Variable | Para qué |
|---|---|
| `GG_EMAIL` / `GG_PASSWORD` | login en `intranet.garantiaglobal.com` (mismas credenciales que `averias_bot` y `siniestros_bot`) |
| `ANTHROPIC_API_KEY` | API de Claude, usada por los dos canales para generar el resumen/extracto |
| `WHATSAPP_TOKEN` | token permanente del System User "Neurona" en Meta, con control total sobre la app y ambas WABA — es el token más sensible de este bot (canal WhatsApp) |
| `WHATSAPP_PHONE_NUMBER_ID` | identifica el número de WhatsApp de empresa en la Graph API (canal WhatsApp) |
| `WHATSAPP_VERIFY_TOKEN` | cadena inventada por el equipo (no es secreta de Meta) para que Meta verifique la URL del webhook (canal WhatsApp) |
| `BUZON_EMAIL` | buzón compartido (`neurona@garantiaglobal.com`) que lee/responde el canal de correo vía Outlook — no es una contraseña, pero identifica la cuenta |

No copies ninguno de estos valores fuera de `config.py`. En el mismo
archivo están también, sin ser credenciales pero sí listas a mantener:
- **`NUMEROS_AUTORIZADOS`**: lista blanca de quién puede usar el canal de
  WhatsApp — cualquier número que no esté ahí es ignorado en silencio.
- **`EMAILS_AUTORIZADOS`**: lista blanca equivalente para el canal de
  correo (mismas ~55 personas, columna Email del Excel).
- **`ASUNTO_CLAVE_EMAIL`**: palabra que debe contener el asunto de un correo
  para que el bot lo procese (evita que intente interpretar cualquier correo
  interno que llegue al buzón compartido).

Ambas listas se generaron a partir de `users GG.xlsx`; para dar de alta o
baja a alguien hay que editar directamente la lista correspondiente en
`config.py` y relanzar el proceso afectado (Flask para WhatsApp, `email_gg.py`
para correo) — no hay panel de administración.

**Avisos de seguridad pendientes (no resueltos, ver también el bloque PENDIENTE
de `resumen_bot_averias.txt`):**
- El webhook de WhatsApp **no verifica la firma** `X-Hub-Signature-256` de
  Meta: cualquiera que descubra la URL pública del túnel podría enviar un
  JSON falso haciéndose pasar por un número autorizado. Está identificado
  como pendiente importante (y mientras el canal esté parado, no es
  explotable).
- `webhook_stderr.log` ha quedado con el valor de `WHATSAPP_VERIFY_TOKEN` en
  texto plano (se filtra en la URL de la petición de verificación de Meta) —
  no da acceso a la cuenta de Meta, pero es otro motivo para no compartir esos
  logs fuera del equipo.
- El canal de correo, al ser solo lectura y sin exponer ningún puerto a
  Internet, no tiene una superficie de ataque equivalente; su control de
  acceso es `EMAILS_AUTORIZADOS` + que el remitente SMTP coincida.

---

### INTEGRACIONES EXTERNAS

- **Meta WhatsApp Business Platform (Cloud API):** app "Neurona" dentro del
  portfolio empresarial "Garantia Global Insurtech". Los mensajes salientes se
  mandan por POST a `graph.facebook.com/v20.0/<PHONE_NUMBER_ID>/messages`; los
  entrantes llegan por POST de Meta a `/webhook`. Canal parado actualmente
  (ver "Estado actual").
- **Cloudflare Tunnel** (`cloudflared.exe`, standalone dentro de la carpeta):
  crea un túnel gratuito y anónimo para el canal de WhatsApp; genera una URL
  nueva en cada arranque (no hay cuenta de Cloudflare asociada — ver
  pendientes más abajo).
- **Outlook de escritorio (COM, vía `pywin32`):** usado solo por el canal de
  correo (`outlook_client_gg.py`). Requiere Outlook instalado y con sesión
  iniciada en este PC, con el buzón compartido (`BUZON_EMAIL`) ya añadido al
  perfil. El mismo buzón lo comparten otros bots de la empresa (Flotas_bot,
  Nominadas) sin coordinación propia entre ellos — de ahí `buzon_lock.py`
  (Mutex de sistema `Buzon_Neurona_Lock`): antes de leer/mover/borrar algo
  de la Bandeja, este bot comprueba que ningún otro bot lo está haciendo en
  ese instante; si el buzón está ocupado, omite ese ciclo y lo reintenta 2
  minutos después (nunca se pierde el correo, solo se retrasa). Hay una copia
  idéntica de `buzon_lock.py` en `Flotas_bot/src/` y `Nominadas/` — si se
  corrige algo aquí, replicar en los otros dos.
- **Intranet Garantia Global:** login de solo lectura con Playwright (Chromium
  headless), igual que el resto de bots de esta carpeta.
- **API de Claude (Anthropic):** genera el resumen de estado (`core_gg.py`),
  clasifica la pregunta libre del correo (`email_gg.py`) y extrae el
  fragmento de cobertura relevante (`certificado_gg.py`).

---

### DÓNDE MIRAR SI ALGO FALLA

**Canal de WhatsApp:**
- `webhook_stdout.log` / `webhook_stderr.log` -> salida del servidor Flask:
  arranque, puertos donde escucha, avisos de números no autorizados, y cada
  petición HTTP recibida en `/webhook` con su código de estado.
- `cf_stdout.log` / `cf_stderr.log` -> salida del túnel: aquí aparece la URL
  pública nueva en cada arranque, y también los errores de red/caídas del
  túnel (hubo una caída real el 24/07/2026 por fallo de red del PC, ver
  `resumen_bot_averias.txt`).
- `webhook_pid.txt` / `cf_pid.txt` -> PID de cada proceso, para poder matarlo.
- Si Meta no entrega mensajes o los comerciales no reciben respuesta: lo
  primero es comprobar que el túnel sigue vivo y que la URL configurada en
  Meta coincide con la actual — aunque el motivo más probable ahora mismo es
  simplemente que este canal está parado a propósito (ver "Estado actual").

**Canal de correo:**
- `email_stdout.log` / `email_stderr.log` -> salida del bucle: mensaje de
  arranque, avisos de remitente no autorizado, y cualquier excepción del
  ciclo (se capturan todas: un fallo en un ciclo no mata el proceso, solo
  se reintenta 2 minutos después).
- `email_pid.txt` -> PID del proceso, para poder matarlo.
- Si un correo no se contesta: comprobar que el asunto contiene la palabra
  de `ASUNTO_CLAVE_EMAIL`, que el remitente está en `EMAILS_AUTORIZADOS`, y
  en los logs si salió el aviso de "buzón ocupado por otro bot" (se omite
  ese ciclo y se reintenta solo, no hace falta intervenir).
- Si un correo se contesta dos veces o falla al moverlo con "se copiaron en
  lugar de moverse": ya está contemplado en `outlook_client_gg.py::mover_a_carpeta`
  (si Outlook no puede mover el original por permisos del buzón compartido,
  se copia y luego se borra el original); si volviera a pasar de otra forma,
  revisar `resumen_bot_averias.txt` / memoria del proyecto sobre el
  incidente real del 17-18/08/2026 que motivó `buzon_lock.py`.
- Correos ya respondidos se archivan en la subcarpeta **"INFORMACION"**
  dentro de la Bandeja de entrada del buzón (creada automáticamente si no
  existe) — es la forma de no volver a procesarlos, no un archivo de logs.

**Ambos canales:**
- Archivos con sufijo `-GLOBAL-NN` (`webhook_stderr-GLOBAL-24.log`, etc.) son
  logs rotados/archivados de ejecuciones anteriores.
- El Programador de tareas de Windows de este PC tiene tareas de otros bots
  (Flotas_bot, Nominadas, Siniestros...); este bot **no tiene ninguna tarea
  programada activa propia** (ver "Estado actual"). Si aparece alguna con
  nombre parecido a `GG_PararBotCorreoAverias_...`, es un resto de una
  tarea puntual de un solo uso ya ejecutada (parar `email_gg.py` a una hora
  concreta durante el incidente del buzón compartido) sin próxima ejecución
  programada; no afecta al funcionamiento actual y se puede borrar si se
  quiere limpiar el Programador de tareas.

---

### PENDIENTES CONOCIDOS (detalle completo en `resumen_bot_averias.txt`)

1. **Canal de WhatsApp parado** — hay que decidir si se reactiva
   actualizando la URL en Meta cada vez que se relance el quick tunnel, o si
   se resuelve antes el túnel fijo (punto 3).
2. **Seguridad del webhook de WhatsApp** — falta verificación de firma
   `X-Hub-Signature-256`.
3. **Sin arranque automático** — hay que relanzar todo a mano tras cada
   reinicio del PC o pérdida de sesión; se valoró una tarea programada de
   Windows al inicio de sesión (solo si el reinicio no fue planeado), aún
   no creada — aplazada a propósito, ver también memoria del proyecto.
4. **Túnel de Cloudflare no permanente** — URL nueva en cada arranque;
   migrar a un túnel fijo o a hosting propio con dominio evitaría tener que
   reconfigurar el webhook en Meta cada vez, y evitaría cortes como el del
   24/07/2026. Bloqueado porque montar un túnel fijo requiere cuenta de
   Cloudflare (y posiblemente mover el DNS de garantiaglobal.com), decisión
   que no se puede tomar sin hablarlo antes.
5. Añadir/quitar comerciales de `NUMEROS_AUTORIZADOS` / `EMAILS_AUTORIZADOS`
   sigue siendo manual (editar `config.py` y relanzar el proceso afectado).
