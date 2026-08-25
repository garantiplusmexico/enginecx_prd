# Condensado — gg-informe-averias-por-tecnico

Informe recurrente que responde a "¿por dónde empiezo hoy?". En nuestra versión esto **no debe
ser un informe**, debe ser una vista y un sistema de alertas.

## Alcance / requerimientos
- Dos veces al día en días laborables, cada técnico recibe la lista de **sus averías vivas**.
- Se excluyen las cerradas y las pendientes de liquidación: solo lo que está vivo.
- Orden obligatorio: **de la más antigua a la más reciente**. La primera línea es por donde hay
  que empezar. Es la regla de negocio del informe.
- Columnas: identificador, estado, vehículo, fecha de última actualización, **días sin
  actualizar** y una marca de "gestionada" que el técnico va rellenando.
- Semáforo visual: color por estado y escala de color por antigüedad (rojo = más antigua).
- Una pestaña por técnico, más una de "sin asignar" que va siempre al final.
- Comparativa contra el corte anterior: cuántas averías vivas tiene cada técnico ahora frente a
  la última vez, incluida en el propio envío.

## Actores
- Técnicos/tramitadores (destinatarios). Personal en copia para supervisión.

## Riesgos / pendientes
- Una avería aparece varias veces en el origen (una fila por cambio de estado); hay que quedarse
  con la última actualización de cada una. En nuestro caso esto lo resuelve la API.
- Depende de que exista una lista de técnicos mantenida a mano.
