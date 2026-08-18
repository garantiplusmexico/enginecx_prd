# Resultado de la Fase 0 — prueba de comprobante a público en general

**Fecha:** 17-ago-2026 · **Ejecutó:** Carlos Castellanos (TI GarantiPlus)
**Entorno:** local, contra el validador de pruebas de EDICOM (`Test=true`), sobre contratos del
proyecto BMW (206). No se emitió ningún comprobante fiscal real.

---

## Cambio de plan respecto a la v0.1 del PRD

La v0.1 planteaba hacer la prueba **directo en producción**, sobre uno de los contratos de la cartera
Allianz. Se cambió a **local** porque el validador de pruebas aplica las mismas reglas estructurales
del SAT, el costo es cero y no se emite un comprobante fiscalmente válido e irreversible. Eso también
eliminó el riesgo que la v0.1 registraba ("la prueba de Fase 0 emite un comprobante real").

Antes de eso hubo una confusión que vale la pena dejar anotada: en el módulo de Órdenes de Pago de
SIGA existe una casilla **"GENERAR FACTURA GLOBAL (UNA SOLA FACTURA)"**, y se pensó que ya resolvía
el caso. **No lo hace.** En esa pantalla "factura global" significa *una sola factura para varios
contratos* (consolidada), que es un concepto distinto del comprobante global de la autoridad. Además,
la ruta consolidada arma el receptor con los datos del distribuidor —que en BMW están en genérico—,
así que tampoco servía por esa vía.

## Las tres pruebas

| # | Escenario | Contrato | Resultado |
|---|---|---|---|
| A | Identificador fiscal genérico + **nombre real del cliente** + régimen sin obligaciones + código postal del emisor | 812807 | ✅ **Se emitió.** Identificador fiscal `54C48FE1-7E57-11F1-9C8F-E9D9EF7C59C1` |
| B | Nombre "PUBLICO EN GENERAL", **sin declarar el periodo** | 812808 | ❌ **Rechazado.** Código CFDI40130, textual: *"…el nodo Información Global debe existir"* |
| C | Nombre "PUBLICO EN GENERAL", **declarando el periodo** (diario, mes 08, año 2026) | 812808 | ✅ **Se emitió.** Identificador fiscal `4972640E-7E57-11F1-AE66-572F34A9636E` |

Entre B y C **no se cambió ningún dato**: la única diferencia fue la declaración del periodo, de modo
que el resultado aísla su efecto sin ambigüedad.

Que la autoridad aceptara el comprobante de C también demuestra que la declaración del periodo quedó
en la posición correcta dentro del comprobante: si hubiera estado mal ubicada, el rechazo habría sido
por sello inválido y no se habría emitido nada.

## Hallazgos no previstos

1. **El escenario A es lo que el portal ya hace hoy**, sin que nadie lo haya decidido: cuando el
   cliente no captura sus datos fiscales, el comprobante sale con identificador fiscal genérico y el
   nombre real del cliente. La autoridad lo acepta, pero es incongruente. No estaba documentado.
2. **Falso negativo que produce comprobantes duplicados.** La generación del archivo PDF falla
   *después* de que el comprobante ya está emitido y registrado como válido, y ese fallo se
   propagaba como fallo del timbrado. Con el segundo intento automático activo, el sistema
   reintentaría sobre un contrato ya facturado y emitiría un **duplicado**. Corregido: el PDF es un
   artefacto posterior y no interrumpe ni invalida la emisión.
3. **Los errores del validador se perdían dos veces**: por un lado el servicio de facturación no
   comprobaba la ausencia del sello y fallaba con un error genérico; por otro, el borde de
   comunicación devolvía siempre una respuesta vacía, así que un rechazo se reportaba como éxito.
   Corregido. Esta prueba fue **la primera vez que el motivo del rechazo llegó al sistema que lo
   pidió** en lugar de quedar sólo en la bitácora del servidor.
4. **Los intentos rechazados dejan registros incompletos** que se acumulan. Se confirmó en vivo: el
   escenario B dejó su registro sin sello. No impiden reintentar, pero crecen.

## Decisión

Se adopta el **escenario C** (declarar el periodo), que es el fiscalmente correcto. El escenario A
queda como respaldo documentado.

## Consecuencia de negocio que hay que atender

Los **~1,016 contratos de la cartera Allianz** en producción están exactamente en el estado del
escenario C. Con este desarrollo desplegado, **se pueden facturar**. La decisión sobre esa cartera se
había cerrado descartando el comprobante global "por imposible", y esa premisa ya no es cierta:
conviene reabrirla con negocio y contabilidad.

Queda pendiente que contabilidad avale un comprobante global que ampara **una sola** operación:
estructuralmente pasa, pero la figura está pensada para agregar las operaciones de un periodo.

## Entregable técnico

Rama `feature/PJ4793-cfdi-publico-en-general` en el repositorio de SIGA, commit `8d25819`:
5 archivos, 227 líneas agregadas. Pendiente de revisión y despliegue.
