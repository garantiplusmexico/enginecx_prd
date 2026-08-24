# 02 · Mapa de módulos y lógica de negocio

| Campo | Detalle |
|---|---|
| Capítulo | C2 |
| Requerimiento(s) | RF-02, RF-03 |
| Etapa | A — T-07 |
| Versión | 1.0 (Etapa A — criticidad pendiente de validar con Fabrizio Álvarez, ver §5) |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado (Etapa A) |

> Metodología en `00-metodologia-y-evidencia.md`. Todas las tablas/RPCs por módulo son **Hecho** (extraídas por `grep` de `.from('...')` y `.rpc('...')` en cada carpeta — `inventarios/tablas-rpcs-por-modulo.txt` y `inventarios/dependencias-entre-modulos.txt`, reproducibles). La **criticidad operativa** es una **hipótesis estructural** (basada en cuántos módulos dependen de él y en su volumen de código) marcada explícitamente como pendiente de validación con Fabrizio Álvarez (A6) — afirmarla como hecho sin esa validación violaría RNF-02.

---

## 0. Hallazgo de arranque: la documentación existente no cubre ni el 75% de los módulos

El `CLAUDE.md` del repositorio (fuente de conocimiento que el propio PRD identifica como "todo el conocimiento vive aquí") documenta **17 de los 24 módulos** en su tabla de `src/features/`. **7 módulos no tienen ni una línea de descripción en `CLAUDE.md`**: `callcenter`, `gastos`, `hunter`, `incentivos`, `portal`, `postventa`, `solicitudes`. De estos, `postventa` es el módulo **más grande del sistema** (87 archivos, el 19% de todo `src/features/`) y `hunter` es el segundo más grande (46 archivos). Esto no es un detalle menor: es evidencia directa y cuantificada del problema que motiva el PRD ("TI no lo conoce, no lo gobierna") — ni siquiera la documentación de arranque del propio proyecto lo conoce.

**Además, `CLAUDE.md` lista un módulo `tv` que no existe como carpeta propia** — la funcionalidad del tablero público `/tv` vive dentro de `warroom` (confirmado en C8/T-14: canal `warroom-comando` en `WarRoomView.tsx`, tabla `tv_dashboard_state`).

---

## 1. Resumen ejecutivo — los 24 "módulos" reales

| Módulo | Archivos | Dominio (hipótesis) | Documentado en `CLAUDE.md` | Dependen de él (in-degree) |
|---|---|---|---|---|
| `postventa` | 87 | Operación de garantías | ❌ No | 1 (`callcenter`) |
| `visitas` | 70 | Comercial | ✅ Sí | 8 |
| `hunter` | 46 | Comercial (prospección B2B) | ❌ No | 1 (`config`) |
| `gastos` | 26 | Transversal (administrativo) | ❌ No | 0 |
| `salas` | 33 | Comercial | ✅ Sí | 6 |
| `facturacion` | 35 | Operación de garantías | ✅ Sí | 5 |
| `config` | 23 | Transversal | ✅ Sí | 0 |
| `warroom` | 17 | Comercial | ✅ Sí (parcial, como "tv") | 1 (`visitas`) |
| `vendedores` | 10 | Comercial | ✅ Sí | 4 |
| `solicitudes` | 9 | Transversal (workflow compartido) | ❌ No | 4 |
| `unoauno` | 8 | Comercial | ✅ Sí | 0 |
| `induccion` | 7 | Transversal | ✅ Sí | 4 |
| `portal` | 7 | Operación de garantías | ❌ No | 0 |
| `callcenter` | 6 | Transversal (infra) → toca operación vía `av_casos` | ❌ No | 1 (`postventa`) |
| `auth` | 5 | Transversal | ✅ Sí | 6 |
| `averias` | 15 | Operación de garantías | ✅ Sí | 1 (`config`, `warroom`) |
| `mora` | 4 | Operación de garantías (con consumo comercial) | ✅ Sí | 2 (`config`, `unoauno`) |
| `bienvenida` | 4 | Transversal | ✅ Sí | 1 (`portal`) |
| `incentivos` | 3 | Comercial | ✅ Sí | 0 |
| `productos` | 3 | Transversal (catálogo compartido) | ✅ Sí | 2 (`config`, `salas`) |
| `resumen` | 3 | Comercial | ✅ Sí | 1 (`visitas`) |
| `cobertura` | 2 | Comercial | ✅ Sí | 2 (`config`, `unoauno`) |
| `bitacora` | 0 (placeholder) | — | ✅ Sí (desactualizado) | — |
| `farmer` | 0 (placeholder) | — | ✅ Sí (correcto) | — |

**Nota de lectura de "in-degree":** cuenta módulos que importan código del módulo en cuestión (`from '@/features/X'`), no cuántas tablas comparten. `visitas` con in-degree 8 es, con evidencia, el módulo más central del sistema — lo confirma también su tamaño (70 archivos) y que toca 16 tablas distintas.

---

## 2. Fichas por módulo

### `auth` — Autenticación y roles
- **Propósito:** login, sesión y verificación de rol (`AuthProvider.tsx`, `LoginPage.tsx`).
- **Tablas/RPCs:** `asesores`, `usuarios` (sin RPCs propias).
- **Dependencias:** ninguna hacia adentro; **6 módulos dependen de él** (`callcenter`, `config`, `facturacion`, `gastos`, `hunter`, `postventa`, `salas`, `solicitudes`, `vendedores`, `visitas` — de hecho más de 6, ver tabla completa en `inventarios/dependencias-entre-modulos.txt`).
- **Ubicación de la lógica:** front (`AuthProvider`), con las tablas `usuarios`/`asesores` como fuente — no se detectaron RPCs de autorización propias del módulo (la autorización específica de cada acción vive en el módulo que la ejecuta, vía RLS/RPC — a confirmar en C11/T-32).
- **Criticidad operativa:** **Alta (hipótesis)** — es dependencia transversal de facto; una falla aquí bloquea todo el sistema.
- **Dominio:** Transversal.

### `averias` — Siniestralidad e importación de reportes SIGA
- **Propósito:** importar reportes de averías ACTIVAS/CERRADAS de SIGA (`ImportarAverias.tsx`) y mostrar siniestralidad por país/salas/tendencia/velocidad.
- **Tablas/RPCs:** tabla `averias`; RPCs de cálculo agregado: `siniestralidad`, `siniestralidad_cobertura`, `siniestralidad_tendencia_scope`, `velocidad_siniestro_scope`.
- **Dependencias:** ninguna saliente; lo consumen `config` y `warroom`.
- **Ubicación de la lógica:** **mixta y bien separada** — el *parseo* del Excel (`parseAverias.ts`, confirmado en T-13) vive en el front; el *cálculo agregado* de siniestralidad vive en RPCs de Postgres (los 4 nombres arriba). Es un patrón sano: la transformación de datos externos en el front, el cálculo de negocio en la base.
- **Criticidad operativa:** **Alta (hipótesis)** — es uno de los dos flujos de entrada de SIGA que documenta el PRD, y siniestralidad es un KPI de negocio central.
- **Dominio:** Operación de garantías.

### `bienvenida` — Landing post-login
- **Propósito:** pantalla de bienvenida/rebrand tras el login (`WelcomeScreen.tsx`).
- **Tablas/RPCs:** sin tablas propias; una RPC (`marcar_bienvenida_vista`).
- **Dependencias:** ninguna; lo consume `portal`.
- **Ubicación de la lógica:** trivial, casi toda en front (marca de "ya visto" vía RPC).
- **Criticidad operativa:** **Baja (hipótesis)** — cosmético/UX, sin impacto en KPIs de negocio si falla.
- **Dominio:** Transversal.

### `callcenter` — Softphone y KPIs de call center
- **Propósito:** telefonía integrada (Twilio Voice SDK), presencia de agentes, KPIs de llamadas.
- **Tablas/RPCs:** `cc_llamadas`, `cc_pausas`, `cc_presencia`, `cc_sesiones`, `llamadas`, y **`av_casos`** (del dominio postventa — ver nota); 7 RPCs `cc_kpi_*` más `usuario_actual`.
- **Dependencias:** depende de `auth`; lo consume `postventa`.
- **Ubicación de la lógica:** los KPIs (diario, agente, distribución, pausas, vivo, conexión) están **todos en RPCs** — el front solo orquesta llamadas paralelas a 5 RPCs (`TelefonoKpis.tsx`). Buen patrón para portabilidad.
- **Criticidad operativa:** **Alta (hipótesis)** — atención telefónica en vivo, con Realtime dedicado (C8).
- **Dominio:** **Transversal de infraestructura, pero toca `av_casos` — cruza hacia Operación de garantías.** Es una de las costuras a resolver en E4 (ver `PLAN.md` §1.3): el softphone es un servicio de comunicación reutilizable, pero está acoplado a las tablas de averías via `av_casos`.

### `cobertura` — Auditoría de poblamiento de salas
- **Propósito:** dictamen del avance de cada asesor poblando su sala (según `CLAUDE.md`).
- **Tablas/RPCs:** tabla `cobertura_diaria`; RPCs `cobertura_datos`, `cobertura_snapshot`.
- **Dependencias:** ninguna saliente; lo consumen `resumen` y `unoauno`.
- **Ubicación de la lógica:** cálculo en RPC (`cobertura_datos`/`cobertura_snapshot`), consumo en front — solo 2 archivos, muy delgado.
- **Criticidad operativa:** **Media-Alta (hipótesis)** — alimenta directamente el resumen matutino y el 1:1, ambos con foco en accountability del asesor.
- **Dominio:** Comercial.

### `config` — Mantenedores del Country Manager
- **Propósito:** administración de catálogos y accesos: salas, zonas, asesores, proveedores, tipos de solicitud, feriados, monedas, presupuestos, config de postventa.
- **Tablas/RPCs:** **21 tablas** (el segundo mayor número tras `postventa`) — `areas`, `asesores`, `av_config`, `capacidades`, `feriados`, `grupos_*`, `monedas`, `presupuestos`, `proveedores`, `rol_capacidades`, `roles`, `salas_*`, `solicitud_tipos`, `usuario_areas`, `usuario_roles`, `usuarios`; 9 RPCs de administración.
- **Dependencias:** depende de 8 módulos (`auth`, `averias`, `facturacion`, `hunter`, `induccion`, `mora`, `productos`, `salas`, `vendedores`) — es el módulo con **mayor out-degree**, consistente con ser "el panel de mantenedores de todo".
- **Ubicación de la lógica:** administración simple (CRUD) mayormente en front + RPCs puntuales para operaciones con reglas (`proveedor_crear`, `solicitud_tipo_crear`, `hunter_guardar_mi_firma`, `organigrama`).
- **Criticidad operativa:** **Alta (hipótesis)** — toca la configuración base de todos los demás módulos comerciales.
- **Dominio:** Transversal (pero con alcance sobre tablas de ambos dominios: `av_config` es de operación, `salas_*` es comercial).

### `facturacion` — KPIs de facturación y cierre de mes
- **Propósito:** carga de contratos SIGA (`ImportarContratos.tsx`), dashboards de facturación diaria/mensual, cierre de mes, proyección de cierre, informes.
- **Tablas/RPCs:** `contratos`, `contratos_staging`, `cargas_siga`, `asesores`, `grupos_*`, `plan_tareas`, `planes_accion`, `presupuestos`; 8 RPCs, incluidos `aplicar_contratos_staging`/`aplicar_contratos_staging_anio` (patrón *staging → aplicar*, buena práctica para cargas masivas) y `facturacion_diaria`/`facturacion_mensual` (cálculo agregado).
- **Dependencias:** depende de `auth`, `averias`, `config`, `induccion`, `salas`, `visitas`; lo consumen `config`, `hunter`, `resumen`, `salas`, `warroom` (5 módulos).
- **Ubicación de la lógica:** el patrón *staging* sugiere que la validación de la carga masiva de contratos vive en RPC (`aplicar_contratos_staging`), separada de la importación del Excel (front, `parseContratos.ts`, confirmado en T-13) — mismo patrón sano que `averias`.
- **Criticidad operativa:** **Alta (hipótesis)** — es el segundo flujo de entrada de SIGA y alimenta el cierre de mes, que el PRD identifica explícitamente como cálculo crítico a no perder en una re-escritura.
- **Dominio:** Operación de garantías (los contratos son el objeto que gobierna SIGA), con fuerte consumo desde el lado comercial.

### `gastos` — Rendición de gastos de asesores
- **Propósito:** captura, auditoría y aprobación de rendiciones de gastos (viáticos, gasolina, etc.) de asesores de terreno.
- **Tablas/RPCs:** `gasto_archivos`, `gasto_asignaciones`, `gasto_categorias`, `gastos`, `rendicion_eventos`, `rendiciones`; RPCs de flujo: `gasto_crear`, `gasto_fusionar`, `rendicion_aprobar_jefe`, `rendicion_aprobar_ops`, `rendicion_enviar`, `rendicion_marcar_pagada`, `rendicion_rechazar`, `rendicion_reenviar` — es un **flujo de aprobación de dos etapas** (jefe → operaciones) con estado explícito.
- **Dependencias:** depende solo de `auth`; ningún módulo depende de él (in-degree 0) — es un módulo autocontenido.
- **Ubicación de la lógica — HALLAZGO:** el **auditor de anomalías** (`auditor.ts`) — que marca gastos con monto alto (`umbralMontoAltoClp`) o distancia GPS sospechosa (`umbralGpsKm`) para revisión — vive **enteramente en el front**, con umbrales configurables y cubierto por tests (`auditor.test.ts`). Si esta auditoría condiciona la aprobación (a confirmar si el resultado se envía a las RPCs de aprobación o es solo informativo en la UI), es un candidato a hallazgo de integridad para C11 — un control de fraude/anomalía que corre en el cliente es evitable manipulando el cliente.
- **Criticidad operativa:** **Media (hipótesis)** — administrativo/financiero, sin visibilidad directa de otros módulos hacia él.
- **Dominio:** Transversal (administrativo/financiero, no ligado a garantías ni directamente a ventas).

### `hunter` — Prospección B2B (concesionarios, financieras, importadores)
- **Propósito:** CRM de prospección de nuevos canales comerciales — empresas, personas de contacto, oportunidades, cotizador, contratos, agenda de reuniones, firma digital, onboarding.
- **Tablas/RPCs:** **21 tablas** — `empresas`, `personas`, `hunter_*` (actividad, contacto_rol, contrato, cotizacion, handoff, oportunidad, precio, reunion), `mercado_*` (concesionario, financiera, importador, parametro), `espejo_*` (plan, precio, tramo — sugiere una copia/reflejo del catálogo de productos para cotizar sin afectar el maestro), `sala_vendedores`; 12 RPCs, incluida toda la lógica de **firma digital** (`hunter_firma_cargar`, `hunter_firma_firmar`, `hunter_firma_firmar_interno`, `hunter_firma_solicitar`, `hunter_firmantes_de`).
- **Dependencias:** depende de `auth`, `facturacion`, `solicitudes`; lo consume `config` (para `hunter_guardar_mi_firma`).
- **Ubicación de la lógica:** la firma digital y el cierre de oportunidad (`hunter_cerrar_reunion`, `hunter_opp_archivar`) están en RPC; el cotizador (`CotizadorPanel.tsx`) probablemente calcula en front sobre los datos "espejo" — **a profundizar si se retoma con más tiempo**, no crítico para el dictamen de esta etapa.
- **Criticidad operativa:** **Alta (hipótesis) para el crecimiento del negocio, no para la operación diaria** — es el segundo módulo más grande del sistema (46 archivos) y **no está documentado en absoluto en `CLAUDE.md`**, lo cual es en sí mismo un hallazgo de gobierno.
- **Dominio:** Comercial (prospección/adquisición de nuevos canales).

### `incentivos` — Cálculo y pago de incentivos comerciales
- **Propósito:** ciclo completo de incentivos por período: generación, carga de pagos, envío para revisión, aprobación/rechazo, comentarios del Country Manager.
- **Tablas/RPCs:** `incentivo_comentario`, `incentivo_envio`, `incentivo_linea`, `incentivo_pago`, `incentivo_periodo`, `asesores`, `vendedores`; 9 RPCs de flujo (`incentivos_generar`, `incentivos_aplicar_datos`, `incentivos_enviar`, `incentivos_resolver`, `incentivos_reabrir`, `incentivos_sync`, etc.).
- **Dependencias:** ninguna; in-degree 0.
- **Ubicación de la lógica:** **máquina de estados de dos dimensiones** — el período tiene estado (`abierto → listo_para_carga → generado → cargado → confirmado`) y cada envío individual tiene el suyo (`borrador → en_revision → aprobado → rechazado`), ambos tipados explícitamente en el front (`IncentivosView.tsx`) pero materializados en RPCs (`incentivos_resolver`, `incentivos_reabrir`) — sugiere que la transición de estado se valida en la base, no solo en la UI.
- **Criticidad operativa:** **Alta (hipótesis)** — impacto directo en la compensación de asesores; un error aquí es un error de nómina.
- **Dominio:** Comercial.

### `induccion` — Tour de onboarding (FABBRO)
- **Propósito:** tour guiado por rol usando `react-joyride` (`FabbroTour.tsx`, `FabbroBotones.tsx`, `FabbroTooltip.tsx`, `FabbroPreview.tsx`).
- **Tablas/RPCs:** ninguna propia.
- **Dependencias:** ninguna saliente; lo consumen 4 módulos (`config`, `facturacion`, `salas`, `vendedores` — se integra como overlay en varias vistas).
- **Ubicación de la lógica:** 100% front, sin persistencia propia detectada.
- **Criticidad operativa:** **Baja (hipótesis)** — UX de onboarding, no bloquea operación.
- **Dominio:** Transversal.

### `mora` — Cobranza y penalización
- **Propósito:** vista de cobranza (`CobranzaMora.tsx`, `CobranzaView.tsx`).
- **Tablas/RPCs:** `mora_clientes`, `mora_corte`, `mora_vinculos`; una RPC compartida con `salas` (`salas_resumen`).
- **Dependencias:** ninguna saliente; lo consumen `config`, `unoauno`.
- **Ubicación de la lógica:** muy delgado (4 archivos) — la lógica de corte de mora probablemente vive en la RPC/vista de base (`mora_corte` es nombre de tabla, sugiere que el corte se materializa en la base, no se calcula en el front en cada render).
- **Criticidad operativa:** **Media-Alta (hipótesis)** — el estado de mora de un cliente condiciona cobranza y probablemente cobertura/servicio; se consume en `unoauno` para accountability del asesor.
- **Dominio:** Operación de garantías (estado de pago del contrato), con consumo comercial.

### `portal` — Portal externo (proveedores/clientes)
- **Propósito:** superficie pública/semi-pública — foro de bienvenida, panel y guía de proveedores (talleres).
- **Tablas/RPCs:** sin tablas ni RPCs propias detectadas en la carpeta (probablemente reutiliza RPCs de `postventa`/`solicitudes` para proveedores — a verificar si se profundiza).
- **Dependencias:** depende de `bienvenida`; in-degree 0.
- **Ubicación de la lógica:** front, orquestando llamadas a RPCs de otros módulos.
- **Criticidad operativa:** **Alta (hipótesis) — es superficie pública**, lo que la vuelve sensible de seguridad (autenticación/autorización de terceros externos) independientemente de su tamaño. Prioridad para C11.
- **Dominio:** Operación de garantías (talleres/proveedores son parte del ciclo de averías).

### `postventa` — Gestión completa de casos de avería
- **Propósito:** el módulo más grande del sistema. Cubre todo el ciclo de un caso de avería: nueva avería, bandeja, detalle, evidencias, taller, órdenes de compra, facturas, pagos, encuestas, resoluciones, WhatsApp del caso, reparto de asesores, SLA.
- **Tablas/RPCs:** **20 tablas** (`av_*` casi en su totalidad, más `cc_llamadas`, `contratos`, `monedas`) y **41 RPCs** — el mayor número de todo el sistema, por un margen amplio.
- **Dependencias:** depende de `auth`, `callcenter`, `config`; in-degree 1 (`callcenter`, ver nota de costura arriba).
- **Ubicación de la lógica:** **fuertemente concentrada en RPC** — con 41 funciones nombradas por acción de negocio (`av_cerrar_con_oc_sin_factura`, `av_cerrar_sin_cobertura`, `av_forzar_cierre_sin_retiro`, `av_marcar_sin_ingreso`, `av_reabrir_caso`, `av_clausulado_aprobar`...), la mayoría de las reglas de cierre y transición de un caso viven en la base, no en el front. Es el módulo con el patrón de "lógica en RPC" más consistente de todo el sistema.
- **Criticidad operativa:** **Crítica (hipótesis)** — es el corazón operativo del negocio (gestión de siniestros) y el módulo más grande y complejo; una re-escritura mal informada aquí es el mayor riesgo de todo el proyecto.
- **Dominio:** Operación de garantías (núcleo).

### `productos` — Catálogo de productos de garantía
- **Propósito:** catálogo con base económica, IVA y margen (`ProductosCatalogo.tsx`).
- **Tablas/RPCs:** `productos_catalogo`; RPCs `productos_distintos`, `productos_economia`.
- **Dependencias:** ninguna saliente; lo consumen `config`, `salas` (y `hunter`, indirectamente, vía `espejo_precio`/`espejo_plan`, a confirmar).
- **Ubicación de la lógica:** cálculo económico probablemente en RPC (`productos_economia`).
- **Criticidad operativa:** **Media (hipótesis)** — catálogo maestro, cambios poco frecuentes pero de alto impacto si están mal.
- **Dominio:** Transversal (catálogo compartido, alimenta pricing tanto comercial como de garantía).

### `resumen` — Briefing matutino
- **Propósito:** "☀️ Hoy" — motor de señales con datos de asesores, bitácoras, proyección diaria.
- **Tablas/RPCs:** `asesores`, `bitacoras`, `plan_tareas`, `proyeccion_diaria`, `resumen_diario`, `usuarios`, `visitas`; RPC `cobertura_datos` (compartida con `cobertura`).
- **Dependencias:** depende de `auth`, `cobertura`, `config`, `facturacion`, `salas`, `visitas` — **consume de 6 módulos distintos**, consistente con ser un "resumen" agregador.
- **Ubicación de la lógica:** agregación, probablemente mixta (RPC para el cálculo de `proyeccion_diaria`/`resumen_diario`, ensamblaje final en front).
- **Criticidad operativa:** **Alta (hipótesis)** — es el punto de entrada diario del Country Manager según `CLAUDE.md` ("briefing matutino").
- **Dominio:** Comercial.

### `salas` — Gestión de salas, zonas y metas
- **Propósito:** vistas por Grupo → Zona → Asesor, catálogo de salas, metas (wizard, aceptación), cierre de salas, mapa geográfico.
- **Tablas/RPCs:** 16 tablas (`salas_*`, `americar_siga_real`, `metas_aceptacion`, `mora_clientes`, `mora_salud_salas`...); 19 RPCs, incluidas `cierre_salas_margen`, `activacion_sala`/`salas_activacion`, `pc_ejecutivos_americar`/`pc_mix_americar`.
- **Dependencias:** depende de 7 módulos (`auth`, `config`, `facturacion`, `induccion`, `mora`, `productos`, `vendedores`, `visitas`); lo consumen 6 (`config`, `facturacion`, `induccion`, `resumen`, `unoauno`, `vendedores`, `warroom`).
- **Ubicación de la lógica:** cierre y activación de sala en RPC; el wizard de metas (mencionado en la sección de feedback del usuario — "el wizard muestra la meta ya bajada") combina front + RPC.
- **Criticidad operativa:** **Crítica (hipótesis)** — es, con `postventa`, el segundo eje central del sistema: conecta prácticamente todos los módulos comerciales.
- **Dominio:** Comercial (núcleo).

### `solicitudes` — Workflow de solicitudes y tareas a proveedores
- **Propósito:** creación, asignación y seguimiento de solicitudes (marketing, proveedores) convertibles en tareas.
- **Tablas/RPCs:** `areas`, `plan_tareas`, `proveedores`, `proveedores_publico`, `solicitud_eventos`, `solicitud_tipos`, `solicitudes`, `tarea_avances`, `usuario_areas`, `usuarios`; 15 RPCs de flujo (`solicitud_crear`, `solicitud_asignar`, `solicitud_cambiar_estado`, `solicitud_convertir_en_tarea`, `tarea_proveedor_crear`, `tarea_proveedor_pedir_correccion`, `tarea_calificar_proveedor`...).
- **Dependencias:** depende de `auth`, `visitas`; lo consumen `hunter`, `visitas` (tareas de sala también pasan por aquí, ver `crear_tarea_sala` en `salas`/`visitas`).
- **Ubicación de la lógica:** flujo de estado en RPC, consistente con `gastos` y `postventa`.
- **Criticidad operativa:** **Media (hipótesis)** — infraestructura de workflow compartida, no un dominio de negocio en sí mismo.
- **Dominio:** Transversal (motor de workflow reutilizado por comercial y operación).

### `unoauno` — Sesiones 1:1 con IA
- **Propósito:** dossier semanal, accountability y tareas de la sesión 1:1 del gerente con el asesor.
- **Tablas/RPCs:** `agenda_eventos`, `asesores`, `bitacoras`, `lobbies`, `plan_tareas`, `planes_accion`, `tarea_avances`, `uno_a_uno_sesiones`, `usuarios`, `visitas`; RPCs `cierre_salas_margen` (compartida con `salas`) y `cobertura_datos` (compartida con `cobertura`/`resumen`).
- **Dependencias:** depende de `cobertura`, `config`, `mora`, `salas`, `visitas` — es, junto con `resumen`, uno de los mayores consumidores transversales.
- **Ubicación de la lógica:** agregación de datos de otros dominios para la sesión; la parte de IA (dossier) vive probablemente en Edge Function (a confirmar en C4/T-11 — hay una función `dossier-ia` y `dossier-cron` en el catálogo de 46).
- **Criticidad operativa:** **Alta (hipótesis)** — es una de las herramientas de gestión de personas explícitamente descritas en el PRD original de GarantiMAX (`CLAUDE.md`).
- **Dominio:** Comercial.

### `vendedores` — Roster de vendedores por RUT
- **Propósito:** gestión de identidad de vendedores (fusión, importación, pool sin punto de venta, ficha).
- **Tablas/RPCs:** `autos_vendedor`, `incentivo_pago`, `interacciones_vendedor`, `sala_vendedores`, `vendedores`, `visitas`; 11 RPCs, incluida la resolución de identidad (`vendedor_por_rut`, `vendedor_por_nombre`, `vendedor_inactivo_por_nombre`, `fusionar_vendedor`, `merge_vendedores`, `buscar_vendedor_siga`).
- **Dependencias:** depende de `auth`, `induccion`, `salas`, `visitas`; lo consumen `config`, `hunter` (vía `vendedor_por_rut`), `salas`, `visitas`, `warroom`.
- **Ubicación de la lógica:** la resolución/fusión de identidad de vendedor (un problema de calidad de datos reconocido — múltiples RPCs de "buscar/fusionar/merge") vive en RPC.
- **Criticidad operativa:** **Alta (hipótesis)** — es la fuente de identidad (`CLAUDE.md`: "identidad por RUT") que consumen 5 módulos.
- **Dominio:** Comercial (maestro compartido).

### `visitas` — Terreno, PWA y offline
- **Propósito:** el módulo más central del sistema por dependencias entrantes (in-degree 8). Mi Día, nueva visita, bitácora, calendario, tareas, lobbies, dictado por voz, mejora por IA.
- **Tablas/RPCs:** `agenda_eventos`, `asesores`, `bitacoras`, `lobbies`, `notificaciones`, `plan_tareas`, `planes_accion`, `proyecto_operadores`, `proyectos`, `sala_vendedores`, `saludos_cumpleanos`, `solicitudes`, `tarea_avances`, `usuarios`, `visitas`, `visitas_abiertas`, `visitas_en_curso` (16 tablas); 15 RPCs de gestión de tareas y proyectos.
- **Dependencias:** depende de `auth`, `config`, `induccion`, `resumen`, `salas`, `solicitudes`, `vendedores`, `warroom` — el módulo con **más dependencias salientes de todas** (8).
- **Ubicación de la lógica:** mixta — gestión de tareas en RPC (`completar_tarea`, `calificar_tarea`, `crear_tarea_sala`); la parte PWA/offline (IndexedDB) vive enteramente en el front por naturaleza (`src/lib/idbStore.ts` y similares, a documentar en C9/T-15).
- **Criticidad operativa:** **Crítica (hipótesis)** — es el módulo de trabajo diario del asesor de terreno, con offline obligatorio; su interrupción afecta directamente la operación del Hub Sur.
- **Dominio:** Comercial (núcleo, junto con `salas`).

### `warroom` — Sala de guerra / tablero público
- **Propósito:** command center en vivo con feed de eventos, control remoto del tablero público `/tv` (kiosko 4K).
- **Tablas/RPCs:** `contratos`, `sala_vendedores`, `tv_dashboard_state`, `visitas`, `visitas_en_curso`; RPC `vendedor_por_nombre`.
- **Dependencias:** depende de `averias`, `facturacion`, `resumen`, `salas`, `vendedores`, `visitas` — agrega de 6 dominios distintos para un tablero unificado.
- **Ubicación de la lógica:** front (dashboard de agregación), con Realtime como mecanismo de actualización (ver C8/T-14 completo — 5 de los 11 canales del sistema son de este módulo).
- **Criticidad operativa:** **Alta (hipótesis)** — visibilidad ejecutiva en vivo, pero no transaccional (una caída no bloquea la operación, solo la visibilidad).
- **Dominio:** Comercial.

### `bitacora` y `farmer` — Placeholders
Ambos son carpetas vacías (solo `README.md` describiendo la intención original). `farmer` está correctamente documentado como placeholder en `CLAUDE.md`. **`bitacora` no** — `CLAUDE.md` lo lista como módulo activo ("Bitácora diaria"), pero la funcionalidad real de bitácora de terreno vive en `visitas` (`bitacora.ts`, `BitacoraDia.tsx`, `bitacoraTerreno.ts`, `GateBitacoras.tsx`). Se agrega a los hallazgos de documentación desactualizada (junto con la nota de migraciones/`CLAUDE.md` de `PLAN.md` §12 nota 4).

---

## 3. Segmentación por dominio — resultado (insumo de E4)

| Dominio | Módulos | Notas |
|---|---|---|
| **Comercial / seguimiento de vendedores** | `visitas`, `salas`, `hunter`, `vendedores`, `warroom`, `unoauno`, `resumen`, `cobertura`, `incentivos` | Núcleo: `visitas` + `salas` (mayor in/out-degree del sistema). |
| **Operación de garantías** | `postventa`, `averias`, `facturacion`, `mora`, `portal` | Núcleo: `postventa` (87 archivos, 41 RPCs — con margen el módulo más grande y con lógica más concentrada en base). |
| **Transversal** | `auth`, `config`, `induccion`, `bienvenida`, `gastos`, `productos`, `solicitudes` | Infraestructura y catálogos compartidos por ambos dominios. |
| **Cruza la frontera (costura)** | `callcenter` | Estructuralmente transversal (telefonía), pero su tabla `av_casos` es del dominio de operación — acopla un servicio de comunicación genérico a un caso de avería específico. |

**Diferencias frente a la hipótesis inicial de `PLAN.md` §1.3:** la hipótesis original agrupaba `productos`, `portal`, `solicitudes` directamente en "operación de garantías". Con evidencia real: `productos` es un catálogo compartido (lo consume tanto `salas` como, indirectamente, `hunter`) — se reclasifica como **transversal**. `solicitudes` es un motor de workflow genérico que usan tanto `hunter` (comercial) como talleres/proveedores (operación) — se reclasifica como **transversal**. `portal` sí se confirma en operación (talleres/proveedores). Se agrega `callcenter` como **costura explícita**, no prevista en la hipótesis original.

**Para E4 (T-24/T-37):** si el corte de dominio se ejecutara hoy, las costuras a resolver serían: (1) `callcenter` — decidir si el softphone viaja con operación (por `av_casos`) o se conserva como servicio transversal con una integración más débil; (2) los catálogos transversales (`productos`, `solicitudes`, `config`) tendrían que servir a ambos lados, ya sea duplicados o como servicio compartido cruzando la frontera. Ninguna de las dos es bloqueante por sí sola, pero ambas tienen costo de desacoplamiento que T-08 debe cuantificar a nivel de tabla.

---

## 4. Cobertura declarada (RNF-11)

**24/24 módulos con ficha** (22 con código + 2 placeholders documentados). **0 módulos sin alcanzar.** Profundidad de "reglas de negocio" desigual a propósito: los módulos más grandes y críticos (`postventa`, `salas`, `visitas`, `facturacion`, `hunter`, `gastos`) tienen evidencia de código leída directamente; los módulos pequeños (`bienvenida`, `cobertura`, `incentivos`, `mora`, `productos`) se documentan con la misma exactitud de tablas/RPCs pero con menor profundidad de lectura de lógica interna — declarado aquí en vez de aparentar exhaustividad pareja.

**Pendiente explícito para completar este capítulo (no bloquea el cierre de Etapa A, pero condiciona su firmeza):**
- **Criticidad operativa real** de los 24 módulos — hoy es hipótesis estructural, requiere validación con Fabrizio Álvarez (A6).
- Confirmar si el auditor de gastos (`gastos/auditor.ts`) es solo informativo o condiciona la aprobación — relevante para C11.
- Profundizar `hunter` (cotizador) y `portal` si el tiempo lo permite — son los dos módulos con menor evidencia de "dónde vive la lógica" pese a estar bien inventariados en tablas/RPCs.
