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

| Empresa | Analista | Correo |
|---|---|---|
| Engine CX | Úrsula García | ursula.garcia@garantiplus.mx |
| Celta Soluciones | Alejandra Cortés | janette.cortes@enginecx.com |
| Gplus Seguros | Alejandra Cortés | janette.cortes@enginecx.com |
| Go Virtual México | Claudia Vigueras | claudia.vigueras@govirtual.com.mx |
| Go Virtual España | *(sin analista — no opera aún)* | — |
| TPA | Alejandra Cortés | janette.cortes@enginecx.com |
| Invarat | Alejandra Cortés | janette.cortes@enginecx.com |
| Garantiplus México | Ilse García | administracion@garantiplus.mx |
| Garantiplus Colombia | Brian | contabilidad@garantiplus.co |
| Garantiplus Chile | Andrés Merino | andres.merino@garantiplus.cl |

## Actores
- Analistas de pagos a proveedores: Suly, Alejandra Cortés, Claudia Vigueras, Ilse García, Brian,
  Andrés Merino. Una misma persona atiende varias empresas (Alejandra Cortés cubre cuatro).
- Erik Mendoza Regalado: anticipos de viáticos y reembolsos de todas las empresas (fuera de
  alcance).

## Riesgos / pendientes
- "Suly" quedó identificada como **Úrsula García**; **Brian** sigue sin apellido registrado.
- Garantiplus México, Garantiplus Colombia y Engine CX apuntan a **buzones genéricos**
  (`administracion@`, `contabilidad@`) en lugar de cuentas personales. Sirven para recibir la
  notificación, pero un buzón compartido no identifica a una persona bajo SSO.
- Esta relación cubre a los **analistas de Finanzas**, no a los **Funcionales** (primer nivel de
  autorización por área). Ese mapeo sigue pendiente y es requisito para el alta de usuarios.
- La nomenclatura del CSV no coincide con la de la matriz ("GPMX Colombia" / "GPMX Chile" =
  Garantiplus Colombia / Chile; "Go Virtual" sin distinguir país). El catálogo de empresas del
  portal debe usar los nombres de la matriz como canónicos.
- Que una sola analista concentre varias empresas hace que su ausencia afecte a varios negocios;
  no hay suplente definido.

## Fechas / hitos
- Sin fechas en el documento.
