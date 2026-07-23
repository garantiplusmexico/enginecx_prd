# Condensado — notas-inicial-gracia-anulacion-colombia

## Decisiones
- Habilitar gestión de **periodos de gracia** en Operaciones/Contratos (hoy no existe ahí; sí existe en averías: `averia_periodo_gracia`).
- Mostrar botón de **Cancelación/Anulación** de contratos en la vista de detalle del contrato (ya existe para México) para Colombia.
- Ambas capacidades restringidas al rol **Administrador General**.

## Alcance / requerimientos
- Botón de Cancelación visible solo si el contrato: (a) NO tiene factura activa agregada, (b) NO está en una orden de pago activa.
- Reutilizar patrón existente de México para el botón de cancelación.
- `fx_anulacion` se usa en reportes → considerar impacto.

## Actores
- Rol **Administrador General** (único autorizado para gracia y anulación).
- Área de **Operaciones** (beneficiaria; hoy depende de otras áreas).

## Riesgos / pendientes
- Definir **quién autoriza** periodos de gracia y anulaciones (riesgo de averías con contratos vencidos).
- Impacto en **facturación** e **integraciones**.
- `fx_anulacion` usado en reportes → validar que no se rompan.
- Periodo de gracia no existe hoy en Operaciones/contratos (sí en averías).

## Fechas / hitos
- (No especificadas)

## Importancia / impacto
- Importancia: **Alta**. Impacto: administración operativa, **autonomía** del área, reduce dependencia. Riesgo a controlar en contratos vencidos.
