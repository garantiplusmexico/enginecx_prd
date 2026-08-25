# Bot Nominadas - Garantia Global

> **Si eres nuevo y no sabes nada de este bot, lee esto primero.**
> Este bot NO tiene interfaz: es un proceso que corre solo, cada hora (y
> cada 10 minutos en un ciclo mas ligero), conectandose a la intranet de
> Garantia Global, a una IA (Claude) y al Outlook de escritorio de la
> cuenta `neurona@garantiaglobal.com`. No hay que "hablarle" a nada. La
> unica persona con la que interactua de verdad es **Manuel Moreno**
> (Director del Departamento de Prestaciones), por correo: el bot le
> **propone** rehusar una averia y espera su **"Ok"** antes de tocar nada
> del expediente o del cliente. Si algo falla, la señal esta en el log
> del dia (`logs\nominadas_<fecha>.log`) y en el correo que Manuel recibe
> al final de cada ciclo completo.
>
> **Este bot decide FLUJO, nunca decide dinero ni cobertura.** La IA
> identifica que pieza pide el taller y si esa pieza figura o no en la
> poliza; la decision de rehusar de verdad, los importes y el cierre solo
> se ejecutan tras el "Ok" explicito de un humano (Manuel). Guardalo en
> mente antes de tocar cualquier umbral de confianza en `config.py`.

## Que hace y cuando

Garantia Global vende, entre otras, polizas de garantia mecanica con
cobertura **"nominada"**: solo estan aseguradas las piezas que figuran
expresamente listadas en el art. 1.2 "Bienes Asegurados" del certificado
de esa poliza concreta (a diferencia de una cobertura "todo riesgo"). El
listado de que **productos** tienen este esquema esta en
`Polizas Nominadas 2026.txt`; solo las averias de esos productos son
candidatas a este bot, el resto ni se abre.

Cada hora, el bot revisa las averias en estado **"Pte. revision"** en la
intranet, identifica cuales son de un producto nominado, usa la IA para
leer la declaracion del taller/cliente (mas fotos, presupuestos, ordenes
de trabajo) y el propio certificado de la poliza, y determina si la pieza
que se pide reparar **SI** figura en el listado de bienes asegurados o
**NO**. Si no figura, y la IA tiene confianza suficiente, el bot:

1. Genera una resolucion en PDF ("NO CUBIERTO") a partir de un molde Word
   segun la compañia (Helvetia / GES / generico), fusionada con el
   presupuesto del taller.
2. Envia esa resolucion a **Manuel Moreno**, junto con el razonamiento de
   la IA y el texto exacto que se mandaria al cliente, pidiendole su
   **"Ok"** por correo.
3. Solo cuando Manuel responde -bien con un "Ok" seco, bien con
   instrucciones mas detalladas que una segunda IA interpreta con un
   umbral de confianza muy alto- el bot cierra el expediente en la
   intranet (incluye un paso obligatorio de "Interfaz Ges" con la
   aseguradora), sube la resolucion al expediente y envia el correo final
   de "no cubierto" al cliente.

En ningun punto de este flujo decide una IA un importe o si algo esta
cubierto por si sola sin pasar antes por Manuel: solo **informa** un dato
objetivo (esta o no esta la pieza en la lista) con su nivel de confianza;
si la confianza no es suficiente, o hay cualquier ambiguedad (p.ej. la
matricula tiene mas de una poliza activa a la vez), la averia se marca
para **revision manual humana** y nunca se propone nada.

Hay dos tareas programadas, **los 7 dias de la semana, 24h** (no solo en
horario laboral, a diferencia de otros bots de esta carpeta, porque hay
que poder recoger la respuesta de Manuel en cualquier momento):

- `BotNominadasGG` (cada 1h): el ciclo completo de arriba.
- `BotNominadasGG_Seguimiento` (cada 10 min): solo comprueba si Manuel ya
  dio su "Ok" a algo pendiente; no descarga ni analiza averias nuevas. Se
  activa/desactiva sola (via `schtasks`) segun si queda o no algo
  pendiente del "Ok" de Manuel - no hace falta tocarla a mano.

Ademas, de **viernes 15:00 a lunes 8:00**, Manuel no recibe nada del bot
(ni propuestas ni el informe de ciclo, ni se comprueba su buzon), aunque
el bot sigue generando propuestas por detras y las envia en cuanto
termina la ventana. Esto es temporal mientras Manuel no tenga un horario
fijo: la fecha `VENTANA_SILENCIO_MANUEL_VIGENTE_HASTA` en `config.py`
(linea 92) hace que deje de aplicarse sola a partir de esa fecha, sin
tocar codigo (ver `horario_manuel.py`).

### DONDE ESTAN LAS CONTRASEÑAS Y CLAVES

Todo esta en texto plano en `config.py` (no hay `.env` ni gestor de
secretos en este bot, igual que en `averias_bot`):

- `GG_EMAIL` (linea 15) y `GG_PASSWORD` (linea 16) -> login de la
  intranet `intranet.garantiaglobal.com`. **Son las mismas credenciales
  que usan `averias_bot` y `siniestros_bot`** (usuario
  `neurona@garantiaglobal.com`) - si se cambia la contraseña en la
  intranet, hay que actualizarla en los tres sitios.
- `ANTHROPIC_API_KEY` (linea 23) -> clave real de la API de Claude,
  usada por `extraer_pieza_ia.py` e `interpretar_manuel.py`. **Es una
  clave que consume saldo/credito de la organizacion**, tratala con el
  mismo cuidado que una contraseña: no la publiques ni la subas a ningun
  repositorio publico.
- No hay contraseña de correo: el envio (a Manuel y al cliente) no usa
  SMTP, controla por COM el Outlook de escritorio ya abierto y logueado
  en el PC (`CUENTA_ENVIO_OUTLOOK`, linea 20, solo identifica que cuenta
  buscar entre las ya abiertas, no autentica nada).
- `EMAIL_MANUEL` (linea 31) no es una contraseña, pero es el dato de
  contacto de una persona: tratalo como informacion interna, no lo
  publiques fuera de la organizacion.

### DOCUMENTOS DE NEGOCIO DE LA CARPETA (no son codigo, pero el bot los lee o de ellos sale la logica)

- `Polizas Nominadas 2026.txt` -> lista de nombres de producto con
  cobertura nominada (leida por `productos_nominados.py`). Si Garantia
  Global lanza un producto nominado nuevo, o cambia el nombre de uno
  existente, hay que añadirlo/corregirlo aqui o el bot lo tratara como
  cobertura normal y ni lo abrira.
- `Cuerpo email.txt` -> texto legal/comercial ya redactado y aprobado
  (incluye el aviso de contenido con asistencia de IA revisado por un
  humano) que se envia al cliente cuando se rehusa. El bot **nunca
  reescribe este texto con IA**, solo inserta el nombre del cliente y el
  numero de expediente (`correo_cliente.py`). Si hay que cambiar el
  texto legal, se edita este fichero a mano.
- `Molde resolucion NO CUBIERTO - GG HELVETIA.docx` / `- GG GES.docx` /
  `- GG.docx` -> plantillas Word con placeholders tipo `[MATRÍCULA]`,
  `[VIN]`, `[AAAA]`... que `generar_resolucion.py` rellena segun la
  compañia aseguradora leida del propio certificado (Helvetia / GES /
  generico si no se identifica ninguna de las dos). Si un dato no consta
  en la documentacion del expediente, el placeholder se rellena con
  "No consta en la documentacion" (la IA tiene prohibido inventarlo).
- `Instrucciones NOMINADAS.docx` -> documento del propio Manuel/Garantia
  Global que describe, paso a paso y con capturas, la secuencia manual
  real para cerrar un expediente de este tipo en la intranet (los campos
  de Gestion, el bloque "Interfaz Ges" con la aseguradora GES, el orden
  Apertura -> Reestimar -> Rehuse -> Cerrar). Es la base de la que sale
  la logica de cierre de `ficha_averia.py`; si Garantia Global cambia
  este procedimiento, hay que releer este documento y actualizar el
  codigo, no al reves.

### ARCHIVOS DEL PROYECTO

- `config.py`                -> Credenciales, umbrales de confianza, rutas, plantillas y la ventana de silencio de Manuel
- `main.py`                  -> Orquestador; esto es lo que lanzan las dos tareas programadas
- `descargar_candidatas.py`  -> Reutiliza el login/descarga de `averias_bot` y filtra las averias en "Pte. revision"
- `productos_nominados.py`   -> Compara el Producto de una poliza contra `Polizas Nominadas 2026.txt`
- `ficha_averia.py`          -> Toda la interaccion con la ficha de la averia y con `/contratos` en la intranet (Playwright): login, leer Gestion/Observaciones/Archivos, localizar el certificado, cerrar el expediente (incluida la secuencia de "Interfaz Ges")
- `diag_nominadas.py`        -> Script de SOLO LECTURA para volcar los selectores reales de una averia concreta y confirmarlos antes de fiarse de `ficha_averia.py`
- `extraer_pieza_ia.py`      -> Llamada a la IA que identifica la pieza solicitada y comprueba si figura en el art. 1.2 del certificado
- `generar_resolucion.py`    -> Rellena el molde Word, lo convierte a PDF (via Word/COM) y lo fusiona con el presupuesto del taller
- `correo_cliente.py`        -> Construye el cuerpo del correo final al cliente a partir de `Cuerpo email.txt`
- `email_manuel.py`          -> Envia la propuesta de rehuse a Manuel (con el razonamiento de la IA y el texto que recibiria el cliente)
- `email_cliente.py`         -> Envia la resolucion final al cliente y guarda copia `.msg` como prueba del envio
- `outlook_utils.py`         -> Envio de correo por Outlook de escritorio (COM), comun a los tres emails de arriba
- `seguimiento_manuel.py`    -> Busca en la bandeja de Neurona la respuesta de Manuel a una propuesta concreta, y archiva el hilo ya cerrado
- `interpretar_manuel.py`    -> IA que traduce una respuesta de Manuel que NO es un "Ok" simple en un plan de accion (cerrar o no, con/sin Interfaz Ges, avisar o no al cliente) - nunca decide importes ni cobertura
- `horario_manuel.py`        -> Calcula si estamos dentro de la ventana de silencio de Manuel
- `estado.py`                -> `data\estado_nominadas.json`: una entrada por averia con su fase, para no reprocesar ni reenviar nada dos veces
- `informe_ciclo.py`         -> Resumen que se envia a Manuel al final de cada ciclo completo (propuestas, descartes, cierres, backlog de revision manual)
- `buzon_lock.py`            -> Mutex para no chocar con otros bots (Flotas_bot, bot de averias/coberturas) que tocan la misma bandeja compartida de Neurona
- `programar_tareas.bat` / `.ps1` -> Crea las dos tareas programadas de Windows

---

### PASO 1 - Copiar la carpeta al PC donde va a correr

Copia `Nominadas\` completa al PC de produccion (el que tiene abierto y
logueado el Outlook de `neurona@garantiaglobal.com`, y con **Microsoft
Word instalado con licencia activa**, porque `generar_resolucion.py`
convierte el docx a PDF usando Word por COM, no una libreria aparte). No
hace falta tocar `config.py` salvo que cambien las credenciales o la
lista de productos nominados.

**En el PC actual (el que se uso para desarrollar este bot) las dos
tareas ya estan registradas y activas** (`schtasks /Query /TN
"BotNominadasGG"`); si vas a montarlo en OTRO PC, sigue los pasos 2 a 4
completos.

---

### PASO 2 - Instalar dependencias

```
pip install -r requirements.txt
playwright install chromium
```

Ademas de lo que instala `requirements.txt` (playwright, openpyxl,
pywin32, python-docx, pdfplumber, pypdf, Pillow, anthropic, extract-msg),
hace falta:

- **Microsoft Word** instalado en ese PC (conversion docx -> PDF).
- **Outlook de escritorio** instalado, abierto y logueado con la cuenta
  de Neurona (envio de correos y lectura de la respuesta de Manuel).

`pywin32` y `openpyxl` ya suelen estar instalados en los PCs de esta
carpeta porque los usan `averias_bot`/`siniestros_bot`/`Flotas_bot`.

---

### PASO 3 - Prueba manual (con supervision)

**Antes de dejar correr el bot en modo real**, hay selectores de
`ficha_averia.py` marcados en el propio codigo como candidatos a revisar
contra la intranet real (descarga de adjuntos, localizar el certificado
en `/contratos`, el bloque "Interfaz Ges" del cierre). Si un selector no
encuentra lo esperado, el codigo esta pensado para **fallar de forma
segura**: lanza `SelectorNoVerificado` y la averia se marca para revision
manual, nunca se adivina ni se fuerza un dato. Aun asi, conviene
confirmar contra 2-3 averias reales con:

```
python diag_nominadas.py <id_averia> [matricula]
```

Este script es de **solo lectura** (no escribe nada en la intranet) y
vuelca por consola los campos/selectores que encuentra, para poder
comparar con lo que espera `ficha_averia.py`.

Despues, abre una consola en `Nominadas\` y prueba el flujo completo sin
tocar nada real:

```
python main.py --dry-run
```

Analiza y loguea que haria (que averias propondria, cuales descartaria,
cuales cerraria si Manuel ya dio el Ok) **sin enviar ningun correo, sin
escribir en la intranet y sin tocar `estado_nominadas.json`**.

Para iterar mas rapido reutilizando el ultimo export ya descargado (te
ahorras el login + descarga contra la intranet):

```
python main.py --sin-descarga --dry-run
```

Para probar solo el ciclo ligero de seguimiento (comprobar el "Ok" de
Manuel sin analizar averias nuevas):

```
python main.py --solo-pendientes --dry-run
```

Cada ejecucion deja un log en `logs\nominadas_<fecha>.log` (se crea sola,
no hace falta la carpeta de antemano).

---

### PASO 4 - Programar las tareas (cada 1h y cada 10 min, todos los dias)

Antes de nada, edita `programar_tareas.bat` y comprueba la linea
`set "PYEXE=..."`: debe apuntar al `python.exe` de ESE PC (ejecuta
`py -0p` alli y copia la ruta que salga).

Despues, doble clic en `programar_tareas.bat` (acepta si pide
administrador). Esto crea dos tareas de Windows:

- `BotNominadasGG` -> `python main.py`, cada 1 hora, todos los dias (24h).
- `BotNominadasGG_Seguimiento` -> `python main.py --solo-pendientes`,
  cada 10 minutos, todos los dias. **Arranca desactivada a proposito**:
  el propio `main.py` la activa/desactiva sola segun si queda algo
  pendiente del "Ok" de Manuel (no hay que tocarla a mano en condiciones
  normales).

**Requisito:** el PC debe estar encendido, con la sesion de Windows
iniciada y **Outlook de escritorio abierto con la cuenta
`neurona@garantiaglobal.com`** de forma permanente (no solo en horario
laboral, a diferencia de `averias_bot`), porque hay que poder recoger la
respuesta de Manuel a cualquier hora.

Para lanzar una prueba inmediata de una tarea ya programada:

```
schtasks /Run /TN "BotNominadasGG"
schtasks /Run /TN "BotNominadasGG_Seguimiento"
```

Para ver el estado o borrarlas:

```
schtasks /Query /TN "BotNominadasGG" /V /FO LIST
powershell -Command "Unregister-ScheduledTask -TaskName 'BotNominadasGG' -Confirm:$false"
powershell -Command "Unregister-ScheduledTask -TaskName 'BotNominadasGG_Seguimiento' -Confirm:$false"
```

---

### LO QUE HACE EL BOT (flujo completo)

**Ciclo completo (`main.py`, cada 1h):**

1. Descarga el export de averias de Garantia Global reutilizando el
   login/descarga de `averias_bot` (sin duplicar codigo) y se queda con
   las que estan en estado "Pte. revision".
2. Para cada averia que todavia no tiene entrada en
   `estado_nominadas.json` (nunca se reanaliza una ya tratada): abre su
   ficha y busca su producto/poliza en `/contratos` por matricula (el
   Producto no existe ni en el export ni en la pestaña Gestion). Si la
   matricula tiene mas de una poliza ACTIVA a la vez, o no se encuentra
   el contrato, la averia va a **revision manual** (nunca se adivina cual
   poliza es la correcta).
3. Si el producto no esta en `Polizas Nominadas 2026.txt`, la averia se
   marca **descartada** (cobertura normal, fuera de alcance de este bot)
   y no se toca mas.
4. Si es nominado, se descarga el certificado de esa poliza, se lee la
   pestaña Observaciones (declaracion) y se descargan los adjuntos ya
   subidos (presupuestos, fotos, ordenes de trabajo). Todo eso, mas el
   certificado casi completo, se manda a la IA (`extraer_pieza_ia.py`),
   que identifica la pieza solicitada y comprueba si figura en el art.
   1.2 del certificado. La IA **solo informa el dato y su confianza**, no
   decide rehusar: si la confianza no llega al 75% (`CONFIANZA_MINIMA` en
   `config.py`) o hay cualquier duda, la averia va a **revision manual**.
5. Si la pieza SI figura en el listado, la averia se marca
   **descartada** (cobertura normal). Si NO figura y la confianza es
   suficiente, es **candidata a rehuse**: se genera el PDF de resolucion
   (molde Word de la compañia + presupuesto del taller fusionado) y se
   envia a Manuel pidiendo su "Ok" (o se retiene si estamos en la ventana
   de silencio, y se envia en cuanto termina). La averia pasa a fase
   **pendiente_manuel**.
6. Al final del ciclo se envia a Manuel un resumen (`informe_ciclo.py`)
   con lo propuesto, lo descartado, lo cerrado en este ciclo, y el
   **backlog completo** de todo lo que sigue en revision manual (no solo
   lo nuevo de hoy).

**Ciclo de seguimiento (`main.py --solo-pendientes`, cada 10 min, solo si
hay algo pendiente):**

7. Busca en la bandeja compartida de Neurona (con lock para no chocar con
   otros bots) una respuesta de Manuel a cada averia pendiente, por
   remitente + numero de averia en el asunto.
8. Si la primera linea del cuerpo es exactamente "Ok" -> aprobacion
   directa, sin pasar por IA. Si es una respuesta mas larga/detallada,
   una segunda IA (`interpretar_manuel.py`) decide el **flujo** (cerrar o
   no, con o sin "Interfaz Ges", avisar o no al cliente) - **nunca**
   importes ni criterio de cobertura, eso ya viene fijado desde el paso 4.
   Si la confianza no llega al 85% (`CONFIANZA_MINIMA_INSTRUCCION_MANUEL`)
   o la accion no se reconoce, no se actua: queda para revision humana,
   igual que ante un "Ok" ambiguo.
9. Si hay luz verde: se reabre la ficha y se ejecuta la secuencia de
   cierre confirmada con Manuel (Provision=591 + datos de rehuse ->
   Guardar -> abrir "Interfaz Ges" (boton "Apertura") -> Estado=Cerrada +
   Provision=0 -> Guardar, verificando de verdad recargando la pagina ->
   "Reestimar" -> "Rehuse" -> "Cerrar" en Interfaz Ges, esperando la
   confirmacion "OK" del historico en cada paso), salvo que Manuel haya
   pedido explicitamente saltarse el Interfaz Ges (p.ej. porque GES esta
   caida ese dia). Despues se escribe una observacion resumen, se sube el
   PDF de resolucion al expediente, se envia el correo final al cliente
   (salvo instruccion contraria de Manuel) y se sube tambien la copia
   `.msg` de ese envio como prueba. La averia pasa a fase **cerrado** y el
   correo de Manuel se archiva en `Neurona\Nominadas` para dejar la
   bandeja compartida limpia.

---

### SOLUCION DE PROBLEMAS

**"Login fallido en Garantia Global"**
-> Revisa `GG_EMAIL` / `GG_PASSWORD` en `config.py`.

**`SelectorNoVerificado` en el log**
-> Algo en la pagina de la intranet no coincide con lo que espera
   `ficha_averia.py` (puede que Garantia Global haya cambiado algo, o que
   ese caso concreto sea distinto a los ya probados). La averia en
   cuestion queda marcada `revision_manual` (no se pierde, no se fuerza
   nada malo). Ejecuta `python diag_nominadas.py <id_averia> [matricula]`
   contra ese caso real y ajusta el selector correspondiente en
   `ficha_averia.py`.

**`CierreNoConfirmado` en el log**
-> Se intento cerrar el expediente (cambiar Estado, o algun paso del
   Interfaz Ges) pero, tras recargar la pagina o revisar el historico, no
   se confirmo el cambio (puede ser un campo obligatorio vacio, GES
   caida, etc.). La averia se queda en `pendiente_manuel` para
   reintentarlo en el siguiente ciclo; revisa el expediente a mano en la
   intranet antes de que se reintente solo.

**El bot no le manda nada a Manuel / no comprueba su respuesta**
-> Comprueba si estamos dentro de la ventana de silencio (viernes 15:00
   a lunes 8:00, ver `horario_manuel.py`). Si ya deberia haber terminado
   y sigue en silencio, revisa la fecha
   `VENTANA_SILENCIO_MANUEL_VIGENTE_HASTA` en `config.py`: pasada esa
   fecha la ventana deja de aplicarse ella sola, sin tocar codigo.

**"No se pudo enviar el correo" / Outlook**
-> Asegurate de que Outlook de escritorio esta abierto y con la sesion de
   `neurona@garantiaglobal.com` iniciada en el PC que ejecuta la tarea, de
   forma permanente (no solo en horario laboral).

**`BuzonOcupado` en el log**
-> Otro bot (Flotas_bot, el bot de correo de averias/coberturas) esta
   usando la bandeja compartida de Neurona en ese instante. El ciclo se
   omite y se reintenta solo en el siguiente (10-60 min segun cual); no
   requiere accion salvo que aparezca en muchos ciclos seguidos.

**Word no convierte a PDF / `WINWORD.EXE` se queda colgado**
-> `generar_resolucion.py` mata el proceso `WINWORD.EXE` antes de cada
   intento (hasta 3 reintentos). Si falla siempre, comprueba que Word
   este instalado con una licencia activa en ese PC y que no haya quedado
   un dialogo de Word abierto esperando un clic.

**Aparece un placeholder tipo `[MATRÍCULA]` literal en la resolucion**
-> No deberia pasar: `generar_resolucion.py` aborta ANTES de generar el
   PDF si detecta que quedo algun placeholder sin sustituir. Si ocurre,
   revisa el `mapping` de `generar_resolucion.py` contra el texto exacto
   de la plantilla Word afectada.

**Correo duplicado al cliente o a Manuel**
-> Ya paso una vez en produccion (2026-08-13) por dos ejecuciones
   solapadas de `main.py`. El mutex `BotNominadasGG_Lock` (en `main.py`)
   evita que dos procesos corran a la vez; si sospechas que ha vuelto a
   pasar, revisa en el Administrador de tareas si hay mas de un
   `python.exe` de este bot corriendo, y compara las horas del log del
   dia con las de las tareas programadas.

**Faltan columnas en el export**
-> Si Garantia Global cambia el nombre de alguna columna (Id., Estado,
   Matricula, Fecha de ultima actualizacion), `descargar_candidatas.py`
   lanzara un error indicando cual falta.
