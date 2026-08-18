# BMW — paquete de cambios ago-2026 · plan técnico

**Fecha:** 14-ago-2026 · **Base:** respuestas de negocio del 14-ago
**Insumo para el PRD.** Sustituye a `bmw-careplus-y-modulo-usuarios-{plan,preguntas}.md` (eliminados).

Seis frentes. Todo verificado en código y en BD; cada afirmación lleva su referencia.
Repos en `main` y al día: `bmw_landing` (67b9012), `gp_3.0_siga_api` (89a79f2), `gp_4.0_siga` (59c1826),
`bridgestone_landing` (3320eae).

| # | Frente | Repos | Bloqueado por |
|---|---|---|---|
| W1 | Care Plus + Contado factura al distribuidor | api, landing | — |
| W2 | Público en general + reintento + error real del PAC | api, **gp_4.0_siga** | **D1** |
| W3 | Módulo de alta de usuarios BMW | api, landing | — |
| W4 | Modalidad "Financiamiento externo" | api, landing | D4 |
| W5 | Paginación + folio de factura en el listado | api, landing | D5 |
| W6 | Avería sólo con VIN y descripción | **gp_4.0_siga** | **D3** |

---

## 0. Decisiones tomadas (14-ago)

| # | Tema | Decisión |
|---|------|----------|
| 1 | Care Plus al distribuidor | Sólo cuando **producto = Care Plus Y modalidad = Contado**. Se ocultan CP fiscal y régimen fiscal. Nombre y RFC se siguen pidiendo y guardando en el contrato; los datos fiscales del CFDI son los del distribuidor |
| 2 | Uso de CFDI al dealer | `S01` por ahora (sin cambio). Negocio confirmará después |
| 3 | Care Plus ya vendidos | Se dejan como están. No se refacturan |
| 4 | Datos fiscales de los 48 dealers | **Se quedan genéricos.** Se acepta que el timbrado marque error |
| 5 | Lista blanca del módulo de usuarios | **Correos en `appsettings`** |
| 6 | Credencial del alta | **Contraseña en claro por correo**, como hace SIGA hoy |
| 7 | Quién administra | Carlos y Alexis — los mismos de `ContractActivation:AllowedUsers` |
| 8 | Editar el correo | **Sí** se permite |
| 9 | Usuarios existentes | Los 640 aparecen en el listado. El módulo lleva **filtros de búsqueda y de estado activo/inactivo** |
| 10 | Alcance del administrador | Los **48 distribuidores** BMW (decidido antes) |
| 11 | Rol que se puede dar de alta | Sólo **"Usuario Distribuidor"**, fijado por el servidor |
| 12 | Eliminación | **Lógica** (desactivación) |

---

## 1. Tres hallazgos que cambian la forma del trabajo

### 1.1 · El error del PAC nunca cruza el gRPC — y ese es justo el try/catch que falta

Tenías razón en que faltaba un try/catch. Está localizado:

```csharp
// gp_4.0_siga/FacturacionGarantiplus/Infrastructure/Server/FacturacionServer.cs:193-203
public override async Task<SingleInvoiceResponse> MakeSingleInvoice(SingleInvoiceRequest request, ServerCallContext context)
{
    ...
    await _billingService.BillSingleInvoiceSingleContract(contractId: request.IdContrato, orderId: null);
    ...
    return new SingleInvoiceResponse();   // ← SIEMPRE vacío: sin try/catch, sin error, sin id_factura, sin uuid
}
```

El contrato gRPC **sí** tiene los campos (`protos/Facturacion.proto:21-28`:
`id_factura, uuid, xml, pdf, error`) y el consumidor **ya los lee**
(`BmwPaymentService.InvoiceContractAsync`, `BmwPaymentService.cs:80-91`, devuelve `(bool Ok, string? Error)`).
El hermano `MakePaymentOrder` (`FacturacionServer.cs:177-191`) **sí** propaga su error. `MakeSingleInvoice` es
el único que no.

Y cuando el PAC rechaza, el error se pierde dos veces:

1. `GetInvoiceSeal` (`BillingServiceMX.cs:156-197`) hace `invoice.SelectSingleNode("//tfd:TimbreFiscalDigital")`
   y, sin comprobar nulo, lee `timbre.Attributes...` (`:169`) → **NullReferenceException**. El texto del rechazo
   viene en la respuesta del PAC y sólo queda en el log (`GetPACResponseForCFDI`, `:240` y `:264`,
   `_logger.Information(output)`). Por eso el CFDI40130 sólo se pudo ver leyendo el log del contenedor.
2. La NRE sube sin capturar y gRPC la convierte en un `RpcException` genérico. Contracts la atrapa en su
   `catch` (`BmwPaymentService.cs:93-97`) y registra *"Exception was thrown by handler"*.

**Efecto secundario que ya existe:** hoy, cuando el timbrado tiene éxito, `MakeSingleInvoice` tampoco
devuelve `id_factura` ni `uuid`, así que el log de éxito de Contracts (`:88-90`) imprime valores vacíos.

Esto obliga a tocar y desplegar `FacturacionGarantiplus`. **No es un problema**: todos los proyectos del repo
de SIGA se despliegan a mano con `dotnet publish` + subida de DLLs, y de eso se encarga el desarrollador. Es
la única forma de que el reintento del back sepa *por qué* falló; sin el error tipado, el reintento sería a
ciegas.

### 1.2 · "Público en general" choca con CFDI40130 — y define si algo timbra

Regla del SAT verificada en producción el 13-ago: si `Rfc = XAXX010101000` **y** `Nombre` contiene
`"PUBLICO EN GENERAL"`, el CFDI **exige el nodo `InformacionGlobal`**, que `CFDIFactura.BuildXML` no
construye. EDICOM devolvió literalmente:

```
CFDI40130: Cuando el tipo de comprobante sea Ingreso y el campo Rfc del nodo receptor corresponda
al valor "XAXX010101000" y el campo Nombre del nodo Receptor contenga la descripción
"PUBLICO EN GENERAL", el nodo Información Global debe existir.
```

**Pero el 12-ago QA sí aceptó un CFDI con RFC genérico** — porque el nombre iba con el del cliente, no con
`PUBLICO EN GENERAL`; ahí la regla no aplica. Ese es el matiz que decide todo el frente W2:

| Variante del fallback | ¿Timbra? | Costo |
|---|---|---|
| **F1** — RFC `XAXX010101000` + régimen `616` + CP del emisor (`11000`), **conservando el nombre real** | Pasó en QA el 12-ago. **Sin verificar en PROD** | 3 líneas en `RepositoryMX` o en el back. Fiscalmente incongruente |
| **F2** — público en general de verdad: nombre `PUBLICO EN GENERAL` + `InformacionGlobal` | Sí, pero es una **factura global periódica**, no una por contrato | Desarrollo en `CFDIFactura.BuildXML` + proceso de agregación. Contradice *"el proyecto de facturación sigue igual"* |
| **F3** — no timbrar cuando no hay datos fiscales | N/A | Lo más barato y honesto, pero no cumple lo pedido |

El código ya tiene la mitad de F1 escrita y muerta: `RepositoryMX.cs:199` calcula
`bool facturaGenerica = rfcReceptor.Equals("XAXX010101000")` y **nunca la usa**; el comentario de `:229-234`
dice explícitamente que debía forzar régimen 616 y el CP del emisor, y la lógica nunca se escribió. La misma
clase **sí** lo hace bien en la ruta consolidada (`:743-747`).

→ **Decisión pendiente D1.** Es la que desbloquea W2 y, de rebote, si Care Plus llega a timbrar.

### Fase 0 · La prueba en PROD que decide D1 — va primero, antes de escribir nada más

Hay un banco de pruebas ideal: los contratos de la **cartera Allianz** ya cargados en PROD, que fueron a
público en general y **no timbraron por esta misma razón**. La prueba es tomar uno, mandarlo **con
`InformacionGlobal`** y ver si EDICOM lo acepta.

**Lo que hay que cambiar para poder probar** (todo en `gp_4.0_siga/FacturacionGarantiplus`):

| # | Cambio | Dónde |
|---|---|---|
| 1 | Propiedades `Periodicidad`, `Meses`, `Anio` en el CFDI | `Entities/Classes/CFDIFactura.cs` |
| 2 | Emitir `<cfdi:InformacionGlobal>` como **primer hijo** de `Comprobante`, antes de `Emisor` | `CFDIFactura.BuildXML`, insertar antes de `:329-336` |
| 3 | **Los mismos tres atributos en la cadena original**, después de `LugarExpedicion` (`:151`) | `CFDIFactura.GeneraCadenaOriginal:99-155` |
| 4 | Poblar los tres campos reusando la variable muerta `facturaGenerica` | `RepositoryMX.cs:199` |
| 5 | El try/catch de §3.1, para ver el error del PAC sin leer el log del contenedor | `BillingServiceMX.cs:168`, `FacturacionServer.cs:193` |

⚠️ **El punto 3 no es opcional.** `GeneraCadenaOriginal()` y `BuildXML()` están escritos a mano y por
separado; si sólo se agrega el nodo al XML, el sello deja de corresponder y el PAC rechaza por **sello
inválido** — un falso negativo que no responde nada.

**Guard que hace la prueba segura en PROD:** emitir `InformacionGlobal` **sólo** cuando
`rfc == "XAXX010101000"` **y** `nombre == "PUBLICO EN GENERAL"` — que es literalmente la condición de
CFDI40130. Ningún contrato de la landing cumple eso, porque `WriteClientFiscalDataAsync` escribe
`razon_social = contrato.nombre` (el nombre real del cliente). El cambio no puede alterar el flujo vivo.

**Dos cosas que hay que ajustar en los datos del contrato de prueba, no en código:**
- **`metodo_pago` debe ser `PUE`**, no `PPD`. Una factura global es de operaciones ya cobradas; con `PPD`
  el PAC la rechaza por otra regla. Además `BuildXML:296` fuerza `FormaPago="99"` cuando el método es `PPD`,
  y `RepositoryMX:205` pone `CondicionesDePago="CREDITO"`. Con `PUE` ambos quedan correctos.
- **`descuento` debe ser 0** en la póliza de prueba. Hay un bug latente: en la cadena original el `Descuento`
  se emite después de `LugarExpedicion` (`:152-154`) cuando el SAT lo pide entre `SubTotal` y `Moneda`. Hoy
  no afecta porque BMW no usa descuento, pero contaminaría la prueba.

**Lo que NO es problema:** `fecha_factura` es `SELECT NOW()` (`RepositoryMX.cs:81`), así que la regla de las
72 horas no aplica por más viejo que sea el contrato. Y `Exportacion="01"` ya va fijo (`:322`), que es lo
correcto para una global.

**Periodicidad sugerida:** `01` (Diario), `Meses` = mes en curso, `Año` = año en curso — porque la fecha del
comprobante es `NOW()`. Una factura global con **una sola** operación es válida.

**Llamada:** el proto **no declara `package`** (sólo `csharp_namespace`), así que el método es
`BillingService/MakeSingleInvoice`, sin prefijo. El servicio escucha en el puerto **10001**.

```bash
grpcurl -plaintext -proto protos/Facturacion.proto \
  -d '{"id_contrato": <ID>}' \
  <host>:10001 BillingService/MakeSingleInvoice
```

⚠️ **Si la prueba sale bien, el CFDI es real y fiscalmente válido**, con UUID ante el SAT. No es reversible
sin un proceso de cancelación. Conviene elegir un contrato de importe bajo y del grupo que de todas formas se
querría facturar.

**Cómo se lee el resultado:**

| Resultado | Qué significa |
|---|---|
| Timbra con UUID | **F2 es viable.** La factura global resuelve público en general, y cambia la conversación de W1/W2 completa |
| CFDI40130 otra vez | El nodo no se emitió bien o no en la posición correcta → revisar XML contra la XSLT |
| Error de sello | Falta el punto 3: la cadena original no coincide con el XML |
| Otro código CFDI4xxxx | Hay una regla más de la global (método de pago, periodicidad, importe). Se itera: cada intento es barato |

### 1.3 · La avería ya tiene configuración por proyecto — pero no cubre lo que bloquea

`ClaimRegistrationRequirements` (`PaisesService/Classes/ClaimRegistrationRequirements.cs:12-15`) existe y
—a diferencia del resto de banderas de `PaisesService`— **ya es por proyecto, no sólo por país**:

```csharp
// PaisesService/Classes/MX/PaisMX.cs:24-35
private static readonly Dictionary<int, ClaimRegistrationRequirements> ClaimRegistrationRequirementsByProject = new()
{
    { BridgestoneProjectId, new ClaimRegistrationRequirements
        { VinRequired = false, DescriptionRequired = false, VinMinLength = 0, DescriptionMinLength = 0 } }
};
// :1663-1670 → si el proyecto no está en el diccionario, devuelve .Default
```

Bridgestone (173) ya lo usa en producción; **BMW (206) no está**. Meterlo ahí **no afecta a ningún otro
proyecto de MEX** — a diferencia de los demás flags de `IPaisBusinessRules`, cuyas firmas no reciben
`idProyecto` y sí son por país.

⚠️ **Pero ese flag sólo relaja VIN y descripción, que son justo los dos campos que SÍ queremos pedir.** Los
que estorban son otros dos, y ninguno es configurable:

- **`id_contrato`** — `[Required]` en `RegistroAveria.cs:10`, y es la **única** llave con la que se localiza
  la póliza (`ClaimValidator.cs:77-90`, `AveriasBusinessRules.cs:2325`). `averia.id_poliza` es NOT NULL sin
  default. **No existe hoy ningún camino que busque la póliza por VIN solo** (`AveriasController.FindVin`
  existe pero está huérfano, cero referencias).
- **`producto_involucrado`** — `[Required]` en `RegistroAveria.cs:24`; de ahí salen `id_producto`,
  `id_proyecto` y `tipo`. Sin él se rompen el chequeo de avería duplicada (`ClaimValidator.cs:34-51`) y la
  asignación automática de técnico.

Y el VIN **no identifica unívocamente una póliza**: `idx_vehiculo_vin` no es único y en la BD hay
**16,604 VINs con más de una póliza** (para BMW hoy no hay duplicados, pero la ambigüedad es estructural).

→ **Decisión pendiente D3.**

---

## 2. W1 · Care Plus + Contado factura al distribuidor

**Precedencia de la decisión de facturación** (queda así, en este orden):

```
1. Care Plus  Y  Contado           → receptor = DISTRIBUIDOR
2. sin CP fiscal ni régimen        → receptor = genérico (W2)
3. resto                           → receptor = CLIENTE (comportamiento actual)
```

### Backend — `Services/Contracts`

| # | Cambio | Dónde |
|---|---|---|
| 1 | Flag `BmwPaymentFlow.CarePlusDealerBillingEnabled` (default `false`, fail-safe como el resto) | `Options/BmwPaymentFlowOptions.cs`, `appsettings.json:222` |
| 2 | Resolver si el contrato es Care Plus. El dato canónico es `producto_proyecto.facturar_a_nombre`, que `VentasBusinessRules.cs:425,768` ya vuelca en `contrato.tipo_facturacion` → basta con **respetar** ese valor en vez de asumir `"Beneficiario"` | `BmwController.cs:1782-1838` (rama Contado) |
| 3 | En la rama Contado: si es Care Plus → `ApplyDealerBillingAsync`; si no → el flujo actual, intacto | `BmwController.cs:1787-1805` |
| 4 | Restaurar `ApplyDealerBillingAsync` + `WriteDealerFiscalsAsync` de `f6acc67`, sin el guard de datos fiscales (decisión 4: se acepta que falle) pero **logueando** cuando el dealer va con RFC genérico | `Services/Bmw/BmwPaymentService.Billing.cs` |
| 5 | Limpiar comentarios que hoy mienten y código muerto | `BmwController.cs:1779`, `BmwBillingOptions.cs:36`, `BmwPaymentService.Billing.cs:15-18`, `BmwPaymentService.cs:314-315` |

### Datos

`UPDATE producto_proyecto SET facturar_a_nombre='Distribuidor'` para los **33 productos Care Plus** del
proyecto 206 — identificados por `bmw_modelo_producto.linea_producto='Care Plus'`, **nunca por id**
(ids impares 8023–8087 sólo como referencia). Script por ambiente; no hay migraciones EF.

⚠️ Ojo: `facturar_a_nombre` es por producto, **no por modalidad**. Al ponerlo en `Distribuidor`, un contrato
Care Plus **Enganche o Financiado** también nacería con `tipo_facturacion='Distribuidor'`. Como la rama
Enganche/Financiado (`BmwController.cs:1843-1920`) sobrescribe a `"Beneficiario"`, el resultado final es el
correcto — pero hay que dejarlo explícito en el código y en la prueba de no regresión, porque hoy depende de
un efecto colateral.

### Landing — `bmw_landing`

| # | Cambio | Dónde |
|---|---|---|
| 6 | Ocultar el bloque de CP fiscal + Régimen fiscal **sólo** si `linea === 'Care Plus' && paymentModality === 'Contado'`. Hoy se muestran siempre, en todas las modalidades | `sections/ClientDataSection.tsx:150-180` |
| 7 | No exigirlos en esa combinación (hoy la regla es "si viene uno, viene el otro") | `validation.ts:80-96` |
| 8 | Nombre y RFC **siguen igual**: se piden y se guardan en el contrato | sin cambio |
| 9 | Bump `v1.0.12` → `v1.0.13` en `.env`, `.env.qa`, `.env.production` | (CLAUDE.md dice v1.0.3, está desfasado) |

> **Observación de negocio, para que quede dicha:** con la decisión 4 (dealers con `XAXX010101000`), el CFDI
> saldría a nombre del distribuidor pero con **RFC genérico** — es decir, **el dealer no puede deducirlo**.
> Si el objetivo era que dedujera, hace falta el RFC real; si el objetivo era sólo que la factura no salga a
> nombre del cliente, con genérico alcanza. Ver **D2**.

---

## 3. W2 · Público en general + reintento + error real del PAC

### 3.1 · Que el error del PAC llegue al back — `gp_4.0_siga`

| # | Cambio | Dónde |
|---|---|---|
| 1 | En `GetInvoiceSeal`, comprobar `timbre == null` antes de leer atributos; extraer el texto del rechazo de `PACResponse` y lanzar una excepción tipada (`PacRejectionException` con código y mensaje) en vez de la NRE | `BillingServiceMX.cs:168-169` |
| 2 | `try/catch` en `MakeSingleInvoice` que rellene `SingleInvoiceResponse.Error` con el mensaje del PAC, y `IdFactura`/`Uuid` en el éxito (hoy tampoco se devuelven). Copiar el patrón de `MakePaymentOrder` | `FacturacionServer.cs:193-203` |

**Comportamiento sin cambios**: no se toca cómo se arma ni cómo se sella el CFDI. Sólo deja de tragarse el
error. Es lo mínimo compatible con *"el proyecto de facturación debe seguir funcionando igual"*.

### 3.2 · Decidir el receptor y reintentar — `Services/Contracts`

| # | Cambio | Dónde |
|---|---|---|
| 3 | Si `FiscalPostalCode` y `FiscalRegime` vienen vacíos → escribir receptor genérico según **D1**. La condición ya está a la mano: `BmwController.cs:1771-1777` los normaliza a `null` | `BmwPaymentService.Billing.cs` (método nuevo `WriteGenericFiscalDataAsync`) |
| 4 | Si venían datos fiscales y `InvoiceContractAsync` devuelve `Ok=false` → reescribir `fiscales_poliza` a genérico y **reintentar una vez**. Un solo reintento, no bucle | `BmwController.cs:1796-1804` y `:1874-1885` |
| 5 | Registrar el resultado del reintento (éxito/fracaso + error del PAC) de forma consultable, no sólo en el log | a definir (columna en `bmw_registro` o LogsMonitor) |

**Aplica a las tres modalidades**, no sólo a Contado: hoy Enganche y Financiado también timbran al crear
(`EngancheInvoiceOnCreate` / `FinanciadoInvoiceOnCreate` en `true`).

⚠️ **Efecto secundario a manejar:** `PersistInvoiceEntity` inserta la fila en `factura` **antes** de pedir el
sello (`BillingServiceMX.cs:86`), así que cada intento fallido deja una factura huérfana (`sellada=0`, sin
`factura_poliza`). Ya hay **522 huérfanas** de los últimos 90 días; con reintento automático se duplican. No
bloquea (no hay único por serie+folio), pero conviene marcarlas o limpiarlas.

---

## 4. W3 · Módulo de alta de usuarios BMW

### 4.1 · Punto de partida

En la API **no existe nada**: cero endpoints de alta, edición, baja, asignación de rol o de distribuidor
(grep de `UserManager|CreateUser|AddToRole` en `Services/**` → 0 resultados). Sólo hay dos GET globales
(`UsersController.cs:67,131`), ambos `Administrador General` y sin scope. El único alta real vive en el
monolito (`UsuariosController.cs:216-407`). Y los modales `AddManagerModal`/`AddFiModal`/`AddAdvisorModal` de
la landing **no crean usuarios** — son filas de catálogo `bmw_gerente`/`bmw_ejecutivo_fi`/`bmw_asesor`. El
patrón de UI sirve; el backend es todo nuevo.

**Dónde va:** `Services/Authentication` — es el único servicio con `PasswordHasher<aspnetusers>`
(`AuthService.cs:23,146`), `IEmailSender` (`Program.cs:97-113`) y `DataAccess` completo
(`Authentication.csproj:29`) ya cableados.

Controller nuevo `LandingUsersController` → `/authentication/api/LandingUsers/v1/{projectId}/…`, con
allow-list de proyectos en `appsettings` (`LandingUserAdmin:AllowedProjectIds: [206]`).

| Verbo | Ruta | Rate limit |
|---|---|---|
| GET | `access` → `{ canManage, distributors[] }` | `Standard` |
| GET | `users` → listado scoped, con filtros y estado | `Standard` |
| POST | `users` → alta | `Restrictive` |
| PUT | `users/{id}` → nombre, correo y dealers | `Restrictive` |
| POST | `users/{id}/deactivate` · `users/{id}/activate` | `Restrictive` |

### 4.2 · Lista blanca — reusar el patrón que ya existe

`ContractActivationService.IsCallerAllowed(ClaimsPrincipal)`
(`Services/Contracts/Services/ContractActivationService.cs:41-67`) ya hace exactamente esto: lee
`ContractActivation:AllowedUsers` de `appsettings`, **falla cerrado si la lista está vacía** (`:44-50`), y
compara contra los claims `UserName` / `email` / `Identity.Name` sin distinguir mayúsculas.

Los correos son los mismos (`appsettings.json:193-198`):
```json
"ContractActivation": { "AllowedUsers": [ "carlos.castellanos@garantiplus.mx", "alexis.herrera@gplusseguros.mx" ] }
```

→ Sección nueva `LandingUserAdmin:AllowedUsers` con esos dos correos, y el helper movido a `Common/` para no
duplicarlo entre `Contracts` y `Authentication`.

### 4.3 · Qué escribe el alta (transacción única)

| Tabla | Qué |
|---|---|
| `AspNetUsers` | `Id`, `UserName` = `Email`, `Normalized*` en mayúsculas, `EmailConfirmed=true`, `PasswordHash`, `SecurityStamp`, `ConcurrencyStamp`, **`LockoutEnabled=true`**, `nombre` |
| `AspNetUserRoles` | Un solo rol: **"Usuario Distribuidor"**, resuelto **por nombre** en runtime (el GUID cambia entre ambientes) |
| `usuario_distribuidor` | Una fila por dealer (PK compuesta `id_distribuidor`+`userid`) |
| `usuario_creador` | `(userid, userid_creador)` — rastro de quién dio de alta a quién |
| ~~`proyecto_usuario`~~ | **No se escribe**: el proyecto se deriva de `distribuidor.id_proyecto` |

Contraseña generada con el mismo criterio del monolito (`aspnetusers.cs:92-135`) y enviada por correo con la
plantilla que **ya existe**: `correos_proyecto` id **200**, proyecto 206, tipo `UserRegistrationEmail`,
`enviar=true`, con `{{nombre}} {{usuario}} {{contrasena}} {{url}}`. Se lee el mismo renglón que usa el
monolito (`CatalogosBusinessRules.cs:2991-3023`) para no tener dos textos oficiales. El correo se manda
**después del commit**.

### 4.4 · Candados

| # | Candado | Por qué |
|---|---|---|
| 1 | Lista blanca validada **en el servidor, en cada petición** | Verificado: el valor de `BASE_API_PATH` aparece en texto claro en `dist/assets/index-*.js`. En el front sería cosmética |
| 2 | **El rol lo pone el servidor.** No se acepta `roleId` en el body | Sin esto, un POST con el GUID de `Administrador General` crea un superusuario |
| 3 | Todo `id_distribuidor` validado contra `distribuidor WHERE id_proyecto=206 AND activo` | Sin el filtro por proyecto, mandar un dealer de Bridgestone crea accesos cruzados |
| 4 | Correo existente → **409, nunca upsert** | Un upsert sería la vía directa para agregarse dealers a una cuenta de GP |
| 5 | **Objetivo confinado**: antes de tocar `{id}`, debe tener *exactamente* el rol Usuario Distribuidor y *todas* sus filas de `usuario_distribuidor` en el proyecto 206. Si no → **404** (no 403) | Es lo que impide desactivar a un Administrador General desde el módulo |
| 6 | La respuesta **nunca** lleva la contraseña; sólo va en el correo al buzón del nuevo usuario | Decisión 6 acepta el correo en claro; no hay razón para exponerla también en la API |
| 7 | Baja lógica = `LockoutEnd = MaxValue` **y `LockoutEnabled = true`** + rotar `SecurityStamp` | `AuthService.cs:78` **ignora `LockoutEnd` si `LockoutEnabled=false`** → un "desactivado" seguiría obteniendo JWT (hay 1 usuario así en MEX). ⚠️ Un token ya emitido vive hasta 60 min |
| 8 | El admin no puede editarse ni desactivarse a sí mismo | Como también es Usuario Distribuidor, el candado 5 lo haría aparecer en su propio listado |
| 9 | Todo en transacción; correo al final | El `Create` del monolito no la usa (`UsuariosController.cs:304-380`) y deja usuarios huérfanos |
| 10 | Auditoría con `User.FindFirst("Id")` y `"UserName"`, **no `sub`** | El token no emite `sub`; hay bug vivo por eso en `UsersController.cs:141` |
| 11 | Rate limit en mutaciones (`Restrictive`, 20/min) | Mecanismo ya existente |
| 12 | Listado propio y scoped; **no reusar `GetAllUsers`** | Es global y sin scope |
| 13 | Todo por EF, parametrizado | El monolito arma `UPDATE ... SET nombre='{0}'` con `string.Format` (`UsuariosController.cs:310-311`) |
| 14 | ⚠️ **Editar el correo cambia la identidad de login** (decisión 8). Hay que actualizar `UserName`, `NormalizedUserName`, `Email` y `NormalizedEmail` juntos, revalidar unicidad y **auditar el cambio con valor anterior y nuevo** | Cambiar el correo de un usuario + "olvidé mi contraseña" es una toma de cuenta. El candado 5 limita el radio a usuarios de dealer BMW, pero el rastro es obligatorio |

### 4.5 · Landing

- Ruta `/usuarios` + `/embed/usuarios` en `App.tsx:33-44`, **página propia** (patrón de `ResetPasswordPage`).
- Guard: al montar, `GET access`. Cosmético por diseño; cada endpoint revalida.
- Entrada: botón en el bloque de "Sesión activa" (`LandingView.tsx:83-129`), sólo si `access.canManage`.
- **Filtros (decisión 9)**: por nombre, correo, distribuidor y **estado activo/inactivo**. Con ≤700 usuarios
  el filtrado client-side del patrón de `CreatedContractsView.tsx:317-353` alcanza; si se prefiere
  server-side, aplica lo mismo que W5.
- Reutilizar: tabla y filtros de `CreatedContractsView.tsx`, `ConfirmDeleteDialog.tsx`, patrón de modal de
  `AddManagerModal.tsx`, primitivas `Input`/`Button`/`Select`.
- Selector de distribuidores: `components/ui/Select.tsx` es de valor único → con 48 dealers, **checkboxes con
  buscador** dentro del modal.
- Servicio nuevo `src/services/sigaUsersService.ts`; exportar `bmwGetJson`/`bmwSendJson`
  (`sigaService.ts:549,579`, hoy privados) o extraerlos a `src/services/http.ts`.

---

## 5. W4 · Modalidad "Financiamiento externo"

La modalidad es **texto libre de punta a punta**: no hay catálogo, ni enum, ni FK.
`bmw_registro.modalidad_pago` es `varchar(30)` sin CHECK — *"Financiamiento externo"* mide 22, cabe.
`bmw_modelo_producto` **no tiene columna de modalidad** y `ResolveProductAsync` la descarta explícitamente
(`ProductResolution.cs:27`, `_ = paymentModality;`), así que **no hay filas nuevas de catálogo ni cambio de
esquema**. El precio tampoco depende de la modalidad.

**Riesgo #1 — el punto que no se puede olvidar:** `BmwController.cs:1843-1845` ramifica con
`"Enganche" || "Financiado" || "Financiamiento"` y **no tiene `else`**. Una modalidad desconocida no ejecuta
nada: contrato creado **sin timbrar, sin ODP y sin `medio_pago`/`tipo_facturacion`**, y en silencio, porque
todo va dentro de un `try/catch` best-effort.

**Riesgo #2 — tres arrays duplicados en la landing.** Están tipados como `PaymentModality[]`, no como
exhaustivos, así que **TypeScript no avisa** si se olvida alguno: el listado mostraría `—` y tomaría la rama
de pago equivocada.

| # | Cambio | Dónde |
|---|---|---|
| 1 | Unión de tipos `PaymentModality` | `bmw_landing/src/types.ts:3` |
| 2 | Array `PAYMENTS` del dropdown | `sections/ProductDetailSection.tsx:14-18` |
| 3 | Array `PAYMENT_MODALITIES` (normalización del listado) | `lib/registrationDocuments.tsx:5` |
| 4 | Array `PAYMENTS` del OCR | `lib/mergeInvoiceOcrIntoForm.ts:8` |
| 5 | Prompt de Gemini | `services/invoiceOcrGemini.ts:100` |
| 6 | **Agregar el literal al `else if`** | `BmwController.cs:1843-1845` |
| 7 | Si necesita claves CFDI o flags propios: `BmwBillingOptions.cs:40`, `BmwPaymentFlowOptions.cs`, `appsettings.json:199-229` y refactor del binario `isEnganche` (`BmwController.cs:1847,1851-1866,1871-1873,1889-1891`) | ver **D4** |

Resultado esperado, idéntico a Financiado (verificado en BD): `contrato.tipo_pago = 2` (ya sale gratis de
`MapPayment`, `BmwLandingContractRequestFactory.cs:331-344`), `medio_pago = "Orden de pago"`,
`tipo_facturacion = "Beneficiario"`. **Nada que tocar en `gp_4.0_siga`.**

---

## 6. W5 · Paginación y folio de factura en el listado

BS ya lo tiene y es portable: commit `87b75e0` tocó 3 archivos de front.

### El folio ya existe, sólo falta exponerlo
- Columna: `bmw_registro.folio_factura_vehiculo` (BS la llama `folio_factura` — **ojo con el nombre**).
- Ya se captura (`buildBmwContractFormData.ts:45` → `BmwController.cs:1593` → `BmwRegistrationService.cs:424,438,480`)
  y ya tiene validación de duplicado (`:376-383`).
- Falta: `SELECT` en `BmwRegistroQueryService.BuildListSql` (`:145-197`), propiedad en
  `BmwRegistroListResponses.cs`, tipo TS y `<td>`.

### Paginación
BS es **server-side vía OData**: `[AutoODataFilter]` + `ODataQueryOptions<T>`
(`BridgestoneController.cs:306-342`), y el front manda `%24top/%24skip/%24filter/%24orderby`
(`bridgestone_landing/src/services/sigaService.ts:97-108`). La respuesta trae
`{ value: [...], pagination: { total, pageSize, currentPage, totalPages } }`.

**El pipeline OData ya está registrado en el microservicio Contracts** (`Program.cs:298-304`), así que BMW no
necesita tocar `Program.cs`. El endpoint de BMW (`BmwController.cs:1267-1305`) hoy no tiene ni
`[AutoODataFilter]` ni `ODataQueryOptions`, y devuelve un objeto envuelto (`{ Items: [...] }`) en vez de
`IQueryable`.

⚠️ **Tres filtros de BMW no sobreviven tal cual a server-side** (esto es **D5**):
- **Estatus**: es un `<select>` cuyas opciones se derivan de las filas cargadas
  (`CreatedContractsView.tsx:308-315`) → con paginación sólo vería los estatus de la página actual.
- **Modalidad de pago**: filtra sobre `resolveRowPaymentModality(r)`, un valor **derivado en cliente**
  (`lib/registrationDocuments.tsx:25`) que no es propiedad del DTO.
- **Inicio**: compara contra la cadena de fecha ya formateada en español (`:326-330`).

Y `contractRows = rows.filter(hasValidContractId)` (`:302-305`) oculta registros sin contrato en cliente; en
BS eso lo hace el backend con `contractId ne null`. Con paginación server-side ese filtro rompería el conteo.

BS **no tiene componente de paginación reutilizable** — es JSX inline (`CreatedContractsView.tsx:387-415`,
sólo Anterior/Siguiente, `PAGE_SIZE = 20`, debounce de 800 ms). Las primitivas `ui/` son las mismas en ambos
repos (`Button` difiere sólo en el color por defecto), así que el bloque se copia tal cual.

---

## 7. W6 · Avería sólo con VIN y descripción

Alcance: `TallerExternoController` (`gp_4.0_siga`), rol `Taller` / `Usuario Distribuidor-Taller`.

**Lo fácil ya está resuelto:** agregar BMW (206) al diccionario `ClaimRegistrationRequirementsByProject`
(`PaisMX.cs:24-35`) con `VinRequired=true, DescriptionRequired=true` y longitudes mínimas — o dejar el
`Default`, que ya los exige. Y **ocultar los campos que sobran**: hoy los `@if (claimVinRequired)` /
`@if (claimDescriptionRequired)` sólo existen **dentro del bloque comentado** de `Registro.cshtml:67-146`
(líneas `:107` y `:125`); el marcado vivo (`:30-62`) muestra todo siempre. Los flags hoy sólo afectan reglas
de validación jQuery, no visibilidad.

**Lo que bloquea de verdad** (ver §1.3): `id_contrato` y `producto_involucrado` son `[Required]` y no
configurables, y sin contrato no hay forma de resolver `averia.id_poliza` (NOT NULL). → **D3**.

Además, si la simplificación debe valer también para el agente de IA/WhatsApp:
`ClaimsController.CreateClaim` y `IssuesController.CreateIssue`/`ConvertToClaim` (`gp_3.0_siga_api`)
**no leen `ClaimRegistrationRequirements`** y siguen exigiendo `ContractId` + `VinOrPlate` + `Description`
por `[Required]` en los DTOs. Un cambio hecho sólo en el monolito no aplica ahí.

---

## 8. Decisiones que faltan

| # | Decisión | Bloquea | Recomendación |
|---|---|---|---|
| **D1** | Forma del fallback "público en general": **F1** (RFC genérico + 616 + CP del emisor, conservando el nombre real), **F2** (factura global con `InformacionGlobal`) o **F3** (no timbrar) | **W2 entero** | **Se decide con la Fase 0** (§1.2): prueba directa en PROD sobre un contrato Allianz. Si F2 timbra, gana F2 y deja de hacer falta el apaño de F1 |
| **D2** | ¿El objetivo de facturar Care Plus al dealer es que **deduzca**? | Cierre de W1 | Si es que deduzca, la decisión 4 (datos genéricos) no lo logra: el CFDI saldría con RFC `XAXX010101000` y no es deducible |
| **D3** | Avería sólo VIN + descripción: ¿de dónde sale la póliza? (a) se sigue pidiendo el contrato pero se ocultan los demás campos; (b) se resuelve por VIN — hay que definir qué hacer con VIN ambiguo; (c) sólo aplica a BMW, donde hoy no hay VIN duplicado | **W6** | (a) si "sólo VIN y descripción" se refería a los campos *visibles*; (b) es desarrollo nuevo, con `producto_involucrado` también por resolver |
| **D4** | "Financiamiento externo": ¿reusa las claves CFDI y los flags de Financiado, o lleva los suyos? | Alcance de W4 | Reusar. Si lleva propios, hay que refactorizar el binario `isEnganche` a tres casos |
| **D5** | Con paginación server-side se pierden los filtros de estatus, modalidad e inicio tal como están hoy. ¿Se aceptan filtros sólo sobre campos del DTO, como en BS? | Alcance de W5 | Sí, igualar a BS y exponer en el DTO lo que haga falta filtrar |

---

## 9. Estimación

Días de 8 h, escribiendo el código con Claude. Incluye pruebas. No incluye espera de terceros ni aprobación
de PR. Los rangos son reales, no colchón.

| Frente | Días | Nota |
|---|---|---|
| **Fase 0 · prueba de `InformacionGlobal` en PROD** | **1 – 2** | **Va primero.** Cambio en `CFDIFactura` + `RepositoryMX` + try/catch, publish manual, grpcurl. El rango es por si hay que iterar sobre la respuesta del PAC |
| W1 · Care Plus + Contado al distribuidor | 1.5 | Backend 0.75 · landing 0.5 · script 0.25 |
| W2 · Público en general + reintento + PAC | **3 – 5** | Código 2 · **iteración contra el PAC 1 – 3** |
| W3 · Módulo de usuarios | 7 | Backend 2.5 · landing 1.5 · ciclos y depuración de Identity 1.5 · pruebas 1.5 |
| W4 · Financiamiento externo | 1.25 | 6 puntos de código + config + pruebas |
| W5 · Paginación + folio | 2 | Backend 0.5 · landing 1 · pruebas 0.5 |
| W6 · Avería VIN + descripción | **0.5 – 3** | **Se resuelve al final** (decisión del 14-ago). 0.5 si es (a); 3 si hay que resolver la póliza por VIN |
| Despliegue y validación | 3.5 | 4 componentes por pipeline; `FacturacionGarantiplus` va por `dotnet publish` manual y lo hace el desarrollador |
| **Total** | **19.5 – 26 días** | ≈ 4 – 5 semanas |

**Entregas independientes, por si hay que comprometer algo antes:**

| Entrega | Días | Depende de |
|---|---|---|
| W4 + W5 (modalidad, paginación y folio) | 4.5 | D4, D5 |
| W3 (módulo de usuarios) | 8.5 | nada |
| W1 + W2 (facturación) | 6 – 8 | **D1** |
| W6 (avería) | 1.5 – 4 | **D3** |

---

## 10. Riesgos

- **La Fase 0 gobierna el frente de facturación.** Hasta que no se sepa si `InformacionGlobal` timbra, W1 y
  W2 no tienen forma definida. Por eso va primero y por eso su rango es el más ancho.
- **`FacturacionGarantiplus` tiene cambios locales sin commitear** en `appsettings.json` (igual que
  `PDFGenerator`). Revisarlos antes de publicar, para no subir configuración de local a PROD.
- **El reintento automático duplica las facturas huérfanas** (522 en 90 días). Hay que decidir si se marcan o
  se limpian.
- **W4 falla en silencio si se olvida `BmwController.cs:1843-1845`**: contratos sin timbrar y sin ODP, sin
  ningún error visible. Es el riesgo más barato de evitar y el más caro de descubrir tarde.
- **W6 puede ser 0.5 o 3 días** según D3, y si además debe aplicar al agente de IA/WhatsApp, crece: esos
  endpoints viven en otro repo y no leen la configuración de PaisesService.
- **Editar el correo (decisión 8) es cambiar la identidad de login.** Con contraseña en claro por correo
  (decisión 6), cambiar el correo y pedir "olvidé mi contraseña" es una toma de cuenta. El candado 5 limita
  el radio a usuarios de dealer BMW; la auditoría del candado 14 es obligatoria, no opcional.
