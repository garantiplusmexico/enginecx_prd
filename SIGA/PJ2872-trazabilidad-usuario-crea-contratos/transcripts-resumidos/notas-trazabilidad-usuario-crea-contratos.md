# Condensado — notas-trazabilidad-usuario-crea-contratos

## Decisiones
- Registrar/exponer el **usuario creador** de cada garantía (contrato) en reportes e informes.
- Agregar columna **'Usuario creador'** en los reportes de **Producción** y **Explotación**.

## Alcance / requerimientos
- Extender los **SPs/queries** donde falte poblar/exponer `registra_contrato`.
- Aprovechar que `usuario_creador` **ya existe** y ya se usa para **filtrar** reportes.
- Referencia existente: el **export Excel de Chile** ya incluye la columna 'Usuario registra'.

## Actores
- **Solicita:** Operaciones / Colombia.
- **Revisión técnica:** Alexis Salvador Herrera Garcia (alexis.herrera@gplusseguros.mx).
- Consumidores: auditoría / control interno (lectores de reportes).

## Riesgos / pendientes
- Confirmar en qué reportes/SPs falta el dato (`registra_contrato`) y cuáles ya lo tienen.
- Consistencia entre países (México / Colombia / Chile) sobre nombre y presencia de la columna.
- Datos históricos: garantías creadas antes del cambio podrían no tener `usuario_creador`.

## Fechas / hitos
- No especificadas. Importancia **Media**; impacto en trazabilidad/auditoría, sin efecto en captación.
