# Plan de Desarrollo — RedirectUrl de la pasarela resuelto por proyecto

> Generado por Claude Code. Este documento es el punto de partida para la ejecución.
> El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | *(ninguno)* — ver §12.1 |
| Repositorio | `gp_4.0_siga` (código) + `gp_3.0_siga_api` (configuración) |
| Rama | `feature/redirect-pasarela-por-proyecto` |
| Rama base | `develop` (verificada y actualizada: `ee40ebd`) |
| Tipo | Bugfix de comportamiento / Feature de configuración |
| Responsable | Juan Carlos Castellanos Solis |
| Folio PRD | `PJ5642` — ⚠️ **PROVISIONAL E INVENTADO**, ver §12.1 |
| Fecha de generación | 2026-09-04 |
| Estado | Borrador |
| ID plan (BD) | **69** |

---

## 1. Resumen técnico

Cuando un cliente termina de pagar en OpenPay, la pasarela lo devuelve a una URL que hoy es **un solo
valor por proceso**. En el servicio `Contracts` ese valor apunta a la landing de BMW, así que **todo
contrato que genere link por la API —sea del proyecto que sea— aterriza en una página con marca BMW**.
Lo reportó Alexis (Omega) el 4-sep-2026 tras pagar un contrato suyo en QA.

El cambio hace que la URL de retorno se resuelva **por proyecto**: se conserva `Openpay:RedirectUrl`
como valor por defecto y se agrega un diccionario opcional `Openpay:RedirectUrlByProject` que
sobreescribe por `id_proyecto`. BMW conserva su landing por configuración; el resto de los proyectos
cae en la página genérica que ya usa SIGA web.

**Componentes que se modifican:**

- `gp_4.0_siga/PaisesService` — `PaymenGatewayOpenPay` y `WarrantyPaymentInfo` (código).
- `gp_3.0_siga_api/Infrastructure/mexico/{qa,prod}/Contracts-task-definition.json` (configuración).
- `gp_4.0_siga/GarantiplusWeb` — **solo se recompila**, no cambia su configuración.

**Stack:** .NET Core 8, C#, PostgreSQL. Sin cambios de arquitectura: se respeta la existente.

---

## 2. Prerequisitos

- [ ] **Confirmar la URL de PROD del sitio `Pagos`.** Se conoce la de QA
      (`https://qa-pagos.garantiplus.mx/AprobadoOpenpay/`); la de producción hay que leerla del
      `appsettings.json` de GarantiplusWeb en el servidor de PROD. **Sin este dato no se ejecuta la Fase 2.**
- [ ] Confirmar quién despliega `GarantiplusWeb` (EC2) y coordinar la ventana, porque es el sistema
      principal de operación.
- [ ] Acceso a los repos `gp_4.0_siga` y `gp_3.0_siga_api`.
- [ ] Decidir si esto viaja con T-018 o en su propio ciclo (ver §12.3).
- [ ] `CLAUDE.md` de `gp_4.0_siga`: **NO EXISTE** y se decidió no generarlo con `/init` en esta corrida.
      Queda como tarea aparte, jerárquica (raíz + uno por proyecto), empezando por `PaisesService`.

---

## 3. Arquitectura del cambio

No se introduce arquitectura nueva. Se respeta la existente (`rules/arquitectura.md`: no se refactoriza
código existente salvo petición explícita).

⚠️ **`PaisesService` es una librería COMPARTIDA.** La consumen `Ventas.Domain`, `GarantiplusWeb`,
`ClientsService` y `AveriasBusinessRules`. Para el link de pago hay **dos** consumidores vivos que
entran por el mismo método `IVentasBusinessRules.GetPaymentGatewayLink`:

```
SIGA web (EC2)          GarantiplusWeb/Areas/Contratos/ContratosController.cs:560 y :2460
                                    ↘
                                     Ventas.Domain → PaisesService.PaymenGatewayOpenPay
                                    ↗                        ↓
API de SIGA (ECS)       Contracts/Services/PaymentLinkService.cs      OpenpayGP (legacy)
                                                                              ↓
                                                                          OpenPay
```

Cada proceso aporta su propia configuración, y por eso hoy la misma clase produce dos redirects
distintos:

| Proceso | `Openpay:RedirectUrl` hoy |
|---|---|
| SIGA web QA | `https://qa-pagos.garantiplus.mx/AprobadoOpenpay/` |
| Contracts QA | `https://qa-bmw.garantiplus.com/pago-exitoso` |
| Contracts PROD | `https://bmw.garantiplus.com/pago-exitoso` |

**Consecuencia de despliegue:** al cambiar la librería hay que reconstruir y desplegar **los dos**
consumidores, no solo la API.

---

## 4. Tareas de desarrollo

### Fase 0 — Red de seguridad

- [ ] **T-01** — Documentar el comportamiento actual como baseline, con evidencia.
  - Archivos: `enginecx_prd/SIGA/redirect-pasarela-por-proyecto/BASELINE.md`
  - Debe registrar, para tarjeta y para SPEI: qué `RedirectUrl` sale hoy desde SIGA web y desde la API,
    y el formato exacto de la query string.
  - Criterio: el baseline permite comparar antes/después sin volver a leer código.

- [ ] **T-02** — Confirmar la URL de PROD del sitio `Pagos` leyendo el `appsettings.json` de
      GarantiplusWeb en el servidor de producción.
  - Criterio: valor confirmado y anotado en §7. **Bloquea la Fase 2.**

- [ ] **T-03** — Verificar que ningún otro consumidor de `PaisesService` construya links de pago.
  - Criterio: `grep` de `GetPaymentGatewayLink` en los 4 proyectos que referencian la librería, con
    el resultado anotado. Si aparece un tercer consumidor, **detenerse y avisar**.

### Fase 1 — Resolución por proyecto (P1)

- [ ] **T-04** — Agregar `ProjectId` a `WarrantyPaymentInfo`.
  - Archivos: `PaisesService/Pasarela/DTO/WarrantyPaymentInfo.cs`
  - Criterio: propiedad de solo lectura, poblada por constructor, siguiendo el estilo actual.

- [ ] **T-05** — Traer `d.id_proyecto` en `GetWarrantyPaymentInfo`.
  - Archivos: `PaisesService/Pasarela/Classes/PaymenGatewayOpenPay.cs`
  - La consulta **ya hace `INNER JOIN distribuidor d`**: es una columna más en el `SELECT`, sin join nuevo.
  - Criterio: el valor llega hasta `GenerateChargeModel` y se lee con `GetInt32`.

- [ ] **T-06** — Leer el diccionario de configuración `Openpay:RedirectUrlByProject`.
  - Archivos: `PaisesService/Pasarela/Classes/PaymenGatewayOpenPay.cs`
  - `Openpay:RedirectUrl` se conserva **tal cual** como valor por defecto: si no hay entrada para el
    proyecto, el comportamiento es idéntico al de hoy.
  - Criterio: con la configuración vacía, el redirect generado es byte a byte el del baseline (T-01).

- [ ] **T-07** — Resolver la URL en `GenerateChargeModel` y dejar traza en log.
  - Archivos: `PaisesService/Pasarela/Classes/PaymenGatewayOpenPay.cs` (línea ~192)
  - **El formato de la query string NO cambia:** `?id={id_poliza}&id_pasarela={uuid}`. Lo consumen
    `Pagos/Controllers/HomeController.AprobadoOpenpay(long id, string id_pasarela)` y la landing de BMW.
  - El log va por `Log` **y** por `Console`, igual que la traza de MSI: en ECS el driver `awslogs` solo
    captura stdout.
  - Criterio: el log dice proyecto, si hubo override y la URL final.

### Fase 2 — Configuración (P1)

- [ ] **T-08** — Actualizar la task-definition de **QA** de Contracts.
  - Archivos: `gp_3.0_siga_api/Infrastructure/mexico/qa/Contracts-task-definition.json`
  - `Openpay__RedirectUrl` pasa a la página genérica de `Pagos`; se agrega
    `Openpay__RedirectUrlByProject__206` con la landing de BMW.
  - Criterio: BMW conserva su destino y todo lo demás cae en `AprobadoOpenpay`.

- [ ] **T-09** — Misma operación en **PROD**.
  - Archivos: `gp_3.0_siga_api/Infrastructure/mexico/prod/Contracts-task-definition.json`
  - ⚠️ Usa el valor confirmado en T-02, **nunca uno deducido de la URL de QA**.
  - Criterio: revisado línea por línea antes de aplicar.

- [ ] **T-10** — Confirmar que `GarantiplusWeb` **no** necesita cambios de configuración.
  - Criterio: su `Openpay:RedirectUrl` ya apunta a `AprobadoOpenpay` y no lleva overrides, así que su
    comportamiento no cambia. Dejarlo escrito.

### Fase 3 — Validación y despliegue (P1)

- [ ] **T-11** — Probar en local con las tres combinaciones: sin diccionario, con override para 206 y
      con override para un proyecto que no existe.
  - Criterio: la URL resultante es la esperada en los tres casos.

- [ ] **T-12** — Desplegar a QA: `PaisesService` **y sus dos consumidores** (GarantiplusWeb y Contracts).
  - ⚠️ `PaisesService` no se compila en los deploys normales — se despliega aparte, igual que
    `PasarelaPagos/OpenpayGP`.
  - Criterio: los dos procesos corriendo con la librería nueva.

- [ ] **T-13** — Validar en QA end-to-end.
  - Contrato de **Omega** por el endpoint genérico → debe caer en `AprobadoOpenpay`.
  - Contrato de **BMW** por su endpoint → debe seguir cayendo en `/pago-exitoso`.
  - Alta desde **SIGA web** → debe seguir cayendo en `AprobadoOpenpay`.
  - Criterio: los tres verificados leyendo el `redirect_url` real del cargo, no solo el 200.

- [ ] **T-14** — Desplegar a PROD y repetir la verificación de BMW.
  - Criterio: un contrato real de BMW conserva su retorno. Es el único camino que hoy funciona bien y
    el que no se puede romper.

---

## 5. Cambios en base de datos

Ninguno. Solo se lee una columna que ya existe (`distribuidor.id_proyecto`).

---

## 6. Endpoints nuevos o modificados

Ninguno. El contrato de `POST /contracts/api/Contracts/v1/CreatePaymentLink/{contractId}` no cambia:
mismo request, misma respuesta, mismos códigos. Lo único que cambia es a dónde devuelve OpenPay al
cliente **después** de pagar.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `Openpay__RedirectUrl` | URL de retorno **por defecto**. Pasa a la página genérica de `Pagos`. | QA / PROD |
| `Openpay__RedirectUrlByProject__206` | Override para BMW: conserva su landing. | QA / PROD |

Valores objetivo:

| Ambiente | Por defecto | Override 206 |
|---|---|---|
| QA | `https://qa-pagos.garantiplus.mx/AprobadoOpenpay/` | `https://qa-bmw.garantiplus.com/pago-exitoso` |
| PROD | *(pendiente T-02)* | `https://bmw.garantiplus.com/pago-exitoso` |

El doble guion bajo es el separador de anidamiento del proveedor de configuración de .NET, así que el
diccionario se alimenta por variable de entorno sin tocar código.

---

## 8. Consideraciones de seguridad

- **Se descartó a propósito** que la URL de retorno viaje en el request del endpoint: sería un
  *open redirect* en un endpoint de cobro, y obligaría a mantener una lista blanca. La resolución
  vive del lado del servidor y solo se alimenta por configuración de despliegue.
- No hay secretos involucrados: son URLs públicas de retorno.
- No cambian permisos, policies ni roles.

---

## 9. Consideraciones de infraestructura

- Sin servicios AWS nuevos ni costo adicional.
- Se redespliega el servicio `Contracts` (ECS + Fargate, subiendo versión de imagen) y `GarantiplusWeb`
  (EC2), por compartir la librería.
- Sin cambios en Cloudflare ni Route 53: los dos dominios de destino ya existen y ya reciben tráfico.

---

## 10. Criterios de aceptación

- [ ] Un contrato que **no** es de BMW, con link generado por la API, devuelve al cliente a
      `AprobadoOpenpay` del sitio `Pagos`.
- [ ] Un contrato de **BMW** sigue devolviendo a su landing, en QA y en PROD.
- [ ] Un alta desde **SIGA web** conserva su retorno actual, sin cambios de configuración.
- [ ] Con el diccionario vacío, el redirect es **idéntico** al baseline de T-01.
- [ ] El formato `?id={id_poliza}&id_pasarela={uuid}` se conserva sin cambios.
- [ ] El log deja ver, por contrato, qué proyecto se resolvió y qué URL se usó.

---

## 11. Riesgos técnicos identificados

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| **R-1** — La librería es compartida: tocarla afecta a SIGA web, el sistema principal de operación | Alta | **Alto** | El default preserva el comportamiento; SIGA web no lleva overrides. T-11 exige verificar el caso "sin diccionario" contra el baseline |
| **R-2** — Desplegar solo uno de los dos consumidores deja versiones distintas de la misma librería | Media | Medio | T-12 los trata como una sola unidad de despliegue |
| **R-3** — Poner en PROD una URL deducida en vez de la real | Media | Alto | T-02 la bloquea: sin el dato confirmado no se ejecuta la Fase 2 |
| **R-4** — Que exista un tercer consumidor de `GetPaymentGatewayLink` no detectado | Baja | Medio | T-03 lo verifica antes de tocar código |
| **R-5** — Que alguien "arregle de paso" el camino de SPEI | Baja | Medio | Hoy SPEI **no** fija `RedirectUrl`; queda **fuera de alcance** a propósito (§12.2) |

---

## 12. Notas para el programador

**12.1 — El folio `PJ5642` es PROVISIONAL E INVENTADO.** No hay PRD: se eligió un folio libre solo
porque el registro en BD lo exige como llave. Si se levanta el PRD formal, reemplazarlo aquí, en el
`PLAN.md` y en `pm_plan_desarrollo`.

**12.2 — SPEI queda fuera de alcance.** Hoy `RedirectUrl` solo se fija en el `case CreditDebitCard`;
en el camino de banco/SPEI no se fija nunca. No se toca: cambiarlo sería introducir un comportamiento
que hoy no existe, y nadie lo ha pedido.

**12.3 — Relación con T-018 y T-029.** T-018 (link de pago genérico) está pendiente de subir a PROD
esperando la confirmación de Alexis. Este cambio **no depende** de él y toca repos distintos, así que
puede ir en su propio ciclo. T-029 (cambio de credenciales de OpenPay a BBVA) está cerrada pero
congelada: si se retoma, conviene agrupar los despliegues, porque tocan las mismas piezas.

**12.4 — El redirect es cosmético, y eso baja el riesgo.** Quien activa el contrato es el webhook, no
el retorno: el cuerpo de `AprobadoOpenpay` está **todo comentado** y solo hace `return View()`. Si el
redirect falla, no se pierde ningún cobro. Lo que se corrige es que un cliente de otro proyecto
termine en una página con marca ajena.

**12.5 — Pregunta abierta que puede ampliar el alcance.** ¿Omega quiere que su cliente caiga en una
página de GarantiPlus, o en una suya? Si es lo segundo, el diseño cambia: el redirect tendría que
viajar en el request con lista blanca, y este plan no aplica. **Confirmar con Alexis antes de ejecutar.**

**12.6 — Producción tiene el mismo defecto desde siempre.** No lo introdujo el endpoint genérico:
viene de que el link de pago nació dentro de BMW. Hoy solo se nota porque Omega ya lo consume.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Red de seguridad** | Baseline, URL de PROD, inventario de consumidores | T-01 a T-03 | 0.5 – 1 día | 254 |
| **Fase 1 — Resolución por proyecto (P1)** | `ProjectId` en el DTO, columna en la consulta, diccionario y resolución | T-04 a T-07 | 1 – 2 días | 255 |
| **Fase 2 — Configuración (P1)** | Task-definitions de QA y PROD | T-08 a T-10 | 0.5 – 1 día | 256 |
| **Fase 3 — Validación y despliegue (P1)** | Pruebas locales, QA, PROD | T-11 a T-14 | 1 – 2 días | 257 |
| **Total proyecto** | | 14 tareas | ~3 – 6 días hábiles (≈ 1 semana) | — |
| **Solo P1** | Fase 0 + Fase 1 | T-01 a T-07 | ~1.5 – 3 días hábiles | — |

> **Riesgo de deadline:** no hay PRD y por lo tanto no hay fecha límite comprometida. El alcance cabe
> holgadamente en una semana con un solo desarrollador; no se requiere recurso adicional. El camino
> crítico no es el código —son unas 30 líneas— sino **coordinar el despliegue de GarantiplusWeb en
> EC2**, que es el sistema principal de operación y no se toca sin ventana acordada.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
