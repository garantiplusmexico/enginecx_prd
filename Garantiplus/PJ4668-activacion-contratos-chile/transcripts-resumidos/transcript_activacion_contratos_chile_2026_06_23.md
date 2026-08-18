# Condensado — Reunión "Activación de contratos Chile" (2026-06-23)

**Asistentes:** Aldo Álvarez · Andrés Merino Sotomayor · David Simancas Estrada · Gustavo Iván Carreto Abascal
**Duración:** 24 min

## Decisiones

- **Regularizar por etapas, no todo de golpe.** Héctor quiere activar desde 2022; el despacho contable entregó desde 2024. Se acordó **activar 2024 → hoy primero** (resuelve la mayor parte del problema) y luego pedir hacia atrás.
- **El filtro de averías de David no se implementa como bloqueo, sino como tablero.** El filtro de aprobación ya existe (una avería sobre contrato no activo escala a aprobación; hoy la da David tras redirección de Isra). Aldo propuso lo contrario: **dejar pasar las averías** e identificarlas en un tablero cliente por cliente, para que los vendedores gestionen el cobro. Se puede pilotear en Chile y luego escalar a México.
- **Andrés comparte dos insumos, no uno:** (a) el histórico de facturas por año (PDF **y** XML — se confirmó que se necesitan ambos para inyectar), y (b) su relación contrato↔factura ya existente. Se cruzan entre sí para detectar diferencias.
- **La política de cartera arranca simple:** todo a 30 días; lo que pase de 30 días cuenta como vencido. Refinar después con políticas por cliente (30/45/60, como en México) si se justifica.
- **El proceso mensual queda definido:** el despacho deposita cada mes las facturas emitidas en un espacio compartido → se valida → se carga → se activa. Una vez por mes.

## Alcance / requerimientos

- **Cadena de activación en SIGA (4 pasos, en orden):** contrato registrado → factura emitida y cargada → orden de pago generada y asociada → proceso de activación con fecha de pago confirmada. Chile ya cumple el paso 1.
- **Cuello de botella confirmado:** la orden de pago debe corresponder **1:1** con la factura para cargarse automáticamente, pero se genera a mano contrato por contrato en un buscador de SIGA. Con 600–800 ventas/mes por país es inviable.
- **Work-around vigente:** el RPA de Omar carga órdenes de pago **una por una**; como las facturas agrupan múltiples contratos, TI **inyecta las facturas directamente en la base de datos** para saltarse la validación 1:1.
- **Volumen de la regularización histórica:** ~60 mil y tantos contratos desde 2022. El RPA corriendo de noche tomaría **~15 días**.
- **Solo se generan órdenes de pago para contratos con factura emitida.** Sin factura emitida no tiene sentido generar la orden.
- **Métodos de facturación en Chile:** consolidada a fin de mes (**85–90%** del total) y manual bajo pedido de ciertos clientes (agrupar contratos de varios meses en una factura). La pasarela de pago existe en otros países pero **no aplica en Chile** por un tema normativo: si Garantiplus recauda directamente, empieza a operar como aseguradora.
- Se pidió a Andrés crear la carpeta compartida de Drive con acceso para él, Iván y Aldo.

## Actores

- **Aldo Álvarez** — coordina el área; diseñó el work-around completo.
- **Andrés Merino Sotomayor** — Chile; gestiona al despacho contable, dueño de la carpeta de Drive, tiene la relación contrato↔factura y el control de pagos.
- **David Simancas Estrada** — aprueba hoy las averías sobre contratos no activos; solicitante del filtro.
- **Gustavo Iván Carreto Abascal** — datos/automatización; construye el motor.
- **Omar** — opera el RPA de órdenes de pago.
- **TI** — inyecta las facturas en base de datos.
- **Vendedores** — gestionarán el cobro con el distribuidor a partir del tablero.
- Mencionados: Héctor (quiere desde 2022), Fabricio / Juliana / Israel (country managers), Benjamín, Ana (hizo una activación masiva histórica).

## Riesgos / pendientes

- **Ya existen contratos activos en el histórico.** Ana hizo una activación masiva hasta ~mediados de 2023, y puede que algunos de 2024. El motor debe contemplar que no todo el histórico está sin activar.
- **El documento de orden de pago en Chile es una plantilla de México y no aplica.** Requiere ajuste propio.
- **No existe consecutivo de SIGA en Chile.** En Colombia el número de factura coincide en dígitos con el folio de SIGA pero no en las letras; en Chile ese consecutivo directamente no existe. Relevante para el supuesto de correspondencia folio ↔ `FACTURA N°`.
- **El control de pagos de Andrés está por número de factura, no por contrato**, y referenciado a la transacción. Sirve para v2 porque el motor ya tendrá la relación contrato↔factura, pero obliga a derivar la fecha de pago factura → contrato.
- **Desfase entre facturación y activación:** las facturas chilenas tienen crédito a 30 días, así que un contrato facturado el 30 de enero se paga el 28 de febrero o el 1 de marzo, y hasta entonces no se activa. Pero **el pico de siniestralidad en Chile ocurre en el primer mes** — justo la ventana en que el contrato aún no está activo.
- El despacho entregó hasta marzo/abril; Andrés puede conseguir el actualizado.
- La idea original era **extraer los contratos de las facturas con IA**. El PRD posterior descubrió que el XML no contiene los números de contrato, lo que invalida ese enfoque y deja al Excel como única fuente de verdad.

## Fechas / hitos

- **2026-06-23** — reunión de origen.
- **~15 días** de corridas nocturnas del RPA para la regularización histórica.
- **Crédito a 30 días** en las facturas chilenas: define el desfase entre facturación y activación.
- **Prioridad 1:** 2024 → hoy. **Prioridad 2:** hacia atrás hasta 2022.
