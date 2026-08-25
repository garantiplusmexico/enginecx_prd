# Condensado — gg-informe-planificacion

Informe de gestión del área de averías. Define el conjunto de indicadores que el equipo
necesita ver; en nuestra versión son vistas y tarjetas del panel, no un archivo adjunto.

## Alcance / requerimientos
Indicadores que se producen hoy, cada día laborable:
- Resumen ejecutivo del área.
- **Entradas diarias** y **averías rezagadas**.
- Indemnizaciones y provisiones.
- **Coste medio** por comercial, por producto y por cliente.
- Segmentación de **tiempos de cierre**.
- **Análisis por técnico**.
- Tiempos de cierre avanzados: triángulo de desarrollo, antigüedad del trabajo en curso, cierres
  por antigüedad.
- Pendientes de liquidación y casos cerrados que aún conservan provisión.
- Resumen diario en el propio aviso: **cerradas frente a nuevas entradas** de ayer y del día
  anterior, con su tendencia, y el **técnico "foco"**: el que más averías activas acumula sin
  actualizar por encima de 7, 14 y 30 días.

## Riesgos / pendientes
- Si el cálculo del resumen falla, el envío sale igual sin ese bloque y solo se registra el
  error: un indicador puede desaparecer sin que nadie lo note.
- Los nombres de columna del origen están fijados: cualquier cambio en el origen rompe el
  informe.
