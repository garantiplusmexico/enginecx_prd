# Bot Neurona — automatización de altas de flota

Bot que lee el buzón **neurona@garantiaglobal.com** cada 5 minutos, procesa las solicitudes de ALTA FLOTA / ALTA FLOTA PARTNERS / RENOVACIÓN / ACTIVACIÓN FLOTA / ALTA FLOTA BROKER que llegan de los comerciales (o de un robot externo, en el caso de BROKER), y ejecuta el flujo completo en GES y en la intranet de Garantía Global, devolviendo un PDF final al comercial (o a la compraventa).

**Sin LLMs en el bucle. Sin app registration en Azure.** El coste operativo por correo procesado es cero.

---

## Si eres nuevo y no sabes nada de este bot, lee esto primero

Un comercial manda un correo a `neurona@garantiaglobal.com` con la matrícula
en el asunto (`ALTA FLOTA - <matrícula>`, `ALTA FLOTA PARTNERS - <matrícula>`,
`RENOVACION - <matrícula>` o `ACTIVACION FLOTA - <matrícula>`) siguiendo una
plantilla fija (ver `INSTRUCCIONES_COMERCIALES.txt`). El bot, sin que nadie
tenga que tocar nada, entra en GES para contratar la póliza, la da de alta
en la intranet de Garantía Global, genera el documento "Vehículo en
Depósito" y responde al comercial con los PDF.

**Desde el 14/08/2026 la plantilla de ALTA FLOTA / ALTA FLOTA PARTNERS se
simplificó**: el comercial ya solo tiene que rellenar **Compraventa,
Matrícula y Kilómetros actuales** (más los datos de contacto) — el resto
(NIF/CIF, teléfono y domicilio del tomador; marca/modelo, bastidor,
potencia y fecha de matriculación del vehículo) lo intenta rellenar el
propio bot: primero buscando en la intranet de Garantía Global y, si el
vehículo es nuevo, leyéndolo por OCR de la ficha técnica/permiso de
circulación (`src/autocompletar_alta.py`, `src/lector_documentos.py`). **Por
eso los 3 adjuntos (ficha técnica, permiso de circulación, foto del
kilometraje) siguen siendo imprescindibles** aunque ya no haga falta
transcribir esos datos a mano: son la fuente de la que el bot lee lo que no
encuentra en la intranet. RENOVACIÓN sigue pidiendo todos los campos como
antes (no tiene autocompletado propio distinto al de ALTA). Lo que no se
consiga rellenar solo cae, igual que siempre, en pedirlo por correo al
comercial.

Hay dos flujos más, además de ALTA/RENOVACIÓN, que ya están en producción
aunque no estén en la Fase 1 original (ver §8):
- **`ACTIVACION FLOTA - <matrícula>`**: activa en la intranet una garantía
  flotante ya contratada (solo pide matrícula y km al comercial) y manda el
  email de baja a `servicioalcliente@ges.es`. No toca GES para contratar
  nada nuevo.
- **`ALTA FLOTA BROKER - <número de contrato>`**: un robot externo crea la
  garantía flotante directamente en la intranet; Neurona solo lee ese
  contrato para replicar el alta en GES (con las credenciales de GES
  Partners) y enviar el "Vehículo en Depósito" a la compraventa. No hay
  comercial de por medio en este flujo.
- **`ACTIVACION PARTICULARES - <matrícula>`** (añadido 19/08/2026): pólizas
  de particulares captadas por el canal digital ("captación digital VL"),
  que ya existen en la intranet con la compraventa fija "TOMADOR PARTICULAR
  CAPTACIÓN DIGITAL VL" antes de que llegue ningún correo. La comercial solo
  manda Matrícula, Importe y Fecha de pago (Teléfono/Email del cliente son
  opcionales, con los mismos ficticios que ACTIVACION FLOTA si faltan). El
  bot no toca GES ni cliente/producto: busca la matrícula en la intranet,
  pone F.Pago y ajusta el Importe Sin Impuestos para que el Total salga
  igual al importe que dio la comercial (ver nota de la fórmula del 8,15%
  más abajo), guarda, descarga el contrato y lo reenvía a la comercial. Por
  instrucción explícita de Cesar (19/08/2026): el importe de la comercial
  siempre se escribe tal cual, sin comparar antes con lo que hubiera en la
  intranet ni escalar por descuadre — es la única excepción de este bot a
  la regla general de "no comprometer importes sin verificación", porque
  aquí la verificación ES el correo de la comercial. Si la matrícula no
  aparece en la intranet (no debería pasar, ya que la póliza se crea antes
  por el canal digital), se responde a la comercial pidiendo que revise la
  garantía generada, sin escalar a tramitación.

**El buzón de `neurona@garantiaglobal.com` lo comparten varios bots
independientes** (Flotas_bot/Neurona, Nominadas, y el bot de correo de
averías/coberturas — "W.app averias"), cada uno con su propio ciclo. Para
que no se pisen al tocar la misma Bandeja a la vez, todos usan el mismo
Mutex con nombre (`src/buzon_lock.py`, copiado igual en los tres proyectos)
antes de leer/mover/borrar nada — ver §9.1.

El ciclo completo (revisar pendientes, escalados, limpieza de bandeja y
correos nuevos) corre solo cada 5 minutos, **todos los días, sin límite de
horario**, mediante una tarea programada de Windows (`NeuronaFlotas`,
creada con `programar_tareas.ps1` — ver §7). El script `src/main.py`
también tiene un modo de bucle continuo (`python -m src.main`, sin
`--once`) que solo trabaja de 08:00 a 18:00, pensado para pruebas manuales
en primer plano, no para producción.

**El código de producción es todo lo que hay dentro de `src\`.** Los
scripts sueltos en la raíz (`completar_alta_*.py`, `completar_pdf_*.py`,
`enviar_email_*.py`, `parche*.py`, `probar_*.py`, `ver_*.py`, `convertir.py`,
`limpiar.py`) son arreglos manuales puntuales que se hicieron para una
matrícula concreta cuando el bot se quedó a medias — no se ejecutan solos
ni forman parte del proceso automático, y no hay que relanzarlos "por si
acaso". La carpeta `Viejo\` es código antiguo/de pruebas, ya no se usa.

### Dónde están las contraseñas

Ninguna contraseña está en el código: todas viven en el archivo **`.env`**
(en la raíz del proyecto, al lado de `.env.example`), que se lee desde
`src/config.py` con `python-dotenv`. El `.env` real **no debe compartirse
ni subirse a ningún sitio**. Variables que contiene:

| Variable en `.env` | Para qué |
|---|---|
| `GES_USER` / `GES_PASSWORD` | login en el portal de agente de GES (flujo normal) |
| `GES_PARTNERS_USER` / `GES_PARTNERS_PASSWORD` | login en GES para "ALTA FLOTA PARTNERS" **y también para "ALTA FLOTA BROKER"** — son la misma cuenta (la nº 01252), el manual de Broker solo la llama de otra forma. No crear variables nuevas para Broker. |
| `INTRANET_USER` / `INTRANET_PASSWORD` | login en la intranet de Garantía Global (misma cuenta `neurona@garantiaglobal.com` que usan `averias_bot`, `siniestros_bot` y `W.app averias`) |
| `BUZON_NEURONA` | buzón de Outlook que se lee |
| `ESCALADO_EMAIL` | a quién se avisa si un comercial no responde a tiempo (por defecto Cesar) |
| `ESCALADO_CC` | quién va SIEMPRE en copia de cualquier aviso de escalado (asunto no reconocido, pendiente vencido, etc.) — por defecto Miriam y tramitación. Instrucción de Cesar (17/08/2026): sin esta copia un caso puede quedar visto solo por Cesar/Miriam sin que tramitación se entere de que existe. |
| `HORAS_RECORDATORIO_TRAMITACION` | cada cuántas horas (admite decimales, por defecto 1.5) Neurona insiste a tramitación si un rechazo de GES escalado a mano sigue sin confirmarse con un "OK" en el mismo hilo |

> **Aviso de seguridad pendiente de resolver:** el archivo `.env.example`
> de este repo (que debería ser solo una plantilla vacía) tiene
> **rellenados de verdad** `INTRANET_USER` e `INTRANET_PASSWORD`, en vez
> de dejarse en blanco como el resto de campos. Es la misma contraseña
> compartida con los otros bots de esta carpeta. Recomendado: vaciar esos
> dos campos en `.env.example` y valorar con IT si conviene rotar esa
> contraseña, ya que ha quedado escrita en un archivo que normalmente se
> trata como "plantilla segura para compartir".

---

## Arquitectura

- **Lectura del buzón:** `pywin32` conecta con el Outlook Desktop del PC y usa la sesión que ya tiene el usuario. Cero configuración en Azure, cero credenciales secretas.
- **Coordinación con otros bots del mismo buzón:** un Mutex de sistema (`src/buzon_lock.py`) evita que Flotas, Nominadas y el bot de averías toquen la Bandeja a la vez; si está ocupado, el ciclo se omite y se reintenta en el siguiente disparo (5 min después).
- **Parseo del correo:** regex sobre la plantilla fija (`src/parser.py`), tolerante con etiquetas sin ":", cabeceras de cita de Outlook y varios idiomas de esas cabeceras.
- **Autocompletado de datos:** `src/autocompletar_alta.py` intenta rellenar tomador y vehículo desde la intranet y, si el vehículo es nuevo, con OCR de los adjuntos (`src/lector_documentos.py`) antes de pedir nada al comercial.
- **Acciones en GES e intranet:** Playwright (Chromium invisible en producción).
- **Word "Vehículo en Depósito":** `python-docx` rellena una plantilla + `docx2pdf` convierte a PDF.
- **Persistencia:** JSON local para hilos pendientes + CSV diario de auditoría.

---

## Estructura

```
automatizacion_correo/
├── src/
│   ├── main.py               # Orquestador (se ejecuta cada 5 min)
│   ├── config.py             # Configuración (lee .env)
│   ├── outlook_client.py     # Cliente Outlook local vía pywin32
│   ├── buzon_lock.py         # Mutex compartido con Nominadas / bot de averías
│   ├── parser.py             # Parseo de plantilla + validación adjuntos
│   ├── autocompletar_alta.py # Rellena tomador/vehículo desde intranet + OCR
│   ├── lector_documentos.py  # OCR de ficha técnica / permiso de circulación
│   ├── pending_manager.py    # Hilos pendientes + escalado a 2h
│   ├── mailer.py             # Plantillas HTML de respuesta
│   ├── ges_bot.py            # Playwright → GES
│   ├── intranet_bot.py       # Playwright → intranet Garantía Global
│   ├── deposito_generator.py # Word "Vehículo en Depósito" + PDF
│   └── audit_log.py          # Log CSV diario
├── tests/
│   └── test_parser.py        # Tests del parser (9, todos verdes)
├── plantillas/
│   ├── VEHICULO_EN_DEPOSITO_ALTA.docx        ← crear a mano (ver §4)
│   └── VEHICULO_EN_DEPOSITO_RENOVACION.docx  ← crear a mano (ver §4)
├── data/
│   ├── pending.json           # Estado de hilos pendientes (autogenerado)
│   ├── salida/                # Docx/PDF generados
│   └── logs/                  # Logs diarios
├── requirements.txt
└── .env.example               # Copiar a .env y rellenar
```

---

## 1. Requisitos del PC donde correrá

- Windows 10/11, encendido y **sin suspender** en horario laboral.
- Python 3.11 o superior.
- Google Chrome instalado (Playwright lo usa).
- **Outlook Desktop instalado, abierto, con el buzón `neurona@garantiaglobal.com` añadido** (como buzón principal o compartido). Es lo único que el bot necesita para el correo.
- Word instalado (para convertir docx→pdf).

---

## 2. Instalación

```bash
# En una terminal en la carpeta del proyecto:
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
playwright install chromium
```

Verificar tests:

```bash
python -m pytest tests/ -v
```

---

## 3. Configuración

### 3.1. Rotar credenciales de GES

Cambiar la contraseña de GES **antes** de meterla en el bot. La que estaba en el Word original ha circulado y debe rotarse.

### 3.2. Crear el `.env`

```bash
copy .env.example .env
notepad .env
```

Rellenar:
- `GES_USER`, `GES_PASSWORD`
- `INTRANET_URL`, `INTRANET_USER`, `INTRANET_PASSWORD`
- El resto ya vienen con valores razonables por defecto.

**No hay que configurar nada de Azure.** El bot usa la sesión de Outlook que ya tiene abierta el usuario del PC.

---

## 4. Crear las plantillas del Word "Vehículo en Depósito"

Coge los moldes originales (ALTA y RENOVACIÓN) y guarda dos copias en `plantillas/`:

- `VEHICULO_EN_DEPOSITO_ALTA.docx`
- `VEHICULO_EN_DEPOSITO_RENOVACION.docx`

En cada uno, sustituye los datos concretos por estos placeholders (**dobles llaves, sin espacios**):

| Dato | Placeholder |
|---|---|
| Nombre compraventa | `{{COMPRAVENTA}}` |
| NIF/CIF | `{{NIF_CIF}}` |
| Teléfono | `{{TELEFONO}}` |
| Domicilio | `{{DOMICILIO}}` |
| Nº póliza | `{{NUMERO_POLIZA}}` |
| F. Efecto | `{{FECHA_EFECTO}}` |
| Marca y modelo | `{{MARCA_MODELO}}` |
| Potencia | `{{POTENCIA_CV}}` |
| Kilometraje | `{{KM}}` |
| Matrícula | `{{MATRICULA}}` |
| Año de matriculación (derivado de la fecha completa que da el comercial) | `{{ANIO_MATRICULACION}}` |

---

## 5. Selectores de las webs (ya configurados, pero frágiles)

Los selectores CSS de `ges_bot.py` (diccionario `SEL`, ej. `#TOMADOR-tipoIdent`)
e `intranet_bot.py` **ya están rellenados con los valores reales** de GES y de
la intranet de Garantía Global — no quedan placeholders `TODO SELECTOR`
pendientes de sustituir, el bot lleva meses en producción con ellos. Aun así
son selectores CSS/XPath frágiles: si GES o la intranet cambian de diseño en
esa pantalla, el bot fallará de golpe en ese paso concreto y habrá que
localizar el selector nuevo y actualizarlo:

1. Poner `HEADLESS=false` en el `.env` para ver el navegador.
2. Poner un correo de prueba en el buzón y ejecutar:
   ```bash
   python -m src.main
   ```
3. En el paso donde falle:
   - F12 → pestaña Elementos.
   - Localizar el input/botón real.
   - Copiar su selector (click derecho → Copy → Copy selector).
   - Sustituir el selector correspondiente en `SEL` (`ges_bot.py`) o en la
     línea equivalente de `intranet_bot.py`.

Ver también §9.1: buena parte de los `parcheN.py`/`completar_alta_*.py`
sueltos en la raíz existen precisamente por esto — si el bot empieza a
fallar de golpe en un paso concreto, sospecha primero de un cambio de
diseño en esa web antes que de un bug del bot.

---

## 6. Modo DRY_RUN (recomendado las primeras semanas)

Con `DRY_RUN=true`, el bot hace **todo el flujo** hasta el paso final de contratar en GES / guardar en intranet, pero **no pulsa el botón definitivo**. Guarda una captura de pantalla en `data/salida/` para revisar. Cuando lleve 1-2 semanas sin fallos, pasar a `DRY_RUN=false`.

---

## 7. Programar la ejecución cada 5 minutos

**Forma recomendada (script ya incluido):**

```powershell
.\programar_tareas.ps1 -PyExe "C:\ruta\al\proyecto\.venv\Scripts\python.exe"
```

Esto crea/reemplaza la tarea `NeuronaFlotas` con:
- Desencadenador **diario a las 00:00** con repetición cada 5 minutos durante
  24 horas (así se relanza solo cada día — un trigger `-Once` con
  repetición, que se probó primero, **no** vuelve a dispararse al día
  siguiente, solo dentro del mismo día en que se creó).
- Acción: `python.exe -m src.main --once` (un ciclo y termina, no el bucle
  interno de `main()`).
- `-MultipleInstances IgnoreNew`: si un ciclo tarda más de 5 minutos (GES o
  la intranet lentos), el siguiente disparo se salta en vez de solaparse
  con el anterior sobre el mismo `pending.json`/buzón.

Con esto el bot corre **cada 5 minutos, todos los días, sin límite de
horario** (no está restringido a 08:00-18:00 ni a días laborables). El
script **no se ejecuta solo** — hay que lanzarlo a mano una vez desde
PowerShell en el PC donde va a correr, con el usuario ya logueado (para que
Outlook esté abierto).

**Alternativa manual (Programador de tareas, interfaz gráfica):**

1. Crear tarea básica → "NeuronaFlotas".
2. Desencadenador: diario, cada 5 minutos, repitiendo durante 1 día (para
   que se renueve solo cada día — ver nota de arriba).
3. Acción: iniciar programa → `C:\ruta\al\proyecto\.venv\Scripts\python.exe`.
4. Argumentos: **`-m src.main --once`** (sin `--once` se lanza el bucle
   interno de `main()`, que solo trabaja 08:00-18:00 y se quedaría
   corriendo indefinidamente en paralelo con cada disparo siguiente de la
   tarea — no es lo que se quiere con un trigger repetitivo).
5. Iniciar en: `C:\ruta\al\proyecto\`.
6. **Debe ejecutarse con el usuario logueado** (para que Outlook esté abierto).
7. En Configuración, activa "No iniciar una nueva instancia" (equivalente a
   `IgnoreNew`) para evitar solapamientos.

**Modo bucle continuo (`python -m src.main`, sin `--once`)**: existe para
pruebas manuales en primer plano — corre indefinidamente, un ciclo cada 5
minutos, pero solo entre las 08:00 y las 18:00 (fuera de ese horario
duerme hasta las 8:00 siguientes). No es el modo que usa la tarea
programada en producción.

---

## 8. Qué hace este bot

**Sí:**
- Lee correos con asunto `ALTA FLOTA - <matrícula>`, `ALTA FLOTA PARTNERS - <matrícula>`, `RENOVACION - <matrícula>`, `ACTIVACION FLOTA - <matrícula>`, `ACTIVACION PARTICULARES - <matrícula>` y `ALTA FLOTA BROKER - <número de contrato>`.
- Para ALTA FLOTA/PARTNERS y RENOVACION: intenta rellenar solo con lo que falte (intranet + OCR de adjuntos) antes de pedir nada al comercial (ver §"autocompletado" arriba).
- Valida campos y adjuntos. Si falta algo, responde al comercial y espera.
- Re-chequea cada 5 min si el comercial ha respondido con lo que faltaba.
- Si a las 2h no hay respuesta, avisa a `ESCALADO_EMAIL` (con `ESCALADO_CC` siempre en copia) — sigue vigilando el hilo, no abandona el caso.
- Si la marca/modelo del correo no coincide con lo que devuelve GES, o si GES rechaza el alta por un motivo de negocio (ej. matrícula ya en vigor en otra póliza), o si falta el domicilio del tomador para que GES lo encuentre: pregunta al comercial en el mismo hilo antes de escalar; si tras su respuesta el problema persiste, escala a `tramitacion@garantiaglobal.com` y espera su "OK" en el mismo hilo para dar el caso por cerrado (insistiendo cada `HORAS_RECORDATORIO_TRAMITACION` si no responde).
- Contrata la póliza en GES (ALTA FLOTA / PARTNERS / RENOVACION / BROKER).
- Da de alta en la intranet, con adjuntos (excepto BROKER, cuyo alta en intranet ya la hace un robot externo).
- Descarga el contrato PDF.
- Genera el Word "Vehículo en Depósito" y lo convierte a PDF.
- Responde al comercial (o a la compraventa, en BROKER) con el PDF adjunto.
- **ACTIVACION FLOTA**: activa en la intranet una garantía flotante ya contratada (actualiza cliente, km, F.Inicio/F.Fin y producto a la variante "Activa" del mismo canal) y envía el email de baja a `servicioalcliente@ges.es`. No pasa por GES.
- **ACTIVACION PARTICULARES**: la póliza (canal captación digital) ya existe en la intranet — pone F.Pago y ajusta el importe para que el Total salga igual al que da la comercial, guarda, descarga el contrato y lo reenvía a la comercial. No pasa por GES ni toca cliente/producto. Si la matrícula no aparece, avisa a la comercial para que revise la garantía generada (sin escalar a tramitación).
- Organiza el buzón en subcarpetas (Tramitado / Pendiente doc / Escalado / Error / SAC GES).
- Barre la Bandeja para archivar en Tramitado correos de gestiones que el propio bot ya cerró con OK (confirmaciones tardías, copias que quedaron leídas sin archivar) — nunca borra nada.
- Ignora sin tocar los correos que son de otros bots del mismo buzón (asunto "Nominadas" o "INFORMACION"/respuestas del bot de averías) y los avisos automáticos de SAC GES.
- Registra cada operación en un CSV diario.

**No (todavía):**
- MODIFICACIONES (importes) → las modificaciones de importe requerirán confirmación humana (regla del proyecto: no comprometer importes sin verificación).
- La salvaguarda anti-duplicados de GES (`buscar_proyecto_existente_por_matricula`) está implementada pero **desactivada** mientras se estabiliza el flujo de renovaciones — ver riesgo en §9.1.

---

## 9. Depuración

- Logs del día: `data/logs/bot_YYYY-MM-DD.log`
- Auditoría (una fila por correo): `data/logs/neurona_YYYY-MM-DD.csv` (columnas: `timestamp, message_id, tipo, matricula, compraventa, email_comercial, resultado, numero_poliza, detalle`; `resultado` puede ser `OK`, `PENDIENTE_DOC`, `ESCALADO`, `ERROR`, `DRY_RUN`).
- Capturas de pantalla de cada paso (y en cada error) de Playwright: `data/salida/ges_*.png` y `data/salida/intranet_*.png` (más volcado de HTML en `ges_error_*.html`).
- Cola de correos con datos/adjuntos incompletos: `data/pending.json`, gestionada por `src/pending_manager.py`. Cada entrada guarda cuántas veces se ha reclamado (`veces_pedido`) y si ya se escaló.
- Correos con error → carpeta `Neurona/Error` en Outlook.
- Correos escalados → carpeta `Neurona/Escalado`.
- Correos ya tramitados → carpeta `Neurona/Tramitado`; con documentación pendiente → `Neurona/Pendiente documentacion`.

### 9.1. Riesgos operativos conocidos

- **Comprobación anti-duplicados desactivada temporalmente en GES**
  (`src/ges_bot.py`, función `contratar()`): tras un incidente real
  (matrícula 4654HGR, 22/07/2026) en el que 3 reintentos crearon 3
  pólizas duplicadas, se añadió `buscar_proyecto_existente_por_matricula`,
  pero está desactivada mientras se estabiliza el flujo de renovaciones.
  **Hasta que se reactive, si el bot reintenta una gestión, revisa a mano
  en GES que no se haya duplicado la póliza.**
  - Origen de este comportamiento: es intencional, sirvió para permitir
    resolver renovaciones que requerían reintento.
- Los selectores CSS de `ges_bot.py`/`intranet_bot.py` son frágiles ante
  cambios en las webs de GES/intranet — de ahí la cantidad de
  `parcheN.py` y `completar_alta_*.py` puntuales en la raíz; si el bot
  empieza a fallar de golpe en un paso concreto, sospecha primero de un
  cambio de diseño en esa web antes que de un bug del bot.
- **El EntryID guardado en pending.json quedaba obsoleto al mover el
  correo de carpeta (corregido 2026-08-14).** Confirmado con una prueba
  directa: al mover un item entre carpetas del MISMO store de Exchange,
  Outlook le asigna un EntryID nuevo - el objeto en memoria no se
  autoactualiza, así que si se registraba `mensaje.EntryID` de ANTES de
  moverlo (que es lo que hacía `procesar_mensaje` en los 6 sitios donde se
  deja un pendiente), ese ID nunca volvía a resolver via
  `buscar_por_entry_id`/`GetItemFromID`. Esto rompía en silencio (con solo
  un warning en el log) tanto `_rutas_pendiente` (adjuntos del correo
  original al reintentar) como `_escalar_pendiente` (reenviaba un aviso
  suelto en vez del hilo original) y probablemente explica, al menos en
  parte, los "redetectados infinitos" ya documentados en
  `hay_respuesta_nueva` (1450HHM/0109JPW/3151LRK): si el mensaje de
  referencia nunca se encuentra por EntryID, el filtro por fecha tampoco
  se aplica. Caso real que lo destapó: RENOVACION 2215LCW, que se quedó
  con `autocompletado_intentado=false` sin que nada la reintentara.
  Arreglado centralizando el patrón "mover y luego registrar" en
  `_mover_y_registrar_pendiente()` (`main.py`), que usa siempre el EntryID
  que devuelve `mensaje.Move()`, nunca el de antes de mover.
  - **Ampliación 2026-08-17 (matrícula 7013NRB):** el propio `Move()` puede
    fallar con un `com_error` intermitente de Outlook ("No se pueden mover
    los elementos"), visto justo después de un `Reply()` sobre el mismo
    mensaje. Si eso no se controla, el pendiente no llega ni a registrarse
    y el correo se vuelve a detectar como nuevo en el siguiente ciclo,
    repitiendo la misma pregunta al comercial sin fin. Ahora, si el
    `Move()` falla, se registra igual el pendiente con el EntryID de antes
    de mover: mejor un pendiente en la carpeta equivocada que uno perdido.
- **ACTIVACIÓN cambiaba el producto contratado sin querer (corregido
  2026-08-14).** `intranet_bot.activar_poliza_flotante()` buscaba en el
  combo Producto (Select2-AJAX) solo la palabra "ACTIV" y se quedaba con la
  primera opción del listado que la contuviera, sin comprobar que fuera una
  variante activa del MISMO producto que el cliente ya tenía contratado.
  Caso real: matrícula 7508LVB (14/08/2026) — el producto pasó de forma
  incorrecta a "Global Auto F1 Activa - Broker" sin que ese fuera el canal
  contratado (aviso de Esther González, equipo Venta Online). Ahora se lee
  el producto/canal (Broker o no) que tenía asignado ANTES de tocar el
  combo, y solo se selecciona una opción "ACTIV" que respete ese mismo
  producto/canal; si no hay ninguna que lo respete, aborta sin marcar como
  activada en vez de adivinar. **La póliza de 7508LVB quedó con el producto
  incorrecto en la intranet y requiere corrección manual** — el bot no
  reescribe registros ya guardados.
- **ACTIVACIÓN leía mal el producto original (corregido 2026-08-14, mismo
  día que el bug anterior).** El fix de arriba seguía leyendo el producto
  actual con `producto_select.locator("option").first` (primera `<option>`
  del `<select>` nativo). Caso real: matrícula 3711HYB (14/08/2026) — esa
  primera opción era un placeholder ("Selecciona...") y no el producto
  real, así que la búsqueda posterior no encontró ninguna variante ACTIV y
  el bot abortó sin activar (aviso a tramitación para hacerlo a mano). Es
  más grave de lo que parece: si el texto leído hubiera quedado vacío en
  vez de ser un placeholder no vacío, el filtro de canal se salta
  silenciosamente y el bot vuelve a poder coger la primera opción ACTIV de
  cualquier producto — reintroduciendo el bug de 7508LVB. Ahora se lee el
  producto actual del contenedor visual de Select2
  (`_texto_select2_contenedor`, el mismo helper ya usado para marca/
  compraventa) y, si el texto resultante es un placeholder conocido
  ("Selecciona...", "Seleccione un elemento", vacío...), se aborta de
  inmediato con un mensaje claro en vez de seguir.
- **ACTIVACIÓN de 3711HYB reintentada con el fix de arriba y AÚN ASÍ no se
  guardó, dando falso positivo (corregido 2026-08-14).** Al reintentar
  3711HYB tras el fix de lectura de producto, el guardado de "Editar
  Contratos" falló de verdad con un toast "Error no se pudo guardar" (el
  teléfono del cliente llevaba espacios - "662 49 49 65" - y superaba la
  longitud máxima que valida el servidor) y el formulario reseteó TODOS
  los combos Select2 (Producto, Compraventa, Forma de Pago) a
  "Selecciona...". Pero la comprobación final del bot solo buscaba la
  palabra "ACTIV" en `page.content()` completo, y esa palabra seguía
  presente en el DOM (opciones ya cargadas por el AJAX del combo aunque no
  se hubiera guardado nada) - el bot dio el caso por bueno, envió el email
  de baja a GES y marcó la gestión como tramitada, sin que el contrato se
  hubiera actualizado. Verificado leyendo el contrato en fresco tras el
  "éxito": producto seguía en "Global flotante" (no Activa) y Nombre/NIF/
  Teléfono/Email vacíos. Dos fixes aplicados: (1) `telefono_cliente` se
  normaliza quitando todo lo que no sea dígito antes de rellenar cualquier
  formulario; (2) la comprobación final ahora exige que no aparezca el
  aviso "Error no se pudo guardar" Y que el contenedor Select2 del propio
  Producto (releído tras guardar) muestre de verdad una variante ACTIV, en
  vez de mirar el HTML completo de la página. También se amplió la
  detección de errores del formulario de propietario: antes solo
  reconocía la clave `validation.required`, y una regla distinta como
  `validation.max.string` (justo la que disparó este incidente) pasaba
  desapercibida. Corregido manualmente en producción tras diagnóstico con
  captura de red: 3711HYB quedó con producto "Global Flotante Activa" y
  datos de cliente completos (Florencia Guantay Oliva); el email de baja a
  GES ya enviado con el falso positivo NO se ha corregido/retirado - queda
  pendiente avisar a tramitación de que fue prematuro.
- **ACTIVACIÓN de 8222HGW guardó bien pero el bot dio FALSO NEGATIVO
  (corregido 2026-08-14).** Caso inverso al de 3711HYB de arriba: el
  guardado de "Editar Contratos" sí se completó en el servidor (producto
  final "Tarifa plana flotante activa", el correcto), pero la comprobación
  final releía el contenedor visual de Select2 del Producto DEMASIADO
  PRONTO tras el clic en Guardar - el widget queda en un estado transitorio
  ("Selecciona...") antes de repintarse con el valor ya persistido, y el
  bot lo interpretó como que el guardado no había persistido. Abortó sin
  marcar como activada, dejando sin enviar el email de baja a GES y
  avisando (de forma incorrecta) a tramitación y al comercial de que había
  que hacerlo a mano. Verificado con un script de solo lectura que repitió
  la navegación de búsqueda/edición sin tocar Guardar: el contrato ya
  estaba activo. Fix: tras el clic en Guardar y comprobar que no aparece el
  toast "Error no se pudo guardar", se recarga la página (`page.reload()`)
  antes de releer el contenedor Select2 del Producto, forzando a que se
  reinicialice desde el `<select>` ya persistido en servidor en vez de
  desde el estado a medio repintar. Pendiente: reenviar el email de baja a
  GES para 8222HGW y avisar a tramitación/comercial de que la activación sí
  se completó.
- **RENOVACION no buscaba en intranet/OCR (corregido 2026-08-14).**
  `autocompletar_alta.completar()` excluía explícitamente RENOVACION
  alegando que "ya tiene su propia fuente de datos", pero esa fuente
  nunca se implementó: cualquier campo que faltara en una renovación
  caía siempre en "pedir documentación al comercial", aunque el dato
  (tomador vía compraventa, vehículo vía matrícula) ya estuviera en la
  intranet. Caso real: matrícula 2988HMC (búsqueda de tarjeta de
  producto) y 2215LCW (quedó en Pendiente documentación pudiéndose
  completar por intranet). Ahora RENOVACION pasa por el mismo
  autocompletado que ALTA FLOTA/PARTNERS (`autocompletar_alta.py`,
  `main.py`).
- **Buzón compartido con otros bots: dos procesos movieron el mismo correo
  casi a la vez (corregido 2026-08-17/18).** Flotas_bot, Nominadas y el bot
  de correo de averías/coberturas automatizan el mismo Outlook de
  escritorio sobre la misma Bandeja, sin coordinación entre ellos. Outlook
  falló con "se copiaron en lugar de moverse porque no se pueden eliminar
  los elementos originales" cuando dos bots tocaron el mismo correo casi
  simultáneamente. Fix: un Mutex de sistema con nombre (`Buzon_Neurona_Lock`,
  `src/buzon_lock.py`) que cualquiera de los tres adquiere antes de
  leer/mover/borrar algo de la Bandeja; si otro bot lo tiene, espera hasta
  60s y si no se libera se rinde y deja el intento para el ciclo siguiente
  (seguro, porque los tres se repiten solos en minutos). El decorador
  `@buzon_lock.requerido` envuelve `ciclo_unico()` en `main.py`. **El mismo
  fichero está copiado igual en Flotas_bot, Nominadas y "W.app averias"**
  (proyectos independientes, sin paquete compartido) - si se corrige algo
  aquí, hay que replicarlo a mano en los otros dos.
- **Correo "INFORMACION" del bot de averías se movía a Error antes de que
  ese bot pudiera contestarlo (corregido 2026-08-18).** Flotas_bot no
  reconocía el asunto "INFORMACION"/"RE: INFORMACION" (canal de correo del
  bot "W.app averias", mismo buzón Neurona) como ajeno, y lo trataba como
  "asunto no reconocido", moviéndolo a `Neurona/Error` antes de que el otro
  bot lo recogiera. Ahora `procesar_mensaje` lo detecta
  (`config.ASUNTO_BOT_AVERIAS`) y lo deja intacto en la Bandeja, igual que
  ya hacía con los correos de "Nominadas".
- **Respuestas del comercial sin ":" en la etiqueta se perdían (corregido
  2026-08-17, matrícula 7277JTG).** El propio correo que manda Neurona
  pidiendo datos usa el formato "viñeta + etiqueta valor" sin ":", y los
  comerciales suelen responder imitándolo literalmente. Antes, esas líneas
  caían por la vía de "adivinar el campo por la forma del valor", que no
  sabe reconocer marca/modelo ni potencia en texto libre - los 4 campos
  pedidos llegaban bien pero el bot los seguía dando por "incompletos".
  Fix: `_intentar_etiqueta_sin_dos_puntos` en `parser.py` reconoce
  "Etiqueta valor" (sin ":") si la línea empieza por un alias de campo
  conocido. De paso se corrigió que un teléfono/NIF/matrícula suelto en la
  firma del comercial (detectado "por forma") pudiera pisar en silencio un
  dato ya bueno que vino etiquetado en una respuesta anterior - ahora esos
  campos "adivinados por forma" no sobrescriben un valor ya confirmado.
- **Domicilio con "del compraventa" en la etiqueta se perdía sin avisar
  (corregido 2026-08-17, matrícula 7558GDF).** Etiquetas como "Domicilio
  del compraventa:" no coincidían con ningún alias conocido (solo
  "domicilio" a secas) y, al no existir heurística de forma para
  direcciones, el valor se descartaba en silencio - el domicilio llegó
  bien etiquetado 6 veces seguidas y las 6 se perdieron, agotando el tope
  de reintentos. Fix: `parser.py` reconoce y quita el cualificador ("del/de
  la compraventa/tomador/cliente") tanto si viene pegado a la etiqueta como
  al valor.
- **Nombre de compraventa abreviado o con typo no se encontraba en el combo
  de la intranet (corregido 2026-08-17, matrícula 2979KFL).** El correo
  traía "GR AUTOVAN" pero la ficha real en la intranet es "GRP AUTOVAN
  S.L" - la póliza ya se había contratado en GES y el alta en intranet se
  quedó a medias solo por no coincidir el texto. Fix:
  `_resolver_compraventa_por_cif` en `intranet_bot.py` prueba, cuando el
  nombre exacto no se encuentra, palabras clave del nombre (las más
  distintivas primero) y solo da por buena una compraventa si su NIF/CIF
  real coincide exactamente con el del correo - nunca decide por parecido
  de nombre a solas.
- **Reparto de nombre/apellidos con nombre compuesto, en ACTIVACIÓN
  (corregido 2026-08-17, matrícula 8294HCN).** Repartir por posición desde
  el principio (1ª palabra = nombre, 2ª = primer apellido) rompía con
  nombres compuestos: "Andrés Felipe Muñoz Espinosa" quedaba como
  Nombre=Andrés, Apellido1=Felipe, Apellido2=Muñoz Espinosa. Fix: ahora se
  toman las **dos últimas palabras** como apellidos (convención
  española/latina) y todo lo anterior como nombre, por compuesto que sea
  (`_ejecutar_activacion` en `main.py`).
- **F.Inicio/F.Fin de la garantía no se actualizaban al activar (corregido
  2026-08-17, matrícula 2343LWY).** `activar_poliza_flotante()` nunca
  tocaba esos campos, así que el contrato se quedaba con la fecha de
  contratación de la flota original en vez de la fecha real de activación.
  Ahora se rellenan con la fecha de hoy y "hoy + `INTRANET_DURACION_MESES`
  meses - 1 día" (`_fecha_fin_garantia` en `intranet_bot.py`).
- **Escalado sin copia a tramitación, y correos ya resueltos que se
  quedaban en la Bandeja (corregido 2026-08-17, instrucción de Cesar).**
  Antes un aviso de escalado podía llegar solo a `ESCALADO_EMAIL` sin que
  tramitación se enterara de que el caso existía. Ahora **todo aviso de
  escalado lleva siempre en copia `ESCALADO_CC`** (por defecto Miriam y
  tramitación). Además se añadió `limpiar_bandeja_flotas_resueltas()`
  (`main.py`), que en cada ciclo barre la Bandeja completa buscando
  correos de una gestión que el propio bot ya cerró con "OK" en el
  audit_log (confirmaciones/acuses tardíos, o el original que quedó
  marcado leído sin archivarse) y los archiva en `Neurona/Tramitado` -
  **nunca borra nada**. No toca una matrícula con un pendiente activo, ni
  un correo anterior a la última gestión OK registrada (para no archivar
  por error, p. ej., la renovación de este año solo porque la del año
  pasado ya está cerrada).
- **Matrícula del asunto con guion "ancho" se fusionaba con el texto
  siguiente (corregido 2026-08-17, póliza 0550162434, matrícula 0481HWT).**
  En asuntos tipo "ALTA FLOTA 0481HWT - Poliza 0550162434", la limpieza de
  matrícula (que quita espacios/guiones de cualquier posición) fusionaba
  matrícula y texto siguiente en uno solo. `parsear_asunto` ahora corta en
  el primer " - " (guion con espacios a los lados) antes de limpiar, sin
  romper matrículas que ya llevan un guion pegado (ej. "6150-DFS"). De
  paso se corrigió que, si el cuerpo no traía la matrícula pero el asunto
  sí, no se usara esa matrícula para disparar el autocompletado por
  intranet - ahora `validar()` en `parser.py` la toma del asunto en ese
  caso.

---

## 10. Coste

- **API de Claude/LLM: 0 €/mes.**
- Azure/Graph: 0 € (no se usa).
- Playwright, Outlook local, python-docx: gratuitos.
- Único coste: electricidad del PC.
