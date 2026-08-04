## **Activacion de contratos Chile**

# **Asistentes**

Aldo Álvarez, Andrés Merino Sotomayor, David Simancas Estrada, Gustavo Ivan Carreto Abascal

# **Transcripción**

Aldo Álvarez: que mostrarles paso a paso.

Aldo Álvarez: Ah, en Colombia todo partian de que tenemos una vista de ventas que trae el detalle de las facturas, ¿no?

Aldo Álvarez: En Colombia hay una vista particularmente que es la versión

Aldo Álvarez: 5\.

Aldo Álvarez: Y es como cualquier otra zona de venta.

Aldo Álvarez: trae el registro del contrato, fecha de compra, fecha de cancelación, fecha de inicio, pero trae dos variables que las otras dos eh vistas no tienen, que una es la factura que ya está cargado dentro de SIGA y la orden

Aldo Álvarez: de pago que ya está generada dentro de SIG.

Aldo Álvarez: Ajá.

Gustavo Ivan Carreto Abascal: Ok.

Aldo Álvarez: Para que un contrato se active, tienes que tener, o sea, el contrato enregistrado, la factura cargada, la orden de pago generada y asociada y tienes que correr un proceso de activación.

Aldo Álvarez: O sea, tú tienes que decir, "Ya está el registro, ya le cargué su factura, ya le cargué su orden de pago y ahora, dado que ya tengo factura y orden de pago, necesito que a este contrato con esta fecha de pago me lo active siga,

Aldo Álvarez: ¿no?

Aldo Álvarez: Y entonces hay que descomponer ese proceso en varios pasos porque hoy el paso número uno del registro no hay problema, Chile ya registra y tiene sus contratos, ¿no?

Aldo Álvarez: Chile de inicio no tenía la necesidad de activación porque en Chile, a diferencia de Colombia y México, en México y en Colombia hay obligación sobre el contrato hasta que el contrato está pagado.

Aldo Álvarez: Entonces acá si legalmente te puedes defender si por ejemplo Iván compra una garantía con un distribuidor y quiere tener el que hacer uso de su avería y viene Iván conmigo y me dice, "Oye, mi avería yo sí le puedo decir,

Aldo Álvarez: oye, tu distribuidor no ha pagado.

Aldo Álvarez: Entonces, tengo que hablar con el distribuidor y necesito que me pague y una vez que me pague, entonces ya te pago tu avería." Yo siempre he insistido que ese proceso de cara al

Aldo Álvarez: cliente final es desastroso.

Aldo Álvarez: O sea, porque imagínate, o sea, que como, o sea, que como cliente final te digan que compraste una garantía, pero como el que al que tú se la pagaste no la pagó, o sea, no no va a ser efectiva,

Aldo Álvarez: pero tú ya la pagaste, pues tiene un impacto mediático importante, pero es lo que es, o sea, sí funciona hoy, no significa que esté correcto o no.

Aldo Álvarez: No me estoy brincando pasos porque les quiero mostrar la sábana y les quiero ver les quiero mostrar cómo se ve y aprovecho para hacer conciliación y todo lo demás.

Aldo Álvarez: Pero el punto es que en Chile eso no sucede.

Aldo Álvarez: En Chile legalmente desde que el cliente adquiere su garantía, hay una responsabilidad por nuestra parte de hacer valle de esa garantía, independientemente de si me pagaron la garantía o no.

Aldo Álvarez: Y de hecho de ahí viene el proceso que está pidiendo David, que es que no se paguen garantías sobre contratos que no están activos, porque en teoría es un tema de respaldo legal, pero en Chile ese respaldo legal no existe.

Aldo Álvarez: Entonces solamente van a meter ese filtro para que cuando un contrato no esté pagado porque no está, o sea, no esté pagado y no está activo, pues sea el vendedor quien vaya a buscar al distribuidor para pedir ese pago,

Aldo Álvarez: independientemente de que yo tengo que hacer efectiva la bella.

Aldo Álvarez: ¿Me explico?

Aldo Álvarez: Entonces, lo que va a terminar pasando es que se va a generar un filtro para que en Chile en particular se puedan pagar averías, aunque no esté el contrato en activo, pero se va a registrar qué contrato es el que no está en activo para llevar la cuenta de los que necesito ir a conseguir

Aldo Álvarez: que me pagas.

Aldo Álvarez: Eso es lo que va a cambiar.

Aldo Álvarez: Ahora, dado que el contrato ya se registró, para cargar la factura, primero necesitamos emitir la factura.

Aldo Álvarez: Ajá.

Aldo Álvarez: Dado que la factura ya David ya estás ya para me brinqué el contexto, entonces ya para ti esto va a ser meramente informativo, ¿eh?

Aldo Álvarez: Pero cualquier cosa me dices.

Aldo Álvarez: Al final te digo cuál es el resumen de esto.

David Simancas Estrada: Gracias.

David Simancas Estrada: Okay.

Aldo Álvarez: Eh, entonces para cargar la factura, primero necesito emitir la factura.

Aldo Álvarez: En Chile apenas estamos tratando de cerrar un proveedor de facturación electrónica automática, de tal manera que en cuanto el DMS emita el contrato, esa información viaje por API al facturador y el facturador genere las facturas.

### 00:05:00

Aldo Álvarez: Hoy eso no sucede así en Chile.

Aldo Álvarez: Hoy en Chile se genera el contrato.

Aldo Álvarez: Hay que pedirle al despacho que genere la factura y ellos generan las facturas.

Aldo Álvarez: ¿Cierto, Andrés?

Andrés Merino Sotomayor: Así es.

Andrés Merino Sotomayor: Y es una factura consolidada a final de mes, no es por

Aldo Álvarez: Y ahí hay ahí, por ejemplo, algunas variaciones contra el resto de los países,

Andrés Merino Sotomayor: contrato.

Aldo Álvarez: porque por ejemplo en el resto de los países hay tres, cuatro tipos de facturación.

Aldo Álvarez: O sea, estás de pasarela de pago, que es cuando pagas a través un servicio tipo Open Pay y entonces en cuanto pagas ese contrato emite su factura individual para ese

Andrés Merino Sotomayor: Ahí tengo una duda,

Aldo Álvarez: contrato.

Andrés Merino Sotomayor: ese contrato es vendido también a través de un canal V2 V2C, pero nosotros le prestamos la plataforma de pago a nuestros partner, a nuestro distribuidor.

Aldo Álvarez: Ajá.

Andrés Merino Sotomayor: Ah, ya, perfecto.

Andrés Merino Sotomayor: Que acá en Chile hemos pensado hacerlo, pero hay un tema normativo de que si los que recaudamos somos nosotros, eh, ya empieza a ser una aseguradora.

Andrés Merino Sotomayor: Pero voy a darle una vuelta porque nos han pedido algunos distribuidores,

Aldo Álvarez: Okay.

Andrés Merino Sotomayor: algo así.

Aldo Álvarez: Bueno, pues podemos ir a profundidad, pero bueno, es ese método de pago existe en otros países.

Andrés Merino Sotomayor: Perfecto.

Aldo Álvarez: Existe también el de facturación manual, que es clientes que por algún motivo quieren juntar facturas del mes anterior con este y que todos esos contratos estén una sola factura.

Aldo Álvarez: Entonces dicen, "Oye, necesito que estos contratos en particular me los metes en esta factura." Me mandan ese detalle,

Aldo Álvarez: yo lo facturo manual y se emite una factura para esos contratos y se da por situaciones muy particulares de ciertos clientes, no es una norma.

Aldo Álvarez: Y la que es más común es la que menciona Andrés, que es cierra el mes.

Aldo Álvarez: Yo veo que contratos emitiste durante el mes, los agrupo en una sola factura y emito la factura.

Aldo Álvarez: El 85 90% de la facturación está en ese método de facturación.

Aldo Álvarez: Entonces, la mayor parte de las facturas en el caso de Chile quiero pensar que se emiten al final del mes, porque se hace el corte, se meten los contratos, se emite la factura y así, ¿no?

Aldo Álvarez: Ahora, aquí empiezan los problemas porque por default para que un contrato se pueda cargar y perdónenme, ahorita ya ya se hizo el export,

Aldo Álvarez: ahorita les muestro aquí cómo se ve que por no era la 5, era la tres.

Aldo Álvarez: ¿Ven?

Aldo Álvarez: Por eso no hay que tener versiones diferentes de la vista.

Aldo Álvarez: Ya uno no sabe cuál es.

Aldo Álvarez: Eh, pero el punto es cuando ya se emite la factura para cargar la factura dentro del SIGA en un proceso automático, la factura tendría que tener correspondencia uno a uno con la orden de pago.

Aldo Álvarez: Lo que significa que si me emitiste una factura por 100 contratos, tendrías que tener una una orden de pago emitida para esos 100 contratos y tiene que coincidir uno a uno, si no no carga.

Aldo Álvarez: Entonces, y te preguntarás, sobre todo tú, Ivan, ¿cuál es el problema de hacer es que hoy emitiera una orden de pago es manual?

Aldo Álvarez: Si tú quieres agregar los 100 contratos, tienes que entrar a SIGA, generar orden de pago y buscar en un buscador a mano, contrato por contrato, ir seleccionando y cuando llegues a los 100 se genera la orden de pago.

Aldo Álvarez: Y ese proceso para 600 800 ventas que tenemos al mes por país en una persona, en un espacio de 3 cu días cuando tienes más cosas que hacer, no hay manera, ¿no?

Gustavo Ivan Carreto Abascal: M.

Aldo Álvarez: Entonces, parte de lo que estamos evaluando en los 55 requerimientos que tenemos de mejor hacia

Gustavo Ivan Carreto Abascal: M.

Aldo Álvarez: es uno de esos es, o sea, es poder cargar de manera masiva, oye, todos estos contratos, métemelos en esta orden de pago, subes el pinche Excel, lo haces con API o como sea, queda y resuelto.

Aldo Álvarez: Mientras eso no sucede, entonces necesitamos est así es.

Aldo Álvarez: Eh, entonces necesitamos que el equipo de de ti escriba las facturas directamente en la base de datos y para que podamos escribir la factura tiene que haber una orden de pago independientemente de si coincide o no.

Aldo Álvarez: Entonces, y se preguntarán, ¿quién pensó en esto?

Aldo Álvarez: Claramente nadie pensó en esto.

Aldo Álvarez: Se les hizo muy fácil decir, ah, pues con que coincidan a uno, pero necesito que coincida, pero necesita cargar este esto primero para poder cargar.

### 00:10:00

Aldo Álvarez: Nadie lo pensó.

Aldo Álvarez: Entonces, vamos a hacer mejoras dentro del sistema eh, para poder incorporarlo.

Aldo Álvarez: Y entonces ahí es donde entra un proceso que ejecuta Omar.

Aldo Álvarez: Omar tiene un RPA que literalmente es un bot que mueve tu mouse y entra a Siga y mueve, o sea, va y selecciona, quiero generar orden de pago, mete este contrato, va, lo busca, lo copia, lo pega, lo agrega y carga la orden de pago.

Aldo Álvarez: Pero ese RPA lo que hace es cargar individualmente una orden de pago por contrato.

Aldo Álvarez: Entonces, si yo quisiera cargar la factura de manera natural, o sea, a través de la plataforma y cargar la factura, te va a decir que no, porque la factura tiene múltiples contratos y la orden de pago se hace de manera individual y por eso es que el

Aldo Álvarez: equipo de TI tiene que tomar la factura y básicamente inyectarla en la base de datos y brincarse ese proceso.

Aldo Álvarez: Yo sé, yo sé, jóvenes, yo sé lo que están pensando y yo coordino esta área.

Aldo Álvarez: Entonces, imagínense, ustedes lo están pensando, yo lo tengo que resolver.

Aldo Álvarez: Entonces, tantita paciencia.

Aldo Álvarez: Todo lo que estamos haciendo ahorita es un work around, que de hecho se me ocurrió a mí para poder resolver esto en lo que arregla el sistema.

Aldo Álvarez: Entonces, lo que vamos a hacer es correr un RPA que va a cargar orden de pago para todos los contratos históricos de Chile y lo va a cargar uno por uno,

Aldo Álvarez: pero solamente lo vamos a hacer para aquellos contratos que tengan factura emitida, porque si no se emitió esa factura, ¿para qué genera orden de pagos?

Aldo Álvarez: ese contrato en real debería yo de cargar y entonces necesito el histórico de las facturas para poder eh identificar esos contratos.

Aldo Álvarez: Y ahí fue donde le pedí a Andrés que me ayudara con el despacho contable a traer el histórico de 2024, 2025, 2026, que hasta donde yo me quedé ya nos lo compartieron, ¿cierto?

Andrés Merino Sotomayor: Sí, quedamos hasta abril, si no me equivoco, o marzo, pero puedo conseguir el actualizado.

Aldo Álvarez: Entonces ahora justo más bien vamos a separar esta conversación en dos.

Aldo Álvarez: Andrés, el primer punto que necesito que me ayudes a hacer es generar una carpeta compartida a la que tenga acceso Iván, tenga acceso yo y me cargues todo el histórico de las facturas por año, porque ahora yo necesito revisar esas facturas con inteligencia artificial y extraer los

Aldo Álvarez: contratos.

Andrés Merino Sotomayor: con el documento.

Andrés Merino Sotomayor: Entiendo.

Andrés Merino Sotomayor: Entonces,

Aldo Álvarez: Ajá.

Aldo Álvarez: Bueno, esa es la idea.

Aldo Álvarez: Si tú tienes un consolidado que diga,

Andrés Merino Sotomayor: perfecto.

Aldo Álvarez: "Mira, estos contratos tienen factura, aquí está la relación, pues mándame la relación y es más fácil." Pero yo no sé si

Andrés Merino Sotomayor: Tengo tengo esa relación, tengo porque claro, hay facturas que agrupan muchos contratos,

Aldo Álvarez: existe.

Andrés Merino Sotomayor: entonces tengo cada número de contratos qué número de factura asignado tiene, dónde se facturó, pero igual podemos hacer un cruce para calcular los montos,

Aldo Álvarez: Perfecto.

Andrés Merino Sotomayor: hacer un doble cheque y que no se nos quede ninguno abajo.

Andrés Merino Sotomayor: Oh.

Aldo Álvarez: Justo te pediría, compárteme las dos cosas.

Aldo Álvarez: O sea, porque lo que yo voy a hacer es extraer la de la base que tiene todas las facturas con inteligencia artificial los contratos.

Aldo Álvarez: Voy a voy a generar una relación y voy a cruzarlo contra la que tú tienes para ver si hay correspondencia uno a uno o dónde están los las diferencias, ¿no?

Aldo Álvarez: Ya sabiendo a qué factura pertenece cada contrato, entonces ya le puedo pedir a Omar que corra un RPA para más o menos 60 y tantos mil contratos que tienen desde el 2022 eh nos va a

Aldo Álvarez: tomar como 15 días.

Aldo Álvarez: de dejar el RPA en las noches cargando, ¿no?

Aldo Álvarez: Y una vez que las órdenes de pago estén, con la información que Andrés nos va a compartir en la carpeta, le voy a pedir a Ti que haga la inyección de las facturas, como el proceso que ya viste en Colombivas,

Aldo Álvarez: que ya, o sea, que que ya nos dejaron ahí en una carpeta compartida los los PDFs y los XML y lo cargan, ¿no?

Aldo Álvarez: Ahora,

Gustavo Ivan Carreto Abascal: H

Aldo Álvarez: en la información que te compartió el despacho Andrés, ¿te compartieron PDF y XML o solo XML o solo PDF?

Andrés Merino Sotomayor: Vo exportar

Aldo Álvarez: Okay,

Andrés Merino Sotomayor: ambos.

Aldo Álvarez: si necesitamos ambos para poderlos inyectar.

Aldo Álvarez: Y lo último que va a faltar ya con esto, con lo que estamos platicando, vamos acamos inteligencia artificial, vemos que tiene, ya sabemos cuáles contratos en factura, corremos el RPA, se carga la orden de pago, perfecto, ya que tengan su orden de pago,

Aldo Álvarez: le inyectamos la factura de XML.

Aldo Álvarez: Muy bien, ya está casi todo listo.

Aldo Álvarez: ¿Y qué va a hacer falta?

Aldo Álvarez: la conciliación de pago.

### 00:15:00

Aldo Álvarez: O sea, Colombia a través de su despacho contable, porque lo hacen ellos, ellos tienen una relación en un Excel de los contratos que ya les pagaron y dicen, "No, estos este contrato ya se pagó y se pagó en esta fecha y de esa información de finanzas es que te saca la

Aldo Álvarez: fecha de pago.

Aldo Álvarez: Porque para activar el contrato necesitas el contrato ya que financias te diga que sí está pagado y la fecha de cuándo se pagó.

Aldo Álvarez: ¿Alguien dentro de Chile lleva esa ese control?

Aldo Álvarez: Andrés,

Andrés Merino Sotomayor: Pero contra número de factura, no contra número de contrato está abierto,

Aldo Álvarez: está bien,

Andrés Merino Sotomayor: pero sí.

Aldo Álvarez: porque al final si ya voy, o sea, si ya voy a tener la relación de contrato contra factura y tengo la relación de pago de factura, pues no.

Andrés Merino Sotomayor: No tengo.

Andrés Merino Sotomayor: Sí, está está referenciado a la transacción

Aldo Álvarez: Entonces, perfecto.

Aldo Álvarez: Entonces,

Andrés Merino Sotomayor: también.

Aldo Álvarez: si también nos pueden compartir en un espacio compartido esa relación del histórico, pues ya podríamos activar.

Aldo Álvarez: Ahora, Héctor va a querer activar desde el 2022 y el despacho contable le pedimos desde el 2024\. Entonces, vamos por pasos, activemos 2024 a la fecha que me resuelve la mayor parte del problema y luego pedimos hacia

Andrés Merino Sotomayor: Hay hay algunos contratos activos en el histórico hacia atrás.

Aldo Álvarez: atrás.

Andrés Merino Sotomayor: Yo cuando recién ingresé a la empresa y estaba saliendo a mericar de la gestión contable, existían contratos que fueron activos y Ana Techita en su minuto hizo también una activación masiva de varios contratos.

Andrés Merino Sotomayor: que debe haber sido hasta mediados del 2023, puede que algunos el 2024,

Aldo Álvarez: Okay.

Andrés Merino Sotomayor: pero de ahí en adelante ya no.

Andrés Merino Sotomayor: De hecho, el documento de orden de pago no existía y el que está ahora eh es una plantilla de México, tampoco aplica para Chile.

Aldo Álvarez: Ya nada más.

Aldo Álvarez: Esto es para fines ilustrativos de Iván.

Aldo Álvarez: Esta es la factura que te trae aquí el número de factura.

Aldo Álvarez: Ahora, el la parte interesante en Colombia es que el número de factura no coincide con el folio de factura

Gustavo Ivan Carreto Abascal: Okay.

Aldo Álvarez: de sigo porque le faltan las letras.

Aldo Álvarez: Coincide a números, pero detrás no.

Aldo Álvarez: O sea, simplemente lo quitas el cuadra, ¿no?

Aldo Álvarez: Entonces, a este es que le copiamos la factura de Sigo con el documento donde sacamos extracción de Sigo, pero lo hacemos con API.

Aldo Álvarez: Sí, sabemos que tiene ya factura emitida, pero no cargada.

Aldo Álvarez: Y en el caso de Chile tendremos, o sea, no existe un consecutivo de FIGO, pero por eso decía, "Separemos la conversación en dos. vas a tener el histórico de las facturas que nos va a compartir Andrés y más bien tenemos que definir con el equipo del

Aldo Álvarez: despacho contable que mes a mes depositar en un espacio compartido las facturas que emitieron ese mes y entonces empezar a

Gustavo Ivan Carreto Abascal: y empezar a encontrar el rasero.

Aldo Álvarez: ay y empezar a llevar el acumulado,

Gustavo Ivan Carreto Abascal: No.

Aldo Álvarez: ¿no?

Aldo Álvarez: Porque entonces este proceso de activación en el caso de Chile va a suceder una vez por mes, que es se emite la factura, se carga la factura, revisó que se pagó, ya está pagado, ¿me explico?

Gustavo Ivan Carreto Abascal: Sí.

Aldo Álvarez: Y entonces eso es lo que vamos a hacer, ese es el plan para regularizar y activar.

Aldo Álvarez: ¿Alguna duda?

Andrés Merino Sotomayor: Claro, por mi lado tengo una duda operativa a futuro, eso sí, que puede que ya la tengan media solucionada ustedes cuando estamos cuando se emite un contrato,

Gustavo Ivan Carreto Abascal: Yeah.

Andrés Merino Sotomayor: ejemplo, el día de enero para hacerlo en práctico.

Andrés Merino Sotomayor: Facturamos el día 30 de enero ese contrato y en Chile, por lo menos la facturas tienen crédito a 30 días, por lo que está pagando el cliente el 28 de febrero, primero de marzo y una vez ahí, entiendo,

Andrés Merino Sotomayor: activamos el contrato.

Aldo Álvarez: Correcto.

Andrés Merino Sotomayor: Considerando que la velocidad del siniestro en Chile, su pic está en el primer mes.

Andrés Merino Sotomayor: Yo lo que estoy haciendo para el control hoy en día, estamos analizando la cartera del cliente y si el cliente no tiene facturas en deuda hacemos ingreso de o cuando es un cliente pequeño se lo facturamos y le

Andrés Merino Sotomayor: obligamos a pagarlo.

Andrés Merino Sotomayor: Pero cuando es un cliente Americar la verdad es que Fabricio firma y autoriza el ingreso dejando el respaldo, pero no sé cómo ustedes lo hacen con algunos clientes grandes que puede que sea un hito regular.

Aldo Álvarez: Mira, eh, ahí te va.

Aldo Álvarez: Separemos la conversación en dos otra vez.

Aldo Álvarez: La primera parte es que se una disculpa, es la manera en la que estructuro yo mi cabeza.

Andrés Merino Sotomayor: Vale.

Aldo Álvarez: Eh, entonces la primera parte es este proceso que te estoy platicando también ayuda a llevar, o sea, una gestión de las cuentas por cobrar,

Andrés Merino Sotomayor: Sin

Aldo Álvarez: o sea, porque tienes el acumulado de las facturas,

Andrés Merino Sotomayor: duda.

Aldo Álvarez: está llegado a los contratos, tienes la conciliación por factura, por ende sabes qué contratos están pagados y cuáles no.

Aldo Álvarez: Y dado que sabes qué contratos están pagados y cuáles no, pues sabes qué clientes te deben y cuánto, ¿no?

### 00:20:00

Aldo Álvarez: Y por la fecha de emisión de la factura tú puedes ya si te quieres meter muy a detalle, o sea, puedes poner políticas de pago, porque en México,

Andrés Merino Sotomayor: Exacto.

Aldo Álvarez: por ejemplo, hay gente que paga 30, 45 o a 60, pudieras meter ese detalle y saber qué facturas están vendidas y cuáles no.

Aldo Álvarez: Si no, arrancas con una política más simple, que es todos 30 días, todo lo que no tenga menos de 30 días no lo voy a cobrar.

Aldo Álvarez: que tenga más de 30 ya está vencido y empieza a contar bien, ¿no?

Aldo Álvarez: Entonces aquí se separa la primera conversación es bueno con este mismo sistema que estoy platicando y este proceso ya vamos a poder llevar, o sea, pues mayor control sobre la cartera vencida, ¿no?

Andrés Merino Sotomayor: Sin duda.

Aldo Álvarez: Y por otro lado, que es tu pregunta para el tema de las averías pagadas sobre contratos que no nos han activado, existe un filtro e que en su momento, Andrés, yo le, o sea,

Aldo Álvarez: me pidieron el filtro para que cuando entre una avería de un contrato que no está pagado, la aprobación pase por el country manager.

Andrés Merino Sotomayor: Te puedes imaginar cómo es en Chile, son todos, literalmente.

Aldo Álvarez: Les yo les dije, Andrés, les dije en estuvimos con Juliana, con Israel y con Fabricio en tres juntas diferentes porque desde la primera dijeron que no, yo les dije que sí.

Aldo Álvarez: Me dijeron que no, yo les dije que sí.

Aldo Álvarez: Y les dije, si tú autorizas esto, te vas a meter, no un balazo, te vas a hacer un escopetazo en el pie porque te van a llevar 4,000 activaciones y entonces tu correo va a estar de puras activaciones de temas.

Aldo Álvarez: Y lo que dijeron los country managers fue, no, si ese es el proceso,

Andrés Merino Sotomayor: Era

Aldo Álvarez: nos vamos a alinear porque es importante que la transversalidad y yo no está, o sea, es que no lo dimensionas,

Andrés Merino Sotomayor: un momento crítico, veámoslo

Aldo Álvarez: es que no lo dimensionas,

Andrés Merino Sotomayor: así.

Aldo Álvarez: ¿eh?

Aldo Álvarez: Pero entonces aquí pasan dos cosas, o sea, uno, el filtro existe y es así, o sea, cuando se va a pagar una averia sobre un contrato que no está en activo, se puede emitir una aprobación.

Aldo Álvarez: Hoy le llega el country manager, pero por ejemplo Isra ya los reenvió a David y ahora David es el que

Andrés Merino Sotomayor: Perfecto.

Aldo Álvarez: aprueba.

Aldo Álvarez: Y en el caso de Fabricio, Fabricio los puede reubicar contigo o con Agustín o con Pablo o con Y la aprobación se puede dar por otra persona siempre y cuando quede documentado por quién

Andrés Merino Sotomayor: Claro,

Aldo Álvarez: y por qué.

Aldo Álvarez: ¿Me explico?

Andrés Merino Sotomayor: perfecto.

Aldo Álvarez: Entonces,

Andrés Merino Sotomayor: Ah, ya,

Aldo Álvarez: nada más es de que definan quién.

Andrés Merino Sotomayor: pero se mantiene Ya,

Aldo Álvarez: Si se mantiene la aprobación, lo que puede cambiar es quién aprueba.

Andrés Merino Sotomayor: ya.

Andrés Merino Sotomayor: Perfecto.

Andrés Merino Sotomayor: Ah, ya.

Andrés Merino Sotomayor: Pero ese flujo está pensado para estos casos, entonces quedaría funcionando ya.

Aldo Álvarez: Ajá.

Andrés Merino Sotomayor: Perfecto.

Aldo Álvarez: Lo que yo propuse fue otra cosa, Andrés, que fue déjalas pasar y mejor identificamos las averías por

Andrés Merino Sotomayor: Buenísimo.

Aldo Álvarez: contrato.

Aldo Álvarez: Veo cuáles ya se pagaron sobre contratos que no están en activo.

Aldo Álvarez: Yo te hago un tablero y te pongo en un espacio cliente por cliente quién está pagando avería sobre contratos no activos para que tus vendedores vayan y confirmen esos contratos.

Aldo Álvarez: Y es más simple porque entonces ya ese tablero lo puedes mostrar en la junta de ventas y dices a los de ventas, oye, esto ya se pagó.

Aldo Álvarez: Que en el caso de Chile estaría más transparente porque tengo que pagar sí o sí independientemente si Americar me paga o no.

Aldo Álvarez: Entonces si generas el tabler con el talle por cliente, pues decimos, mira, esto es lo que ya se pagó.

Aldo Álvarez: Este, ve y búscame esos pagos de los contratos.

Andrés Merino Sotomayor: No, sin duda,

Aldo Álvarez: Entonces esa opción existe.

Andrés Merino Sotomayor: sin duda.

Aldo Álvarez: Si quieren que la piloteemos en Chile, la podemos pilotear, pero tendríamos que desarrollar los tableros que tampoco es Rocket Science.

Aldo Álvarez: Y ya a partir de ahí definimos el proceso, nos juntamos con Benjamín, le decimos, "Oye, mira, esto hay que estarlo cobrando, lo dejamos pasar y vemos cómo funciona y como va a funcionar lo vamos a escalar a México y a

Aldo Álvarez: Chill."

Andrés Merino Sotomayor: Perfecto.

Aldo Álvarez: ¿Alguna otra duda?

Aldo Álvarez: Bueno,

### La reunión finalizó después de 00:24:09 👋

*Esta transcripción editable se generó automáticamente y puede contener errores. Los usuarios también pueden cambiar el texto después de que se cree.*

