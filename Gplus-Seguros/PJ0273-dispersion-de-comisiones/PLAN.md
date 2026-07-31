# Plan de Desarrollo — Dispersión y cobro de comisiones GPLUS

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/Gplus-Seguros/PJ0273-dispersion-de-comisiones/PRD.md` (v0.1, 2026-07-28) |
| Repositorio | `gp_seguros` (backend) + `frontend-omega` (frontend) |
| Rama | `feature/PJ0273-dispersion-de-comisiones` (misma en ambos repos) |
| Tipo | Feature (extensión de un subsistema existente) |
| Responsable | Alexis Salvador Herrera Garcia |
| Folio PRD | PJ0273 |
| Fecha de generación | 2026-07-29 |
| Estado | Borrador |
| Rama base | `develop` (verificada y actualizada en ambos repos) |
| ID plan (BD) | *(lo escribe el flujo al registrar el plan)* |

---

## ⚠️ Hallazgo que redefine el plan

**El PRD asume que este módulo se construye desde cero. No es así: Omega ya implementa aproximadamente la mitad del MVP.** La auditoría del código encontró un subsistema de comisiones en producción:

| Pieza existente | Ubicación | Cubre |
|---|---|---|
| Motor de cálculo del corte mensual | `Services/polizas/emisiones/Controllers/Pago_ComisionController.cs` → `GenerarCortePagoComision(mes, anio)` | Buena parte de RF-04 |
| Consulta del corte | Mismo controlador → `ObtenerCortePagoComision` sobre la vista `vr_recibo_dispersion_pago` | Base de RF-05/RF-06 |
| Persistencia del cálculo | Tablas `dispersion_pago` y `dispersion_pago_detalle` (monto por concepto de comisión) | Base de RF-04/RF-05 |
| Configuración jerárquica de porcentajes | `configuracion_comision` a nivel grupo / empresa / sucursal, con herencia (`includeParentLevels`), + catálogo `concepto_comision` + `meta_venta` | **RF-03 esencialmente completo** |
| Soporte de pólizas externas | `poliza_externa` / `recibo_poliza_externa`, ya incluidas en el corte | Habilita el 80% de cartera fuera de Omega |
| Reparto multi-concepto | `dispersion_pago_detalle.id_concepto_comision` permite varios beneficiarios por recibo | Reparto a distribuidor **y a Garanti Plus** |
| Mecanismo de correo automático | Publicación a NATS → servicio `emailing` (patrón en `Orden_PagoController.EnviarCorreoPasarelaPago`) | Infraestructura de RF-07 |
| UI de dispersión y configuración | `frontend-omega/src/views/ventas/dispersionPagos/DispersionPagos.vue`, `src/views/configuracion/configuracionesComisiones/ConfiguracionesComisiones.vue`, `src/views/ventas/ordenesPago/` | Base de la UI |

**Consecuencias directas:**

1. **Queda respondida la pregunta abierta §14 del PRD** (*"¿El módulo vivirá dentro de Omega o como sistema aparte?"*): **dentro de Omega**, extendiendo el servicio `emisiones`. Construirlo aparte duplicaría el motor de cálculo, la configuración de porcentajes y el catálogo de conceptos que ya existen y ya están en producción.
2. **También queda respondida la pregunta abierta sobre el mecanismo de correo**: no hace falta definir SMTP ni contratar un servicio transaccional. Omega ya publica a NATS y el servicio `emailing` entrega.
3. **El esfuerzo real es sustancialmente menor** al que sugiere el PRD: ~36-54 días hábiles en lugar de un desarrollo completo desde cero.
4. **Cambia la naturaleza de RF-01.** El PRD pide "cargar un archivo con las pólizas del periodo" hacia un sistema nuevo. Dado que el motor de corte ya consume `poliza_externa`, la vía correcta es **importar la producción externa como pólizas externas de Omega** en lugar de mantener un almacén paralelo de bases. Eso resuelve RF-01/RF-02, hace funcionar RF-04 sin trabajo adicional, y **adelanta parte de la Fase 2 del PRD** ("carga masiva de producción externa en Omega para autoconsulta de distribuidores"). Esta decisión debe confirmarse antes de arrancar — es la más estructural del plan.

---

## 1. Resumen técnico

Se **extiende el subsistema de comisiones existente de Omega**, sin crear servicios nuevos. Todo el trabajo de backend ocurre dentro de `Services/polizas/emisiones` (contenedor `gp_omega_policies`), y el de frontend dentro de las áreas `ventas` y `configuracion` ya existentes en `frontend-omega`.

Los cinco bloques de trabajo son:

1. **Auditoría y saneamiento del motor de corte existente** — validar su cálculo contra el Excel manual y corregir los defectos detectados (ver §11), antes de construir encima.
2. **Carga masiva de producción externa** (RF-01, RF-02) — importador de bases por negocio/distribuidor que valida campos mínimos y da de alta `poliza_externa` + `recibo_poliza_externa`, con reporte de errores por renglón.
3. **Cierre versionado y estado de cuenta** (RF-04, RF-05, RNF-06) — congelar el resultado del corte en un cierre inmutable por periodo, con desglose por distribuidor y cálculo explícito de la ganancia de GPLUS.
4. **Ciclo de facturación y comunicación** (RF-06, RF-07, RF-08) — vista para contabilidad, envío automático del estado de cuenta con fecha límite vía NATS → `emailing`, seguimiento del estatus de facturación y reprogramación por incumplimiento.
5. **Eventos de BI, operación en paralelo y despliegue** (PRD §11 y §6).

**Arquitectura:** se mantiene la de Omega — microservicios en ECS + Fargate (`rules/arquitectura.md` §1) — sin añadir contenedores. **Stack:** .NET Core 8 / C# y Vue 2 + Vuetify, respetando el stack existente (`rules/stack.md`); PostgreSQL.

**Fuera de alcance** (PRD §6): bot de Omar, autoconsulta de distribuidores, alertas de pagos subsecuentes, cobro a aseguradoras (Fase 3), pago semanal a Autocom, y el retiro del Excel actual — que solo se apaga tras validar el paralelo sin discrepancias.

---

## 2. Prerequisitos

Bloqueantes:

- [ ] **Confirmar la decisión estructural de RF-01**: importar la producción externa como `poliza_externa` de Omega (recomendado) frente a mantener un almacén paralelo de bases. Todo el diseño de las Fases 1 y 2 depende de esta respuesta.
- [ ] **Muestras reales de las bases de Patricia, Juan Carlos y Deca** (los tres archivos Excel, tal como se cargan hoy). Cada negocio tiene su propio formato de columnas; sin las muestras no se puede definir el contrato de importación ni estimar T-05 con confianza.
- [ ] **El Excel de conciliación de un mes cerrado completo**, con su resultado final, para poder contrastar el motor de cálculo existente contra el cálculo manual (T-01). Es el insumo que determina si el motor actual es correcto o hay que ajustarlo.

Bloqueante de la Fase 3 únicamente:

- [ ] **Comunicado oficial de contabilidad con los tiempos de pago/provisión.** Es pregunta abierta del PRD §14 y riesgo declarado en §13. Sin esa regla, RF-08 (reprogramación) no puede implementarse en detalle. **No bloquea las Fases 0 a 2.**

Definiciones de negocio a cerrar antes de la Fase 2:

- [ ] **Confirmar si `configuracion_comision` ya modela el % que paga la aseguradora**, o solo el que GPLUS paga hacia abajo. El PRD define UDI como la *diferencia* entre ambos; si el % de la aseguradora no está modelado, hay que agregarlo (T-04).
- [ ] **Día y hora exactos del disparo del cierre mensual.** El PRD §14 menciona "las 9 de la noche" como ejemplo, no como regla.
- [ ] Correo de contabilidad que debe ir en copia en cada solicitud de factura.

Accesos e infraestructura:

- [ ] Base de datos PostgreSQL de desarrollo con datos representativos de al menos un periodo cerrado.
- [ ] `CLAUDE.md` presente en ambos repositorios — ✅ generado el 2026-07-29 como parte de este flujo.
- [ ] Repositorios en `develop` actualizado — ✅ verificado.

---

## 3. Arquitectura del cambio

No se crean servicios nuevos. El cambio vive dentro de dos contenedores existentes y reutiliza el broker que Omega ya opera.

```
                         ┌──────────────────────────────────────────┐
frontend-omega           │  gp_omega_policies (Services/polizas/    │
(Vue + Vuetify)          │                     emisiones)           │
  ├─ Carga de bases ────►│                                          │
  ├─ Cierre / edo. cta ─►│  ImportacionProduccionExterna (nuevo)    │
  ├─ Vista contabilidad ►│  Pago_ComisionController (existente,     │
  └─ Config. de % ──────►│    auditado y extendido)                 │
        │                │  CierreComisiones (nuevo, versionado)    │
        │                │  EstadoCuentaDistribuidor (nuevo)        │
    KrakenD              │  SeguimientoFacturacion (nuevo)          │
                         └───────┬──────────────────────┬───────────┘
                                 │                      │
                                 ▼                      │ NATS
                        PostgreSQL (Aurora RDS)         │ EmailPublisher:EmailingSubject
                        · poliza_externa      (exist.)  ▼
                        · dispersion_pago     (exist.)  gp_omega_emailing
                        · configuracion_comision(exist.)   (existente)
                        · cierre_comision     (nuevo)        │
                        · estado_cuenta_*     (nuevo)        ▼
                        · seguimiento_factura (nuevo)   Distribuidor + copia a contabilidad
```

**Decisiones de diseño y su porqué:**

| Decisión | Justificación |
|---|---|
| Extender `emisiones` en lugar de crear un microservicio nuevo | El motor de corte, la configuración de porcentajes y las pólizas viven ahí. Un servicio aparte tendría que leer las mismas tablas o duplicar el cálculo — y el PRD advierte explícitamente del riesgo de manejar dinero con dos cálculos distintos. |
| Importar la producción externa a `poliza_externa` en vez de un almacén de bases | El motor ya las consume; evita un segundo modelo de datos de pólizas y adelanta la autoconsulta de la Fase 2 del PRD. |
| Cierre inmutable versionado, separado de `dispersion_pago` | RNF-06 exige que el estado de cuenta refleje exactamente el periodo cerrado. Hoy `GenerarCorte` **sobrescribe** el cálculo en cada ejecución, así que volver a correrlo cambia lo que ya vio contabilidad. El cierre versionado congela el resultado y guarda qué porcentajes estaban vigentes (RNF-03). |
| Reutilizar NATS → `emailing` | Ya está en producción para las órdenes de pago; el contrato del mensaje es `{to, name_to, cc, subject, body}`. Evita definir un mecanismo nuevo (pregunta abierta del PRD §14). |
| Reparto a Garanti Plus como `concepto_comision` | El modelo `dispersion_pago_detalle` ya soporta varios conceptos por recibo; el reparto no necesita estructura nueva. |
| Auditar antes de construir (Fase 0) | Se maneja dinero real (riesgo declarado en el PRD §13). Construir estado de cuenta y correos automáticos sobre un motor no verificado propagaría un error de cálculo directo a los pagos. |

---

## 4. Tareas de desarrollo

### Fase 0 — Auditoría y saneamiento del motor existente

- [ ] **T-01** — Contrastar el motor de corte actual contra el cierre manual de un mes real
  - Archivos: documento de resultados en `Common/reportesSQL/comisiones/auditoria-corte.md`
  - Detalle: ejecutar `GenerarCortePagoComision` sobre un periodo ya cerrado a mano y comparar renglón por renglón contra el Excel de Patricia. Documentar toda discrepancia y su causa
  - Criterio de completitud: informe con el porcentaje de coincidencia y la lista clasificada de diferencias

- [ ] **T-02** — Corregir los defectos detectados en el cálculo del corte
  - Archivos: `Services/polizas/emisiones/Controllers/Pago_ComisionController.cs`
  - Detalle: (a) `monto_pendiente_pago` queda siempre en 0 al recalcular, porque `montoPagoOriginal` se calcula sobre la colección ya reconstruida en lugar de sobre el valor previamente persistido; (b) `error_configuracion` es una bandera global: tras el primer fallo, **todos** los recibos siguientes se agregan al reporte de error aunque estén correctos, y el cálculo se aborta en silencio para el resto del periodo; (c) en `AgregarInformacionAdicionalPoliza`, las pólizas cuya empresa no está en el mapa se omiten sin aviso y llegan al cálculo con `id_tipo_poliza` sin asignar. Ver §11
  - Criterio de completitud: un periodo con un solo recibo mal configurado reporta exactamente ese recibo y calcula correctamente el resto; `monto_pendiente_pago` refleja la diferencia real contra el cálculo anterior

- [ ] **T-03** — Cobertura de pruebas del motor de cálculo
  - Archivos: proyecto de pruebas nuevo `Services/polizas/emisiones/emisiones.Test/`
  - Detalle: casos con y sin meta de venta, pólizas de empleado (comisión cero), pólizas externas, herencia de configuración en los tres niveles, y recibo sin configuración. Es el único blindaje real antes de automatizar pagos
  - Criterio de completitud: `dotnet test` en verde con los escenarios anteriores cubiertos

- [ ] **T-04** — Cerrar el modelo de porcentajes: aseguradora, distribuidor y Garanti Plus
  - Archivos: `Services/clientes/Models/configuracion_comision*.cs`, `Services/clientes/Controllers/Configuracion_ComisionController.cs`, script de migración
  - Detalle: verificar si el % que paga la aseguradora está modelado. Si no, agregarlo para poder calcular la UDI como diferencia (definición del PRD §2) y la ganancia de GPLUS. Confirmar que el reparto a Garanti Plus está representado como `concepto_comision`
  - Criterio de completitud: para una póliza de prueba se obtienen los tres montos —lo que paga la aseguradora, lo que se paga al distribuidor y lo que retiene GPLUS— y suman correctamente

### Fase 1 — Carga masiva de producción externa (RF-01, RF-02)

- [ ] **T-05** — Definir el contrato de importación y la plantilla por negocio
  - Archivos: `Services/polizas/emisiones/DTOs/Comisiones/Requests/ImportPolicyBatchRequest.cs`, plantilla `.xlsx` de referencia
  - Detalle: campos mínimos del PRD §10 (número de póliza, aseguradora, cliente, vigencia, prima, recargos, derecho, IVA, prima total, clave especial/tradicional, negocio/distribuidor). Mapeo de columnas configurable por negocio, dado que cada uno entrega un formato distinto (riesgo declarado del PRD §13)
  - Criterio de completitud: contrato validado contra las tres bases reales de Patricia, Juan Carlos y Deca

- [ ] **T-06** — Importador con validación por renglón y reporte de errores
  - Archivos: `Services/polizas/emisiones/Controllers/ImportacionProduccionExternaController.cs`, `Services/PolicyBatchImportService.cs`
  - Detalle: leer el archivo con `Common/ExcelUtils`, validar los campos mínimos por renglón, y **rechazar el lote completo si hay errores**, devolviendo un Excel con el detalle por renglón (mismo patrón que `ObtenerArchivoErrorPagos` ya usa). Registrar quién cargó, cuándo y cuántos registros (RNF-03). Idempotencia por número de póliza + periodo para evitar duplicados en recargas
  - Criterio de completitud: una base válida da de alta las pólizas externas y sus recibos; una base con tres renglones inválidos devuelve el Excel de errores y no persiste nada

- [ ] **T-07** — Frontend: pantalla de carga de bases
  - Archivos: `frontend-omega/src/views/ventas/dispersionPagos/CargaBases.vue`, router y sidebar
  - Detalle: selección de negocio/distribuidor y periodo, carga del archivo, descarga de la plantilla, y visualización del resultado con el Excel de errores descargable. Seguir el patrón de `CargaMasiva.vue` que ya existe para vehículos
  - Criterio de completitud: Patricia puede cargar su base y ver el resultado sin intervención de TI

- [ ] **T-08** — Bitácora de cargas
  - Archivos: `Services/polizas/emisiones/Models/carga_base_produccion.cs`, controlador de consulta
  - Detalle: RNF-03 — historial consultable de qué se cargó, quién y cuándo, con posibilidad de revertir un lote antes de que se genere el cierre
  - Criterio de completitud: se puede revertir una carga errónea sin tocar la base de datos a mano

### Fase 2 — Cierre versionado y estado de cuenta (RF-04, RF-05, RNF-06)

- [ ] **T-09** — Entidad de cierre inmutable por periodo
  - Archivos: `Services/polizas/emisiones/Models/{cierre_comision,cierre_comision_detalle}.cs`, migración
  - Detalle: al publicar un cierre se congela el resultado del cálculo junto con **los porcentajes vigentes en ese momento** (RNF-03) y el usuario que lo publicó. Estados: `Borrador` → `Publicado` → `Cancelado`. Un cierre publicado no se recalcula: si hay que corregir, se cancela y se emite uno nuevo con trazabilidad de la corrección
  - Criterio de completitud: recalcular tras publicar no altera lo que ya vieron contabilidad ni el distribuidor (RNF-06)

- [ ] **T-10** — Cálculo de UDI y ganancia de GPLUS por póliza (RF-04)
  - Archivos: `Services/polizas/emisiones/Services/CommissionCalculationService.cs`
  - Detalle: extraer del controlador la lógica hoy embebida en `CalcularComisionRecibo` hacia un servicio inyectable con interfaz (`rules/coding-guidelines.md` §3), y añadir el cálculo explícito de la ganancia de GPLUS como diferencia entre lo que paga la aseguradora y lo repartido. **No se altera la fórmula existente sin evidencia de T-01**
  - Criterio de completitud: por póliza se obtienen UDI del distribuidor, reparto a Garanti Plus y ganancia de GPLUS, y las pruebas de T-03 siguen en verde

- [ ] **T-11** — Estado de cuenta por distribuidor (RF-05)
  - Archivos: `Services/polizas/emisiones/Controllers/EstadoCuentaController.cs`, `Services/StatementService.cs`
  - Detalle: agregación por distribuidor sobre el cierre publicado, con detalle de pólizas y monto total a pagar. Exportable a Excel y a PDF (`iText` ya está en el servicio) para adjuntarlo al correo de RF-07
  - Criterio de completitud: el estado de cuenta cuadra contra el total del cierre y contra el Excel manual del periodo en paralelo

- [ ] **T-12** — Frontend: pantalla de cierre y estado de cuenta
  - Archivos: `frontend-omega/src/views/ventas/dispersionPagos/DispersionPagos.vue` (extender), `CierreComisiones.vue`, `EstadoCuentaDistribuidor.vue`
  - Detalle: generar cierre en borrador, revisarlo por distribuidor, publicarlo con confirmación explícita (es la acción que dispara los correos), y consultar cierres anteriores. Usar `Components/TablaOmega` con paginación server-side
  - Criterio de completitud: el ciclo completo generar → revisar → publicar se ejecuta desde la UI

### Fase 3 — Contabilidad, facturación y comunicación (RF-06, RF-07, RF-08)

- [ ] **T-13** — Rol y vista de contabilidad (RF-06, RNF-02)
  - Archivos: `Services/polizas/emisiones/Controllers/`, catálogo de roles, `frontend-omega/src/views/ventas/dispersionPagos/CierreContabilidad.vue`
  - Detalle: los endpoints de comisiones hoy autorizan `Administrador General, Mesa de control, Cobranza`. Agregar rol `Contabilidad` con acceso **solo lectura** al cierre publicado y a los estados de cuenta. Mantener escritura restringida a Norma, Patricia y Carlos (RNF-02)
  - Criterio de completitud: un usuario de contabilidad ve el cierre sin que nadie se lo envíe, y recibe 403 al intentar modificarlo

- [ ] **T-14** — Modelo de seguimiento de facturación
  - Archivos: `Services/polizas/emisiones/Models/seguimiento_facturacion.cs`, migración
  - Detalle: por distribuidor y periodo — fecha límite de facturación, estatus (`Pendiente`, `Facturado en tiempo`, `Facturado tarde`, `Reprogramado`), fecha de recepción de la factura, y bitácora de correos enviados con su fecha/hora (RNF-03)
  - Criterio de completitud: el estado de facturación de cada distribuidor es consultable y auditable

- [ ] **T-15** — Envío automático del estado de cuenta y solicitud de factura (RF-07)
  - Archivos: `Services/polizas/emisiones/Services/CommissionMailService.cs`
  - Detalle: al publicar el cierre, publicar en NATS un mensaje por distribuidor con el contrato ya usado por `emisiones` (`{to, name_to, cc, subject, body}`), copiando a contabilidad, con el estado de cuenta adjunto o enlazado y la fecha límite. **Si falla el envío debe alertar, no fallar en silencio** (RNF-04): registrar el fallo y permitir reenvío manual desde la UI
  - Criterio de completitud: publicar un cierre con tres distribuidores genera tres correos con copia a contabilidad; un fallo de envío queda visible y es reintentable

- [ ] **T-16** — Registro de factura recibida y reprogramación (RF-08)
  - Archivos: `Services/polizas/emisiones/Controllers/SeguimientoFacturacionController.cs`, `Services/InvoiceReschedulingService.cs`
  - Detalle: marcar la factura como recibida (a tiempo o tarde) y, ante incumplimiento de la fecha límite, aplicar la regla de reprogramación **como configuración, no como código** — la regla de contabilidad aún no existe (PRD §14) y va a cambiar. Recordatorio automático antes del vencimiento
  - Criterio de completitud: con una regla de prueba configurada, un distribuidor que no factura a tiempo queda reprogramado automáticamente y contabilidad lo ve reflejado

- [ ] **T-17** — Frontend: tablero de seguimiento de facturación
  - Archivos: `frontend-omega/src/views/ventas/dispersionPagos/SeguimientoFacturacion.vue`
  - Detalle: por periodo, estado de cada distribuidor, acción de marcar factura recibida y reenvío manual de la solicitud
  - Criterio de completitud: Patricia deja de enviar correos a mano; el tablero refleja el estado real del periodo

### Fase 4 — Eventos de BI, operación en paralelo y despliegue

- [ ] **T-18** — Emisión de eventos para BI (PRD §11)
  - Archivos: `Services/polizas/emisiones/Services/CommissionEventPublisher.cs`
  - Detalle: `base_cargada` (usuario, distribuidor, número de registros), `cierre_generado` (periodo, distribuidores, monto total), `correo_solicitud_factura_enviado` (distribuidor, monto, fecha límite), `factura_recibida` (a tiempo o tarde), `pago_reprogramado` (nueva fecha, motivo)
  - Criterio de completitud: los cinco eventos se emiten con los campos que pide el PRD

- [ ] **T-19** — Reporte de conciliación automático contra manual
  - Archivos: `Services/polizas/emisiones/Controllers/CommissionReportsController.cs`
  - Detalle: el PRD §6 y §12 exigen correr en paralelo hasta lograr cero discrepancias antes de retirar el Excel. Este reporte compara el cierre del sistema contra la base manual cargada y lista las diferencias por póliza — es la herramienta que permite apagar el proceso manual con evidencia
  - Criterio de completitud: el reporte identifica correctamente diferencias introducidas a propósito en una prueba

- [ ] **T-20** — Endurecimiento de permisos y privacidad (RNF-02, RNF-05)
  - Archivos: `Program.cs`, controladores de comisiones
  - Detalle: verificar que ningún endpoint de comisiones quede sin `[Authorize]` con rol; que los montos no aparezcan en logs; y que un distribuidor —cuando en una fase futura tenga acceso— solo pueda ver su propio estado de cuenta
  - Criterio de completitud: revisión de seguridad pasada sobre todos los endpoints nuevos y modificados

- [ ] **T-21** — Despliegue a QA y periodo de paralelo
  - Archivos: `Services/polizas/emisiones/build.ps1` (subir versión), `Infrastructure/qa/docker-compose.yml`, `Services/apigateway/krakend.json`
  - Detalle: publicar la imagen de `emisiones` y desplegar. Recordar el flujo real de ramas: `feature/* → develop → pre-qa → qa` (la CI bloquea PRs a `qa` que no vengan de `pre-qa`). Acompañar al menos un cierre mensual completo en paralelo con el Excel
  - Criterio de completitud: un cierre real ejecutado en paralelo sin discrepancias, validado por Patricia y contabilidad

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `cierre_comision` | Nueva | Cierre inmutable por periodo: mes, año, estado (Borrador/Publicado/Cancelado), usuario y fecha de publicación, monto total, cierre que sustituye (si es corrección) |
| `cierre_comision_detalle` | Nueva | Renglón congelado por recibo: distribuidor, póliza, UDI, reparto a Garanti Plus, ganancia GPLUS, y los porcentajes vigentes al momento del cálculo (RNF-03) |
| `estado_cuenta_distribuidor` | Nueva | Agregación por distribuidor y periodo: total a pagar, número de pólizas, referencia al cierre |
| `seguimiento_facturacion` | Nueva | Fecha límite, estatus de facturación, fecha de recepción, número de reprogramaciones |
| `seguimiento_facturacion_correo` | Nueva | Bitácora de correos enviados: fecha/hora, destinatario, resultado del envío, reintentos |
| `carga_base_produccion` | Nueva | Bitácora de cargas: usuario, negocio/distribuidor, periodo, archivo, número de registros, estado |
| `regla_reprogramacion_pago` | Nueva (configuración) | Regla configurable de reprogramación por facturación tardía (RF-08) |
| `configuracion_comision` | **Modificación** | Agregar el % que paga la aseguradora, si T-04 confirma que hoy no está modelado |
| `dispersion_pago` | **Modificación** | Referencia al cierre que lo congeló; corrección de la semántica de `monto_pendiente_pago` |
| `poliza_externa` / `recibo_poliza_externa` | **Modificación menor** | Marca de origen de importación y referencia al lote de carga, para poder revertir |

**Índices requeridos:** `cierre_comision(anio, mes)` **único** para cierres publicados, `cierre_comision_detalle(id_cierre_comision, id_distribuidor)`, `seguimiento_facturacion(id_cierre_comision, id_distribuidor)` único, `carga_base_produccion(anio, mes, id_distribuidor)`.

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| PUT | `/api/v1/pago-comision/generar-corte/{mes}/{anio}` | Generación del corte | **Modificado** (saneado en T-02, genera cierre en borrador) |
| GET | `/api/v1/pago-comision/obtener-corte/{mes}/{anio}` | Consulta del corte | **Modificado** (lee del cierre versionado) |
| POST | `/api/v1/produccion-externa/importacion` | Carga masiva de base por negocio (RF-01) | Nuevo |
| GET | `/api/v1/produccion-externa/plantilla` | Descarga de la plantilla de carga | Nuevo |
| GET | `/api/v1/produccion-externa/cargas` | Bitácora de cargas del periodo | Nuevo |
| DELETE | `/api/v1/produccion-externa/cargas/{id}` | Reversión de un lote antes del cierre | Nuevo |
| POST | `/api/v1/cierres-comision` | Generar cierre en borrador para un periodo | Nuevo |
| GET | `/api/v1/cierres-comision` | Listado de cierres con OData | Nuevo |
| GET | `/api/v1/cierres-comision/cnt` | Conteo para paginación | Nuevo |
| GET | `/api/v1/cierres-comision/{id}` | Detalle del cierre | Nuevo |
| POST | `/api/v1/cierres-comision/{id}/publicacion` | Publicar el cierre y disparar los correos (RF-07) | Nuevo |
| POST | `/api/v1/cierres-comision/{id}/cancelacion` | Cancelar un cierre publicado con motivo | Nuevo |
| GET | `/api/v1/cierres-comision/{id}/estados-cuenta` | Estados de cuenta por distribuidor (RF-05) | Nuevo |
| GET | `/api/v1/estados-cuenta/{id}/exportacion` | Descarga en Excel o PDF | Nuevo |
| GET | `/api/v1/seguimiento-facturacion` | Tablero de facturación del periodo | Nuevo |
| PATCH | `/api/v1/seguimiento-facturacion/{id}` | Marcar factura recibida (RF-08) | Nuevo |
| POST | `/api/v1/seguimiento-facturacion/{id}/reenvio` | Reenvío manual de la solicitud (RNF-04) | Nuevo |
| GET | `/api/v1/cierres-comision/{id}/conciliacion` | Reporte de diferencias contra la base manual | Nuevo |

---

## 7. Variables de entorno y configuración

Casi todas ya existen en `emisiones`; solo se agregan las tres últimas.

| Variable | Descripción | Ambiente |
|---|---|---|
| `ConnectionStrings__GPSeguros_Connection` | PostgreSQL | Todos (existente) |
| `EmailPublisher__EmailingUrl` | `nats://gp_omega_nats:4222` | Todos (existente) |
| `EmailPublisher__EmailingStream` | Stream de correo | Todos (existente) |
| `EmailPublisher__EmailingSubject` | Subject de correo | Todos (existente) |
| `Comisiones__EmailsContabilidad` | Destinatarios en copia de la solicitud de factura | Todos (nueva) |
| `Comisiones__DiasLimiteFacturacion` | Días predeterminados para facturar tras el cierre | Todos (nueva) |
| `Comisiones__DiaCierreMensual` | Día del mes en que se dispara el cierre | Todos (nueva) |

---

## 8. Consideraciones de seguridad

- **Se maneja dinero real.** Es el riesgo central declarado en el PRD §13. Las mitigaciones de este plan son estructurales, no opcionales: pruebas del motor de cálculo (T-03), cierre inmutable versionado (T-09), reporte de conciliación (T-19) y periodo de paralelo obligatorio antes de retirar el Excel (T-21).
- **Autorización por rol** (RNF-02): escritura para Norma, Patricia y Carlos; lectura para contabilidad. Los endpoints existentes ya usan `[Authorize(Roles = "Administrador General,Mesa de control,Cobranza")]`; el rol `Contabilidad` se agrega en T-13. Ningún endpoint nuevo puede quedar sin rol.
- **Privacidad de montos** (RNF-05): no registrar montos de comisión ni datos de pólizas en logs (`rules/coding-guidelines.md` §9). La exposición de estados de cuenta a distribuidores es de fase futura y debe filtrar estrictamente por distribuidor.
- **Trazabilidad** (RNF-03): quién cargó cada base, qué porcentajes estaban vigentes al calcular, y cuándo se envió cada correo. Está cubierto por `carga_base_produccion`, el congelado de porcentajes en `cierre_comision_detalle` y `seguimiento_facturacion_correo`.
- **Archivos cargados**: validar tipo MIME y tamaño, y tratar el contenido como no confiable. Un Excel de un tercero es una entrada de usuario.
- **Sin secretos en código** (`rules/coding-guidelines.md` §11): los correos de contabilidad y la configuración de tiempos van en variables de entorno.
- **Correos automáticos hacia terceros**: un cierre publicado por error dispara correos a distribuidores externos con montos. Por eso la publicación es una acción explícita y separada de la generación, con confirmación en la UI (T-12).

---

## 9. Consideraciones de infraestructura

- **Sin servicios nuevos en AWS.** El trabajo ocurre dentro de `gp_omega_policies` y usa el `gp_omega_emailing` y el `gp_omega_nats` existentes. Es la principal ventaja de extender Omega en lugar de construir aparte.
- **ECR**: nueva versión de la imagen de `emisiones`; recordar subir `$version_nueva` en `build.ps1`.
- **RDS PostgreSQL**: sin instancia nueva. El crecimiento por cierres versionados es acotado (un cierre mensual por periodo con su detalle).
- **KrakenD**: solo configuración, sin infraestructura nueva.
- **Almacenamiento de archivos cargados y estados de cuenta generados**: usar el S3 ya configurado en el servicio (`Common/S3Access`); no requiere bucket nuevo, aunque conviene un prefijo dedicado.
- **Programación del cierre mensual**: si se automatiza el disparo, la opción de menor costo es un `BackgroundService` dentro de `emisiones`; evita añadir un contenedor solo para eso. Alternativa: regla de EventBridge invocando el endpoint. Decidir junto con el día/hora de cierre (prerequisito abierto).

---

## 10. Criterios de aceptación

- [ ] El cierre calculado por el sistema coincide con el cierre manual de Patricia en un periodo real, sin discrepancias (PRD §12, meta explícita de cero).
- [ ] Patricia, Juan Carlos y Deca cargan su base desde la UI y reciben un reporte de errores por renglón cuando algo falta (RF-01, RF-02).
- [ ] Los porcentajes de aseguradora, distribuidor y reparto a Garanti Plus se mantienen desde la UI sin fórmulas sueltas en Excel (RF-03).
- [ ] Por póliza se obtienen UDI del distribuidor y ganancia de GPLUS (RF-04).
- [ ] Cada distribuidor tiene su estado de cuenta con detalle de pólizas y monto total (RF-05).
- [ ] Contabilidad consulta el cierre publicado sin que nadie se lo envíe, y no puede modificarlo (RF-06, RNF-02).
- [ ] Al publicar el cierre se envía automáticamente un correo por distribuidor con su estado de cuenta y fecha límite, con copia a contabilidad (RF-07).
- [ ] Un fallo de envío queda visible y es reintentable, en lugar de fallar en silencio (RNF-04).
- [ ] Un distribuidor que no factura antes de la fecha límite se reprograma según la regla configurada (RF-08).
- [ ] Un cierre publicado no cambia si se vuelve a ejecutar el cálculo (RNF-06).
- [ ] Queda registrado quién cargó cada base, qué porcentajes estaban vigentes y cuándo se envió cada correo (RNF-03).
- [ ] Los cinco eventos de BI del PRD §11 se emiten correctamente.
- [ ] Patricia envía **cero** correos manuales de solicitud de factura en el primer cierre automatizado (meta del PRD §12).

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| El motor de cálculo existente no coincide con el Excel manual | Media | Alto | T-01 es la primera tarea del plan: auditar antes de construir encima. Si diverge mucho, replantear el alcance de la Fase 2 antes de comprometer fechas |
| `monto_pendiente_pago` queda siempre en 0 al recalcular (defecto aparente en `CalcularComisionRecibo`) | Confirmada por lectura de código | Medio | T-02. Verificar en ejecución antes de corregir, por si algún consumidor depende del comportamiento actual |
| Una sola configuración faltante aborta el cálculo de todo el periodo y contamina el reporte de errores | Confirmada por lectura de código | Alto | T-02: aislar el error por recibo en lugar de usar una bandera global. Hoy un error en el primer recibo hace que el reporte liste pólizas correctas como erróneas |
| Recalcular el corte sobrescribe lo que contabilidad y los distribuidores ya vieron | Alta | Alto | T-09: cierre inmutable versionado. Es el requisito RNF-06 y hoy no se cumple |
| Cada negocio entrega su base en un formato distinto | Alta | Medio | Mapeo de columnas configurable por negocio (T-05), no un formato único impuesto. Prerequisito: las tres bases reales |
| La regla de reprogramación no existe todavía (contabilidad no ha emitido el comunicado) | Alta | Medio | Implementarla como configuración (T-16), no como código. Solo bloquea la Fase 3; las Fases 0 a 2 avanzan sin ella |
| Un cierre publicado por error dispara correos con montos a distribuidores externos | Media | Alto | Publicación como acción explícita, separada de la generación, con confirmación en la UI y posibilidad de cancelar el cierre con trazabilidad |
| Un error de cálculo se traduce en un pago real incorrecto | Baja tras mitigar | Muy alto | Pruebas del motor (T-03), reporte de conciliación (T-19) y periodo de paralelo obligatorio antes de retirar el Excel (T-21, PRD §6) |
| El pago semanal a Autocom queda fuera y el proceso resultante es híbrido | Confirmada | Bajo | Declarado fuera de alcance en el PRD §6; documentar la frontera para que no genere expectativa |

---

## 12. Notas para el programador

- **Lee primero el hallazgo del inicio de este documento.** El PRD fue escrito sin conocer el subsistema de comisiones que ya existe en Omega; el plan está construido sobre lo que hay, no sobre lo que el PRD asume.
- **La decisión de RF-01 es la primera que hay que cerrar** y la más cara de revertir: importar la producción externa como `poliza_externa` (recomendado, reutiliza el motor) frente a un almacén paralelo de bases.
- **No reescribir el motor de cálculo.** Corregir sus defectos (T-02) y extraerlo a un servicio con interfaz (T-10), pero sin alterar la fórmula mientras T-01 no demuestre que está mal. Es código que hoy mueve dinero.
- **Rama base confirmada:** `develop` existe y está actualizada en ambos repositorios.
- **El flujo de ramas real no es el del README.** La CI bloquea los PR a `qa` que no vengan de `pre-qa` y los PR a `main` que no vengan de `release`.
- **`emisiones` es un servicio grande y ya en producción.** Todo cambio ahí afecta también emisión de pólizas y órdenes de pago. Preferir clases nuevas sobre modificar las existentes, y no refactorizar lo que no toca este alcance (`rules/stack.md`: no refactorizar salvo petición explícita).
- **Convenciones divergentes, mismo criterio que en el plan de siniestros:** el repositorio usa `snake_case` español para entidades; las guías de Engine piden `PascalCase` inglés. Para las clases nuevas se propone `PascalCase` inglés con mapeo explícito por `[Table]`/`[Column]`, y tablas en `snake_case`. Confirmar antes de T-09.
- **El contrato del correo ya existe:** publicar a NATS un JSON `{to, name_to, cc, subject, body}` en `EmailPublisher:EmailingSubject`. Copiar el patrón de `Orden_PagoController.EnviarCorreoPasarelaPago`, pero **con manejo de error real** — esa implementación traga la excepción y solo la imprime en consola, lo que incumpliría RNF-04 en este contexto.
- **Todo endpoint nuevo requiere entrada en `krakend.json`** o el frontend recibirá 404. Validar el JSON tras editarlo.
- **En el frontend ya hay pantallas de dispersión y configuración de comisiones**: extenderlas antes de crear pantallas nuevas paralelas. Recordar `limpia_filtros()` al montar cada listado, porque el objeto de filtros de `operacion-generica.js` es estado global compartido.
- **Orden de ejecución sugerido:** las Fases 0 a 2 no dependen de ningún prerequisito externo salvo las muestras de las bases y el Excel de un mes cerrado. La Fase 3 depende de la regla de contabilidad. Si esa regla se retrasa, se puede entregar hasta la Fase 2 (cierre y estado de cuenta correctos y visibles) y dejar los correos automáticos para después.

---

## 13. Relación de tareas y tiempos

**Supuesto de la estimación: dos desarrolladores trabajando en paralelo.** Los rangos de esta tabla ya incorporan la compresión del ~30% que aporta el segundo recurso. El rango con un solo desarrollador se conserva en la última columna como referencia, para no perder la trazabilidad de dónde salió el número.

| Fase | Incluye | Tareas | Días hábiles (2 devs) | ID (BD) | *Ref. 1 dev* |
|---|---|---|---|---|---|
| **Fase 0 — Auditoría y saneamiento** | Contraste contra el cierre manual, corrección de defectos del motor, pruebas del cálculo, cierre del modelo de porcentajes | T-01 a T-04 | 4 – 6 días | | *6 – 9* |
| **Fase 1 — Carga de producción externa (P1)** | Contrato e importador con validación por renglón, pantalla de carga, bitácora y reversión de lotes | T-05 a T-08 | 6 – 8 días | | *8 – 12* |
| **Fase 2 — Cierre versionado y estado de cuenta (P1)** | Cierre inmutable, cálculo de UDI y ganancia GPLUS, estados de cuenta, UI de cierre | T-09 a T-12 | 6 – 9 días | | *9 – 13* |
| **Fase 3 — Contabilidad, facturación y correos (P2)** | Rol de contabilidad, seguimiento de facturación, envío automático, reprogramación, tablero | T-13 a T-17 | 7 – 10 días | | *10 – 14* |
| **Fase 4 — BI, conciliación y despliegue** | Eventos de BI, reporte de conciliación, endurecimiento de permisos, despliegue y periodo de paralelo | T-18 a T-21 | 4 – 6 días | | *6 – 9* |
| **Total proyecto (P1+P2)** | | 21 tareas | ~27 – 39 días hábiles (≈ 5.5 – 8 semanas) | — | *39 – 57* |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-12 | ~16 – 23 días hábiles (≈ 3 – 4.5 semanas) | — | *23 – 34* |

> **Notas sobre la tabla:**
> - **Mapeo con la numeración del PRD:** todo este plan corresponde a la **Fase 1 (MVP)** del PRD. Las Fases 2 y 3 del PRD (bot de Omar, autoconsulta, cobro a aseguradoras) **no** están aquí. Las fases numeradas arriba son fases de ejecución internas del MVP.
> - **El guardarraíl aquí incluye la Fase 2 de ejecución**, no solo Fase 0 + Fase 1: un cierre sin estado de cuenta no le sirve a nadie. El corte mínimo con valor real es "cierre correcto, versionado y visible", que es donde termina la Fase 2.
> - La Fase 0 puede resultar más corta o bastante más larga según lo que arroje T-01. Si el motor existente coincide con el Excel manual, son 6 días; si diverge estructuralmente, hay que reestimar todo el plan antes de continuar.
> - Estimaciones para **dos desarrolladores de tiempo completo**. Con uno solo, aplicar la columna de referencia.
> - El paralelismo real está entre el frontend de la Fase 2 y el backend de la Fase 3. La Fase 0 es secuencial e indivisible —una sola persona debe auditar el motor para tener criterio consistente— y las Fases 1 y 2 están encadenadas por el modelo de datos, así que el segundo recurso rinde menos aquí que en un proyecto desde cero.

> **Riesgo de deadline:** el PRD **no fija fecha límite** ni fecha de inicio comprometida, así que no hay días hábiles disponibles contra los cuales contrastar. El riesgo real no es de calendario sino de **dependencias externas**: la regla de reprogramación de contabilidad (bloquea la Fase 3) y las muestras de las bases reales (bloquean la Fase 1).
>
> Recomendación: **comprometer Fases 0 a 2 (~16-23 días hábiles)**, que entregan el cierre correcto, versionado y visible para contabilidad, y no dependen del comunicado de contabilidad. Arrancar la Fase 3 cuando esa regla exista.
>
> ⚠️ **Los tiempos comprometidos en la tabla asumen dos desarrolladores en paralelo.** Si el proyecto se asigna a una sola persona, el total vuelve a 39-57 días hábiles (≈ 8-11 semanas) y el guardarraíl a 23-34 días. Confirmar la asignación de recursos antes de comunicar fechas a negocio. Ojo además con que en este proyecto el segundo recurso rinde menos que en uno desde cero: la Fase 0 no se paraleliza.
>
> **Comparado con lo que el PRD asume, este proyecto es más barato de lo esperado** — aproximadamente la mitad del MVP ya está construido. El esfuerzo se concentra en verificar que lo existente es correcto, versionarlo y cerrar el ciclo de comunicación, no en construir el motor de cálculo.

---

*Generado por Claude Code — Engine CX*
*Modelo: claude-opus-5 — esfuerzo: alto*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
