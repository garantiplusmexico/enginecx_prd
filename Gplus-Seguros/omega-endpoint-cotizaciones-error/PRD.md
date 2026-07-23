# PRD — Endpoint de consulta de cotizaciones con error

| Campo | Detalle |
|---|---|
| Proyecto / Sistema | Omega — Cotizaciones |
| Tipo | Feature |
| Área / empresa | GPLUS Seguros |
| Versión | v0.1 |
| Fecha | 2026-07-22 |
| Autores | Alexis Herrera |
| Revisión / liderazgo | Aldo Álvarez — Director de TI *(confirmar)* |

---

## 1. Resumen del cambio

Se agrega a Omega un **endpoint de consulta** que expone las cotizaciones que quedaron registradas con error. Actualmente, cuando una cotización falla (por ejemplo, por validaciones de excepción por aseguradora que la registran con error y la excluyen del envío a NATS), el error se guarda en la base de datos, pero **no existe una forma directa de consultarlo**.

El endpoint devolverá las **últimas 10 cotizaciones con error**, mostrando el folio de cotización, la aseguradora y el error asociado. El resultado esperado es que el solicitante pueda **identificar rápidamente las cotizaciones que fallaron** sin necesidad de consultar la base de datos manualmente.

---

## 2. Contexto del cambio

- **Hoy:** Las cotizaciones que fallan quedan registradas con su error en la base de datos, pero para revisarlas hay que consultar la BD directamente. No hay un canal expuesto para verlas.
- **Necesidad que lo dispara:** Alexis Herrera necesita poder identificar de forma ágil las cotizaciones que terminaron en error, para dar seguimiento a fallos del cotizador.
- **Naturaleza del cambio:** Es una feature de **solo lectura** sobre datos de error ya existentes; no altera el flujo de cotización.

---

## 3. Alcance del cambio

**Qué entra:**

| Elemento | Descripción |
|---|---|
| Endpoint de consulta | Nuevo endpoint que devuelve las últimas 10 cotizaciones con error |
| Datos expuestos | Folio de cotización, aseguradora y error de cada cotización |
| Origen de datos | Lectura de las cotizaciones con error ya registradas en la base de datos |

**Qué NO entra:**

| Exclusión | Justificación |
|---|---|
| Modificación del flujo de cotización | La feature es solo lectura; no cambia cómo se generan ni se registran las cotizaciones o sus errores |
| Filtros o parámetros de consulta | El alcance definido es fijo: siempre las 10 más recientes, sin parámetros |
| Reintento o corrección de cotizaciones con error | Solo se consultan; no se re-procesan |

---

## 4. Requerimientos funcionales

| ID | Requerimiento | Descripción |
|---|---|---|
| RF-01 | Exponer endpoint de consulta | El sistema debe ofrecer un endpoint que retorne las cotizaciones con error |
| RF-02 | Límite fijo de 10 registros | El endpoint devuelve únicamente las 10 cotizaciones con error más recientes |
| RF-03 | Campos de salida | Cada registro debe incluir: folio de cotización, aseguradora y error |
| RF-04 | Orden por recencia | Los resultados se ordenan de la cotización con error más reciente a la más antigua |

---

## 5. Requerimientos no funcionales *(solo los que apliquen a este cambio)*

| ID | Requerimiento | Descripción |
|---|---|---|
| RNF-01 | Solo lectura | El endpoint no debe escribir ni modificar datos; únicamente consulta |
| RNF-02 | Autenticación / permisos | El acceso al endpoint debe estar protegido según el estándar de Omega *(definición técnica pendiente)* |

---

## 6. Componentes e integraciones afectadas

| Componente / Integración | Tipo de cambio | Descripción |
|---|---|---|
| API de Omega (Cotizaciones) | Nuevo | Nueva ruta/endpoint de consulta *(servicio exacto por confirmar con equipo técnico)* |
| Base de datos de cotizaciones | Solo lectura | Consulta de las cotizaciones con error ya registradas *(tabla/campos por confirmar con equipo técnico)* |

---

## 7. Preguntas abiertas

| Tema | Pregunta abierta |
|---|---|
| Servicio/componente | ¿En qué servicio/componente de Omega debe vivir el endpoint? |
| Persistencia | ¿En qué tabla y campos de la BD se registran las cotizaciones con error? |
| Autenticación | ¿Qué esquema de autenticación/permisos aplica para consumir el endpoint? |
| Definición de "error" | ¿Se consideran todas las cotizaciones con error o solo las excluidas del envío a NATS por excepción de aseguradora? |

---

*Engine CX — Departamento de Desarrollo*
*Versión: v0.1*
