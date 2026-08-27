# PRD - API de Averías de SIGA: capacidades requeridas para automatizar el ciclo de dictamen

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | API de Averías de SIGA — capacidades de lectura y escritura requeridas para automatizar el ciclo de dictamen de averías |
| **Área / empresa** | EngineCX (sistema afectado: SIGA; alcance operativo: México en las etapas 1–4, Colombia y Chile en la etapa 5) |
| **Versión** | v0.1 — **BORRADOR PARCIAL: 3 de 36 solicitudes especificadas** |
| **Fecha** | 2026-08-27 |
| **Autores** | Omar André Lara Saldaña (omar.lara@enginecx.com) |
| **Dirigido a** | Equipo de desarrollo de la API de SIGA *(interlocutor por confirmar, §14)* |
| **Revisión / liderazgo** | *(por confirmar, §14)* |
| **Tipo de proyecto** | Feature web/API |
| **Documento hermano** | `Desarrollos_internos/PJ1544-copiloto-averias/PRD.md` — el desarrollo que consume estas capacidades |

> ⚠️ **ESTADO DEL DOCUMENTO — NO ENTREGAR TODAVÍA.** Esta versión especifica **3 de las 36 solicitudes** (G11, G21, G19), elegidas como muestra de formato ya validada. Las 33 restantes están **inventariadas y clasificadas por etapa y severidad** en `transcripts-resumidos/inventario-huecos-api.md`, pero **les falta el detalle técnico**: ruta, cuerpo de petición y respuesta, códigos de error, permisos y criterios de aceptación. Además hay **13 verificaciones en runtime pendientes** porque el entorno QA estuvo caído (§14). No entregar al equipo de SIGA hasta completar ambas cosas.
>
> **Cómo leer este documento.** Cada capacidad solicitada lleva un identificador `G-NN`, la etapa que desbloquea, la evidencia de su estado actual y un contrato de endpoint propuesto. **La numeración de los `G-NN` es estable**: sirve para responder punto por punto.
>
> **Sobre el estado actual.** Todo lo que este PRD afirma sobre la API está **verificado** contra los OpenAPI publicados en `qa-siga-api.garantiplus.com`, capturados el 2026-08-26 y contrastados con la captura del 2026-08-24. Cuando algo no se pudo verificar, se dice explícitamente en lugar de suponerlo.
>
> **Sobre los nombres propuestos.** Las rutas, campos y códigos que aquí se proponen son una **propuesta de forma, no una imposición**. Lo que el desarrollo necesita es la capacidad y su semántica; la nomenclatura es del equipo que mantiene la API. Lo único no negociable son las **reglas de integridad** que cada capacidad debe garantizar, marcadas como tales.

## 1. Resumen ejecutivo

EngineCX está construyendo el **Copiloto de Averías**: una automatización que, al momento en que SIGA asigna una avería a un técnico, reúne el expediente, dictamina la procedencia contra el condicionado del contrato y le entrega a esa persona el veredicto razonado y el documento de resolución ya capturado. El desarrollo se apoya por completo en la API de SIGA como fuente de verdad.

**La primera etapa no requiere ningún cambio en la API y arranca de inmediato.** Eso es deliberado: la lectura que la API ya expone —contratos por VIN, detalle del vehículo, texto del certificado, averías, y documentos de evidencia descargables— alcanza para dictaminar y documentar. El desarrollo entrega valor antes de que este documento se atienda.

**Las cuatro etapas siguientes sí dependen de capacidades que hoy no existen.** Este PRD las inventaría: **36 solicitudes en 6 grupos**, cada una atada a la etapa que desbloquea, con su evidencia y su contrato propuesto. **Diez son bloqueantes**: sin ellas la etapa correspondiente no se puede construir de ninguna forma.

**El bloqueo principal es que no se puede resolver una avería por API.** `ClaimResponse.statusId` es un campo de respuesta y el único `status` escribible del servicio pertenece a `UpdateIssue`, que opera sobre incidencias, no sobre averías. Hoy el sistema puede dictaminar y redactar la resolución, pero un técnico tiene que entrar a la plataforma a marcar el resultado a mano.

**Por qué vale la pena.** En México, entre enero y julio de 2026 entraron **1 582 averías y 604 (38.2%) terminaron en `No procede garantía`**. De esos rechazos, **330 (54.6%)** responden a cuatro causales verificables contra el texto del contrato —intervalo de mantenimiento excedido 29.1%, componente excluido 15.7%, fuga excluida 6.8%, sin vigencia 3.0%—, es decir **una de cada cinco averías del país**. Son expedientes que hoy se trabajan completos: crear, descargar información, generar la resolución, teclear los datos, enviar. El objetivo de negocio es que la operación de los tres países pueda ejecutarse desde México, lo que exige **entre 45% y 75% más de capacidad por persona**.

**Tres notas sobre el enfoque de este documento.** Primera: **no se pide nada que ya exista**; cada ausencia está probada por conteo exhaustivo sobre el JSON del contrato, no por búsqueda manual. Segunda: **varias solicitudes son correcciones de documentación**, no funciones nuevas, y están marcadas como tales porque son las más baratas de atender. Tercera: **este documento no pide cambios en la interfaz de SIGA** ni en su lógica de negocio; pide exponer por API lo que la plataforma ya hace.

## 2. Contexto y problema

### 2.1 El proceso que se quiere automatizar

1. El cliente lleva el vehículo a la agencia. En más del 90% de los casos llega **sin llamar antes**.
2. **La agencia registra la avería en SIGA** y sube evidencia. La plataforma exige al menos un documento en cada uno de tres tipos —evidencias, presupuesto, fotos de odómetro— antes de dejarla avanzar.
3. SIGA **asigna la avería a un técnico** por round-robin y **le envía un correo** con el asunto `Asignación de avería {folio} / Vin {VIN}`. **Ese correo trae solo folio y VIN**: es la única llave con la que arranca la automatización.
4. La agencia pasa la avería a **`Validación`**. Ahí arranca el compromiso contractual de **48 horas hábiles** —cláusula 10 del certificado— y solo entonces el técnico puede trabajarla.
5. El técnico descarga el certificado, revisa la evidencia y **dictamina `Aceptada` o `No procede garantía`**. Es el único tramo de estatus que el área técnica puede mover.
6. Redacta la **resolución** en un formato de Word externo a la plataforma, tecleando a mano folio, contrato, fecha, marca, modelo y datos de la unidad **que ya están en pantalla**, y la sube al expediente. Ese documento tiene **valor legal**: la agencia se lo entrega al cliente.
7. Si fue aceptada, la agencia mueve `Taller` → `Solucionada` y se procesa el pago.

### 2.2 Las cinco etapas y qué bloquea cada una

| Et. | Qué automatiza el Copiloto | Escritura en SIGA | Solicitudes que la desbloquean |
| :-: | --- | --- | --- |
| **1** | Reúne el expediente, dictamina, redacta la resolución de improcedencia y entrega la plantilla capturada en todos los casos | **Ninguna** | **Ninguna bloqueante.** G11–G20 la mejoran |
| **2** | Sube la resolución y marca `No procede garantía` | Documento + estatus, solo improcedencias | **G21** ⛔, G22, **G23** ⛔, G24, G25, **G04** ⛔, **G06** ⛔ |
| **3** | Valida cobertura, verifica que el presupuesto cuadre, propone autorizar; el técnico aprueba caso por caso | `Aceptada`, solo tras aprobación humana | **G26** ⛔, **G27** ⛔, **G28** ⛔, G29 |
| **4** | El humano revisa un expediente ya armado en lugar de construirlo | Igual que la etapa 3 | G30, G31, G32 |
| **5** | Colombia y Chile operados desde México | Igual, por país | **G33** ⛔, G34 |

### 2.3 Tres reglas de integridad que la forma de los endpoints debe garantizar

No son preferencias de diseño: son restricciones que el Copiloto tiene que poder cumplir, y **la forma del endpoint decide si son cumplibles o si dependen de que el cliente se porte bien**. Se piden verificadas del lado del servidor.

| Regla | Por qué | Qué implica para el endpoint |
| --- | --- | --- |
| **Ningún rechazo sin resolución adjunta** | Es el antipatrón que ya existe hoy: cuando un distribuidor captura solo refacciones no cubiertas, la plataforma rechaza y cierra la avería **sin cargar resolución ni información alguna**, y cuando la agencia reclama nadie sabe qué contestar | El endpoint de resolución debe **exigir la referencia al documento** y rechazar la operación si no existe. **G21** |
| **Ninguna autorización sin un humano identificado** | Un rechazo mal fundado se reclama y se corrige; una autorización mal fundada se paga. El Copiloto nunca autoriza por sí mismo | El endpoint de aceptación debe **exigir un campo de atribución de la persona que aprobó**, distinto de la identidad que llama. **G23**, **G28** |
| **Ningún fallo silencioso** | Un filtro con el nombre de propiedad equivocado hoy devuelve **una lista vacía con HTTP 200**, indistinguible de "no hay resultados" | Nomenclatura documentada y consistente, y error explícito ante propiedad desconocida. **G06** |

### 2.4 Estado actual verificado

**Cuatro microservicios**, y solo cuatro: `authentication`, `catalogs`, `contracts`, `claims`. Se probaron y descartaron quince nombres más —`payments`, `reports`, `notifications`, `documents`, `users`, `sales`, `policies`, `vehicles`, `workshops`, `dealers`, `audit`, `files`, `storage`, `integrations`, `webhooks`—, todos 404.

**Ausencias confirmadas por conteo exhaustivo de cadenas sobre el JSON completo del spec de `claims`:**

| Cadena | Ocurrencias | Conclusión |
| --- | :-: | --- |
| `reason` | **0** | No existe el motivo de rechazo en ninguna entidad |
| `history` | **0** | No existe historial de estatus |
| `followup`, `comment`, `seguimiento`, `observacion` | **0** | El seguimiento de la avería no está expuesto, aunque la plataforma lo tiene en la interfaz y notifica por correo |
| `labor`, refacciones | **0** | No hay mano de obra ni refacciones |
| `budget` | **1** | Solo en la prosa descriptiva del servicio; no hay endpoint |
| `odomet` | 9 | **Todas en incidencias.** Ninguna en `ClaimResponse` |

**Lo que la API sí entrega hoy, y que hace posible la etapa 1:** contrato filtrable por VIN, detalle completo del vehículo, **texto extraído del certificado** (`GetContractPdfDataById`), avería con su descripción y estatus, y listado y descarga de la evidencia cargada.

### 2.5 Coherencia con el propósito declarado del propio servicio

Estas solicitudes no introducen un caso de uso ajeno: **completan lo que la documentación del servicio ya promete.**

- La descripción de `claims` dice que permite *"register claims, upload supporting documentation, and **monitor claim status**"*, ofrece *"Document management for claims (budgets, **resolutions**, photographic/video evidence)"* y *"**Claims tracking and reporting** with flexible filtering"*, con *"Multi-role access control (workshops, **technicians**, **coordinators**, administrators)"*. Sin embargo no expone escritura de estatus, ni historial, ni motivo, ni presupuesto.
- La API **ya está diseñada contemplando un agente automatizado**: `ConvertToClaim` documenta *"Human action — the agent never converts automatically"*, y `CreateIssueRequest.odometer` dice *"Already converted to a number by the conversational agent (from text, photo, or voice note)"*. El consumidor que este PRD representa ya estaba previsto.
- **Multi-país ya es el plan declarado**: *"Multi-country support (currently MEX, expandable to other markets)"*. La etapa 5 se apoya en esa intención, no la inventa.

## 3. Objetivo

Exponer por API las capacidades que faltan para que el ciclo de dictamen de una avería —desde la asignación hasta la resolución sustentada en el expediente— pueda ejecutarse sin intervención manual de captura, conservando en manos de una persona toda decisión con efecto económico.

El resultado se mide por **capacidades entregadas y verificadas contra los criterios de aceptación** de cada solicitud (§12), y por las etapas del Copiloto que quedan desbloqueadas.

### 3.1 Fases de entrega sugeridas

| Fase | Contenido | Desbloquea |
| --- | --- | --- |
| **A — Correcciones y confirmaciones** | Lo que probablemente no requiere desarrollo: homologar la nomenclatura OData documentada, confirmar el tipo de documento de resolución, publicar los límites de tasa y el formato de fechas. **Es la fase más barata y la más urgente** | Elimina riesgo de la etapa 1 |
| **B — Lectura completa del expediente** | Consulta singular de avería, campos faltantes, catálogos de estatus y motivos, componente reclamado, historial y fecha de paso a validación | Etapa 1 al 100% |
| **C — Resolución de averías** | Resolver una avería con motivo, comentario, referencia al documento y atribución. Idempotencia y auditoría | **Etapa 2** |
| **D — Datos económicos** | Presupuesto desglosado, límites e importes del vehículo, aceptación con detalle de lo autorizado | **Etapa 3** |
| **E — Operación y escala** | Seguimiento, agregación, estado de pago, y alcance de Colombia y Chile | Etapas 4 y 5 |

## 4. Usuarios y actores

| Actor | Rol frente a la API |
| --- | --- |
| **Orquestador (n8n)** | Consumidor principal. Autentica como identidad de servicio, lee el expediente y ejecuta las escrituras acotadas de su etapa |
| **Agente de cobertura** | Solo lectura, a través del orquestador. Consume el condicionado y la evidencia. Nunca llama a la API directamente |
| **Agente de presupuesto** | Aparece en la etapa 3. Solo lectura. Consume el presupuesto desglosado y los límites del contrato |
| **Técnico de averías** | No consume la API directamente. Es quien **aprueba** las autorizaciones, y su identidad debe viajar en la escritura correspondiente |
| **Identidad de servicio** | El sujeto que autentica. **Hoy no existe**: solo hay login de persona con usuario y contraseña |
| **Equipo de desarrollo de SIGA** | Destinatario de este documento. Único que puede exponer las capacidades solicitadas |

---

## 5. Solicitudes

Cada solicitud lleva un identificador estable `G-NN` para poder responder punto por punto. La severidad indica qué pasa si no se atiende: **⛔ bloqueante** — la etapa no se puede construir de ninguna forma; **⚠ degrada** — hay una alternativa peor, funciona con costo en exactitud o en diagnóstico; **★ alto valor** — no bloquea, pero cambia cualitativamente lo que el sistema puede garantizar.

### Estado de especificación

| Grupo | Solicitudes | Especificadas | Pendientes de detallar |
| --- | :-: | :-: | --- |
| **0 — Plataforma y transversal** | G01–G10 | 0 | G01–G10 |
| **1 — Lectura del expediente** | G11–G20 | 2 (G11, G19) | G12–G18, G20 |
| **2 — Escritura de improcedencia** | G21–G25 | 1 (G21) | G22–G25 |
| **3 — Caso procedente** | G26–G29 | 0 | G26–G29 |
| **4 — Alta carga** | G30–G32, G35, G36 | 0 | G30–G32, G35, G36 |
| **5 — Operación regional** | G33–G34 | 0 | G33–G34 |

**Dos solicitudes añadidas el 2026-08-27**, derivadas de requisitos ya establecidos y aún sin especificar:

- **G35 · Catálogo de técnicos** — etapa 4. La métrica central del proyecto es *averías por persona y por día*, y la cola priorizada se ordena por técnico. Hoy `ClaimResponse` trae `technicianId` y `technicianName`, pero no existe el padrón: no hay forma de saber quién está activo ni de correlacionar un buzón de correo con un `technicianId`. `GetAllAdvisors` es de asesores de venta, no de técnicos.
- **G36 · Marca de origen del dictamen** — etapa 2. El área pidió expresamente que las averías resueltas automáticamente no se asignen a un técnico pero **sí se midan aparte**: *"lo ideal sería medirlas bajo otro parámetro"*. Sin un campo que distinga dictamen automático de humano, esos casos se mezclan con la carga del equipo y el indicador de desempeño queda corrupto.

### Muestra de formato — tres solicitudes a profundidad final

*Las tres cubren el rango completo: una trivial, el bloqueo principal y la más compleja. **El formato de estas tres está validado**; es el que deben seguir las 33 restantes.*

## G11 · Consulta singular de una avería — etapa 1 · ⚠ degrada

**Paso del proceso que lo necesita:** paso 3. El correo de asignación trae un folio; hay que traer esa avería y solo esa.

**Por qué es necesario.** Hoy la única vía es filtrar la colección `GetClaims`. Eso obliga a interpretar una lista para saber si el caso existe: cero resultados es ambiguo —puede ser que la avería no exista, que el filtro use un nombre de propiedad equivocado, o que la identidad no tenga permiso—. Con una consulta singular, esos tres casos se distinguen por código de respuesta.

**Estado actual verificado.** No existe. El servicio tiene `GET /api/Issues/v1/GetIssueById/{id}` para incidencias, pero para averías solo la colección `GET /api/Claims/v1/GetClaims`. Es una asimetría del modelo, no una decisión documentada.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetClaimById/{claimId}`
- **Petición:** sin cuerpo. `claimId` entero en la ruta.
- **Respuesta 200:** el mismo `ClaimResponse` que devuelve la colección, con los campos de **G12** si se atienden.
- **Errores:**
  - `401` sin token válido.
  - `403` la identidad no tiene permiso sobre esa avería.
  - `404` la avería no existe.
- **Permisos:** cualquier rol que hoy pueda ver la avería en `GetClaims`.
- **Idempotencia:** no aplica, es lectura.
- **Efectos colaterales:** ninguno.

**Criterios de aceptación**

1. Con un `claimId` existente y permiso, devuelve `200` y un solo objeto, no un arreglo.
2. Con un `claimId` inexistente devuelve `404`, **nunca** `200` con cuerpo vacío.
3. Con un `claimId` existente pero fuera del alcance de la identidad, devuelve `403` y no `404`, para que el consumidor distinga "no existe" de "no puedo verlo".

**Si no se atiende.** El Copiloto sigue filtrando la colección. Funciona, pero no puede distinguir con certeza entre avería inexistente y error de consulta, lo que degrada el diagnóstico de excepciones.

## G21 · Resolver una avería — etapa 2 · ⛔ BLOQUEANTE

**Paso del proceso que lo necesita:** paso 5. Es el dictamen: pasar de `Validación` a `Aceptada` o a `No procede garantía`.

**Por qué es necesario.** Es **el bloqueo principal de todo el proyecto**. Sin esta capacidad el Copiloto puede reunir el expediente, dictaminar y redactar la resolución, pero un técnico tiene que entrar a la plataforma a marcar el resultado a mano. En México eso son **604 expedientes al año** solo del lado del rechazo, de los cuales **330 tienen causal verificable** contra el texto del contrato.

**Estado actual verificado.** No existe ninguna vía de escritura sobre el estatus de una avería. `ClaimResponse.statusId` aparece únicamente como campo de respuesta. El único `status` escribible del servicio es `UpdateIssueRequest.status`, que opera sobre **incidencias**, una entidad distinta. La cadena `reason` no aparece **ninguna vez** en el spec completo, así que tampoco existe dónde registrar el motivo.

**Lo que se pide**

- **Método y ruta:** `PATCH /api/Claims/v1/ResolveClaim/{claimId}`

  Un solo endpoint para los dos desenlaces, porque es una sola transición de negocio y el área técnica solo puede mover ese tramo. Si el equipo prefiere dos rutas separadas, la semántica y las reglas de integridad son las mismas.

- **Cabeceras:** `Idempotency-Key` obligatoria (**G04**).

- **Petición:**

  | Campo | Tipo | Obligatorio | Notas |
  | --- | --- | :-: | --- |
  | `targetStatusId` | int | **sí** | Solo se aceptan los de `Aceptada` y `No procede garantía`, del catálogo de **G14** |
  | `rejectionReasonId` | int | **condicional** | **Obligatorio** cuando el destino es `No procede garantía`. Del catálogo de **G15** |
  | `resolutionDocumentId` | int | **sí** | Documento ya cargado en el expediente vía `UploadClaimDocument`. **Regla de integridad** |
  | `comment` | string | **sí** | Sustento del dictamen, en texto libre. Es lo que hoy se escribe en el seguimiento |
  | `approvedBy` | string | **condicional** | **Obligatorio** cuando el destino es `Aceptada` (**G23**). Identificador de la persona que aprobó |

- **Respuesta 200:**

  ```json
  {
    "claimId": 3246,
    "previousStatus": "Validación",
    "status": "No procede garantía",
    "rejectionReason": "Intervalo de Mantenimiento Excedido",
    "resolutionDocumentId": 91733,
    "resolvedAt": "2026-08-27T10:14:22-06:00",
    "resolvedBy": "svc-copiloto-averias",
    "approvedBy": null,
    "alreadyResolved": false
  }
  ```

  `alreadyResolved: true` cuando la llamada se repite con la misma `Idempotency-Key`, devolviendo el resultado original sin volver a aplicarlo.

- **Errores — cada uno distinguible, ninguno silencioso:**

  | Código | Cuándo |
  | --- | --- |
  | `400` | Cuerpo mal formado o `targetStatusId` fuera de los dos permitidos |
  | `401` | Sin token válido |
  | `403` | La identidad no tiene el permiso de resolución |
  | `404` | La avería no existe |
  | `409` | La avería **no está en `Validación`**. El cuerpo debe indicar el estatus actual |
  | `422` | Falta `rejectionReasonId` al rechazar, falta `approvedBy` al aceptar, o `resolutionDocumentId` no existe o no pertenece a esa avería |

- **Permisos:** rol de área técnica —técnico o coordinador— y el rol de servicio de **G03**. Explícitamente **no** los roles de taller ni de distribuidor.

- **Idempotencia:** obligatoria por `Idempotency-Key`. Un reintento por timeout **no debe** producir una segunda resolución.

- **Efectos colaterales esperados:** la misma notificación por correo que la plataforma ya emite hoy cuando el técnico dictamina, y una entrada de auditoría (**G25**). El Copiloto **no** quiere sustituir esas notificaciones: quiere que sigan ocurriendo igual que cuando dictamina una persona.

**Criterios de aceptación**

1. Resolver una avería en `Validación` con todos los campos válidos devuelve `200` y el estatus queda cambiado en la plataforma.
2. Resolver con destino `No procede garantía` **sin** `rejectionReasonId` devuelve `422` y **no** cambia nada.
3. Resolver **sin** `resolutionDocumentId` válido devuelve `422` y **no** cambia nada. *(Esta es la regla que evita el rechazo sin resolución.)*
4. Resolver con destino `Aceptada` **sin** `approvedBy` devuelve `422` y **no** cambia nada.
5. Resolver una avería que ya está en `Aceptada`, `Cerrada` o `Taller` devuelve `409` e indica el estatus actual.
6. Repetir la llamada con la misma `Idempotency-Key` devuelve `200` con `alreadyResolved: true` y **no** produce un segundo cambio ni una segunda notificación.
7. Un token con rol de taller o distribuidor recibe `403`.
8. Tras la operación, la avería consultada por `GetClaims` refleja el nuevo estatus **y** el motivo.

**Si no se atiende.** La etapa 2 no existe. El Copiloto queda en modo solo-propuesta: dictamina, redacta y avisa, pero el técnico entra a marcar a mano. Se conserva el valor del análisis y de la captura, y se pierde el cierre del ciclo. **La etapa 3 también queda bloqueada**, porque depende de la misma capacidad del lado de la aceptación (**G28**).

## G19 · Condicionado del contrato como datos — etapa 1 · ★ alto valor

**Paso del proceso que lo necesita:** paso 5, el dictamen. Es la norma contra la que se decide si una avería procede.

**Por qué es necesario.** Es la solicitud de mayor impacto de todo el documento. El condicionado hoy existe solo como **prosa dentro de un PDF**, así que el dictamen depende de que un modelo de lenguaje lea correctamente un documento escaneado y localice la cláusula aplicable. Con el condicionado como datos, la causal de rechazo **número uno** —intervalo de mantenimiento excedido, **29.1% de los rechazos de México**— se resuelve con **aritmética de fechas y kilómetros** en lugar de interpretación de texto. Lo mismo para vigencia, periodo de espera, ámbito geográfico y límites.

Dicho de otro modo: esta capacidad convierte una parte sustancial del dictamen de **probabilístico a determinista**. Es la diferencia entre un sistema que hay que auditar caso por caso y uno que se puede verificar por construcción.

**Estado actual verificado.** No existe. `GetContractPdfDataById` devuelve el certificado como **texto extraído** —lo cual es valioso y hace posible la etapa 1—, pero es prosa. `ContractInfo` trae precio, impuestos y total **del contrato**, no los límites de cobertura. `VehicleInfo.timelyServices` es un booleano capturado en la venta, no un régimen de mantenimiento. Ningún endpoint expone exclusiones ni operaciones no incluidas.

*Nota de honestidad: la completitud del texto que devuelve `GetContractPdfDataById` está **pendiente de verificar en runtime** (el entorno QA estuvo caído). Si ese texto resultara incompleto o inestable, esta solicitud pasa de alto valor a **bloqueante de la etapa 1**, porque no habría ninguna vía al condicionado.*

**Lo que se pide**

- **Método y ruta:** `GET /api/Contracts/v1/GetContractCoverage/{contractId}`
- **Petición:** sin cuerpo.
- **Respuesta 200:** el condicionado del contrato concreto, estructurado. Los `clauseRef` permiten citar la cláusula textual en la resolución, que es un requisito legal del documento que se entrega al cliente.

  ```json
  {
    "contractId": 795713,
    "productName": "EXCELLENCE TT GM",
    "coverageModel": "todo-salvo-excluido",
    "validity": {
      "startDate": "2026-08-12",
      "endDate": "2027-08-11",
      "waitingPeriodDays": 0,
      "geographicScope": "MEX",
      "clauseRef": "3, 5"
    },
    "maintenanceRegime": {
      "vehicleCategory": "seminuevo",
      "intervalMonths": 6,
      "intervalKilometers": 10000,
      "criterion": "whichever-first",
      "requiresManufacturerAuthorizedDealer": true,
      "acceptedProof": ["carnet-sellado", "facturas"],
      "clauseRef": "9"
    },
    "limits": {
      "perClaimLimitType": "vehicle-sale-value",
      "perClaimLimitAmount": null,
      "contractLimitType": "vehicle-sale-value",
      "contractLimitAmount": null,
      "vehicleSaleValue": 285000.00,
      "valuationSource": "Libro Azul",
      "currency": "MXN",
      "clauseRef": "11"
    },
    "excludedElements": [
      { "code": "CONSUMIBLES", "label": "Consumibles: filtros, aceite, juntas, amortiguadores, escapes, discos y pastillas de freno, correas, bujías, batería, plumas", "clauseRef": "1" },
      { "code": "CARROCERIA", "label": "Totalidad de los elementos de carrocería", "clauseRef": "1" }
    ],
    "excludedOperations": [
      { "code": "FUGAS", "label": "Fugas de aceite, refrigerante o combustible", "clauseRef": "13.6" },
      { "code": "DESGASTE", "label": "Piezas al final de su vida útil por función y usabilidad natural", "clauseRef": "13.4" },
      { "code": "RUIDOS", "label": "Ruidos, vibraciones y traqueteos no derivados de rotura fortuita", "clauseRef": "13.31" }
    ],
    "generalExclusions": [
      { "code": "DOC_72H", "label": "Documentación no aportada dentro de las 72 h tras ser requerida", "clauseRef": "12.4" },
      { "code": "KM_INCOHERENTE", "label": "Los kilómetros de inicio del contrato no guardan relación con los de la avería", "clauseRef": "12.5" }
    ],
    "coveredComponents": null,
    "documentationRequirements": {
      "responseDeadlineBusinessHours": 48,
      "documentationDeadlineHours": 72,
      "required": ["orden-de-entrada", "presupuesto-sin-desmontar", "libro-de-mantenimiento", "facturas-de-inspecciones"],
      "clauseRef": "10"
    },
    "certificateVersion": "2026-08-12T15:08:21",
    "source": "condicionado-producto"
  }
  ```

  Notas sobre el diseño de la respuesta:
  - `coverageModel` distingue los dos productos de México: `todo-salvo-excluido` para `Excellence` (el 95% de la cartera) y `nominado` para `Expert`, que sí trae lista de 120 componentes cubiertos. En el modelo nominado, `coveredComponents` viene poblado y las listas de exclusión pueden venir vacías.
  - Los `code` deben ser **estables y comparables entre contratos**; las `label` son para citar en el documento.
  - `perClaimLimitAmount` en `null` con `perClaimLimitType: "vehicle-sale-value"` expresa el caso real del certificado de muestra, donde el límite es el valor del vehículo y no una cifra fija.

- **Errores:** `401`; `403` fuera de alcance; `404` contrato inexistente; `409` si el contrato no tiene condicionado modelado —caso legítimo durante la transición, y el consumidor debe poder distinguirlo de un error.
- **Permisos:** los mismos que hoy permiten leer el contrato.
- **Idempotencia:** no aplica, es lectura.
- **Efectos colaterales:** ninguno.

**Criterios de aceptación**

1. Para un contrato `Excellence`, la respuesta trae `maintenanceRegime` con intervalo en meses y en kilómetros y con el criterio de cuál aplica primero.
2. Para un contrato `Expert`, `coverageModel` es `nominado` y `coveredComponents` viene poblado.
3. Todo elemento de las listas de exclusión trae un `clauseRef` que corresponde a una cláusula real del certificado de ese contrato.
4. Los `code` son idénticos entre dos contratos del mismo producto.
5. Si el contrato no tiene condicionado modelado, devuelve `409` y **no** un `200` con listas vacías. *(Un `200` con listas vacías haría que el Copiloto concluyera "no hay exclusiones" y autorizara indebidamente: es el fallo silencioso más peligroso de todo el sistema.)*
6. `vehicleSaleValue` viene con su moneda y su fuente de valuación.

**Si no se atiende.** La etapa 1 funciona leyendo el texto del certificado, con dos costos. Primero, la causal de mayor volumen se dictamina interpretando prosa, lo que obliga a un umbral de confianza muy alto y manda a revisión humana muchos casos que serían mecánicos. Segundo, el sistema no puede citar la cláusula con garantía de exactitud, y la resolución que se entrega al cliente tiene valor legal. **Si además el texto del certificado resultara incompleto, la etapa 1 no sería viable.**


## 14. Preguntas abiertas

### Pendientes de verificación en runtime — el entorno QA estuvo caído

El 2026-08-27 todo `qa-siga-api.garantiplus.com` devolvía `503` con `server: awselb/2.0`. Doce puntos se resuelven con el script `verificar-api.py` en cuanto vuelva; tres hay que preguntarlos a personas. **Cuatro pueden tumbar la etapa 1** si salen mal.

| # | Pendiente | Riesgo |
| :-: | --- | --- |
| **V1** | ¿`ClaimResponse` devuelve `vinOrPlate` y `odometer` aunque el esquema no los declare? | Cambia G12 de función nueva a corrección de documentación |
| **V2** | ¿El filtro OData es `claimId` o `IdAveria`? | 🔴 Si ninguno funciona, no hay forma de consultar una avería por folio |
| **V3** | ¿Existe ya el tipo de documento "Resolución"? | Elimina G22 o lo vuelve bloqueante de la etapa 2 |
| **V4** | ¿`GetContractPdfDataById` devuelve el certificado completo y fiel? | 🔴 Si es incompleto, **G19 sube a bloqueante de la etapa 1** |
| **V5** | ¿`GetAllContracts` acepta `$filter=vin eq '...'`? | 🔴 El VIN es la única llave que trae el correo |
| **V6** | ¿Existe alguna ruta de escritura sobre averías no documentada? | Podría desbloquear la etapa 2 sin esperar |
| **V7** | ¿`$apply` funciona en los listados? | Determina si G31 es necesario |
| **V8** | ¿Qué roles concretos devuelve `GetAllRoles`? | Permite nombrar el rol de servicio con su nomenclatura |
| **V9** | ¿El folio del correo coincide con el `claimId`? | 🔴 Sin correspondencia no se localiza el caso |
| **V12** | ¿Se llega al odómetro y VIN por la incidencia asociada? `IssueResponse` trae `vinOrPlate`, `odometer` y `claimId` | **Podría eliminar G12** |
| **V10** | ¿Existe plan para las APIs de Colombia y Chile? — preguntar a TI | Determina si G33 se pide ahora |
| **V11** | ¿El folio del correo es el que ve el técnico en pantalla? — preguntar a David Simancas | Confirma V9 desde la operación |
| **V13** | ¿Cómo se da de alta una identidad de servicio hoy? — preguntar a TI | Define cómo se redactan G01 y G03 |

**Regla de interpretación de códigos**, para no pedir de más: las cuentas de prueba disponibles son de **taller** y de **distribuidor**, no de técnico. Un `403` significa *"existe pero esta cuenta no tiene permiso"*, **no** *"no existe"*. Solo un `404` o `405` autoriza a pedir algo como función nueva; un `400` o `422` significa que existe y valida la entrada, y solo hay que documentar el contrato.

### Gobierno de la entrega

- **D6 — ¿Quién es el destinatario y quién el patrocinador?** Confirmar si el interlocutor es Alexis y quién de EngineCX respalda la entrega. Es el único punto de las decisiones D1–D6 que sigue abierto.
- ¿Se entrega el documento completo de una vez, o se acuerda antes una sesión para presentar las diez solicitudes bloqueantes?
- ¿Hay un plazo objetivo para la fase A —las correcciones y confirmaciones, que probablemente no requieren desarrollo—?
