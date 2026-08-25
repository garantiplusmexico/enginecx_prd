# Condensado — gg-informe-cliente-blendio

Informe de siniestralidad **por cliente/grupo**, generado a demanda. Aporta dos ideas fuertes:
la jerarquía de fuentes de un dato y el uso de IA para recuperar información que los campos
estructurados no tienen.

## Decisiones
- **Prioridad de la fuente de cada dato: IA > ficha del expediente > listado masivo.** Cada fila
  del informe declara de dónde salió el dato en una columna "Fuente".
- Se recurre a la IA porque los desplegables del expediente suelen venir genéricos ("Otros",
  "N/A") aunque el motivo real sí esté escrito en las notas de los gestores.

## Alcance / requerimientos
- Filtrar las averías de las razones sociales que componen un grupo/cliente (comparación
  tolerante a mayúsculas y acentos, pero no a nombres distintos).
- Quedarse con el estado más reciente de cada avería.
- Para las averías relevantes (rehusadas, indemnizadas o con provisión viva), leer del
  expediente: tipo y causa de rehúse, descripción, piezas y el histórico de observaciones.
- Pedir a la IA que identifique, a partir del histórico de observaciones, **la pieza realmente
  afectada** y, si está rehusada, **el motivo real del rechazo** en una frase.
- Salidas del informe: portada con indicadores (totales e importes de rehusadas, indemnizadas y
  provisionadas, más ranking por concesionario), una hoja de **notas y criterios** que explica
  en texto llano qué se asumió para construir cada cifra, matriz cliente × año/mes, y
  resumen + detalle por cada categoría.
- Aviso explícito en portada de **cuántas averías no se pudieron verificar** contra el
  expediente.
- Reejecutable: lo ya analizado y sin cambios no se vuelve a procesar.

## Riesgos / pendientes
- El informe se genera y se distribuye a mano; no hay automatización ni destinatarios definidos.
- Es una réplica por cliente: montar otro cliente implica duplicar el proceso.
