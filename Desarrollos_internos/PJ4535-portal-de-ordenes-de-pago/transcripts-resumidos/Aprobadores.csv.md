# Condensado — Aprobadores.csv

Documento fuente: catálogo de autorizadores del Portal de Órdenes de Pago, llenado por Aldo
Álvarez el 2026-08-11 sobre la plantilla generada en esta sesión. Es el **catálogo inicial de
usuarios con facultad de autorizar**.

## Decisiones
- El **Funcional NO es el jefe del área que solicita**: es el aprobador del **equipo contable**
  de cada empresa. Las áreas operativas (TI, Marketing, Ventas, Operaciones) son **clientes** del
  proceso — solicitan, no autorizan. Aclaración expresa de Aldo Álvarez (2026-08-11) que corrige
  la lectura inicial de la política.
- **Los solicitantes no se cargan por adelantado**: cualquier cuenta válida de Google Workspace
  del grupo queda dada de alta como solicitante en su primer ingreso. Solo autorizadores,
  analistas y administradores requieren alta explícita.
- **Héctor Izquierdo opera con una sola cuenta de Google** (`haizquierdo@enginecx.com`) y dos
  investiduras: CEO y Consejo. El portal le pide confirmar con cuál resuelve cuando el monto
  corresponde al nivel Consejo.
- **Go Virtual España sí opera** con normalidad y se incorpora al MVP como cualquier otra empresa.
- Ilse García (Garantiplus México) y Brian (Garantiplus Colombia) deben autorizar con **cuenta
  personal**, no con los buzones compartidos `administracion@` y `contabilidad@` que traía el
  archivo.

## Alcance / requerimientos
Nivel **Funcional** — equipo contable de cada empresa:

| Empresa | Área | Persona | Correo registrado |
|---|---|---|---|
| Garantiplus México | Contabilidad | Ilse García | administracion@garantiplus.mx *(pendiente cuenta personal)* |
| Garantiplus Colombia | Contabilidad | Brian | contabilidad@garantiplus.co *(pendiente cuenta personal)* |
| Garantiplus Chile | Operaciones | Andrés Merino | andres.merino@garantiplus.cl |
| Go Virtual México | Contabilidad | Claudia Vigueras | claudia.vigueras@govirtual.com.mx |
| Go Virtual España | Contabilidad | Claudia Vigueras | claudia.vigueras@govirtual.com.mx |
| Invarat | Contabilidad | Alejandra Cortés | janette.cortes@enginecx.com |
| Gplus Seguros | Contabilidad | Alejandra Cortés | janette.cortes@enginecx.com |
| TPA | Contabilidad | Alejandra Cortés | janette.cortes@enginecx.com |
| Celta Soluciones | Contabilidad | Alejandra Cortés | janette.cortes@enginecx.com |
| Engine CX | Contabilidad | Úrsula García | ursula.garcia@garantiplus.mx |

Nivel **Country Manager** — un titular por empresa (no aplica en Celta Soluciones ni Engine CX):

| Empresa | Persona | Correo |
|---|---|---|
| Garantiplus México | Israel Escutia | israel.escutia@garantiplus.mx |
| Garantiplus Colombia | Luz Godoy | luz.godoy@garantiplus.co |
| Garantiplus Chile | Fabrizio Álvarez | fabrizio.alvarez@garantiplus.cl |
| Go Virtual México | Juan Berner | juan.berner@enginecx.com |
| Go Virtual España | Roberto Herranz | roberto.herranz@govirtual.es |
| Invarat | Israel Escutia | israel.escutia@garantiplus.mx |
| Gplus Seguros | Israel Escutia | israel.escutia@garantiplus.mx |
| TPA | Israel Escutia | israel.escutia@garantiplus.mx |

Niveles **transversales** a todo el grupo:

| Nivel | Persona | Correo |
|---|---|---|
| CFO | Octavio Zetina Lara | octavio.zetina@enginecx.com |
| CEO | Héctor Izquierdo | haizquierdo@enginecx.com |
| Consejo | Héctor Izquierdo | haizquierdo@enginecx.com *(misma cuenta, investidura distinta)* |

## Actores
- 6 personas cubren el nivel Funcional de las 10 empresas; Alejandra Cortés concentra cuatro.
- 5 personas cubren el nivel Country Manager de 8 empresas; Israel Escutia concentra cuatro.
- Héctor Izquierdo cubre CEO y Consejo; Octavio Zetina Lara cubre CFO en todo el grupo.

## Riesgos / pendientes
- **Concentración de funciones**: las personas del nivel Funcional son las mismas que gestionan
  los pagos a proveedores (Ilse García, Claudia Vigueras, Alejandra Cortés, Úrsula García).
  Autorizan en el primer nivel y después solicitan el pago del mismo gasto.
- **Concentración por persona**: la ausencia de Alejandra Cortés deja sin Funcional a cuatro
  empresas, y la de Israel Escutia sin Country Manager a otras cuatro. Mitigado parcialmente por
  la autorización jerárquica y por RF-28.
- Falta el **apellido de Brian** y las **cuentas personales** de Ilse García y Brian.
- El archivo no incluye solicitantes, por decisión: se autoprovisionan al primer ingreso.

## Fechas / hitos
- Sin fechas en el documento.
