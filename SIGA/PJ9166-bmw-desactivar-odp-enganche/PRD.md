# PRD — Flags ODP/Pasarela por modalidad + renombre del acceso a SIGA (BMW)

> Plantilla para features y bugfixes sobre proyectos existentes.
> Al ser un cambio sobre algo que ya existe, el contexto del sistema no se redocumenta — solo se describe el cambio específico.

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | API de SIGA (Contracts) + Landing BMW |
| Tipo | Mejora (configurabilidad del flujo de pago por modalidad + ajuste de UI) |
| Área / empresa | GarantiPlus México |
| Versión | v0.2 |
| Fecha | 2026-07-09 |
| Autores | Carlos Castellanos |
| Revisión / liderazgo | Aldo Álvarez (Dir. TI) · Israel Escutia / Mario Luna (negocio BMW) |

---

## 1. Resumen del cambio

BMW confirmó que se fondea a los distribuidores igual que en Financiado: BMW descuenta directamente los conceptos y paga a los proveedores; el distribuidor ya tiene el dinero del enganche en su caja. La consecuencia es que **el Enganche ya no debe generar automáticamente la Orden de Pago (ODP)** al crear el contrato.

En lugar de eliminar el código, este cambio introduce una **matriz de flags booleanos por modalidad en `appsettings`** que decide si se genera la ODP (y, para Contado, la pasarela). El mecanismo de generación (`CreatePaymentOrderAsync`, facturación) **no cambia**: solo se envuelve en un `if (flag)`. Así, si en el futuro BMW quiere reactivar la ODP del Enganche, basta con poner el flag en `true` — sin tocar código ni desplegar cambios de lógica.

Estado inicial de los flags: Enganche `GenerateOdp = false` (cumple el objetivo actual), Financiado `GenerateOdp = false` (cableado y listo para futuro), Contado `GenerateOdp = true` y `EnableGateway = true` (como hoy). La etiqueta "Enganche" se conserva en la modalidad de pago para el desglose por canal.

Adicionalmente, este PRD agrupa un cambio menor de UI en la landing (no amerita PRD propio): **renombrar el acceso "Ir a SIGA"** por un nombre con significado — "Sistema de Gestión de Garantías" — a petición de negocio, para que el usuario final no vea una sigla interna.

---

## 2. Contexto del cambio

**Cómo funciona hoy** (rama post-creación en [`BmwController.cs`](../../gp_3.0_siga_api/Services/Contracts/Controllers/BmwController.cs), ~L1705-1807):

- **Contado** → factura al cliente + timbra al crear + genera ODP alterna; la pasarela se ofrece (habilitación por `medio_pago = "Pago beneficiario"`).
- **Enganche** → `ApplyDealerBillingAsync` (factura al **distribuidor**) **+ genera la ODP automática** vía `CreatePaymentOrderAsync`. Es la única modalidad con ODP automática. Sin pasarela.
- **Financiado / Financiamiento** → `ApplyFinancingBillingAsync` (factura al cliente/beneficiario), **sin ODP ni pasarela**.

La generación de la ODP es un mismo mecanismo genérico (`CreatePaymentOrderAsync`) reutilizado por Contado y Enganche; no depende de la modalidad.

**Qué dispara el cambio:** indicación de negocio (junta 2026-07-09). Se decidió no borrar el código sino hacerlo configurable, para reactivar la ODP (o, a futuro, la pasarela de Contado) solo cambiando un valor en `appsettings`.

**Decisiones de negocio confirmadas:**
- El Enganche **mantiene** la facturación al distribuidor; el único cambio de comportamiento es que deja de generar la ODP.
- La pasarela **solo aplica a Contado**. No se cablea pasarela para Enganche/Financiado: habilitarla ahí exigiría cambiar la facturación a beneficiario y ajustar el front, lo cual queda fuera de alcance.

---

## 3. Alcance del cambio

**Qué entra:**

| Elemento | Descripción |
|---|---|
| Options de flags por modalidad | Nueva clase de Options (bind desde `appsettings`, sin hardcode) con la matriz `{ modalidad → { GenerateOdp, EnableGateway } }`. |
| Gate de ODP por flag | La generación de la ODP en cada modalidad solo corre si su `GenerateOdp` está en `true`. Aplica a Contado (existente) y Enganche (existente). |
| ODP de Financiado cableada y gated | Agregar la llamada genérica `CreatePaymentOrderAsync` para Financiado, gobernada por su `GenerateOdp` (default `false`). Deja preparada la ODP sin activarla. |
| Gate de pasarela de Contado por flag | La habilitación de pasarela de Contado (`ApplyContadoBeneficiaryBillingAsync` + timbrado) se gobierna con `EnableGateway` (default `true`). |
| Valores por defecto en appsettings | Enganche `GenerateOdp=false`; Financiado `GenerateOdp=false`; Contado `GenerateOdp=true`, `EnableGateway=true`. Replicar en los appsettings por ambiente. |
| Renombre del acceso a SIGA (landing) | Cambiar el texto "Ir a SIGA" por "Sistema de Gestión de Garantías" en los dos puntos donde aparece el enlace (login y /documentos). El `href` (`getSigaWebUrl()`) no cambia. |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Pasarela para Enganche/Financiado | Habilitarla requiere facturar al beneficiario y cambios en el front; se decidió dejar la pasarela solo en Contado. |
| Cambiar la facturación del Enganche | Se mantiene facturación al distribuidor. |
| ODP/concentrado manual hacia BMW | Proceso interno posterior de Operaciones; no se toca. |
| Etiqueta "Enganche" en modalidad de pago | Se conserva para el desglose por canal. |
| Contratos ya creados con ODP | El cambio aplica a contratos nuevos; no se migran ni revocan ODP existentes. |
| Cambios en la landing | El front ya trata no-Contado como gestión interna (sin acciones de pago) y ofrece pasarela solo en Contado; solo se verifica, no se modifica. |

---

## 4. Requerimientos funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Flags por modalidad en appsettings | Existe una sección de configuración con un flag `GenerateOdp` por cada modalidad (Contado, Enganche, Financiado) y un flag `EnableGateway` para Contado. |
| RF-02 | ODP condicionada al flag | Al crear un contrato BMW, la ODP se genera únicamente si el `GenerateOdp` de esa modalidad está en `true`; el mecanismo de generación no cambia. |
| RF-03 | Enganche sin ODP por defecto | Con la configuración por defecto (`Enganche.GenerateOdp=false`), crear un contrato de Enganche NO genera ODP. La facturación al distribuidor se conserva. |
| RF-04 | Reactivación sin código | Poner `Enganche.GenerateOdp=true` (o `Financiado.GenerateOdp=true`) reactiva la ODP sin cambios de código ni de lógica, solo reinicio/redeploy de configuración. |
| RF-05 | Financiado preparado | La ODP de Financiado queda cableada con la misma llamada genérica, gobernada por su flag (default `false`, es decir, sin ODP como hoy). |
| RF-06 | Pasarela de Contado condicionada | La pasarela/habilitación de pago en línea de Contado se genera solo si `Contado.EnableGateway=true` (default `true`). |
| RF-07 | Conservar etiqueta y desglose | La modalidad "Enganche" se sigue mostrando para el desglose por canal. |
| RF-08 | Best-effort sin romper la creación | Si un paso de ODP/facturación falla o está desactivado por flag, el contrato ya creado no se ve afectado (se conserva el manejo best-effort actual). |
| RF-09 | Renombrar el acceso a SIGA | El enlace mostrado hoy como "Ir a SIGA" (en login y en /documentos) debe decir "Sistema de Gestión de Garantías". El destino del enlace no cambia. |

---

## 5. Requerimientos no funcionales *(solo los que apliquen a este cambio)*

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Configuración tipada (Options), sin hardcode | Los flags se leen vía una clase de Options bindeada desde `appsettings`, siguiendo CODING_GUIDELINES (nada de valores mágicos en el controlador). |
| RNF-02 | Valor por defecto seguro | Si falta una entrada de configuración para una modalidad, el comportamiento por defecto debe ser NO generar (fail-safe: no crear ODP/pasarela inesperada). |
| RNF-03 | Sin cambios de esquema | No requiere modificaciones de base de datos. |
| RNF-04 | Compatibilidad con contratos previos | No afecta contratos de Enganche ya creados con ODP. |
| RNF-05 | Paridad entre ambientes | La sección de flags debe existir en los appsettings de todos los ambientes (dev/QA/PROD) con los valores acordados. |

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| Nueva clase de Options (p. ej. `BmwPaymentFlowOptions`) | Nuevo | Modela la matriz de flags por modalidad; se registra y bindea desde `appsettings`. |
| `Services/Contracts/appsettings.json` (+ por ambiente) | Modificación | Agregar la sección de flags con los valores por defecto acordados. |
| `Services/Contracts/Controllers/BmwController.cs` (rama post-creación) | Modificación | Envolver la generación de ODP (Contado y Enganche) en `if (flag.GenerateOdp)`; agregar la ODP de Financiado gated; envolver la pasarela de Contado en `if (flag.EnableGateway)`. |
| `PaymentOrderService.CreatePaymentOrderAsync` | Solo lectura | Sin cambios; se sigue invocando cuando el flag correspondiente esté activo. |
| `BmwPaymentService` (`ApplyDealerBillingAsync` / `ApplyFinancingBillingAsync` / `ApplyContadoBeneficiaryBillingAsync`) | Solo lectura | Sin cambios; se siguen invocando según la modalidad. |
| Landing — `CreatedContractsView.tsx` | Solo lectura / verificación | Verificar que un Enganche sin ODP no muestre enlaces de descarga de ODP ni errores; la pasarela ya está limitada a Contado. |
| Landing — `LandingView.tsx` (~L205) | Modificación | Cambiar el texto "Ir a SIGA" del enlace por "Sistema de Gestión de Garantías". |
| Landing — `DocumentsView.tsx` (~L96) | Modificación | Cambiar el texto "Ir a SIGA" del enlace por "Sistema de Gestión de Garantías". |
| Base de datos | Sin cambios | No se altera esquema ni datos. |

---

## 7. Decisiones cerradas (antes preguntas abiertas)

| Tema | Resolución |
|---|---|
| Nombre y forma de la sección de config | **Nueva sección `BmwPaymentFlow`** con sub-objeto por modalidad (`Contado`/`Enganche`/`Financiado` → `{GenerateOdp, EnableGateway}`), separada de `BmwPaymentOrderOptions`. |
| Contratos Enganche en QA con ODP | **Opción (a): dejarlos.** El cambio aplica solo a contratos nuevos; los Enganche de prueba ya creados en QA conservan su ODP (ruido de prueba conocido, sin limpieza). |
| Identificación para ODP manual | **Sin acción por ahora.** Los datos para identificarlos ya existen (`modalidad_pago`, `fecha_pago`, estatus, fecha de creación del contrato). Hoy no hay un proceso self-service (se pide a TI). A futuro se podría generar un **reporte en SIGA** con esta información; fuera de alcance de este cambio. |
| Texto del acceso a SIGA | **"Sistema de Gestión de Garantías"** (sin "Ir a"). Confirmado por el responsable. |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v0.3*
