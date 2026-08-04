# PRD - Activación de Contratos Chile

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | Activación de Contratos Chile — motor de datos `contratos_chile` |
| **Área / empresa** | Garantiplus Chile |
| **Versión** | v1.1 |
| **Fecha** | 2026-08-04 |
| **Autores** | Gustavo Iván Carreto Abascal (datos / automatización) |
| **Revisión / liderazgo** | Aldo Álvarez |
| **Tipo de proyecto** | Automatización |

## 1. Resumen ejecutivo

En México y Colombia la obligación sobre un contrato de garantía existe **solo hasta que el contrato está pagado**, por lo que activarlo en SIGA es lo que le da respaldo legal. En Chile la responsabilidad legal existe **desde que el cliente adquiere la garantía**, sin importar si el distribuidor pagó. Por eso Chile nunca necesitó activar contratos, y hoy tiene alrededor de 60 mil contratos sin activar desde 2022.

Eso dejó a la operación chilena sin dos capacidades que el resto de los países sí tiene. La primera es **control de cartera**: sin la relación contrato↔factura conciliada no se sabe qué distribuidor debe cuánto ni desde cuándo. La segunda es el **seguimiento de averías sobre contratos no pagados**: en Chile la avería se paga igual por obligación legal, pero hoy no queda registro de sobre qué contratos no activos se está pagando, así que nadie va a cobrarle al distribuidor.

Activar un contrato en SIGA exige cuatro pasos en orden —registro, factura cargada, orden de pago asociada, proceso de activación— y Chile solo cumple el primero. El cuello de botella es que la orden de pago debe corresponder **1:1** con la factura para cargarse de forma automática, pero se genera a mano, contrato por contrato, en un buscador de SIGA. Con 600–800 ventas al mes y facturas consolidadas que agrupan decenas de contratos, hacerlo manualmente es inviable. El work-around vigente es un RPA que carga órdenes de pago una por una mientras TI inyecta las facturas directamente en base de datos.

**El MVP de este PRD es el motor de datos que alimenta ese work-around**: consolida y valida los insumos del despacho contable alojados en Google Drive, y produce tres entregables confiables —el listado para el RPA, el listado para la inyección de TI y un reporte de conciliación—. El motor **no activa contratos, no ejecuta el RPA y no inyecta nada**: solo garantiza que los datos con los que operan Omar y TI estén completos y cuadrados. La conciliación de pagos y la generación del set de activación quedan para una fase posterior.

El resultado esperado es habilitar la regularización histórica (~15 días de RPA nocturno sobre el acervo desde 2022) y dejar instalado el proceso mensual recurrente, con la relación contrato↔factura auditable como subproducto que alimenta el control de cartera y el tablero de averías.

**Insumos del despacho en Drive** → **Ingesta y normalización** → **Conciliación Excel↔XML por factura** → **Tres entregables validados** → **RPA de órdenes de pago (Omar) e inyección de facturas (TI)**

## 2. Contexto y problema

**Cómo funciona hoy.** El contrato se registra en SIGA sin problema —Chile ya lo hace—. A partir de ahí el proceso se rompe. La factura no se emite automáticamente: hay que pedirle al despacho contable que la genere, y en el **85–90%** de los casos se emite **consolidada a fin de mes**, agrupando muchos contratos en un solo folio. Existe además facturación manual bajo pedido de ciertos clientes, que agrupan contratos de varios meses en una factura. La pasarela de pago que se usa en otros países no aplica en Chile: si Garantiplus recauda directamente, empieza a operar como aseguradora, lo que tiene implicaciones normativas.

**El dolor concreto.** Para cargar una factura automáticamente en SIGA, la orden de pago debe corresponder 1:1 con ella. Pero la orden de pago se genera manualmente, contrato por contrato, buscando cada uno en un buscador. Para 600–800 ventas mensuales por país, con una persona y unos pocos días disponibles, no hay manera. El resultado es un doble work-around: el RPA de Omar carga órdenes de pago individuales, y como no coinciden 1:1 con las facturas consolidadas, TI inyecta las facturas directamente en la base de datos, saltándose la validación del sistema.

**Por qué ahora.** Dos drivers concretos. El de cartera: sin la conciliación no hay visibilidad de cuánto debe cada distribuidor ni desde cuándo, y las facturas chilenas tienen crédito a 30 días. El de averías: David solicitó poder identificar las averías pagadas sobre contratos no activos para que el vendedor gestione el cobro. A eso se suma el volumen acumulado —~60 mil contratos desde 2022— que solo crece.

**Distinción crítica para el equipo de desarrollo.** El *filtro de averías* de este contexto **no es un bloqueo**. El filtro de aprobación ya existe en SIGA (una avería sobre contrato no activo escala a aprobación). Lo que se decidió es lo contrario: **dejar pasar las averías** —en Chile hay que pagarlas de todas formas— e **identificarlas** en un tablero cliente por cliente para que ventas gestione el cobro. El motor de este PRD habilita esa identificación al producir la relación contrato↔factura; el tablero es una fase posterior.

## 3. Objetivo del producto

Construir un motor de datos headless, orquestable por n8n, que a partir de los insumos del despacho contable alojados en Google Drive produzca los entregables que permiten regularizar y luego mantener la activación de contratos en Chile: el listado para el RPA de órdenes de pago, el listado para la inyección de facturas por TI, y un reporte de validación que garantice que los datos cuadran **antes** de operar sobre ellos.

El mismo motor debe servir para los dos modos de uso: la **regularización histórica** de los años ya facturados, y el **proceso mensual recurrente** que se instala después (se factura → se valida → se carga → se activa). La mejora medible es la cobertura de activación: pasar de un acervo mayoritariamente inactivo a tener activados los contratos con factura emitida y pagada.

### 3.1 Estrategia de implementación por fases

| **Fase** | **Nombre** | **Descripción** |
| --- | --- | --- |
| Fase 1 | Motor de validación **(MVP de este PRD)** | Ingesta de Excel, XML y PDF; conciliación Excel↔XML a nivel factura; generación de `feed_rpa`, `lista_ti` y `reporte_validacion`; publicación en Drive. Cubre 2025 y 2026. |
| Fase 2 | Conciliación de pagos y activación | Ingesta de "Fechas de Pago", derivación de la fecha de pago por contrato y generación del set de contratos a activar. Primero 2024 → hoy, luego hacia atrás hasta 2022. |
| Fase 3 | Orquestación y tableros | Automatización mensual end-to-end en n8n; tableros de cartera vencida y de averías sobre contratos no activos. |

**La Fase 1 es el MVP de este PRD.** Las Fases 2 y 3 se documentan para dar contexto de dirección, pero su alcance detallado se define en sus propios PRD.

**Prioridad de regularización acordada:** activar de **2024 a la fecha** primero, porque resuelve la mayor parte del problema, y después pedir el histórico hacia atrás hasta 2022.

## 4. Usuarios y actores

| **Usuario / Actor** | **Rol en el proceso** |
| --- | --- |
| Despacho contable (Chile) | Emite las facturas y deposita mensualmente los Excel de facturación, XML y PDF en la carpeta compartida de Drive. Es el origen de todos los insumos. |
| Andrés Merino Sotomayor | Propietario de la carpeta de Drive. Gestiona al despacho contable, mantiene la relación contrato↔factura y lleva el control de pagos por número de factura. |
| Operador del motor | Ejecuta el motor, revisa el reporte de validación y **decide qué contratos se mandan al RPA**. El motor no filtra solo. |
| Omar | Opera el RPA que carga las órdenes de pago en SIGA, una por una. Consume `feed_rpa.csv`. |
| Equipo de TI | Inyecta las facturas directamente en la base de datos de SIGA. Consume `lista_ti.csv` junto con los XML y PDF. |
| David Simancas Estrada | Solicitante del seguimiento de averías sobre contratos no activos. Hoy aprueba esas averías tras la redirección del country manager. |
| Vendedores | Gestionan el cobro con el distribuidor a partir de la información de contratos no activos con avería pagada. |
| Finanzas | Confirma que la factura está pagada y en qué fecha. Insumo indispensable para la activación (Fase 2). |
| Dirección / liderazgo | Consume la visibilidad de cartera vencida por distribuidor que habilita el proceso. |

## 5. Alcance MVP y funcionalidades

| **Funcionalidad** | **Descripción** |
| --- | --- |
| Ingesta de Excel de facturación | Lee los Excel del despacho (`FACTURACION AÑO 2025.xlsx`, `FACTURACION 2026.xlsx`). Cada fila es un contrato. El mapeo de columnas es **por nombre, no por posición**, y tolera columnas ausentes: el esquema varía entre años (el archivo 2026 trae `Impuestos`, `Total` y `Garant. Fabrica`, que 2025 no tiene). |
| Ingesta y parseo de XML (DTE SII) | Parsea los documentos tributarios electrónicos `F{folio}T{tipo}.xml` para extraer folio, tipo de DTE, fecha de emisión, RUT del receptor y montos (neto, IVA, total). Se usa exclusivamente para validar **a nivel factura**. |
| Inventario de PDF | Registra qué folios tienen PDF disponible. El PDF es evidencia y respaldo para la inyección de TI; no se extrae texto de él. |
| Normalización | Estandariza montos (formato chileno `$1.234.567` → entero), folios, fechas e identificadores de contrato. Marca las filas vacías y las marcadas como `NO FACTURADO`. |
| Conciliación Excel↔XML por factura | Compara la suma de los montos de los contratos que el Excel asigna a un folio contra el monto de ese folio en el XML, con una tolerancia de redondeo configurable. |
| Clasificación en tres estados | Cada factura queda en `CUADRA` (folio existe y montos coinciden), `NO_CUADRA` (folio existe, montos no) o `NO_VERIFICABLE` (no hay XML/PDF, o el folio no está en el Excel). |
| Generación de `feed_rpa.csv` | Un renglón por contrato con factura emitida, con los datos que el RPA necesita para buscarlo en SIGA más los de trazabilidad, y su estado de validación. |
| Generación de `lista_ti.csv` | Un renglón por factura, agrupando sus contratos, con los datos del XML y las referencias a los archivos XML y PDF. |
| Generación de `reporte_validacion.xlsx` | Libro de control con cinco hojas: Resumen, No cuadra, No verificable, Sin factura y Excluidos. |
| Publicación de resultados | Sube los tres entregables a una subcarpeta `Resultados_Motor/` en Drive, con fecha en el nombre. Nunca escribe sobre las carpetas de insumos. |
| Ejecución headless | Corre sin sesión interactiva, con logging estructurado y código de salida distinto de cero ante fallo, para que n8n pueda detectarlo. |

**Principio rector del MVP: reportar, no decidir.** El motor clasifica y expone; **no filtra automáticamente qué va al RPA**. Los casos problemáticos —sin factura, montos que no cuadran, sin XML— se reportan con su motivo y nunca se descartan en silencio. La decisión de qué se opera es del operador, porque una exclusión automática equivocada sobre 60 mil contratos es mucho más costosa que una revisión manual.

## 6. Fuera de alcance

- **Activación de contratos en SIGA**: el motor produce insumos; la activación es un proceso de SIGA que se ejecuta con la fecha de pago confirmada por finanzas.
- **Ejecución del RPA de órdenes de pago**: lo opera Omar. El motor solo lo alimenta.
- **Inyección de facturas en base de datos**: la hace TI. El motor solo produce el listado.
- **Conciliación de pagos y derivación de la fecha de pago**: queda para la Fase 2. La carpeta "Fechas de Pago" está vacía a la fecha de este PRD.
- **Generación del set de contratos a activar**: depende de la conciliación de pagos, por lo tanto Fase 2.
- **Orquestación mensual automatizada en n8n**: Fase 3. El MVP se diseña compatible (headless, exit code, log limpio), pero corre invocado manualmente.
- **Tableros de cartera vencida y de averías sobre contratos no activos**: Fase 3. Requieren que la relación contrato↔factura ya esté establecida y validada, que es justo lo que produce este MVP.
- **Validación contrato por contrato contra el XML**: técnicamente imposible. El detalle del XML no contiene los números de contrato (ver §10), así que la validación solo puede ser agregada por factura.
- **Extracción de contratos desde las facturas con IA**: era el enfoque original, descartado al confirmarse que el XML no contiene esa información. El Excel es la única fuente de la relación.

## 7. Flujos principales

### 7.1 Flujo del motor

```mermaid
flowchart TD
    A[Google Drive: insumos del despacho] --> B[Ingesta]
    B --> B1[Excel de facturación]
    B --> B2[XML DTE SII]
    B --> B3[PDF]
    B1 --> C[Normalización: montos, folios, fechas, IDs]
    B2 --> C
    B3 --> C
    C --> D{¿La fila tiene folio de factura?}
    D -->|No / NO FACTURADO| E[Hoja 'Sin factura' del reporte]
    D -->|Sí| F[Agrupar contratos por folio]
    F --> G{¿Existe XML y PDF de ese folio?}
    G -->|No| H[NO_VERIFICABLE]
    G -->|Sí| I{¿Suma del Excel = monto del XML,<br/>dentro de la tolerancia?}
    I -->|Sí| J[CUADRA]
    I -->|No| K[NO_CUADRA + delta]
    H --> L[Entregables]
    J --> L
    K --> L
    E --> L
    L --> M[feed_rpa.csv → RPA de Omar]
    L --> N[lista_ti.csv → inyección de TI]
    L --> O[reporte_validacion.xlsx → operador]
    M --> P[Drive: Resultados_Motor/]
    N --> P
    O --> P
```

El flujo tiene una asimetría deliberada: **todo lo que no se puede verificar sigue avanzando hacia los entregables, marcado**. No hay ninguna rama que termine en un descarte silencioso. Esto es consecuencia directa del volumen: sobre 60 mil contratos, un filtro automático mal calibrado produce un error masivo e invisible, mientras que un caso marcado de más solo cuesta una revisión.

La conciliación ocurre en el nodo de agrupación por folio, no antes. Es el punto donde el diseño reconoce que el Excel y el XML viven en granularidades distintas —el Excel es por contrato, el XML es por factura— y que la única granularidad común es la factura.

### 7.2 Flujo del proceso completo de activación (contexto)

```mermaid
flowchart LR
    A[Contrato registrado<br/>en SIGA] --> B[Factura emitida<br/>por el despacho]
    B --> C[Factura cargada<br/>en SIGA]
    C --> D[Orden de pago<br/>generada y asociada]
    D --> E[Proceso de activación<br/>con fecha de pago]
    B -.alimenta.-> M[Motor contratos_chile]
    M -.feed_rpa.-> D
    M -.lista_ti.-> C
```

Este segundo diagrama existe para ubicar el alcance: **el motor toca dos de los cinco pasos, y solo como proveedor de datos**. El paso 1 ya funciona, el paso 5 depende de finanzas, y los pasos 3 y 4 los ejecutan TI y Omar con los entregables del motor. Entender esto evita que el equipo de desarrollo asuma responsabilidad sobre resultados que el motor no controla.

## 8. Requerimientos funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RF-01 | Ingesta multi-año de Excel | Leer los Excel de facturación de los años configurados, mapeando columnas **por nombre** y tolerando las que falten o sobren respecto de otros años. |
| RF-02 | Normalización de montos | Convertir montos en formato chileno (`$1.234.567`, con `$` y punto como separador de miles) a entero, sin pérdida ni error de escala. |
| RF-03 | Detección de contratos sin factura | Identificar como "sin factura" toda fila cuyo `FACTURA N°` esté vacío o diga `NO FACTURADO`, y llevarla a la hoja correspondiente del reporte en lugar de descartarla. |
| RF-04 | Parseo de DTE del SII | Extraer de cada XML: folio, tipo de DTE, fecha de emisión, RUT del receptor, razón social y montos neto, IVA y total. |
| RF-05 | Inventario de documentos | Determinar, para cada folio, si existe su XML y si existe su PDF, a partir de la convención `F{folio}T{tipo}.{ext}`. |
| RF-06 | Agrupación por folio | Agrupar los contratos del Excel por folio de factura y calcular la suma de sus montos y la cantidad de contratos. |
| RF-07 | Conciliación de montos | Comparar la suma agrupada contra el monto del XML del mismo folio, aplicando una tolerancia de redondeo configurable. |
| RF-08 | Clasificación en tres estados | Asignar a **cada** factura exactamente uno de: `CUADRA`, `NO_CUADRA`, `NO_VERIFICABLE`, junto con el motivo legible de la clasificación. |
| RF-09 | Reporte de documentos huérfanos | Reportar los XML o PDF cuyo folio no tiene correspondencia en ningún Excel, como posible factura no registrada en la relación. |
| RF-10 | Generación de `feed_rpa.csv` | Emitir un renglón por contrato con factura emitida, con: identificador de contrato, folio, monto, beneficiario, RUT, VIN, patente, distribuidor, fecha de alta y estado de validación. |
| RF-11 | Generación de `lista_ti.csv` | Emitir un renglón por factura con: folio, tipo de DTE, fecha de emisión, RUT del receptor, monto del XML, monto del Excel, cantidad de contratos, lista de contratos, referencia al XML, referencia al PDF y estado de validación. |
| RF-12 | Generación del reporte de validación | Emitir un libro Excel con cinco hojas: Resumen (conteos por estado, montos y cobertura por año), No cuadra (con el delta), No verificable, Sin factura y Excluidos. |
| RF-13 | Conservación de filas | Garantizar que `contratos con factura + contratos sin factura + excluidos = total de filas del Excel`, y abortar la ejecución si la igualdad no se cumple. |
| RF-14 | Publicación de resultados | Subir los tres entregables a la subcarpeta `Resultados_Motor/` de Drive, con la fecha en el nombre del archivo, sin sobrescribir corridas anteriores. |
| RF-15 | Configurabilidad sin código | Permitir cambiar años a procesar, IDs de carpetas de Drive, tolerancias, tipos de DTE válidos y reglas de exclusión editando **únicamente** el archivo de configuración. |

## 9. Requerimientos no funcionales

| **ID** | **Requerimiento** | **Descripción** |
| --- | --- | --- |
| RNF-01 | Ejecución headless | El motor corre sin sesión interactiva ni intervención humana durante la corrida, de modo que pueda invocarse desde n8n en la Fase 3. |
| RNF-02 | Fallo ruidoso | Ante cualquier error, el motor termina con código de salida distinto de cero y un mensaje de log que identifica la causa, para que el orquestador lo detecte. Nunca falla en silencio ni continúa con datos parciales. |
| RNF-03 | Trazabilidad de cada fila | Cada renglón de los entregables permite rastrear su origen hasta la fila del Excel de la que salió. |
| RNF-04 | Idempotencia | Dos corridas sobre los mismos insumos producen el mismo resultado. Los entregables se versionan por fecha; no se sobrescriben corridas anteriores. |
| RNF-05 | Integridad de los insumos | El motor **nunca escribe** en las carpetas de insumos de Drive. Los resultados van a una subcarpeta separada. |
| RNF-06 | Privacidad de los datos | Los insumos contienen RUT, nombres de beneficiarios, VIN y patentes de personas reales. Los datos reales son efímeros y locales, viven fuera del control de versiones y no se copian a documentación, notas ni reportes de avance. |
| RNF-07 | Gestión de credenciales | Las credenciales de acceso a Drive viven fuera del control de versiones. La plantilla de configuración documenta cada llave con valor vacío. |
| RNF-08 | Mínimo privilegio | La identidad con la que el motor accede a Drive tiene lectura sobre las carpetas de insumos y escritura **solo** sobre la carpeta de resultados. |
| RNF-09 | Logging sin datos personales | Los registros de ejecución referencian folios, conteos y estados; nunca RUT, nombres, VIN ni patentes. |
| RNF-10 | Tolerancia a la variación de esquema | Un cambio de columnas entre años del Excel no rompe la ejecución; las columnas ausentes se manejan y las nuevas se ignoran si no están mapeadas. |
| RNF-11 | Operabilidad por un tercero | Una persona ajena al desarrollo puede instalar y ejecutar el motor siguiendo únicamente el README del repositorio. |
| RNF-12 | Legibilidad de los entregables en Chile | Los CSV se abren correctamente en Excel con la configuración regional chilena, sin que las columnas se colapsen por el separador. |

## 10. Integraciones y datos

| **Integración / Fuente** | **Uso esperado** |
| --- | --- |
| Google Drive — `Cruce Facturas/Contratos` | **Lectura.** Excel de facturación por año. Fuente de verdad de la relación contrato↔factura, montos, fechas y datos del beneficiario. |
| Google Drive — `Facturas XML` | **Lectura.** Documentos tributarios electrónicos del SII para validación a nivel factura. |
| Google Drive — `Facturas PDF` | **Lectura.** Evidencia y respaldo; insumo para la inyección de TI. |
| Google Drive — `Fechas de Pago` | **Lectura (Fase 2).** Vacía a la fecha de este PRD. |
| Google Drive — `Resultados_Motor/` | **Escritura.** Único destino de salida del motor. |
| RPA de órdenes de pago (Omar) | **Consumo.** Recibe `feed_rpa.csv`. El motor no lo invoca ni conoce su estado. |
| Equipo de TI | **Consumo.** Recibe `lista_ti.csv` junto con los XML y PDF referenciados. |
| SIGA | **Sin integración directa en el MVP.** El motor no lee ni escribe en SIGA; los identificadores de contrato que produce son los que el RPA usa para buscar allí. |

**Datos mínimos requeridos para operar.** Del Excel: `FACTURA N°` (folio), `ID` (contrato), `Producto`, `Importe` y `Monto a Facturar`, las fechas (`F. Alta`, `F. Pago`, `F. Cancelación`, `F. Inicio`, `F. Fin`), los datos del beneficiario y vehículo (`Beneficiario`, `R.U.T.`, `VIN`, `Patente`), los del canal (`Id Distr.`, `Distribuidor`, `Canal`, `Punto Venta`, `Grupo`) y `Estatus`. Del XML: tipo de DTE, folio, fecha de emisión, RUT del emisor, RUT y razón social del receptor, y los montos neto, IVA y total. De los archivos: la convención de nombre `F{folio}T{tipo}.{ext}`, que es lo que permite asociar documento y folio.

**Hallazgo estructural que condiciona todo el diseño.** El bloque `Detalle` del XML **no contiene los números de contrato**: una línea consolidada declara la cantidad (`8 UNID`) sin desglosar cuáles son los ocho contratos. Por eso el XML sirve para validar a nivel factura pero **nunca** para recuperar contratos individuales, y la relación contrato↔factura existe únicamente en el Excel. Cualquier diseño que asuma lo contrario es inviable.

**Esquema de permisos.** El motor **lee** las cuatro carpetas de insumos y **escribe únicamente** en `Resultados_Motor/`. No tiene permiso de modificación sobre los insumos ni acceso alguno a SIGA. Toda acción que altere el estado de un contrato —cargar una orden de pago, inyectar una factura, activar— queda fuera del motor y requiere la intervención de Omar o de TI.

## 11. Eventos para BI

Estos eventos alimentan los tableros de cartera vencida y de averías sobre contratos no activos previstos en la Fase 3. Se registran por corrida del motor.

**Eventos de ejecución**

- `corrida_iniciada`: se registra al arrancar el motor, con los años a procesar y el origen de los insumos.
- `corrida_finalizada`: se registra al terminar correctamente, con los conteos por estado y el total de filas procesadas.
- `corrida_fallida`: se registra ante un error que aborta la ejecución, con la causa.

**Eventos de conciliación**

- `factura_clasificada`: se registra por cada factura evaluada, con su estado resultante y el motivo.
- `factura_no_cuadra`: se registra cuando la suma del Excel difiere del monto del XML más allá de la tolerancia, con el delta.
- `factura_no_verificable`: se registra cuando falta el XML o el PDF de un folio presente en el Excel.
- `documento_huerfano`: se registra cuando existe un XML o PDF cuyo folio no aparece en ningún Excel.
- `contrato_sin_factura`: se registra por cada contrato cuyo folio viene vacío o marcado como `NO FACTURADO`.

**Campos mínimos por evento:** fecha y hora, identificador de la corrida, año de origen del insumo, folio (cuando aplique), cantidad de contratos afectados, monto involucrado, estado y motivo. **Los eventos no incluyen datos personales** —ni RUT, ni beneficiario, ni VIN, ni patente—: la trazabilidad hacia el contrato individual se hace por identificador de contrato, no por identidad de la persona.

## 12. Métricas de éxito

| **Métrica** | **Descripción** |
| --- | --- |
| **Cobertura de activación** | Porcentaje de contratos con factura emitida que quedan efectivamente activados en SIGA. Es la métrica principal del proyecto y la razón por la que existe. **Requiere validación con BI y operación** para fijar línea base (cuántos contratos activos hay hoy, considerando la activación masiva histórica) y meta por período. |
| Clasificación completa | Porcentaje de facturas clasificadas en alguno de los tres estados. La meta es 100%: una factura sin estado es un caso invisible. Se mide dentro del propio reporte de validación. |
| Conservación de filas | La suma de contratos con factura, sin factura y excluidos debe igualar el total de filas del Excel en cada corrida. Es binaria: se cumple o la corrida es inválida. |
| Tasa de correspondencia documental | Porcentaje de folios del Excel que tienen su XML y PDF. Mide la completitud de lo que entrega el despacho contable y sirve para gestionar con Andrés lo que falte. |
| Facturas que cuadran | Porcentaje de facturas en estado `CUADRA` sobre el total verificable. Mide la calidad de los datos del despacho; una caída señala un problema de origen, no del motor. |

Las cuatro métricas posteriores a la principal se derivan de los criterios de calidad del diseño original y son observables en el propio reporte de validación, sin instrumentación adicional. **La métrica principal no la mide el motor** —depende del estado en SIGA— y requiere que BI la instrumente contra el resultado de las corridas del RPA.

## 13. Riesgos y supuestos

### Riesgos

| **Riesgo** | **Impacto potencial** |
| --- | --- |
| **Parte del histórico ya está activo.** Hubo una activación masiva hasta aproximadamente mediados de 2023, y posiblemente algunos contratos de 2024. | Si el motor alimenta al RPA con contratos que ya tienen orden de pago, se generan órdenes duplicadas sobre un volumen de ~60 mil contratos. El motor no puede detectarlo hoy: el estado de activación vive en SIGA, que no es insumo del MVP. **Es el riesgo más alto del proyecto** y está abierto en §14. |
| **Ambigüedad en la base de comparación de montos.** El monto total del DTE incluye IVA, mientras que los montos del Excel podrían ser netos. | Si se compara la suma del Excel contra el monto total del XML y los montos del Excel son netos, prácticamente todas las facturas se marcarían como `NO_CUADRA` por la diferencia del 19%, haciendo el reporte inservible y ocultando las discrepancias reales. |
| **El supuesto de correspondencia folio ↔ `FACTURA N°` no está verificado.** En Chile no existe un consecutivo de SIGA, y en Colombia el número de factura coincide en dígitos con el folio pero no en las letras. | Si la correspondencia no es 1:1, la asociación entre documentos y contratos es incorrecta y todo el reporte pierde validez. Debe medirse antes de operar. |
| **Los insumos del despacho pueden estar incompletos o desactualizados.** La entrega llegó hasta marzo o abril. | La regularización quedaría parcial y habría que repetir el ciclo, con el costo de coordinación que implica. |
| **Método de acceso a Drive sin definir.** | Bloquea la ejecución automatizada y, en Fase 3, la orquestación con n8n. |
| **Tratamiento de notas de crédito sin definir.** | Una nota de crédito no contemplada altera los montos conciliados y puede generar diferencias que se interpreten como errores del despacho. |
| **Desfase entre facturación y activación.** Las facturas chilenas tienen crédito a 30 días, y el pico de siniestralidad ocurre en el primer mes. | Existe una ventana estructural en la que el contrato está vigente, con siniestralidad alta, y todavía no activado. Es una característica del negocio, no un defecto del motor, pero condiciona las expectativas sobre la métrica de cobertura. |
| **El documento de orden de pago vigente en Chile es una plantilla de México.** | No aplica al proceso chileno y requiere ajuste propio, fuera del alcance de este motor pero en la misma cadena. |

### Supuestos

| **Supuesto** | **Descripción** |
| --- | --- |
| El Excel es la fuente de verdad | La relación contrato↔factura del Excel del despacho es correcta y completa. El XML y el PDF validan, no corrigen. |
| `ID` es el identificador de SIGA | Se asume que la columna `ID` del Excel es el identificador con el que el RPA busca el contrato en SIGA. **Pendiente de confirmar con Omar.** |
| Convención de nombres estable | Los archivos siguen el patrón `F{folio}T{tipo}.{ext}` y el folio del nombre corresponde al `FACTURA N°` del Excel. |
| El despacho mantiene la entrega mensual | El proceso recurrente depende de que el despacho deposite cada mes las facturas emitidas en la carpeta compartida. |
| Los tipos de DTE relevantes son 33 y 34 | Factura afecta y exenta. El tipo 61 (nota de crédito) existe pero su tratamiento está por definir. |
| El RUT emisor es constante | Todas las facturas provienen del mismo emisor (Garantiplus Chile SpA), lo que permite validarlo como control. |
| El motor procesa lo que exista | Los años faltantes (2024, 2022–2023) entran cuando el despacho los cargue; su ausencia no bloquea la operación sobre los años disponibles. |

## 14. Preguntas abiertas

| **Tema** | **Pregunta abierta** |
| --- | --- |
| **Contratos ya activos** | ¿Cómo se identifican los contratos que ya fueron activados en la carga masiva histórica, para excluirlos del feed del RPA? ¿Existe un export o una vista de SIGA con el estado de activación que el motor pueda consumir, o la validación la hace el RPA antes de generar cada orden? **Debe resolverse antes de correr el RPA sobre el histórico.** |
| **Montos** | ¿Los montos del Excel (`Importe`, `Monto a Facturar`) son netos o incluyen IVA? De ello depende contra qué campo del XML se concilian. |
| **Montos** | ¿Cuál es la tolerancia de redondeo aceptable en la conciliación? |
| **Identificadores** | ¿La columna `ID` del Excel es efectivamente el identificador con el que el RPA busca el contrato en SIGA? |
| **Identificadores** | ¿El folio del nombre de archivo (`F…T33`) corresponde 1:1 con el `FACTURA N°` del Excel? Considerando que en Chile no existe consecutivo de SIGA, ¿hay algún caso de desalineación conocido? |
| **Reglas de negocio** | ¿Qué líneas deben excluirse del feed por no ser garantías (reparaciones, cotizaciones, órdenes de compra)? ¿Los patrones identificados hasta ahora son suficientes? |
| **Reglas de negocio** | ¿Cómo se tratan las notas de crédito (DTE 61) y los contratos cancelados en la conciliación? |
| **Accesos** | ¿Qué método de autenticación se usa en producción para acceder a Drive: cuenta de servicio o credencial OAuth del orquestador? ¿Quién es el responsable de gestionarla? |
| **Cobertura** | ¿Cuándo entrega el despacho contable los Excel de 2024 y de 2022–2023? ¿Se confirma la entrega actualizada más allá de marzo/abril? |
| **Fase 2** | ¿Cuál es el formato, la fuente y la periodicidad del control de pagos? Está referenciado por número de factura y a la transacción, no por contrato. |
| **Salida** | ¿Cuáles son el nombre y la ubicación definitivos de la subcarpeta de resultados y de los archivos de salida? |
