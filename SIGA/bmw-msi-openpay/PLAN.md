# Plan de Desarrollo — BMW: habilitar 3 y 6 MSI en la pasarela OpenPay

> Generado por Claude Code. **Sin PRD**: la fuente es la solicitud de negocio registrada como **T-007**
> en el tablero, siguiendo el mismo criterio que el plan `bmw-tyc-y-direccion-default`.
> **v0.2 (28-ago):** reescrito tras las correcciones del responsable — la landing queda transparente,
> `max_msi = 6` confirmado, y la verificación de OpenPay pasa a ser una prueba empírica.

| Campo | Detalle |
|---|---|
| PRD de origen | *(ninguno)* — Fuente: solicitud de BMW, tarea **T-007** del tablero |
| Repositorios | **Uno de código**: `gp_3.0_siga_api`. **Uno de datos**: `producto_proyecto` (SIGA) |
| Rama | `feature/bmw-msi-openpay` |
| Tipo | Feature |
| Responsable | Juan Carlos Castellanos Solis |
| Folio PRD | *(sin asignar — no hay generador de folios; se pide a gestión)* |
| Fecha de generación | 2026-08-28 (v0.2) |
| Estado | Borrador |
| ID plan (BD) | *(no registrado)* |
| Modelo / esfuerzo | `claude-opus-5` — esfuerzo normal |

---

## 1. Resumen técnico

**La cañería del MSI ya está construida de punta a punta y funciona.** Lo verifiqué siguiendo el dato
desde la pantalla de SIGA hasta el request de OpenPay:

```
SIGA  Catalogos > Pagos Pasarela        → producto_proyecto.pago_pasarela = 1
      PagosPasarelaController.Save         producto_proyecto.max_msi     = N
                                                    │
API   BmwRegistroQueryService:164 lee pp.max_msi ───┘   ✅ YA EXISTE
                                                    │
API   BmwPaymentLinkRequest.Msi  [Range(3,24)]  ────┘   ✅ YA EXISTE
      BmwPaymentService.cs:155 → MSI = request.Msi      ✅ YA EXISTE
                                                    │
SIGA  PaymenGatewayOpenPay.cs:185-190 ──────────────┘   ✅ YA EXISTE
      DeferralPayments { Payments = "6" }
```

**No hay que construir el mecanismo. Hay que decidir quién elige los meses, y ponerle un interruptor.**

**La landing no participa.** Decisión del responsable: la landing es transparente — no sabe de MSI, no
elige meses, no pinta selector. Sigue pidiendo el link como hoy (`{ paymentType: 1 }`) y mostrando lo
que reciba. Todo se configura en el backend. **Eso deja a `bmw_landing` fuera del alcance: no se toca.**

**Arquitectura:** ninguna nueva. Microservicio `Contracts` en ECS+Fargate.

---

## 2. Prerequisitos

- [x] **Meses confirmados: 3 y 6** — confirmado por el responsable
- [x] **Negocio al tanto** de que los MSI se habían quitado a propósito en junio
- [ ] **Ejecutar la prueba T-01**, que decide el diseño (ver §3). Nada de código antes
- [ ] **Pedir a OpenPay el % de comisión de 3 y 6 MSI** — ver §12 nota 1. No bloquea el desarrollo,
      sí el encendido en producción
- [ ] Acceso a la pantalla `Catalogos > Pagos Pasarela` de SIGA en QA y PROD

---

## 3. Arquitectura del cambio — la decisión que hay que tomar

Tres hechos verificados que acotan el problema:

**1. `max_msi` es un TOPE, no una lista.** El catálogo de meses de México está **hardcodeado** en
`PaisMX.GetMsi()` como `{3, 6, 9, 12}` (el `DbSet` de `meses_sin_intereses` está comentado: no hay
tabla). Con `max_msi = 6`, los valores por debajo del tope son exactamente `{3, 6}`.

**2. OpenPay recibe UN número, no un rango.** `DeferralPayments.Payments` es un `string` con un solo
valor. Así lo usa SIGA hoy (`ContratosController:4526`):

```csharp
MSI.plazos.Where(t => t.Key <= maxMsi)   // max_msi filtra la lista…
```
…y después **un humano elige un valor exacto** del dropdown. `max_msi = 6` **no** significa "ofrécele
3 y 6 al cliente"; significa "quien elija no puede pasar de 6".

**3. La landing no va a elegir.** Es la decisión del responsable, y es la correcta: la landing no
tiene por qué conocer la política comercial de meses.

De 1+2+3 sale la pregunta que ordena todo el plan: **si la landing no elige y `max_msi` solo es un
tope, ¿quién elige el número que se manda a OpenPay?** Solo hay dos respuestas posibles:

| | **Diseño A — elige el cliente en el checkout** | **Diseño B — lo fija el backend** |
|---|---|---|
| Qué manda la API | **Omite** `DeferralPayments` | `DeferralPayments = N` fijo desde `appsettings` |
| Quién elige | El cliente, en la pantalla de OpenPay | Nadie: todos los pagos salen a N meses |
| ¿Sobrevive el pago único? | **Sí** | **No** — se pierde |
| ¿Se puede limitar a 3 y 6? | Solo si OpenPay lo permite por comercio | Sí, pero es **un** valor, no dos |
| Landing transparente | ✅ | ✅ |

**El Diseño A es el que cumple lo que pidió el responsable sin efectos colaterales.** El B fuerza a
todos los clientes a meses y elimina el pago de contado, lo que casi seguro no es lo que se quiere.

**Pero A depende de un comportamiento de OpenPay que no podemos deducir del código**: que su checkout
ofrezca los meses cuando el comercio no los fuerza. Por eso **T-01 es una prueba, y va primero**.

Si A funciona ⇒ el trabajo es mínimo (el interruptor y poco más). Si A no funciona ⇒ hay que volver
con negocio, porque la única alternativa es forzar un valor único y perder el pago de contado.

**El interruptor** vive en `BmwPaymentFlow`, que ya es la convención para los flags de pago de BMW
(`ContadoGenerateOdp`, `ContadoEnableOpenPay`, …), y **nace apagado**.

---

## 4. Tareas de desarrollo

### Fase 0 — La prueba que decide el diseño (bloquea todo lo demás)

- [ ] **T-01** — Probar contra QA cómo se comporta OpenPay con y sin `DeferralPayments`
  - **No es revisar el panel**: en SIGA los MSI ya funcionan, así que el comercio ya los tiene
    contratados. Lo que no sabemos es cómo se comporta el checkout, y eso solo se ve probando
  - Sobre un contrato BMW de QA con pasarela, generar dos links y abrirlos:
    1. **Con** `msi: 6` (`POST payment-link` con el campo, que el DTO ya acepta) → confirma que el
       diferido llega y que el importe real de un producto BMW no cae por debajo del mínimo
    2. **Sin** `msi` → ver si el checkout **le ofrece los meses al cliente** y, si los ofrece,
       **cuáles** (¿3, 6, 9 y 12? ¿solo algunos?)
  - Criterio de completitud: sabemos si el Diseño A es viable y qué meses ofrece OpenPay por su cuenta
  - **Resultado ⇒ decisión:**
    - Ofrece meses y son 3 y 6 ⇒ **Diseño A**, sin más
    - Ofrece meses pero incluye 9 y 12 ⇒ **Diseño A** + averiguar si se limitan por comercio en OpenPay
    - No ofrece nada ⇒ **volver con negocio**: solo queda el Diseño B, que elimina el pago de contado

### Fase 1 — API: interruptor y validación (`gp_3.0_siga_api`) → **commit 1**

> Aplica a los dos diseños. Lo que cambia entre A y B es **T-04**.

- [ ] **T-02** — Añadir el interruptor a la configuración
  - Archivos: `Services/Contracts/appsettings.json` y el POCO de opciones de `BmwPaymentFlow`
  - ```json
    "BmwPaymentFlow": {
      "…": "…",
      "EnableMsi": false,
      "AllowedMsiMonths": [ 3, 6 ]
    }
    ```
  - **Nace en `false`**: se enciende cuando la Fase 3 valide en QA. Así el deploy es inocuo
  - Criterio de completitud: la opción se liga y se lee; con `EnableMsi=false` el comportamiento es
    idéntico al de hoy

- [ ] **T-03** — Validar el MSI en el servidor
  - Archivos: `Services/Contracts/Services/Bmw/BmwPaymentService.cs` (`GeneratePaymentLinkAsync`)
  - Rechazar con 400 y mensaje en español si llega un `Msi` fuera de las opciones efectivas
    (`AllowedMsiMonths` ∩ `≤ max_msi`, vacío si el flag está apagado)
  - Hoy **no hay ninguna validación**: el `[Range(3,24)]` del DTO no consulta ni el flag ni `max_msi`.
    Sigue siendo necesaria aunque la landing no mande MSI: el endpoint es público para quien tenga
    token, y el flag apagado tiene que significar apagado de verdad
  - Criterio de completitud: con el flag apagado, un POST con `msi: 6` responde 400 y no llega a OpenPay

- [ ] **T-04** — Aplicar el diseño que salga de T-01
  - **Diseño A:** no hay que tocar el envío. La API sigue sin mandar `DeferralPayments` cuando la
    landing no manda `Msi` (`PaymenGatewayOpenPay.cs:185` ya lo omite si viene `null`). **T-04 se
    reduce a documentarlo** y a dejar el flag gobernando la validación de T-03
  - **Diseño B:** cuando `EnableMsi` está encendido, la API inyecta el MSI configurado aunque la
    landing no lo mande. Requiere decidir **un** valor y asumir que se pierde el pago de contado
  - Criterio de completitud: el comportamiento coincide con lo decidido en T-01

- [ ] **T-05** — Registrar el MSI aplicado en el contrato
  - Archivos: `Services/Contracts/Services/Bmw/BmwPaymentService.cs`
  - Al generar un link con MSI, actualizar `contrato.pago_msi`. Ver el hallazgo H-1 en §12: hoy el
    contrato dice `0` aunque el cliente pague a meses
  - ⚠️ **En el Diseño A el MSI lo elige el cliente en OpenPay, así que al generar el link no se
    conoce.** Habría que tomarlo de la respuesta del cargo o del webhook. Evaluar en T-01 si el dato
    está disponible; si no lo está, **decirlo explícitamente** en vez de guardar un valor inventado
  - Criterio de completitud: `contrato.pago_msi` refleja la realidad, o se documenta por qué no puede

- [ ] **T-06** — Alinear el `[Range]` del DTO
  - Archivos: `Services/Contracts/DTOs/Bmw/Requests/BmwPaymentLinkRequest.cs`
  - Pasar de `[Range(3,24)]` a `[Range(3,12)]`. Ver H-2: hoy un `msi: 18` pasa la validación y SIGA lo
    **descarta en silencio**
  - Criterio de completitud: un `msi: 18` responde 400 en vez de colarse

- [ ] **T-07** — Subir la versión del servicio `Contracts`
  - Usar la skill `actualizar-version-servicio-gp` (4 lugares). Confirmar la etiqueta libre **contra
    el ECR** al momento de ejecutar: al cierre de este plan la última tomada es `v0.28`
  - Criterio de completitud: versión nueva y coherente en los 4 lugares

### Fase 2 — Datos: configurar los productos BMW

- [ ] **T-08** — Poblar `max_msi` en los productos BMW
  - **66 productos** del proyecto 206, hoy **todos** con `pago_pasarela = 1` y `max_msi = NULL`
  - Valor confirmado por el responsable: **`max_msi = 6`**
  - Vía **pantalla de SIGA** (`Catalogos > Pagos Pasarela`), no por script
  - ⚠️ Se aplica **por ambiente**: QA y PROD son bases distintas. Hacerlo en los dos
  - Criterio de completitud: `SELECT pago_pasarela, max_msi, count(*) FROM producto_proyecto WHERE
    id_proyecto=206 GROUP BY 1,2` devuelve una sola fila `1 | 6 | 66`

- [ ] **T-09** — Decidir si Care Plus también va a meses
  - Los 66 incluyen **BMW y BMW Care Plus** de cada modelo. Care Plus se factura al **distribuidor**,
    no al cliente, así que "quién absorbe la comisión" puede responderse distinto para esa línea
  - Criterio de completitud: confirmado con negocio

### Fase 3 — Validación en QA y encendido

- [ ] **T-10** — Validar con el flag **apagado** (no regresión)
  - Generar un link de pago BMW como hoy: debe salir sin MSI, exactamente igual que antes. Es la
    prueba de que el deploy es inocuo
  - Criterio de completitud: comportamiento idéntico al actual

- [ ] **T-11** — Encender el flag en QA y validar de punta a punta
  - Comprobar: el cliente puede pagar a **3 y 6 meses**; el cargo aparece **diferido** en OpenPay;
    `contrato.pago_msi` refleja lo que corresponda según T-05
  - Probar también **pago único** para confirmar que sigue funcionando
  - Criterio de completitud: un pago real de prueba a 3 y otro a 6, verificados en OpenPay
  - ⚠️ Encender el flag exige **imagen nueva** (el `appsettings.json` va horneado: ver §11 R-3)

- [ ] **T-12** — Encender en PROD
  - Solo después de T-11 y de tener el % de comisión sobre la mesa
  - Criterio de completitud: validado con un contrato real

---

## 5. Cambios en base de datos

Ninguno de esquema. **Sí de datos**, vía la pantalla de SIGA:

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `producto_proyecto` | Actualización de datos | `max_msi = 6` en los 66 productos del proyecto 206. Hoy `NULL`. `pago_pasarela` ya está en `1` |
| `contrato` | Escritura en columna existente | `pago_msi` (T-05, sujeto al resultado de T-01) |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `contracts/api/Bmw/v1/{projectId}/contracts/{id}/payment-link` | Empieza a **validar** el `msi` contra el flag y `max_msi`; `[Range]` a `[3,12]` | **Modificado** (el contrato del request no cambia) |

Ningún endpoint nuevo ⇒ **no hay que tocar KrakenD**. El listado de registros **no cambia**: como la
landing no pinta selector, no hace falta exponerle las opciones.

---

## 7. Variables de entorno y configuración

| Clave | Descripción | Ambiente |
|---|---|---|
| `BmwPaymentFlow:EnableMsi` | Interruptor general. **Nace en `false`** | Desarrollo / QA / Producción |
| `BmwPaymentFlow:AllowedMsiMonths` | Meses permitidos: `[3, 6]` | Desarrollo / QA / Producción |

Sin secrets nuevos. **`bmw_landing` no se toca**, así que no hay bump de versión de la landing.

---

## 8. Consideraciones de seguridad

- **La validación es del servidor.** T-03 existe aunque la landing no mande MSI: el endpoint es
  accesible para cualquiera con token válido, y "flag apagado" tiene que significar apagado de verdad.
- **Sin cambios de permisos ni de roles.** El endpoint ya valida el scope del contrato
  (`EnsureContractInScopeAsync`).
- **Riesgo financiero, no de datos.** Un MSI no autorizado no filtra información: cambia cuánta
  comisión paga GarantiPlus. Por eso la validación va en el servidor.

---

## 9. Consideraciones de infraestructura

- **`gp_3.0_siga_api`:** imagen nueva de `Contracts` y redeploy en QA y PROD. Sin recursos AWS nuevos.
- **`bmw_landing`:** no se toca. Sin build ni deploy.
- **`gp_4.0_siga` no se toca.** `PaymenGatewayOpenPay` ya soporta MSI y `PaisMX.GetMsi()` no debe
  modificarse (rompería a los otros proyectos).
- **Sin cambios** en Cloudflare, Route 53, RDS ni KrakenD.

---

## 10. Criterios de aceptación

- [ ] Con `EnableMsi = false`, el comportamiento es **idéntico al actual**
- [ ] Con `EnableMsi = true`, el cliente puede pagar a **3 y 6 meses**, y **el pago único sigue siendo
      posible**
- [ ] El cargo en OpenPay aparece **diferido** a los meses elegidos
- [ ] Un POST a `payment-link` con un MSI no permitido responde **400** y no llega a OpenPay
- [ ] Un `msi: 18` responde **400** en vez de descartarse en silencio
- [ ] Los 66 productos BMW quedan con `max_msi = 6` en QA y en PROD
- [ ] **`bmw_landing` sin cambios**: la landing no sabe de MSI
- [ ] **`PaisMX.GetMsi()` sin tocar**: Nissan, Autocom y GP Renovaciones conservan sus 12 MSI
- [ ] Cambiar los meses permitidos no requiere tocar código, solo `AllowedMsiMonths`

---

## 11. Riesgos técnicos identificados

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **R-1 — Que OpenPay no ofrezca los meses por su cuenta.** Si el checkout no los muestra sin que el comercio los fuerce, el Diseño A no existe y la única alternativa elimina el pago de contado | Media | **Alto** | **T-01 lo resuelve antes de escribir una línea.** Si sale que no, se vuelve con negocio en vez de improvisar |
| **R-2 — Que OpenPay ofrezca también 9 y 12.** Se pedía limitar a 3 y 6; en el Diseño A las opciones las controla el comercio, no nuestro `appsettings` | Media | Medio | T-01 lo mide. Si aparecen, hay que limitarlos del lado de OpenPay |
| **R-3 — Encender el flag exige imagen nueva.** El `appsettings.json` va horneado (`Dockerfile: COPY publish/ App/`) y la task definition no monta volumen de configuración | **Alta** | Bajo | Previsto en T-11 |
| **R-4 — Restringir el catálogo global rompería a otros proyectos.** `PaisMX.GetMsi()` está hardcodeado `{3,6,9,12}` y lo comparte todo México; hay productos con 12 MSI configurados | Baja | **Alto** | El diseño **no lo toca**. Está en criterios de aceptación |
| **R-5 — La comisión no tiene número.** Se sabe **quién** la paga (GarantiPlus, dicho por Aldo el 3-jun) pero no **cuánto** | Media | Medio | El flag nace apagado. Pedir el % antes de encender en PROD |
| **R-6 — Colisión de etiqueta de imagen.** Ya pasó dos veces esta semana: reusar una etiqueta sobreescribe la imagen en silencio | Media | **Alto** | T-07 obliga a confirmar contra el **ECR**, no contra `develop` |

---

## 12. Notas para el programador

**Sobre la comisión (contexto documentado, no especulación):**

1. En la reunión del **3-jun-2026** (`bmw_landing/docs/Dudas BMW_ Pasarela de pagos…Transcript.md`,
   líneas 1261-1321) Aldo dice textualmente: *"inclusive les queremos dar meses sin intereses, **nos
   cobran una barbaridad los Open Pay**… y es **financiado por nosotros**"*. Israel responde *"yo les
   diría que lo quiten"* y Aldo cierra con *"quítale meses sin intereses"*. Es decir: **la comisión la
   absorbe GarantiPlus**, y los MSI se quitaron **por costo**, no por un problema técnico. Reactivarlos
   es aceptar ese costo de nuevo. Lo que falta no es la decisión —ya está tomada— sino **el número**:
   pedir a OpenPay el % de 3 y 6 MSI para saber cuánto margen cede cada contrato.

**Hallazgos del análisis que no venían en la solicitud:**

- **H-1 — El contrato dice 0 MSI aunque se pague a meses.** `ContractCreationService.cs:263` escribe
  `pago_msi = request.Payment?.InterestFreeMonths ?? 0`, y el factory de BMW
  (`BmwLandingContractRequestFactory.cs:343`) lo hardcodea a `0`. Hoy no se nota porque nunca hay MSI.
  En el Diseño A el dato solo se conoce **después** de que el cliente elige, así que hay que sacarlo
  del cargo o del webhook (T-05).
- **H-2 — El `[Range(3,24)]` del DTO no corresponde con la realidad.** `PaymenGatewayOpenPay.cs:185`
  solo arma `DeferralPayments` si el MSI es `> 0 && <= 12`. Un `msi: 18` pasa la validación del DTO,
  llega a SIGA y se **descarta en silencio**: el cliente pagaría de contado creyendo que va a meses.
  Lo cierra T-06.
- **H-3 — `maxMsi` ya viaja a la landing y se tira.** `sigaService.ts:515` lo parsea y ningún
  componente lo usa. Con la decisión de mantener la landing transparente, **ese campo sobra**: se
  puede dejar (es inofensivo) o limpiar en un barrido posterior. No es parte de este plan.
- **H-4 — No hay tabla `meses_sin_intereses`.** La entidad existe en `DataAccess/Models/`, pero su
  `DbSet` y su mapeo están **comentados** (`garantiplus_dbContext.cs:114` y `:1935`). Los valores
  salen del diccionario hardcodeado de `PaisMX.GetMsi()`. No buscar la tabla: no existe.

**Otras notas:**

2. **Por qué el flag nace en `false`.** Permite desplegar código y datos sin cambiar nada para el
   usuario, y separar "está desplegado" de "está encendido". El encendido queda como decisión de
   negocio con reversa inmediata.
3. **`max_msi` por la pantalla, no por script.** La pantalla de SIGA existe exactamente para esto. Si
   se hiciera por script, recordar que son **dos bases** (QA y PROD).
4. **Sin tests.** La validación real es manual en QA.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — La prueba que decide el diseño** | Dos links en QA (con y sin MSI) y lectura del checkout | T-01 | 0.5 día | |
| **Fase 1 — API: interruptor y validación (P1)** | `appsettings`, validación server-side, diseño A/B, `pago_msi`, `[Range]`, versión | T-02 a T-07 | 1 – 1.5 días *(Diseño A)* · 1.5 – 2 *(B)* | |
| **Fase 2 — Datos: configurar productos** | `max_msi = 6` en 66 productos, QA y PROD | T-08 a T-09 | 0.5 día | |
| **Fase 3 — Validación y encendido** | No regresión, end-to-end en QA con pago real, encendido en PROD | T-10 a T-12 | 1 – 1.5 días | |
| **Total proyecto** | | 12 tareas | **~3 – 4 días hábiles** | — |
| **Solo P1 (mínimo desplegable)** | Fase 0 + Fase 1 | T-01 a T-07 | **~1.5 – 2 días hábiles** | — |

> **Notas sobre la tabla:**
> - Bajó respecto a la v0.1 (~3.5–6.5 días) porque **la landing salió del alcance**: se fue una fase
>   entera de frontend y su build.
> - "Solo P1" es lo desplegable **sin cambiar nada para el usuario**, porque el flag nace apagado.
> - **Fase 0 no es opcional ni se puede paralelizar**: su resultado define qué se implementa en T-04 y
>   T-05. Empezar a codificar antes es apostar.
> - La Fase 3 incluye **pagos reales de prueba** en la pasarela.

> **Riesgo de deadline:** no hay fecha comprometida. Con los meses ya confirmados y negocio al tanto,
> el único frente abierto de verdad es **el resultado de T-01**: si OpenPay no ofrece los meses por su
> cuenta, no es un problema de esfuerzo sino de alcance, y hay que volver con negocio antes de seguir.
> Sumar un segundo desarrollador no comprimiría nada.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
