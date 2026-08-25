# Informe de averías del grupo Blendio - Garantía Global

> **Si eres nuevo y no sabes nada de esto, lee esto primero.**
> Esto NO es un bot que corre solo, no tiene tarea programada ni interfaz.
> Es un conjunto de 3 scripts de Python que alguien lanza a mano, cuando
> se pide el informe de averías del grupo Blendio (un cliente de Garantía
> Global con 19 concesionarios/razones sociales). Se ejecutan en orden,
> uno detrás de otro, y al final se obtiene un Excel.

Genera, a partir del export de averías de Garantía Global, un Excel con
el detalle de averías **rehusadas**, **indemnizadas** y **provisionadas**
(pendientes de liquidación) del grupo Blendio, agrupado por compraventa
(concesionario) y por año/mes, con KPIs generales en una portada.

No envía nada por correo ni toca la intranet salvo en modo lectura: el
resultado es un archivo `.xlsx` que hay que abrir y, si procede, reenviar
a mano a quien lo haya pedido.

---

### DÓNDE ESTÁN LAS CONTRASEÑAS

Este proyecto **no tiene su propio archivo de credenciales**: reutiliza
el de otro bot de esta misma organización. Todo vive en:

```
W.app averias\config.py
```

- `GG_EMAIL` / `GG_PASSWORD` -> login de **solo lectura** en
  `intranet.garantiaglobal.com`, usado por `enriquecer_fichas.py` para
  abrir la ficha web de cada avería. Son las mismas credenciales que usan
  `averias_bot` y `siniestros_bot`; si se cambia la contraseña de esa
  cuenta hay que actualizarla en todos esos sitios.
- `ANTHROPIC_API_KEY` -> clave de la API de Claude (Anthropic), usada por
  `extraer_ia.py` para identificar la pieza afectada y el motivo de
  rehuse a partir del texto libre de las Observaciones.

`enriquecer_fichas.py` y `extraer_ia.py` apuntan a ese archivo con un
`sys.path.insert(...)` al principio del script, usando una **ruta
absoluta con el nombre de usuario del PC donde se escribió originalmente
el código**. Si el código se copia a otro PC (o cambia el nombre de
usuario de Windows), esa ruta ya no existe y el script falla al arrancar
con `ModuleNotFoundError: No module named 'config'`. Hay que editar esa
línea (primeras ~10 líneas del archivo) y poner la ruta real de la
carpeta `W.app averias` en ESE PC. Ver "Solución de problemas" más abajo.

---

### ARCHIVOS DEL PROYECTO

| Archivo | Qué hace |
|---|---|
| `datos_blendio.py` | Módulo compartido, no se ejecuta solo. Contiene la lista de razones sociales del cliente (`COMPRAVENTAS_BLENDIO`), la lectura y deduplicado del Excel origen, el parseo de fechas/importes, y la función que fusiona los datos verificados (web/IA) con los del Excel. |
| `enriquecer_fichas.py` | Abre en modo **solo lectura** la ficha web de cada avería relevante en la intranet de Garantía Global y lee del formulario: Tipo de Rehuse, Causa de Rehuse, Descripción, tabla de Piezas e histórico de Observaciones. Guarda todo en `data\cache_fichas.json`. |
| `extraer_ia.py` | Para cada avería ya cacheada, envía a Claude el histórico de Observaciones + campos estructurados y le pide que identifique la **pieza real** afectada y, si está rehusada, el **motivo real** del rechazo. Añade `pieza_ia` / `motivo_rehuse_ia` a la misma `cache_fichas.json`. |
| `generar_informe_blendio.py` | Junta el Excel origen + `cache_fichas.json` y genera el informe final `.xlsx`. |
| `RESUMEN_Y_COMO_REPLICAR.txt` | Notas informales del desarrollo, incluyen el procedimiento para replicar este mismo informe con otro cliente. Complementa a este documento. |
| `data\` | Se genera sola. Contiene `cache_fichas.json` (caché de lo scrapeado/analizado), los logs y los informes `.xlsx` generados. |

No hay `config.py` propio ni `requirements.txt` propio en esta carpeta
(ver instalación más abajo).

**Carpeta hermana `proa_group_averias\`**: es la réplica de este mismo
informe pero para otro cliente ("Proa Ocasión, SL"). Si en el futuro hay
que generar este informe para un cliente distinto de Blendio, el
apartado 2 de `RESUMEN_Y_COMO_REPLICAR.txt` explica el procedimiento, y
`proa_group_averias\` es un ejemplo real ya hecho de cómo queda una
carpeta replicada (mismos 4 scripts, solo cambia la lista de
compraventas en `datos_blendio.py`).

---

### PASO 1 - Requisitos previos

Necesitas, en el mismo PC:
- La carpeta `averias_bot\` (hermana de esta), con un `data\averias.xlsx`
  **actualizado**. Ese Excel es el export en bloque de TODAS las averías
  de Garantía Global (no solo Blendio) y lo descarga `averias_bot` (ver
  su propio `LEEME.md`). Este proceso no lo descarga por sí mismo, solo
  lo lee.
- La carpeta `W.app averias\` (hermana de esta), con su `config.py`
  y las credenciales mencionadas arriba.

---

### PASO 2 - Instalar dependencias

Este proyecto no trae `requirements.txt` propio; instala a mano:

```
pip install openpyxl playwright anthropic
playwright install chromium
```

(`openpyxl` y `playwright` seguramente ya están instalados en el PC
porque los usan los otros bots de esta carpeta —`averias_bot`,
`siniestros_bot`, `W.app averias`—, pero `anthropic` es específico de
este proceso y de `W.app averias`).

---

### PASO 3 - Comprobar la ruta a `W.app averias`

Antes de ejecutar nada, abre `enriquecer_fichas.py` y `extraer_ia.py` y
revisa la línea:

```python
sys.path.insert(0, r"c:\Users\USUARIO.GLOBAL-61\OneDrive - GLOBARTIA\CLAUDE\W.app averias")
```

Si esa ruta no coincide con la ubicación real de `W.app averias` en el
PC donde vas a ejecutar (lo normal si es un PC distinto al que lo
escribió, o si cambió el nombre de usuario de Windows), cámbiala por la
ruta real, por ejemplo:

```python
sys.path.insert(0, r"C:\ruta\real\a\GGlobal\W.app averias")
```

`generar_informe_blendio.py` **no** necesita este ajuste: no usa IA ni
scraping, solo lee `datos_blendio.py` y la caché ya generada.

---

### PASO 4 - Ejecutar el proceso, en este orden

Desde una consola abierta en `blendio_averias\`:

```
python enriquecer_fichas.py
```
Recorre las averías relevantes (rehusadas, indemnizadas o con provisión
viva) y lee su ficha web una a una. Tarda entre 2 y 4 segundos por
avería. Se puede cortar (Ctrl+C) y relanzar sin perder lo ya hecho:
guarda progreso en `data\cache_fichas.json` cada 20 fichas. Para forzar
releer todo desde cero: `python enriquecer_fichas.py --forzar`. Para
probar con pocas: `python enriquecer_fichas.py --limite=5`.

```
python extraer_ia.py
```
Analiza con Claude las Observaciones ya cacheadas para completar Pieza y
Motivo de Rehuse. Requiere haber ejecutado antes `enriquecer_fichas.py`
(si una avería no tiene "observaciones" en caché, se avisa y se salta).
Tarda 1-2 segundos por avería. Mismas opciones `--forzar` / `--limite=N`.

```
python generar_informe_blendio.py
```
Genera el Excel final en
`data\informe_blendio_averias_<fecha>_<hora>.xlsx`. Admite dos
argumentos opcionales: ruta de origen del Excel de averías (si no es la
por defecto) y ruta de destino del informe, por ejemplo:
```
python generar_informe_blendio.py "C:\otra\ruta\averias.xlsx" "C:\salida\informe.xlsx"
```

---

### PASO 5 - Revisar el resultado

Abre el Excel generado y comprueba:
- **Portada**: número total de averías de Blendio, cuadra con lo
  esperado, y el aviso (si aparece) de cuántas averías aún no se han
  verificado contra la ficha web.
- **Notas y criterios**: qué se ha asumido para construir el informe
  (deduplicado, prioridad de fuentes, definiciones de rehusada /
  indemnizada / provisionada), útil para poder auditar cualquier cifra.

---

### PARA VOLVER A GENERARLO MÁS ADELANTE (mismo cliente)

Basta con repetir el PASO 4 completo (los 3 scripts, en orden). Las
averías ya cacheadas y sin cambios (mismo sello de "Fecha de última
actualización") no se vuelven a leer en la web ni a analizar con IA;
solo se procesan las averías nuevas o modificadas desde la última vez.
Si el Excel origen (`averias_bot\data\averias.xlsx`) no se ha
actualizado desde la última ejecución, el informe saldrá igual pero sin
novedades.

---

### FLUJO COMPLETO (de un vistazo)

1. `averias_bot` descarga `averias.xlsx` con TODAS las averías de
   Garantía Global (no es responsabilidad de este proyecto).
2. `datos_blendio.py` lee ese Excel, se queda con la fila más reciente
   de cada Id. (una avería puede aparecer varias veces, una fila por
   cambio de estado) y filtra solo las filas cuya "Compraventa" coincide
   (sin tildes/mayúsculas) con alguna de las 19 razones sociales de
   `COMPRAVENTAS_BLENDIO`.
3. `enriquecer_fichas.py` abre la ficha web de cada avería relevante
   (rehusada / indemnizada / con provisión viva) y guarda en
   `data\cache_fichas.json` lo que lee directamente del formulario:
   Tipo/Causa de Rehuse, Descripción, tabla de Piezas e histórico de
   Observaciones. Necesario porque el export en bloque no siempre trae
   esos campos bien rellenos.
4. `extraer_ia.py` le pasa a Claude el histórico de Observaciones de
   cada avería (más los campos estructurados) para que identifique la
   pieza real afectada y, si está rehusada, el motivo real del rechazo
   en una frase breve. Necesario porque los desplegables de la ficha
   muchas veces son genéricos ("Otros", "N/A") aunque el motivo sí esté
   descrito en las notas de los gestores. Guarda `pieza_ia` /
   `motivo_rehuse_ia` en la misma caché.
5. `generar_informe_blendio.py` junta el Excel origen con la caché y
   escribe el `.xlsx` final, usando esta prioridad para Causa y Pieza de
   cada avería: **IA > Web (ficha) > Excel (export en bloque)**, la
   fuente final queda indicada en la columna "Fuente" de cada detalle.
   El informe tiene las hojas: Portada, Notas y criterios, Total
   averías, y Resumen+Detalle de Rehusadas / Indemnizadas /
   Provisionadas.

---

### SOLUCIÓN DE PROBLEMAS

**`ModuleNotFoundError: No module named 'config'` al lanzar
`enriquecer_fichas.py` o `extraer_ia.py`**
-> La ruta absoluta del `sys.path.insert(...)` al principio del script
apunta a un PC/usuario distinto al actual. Edita esa línea con la ruta
real de `W.app averias` en este PC (ver PASO 3).

**"Login fallido en Garantia Global. Revisa config.py de 'W.app
averias'."**
-> Revisa `GG_EMAIL` / `GG_PASSWORD` en `W.app averias\config.py`. Son
las mismas credenciales que usan `averias_bot` / `siniestros_bot`; si
alguien cambió la contraseña de esa cuenta en la intranet sin avisar,
hay que actualizarla ahí.

**`ValueError: Faltan columnas en el export de averias: [...]`**
-> Garantía Global ha cambiado el nombre de alguna columna del export
"Por Excel (piezas)". `datos_blendio.py` (lista `COLUMNAS_REQUERIDAS`,
al principio del archivo) indica exactamente cuál falta; hay que
localizar el nuevo nombre en el Excel y actualizarlo ahí.

**`extraer_ia.py` avisa de "averías sin datos de ficha en caché"**
-> Significa que para esas averías no se ejecutó (o falló)
`enriquecer_fichas.py` antes. Vuelve a lanzar `enriquecer_fichas.py`
primero; se puede seguir usando `extraer_ia.py` mientras tanto, solo se
salta esas averías concretas.

**El informe sale con muchas filas marcadas como "Fuente: Excel" (en
vez de "IA"/"Web")**
-> Es normal si no se ha ejecutado `enriquecer_fichas.py` +
`extraer_ia.py` recientemente, o si esas averías dieron error al leer
la ficha. Revisa `data\enriquecer_log.txt` / `data\extraer_ia_log.txt`
(si existen de una ejecución con salida redirigida a archivo) o la
salida por consola de la última ejecución para ver errores puntuales, y
relanza esos dos scripts.

**`enriquecer_fichas.py` se corta a mitad (timeout, corte de red, etc.)**
-> No pasa nada: guarda progreso en `data\cache_fichas.json` cada 20
fichas. Simplemente vuelve a lanzar `python enriquecer_fichas.py`, solo
procesará lo que falte.

**El Excel final no incluye averías que sé que existen del cliente**
-> Revisa que la razón social exacta de esa compraventa esté en la
lista `COMPRAVENTAS_BLENDIO` de `datos_blendio.py` (la comparación
ignora tildes/mayúsculas pero no nombres distintos: p.ej. "Blendio
Oviedo" no es lo mismo que "Blendio Oviedo SLU" si en el Excel origen
aparece con la razón social completa distinta). También comprueba que
`averias_bot\data\averias.xlsx` esté actualizado.

**Quiero generar este mismo informe para otro cliente**
-> No se toca esta carpeta: se duplica entera a una carpeta nueva y se
cambia solo la lista `COMPRAVENTAS_BLENDIO` de `datos_blendio.py` por
las razones sociales del nuevo cliente. El procedimiento paso a paso
está en `RESUMEN_Y_COMO_REPLICAR.txt` (apartado 2), y
`proa_group_averias\` es un ejemplo real ya hecho siguiendo ese mismo
procedimiento.
