# Condensado — Pagos.csv

Documento fuente: relación "ENGINE — Gestión y envío a pagos" (exportada a CSV desde
`Pagos.xlsx`). Define qué persona de Finanzas gestiona los pagos de cada empresa del grupo.

## Decisiones
- El portal enruta la notificación de "pago autorizado" al **analista de pagos a proveedores**
  que corresponde a la empresa que absorbe el gasto, según esta relación.
- La columna de **anticipos de viáticos y reembolsos** (Erik Mendoza Regalado para todas las
  empresas) se registra como contexto pero queda **fuera de alcance**: viáticos y reembolsos son
  otro desarrollo.
- **ISAMAD queda fuera del portal por ahora** (decisión de Aldo Álvarez, 2026-08-11): aparece en
  esta relación pero no tiene fila en la matriz de niveles de autorización, así que el portal no
  podría determinar quién autoriza sus gastos.
- **Go Virtual España no opera aún**: está en la matriz por previsión, sin gasto real ni analista
  asignado. El portal la soporta sin analista.

## Alcance / requerimientos
Mapeo empresa → analista de pagos a proveedores (MVP):

| Empresa | Analista |
|---|---|
| Engine CX | Suly |
| Celta Soluciones | Alejandra Cortés |
| Gplus Seguros | Alejandra Cortés |
| Go Virtual México | Claudia Vigueras |
| Go Virtual España | *(sin analista — no opera aún)* |
| TPA | Alejandra Cortés |
| Invarat | Alejandra Cortés |
| Garantiplus México | Ilse García |
| Garantiplus Colombia | Brian |
| Garantiplus Chile | Andrés Merino |

## Actores
- Analistas de pagos a proveedores: Suly, Alejandra Cortés, Claudia Vigueras, Ilse García, Brian,
  Andrés Merino. Una misma persona atiende varias empresas (Alejandra Cortés cubre cuatro).
- Erik Mendoza Regalado: anticipos de viáticos y reembolsos de todas las empresas (fuera de
  alcance).

## Riesgos / pendientes
- Faltan **nombre completo y correo** de "Suly" y de "Brian" para el alta de usuarios.
- La nomenclatura del CSV no coincide con la de la matriz ("GPMX Colombia" / "GPMX Chile" =
  Garantiplus Colombia / Chile; "Go Virtual" sin distinguir país). El catálogo de empresas del
  portal debe usar los nombres de la matriz como canónicos.
- Que una sola analista concentre varias empresas hace que su ausencia afecte a varios negocios;
  no hay suplente definido.

## Fechas / hitos
- Sin fechas en el documento.
