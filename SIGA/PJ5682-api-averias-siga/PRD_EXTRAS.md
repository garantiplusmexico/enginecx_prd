# PRD_EXTRAS - API de Averías de SIGA: las 25 solicitudes que mejoran el sistema

| **Campo** | **Detalle** |
| --- | --- |
| **Proyecto** | API de Averías de SIGA — solicitudes complementarias |
| **Área / empresa** | EngineCX (sistema afectado: SIGA) |
| **Versión** | v1.0 — final para revisión |
| **Fecha** | 2026-08-27 |
| **Autores** | Omar André Lara Saldaña (omar.lara@enginecx.com) |
| **Dirigido a** | Alexis Salvador Herrera García — Equipo de desarrollo de la API de SIGA |
| **Tipo de proyecto** | Feature web/API |
| **Documento principal** | `PRD.md` — las **11 capacidades imprescindibles**. Lee ese primero |

> **Este documento es el complemento, no la petición principal.** Las once capacidades sin las cuales el Copiloto de Averías no puede funcionar están en `PRD.md`. **Ninguna de las 25 que aquí se describen bloquea el desarrollo**: todas tienen una alternativa peor que ya está prevista, y cada ficha dice cuál es.
>
> **Por qué existe entonces.** Tres razones. Primera, **honestidad de alcance**: se analizó la API completa y estas 25 son lo que se encontró; ocultarlas para que la lista pareciera más corta habría sido engañoso. Segunda, **varias son casi gratis** —corregir documentación, añadir un campo, publicar una política— y conviene que estén sobre la mesa cuando se toque el código de al lado. Tercera, **cuatro son indispensables para etapas posteriores** del Copiloto, y es mejor conocerlas ahora que descubrirlas dentro de seis meses.
>
> **Todo lo aquí afirmado está verificado** contra los OpenAPI publicados en `qa-siga-api.garantiplus.com`, capturados el 2026-08-26. Los nombres propuestos son una propuesta de forma, no una imposición.

## 1. Resumen: qué hay aquí y qué prioridad tiene

**Cuatro de las 25 son bloqueantes de etapas futuras**, no del desarrollo actual:

| ID | Solicitud | Bloquea | Cuándo importa |
| --- | --- | --- | --- |
| **G30** | Agregar seguimiento a la avería | Etapa 4 · RF-62 | Cuando el Copiloto deba pedirle al taller la documentación de pago |
| **G32** | Estado de pago y comprobante | Etapa 4 · RF-63 | Cuando deba vigilar el expediente tras la aceptación |
| **G33** | Contratos y averías de Colombia y Chile | Etapa 5 completa | Cuando la operación se centralice en México. **Depende de una entrega de plataforma sin fecha** |
| **G34** | Catálogos por país normalizados | Etapa 5 completa | Junto con G33 |

**Nueve son casi gratis** — documentación, confirmaciones o un solo campo:

| ID | Solicitud | Por qué es barata |
| --- | --- | --- |
| **G02** | Refresco de token | O se crea el endpoint, **o se quita el campo `refreshToken`** de la respuesta, que hoy se emite sin poder canjearse |
| **G07** | Límites de tasa publicados | Publicar umbrales que ya existen |
| **G08** | Formato de fechas y zona horaria | Documentar lo que el servicio ya hace |
| **G10** | Política de versionado | Publicar un acuerdo, no construir |
| **G11** | Consulta singular de una avería | Existe para incidencias; es simetría del modelo |
| **G12** | Campos faltantes en la avería | **Puede que ya funcione**; si no, el dato existe en la entidad hermana |
| **G14** | Catálogo de estatus | Once valores que hoy viven en la cabeza de las personas |
| **G17** | Identificador de tipo en documentos | Un campo, y el catálogo ya existe |
| **G18** | Garantía de completitud del certificado | Una garantía por escrito, no código |

**Dos son de alto valor y cambian lo que el sistema puede garantizar:** **G19** (el condicionado como datos, que volvería determinista la causal del 29.1% de los rechazos) y **G05** (webhooks, que eliminarían la dependencia de leer buzones de correo de personas).

**Las diez restantes** son mejoras de exactitud, trazabilidad y operación.

## 2. Las 25 solicitudes

Cada una sigue la misma estructura del documento principal: paso del proceso que la necesita, por qué, **estado actual verificado**, contrato propuesto, criterios de aceptación y **consecuencia concreta de no atenderla**. Ese último apartado es lo que permite posponer cualquiera con criterio.

### Índice

| Grupo | Solicitudes |
| --- | --- |
| **A** — Plataforma — cómo consume la API un sistema automatizado | **G01** Identidad de máquina · **G02** Refresco de token · **G05** Eventos de avería (webhooks) · **G07** Límites de tasa publicados · **G08** Formato de fechas y zona horaria explícitos · **G09** Entorno de pruebas con datos representativos · **G10** Política de versionado y deprecación |
| **B** — Lectura del expediente — lo que haría el dictamen más exacto | **G11** Consulta singular de una avería · **G12** Campos faltantes en la avería · **G13** Fecha de paso a validación e historial de estatus · **G14** Catálogo de estatus de avería · **G17** Identificador de tipo en los documentos · **G18** Garantía de completitud del texto del certificado · **G19** Condicionado del contrato como datos · **G20** Lectura del seguimiento de la avería |
| **C** — Gobierno de la escritura — corrección y auditoría | **G24** Corregir o revertir un dictamen · **G25** Auditoría consultable |
| **D** — Operación de alta carga — cerrar el ciclo hasta el pago | **G29** Histórico de casos por componente · **G30** Agregar seguimiento a la avería · **G31** Consulta agregada de la cola de trabajo · **G32** Estado de pago y comprobante del expediente · **G35** Catálogo de técnicos · **G36** Marca de origen del dictamen |
| **E** — Operación regional — Colombia y Chile | **G33** Contratos y averías de Colombia y Chile · **G34** Catálogos por país, normalizados |

### A. Plataforma — cómo consume la API un sistema automatizado

#### G01 · Identidad de máquina — etapa 2 · ⚠ degrada

**Paso del proceso que lo necesita:** todos. Es cómo autentica el orquestador.

**Por qué es necesario.** Hoy la única forma de obtener un token es `POST /api/Auth/v1/Login` con el usuario y la contraseña **de una persona**. Un servicio que corre sin supervisión no debe usar credenciales personales: cuando esa persona cambia de contraseña, sale de la empresa o se le revoca el acceso, la automatización se cae en silencio; y todo lo que el sistema escriba queda atribuido a alguien que no lo hizo.

**Estado actual verificado.** `LoginRequest` acepta solo `username` y `password`. No existe flujo de credenciales de cliente, ni endpoint para dar de alta un consumidor de máquina. Los roles son de solo lectura (`GetAllRoles`, `GetRoleById`): no hay forma de crear ni asignar.

**Lo que se pide**

- **Método y ruta:** `POST /api/Auth/v1/Token`
- **Petición:** `{ "clientId": "...", "clientSecret": "...", "grantType": "client_credentials" }`
- **Respuesta 200:** igual que `LoginResponse` —`accessToken`, `expiresIn`, `tokenType`—, con el sujeto del token identificando al servicio y no a una persona.
- **Errores:** `400` `grantType` no soportado · `401` credenciales inválidas · `403` cliente deshabilitado.
- **Permisos:** el secreto se emite una vez y puede rotarse sin recrear el cliente.
- **Idempotencia:** no aplica.
- **Efectos colaterales:** ninguno.

**Criterios de aceptación**

1. El token emitido lleva un identificador de servicio distinguible de un usuario humano.
2. Rotar el secreto invalida el anterior sin cambiar el `clientId`.
3. Deshabilitar el cliente hace que las llamadas siguientes devuelvan `401`, sin afectar a ningún usuario.

**Si no se atiende.** Se opera con una cuenta de usuario dedicada. Funciona, pero la trazabilidad queda contaminada, la rotación de contraseña rompe el servicio, y la escritura de la etapa 2 se atribuye a una persona que no la hizo — lo que choca con **G23**.

#### G02 · Refresco de token — etapa 1 · ⚠ degrada

**Paso del proceso que lo necesita:** todos.

**Por qué es necesario.** `LoginResponse` **emite un `refreshToken`** pero no existe ningún endpoint donde canjearlo. Es decir: la API entrega una credencial que no se puede usar. Sin refresco, el servicio tiene que volver a autenticarse con la contraseña cada vez que expira el token, lo que obliga a mantener el secreto en memoria de forma permanente y multiplica las llamadas de autenticación.

**Estado actual verificado.** `LoginResponse` declara `refreshToken` y `expiresIn`. Los únicos endpoints de `Auth` son `Login`, `ValidateToken`, `ForgotPassword` y `ResetPassword`. **No hay `RefreshToken`.**

**Lo que se pide**

- **Método y ruta:** `POST /api/Auth/v1/RefreshToken`
- **Petición:** `{ "refreshToken": "..." }`
- **Respuesta 200:** nuevo `accessToken` con su `expiresIn`, y `refreshToken` rotado.
- **Errores:** `400` cuerpo mal formado · `401` refresh inválido, expirado o ya usado.
- **Idempotencia:** el refresh debe ser de un solo uso; reutilizarlo devuelve `401`.

**Criterios de aceptación**

1. Un `refreshToken` válido devuelve un `accessToken` nuevo sin pedir contraseña.
2. Reutilizar un `refreshToken` ya canjeado devuelve `401`.
3. El `expiresIn` documentado corresponde a la vigencia real del token.

**Si no se atiende.** El orquestador se reautentica con contraseña. Funciona, pero conserva el secreto en caliente y no hay forma de acotar la ventana de exposición. **O se elimina `refreshToken` de la respuesta**, que también es una solución válida: hoy su presencia es engañosa.

#### G05 · Eventos de avería (webhooks) — etapa 1 · ★ alto valor

**Paso del proceso que lo necesita:** pasos 3 y 4. Es el disparo del proceso.

**Por qué es necesario.** Hoy la única señal de que existe una avería nueva es **un correo dirigido a la cuenta nominal de un técnico**. Eso obliga al proyecto a pedir delegación sobre los buzones personales de David, Miguel y Eduardo —un pendiente que sigue sin resolver— y a depender de que el formato de ese correo no cambie. Además, la avería se asigna en `Registrada` pero **solo es trabajable en `Validación`**, así que sin un evento hay que reconsultar la avería periódicamente hasta detectar el cambio.

Un webhook resuelve las dos cosas de una vez y elimina la parte más frágil de toda la arquitectura.

**Estado actual verificado.** No existe. Se probó `/webhooks/openapi/v1.json` y devuelve 404. No hay ninguna mención de suscripción, evento ni callback en los cuatro servicios.

**Lo que se pide**

- **Eventos mínimos:** `claim.assigned`, `claim.status_changed`, `claim.document_uploaded`.
- **Registro:** basta que el equipo de SIGA configure la URL de destino a petición. **No se pide un endpoint de autoservicio.**
- **Carga:** identificador de la avería, evento, estatus anterior y nuevo, técnico asignado, marca de tiempo. **No hace falta el expediente completo**: con el identificador, el consumidor lo trae por API.
- **Seguridad:** firma HMAC en cabecera, con secreto compartido, para que el receptor verifique el origen.
- **Reintentos:** al menos tres, con espera creciente, ante respuesta distinta de `2xx`.
- **Entrega:** se acepta *al menos una vez*; el consumidor deduplica por identificador de evento. Se pide que ese identificador venga en la carga.

**Criterios de aceptación**

1. Al asignarse una avería, el destino recibe `claim.assigned` en menos de un minuto.
2. Al pasar a `Validación`, el destino recibe `claim.status_changed` con el estatus anterior y el nuevo.
3. La firma HMAC verifica con el secreto compartido.
4. Un destino que responde `500` recibe reintentos, y el evento no se pierde.
5. Cada evento trae un identificador único y estable para deduplicar.

**Si no se atiende.** El Copiloto sigue leyendo correo y reconsultando la avería para detectar el paso a validación. Funciona —así está diseñada la etapa 1—, pero conserva dos fragilidades: la dependencia del formato de un correo y del acceso a buzones personales, y una latencia de detección igual al intervalo de reconsulta.

#### G07 · Límites de tasa publicados — etapa 1 · ⚠ degrada

**Por qué es necesario.** La documentación afirma tener *"Rate limiting policies to ensure system stability"* pero no publica los umbrales. Un orquestador que no los conoce no puede dimensionar su concurrencia ni distinguir un bloqueo por tasa de una caída del servicio. El volumen actual es bajo —unas 11 averías por día hábil en México—, pero cada caso dispara entre 6 y 10 llamadas, y las etapas 4 y 5 lo multiplican.

**Estado actual verificado.** No hay umbrales, ni cabeceras de límite documentadas, ni código de respuesta declarado para el exceso.

**Lo que se pide**

- Publicar el límite por identidad y por ventana.
- Devolver `429` al excederlo, con `Retry-After`.
- Cabeceras informativas en toda respuesta: límite, restante y momento de reinicio.

**Criterios de aceptación**

1. Los umbrales están en la documentación del servicio.
2. Al excederlos se devuelve `429` con `Retry-After`, no un `500` ni un timeout.
3. Las cabeceras de límite vienen en las respuestas normales, para poder autorregularse antes de chocar.

**Si no se atiende.** El orquestador se autolimita de forma conservadora y trata cualquier error como transitorio. Costo: latencia innecesaria y diagnósticos ambiguos.

#### G08 · Formato de fechas y zona horaria explícitos — etapa 2 · ⚠ degrada

**Por qué es necesario.** El compromiso contractual es de **48 horas hábiles** contadas desde el paso a `Validación` (cláusula 10 del certificado). Medirlo exige saber sin ambigüedad en qué zona horaria están las marcas de tiempo, y la operación abarca tres países con husos distintos. Un desfase de horas convierte la métrica en ruido y, peor, podría hacer que el sistema reporte cumplimiento donde no hubo.

**Estado actual verificado.** Los campos de fecha se declaran como `string` con formato `date-time`, sin especificar si llevan desplazamiento, si son UTC o si son hora local del país del contrato.

**Lo que se pide**

- Todas las marcas de tiempo en **ISO 8601 con desplazamiento explícito**.
- Documentar la zona horaria de referencia por país.
- Para el cómputo de horas hábiles: documentar el calendario que aplica —días festivos y horario— o exponerlo como catálogo. La cláusula excluye domingos y festivos.

**Criterios de aceptación**

1. Toda fecha devuelta lleva desplazamiento explícito.
2. La documentación indica la zona de referencia por país.
3. El criterio de días hábiles y festivos está documentado o consultable.

**Si no se atiende.** La métrica del SLA se calcula con un supuesto de zona horaria. Es utilizable para tendencia, no para reportar cumplimiento contractual.

#### G09 · Entorno de pruebas con datos representativos — etapa 1 · ⚠ degrada

**Por qué es necesario.** Todo lo que este PRD pide tiene criterios de aceptación verificables, y verificarlos exige poder ejercitar los casos: una avería en `Validación`, una ya resuelta, un contrato de cada producto, evidencia de cada tipo. Además, las escrituras de las etapas 2 y 3 **no se pueden probar contra producción**: cambiar el estatus de una avería real tiene consecuencias para un cliente.

**Estado actual verificado.** Existe `qa-siga-api.garantiplus.com`. Las cuentas disponibles para este proyecto son de **taller** y de **distribuidor**, y por tanto ven un subconjunto filtrado. El entorno estuvo **caído con `503` en todo el host** el 2026-08-27.

**Lo que se pide**

1. Una **cuenta de rol técnico o coordinador** en QA, para poder verificar lo que el área técnica ve y hace. *(Es también el bloqueo de las verificaciones pendientes del §14.)*
2. Un conjunto de datos que cubra: avería en `Registrada`, en `Validación`, `Aceptada` y `No procede garantía`; contrato de cada producto vigente de México; y evidencia de los tres tipos obligatorios.
3. Un canal para avisar cuando el entorno se cae o se restablece.

**Criterios de aceptación**

1. Existe una cuenta de rol técnico en QA con credenciales entregadas.
2. Se puede localizar al menos una avería en cada estatus relevante.
3. Los casos de prueba sobreviven a los refrescos del entorno, o se documenta cómo recrearlos.

**Si no se atiende.** Los criterios de aceptación no se pueden verificar de forma independiente, y la puesta en marcha de cada etapa se prueba contra producción. Es asumible para lectura; **no lo es para las escrituras de las etapas 2 y 3**.

#### G10 · Política de versionado y deprecación — todas las etapas · ⚠ degrada

**Por qué es necesario.** El Copiloto va a depender de estos contratos durante años y su dictamen tiene efecto legal. Un cambio no anunciado en un nombre de campo o en un valor de catálogo no rompe el sistema de forma visible: lo hace **dictaminar distinto**. Ya ocurrió un cambio silencioso entre dos capturas de la especificación, tomadas con 48 horas de diferencia.

**Estado actual verificado.** Las rutas llevan `v1`, lo cual es buena base. No hay política publicada de qué constituye un cambio incompatible, ni aviso de deprecación, ni registro de cambios. Entre el 2026-08-24 y el 2026-08-26, `AvailableProductResponse` ganó los campos `taxAmount` y `total` sin aviso; fue un cambio compatible, pero nada garantizaba que lo fuera.

**Lo que se pide**

1. Declarar qué se considera cambio incompatible y qué se hará en ese caso —nueva versión de ruta o negociación por cabecera—.
2. Registro de cambios de la API, aunque sea una nota por versión.
3. Cabeceras `Deprecation` y `Sunset` cuando algo se vaya a retirar, con plazo mínimo anunciado.
4. **Los valores de catálogo son parte del contrato:** añadir un motivo de rechazo o un estatus debe anunciarse igual que un cambio de campo, porque el Copiloto los mapea.

**Criterios de aceptación**

1. La política está publicada y accesible.
2. Cada cambio del contrato queda registrado con su fecha.
3. Un retiro anunciado llega con cabecera y con el plazo comprometido.

**Si no se atiende.** El sistema queda expuesto a deriva silenciosa. La mitigación de nuestro lado es capturar la especificación periódicamente y comparar —ya se hace—, pero eso detecta el cambio **después** de que ocurrió, no antes.

### B. Lectura del expediente — lo que haría el dictamen más exacto

#### G11 · Consulta singular de una avería — etapa 1 · ⚠ degrada

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

#### G12 · Campos faltantes en la avería — etapa 1 · ⚠ degrada

**Paso del proceso que lo necesita:** pasos 3 y 5. Es el expediente sobre el que se dictamina.

**Por qué es necesario.** La respuesta de una avería no incluye tres datos que el dictamen necesita:

- **`vinOrPlate`** — para verificar que el VIN del correo, el del contrato y el de la avería coinciden. Sin él, esa verificación de coherencia queda incompleta y un correo con VIN erróneo no se detecta.
- **`odometer`** — el kilometraje al momento de la avería. Es indispensable para la cláusula 9 (intervalo de mantenimiento, **29.1% de los rechazos**) y la 12.5 (coherencia de kilómetros). Hoy hay que extraerlo de una **fotografía del odómetro**, con el error de lectura que eso implica.
- **`projectId` o país** — para saber qué condicionado, catálogo y plantilla aplican. Imprescindible para la etapa 5.

**Estado actual verificado.** `ClaimResponse` declara `claimId`, `policyId`, `contractId`, `description`, `creationDate`, `statusId`, `technicianId`, `technicianName`, `registeredBy` y `trackingUrl`. La cadena `odomet` aparece nueve veces en el spec de `claims`, **todas en incidencias**. `vinOrPlate` existe en `IssueResponse` pero no se declara en `ClaimResponse`, aunque el ejemplo de OData de `GetClaims` lo menciona.

**Dos vías, y la primera puede ser gratis**

*Vía A — puede que ya exista.* El ejemplo documentado de `GetClaims` incluye `VinOrPlate` en un `$select`. Si el servicio efectivamente lo devuelve, **esta solicitud se reduce a corregir el esquema publicado**. Pendiente de verificar (§14, V1).

*Vía B — puede resolverse por la entidad hermana.* `IssueResponse` trae `vinOrPlate`, `odometer` **y `claimId`**. Si toda avería nace de una incidencia, entonces `GetIssues?$filter=claimId eq {n}` ya da ambos datos. Si es así, **basta documentar ese patrón como la vía oficial** y esta solicitud desaparece. Pendiente de verificar (§14, V12).

*Si ninguna vía aplica:* añadir `vinOrPlate`, `odometer` y `projectId` a `ClaimResponse`. Son los mismos datos que ya viven en la entidad hermana, así que exponerlos es coherencia del modelo, no una función nueva.

**Criterios de aceptación**

1. Dado un identificador de avería, se obtiene su VIN sin recurrir al correo.
2. Se obtiene el kilometraje registrado sin leer una fotografía, o queda documentado que ese dato no existe en el sistema para averías.
3. Se obtiene el país o proyecto de la avería.
4. Si la vía es la incidencia asociada, el patrón queda documentado en el spec.

**Si no se atiende.** El VIN se toma del correo sin poder cotejarlo contra la avería, y el kilometraje se extrae de una fotografía con confianza explícita: cuando la lectura es dudosa, el caso se remite a una persona. La causal de mayor volumen queda dependiendo de leer bien una imagen.

#### G13 · Fecha de paso a validación e historial de estatus — etapa 1 · ⚠ degrada

**Paso del proceso que lo necesita:** paso 4. Es el momento en que arranca el reloj.

**Por qué es necesario.** El compromiso contractual son **48 horas hábiles desde que la avería pasa a `Validación`**, no desde que se registra. Sin esa marca de tiempo **el SLA no se puede medir**. Hoy el tablero del área registra una mediana de 4.1 días y un p90 de 50.1 días, pero nadie sabe con certeza qué mide ese número: si es registro a cierre, no es comparable con las 48 horas.

Es también lo que permite el disparo correcto del dictamen: la avería se asigna en `Registrada`, cuando el expediente puede estar vacío, y solo es trabajable en `Validación`.

**Estado actual verificado.** `ClaimResponse` trae `creationDate` y `statusId`, pero ninguna fecha de transición. La cadena `history` aparece **0 veces** en el spec completo.

**Lo que se pide**

- **Campo:** `validationDate` en la respuesta de la avería, con la marca de tiempo del paso a `Validación`.
- **Y/o endpoint:** `GET /api/Claims/v1/GetClaimStatusHistory/{claimId}`

  ```json
  [
    { "statusId": 7, "status": "Registrada",  "changedAt": "2026-06-26T09:02:11-06:00", "changedBy": "garantias@chevroletmilenio.mx" },
    { "statusId": 8, "status": "Validación",  "changedAt": "2026-06-26T11:18:04-06:00", "changedBy": "garantias@chevroletmilenio.mx" },
    { "statusId": 4, "status": "Aceptada",    "changedAt": "2026-06-26T11:46:52-06:00", "changedBy": "eduardo.alvarez@garantiplus.mx" }
  ]
  ```

- **Errores:** `401` · `403` fuera de alcance · `404` avería inexistente.
- **Efectos colaterales:** ninguno, es lectura.

**Criterios de aceptación**

1. Para una avería que pasó por `Validación`, se obtiene esa marca de tiempo.
2. El historial incluye quién hizo cada cambio.
3. Las marcas de tiempo cumplen **G08**: ISO 8601 con desplazamiento.

**Si no se atiende.** El SLA se aproxima con la fecha de creación, que lo sobrestima. La métrica de cumplimiento contractual del proyecto **no se puede reportar**, solo estimar.

#### G14 · Catálogo de estatus de avería — etapa 2 · ⚠ degrada

**Por qué es necesario.** Para resolver una avería hay que enviar un estatus destino, y para interpretar una avería hay que traducir su `statusId`. Sin catálogo, los identificadores quedan **quemados en la configuración del orquestador**, y si cambian o se añaden, el sistema los interpreta mal en silencio.

**Estado actual verificado.** No existe. `ClaimResponse.statusId` viene como identificador sin catálogo que lo resuelva. Se conocen **once estatus reales** por la operación, no por la API: `Registrada`, `Validación`, `Aceptada`, `No procede garantía`, `Taller`, `Solucionada`, `Cerrada`, `Cancelada`, `Prueba-QA`, `Excepción en revisión`, `Excepción no aprobada`. Los dos últimos solo aparecen en Chile y Colombia.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetClaimStatuses`
- **Respuesta 200:** identificador estable, nombre, y **qué transiciones admite desde él y por qué rol**. Esa última parte es lo valioso: hoy el conocimiento de que el área técnica solo mueve `Validación` → `Aceptada` / `No procede garantía` vive en la cabeza de las personas.

  ```json
  [
    { "statusId": 8, "status": "Validación", "isTerminal": false,
      "allowedTransitions": [
        { "toStatusId": 4, "toStatus": "Aceptada",            "byRole": "technician" },
        { "toStatusId": 1, "toStatus": "No procede garantía", "byRole": "technician" }
      ],
      "countries": ["MEX", "COL", "CHL"] }
  ]
  ```

**Criterios de aceptación**

1. El catálogo trae los once estatus con identificador estable.
2. Cada uno indica sus transiciones permitidas y el rol que puede ejecutarlas.
3. Los estatus que solo existen en algunos países vienen marcados.

**Si no se atiende.** Los identificadores se configuran a mano a partir de observación. Funciona hasta que cambien, y entonces falla sin aviso.

#### G17 · Identificador de tipo en los documentos — etapa 1 · ⚠ degrada

**Por qué es necesario.** El Copiloto tiene que distinguir la foto del odómetro del presupuesto y de la evidencia general, porque cada tipo alimenta una puerta distinta del dictamen. Hoy el tipo llega como **cadena de texto**, así que emparejarlo exige comparar nombres: cualquier cambio de redacción, tilde o mayúscula rompe la clasificación **sin producir un error**.

**Estado actual verificado.** `ClaimDocumentQueryResponse` declara `documentType` como `string`, pero **no `documentTypeId`** — aunque `DocumentTypeResponse` sí expone `documentTypeId`, y `GetDocumentType` ya devuelve el catálogo. La pieza que falta es el vínculo.

**Lo que se pide**

- Añadir `documentTypeId` (int) a `ClaimDocumentQueryResponse` y a `ClaimDocumentResponse`.
- Permitir filtrar por él: `?$filter=claimId eq 3246 and documentTypeId eq 3`.

**Criterios de aceptación**

1. Cada documento devuelto trae el identificador numérico de su tipo.
2. Ese identificador corresponde a una entrada de `GetDocumentType`.
3. Se puede filtrar la lista de documentos por tipo.

**Si no se atiende.** La clasificación se hace por coincidencia de cadena, con normalización de tildes y mayúsculas de nuestro lado. Frágil y silencioso ante cambios de redacción.

#### G18 · Garantía de completitud del texto del certificado — etapa 1 · ⚠ degrada

**Paso del proceso que lo necesita:** paso 5. Es la norma contra la que se dictamina.

**Por qué es necesario.** `GetContractPdfDataById` es **el habilitador de la etapa 1**: es lo que permite dictaminar sin esperar ningún cambio en la API. Pero el contrato de servicio no dice nada sobre la completitud ni la estabilidad de ese texto. Si devolviera solo la primera página, o si el orden de las cláusulas variara entre extracciones, el dictamen sería incorrecto **sin que nada falle visiblemente**.

**Estado actual verificado.** El endpoint existe y su descripción dice *"Returns the PDF file content as extracted text. The PDF must exist in S3."* No hay garantía documentada de completitud, ni de conservación de la estructura, ni de estabilidad entre llamadas. **Pendiente de verificar en runtime** (§14, V4).

**Lo que se pide**

1. **Garantía documentada** de que el texto corresponde al certificado **completo**, todas las páginas y todas las cláusulas.
2. **Estabilidad:** dos llamadas sobre el mismo contrato devuelven el mismo texto.
3. **Conservación de los límites de cláusula**, aunque sea con saltos de línea: lo que el dictamen necesita es poder localizar la cláusula 9 y citarla, y para eso el texto no puede venir como un párrafo continuo.
4. **Un indicador de calidad de extracción** o, en su defecto, un error explícito cuando la extracción falla — nunca un texto truncado con `200`.

**Criterios de aceptación**

1. El texto devuelto contiene las cláusulas 1, 9, 11, 12 y 13, verificable buscando sus encabezados.
2. Dos llamadas consecutivas devuelven texto idéntico.
3. Un contrato cuyo PDF no se pudo extraer devuelve error, no texto parcial.

**Si no se atiende.** El dictamen se apoya en un texto sin garantías. La mitigación de nuestro lado es verificar en cada caso que los encabezados de cláusula esperados estén presentes y, si faltan, remitir a una persona. Funciona, pero convierte un problema de contrato en trabajo humano recurrente. **Si el texto resultara incompleto o inestable, G19 pasa a bloqueante de la etapa 1.**

#### G19 · Condicionado del contrato como datos — etapa 1 · ★ alto valor

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

#### G20 · Lectura del seguimiento de la avería — etapa 1 · ⚠ degrada

**Paso del proceso que lo necesita:** pasos 5 y 6. Es la conversación del expediente.

**Por qué es necesario.** La plataforma tiene un mecanismo de seguimiento: el técnico escribe *"hace falta foto del odómetro"*, eso queda en el expediente **y genera una notificación por correo al taller**. Es el canal real por el que se piden datos y se documenta el criterio. Para el Copiloto es doblemente valioso: le dice **qué se pidió y qué falta** antes de dictaminar, y le da el histórico de cómo el equipo redacta sus observaciones.

**Estado actual verificado.** No está expuesto. Las cadenas `followup`, `comment`, `seguimiento` y `observacion` aparecen **0 veces** en el spec de `claims`, aunque la funcionalidad existe en la interfaz.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetClaimFollowUp/{claimId}`
- **Respuesta 200:**

  ```json
  [
    { "entryId": 55120, "claimId": 3246,
      "createdAt": "2026-06-26T11:22:40-06:00",
      "createdBy": "eduardo.alvarez@garantiplus.mx",
      "authorRole": "technician",
      "text": "Hace falta foto del odómetro.",
      "isVisibleToWorkshop": true }
  ]
  ```

- El campo `isVisibleToWorkshop` importa: hay observaciones internas y observaciones que el taller ve, y el Copiloto no debe confundirlas.
- **Errores:** `401` · `403` · `404`.

**Criterios de aceptación**

1. Se obtienen las entradas de seguimiento de una avería en orden cronológico.
2. Cada entrada trae autor, rol y si es visible para el taller.
3. Un expediente sin seguimiento devuelve lista vacía con `200`, no `404`.

**Si no se atiende.** El Copiloto dictamina sin ver lo que ya se pidió, y puede volver a solicitar algo que el técnico ya solicitó. Es la escritura de este mismo canal la que se pide en **G30** para la etapa 4.

### C. Gobierno de la escritura — corrección y auditoría

#### G24 · Corregir o revertir un dictamen — etapa 2 · ⚠ degrada

**Por qué es necesario.** El sistema se va a equivocar alguna vez, y también el equipo. Hoy, cuando hace falta deshacer algo que el área técnica no puede mover, **se escala a TI para que lo modifique**. Si el Copiloto va a resolver expedientes de forma automática, necesita una vía de corrección proporcional al volumen: sin ella, cada error se convierte en un ticket manual, y el interruptor de apagado del automatismo pierde la mitad de su utilidad porque no puede limpiar lo ya escrito.

**Estado actual verificado.** No existe. El área técnica solo puede mover `Validación` → `Aceptada` / `No procede garantía`; cualquier corrección posterior pasa por TI. Confirmado por la operación: *"únicamente lo hacemos a través de TI, que nos ayudan a modificarlo"*.

**Lo que se pide**

Una de estas dos formas, a elección del equipo:

- **Reapertura:** `POST /api/Claims/v1/ReopenClaim/{claimId}` con `{ "reason": "...", "requestedBy": "..." }`, que devuelve la avería a `Validación` dejando rastro de la reapertura.
- **Rectificación:** permitir a **G21** actuar sobre una avería ya resuelta cuando se envía una bandera explícita `isCorrection: true` y un motivo de corrección, registrando ambas resoluciones en el historial.

En cualquier caso: **la corrección no borra nada**. La resolución anterior queda en el historial y en el expediente. Es lo que exige el valor legal del documento.

**Criterios de aceptación**

1. Una avería resuelta por error puede volver a `Validación` por API, sin ticket a TI.
2. El historial conserva la resolución original y la corrección, con sus autores y fechas.
3. La operación requiere un motivo y no se puede ejecutar en silencio.
4. Está restringida a rol de coordinador o superior, **no** al rol de servicio sin supervisión.

**Si no se atiende.** Cada corrección es un ticket a TI. Con el volumen del MVP es tolerable; al escalar a los tres países deja de serlo, y el riesgo de apagar el automatismo aumenta porque limpiar lo escrito es costoso.

#### G25 · Auditoría consultable — etapa 2 · ⚠ degrada

**Por qué es necesario.** El principio de la operación es explícito: *"todo debe estar dentro de SIGA para poder hacer auditorías"*. Cuando parte de los dictámenes los produce un sistema, la auditoría tiene que poder responder tres preguntas sobre cualquier expediente: **quién lo tocó, cuándo y qué cambió**. Es además la única forma de investigar una discrepancia entre lo que el Copiloto dictaminó y lo que quedó registrado.

**Estado actual verificado.** No hay endpoint de auditoría en ninguno de los cuatro servicios. `history` aparece **0 veces**. Se probó `/audit/openapi/v1.json`: 404.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetClaimAuditTrail/{claimId}`
- **Respuesta 200:** las operaciones aplicadas sobre la avería, con actor, tipo de actor, momento, campo afectado, valor anterior y nuevo.

  ```json
  [
    { "at": "2026-08-27T10:14:22-06:00",
      "actor": "svc-copiloto-averias", "actorType": "service",
      "operation": "resolve",
      "changes": [
        { "field": "statusId",          "from": "8",  "to": "1" },
        { "field": "rejectionReasonId", "from": null, "to": "12" }
      ],
      "idempotencyKey": "avr-3246-resolve" }
  ]
  ```

- Puede satisfacerse junto con **G13**: si el historial de estatus incluye actor y cambios, cubre la mayor parte de la necesidad.
- **Permisos:** rol de coordinador o auditoría. No es necesario que el rol de servicio pueda leerlo.

**Criterios de aceptación**

1. Se puede reconstruir qué le pasó a una avería y quién lo hizo.
2. Las operaciones ejecutadas por un servicio se distinguen de las de una persona.
3. La entrada de auditoría incluye la clave de idempotencia, para poder correlacionar con nuestros registros.

**Si no se atiende.** La auditoría se hace cruzando nuestro registro con el estado final en la plataforma. Funciona mientras nadie discuta la versión de los hechos; si alguien la discute, no hay fuente independiente.

### D. Operación de alta carga — cerrar el ciclo hasta el pago

#### G29 · Histórico de casos por componente — etapa 3 · ⚠ degrada

**Por qué es necesario.** La etapa 3 incluye armar un **comparativo**: situar el caso frente a su referencia para que el técnico vea si el presupuesto es razonable. Hoy ese conocimiento existe pero vive en un tablero alimentado por extracción manual, no consumible en tiempo real. Con el histórico por API, el comparativo se genera solo.

**Estado actual verificado.** No existe endpoint de agregación histórica. El tablero del área lo tiene —importes por componente, por marca, por taller, por kilometraje— sobre 16 800 averías de 2021 a 2026, lo que confirma que el dato está en la base.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetComponentStatistics?componentId={n}&brandId={n}&country={code}&months={n}`
- **Respuesta 200:** importes agregados y tasa de resolución del componente en el periodo.

  ```json
  {
    "componentId": 418, "componentName": "BOMBA DE AGUA",
    "sampleSize": 175, "periodMonths": 24, "currency": "MXN",
    "authorizedAmount": { "p25": 3900.00, "median": 5150.00, "p75": 7300.00 },
    "rejectionRate": 0.18,
    "topRejectionReasons": [
      { "reasonId": 12, "share": 0.41 },
      { "reasonId": 7,  "share": 0.22 }
    ]
  }
  ```

- **Importante:** se piden **percentiles, no promedios**. Un promedio se distorsiona con un caso extremo, y la referencia sirve para detectar desviaciones.
- Si `$apply` funciona en los listados (§14, V7), esto podría resolverse sin endpoint nuevo. Se pide confirmar.

**Criterios de aceptación**

1. Se obtiene la distribución de importes autorizados de un componente en un periodo.
2. La respuesta indica el tamaño de muestra, para poder ignorar referencias sin sustento.
3. Se puede acotar por marca y país.

**Si no se atiende.** El comparativo se construye con lo que el Copiloto haya observado por su cuenta, que al principio es nada. La etapa 3 funciona sin él —las cuatro verificaciones no dependen del histórico—, pero el técnico pierde el contexto que le permitiría juzgar rápido si un importe es razonable.

#### G30 · Agregar seguimiento a la avería — etapa 4 · ⚠ degrada

**Paso del proceso que lo necesita:** paso 6 y el cierre del expediente.

**Por qué es necesario.** Es la escritura del canal que **G20** solo lee. En la etapa 4 el Copiloto tiene que **pedirle al taller la documentación de pago** —resolución firmada, identificación del cliente, facturas— y dar seguimiento a lo que falta. Ese canal ya existe en la plataforma y ya notifica por correo al taller: es exactamente el mecanismo con el que hoy un técnico escribe *"hace falta foto del odómetro"*.

Lo importante es que el Copiloto **no debe montar un canal paralelo**. Si escribiera por correo desde fuera, el taller recibiría dos hilos distintos y el expediente perdería la conversación. Se pide usar el que ya funciona.

**Estado actual verificado.** No expuesto. `followup`, `comment`, `seguimiento`: **0 ocurrencias** en el spec, aunque la funcionalidad existe en la interfaz y dispara notificación.

**Lo que se pide**

- **Método y ruta:** `POST /api/Claims/v1/AddClaimFollowUp/{claimId}`
- **Cabeceras:** `Idempotency-Key` obligatoria (**G04**).
- **Petición:**

  ```json
  {
    "text": "Para procesar el pago hace falta: resolución firmada por el cliente y factura del taller.",
    "isVisibleToWorkshop": true,
    "notifyWorkshop": true
  }
  ```

- **Respuesta 201:** el `entryId` creado, con su marca de tiempo y autor.
- **Errores:** `400` texto vacío · `401` · `403` · `404` avería inexistente · `409` la avería está en un estatus que no admite seguimiento, si aplica.
- **Efectos colaterales:** **la misma notificación por correo que la plataforma ya emite** cuando una persona escribe seguimiento. No se pide un mecanismo nuevo de notificación.

**Criterios de aceptación**

1. Agregar seguimiento devuelve `201` y la entrada aparece en `GetClaimFollowUp`.
2. Con `notifyWorkshop: true`, el taller recibe la misma notificación que recibiría de una persona.
3. Con `isVisibleToWorkshop: false`, la entrada no le llega al taller.
4. Repetir con la misma clave de idempotencia no duplica la entrada ni la notificación.
5. La entrada queda atribuida a la identidad de servicio, distinguible de una persona (**G23**).

**Si no se atiende.** El Copiloto no puede pedir documentación por el canal del expediente. La alternativa —correo por fuera— fragmenta la conversación y deja el expediente incompleto, lo que contradice el principio de que todo debe vivir en la plataforma. En ese caso la solicitud de documentación se queda como tarea del técnico y la etapa 4 pierde su parte de cierre.

#### G31 · Consulta agregada de la cola de trabajo — etapa 4 · ⚠ degrada

**Por qué es necesario.** La etapa 4 ordena los casos **por riesgo e importe, no por antigüedad**, y presenta al técnico una cola priorizada. Construirla exige agrupar y contar del lado del servidor: cuántas averías por estatus, por técnico y por antigüedad. Traer miles de registros página por página para contarlos del lado del cliente es caro y se degrada al escalar a tres países.

**Estado actual verificado.** El spec incluye `ApplyQueryOption` entre sus esquemas, lo que sugiere que **`$apply` podría ya funcionar**. Los ejemplos documentados no lo mencionan y no se ha podido probar (§14, V7). `$count` sí está documentado.

**Lo que se pide**

*Primero, confirmar:* si `$apply` funciona con `groupby` y `aggregate`, **esta solicitud se reduce a documentarlo con ejemplos**, y no hace falta desarrollo. Ejemplo que se querría poder usar:

```
GET /api/Claims/v1/GetClaims
    ?$apply=filter(statusId eq 8)/groupby((technicianId),aggregate($count as total))
```

*Si no funciona,* un endpoint de resumen:

- **Método y ruta:** `GET /api/Claims/v1/GetClaimsSummary?groupBy=status,technician&country=MEX`
- **Respuesta 200:** conteos por combinación, más antigüedad media y máxima del grupo.

**Criterios de aceptación**

1. Se obtiene el conteo de averías por estatus y por técnico en una sola llamada.
2. Se puede acotar por país y por rango de fechas.
3. Se obtiene la antigüedad del caso más viejo de cada grupo, para detectar rezagados.

**Si no se atiende.** La cola se construye paginando los listados. Con el volumen actual —unas 11 averías por día hábil en México— es perfectamente viable; el problema aparece en la etapa 5, con los tres países y el histórico abierto.

#### G32 · Estado de pago y comprobante del expediente — etapa 4 · ⚠ degrada

**Paso del proceso que lo necesita:** paso 7, después de la aceptación.

**Por qué es necesario.** La etapa 4 cierra el ciclo: vigilar el expediente después de la aceptación y **alertar de lo que se atora**. Hoy eso es un punto ciego reconocido por el área, y con una causa concreta: el área técnica **no puede subir el comprobante de pago hasta que el taller mueve la avería a `Solucionada`**, así que hay expedientes pagados sin comprobante cargado durante semanas. Detectar eso a tiempo es justo lo que la etapa 4 debe hacer.

**Estado actual verificado.** `contracts` expone `GetContractPaymentInfo` y `GetPaymentStatus`, pero son del **pago del contrato de garantía por parte del cliente**, no del pago de la reparación al taller. En `claims` no hay nada de pagos. Se probó `/payments/openapi/v1.json`: 404.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetClaimSettlement/{claimId}`
- **Respuesta 200:**

  ```json
  {
    "claimId": 3246,
    "authorizedAmount": 9546.80,
    "invoiceReceived": true,
    "invoiceAmount": 9546.80,
    "invoiceDocumentId": 91840,
    "paymentStatus": "pendiente",
    "paidAt": null,
    "paymentProofDocumentId": null,
    "daysSinceAuthorization": 23,
    "currency": "MXN"
  }
  ```

- **`daysSinceAuthorization`** es el dato que dispara la alerta de expediente atorado.
- Alternativa aceptable: exponer `paymentStatus` y `paidAt` como campos de la avería, sin endpoint nuevo.
- **Errores:** `401` · `403` · `404` · `409` la avería no está aceptada, así que no hay liquidación que consultar.

**Criterios de aceptación**

1. Se distingue una avería con factura recibida de una sin factura.
2. Se distingue una pagada de una pendiente de pago.
3. Se obtiene la antigüedad desde la autorización, para detectar rezago.
4. Si hay diferencia entre el importe autorizado y el facturado, se puede detectar comparando ambos campos.

**Si no se atiende.** El seguimiento post-aceptación se aproxima con el estatus de la avería, que solo distingue `Taller` de `Solucionada` de `Cerrada`. Se pueden detectar rezagos gruesos, pero no la diferencia entre "el taller no ha facturado" y "facturó y no le hemos pagado", que son problemas de dueños distintos.

#### G35 · Catálogo de técnicos — etapa 4 · ⚠ degrada

**Por qué es necesario.** Dos cosas dependen de esto. Primera, **la métrica que justifica todo el proyecto**: el objetivo es llevar la capacidad de ~700 a 1 000–1 200 averías por persona al año, y para calcularlo hace falta saber cuántos técnicos hay activos y quiénes. Segunda, la **correlación con el disparo**: el correo de asignación llega a la cuenta nominal de un técnico, y el Copiloto necesita ligar ese buzón con el `technicianId` de la avería para saber a quién responder.

**Estado actual verificado.** `ClaimResponse` trae `technicianId` y `technicianName`, pero **no existe el padrón**. `catalogs` expone `GetAllAdvisors`, que son **asesores de venta**, no técnicos de averías. No hay forma de saber quién está activo, en qué país opera, ni cuál es su correo.

**Lo que se pide**

- **Método y ruta:** `GET /api/Claims/v1/GetTechnicians`
- **Respuesta 200:**

  ```json
  [
    { "technicianId": 9, "fullName": "Eduardo Álvarez",
      "email": "eduardo.alvarez@garantiplus.mx",
      "country": "MEX", "role": "technician", "isActive": true,
      "receivesAssignments": true }
  ]
  ```

- **`receivesAssignments`** distingue a quien entra en la rotación de asignación de quien solo supervisa. Es lo que permite calcular la capacidad por persona sobre la base correcta.
- **`email`** es lo que permite correlacionar el buzón del correo de asignación con el técnico de la avería.

**Criterios de aceptación**

1. Se obtiene la lista de técnicos con su identificador, correo y país.
2. Se distingue activo de inactivo, y quien recibe asignaciones de quien no.
3. El `technicianId` corresponde al que devuelve `ClaimResponse`.

**Si no se atiende.** El padrón se mantiene como configuración en el orquestador, actualizada a mano. Funciona con dos técnicos en México; al centralizar tres países con plantilla cambiante se convierte en una fuente de error, y la métrica de capacidad se calcula sobre un supuesto en lugar de un dato.

#### G36 · Marca de origen del dictamen — etapa 2 · ⚠ degrada

**Paso del proceso que lo necesita:** paso 5.

**Por qué es necesario.** Es una petición explícita del área: las averías resueltas de forma automática **no deben asignarse a un técnico, pero sí deben medirse aparte** — *"lo ideal sería medirlas bajo otro parámetro, pero que sí notifique"*. Sin un campo que distinga dictamen automático de dictamen humano, esos casos se mezclan con la carga del equipo y **el indicador de desempeño queda corrupto justo cuando más importa**: se vería como si los técnicos hubieran resuelto casos que no tocaron, y a la vez el ahorro real del sistema sería invisible.

Es también lo que permite auditar el automatismo por separado y decidir con datos si se enciende o se apaga.

**Estado actual verificado.** No existe el concepto. Al no haber escritura de estatus, tampoco hay forma de marcar el origen. `technicianId` seguiría apuntando a quien tenía asignado el caso, aunque no lo haya trabajado.

**Lo que se pide**

- **Campo persistido en la avería:** `resolutionOrigin`, con valores `human`, `automated` y `automated_confirmed` — este último para el caso de la etapa 3, donde el sistema propone y una persona aprueba, que **no es ninguno de los otros dos**.
- **Exponerlo** en la respuesta de la avería y admitir filtrarlo por OData, para poder reportar por separado.
- **Que no altere la asignación:** una avería resuelta automáticamente conserva su `technicianId` para efectos de contacto, pero puede excluirse de las métricas de carga filtrando por este campo.

  Si el equipo prefiere, se puede derivar de **G23**: si `resolvedBy.type` es `service` y `approvedBy` es nulo, el origen es automático. En ese caso **basta documentar esa regla** y no hace falta campo nuevo.

**Criterios de aceptación**

1. Se puede distinguir una avería resuelta por el sistema de una resuelta por una persona.
2. Se distingue el caso de propuesta automática con aprobación humana de los otros dos.
3. Se puede filtrar y contar por origen en una sola consulta.
4. El origen no cambia a quién estaba asignada la avería.

**Si no se atiende.** El área no puede separar el trabajo del sistema del trabajo del equipo, y el indicador de desempeño de los técnicos se distorsiona en la dirección equivocada. Se puede reconstruir cruzando nuestro registro con la plataforma, pero eso deja la métrica oficial del área dependiendo de un sistema externo.

### E. Operación regional — Colombia y Chile

#### G33 · Contratos y averías de Colombia y Chile — etapa 5 · ⛔ BLOQUEANTE

**Por qué es necesario.** El plan es consolidar la operación de los tres países en México. Hoy la API existe **solo para México**, así que el Copiloto no puede tocar los otros dos mercados ni siquiera en modo lectura. Los volúmenes no son marginales: Chile **519 averías** y Colombia **749** entre enero y julio de 2026, frente a 1 582 de México. Colombia rechaza el **45.9%** de sus casos, la tasa más alta de los tres, así que es donde el ahorro sería mayor.

**Estado actual verificado.** Los cuatro servicios responden solo para México. La descripción de `claims` y de `contracts` dice *"Multi-country support (currently MEX, expandable to other markets)"*, así que **la intención está declarada**; lo que no existe es la implementación.

**Lo que se pide**

Cualquiera de estas dos formas, a elección del equipo:

- **A — Alcance de país en la misma API.** Los endpoints existentes aceptan y devuelven país o proyecto, y la identidad determina a qué mercados tiene acceso. Es la vía coherente con la intención ya declarada y la que menos trabajo genera del lado del consumidor.
- **B — Instancias por país.** Un despliegue equivalente por mercado, con el **mismo contrato de API**. Aceptable, siempre que los contratos sean idénticos: un esquema distinto por país multiplicaría el trabajo de integración por tres.

En ambos casos se pide:

1. **Paridad de contrato.** El mismo esquema y la misma nomenclatura. Las diferencias reales de negocio se expresan como **datos** —catálogos y condicionados por país (**G34**)—, no como campos distintos.
2. **Un campo de país** en avería y contrato, para poder enrutar (ya pedido en **G12**).
3. **Moneda explícita** en todo importe. Los tres países usan monedas distintas y órdenes de magnitud muy distintos.
4. **Aislamiento por identidad:** una credencial de un país no debe poder leer datos de otro salvo que se le habilite explícitamente.

**Criterios de aceptación**

1. Se puede consultar un contrato de Colombia y uno de Chile con el mismo código de cliente que México.
2. Toda respuesta con importes trae su moneda.
3. Una credencial acotada a un país recibe `403` al pedir datos de otro.
4. El esquema de respuesta es idéntico entre países.

**Si no se atiende.** La etapa 5 no existe y **el objetivo de negocio no se cumple**: la consolidación regional depende de poder operar los tres mercados desde una sola herramienta. Las etapas 1 a 4 siguen entregando su valor en México, así que el proyecto no se cae — pero se queda en un tercio de su alcance.

#### G34 · Catálogos por país, normalizados — etapa 5 · ⚠ degrada

**Por qué es necesario.** Los tres países usan **nomenclaturas distintas para lo mismo**, y hasta estatus que no existen en todos. Sin normalizar, cada mercado exige su propia configuración y **la métrica regional no es comparable**: no se puede decir "el 20% de los rechazos son por mantenimiento" si cada país llama distinto a esa causal.

**Estado actual verificado.** Sobre los 56 valores de motivo: México usa `Intervalo de Mantenimiento Excedido` y `Daño por uso o degradación`; en los otros países aparecen `DESGASTE NATURAL DE PIEZAS`, `COMPONENTE NO INCLUIDO EN LA GARANTIA`, `OPERACION NO INCLUIDA`, `Elemento no cubierto` y `AVERIA POR GOLPE`, en mayúsculas y con criterios que se solapan. Los estatus `Excepción en revisión` y `Excepción no aprobada` **solo aparecen en Chile y Colombia**.

**Lo que se pide**

Es la extensión natural de **G14** y **G15** a los tres mercados:

1. **Un catálogo de motivos común**, con identificadores estables, y marca de en qué países aplica cada uno. Las variantes locales se resuelven con el campo `aliases` de **G15**.
2. **Un catálogo de estatus común**, con la misma marca de aplicabilidad por país, incluidos los dos estatus de excepción.
3. **Condicionados por país.** Los productos de Chile y Colombia son distintos a los de México — se confirmó que *"son un poco diferentes"*—, así que **G19** debe resolverse por contrato y no por plantilla de país.
4. **Documentar las diferencias de proceso que sean reales.** Es la pregunta abierta más importante de este grupo: Colombia rechaza el 45.9% y Chile el 17.5%, y **nadie ha explicado si la diferencia es de producto, de criterio o de calidad del dato**. Si es de criterio, el alcance de la etapa 5 es mucho mayor de lo que parece.

**Criterios de aceptación**

1. Un mismo motivo de rechazo tiene el mismo identificador en los tres países.
2. Cada motivo y cada estatus indica en qué países aplica.
3. Los valores históricos de cada país quedan mapeados al catálogo común.
4. El condicionado se obtiene por contrato, no por país.

**Si no se atiende.** Cada país exige su propia configuración de catálogos, mantenida a mano, y los indicadores regionales se calculan con un mapeo hecho por nosotros. Es viable, pero traslada al consumidor un trabajo de normalización que solo la plataforma puede hacer bien — y cualquier valor nuevo en cualquier país rompe el mapeo en silencio.

## 3. Fuera de alcance

Igual que en el documento principal: no se piden cambios en la interfaz de SIGA, ni en la lógica de negocio del dictamen, ni endpoints de administración de usuarios o suscripciones, ni ejecución de pagos. Donde hace falta configuración —el registro de un webhook en **G05**, un rol en el documento principal— basta que el equipo la aplique a petición y documente el procedimiento.

**Tampoco se pide crear el historial de mantenimientos** del vehículo, que no existe en el sistema y sería un cambio de producto. Es la causal del 29.1% de los rechazos y el Copiloto seguirá deduciéndola de las facturas cargadas como evidencia. **G19** es lo más cerca que se puede estar de resolverlo sin cambiar el producto: si al menos el *régimen* de mantenimiento viene como dato, el sistema puede calcular qué se debió hacer y compararlo contra los documentos, en lugar de deducir ambas cosas de la prosa de un PDF.

## 4. Verificaciones pendientes que afectan a este documento

Tres de estas solicitudes podrían **desaparecer** si se confirma que la capacidad ya existe. No se pudo verificar porque el entorno QA estuvo devolviendo `503` en todo el host.

| Solicitud | Qué hay que confirmar | Si ya funciona |
| --- | --- | --- |
| **G12** | ¿La respuesta de la avería devuelve `vinOrPlate` y `odometer` aunque el esquema no los declare? ¿O son alcanzables por la incidencia asociada, que sí los trae junto con `claimId`? | **G12 se retira**; basta documentar el patrón |
| **G31** | ¿`$apply` con `groupby` y `aggregate` funciona en los listados? El esquema `ApplyQueryOption` sugiere que sí | **G31 se retira**; basta documentarlo con ejemplos |
| **G18** | ¿El texto del certificado es completo, fiel y estable entre llamadas? | **G18 se reduce** a una garantía por escrito. Si resultara incompleto, **G19 pasa a bloqueante de la etapa 1** |

## 5. Cómo priorizar si se quiere avanzar en algo de aquí

Sin ningún compromiso, el orden que más valor da por unidad de trabajo:

1. **G02** — decidir qué pasa con el `refreshToken` que se emite y no se puede canjear. Es una incoherencia del contrato actual y se resuelve en cualquiera de las dos direcciones.
2. **G11, G14, G17** — tres piezas pequeñas que juntas hacen la lectura del expediente mucho menos frágil.
3. **G13** — la fecha de paso a `Validación`. Es lo único que permite medir el compromiso contractual de 48 horas hábiles, hoy inmedible.
4. **G19** — la más costosa y la de mayor impacto. Vale plantearla como conversación de producto, no como un endpoint más.
5. **G30 y G32** — cuando el Copiloto llegue a la etapa 4.
6. **G33 y G34** — cuando exista la decisión de plataforma sobre Colombia y Chile.
