# Condensado — gg-informe-flotas-por-comercial

Informe de productividad comercial construido a partir del registro de lo que hizo otra
automatización. Interesa el **criterio de conteo**, que es una regla de negocio reutilizable.

## Alcance / requerimientos
- Cada día laborable, cuántas gestiones pidió cada comercial el día anterior, por tipo de
  gestión.
- Solo cuentan los tipos de gestión reales; se ignora lo que el sistema no reconoció.
- **Una misma solicitud puede aparecer varias veces el mismo día** (reintentos, pendientes,
  recordatorios, resultado final): se agrupan como **una sola solicitud**. Se atribuye al
  primero que la registró y se muestra el resultado de la última entrada relevante.
- Solo entran al detalle las solicitudes de las personas del ámbito; el resto se excluye pero
  **se cuenta y se declara** ("se han excluido N gestiones que no correspondían"), para poder
  cuadrar el total.
- Un comercial sin actividad aparece con cero: es un dato válido, no un fallo.
- Dos vistas: resumen (matriz persona × tipo con totales) y detalle (una fila por solicitud).

## Riesgos / pendientes
- Si no hay actividad, no existe registro del día: hay que distinguir "sin actividad" de "fallo
  del proceso". Hoy se asume lo primero.
