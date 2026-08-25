# Informe de averías Proa Group - Garantía Global

> **Si eres nuevo y no sabes nada de esto, lee esto primero.**
> Esto NO es un bot que corre solo ni tiene tarea programada: son 3
> scripts de Python que se lanzan a mano, a demanda, cuando alguien pide
> el informe de averías del cliente "Proa Ocasión, SL". No hay
> interfaz ni conversación; cada script imprime su progreso por
> consola y el resultado final es un Excel en `data\`.

Esta carpeta es una **réplica** de `blendio_averias\` (mismo código,
mismo proceso), adaptada para un cliente distinto. Si en el futuro hay
que montar esto para un tercer cliente, la forma más rápida es partir
de esta carpeta o de `blendio_averias\` y seguir el apartado
["Cómo replicar para otro cliente"](#cómo-replicar-esto-para-otro-cliente)
más abajo — ahí también se explican los bugs que hubo que corregir la
última vez.

---

## Qué hace

A partir del export de averías de Garantía Global (el mismo Excel en
bloque que descarga `averias_bot`, que contiene TODAS las averías de
TODOS los clientes), este proceso:

1. Filtra solo las filas cuya columna "Compraventa" sea una razón
   social del grupo Proa Group (hoy solo hay una: "Proa Ocasión, SL").
2. Deduplica por "Id." de avería (cada avería aparece varias veces en
   el export, una fila por cambio de estado; se queda con la más
   reciente).
3. Para las averías relevantes (rehusadas, indemnizadas o con
   provisión viva) visita la ficha web real de cada una en la intranet
   y lee ahí los campos que en el export en bloque suelen venir vacíos
   o incompletos (Causa de Rehuse, Tipo de Rehuse, Piezas,
   Observaciones).
4. Le pasa el histórico de Observaciones de cada ficha a Claude (IA)
   para que identifique la pieza real afectada y, si la avería está
   rehusada, el motivo real del rechazo — porque muchas veces el
   desplegable de la ficha es genérico ("Otros", "N/A") pero el motivo
   real sí está descrito en las notas de los gestores.
5. Genera un Excel (`data\informe_proa_group_averias_<fecha>_<hora>.xlsx`)
   con: Portada (KPIs), Notas y criterios, Total de averías,
   y Rehusadas / Indemnizadas / Provisionadas (Resumen + Detalle),
   indicando en cada fila si el dato de Causa/Pieza viene de la IA, de
   la ficha web o del Excel en bloque (columna "Fuente").

No escribe nada en Garantia Global ni envía ningún correo: es
solo-lectura y el resultado es el propio archivo Excel.

---

## Dónde están las contraseñas

Este proyecto **no tiene su propio archivo de credenciales**: reutiliza
el de otro bot. Todo vive en:

```
GGlobal\W.app averias\config.py
```

- `GG_URL`, `GG_EMAIL`, `GG_PASSWORD` -> login de **solo lectura** en
  `intranet.garantiaglobal.com`, usado por `enriquecer_fichas.py`. Son
  las mismas credenciales que usan `averias_bot` y `siniestros_bot`; si
  se cambia la contraseña de esa cuenta hay que actualizarla en los
  cuatro sitios.
- `ANTHROPIC_API_KEY` -> clave de la API de Claude (Anthropic), usada
  por `extraer_ia.py` para identificar pieza y motivo de rehuse a
  partir de las Observaciones.

`enriquecer_fichas.py` y `extraer_ia.py` apuntan a ese archivo con un
`sys.path.insert(...)` al principio del script, con la ruta absoluta
de la carpeta `W.app averias` **codificada tal cual**. Si algún día se
mueve, renombra o se ejecuta desde otro PC/usuario, hay que actualizar
esa ruta en los dos scripts (ver "Solución de problemas" más abajo:
esto ya causó un bug al replicar este proyecto).

No hay `.env` ni gestor de secretos: no copies el contenido de
`config.py` fuera de estos bots, ni lo subas a ningún sitio compartido
fuera de la organización.

---

## Archivos del proyecto

- `datos_blendio.py` — Módulo compartido (nombre heredado de la
  réplica original de Blendio; no se ha renombrado, ver más abajo).
  Contiene la lista de razones sociales a filtrar
  (`COMPRAVENTAS_BLENDIO`), la lectura y deduplicado del Excel origen,
  el parseo de fechas/importes y la función que combina los datos
  verificados (IA/web) con los del Excel.
- `enriquecer_fichas.py` — Visita la ficha web de cada avería
  relevante y guarda lo leído en `data\cache_fichas.json`.
- `extraer_ia.py` — Analiza con Claude las Observaciones ya cacheadas
  y añade `pieza_ia` / `motivo_rehuse_ia` a la misma caché.
- `generar_informe_blendio.py` — Junta Excel origen + caché y genera
  el informe final (`data\informe_proa_group_averias_<fecha>_<hora>.xlsx`).
  El nombre del archivo lo hereda de Blendio pero genera el informe de
  Proa Group; no afecta a nada, es solo el nombre del script.
- `data\` — Se crea sola al ejecutar. Contiene `cache_fichas.json`
  (caché de fichas web + resultados de IA, por Id. de avería) y los
  informes `.xlsx` generados. **Contiene datos de expedientes de
  clientes: no la compartas fuera de la organización.**

No hay `requirements.txt` propio en esta carpeta (se apoya en los
paquetes ya instalados para los otros bots de `GGlobal\`).

---

## Instalación / puesta en marcha

### Paso 1 — Dependencias
```
pip install openpyxl playwright anthropic
playwright install chromium
```
(`openpyxl` y `playwright` seguramente ya están instalados en el PC
porque los usan `averias_bot`, `siniestros_bot` y `W.app averias`).

### Paso 2 — Comprobar que existe el Excel origen
Este proceso NO descarga el export por sí mismo: lee el mismo archivo
que descarga `averias_bot`:
```
GGlobal\averias_bot\data\averias.xlsx
```
Si ese archivo no existe o está desactualizado, hay que generarlo antes
(ver el LEEME de `averias_bot`, o ejecutar su `descargar_informe.py`).
Este proyecto no avisa si el Excel es antiguo: se fía de la fecha que
tenga ese archivo.

### Paso 3 — Ejecutar los 3 pasos, en este orden
Desde esta carpeta (`proa_group_averias\`):

```
python enriquecer_fichas.py
python extraer_ia.py
python generar_informe_blendio.py
```

- `enriquecer_fichas.py` tarda unos segundos por avería relevante
  (abre un navegador Chromium headless y visita cada ficha). Se puede
  cortar a medias (Ctrl+C) y volver a lanzar sin perder lo ya hecho:
  guarda progreso en `data\cache_fichas.json` cada 20 fichas.
  - `python enriquecer_fichas.py --forzar` ignora la caché y relee
    todas las fichas relevantes.
  - `python enriquecer_fichas.py --limite=5` prueba solo con 5 (útil
    para verificar que el login y el scraping funcionan antes de
    lanzar todo).
- `extraer_ia.py` necesita que ya se haya ejecutado `enriquecer_fichas.py`
  (usa la clave `"observaciones"` de la caché). Acepta los mismos
  `--forzar` y `--limite=N`.
- `generar_informe_blendio.py` no necesita argumentos; genera el Excel
  en `data\`. Si se le pasan argumentos, son
  `[ruta_origen] [ruta_destino]` — por ejemplo, para usar otro Excel de
  origen o forzar un nombre de archivo de salida concreto.

El resultado queda en:
```
data\informe_proa_group_averias_<AAAAMMDD>_<HHMM>.xlsx
```

### Volver a generarlo más adelante
Basta con repetir el Paso 3 completo. Las averías ya cacheadas y sin
cambios (mismo sello de "Fecha de última actualización") no se vuelven
a leer de la web ni a analizar con IA; solo se procesan las nuevas o
las que hayan cambiado desde la última vez.

---

## Cómo leer el Excel generado

- **Portada**: KPIs generales (nº total de averías, rehusadas,
  indemnizadas, provisionadas y sus importes) y ranking de averías por
  compraventa.
- **Notas y criterios**: explica en texto plano qué se ha asumido
  (deduplicado, prioridad IA > Web > Excel, definiciones de
  "rehusada"/"indemnizada"/"provisionada", etc.). Es la primera
  pestaña a mirar si un número no cuadra con lo esperado.
- **Total averías**: matriz Compraventa x Año/Mes.
- **Rehusadas / Indemnizadas / Provisionadas — Resumen**: mismas
  matrices pero con importes y coste medio.
- **Rehusadas / Indemnizadas / Provisionadas — Detalle**: una fila por
  avería, con columna **Fuente** ("IA" / "Web" / "Excel") que indica
  de dónde sale el dato de Causa/Pieza de esa fila concreta. Si pone
  "Excel", esa avería no se ha podido verificar contra la ficha web
  (falta en caché o no se ejecutó `enriquecer_fichas.py` para ella) y
  el dato puede venir incompleto.

---

## Diferencias respecto a `blendio_averias\` (para replicar a un tercer cliente)

Este proyecto es una copia funcional de `blendio_averias\`. Lo único
que cambia entre clientes es:

1. **La lista `COMPRAVENTAS_BLENDIO` en `datos_blendio.py`** (línea
   ~20): en Blendio tiene 19 razones sociales, aquí solo una
   ("Proa Ocasión, SL"). El nombre de la variable y de las funciones
   se ha dejado igual (con "blendio" en el nombre) aunque el cliente
   sea otro; no afecta al funcionamiento, es solo deuda de naming.
2. **El título del informe** ("INFORME DE AVERÍAS — PROA GROUP" en
   `escribir_portada`, dentro de `generar_informe_blendio.py`) y el
   patrón de nombre del archivo de salida
   (`informe_proa_group_averias_...` en vez de
   `informe_blendio_averias_...`).
3. **Nada más debería cambiar** en la lógica de negocio: deduplicado,
   parseo de fechas/importes, prioridad IA/Web/Excel y estructura del
   Excel son idénticos a Blendio.

Al replicar esta carpeta desde `blendio_averias\` se corrigieron
además **dos bugs que NO son específicos del cliente** (son bugs del
código heredado, conviene llevarlos también si se replica desde
`blendio_averias\` en vez de desde esta carpeta):

- **Ruta absoluta rota a `W.app averias`**: en `blendio_averias\`,
  `enriquecer_fichas.py` y `extraer_ia.py` tienen
  `sys.path.insert(0, r"...\USUARIO.GLOBAL-61\...\W.app averias")`,
  una ruta de un usuario/PC que ya no es el actual. En esta carpeta se
  corrigió a la ruta real de este PC
  (`c:\Users\Hp\OneDrive - GLOBARTIA\- CLAUDE\W.app averias`). Es la
  causa más probable de un `ModuleNotFoundError: No module named
  'config'` si esto se mueve a otro PC o usuario sin actualizar la
  ruta.
- **Bug de "ThinkingBlock" en `extraer_ia.py`**: `blendio_averias\`
  lee la respuesta de Claude con `resp.content[0].text`, asumiendo que
  el primer bloque de la respuesta es siempre texto. Si el modelo
  devuelve primero un bloque de razonamiento (`ThinkingBlock`, sin
  atributo `.text`), esa línea rompe con un `AttributeError`. Aquí se
  corrigió buscando explícitamente el primer bloque de tipo `"text"`:
  ```python
  bloque_texto = next((b for b in resp.content if b.type == "text"), None)
  texto = bloque_texto.text.strip() if bloque_texto else ""
  ```
  Si se replica desde `blendio_averias\` en vez de desde aquí, hay que
  aplicar este mismo cambio en su `extraer_ia.py`.

---

## Cómo replicar esto para otro cliente

1. Duplicar esta carpeta completa a `xxx_averias\` (sin la carpeta
   `data\` ni `__pycache__`; se regeneran solos).
2. En `datos_blendio.py`, sustituir el contenido de
   `COMPRAVENTAS_BLENDIO` por las razones sociales exactas del nuevo
   cliente, tal como aparecen en la columna "Compraventa" del export
   (`averias_bot\data\averias.xlsx`). Para listarlas todas y buscar
   las del cliente nuevo:
   ```
   python -c "import openpyxl; wb=openpyxl.load_workbook(r'..\averias_bot\data\averias.xlsx', read_only=True, data_only=True); ws=wb.worksheets[0]; filas=ws.iter_rows(values_only=True); headers=list(next(filas)); idx=headers.index('Compraventa'); vals=sorted(set(str(r[idx]).strip() for r in filas if r[idx])); [print(v) for v in vals]"
   ```
   No hace falta que coincidan en mayúsculas/tildes (el filtro
   normaliza), pero sí el nombre en sí.
3. En `generar_informe_blendio.py`, cambiar el título de la portada
   ("INFORME DE AVERÍAS — PROA GROUP" en `escribir_portada`) y, si se
   quiere, el patrón de nombre del archivo de salida al final de
   `generar_informe`.
4. Confirmar que `sys.path.insert(...)` en `enriquecer_fichas.py` y
   `extraer_ia.py` apunta a la ruta real de `W.app averias` en el PC
   donde se va a ejecutar.
5. Ejecutar en orden: `enriquecer_fichas.py` -> `extraer_ia.py` ->
   `generar_informe_blendio.py`.
6. Revisar la pestaña "Portada" del Excel generado para comprobar que
   el volumen de averías es el esperado para ese cliente.

Por qué en carpeta aparte y no reutilizando esta: la caché
(`data\cache_fichas.json`) y los informes generados quedan ligados a la
lista de compraventas con la que se generaron. Si se reutiliza la
misma carpeta cambiando la lista, hay que borrar antes `data\` entero
para no mezclar cachés de dos clientes distintos.

---

## Solución de problemas

**`ModuleNotFoundError: No module named 'config'`**
-> La ruta de `sys.path.insert(...)` al principio de
   `enriquecer_fichas.py` / `extraer_ia.py` no apunta a la carpeta real
   de `W.app averias` en este PC (ver el bug de ruta rota más arriba).
   Corrígela para que apunte a
   `...\GGlobal\W.app averias` en este PC/usuario.

**"Login fallido en Garantia Global. Revisa config.py de 'W.app averias'."**
-> Revisa `GG_EMAIL` / `GG_PASSWORD` en `GGlobal\W.app averias\config.py`.
   Son las credenciales de solo lectura de `neurona@garantiaglobal.com`.

**`AttributeError` dentro de `preguntar_ia` en `extraer_ia.py`**
-> Si alguna vez se toca ese código y vuelve a leer
   `resp.content[0].text` a pelo en lugar de buscar el bloque de tipo
   `"text"`, puede romper cuando Claude devuelva primero un bloque de
   razonamiento. Ver el apartado de bugs corregidos más arriba.

**Error de la API de Anthropic (401 / autenticación)**
-> Revisa `ANTHROPIC_API_KEY` en `GGlobal\W.app averias\config.py`; si
   ha caducado o se ha rotado, hay que generarla de nuevo en la
   consola de Anthropic y actualizarla ahí (afecta también a los demás
   scripts que la reutilicen).

**"Faltan columnas en el export de averias: [...]"**
-> Garantía Global ha cambiado el nombre de alguna columna del export.
   `datos_blendio.py` (lista `COLUMNAS_REQUERIDAS`) indica cuál falta;
   hay que localizar el nuevo nombre en el Excel y actualizarlo ahí.

**El informe sale con muchas filas "Fuente = Excel" / aviso de averías sin verificar**
-> Significa que `enriquecer_fichas.py` no se ha ejecutado (o no se ha
   ejecutado con la caché al día) para esas averías. Vuelve a lanzar
   `enriquecer_fichas.py` antes de generar el informe.

**El scraping de fichas es muy lento o falla a mitad**
-> `enriquecer_fichas.py` guarda progreso cada 20 fichas en
   `data\cache_fichas.json`; se puede cortar (Ctrl+C) y relanzar sin
   perder lo ya hecho, sigue por donde se quedó.

**No hay logs propios**
-> Estos 3 scripts no escriben archivo de log: todo el progreso sale
   por consola (`print`). Si quieres conservarlo, redirige tú mismo la
   salida al lanzarlos, por ejemplo:
   ```
   python enriquecer_fichas.py > data\enriquecer_log.txt
   ```

---

## Limitaciones a tener en cuenta

- Depende de que `averias_bot\data\averias.xlsx` esté actualizado; este
  proceso no lo descarga ni comprueba su antigüedad.
- Necesita las credenciales de Garantía Global y la `ANTHROPIC_API_KEY`
  de `W.app averias\config.py` (se reutilizan tal cual, no son propias
  de este proyecto).
- Si el volumen de averías relevantes crece mucho, los pasos de
  scraping (`enriquecer_fichas.py`) y de IA (`extraer_ia.py`) tardarán
  proporcionalmente más (varios segundos por avería en cada paso).
- No hay ninguna automatización (tarea programada, envío de correo):
  el informe hay que generarlo y distribuirlo a mano.
