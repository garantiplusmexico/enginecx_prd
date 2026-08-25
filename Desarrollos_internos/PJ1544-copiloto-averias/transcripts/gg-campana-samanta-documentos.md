# Actualizacion masiva del protocolo de averias (proyecto Samanta)

> **Si eres nuevo y no sabes nada de este proyecto, lee esto primero.**
> Esto NO es un bot que corre solo ni una tarea programada: es un
> pipeline de 6 scripts de Python, numerados del `01` al `06`, pensados
> para ejecutarse **a mano, uno detras de otro, desde la consola**,
> durante una campaña puntual de correccion masiva de documentos. No
> hay ningun `main.py` que los encadene ni ninguna tarea de Windows
> asociada. Si necesitas repetir la campaña (otro lote de productos, u
> otro parrafo a corregir), este LEEME te explica el orden y que
> comprobar en cada paso.

## Para que sirve esto

Garantia Global detecto que muchos documentos de "Contrato" y
"Certificado" de productos **GES Seguros y Reaseguros**, generados
desde la Intranet, llevaban un parrafo antiguo/erroneo del punto
"Protocolo de averias" (con el telefono y el correo antiguos de
siniestros). Habia que sustituirlo por el parrafo correcto (con el
formulario web nuevo) en todos los documentos afectados, **sin tocar
nada mas del documento** y **sin tocar los productos de otras
aseguradoras** (Helvetia y AmTrust ya llevaban el texto bueno o estan
descatalogados).

El documento `Instrucciones para la actualizacion masiva del
protocolo de averias.docx` (en la raiz de esta carpeta) es el encargo
de negocio original: define esas reglas (que aseguradoras se tocan,
cuales no, que hacer si hay duda). Los dos modelos:

- `modelo con párrafo ciorrecto.docx` (el nombre del archivo tiene esa
  errata de fabrica, "ciorrecto" en vez de "correcto"; no la corrijas
  al citarlo o el enlace deja de apuntar al archivo real) — plantilla
  de certificado con el parrafo **ya corregido**, de referencia.
- `modelo con párrafo erróneo.docx` — la misma plantilla con el
  parrafo **antiguo**, de referencia.

Estos dos documentos son la fuente de los textos `OLD_RAW` / `NEW_RAW`
que estan escritos literalmente dentro de `proceso\06_clasificar.py`.
Si algun dia cambia de nuevo el texto del protocolo, hay que actualizar
esas dos constantes en el script (y, si se quiere ser prolijo, generar
tambien modelos `.docx` nuevos de referencia).

`_pruebas_validacion\PRUEBA_modelo_modificado.docx` es una prueba
manual que se hizo antes de lanzar la campaña real, para comprobar a
ojo que la sustitucion no rompia el formato del documento.

---

### DONDE ESTAN LAS CONTRASEÑAS

Estan en `proceso\.env` (no van en ningun script en texto plano, a
diferencia de otros bots de esta carpeta compartida):

- `INTRANET_USER` y `INTRANET_PASSWORD` -> credenciales de acceso a
  `https://intranet.garantiaglobal.com`. Son la cuenta de servicio
  "neurona" (el propio comentario del `.env` dice que estan
  reutilizadas de `siniestros_bot/config.py`). **Si se cambia la
  contraseña de esa cuenta en la intranet, hay que actualizarla aqui
  tambien**, o todos los scripts fallaran con "Login fallido".
- Todos los scripts (`01` a `05`) cargan este `.env` con
  `python-dotenv` desde la propia carpeta `proceso\`, asi que solo hay
  que mantener un archivo actualizado. `06_clasificar.py` no necesita
  `.env` porque no entra en la intranet: trabaja offline sobre los
  `.docx` ya descargados.

No hay ninguna otra credencial en el proyecto (no usa SMTP, no usa
Outlook, no llama a ninguna API externa aparte de la intranet).

---

### ARCHIVOS DEL PROYECTO

**Raiz de `Samanta\`:**
- `Instrucciones para la actualización masiva del protocolo de averías.docx` -> encargo de negocio, reglas de que se toca y que no
- `modelo con párrafo ciorrecto.docx` -> plantilla de referencia con el texto ya corregido
- `modelo con párrafo erróneo.docx` -> plantilla de referencia con el texto antiguo
- `_pruebas_validacion\` -> prueba manual de validacion previa a la campaña real
- `proceso\` -> todo el pipeline (ver abajo)
- `LEEME.md` -> este documento

**Dentro de `proceso\`:**
- `.env` -> credenciales de la intranet (ver seccion anterior)
- `01_reconocimiento.py` -> exploracion inicial de la pantalla de productos (solo lectura, no genera CSV)
- `02_listar_ges.py` -> filtra productos "Ges Seguros" y vuelca el listado completo en `productos_ges.csv`
- `03_inspeccionar_ficha.py` -> inspecciona la ficha de un producto concreto para ver la estructura de "Contrato y Certificado" (uso de desarrollo, no forma parte del flujo de datos)
- `04_probar_descarga.py` -> prueba de descarga con los 4 primeros productos, antes de lanzar la descarga completa
- `05_descargar_todos.py` -> descarga masiva de Contrato+Certificado de todos los productos de `productos_ges.csv`, con log en `log_descargas.csv`
- `06_clasificar.py` -> clasifica cada `.docx` descargado (aseguradora + estado del parrafo) y genera `registro_control.csv` + `candidatos_sustitucion.csv`. **No modifica ningun archivo.**
- `productos_ges.csv` -> salida del paso 02 (listado de productos GES)
- `log_descargas.csv` -> salida/registro del paso 05 (resultado de cada descarga)
- `registro_control.csv` -> salida del paso 06 (clasificacion de cada documento)
- `registro_control_intento1_COM_parcial.csv` -> backup historico de un primer intento fallido de una fase posterior; se conserva como referencia, no se usa por ningun script
- `candidatos_sustitucion.csv` -> salida del paso 06 (subconjunto que si se debia corregir)
- `clasificacion_completa.log`, `descarga_completa.log`, `sustitucion_completa.log` -> logs de consola de ejecuciones ya realizadas (ver "Estado actual" mas abajo)
- `capturas\` -> capturas de pantalla de depuracion de los pasos 01-03
- `descargas\` -> `.docx` originales descargados por el paso 05 (`{id}_contrato.docx` / `{id}_certificado.docx`)
- `modificados\` -> `.docx` ya corregidos (salida de la fase de sustitucion, ver "Lo que falta" mas abajo)
- `seccion_contrato_certificado.html` -> volcado de HTML de una ficha, usado como apunte de desarrollo al escribir el paso 03

---

### PASO 1 — Requisitos previos

- Python 3.9 o superior (el codigo usa `pathlib` y f-strings; no hay
  ninguna dependencia de una version concreta mas alla de eso).
- Acceso de red a `https://intranet.garantiaglobal.com` con la cuenta
  de servicio de `proceso\.env`.
- **Solo en Windows, y solo si hay que repetir la fase de sustitucion
  real (ver "Lo que falta")**: Microsoft Word instalado en el PC que
  ejecute ese paso, porque esa fase controla Word por COM.

No existe un `requirements.txt` en el proyecto. Segun los `import` de
los scripts, las dependencias de terceros son:
```
playwright
python-dotenv
python-docx
```
Instalacion recomendada:
```
pip install playwright python-dotenv python-docx
playwright install chromium
```
(Si se reconstruye la fase de sustitucion por COM en Python en vez de
PowerShell, añadir tambien `pywin32`.)

---

### PASO 2 — Ejecutar el pipeline de reconocimiento y descarga (orden 01 a 05)

Todo se lanza desde dentro de `proceso\`, en este orden, uno a uno y
revisando la salida por consola antes de pasar al siguiente:

```
python 01_reconocimiento.py
python 02_listar_ges.py
python 03_inspeccionar_ficha.py
python 04_probar_descarga.py
python 05_descargar_todos.py
```

- `01` y `03` son de exploracion/depuracion: no hace falta relanzarlos
  si ya conoces la estructura de la pantalla de productos y de la
  ficha. Solo son utiles si la Intranet cambia de maquetacion y hay
  que volver a localizar los selectores.
- `03_inspeccionar_ficha.py` tiene el **id de producto `833` escrito a
  fuego** en la URL (`/productos/833/edit`); si ese producto ya no
  existe, cambia el numero en el propio script.
- `02_listar_ges.py` sobreescribe `productos_ges.csv` cada vez que se
  ejecuta (no es reanudable ni acumulativo). Si se relanza para un
  lote distinto de productos, se pierde el listado anterior salvo que
  se haga una copia antes.
- `04_probar_descarga.py` es solo una prueba con los 4 primeros
  productos de `productos_ges.csv`, guarda en `descargas_prueba\`
  (carpeta aparte) y sirve para confirmar que la descarga autenticada
  funciona antes de lanzar el lote completo.
- **`05_descargar_todos.py` es el paso largo** (hasta 2 descargas por
  producto: contrato y certificado). **Es reanudable**: al arrancar
  lee `log_descargas.csv` y se salta cualquier `(id, tipo)` ya marcado
  `OK`, asi que si se corta a mitad (red, sesion caducada, etc.) basta
  con volver a lanzarlo tal cual. Los `ERROR` no se reintentan solos:
  hay que revisar `log_descargas.csv`, mirar la columna `nota`, y
  volver a lanzar el script (los `ERROR` no bloquean que se reintenten
  en la siguiente ejecucion, solo los `OK` se saltan).

Todos estos scripts hacen login contra la Intranet simulando el
formulario web con Playwright (Chromium headless): rellenan el
usuario/contraseña de `.env`, pulsan "Acceder" y comprueban que la URL
ya no sea `/login`. Si el login falla, `02` y `05` lanzan
`RuntimeError("Login fallido")` y se detienen (no reintentan solos,
salvo `01` que reintenta 3 veces solo el `goto` inicial de la pagina).

---

### PASO 3 — Clasificar los documentos descargados

```
python 06_clasificar.py
```

Este paso es **offline**: no toca la Intranet, solo lee los `.docx` ya
guardados en `descargas\` con la libreria `python-docx`. Tambien es
**reanudable** (salta lo que ya este en `registro_control.csv`).

Por cada documento identifica primero la aseguradora buscando texto
literal ("ges seguros y reaseguros", "helvetia", "amtrust"/"am trust")
y despues, solo si es GES, compara cada parrafo normalizado contra las
constantes `OLD_RAW` / `NEW_RAW` escritas al principio del script. El
resultado de cada documento queda en `registro_control.csv`, y los que
tienen **exactamente una** coincidencia exacta con el parrafo antiguo
(candidato firme, sin ambiguedad de maquetacion) pasan ademas a
`candidatos_sustitucion.csv`. **Este script nunca modifica ningun
`.docx`**, es puro diagnostico.

Los documentos que no encajan en ningun caso claro (aseguradora
ambigua, protocolo no localizado, mas de una coincidencia con el texto
antiguo, variante de redaccion) quedan marcados como
`REVISION MANUAL - ...` en `registro_control.csv` para que alguien los
mire a mano en Word; el script nunca decide por su cuenta en esos
casos.

---

### Lo que falta en este repositorio: la fase de sustitucion real

**Importante para quien retome esto:** los logs `sustitucion_completa.log`
y `registro_control_intento1_COM_parcial.csv` prueban que **si existio
una fase 2**, la que de verdad abria cada `.docx` de
`candidatos_sustitucion.csv` con Word por COM, sustituia el parrafo
antiguo por el nuevo y guardaba el resultado en `modificados\` (hay
484 archivos en esa carpeta, el mismo numero que candidatos). Pero
**el script de esa fase no quedo guardado dentro de `proceso\`**: por
el rastro que deja en `clasificacion_completa.log`, se ejecuto como un
script de PowerShell (`clasificar_sustituir.ps1`) lanzado desde una
carpeta temporal de sesion, y no se copio nunca a este proyecto.

Si hay que repetir la campaña (otro parrafo, otro lote de productos),
**hay que reconstruir ese paso**. Por lo que revela el log, hacia
aproximadamente esto:
1. Cargaba `candidatos_sustitucion.csv`.
2. Por cada archivo, abria Word en segundo plano via COM
   (`New-Object -ComObject Word.Application`), volvia a verificar que
   hubiera **una sola** coincidencia del parrafo antiguo (revalidacion
   de maquetacion antes de tocar nada) y sustituia el texto.
3. Guardaba el resultado en `modificados\` (mismo nombre de archivo
   que en `descargas\`).
4. Reiniciaba la instancia de Word cada 40 archivos de forma preventiva
   (para evitar fugas de memoria/COM), y ante errores tipicos de COM
   (RPC no disponible, llamada rechazada, objeto desconectado — todos
   documentados en `sustitucion_completa.log`) cerraba y reabria Word
   y reintentaba una vez antes de marcar el archivo como error.
5. Llevaba su propio contador de resultados por archivo (algo
   equivalente a "REV_MAQUETACION_REVERIFICACION" para los que se
   sustituyeron bien tras la revalidacion, y "REV_ERROR_MOD" para los
   que fallaron incluso tras reintentar).

En la unica ejecucion registrada, de 484 candidatos se sustituyeron
correctamente 481 y 3 quedaron en error (ver el resumen final de
`sustitucion_completa.log`). Esos 3 casos con error, y cualquier fila
`REVISION MANUAL - ...` de `registro_control.csv`, se supone que se
revisaron a mano en Word directamente contra las plantillas de
`modelo con párrafo erróneo.docx` / `ciorrecto.docx` — no hay registro
automatizado de esa revision manual en este proyecto.

---

### Formato de los CSV/LOG generados (sin datos reales, solo estructura)

- `productos_ges.csv` -> columnas `id, nombre, href`
- `log_descargas.csv` -> columnas `id, tipo, resultado, nota`. `resultado` es `OK` o `ERROR`; `nota` trae `status=<codigo> bytes=<n>` o el texto de la excepcion cuando hay `ERROR`.
- `registro_control.csv` -> columnas `id, nombre, tipo, aseguradora, estado, nota`. `aseguradora` es una de `GES / HELVETIA / AMT / AMBIGUA`. `estado` es una de las etiquetas fijas del script (`YA ACTUALIZADO - GES`, `NO MODIFICADO - HELVETIA`, `NO MODIFICADO - AMT`, `REVISION MANUAL - ...` con varias variantes, `ERROR - ARCHIVO NO PROCESABLE`, o vacio si quedo como candidato de sustitucion).
- `candidatos_sustitucion.csv` -> columnas `id, nombre, tipo, archivo`.
- `registro_control_intento1_COM_parcial.csv` -> mismas columnas que `registro_control.csv`; es un volcado parcial y antiguo, no se usa para nada, se conserva solo como historico.
- `clasificacion_completa.log` / `descarga_completa.log` / `sustitucion_completa.log` -> texto plano con lineas de progreso ("... N/total procesados") y avisos de error puntuales; no contienen datos de cliente, solo ids de producto y mensajes de excepcion.

Ninguno de estos archivos debe salir de la organizacion tal cual: aunque
las columnas son "tecnicas", `productos_ges.csv` y `registro_control.csv`
contienen nombres reales de productos/pólizas de clientes.

---

### SOLUCION DE PROBLEMAS

**"Login fallido" al ejecutar cualquier script (01, 02 o 05)**
-> Revisa `INTRANET_USER` / `INTRANET_PASSWORD` en `proceso\.env`. Si
la contraseña de la cuenta de servicio "neurona" cambio en la
Intranet, hay que actualizarla aqui (y avisar de que tambien la usan
otros bots de esta carpeta compartida, como `siniestros_bot`).

**Playwright se queja de que falta el navegador (Chromium)**
-> Ejecuta `playwright install chromium` una vez en esa maquina.

**`05_descargar_todos.py` deja muchos `ERROR` en `log_descargas.csv`**
-> Mira la columna `nota`: si pone `status=...`, la Intranet respondio
pero no con un documento valido (por ejemplo un error 500 o una
redireccion a login por sesion caducada a mitad de la descarga); si es
un texto de excepcion, suele ser un timeout de red. Vuelve a lanzar el
mismo script: es reanudable y solo reintenta lo que no este `OK`.

**`06_clasificar.py` marca muchos documentos como `REVISION MANUAL`**
-> Es esperado si el lote incluye variantes de maquetacion o
redacciones distintas del parrafo que las constantes `OLD_RAW`/`NEW_RAW`
no cubren. No se debe ampliar esas constantes a ciegas: hay que abrir
el `.docx` en cuestion y comparar a mano contra
`modelo con párrafo erróneo.docx` / `ciorrecto.docx` antes de decidir
si es una variante valida a añadir al script.

**Hay que repetir la fase de sustitucion real (Word por COM) y no esta el script**
-> Ver la seccion "Lo que falta en este repositorio" mas arriba: hay
que reconstruirlo desde cero (Python con `pywin32` o PowerShell con
`New-Object -ComObject Word.Application`), reutilizando
`candidatos_sustitucion.csv` como entrada y guardando el resultado en
`modificados\`. No relances nada de eso sobre `descargas\` original sin
tener antes claro donde va a quedar la copia de seguridad de los
documentos sin tocar.

**Errores COM tipo "RPC no disponible" / "llamada rechazada" / "objeto desconectado" al automatizar Word**
-> Son errores conocidos de controlar Word por COM en lotes largos
(se ven documentados en `sustitucion_completa.log`). La solucion que
ya funciono fue cerrar y reabrir la instancia de Word tras el fallo,
reintentar una vez, y reciclar la instancia de Word de forma preventiva
cada 40 archivos aproximadamente para que no se degrade.

**El archivo `modelo con párrafo ciorrecto.docx` "no existe" al buscarlo por el nombre "correcto"**
-> El nombre del archivo tiene esa errata de origen ("ciorrecto"). No
lo renombres sin avisar a quien mantenga este LEEME y sin actualizar
esta referencia.
