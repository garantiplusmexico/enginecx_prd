# Condensado — Transcript_levantamiento_incentivos

Sesión de levantamiento (00:39:01). Participantes: Aldo Álvarez (Engine / Go Virtual) y
Laura Hernández Azpeitia (Autocom — distribuidor Hyundai). Objetivo: entender el proceso
manual de control y recuperación de incentivos (bonos) de la marca.

## Decisiones
- Se atacan **dos** problemas, pero **en orden**: primero **incentivos**, después **comisiones/nómina**.
  Aldo: "empezaría por el de incentivos y me muevo a comisiones". Laura: "Empecemos por ahí".
- Se establece como **regla operativa única y correcta**: cuando hay más de un incentivo en una
  operación, **cada incentivo va en su propia línea en Kitter** (no se suman en un solo renglón).
  Laura: "en vez de sumar el incentivo... sería hacer otra línea con la diferencia del segundo
  incentivo… y si lo establecemos como regla, entonces yo te voy a dar a ti todos los boletines
  que salgan en ese periodo".
- La oferta comercial (boletín de la marca) se **carga a la herramienta** al inicio de cada mes y
  también cuando llegan boletines intermedios; se procesa con IA (incluso desde imagen) para
  convertirla en una base contrastable. Aldo: "eso sí lo puedo hacer sin ningún problema".
- Se plantean **dos alternativas de fuente de datos de ventas**:
  - Alt. 1 — export manual de Kitter a Excel que el usuario sube a la herramienta (más manual).
  - Alt. 2 — acceso directo al **data warehouse** donde vive la información de Kitter, vía TI/BI
    de Autocom (más automático). Aldo queda de validarlo con Juan y con TI de Autocom.
- Aldo se lleva el levantamiento para generar el documento y hacer pruebas; regresa con Laura
  con las alternativas evaluadas.

## Alcance / requerimientos
- **Problema raíz:** el distribuidor es el **último de toda la red en cobro de incentivos**, por
  nulo control administrativo en ventas. El proceso de la marca no es complejo; lo complejo es
  llevar el control y hacer la revisión en cada cierre de mes.
- **Oferta comercial de la marca (Hyundai):** define el **bono flexible** por modelo/versión, el
  % y monto que aporta la **marca** y el % que aporta el **dealer**. El bono se puede aplicar de
  tres formas: (1) contado → descuento directo al precio; (2) crédito → parte del enganche;
  (3) crédito → reducción de tasa.
- **Anexo del boletín con dos listas de importes**: "bono aplicado a reducción de precio" y
  "bono NO aplicado a reducción de precio"; los importes varían entre ambas.
- **Captura en Kitter:** al grabar la venta se coloca un **código distinto según contado o crédito**,
  se indica **a dónde se aplica el bono**, se cambia la cuenta y se captura el **importe sin IVA que
  se va a recuperar de la marca**. Ejemplo validado: Creta GLS Premium, precio de lista 519,900,
  bono 65,000 (65% marca / 35% dealer), operación a crédito Banorte, "bono aplicado a reducción de
  precio" → aportación de la marca con IVA ~42,000 y **sin IVA 36,422**, que es el importe que se
  graba en Kitter.
- **Nota de crédito:** siempre se emite por el importe del bono **con IVA**. La emite el contador
  (Guillermo). Está asociada a un BIN.
- **Control actual:** un Google Drive/hoja que alimenta Eli (gerente operativo de ventas) con
  factura, referencia, fecha de factura, total de factura, año modelo, cliente, vendedor, modelo,
  serie, tipo de operación, tipo de venta, precio de lista, bono, a qué se aplica, % de aportación
  de cada parte, fecha de facturación en dealer portal; el contador marca "tiene rebate" y
  "nota emitida". Al ser alimentado por humanos, es susceptible de errores.
- **Herramienta solicitada (MVP incentivos)**:
  1. Extraer/ingerir el reporte de ventas de Kitter con el desglose del incentivo registrado.
  2. Ingerir con IA la oferta comercial del mes (y boletines intermedios) como base de datos.
  3. **Validar que el incentivo registrado exista en la oferta comercial** para ese modelo/versión y
     forma de aplicación. Ejemplo: si la Creta debía traer 36,422 y trae 25,235, y ese importe no
     aparece en ningún lugar del boletín, la herramienta levanta la alerta —independientemente de
     si está por arriba o por abajo.
  4. **Cruzar notas de crédito contra incentivos por BIN**: si existe nota de crédito de un BIN sin
     incentivo registrado, alertar (para evitar utilidades negativas).
  5. Plataforma que **dispare alertas** de lo que no cuadra, en vez de revisión manual mes a mes.
- **Riesgo de falsos positivos (analizado en la junta):** si se permite sumar incentivos en una
  sola línea, habría que probar todas las combinaciones posibles y podría "palomear" como válida
  una suma de incentivos que **no son compatibles entre sí** (ej. bono de Grand i10 + bono de Creta
  en la misma unidad). Por eso se acuerda la regla de una línea por incentivo.
- **Tipos de incentivos concurrentes identificados:** oferta comercial base; incentivo adicional
  del mismo boletín; boletín de actualización a mitad de mes (caso Tucson: bono sube de 75,000 a
  100,000, aportación marca 75,000 / dealer 25,000); **flotilla**; **descuento comunidad coreana
  (5%)** — es independiente y aplica exista o no oferta comercial en la unidad; **semana híbrida**
  (mensual: cero comisión por apertura, seguro gratis o monto adicional de bono).
- Laura confirma: los incentivos **siempre se pueden sumar entre sí** cuando aplican a la misma
  unidad, porque todos son dinero a recuperar; el problema es solo de captura y de validación.

## Actores
- **Laura Hernández Azpeitia** — solicitante; responsable del control de incentivos y hoy también
  del cálculo de comisiones en Autocom.
- **Eli** — gerente operativo de ventas; alimenta hoy el archivo de control de ventas/incentivos.
- **Guillermo** — contador; emite las notas de crédito y marca "tiene rebate / nota emitida".
- **Contabilidad** — hace el recuento de todos los rebates/recuperaciones; contra su detalle se
  quiere comparar el resultado de la herramienta.
- **Asesores de ventas** — afectados: sus comisiones se calculan sobre la utilidad, que se
  distorsiona cuando el incentivo o la nota de crédito no se registran bien.
- **Compensaciones (Rodrigo)** — equipo que armó la "sábana" de comisiones.
- **Igatsi** — persona del grupo con años de experiencia; Laura lo recomienda explícitamente como
  contraparte de Engine ("sabe perfecto, está involucrado, entiende cuál es la necesidad").
- **Juan** — contraparte de Engine con quien Aldo validará el camino técnico.
- **TI / BI de Autocom** — dueños del data warehouse donde vive la información de Kitter.
- **Aldo Álvarez** — Engine / Go Virtual, responsable del desarrollo.

## Riesgos / pendientes
- **Dependencia de TI/BI de Autocom** para el acceso al data warehouse de Kitter. Sin ese acceso,
  el camino automático no arranca.
- **Kitter calcula mal la utilidad**: no está restando las notas de crédito, por lo que infla la
  utilidad. Ejemplo dado: un Grand i10 manual con utilidad real ~20,000 (17,000 con bono) aparece
  con ~40,000+ porque se suma el incentivo sin restar la nota de crédito. Como las comisiones se
  calculan sobre esa utilidad, se pagan mal. Es un problema **del propio Kitter**, en revisión.
- Cuando el incentivo no se graba y solo se hace la nota de crédito, la utilidad ("beneficios" en
  Kitter) **sale negativa** → no se recupera, no se sabe cuánto se dio, y las comisiones salen mal.
- Captura humana en el Drive de control → errores.
- **Comisiones (segundo proyecto, mucho más complejo):** esquema con variables casi infinitas
  (rangos por volumen, share de financiamiento, tomas —subasta vs. compra para reventa—, seguros,
  accesorios, garantías, venta perfecta); información dispersa (no todo está en Kitter, hay parte
  manual); hojas de cálculo duplicadas con conceptos repetidos (fecha factura = fecha cierre,
  IDB = número de vehículo); macro de recibos de nómina ilegibles al imprimir y que no consideran
  ventas de meses anteriores; pagos en destiempo y desalineados entre unidades y financiamientos.
  Un gerente de ventas invierte ~día y medio analizando la operación para calcular comisiones.
  Requeriría además: plantilla de vendedores activa/actualizada, captura manual de conceptos que
  no viven en Kitter, y asociación de esos conceptos a BINs y vendedores.
- Pendiente definir si el proyecto se hace con apoyo de TI de Autocom o de forma autónoma por Engine.

## Fechas / hitos
- Sin fechas comprometidas en la sesión. Aldo queda de: generar el documento de levantamiento,
  hacer pruebas, tocar base con Juan y con Autocom (TI) para definir la vía de acceso a datos, y
  agendar un siguiente espacio con Laura.
