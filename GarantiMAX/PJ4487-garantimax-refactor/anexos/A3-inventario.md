# Anexo A3 — Inventario del sistema actual y clasificación por fases

> Complemento del PRD `manager/PRD.md` (Reconstrucción de GarantiMAX — Fase 1).
> Levantamiento factual sobre el repositorio `garantiplus-dashboard`, rama de trabajo local, **25-08-2026**.
> Versión v0.2 — 26-08-2026. Este anexo se actualizará con los hallazgos del PRD hermano de análisis técnico (PJ3896) cuando esté disponible.

> ### ⚠️ Cómo leer este anexo tras ADR-011
>
> Este documento describe el **sistema actual** y sigue siendo válido en todo lo que mide. Lo que cambió es su **función**: ya no es el inventario de lo que se conserva, sino la **especificación de las reglas que hay que reimplementar** en el servicio .NET. La v0.2 agrega la §3.1 con las trampas del esquema, verificadas contra el código, y corrige tres errores de la v0.1.

---

## 1. Cifras del sistema actual

| Dimensión | Medida |
| --- | --- |
| Módulos en `src/features/` | **24** (2 de ellos carpetas vacías) |
| Archivos de código (`.ts` / `.tsx`) | **455** |
| Componentes (`.tsx`) | **206** |
| Líneas de código | **~109.000** |
| Archivos de prueba (Vitest) | **65** |
| Tablas en base de datos | **128** |
| Migraciones SQL | **364** |
| Edge Functions | **46** |
| Llamadas `.from()` / `.rpc()` | **926** |
| …de ellas, dentro de archivos `.tsx` | **443** (48 %) |
| Archivos que importan el cliente de Supabase | **152** |
| Archivos que usan Realtime | **9** |
| Líneas de `App.tsx` | **916** |
| Líneas de `MiDiaMovil.tsx` | **972** |
| Dependencias de producción | 14 |
| Router / librería de estado / capa de datos | **ninguna** |

---

## 2. Inventario de módulos y clasificación

Clasificación según el requerimiento: **Fase 1** (núcleo de terreno del asesor) · **Fase 2** · **Fase 3** · **Futuro** · **Legacy** · **Requiere análisis**.

| Módulo | Archivos | Líneas | Qué hace | Clasificación |
| --- | ---: | ---: | --- | --- |
| **`auth`** | 5 | 619 | Inicio de sesión (correo/contraseña y Google), sesión, perfil, "Ver como" | **Fase 1** |
| **`visitas`** | 70 | 14.245 | Mi Día, visitas con check-in, lobbies, tareas, agenda, bitácora, saludos de cumpleaños, notificaciones, app móvil de terreno | **Fase 1** — es el corazón del alcance |
| **`gastos`** | 26 | 8.779 | Captura de boletas, categorización, asignación, rendiciones y flujo de aprobación | **Fase 1** |
| **`bienvenida`** | 4 | 1.866 | Pantalla de bienvenida por perfil, descartable | **Fase 1** |
| **`facturacion`** | 35 | 8.820 | Consulta de facturación e importadores de contratos desde Excel de SIGA | **Fase 2** (consulta del asesor) · **Fase 3** (importadores, que son de CM/GTE) |
| **`salas`** | 33 | 7.722 | Cartera de salas: fichas, metas, comentarios, tareas de sala, cruces de objetivo | **Fase 2** — Fase 1 la lee como referencia |
| **`vendedores`** | 10 | 2.530 | Fichas de vendedor de sala, fusión, pool sin PV, importación y exportación | **Fase 2** — Fase 1 la lee como referencia |
| **`cobertura`** | 2 | 327 | Tablero de penetración de cobertura | **Fase 2** |
| **`incentivos`** | 3 | 1.125 | Períodos, líneas, pagos y comentarios de incentivos | **Fase 2** — hoy **incrustado dentro de `SalasView`**, se extrae como feature propio |
| **`solicitudes`** | 9 | 3.388 | Solicitudes con tipos y eventos | **Fase 3** — verificar uso real del AF (hoy sin gate de capacidad) |
| **`config`** | 23 | 5.254 | Equipo y accesos, matriz de roles y capacidades, proveedores, parámetros | **Fase 3** parcial (perfil del asesor) · resto **Futuro** |
| **`postventa`** | 87 | 27.408 | Casos de avería, evaluación, resolución, chat de WhatsApp, informes. **El módulo más grande del sistema** | **Futuro** |
| **`hunter`** | 46 | 11.390 | Embudo de oportunidades, cotizador, contratos con firma, onboarding, directorio, investigación de mercado | **Futuro** |
| **`callcenter`** | 6 | 2.509 | Panel telefónico, IVR, transcripción, KPIs en vivo (Twilio) | **Futuro** |
| **`warroom`** | 17 | 2.262 | Tablero en vivo de visitas y eventos, proyectable | **Futuro** — primer consumidor real de Realtime |
| **`portal`** | 7 | 2.559 | Portal de clientes y proveedores, con su propia autenticación | **Futuro** |
| **`mora`** | 4 | 1.367 | Cobranza, tramos de mora, cortes y vínculos | **Futuro** |
| **`unoauno`** | 8 | 3.060 | Sesiones 1:1, captura de reunión, supervisión, dossier con IA | **Futuro** |
| **`averias`** | 15 | 1.857 | Importadores de reportes de averías desde Excel | **Futuro** |
| **`productos`** | 3 | 985 | Catálogo de productos | **Futuro** |
| **`resumen`** | 3 | 1.161 | Resumen diario y envío programado | **Futuro** |
| **`induccion`** | 7 | 1.094 | Modo inducción guiado (FABBRO) | **Requiere análisis** — ¿se conserva el concepto o se reemplaza por otra forma de acompañamiento? |
| **`farmer`** | 0 | 0 | Carpeta vacía | **Legacy** — eliminar |
| **`bitacora`** | 0 | 0 | Carpeta vacía; la bitácora real vive en `visitas/` | **Legacy** — eliminar |

### Legacy transversal (no es un módulo, es deuda repartida)

| Elemento | Dónde | Por qué es legacy |
| --- | --- | --- |
| Tier `CM` / `GTE` / `FARMER` | `src/types/index.ts:16` y ~34 archivos | El propio código lo declara *"plumbing para módulos legacy"*. Convive con los 13 roles reales. Ver ADR-008. |
| `MiDiaMovilPreview` y `?midia` | `src/App.tsx:137,191` | Andamiaje para validar la PWA sin instalarla. Innecesario con layout adaptativo. |
| `if (isPWA)` distribuido | `src/App.tsx:454` y consumidores | Bifurca la aplicación entera. Ver ADR-007. |
| Drenaje de cola offline desde `App.tsx` | `src/App.tsx` (`useSincronizarBoletas`) | Parche global para que funcione "en cualquier pestaña". Ver ADR-009. |
| `IncentivosView` dentro de `SalasView` | `src/features/salas/SalasView.tsx:34,351,552` | Un feature montado dos veces dentro de otro. |

---

## 3. Alcance específico de la Fase 1

### Funcionalidades que entran

Autenticación y sesión · Resolución de capacidades · Bienvenida y perfil · **Mi Día** · Visitas con check-in, cronómetro, evidencia y cierre · Aviso de visita en curso · Borrador persistente · Lobbies y otros eventos · Tareas, avances, calificación y cierre · Agenda y días hábiles · Saludos de cumpleaños · Bitácora diaria con dictado y mejora de redacción · Gastos, boletas con lectura automática, categorización, asignación y rendiciones · Notificaciones al asesor · Modo offline con cola y sincronización observable · Layout adaptativo.

### Huella de datos — 33 de 128 tablas

| Grupo | Tablas |
| --- | --- |
| Identidad y permisos | `usuarios`, `roles`, `capacidades`, `usuario_roles`, `rol_capacidades`, `usuario_areas`, `asesores`, `areas` — **corrección v0.2:** faltaba `capacidades`, sin la cual `rol_capacidades` no tiene sentido. Las 6 capacidades sembradas son `facturacion`, `salas`, `midia`, `cobertura`, `unoauno`, `config`. En el sistema nuevo este grupo entero lo sustituyen los roles del JWT (ADR-011) |
| Terreno | `visitas`, `visitas_abiertas`, `visitas_en_curso`, `lobbies`, `agenda_eventos`, `saludos_cumpleanos`, `feriados` |
| Tareas y planes | `plan_tareas`, `tarea_avances`, `tarea_comentarios`, `planes_accion`, `proyectos`, `proyecto_operadores` |
| Bitácora | `bitacoras` |
| Gastos | `gastos`, `gasto_archivos`, `gasto_asignaciones`, `gasto_categorias`, `rendiciones`, `rendicion_eventos` |
| Notificaciones | `notificaciones` |
| Referencia (solo lectura) | `salas_catalogo`, `salas_asignacion`, `salas_zona`, `salas_geo`, `salas_grupo`, `sala_vendedores`, `vendedores`, `clientes` — **corrección v0.2:** la v0.1 listaba `salas`, que **el código no consulta ni una vez**. Ver §3.1 |

### 3.1 Trampas del esquema actual — leer antes de modelar la base nueva

> Añadido en la v0.2. Verificado sobre las 364 migraciones y contrastado con el uso real en el código del sistema actual. **Quien construya el modelo .NET debe leer esto primero:** el histórico de migraciones miente si se lee de arriba abajo.

**1. Tres tablas centrales fueron destruidas y recreadas con diseño distinto.** `visitas`, `bitacoras` y `sala_vendedores` tienen un `drop table ... cascade` y un segundo `CREATE`. Vale la **segunda** definición más sus `ALTER` posteriores. El caso de `visitas`:

| | v1 (`0001_esquema`) | v2 — la viva (`0043_visitas`) |
| --- | --- | --- |
| PK | `id uuid` | `id bigint generated always as identity` |
| Sala | `sala_id uuid` con FK a `salas` | `sala_key text`, sin FK |
| Asesor | `asesor_id uuid` con FK a `asesores` | `asesor_id text` |
| Campos | decálogo, minuta, ánimo | + `termometro`, `acuerdos_previos`, `nuevos_acuerdos`, `decalogo_nota`, `ventas` |

Más `check_in`, `check_out`, `lat`, `lng`, `fotos` (`0063`) y `cliente_uuid` (`0084`). Confirmado por el uso: `sala_key` aparece **270 veces** en el código, `termometro` 29, `cliente_uuid` 23.

**2. La tabla `salas` está abandonada.** El código ejecuta `.from('salas')` **cero veces**. El catálogo real es `salas_catalogo` (PK `sala_key text`), con `salas_asignacion` para saber qué asesor tiene qué sala, más `salas_zona`, `salas_geo` y `salas_grupo`. Hay 15 tablas `salas*` en total y `sala_key` aparece en 87 migraciones: **la identidad de una sala es `sala_key`, no un uuid.**

**3. El vendedor de sala se identifica por nombre.** `sala_vendedores` v2 usa `vendedor text` con el comentario *"nombre del vendedor (identidad SIGA)"*. De ahí que existan las funciones `vendedor_por_nombre` y `vendedor_inactivo_por_nombre`.

**4. Las claves están degradadas de forma sistemática.** No es un descuido aislado: `asesor_id text` comentado como *"uuid en texto; texto flexible"* en `visitas`, `lobbies`, `plan_tareas` y `saludos_cumpleanos`; `sala_key text` sin FK en todas ellas; y en `agenda_eventos` un `visita_id bigint` comentado como *"vínculo blando (visitas usa otro esquema de id)"*. La causa es no haber podido migrar datos. **Sin datos que conservar, esta deuda no se hereda:** el modelo nuevo lleva claves de un solo tipo y FKs reales.

**5. El orden de aplicación no es reconstruible solo por nombre.** Hay **15 números de migración duplicados** entre 364. Y no existe ningún dump consolidado del esquema en el repositorio.

**6. Chile está implícito.** `gastos.moneda` tiene `default 'CLP'`, y hay `rut_proveedor` en gastos y `rut` en vendedores sin contexto de país. El modelo nuevo lleva el país explícito desde el día uno, aunque la primera entrega opere solo Chile.

**Lo bueno.** El DDL es SQL plano y **bien comentado con la intención de negocio** —`campos_dudosos text[]` viene con *"Campos donde la IA dudó (confianza < 0.8) → se resaltan en el editor"*—, no hay tipos ni dominios propios, los estados son `text` con `CHECK (... in (...))` que se traducen directo a enums, y el acoplamiento a Supabase Auth es casi nulo: **2** referencias a `auth.users` en 364 migraciones y **cero** `default auth.uid()`.

---

### Edge Functions que consume — 6 de 46

`leer-boleta` · `transcribir-bitacora` · `mejorar-bitacora` · `mejorar-redaccion` · `notificar` · y los procesos programados `tareas-atrasadas-cron` y `visitas-abiertas-cron`.

**Corrección v0.2 (ADR-011): ya no se reutilizan.** Supabase se abandona, así que estas siete piezas hay que **rehacerlas como endpoints .NET**. Su código actual es la especificación, y `leer-boleta` —que lleva IA dentro— es la más cara. Es el mayor aumento de alcance del cambio de backend.

### Dependencias con módulos fuera de alcance

| Dependencia | Naturaleza | Cómo se resuelve en Fase 1 |
| --- | --- | --- |
| Visitas → **Salas** | Una visita es siempre a una sala | Lectura del catálogo. Sin capacidad de gestión (RF-24). |
| Saludos → **Vendedores de sala** | El cumpleaños es de un vendedor del concesionario | Lectura del catálogo y de la función `cumpleanos_vendedores`. |
| Tareas → **Salas / Planes de acción** | Una tarea puede originarse en una sala o en un plan | Se conserva el vínculo como referencia; la gestión de planes es Fase 3. ⚠️ **Misma advertencia que rendiciones:** asignar y calificar son del mandante, así que durante la transición el asesor solo verá las tareas que él mismo cree. |
| Gastos → **Proyectos** | Un gasto puede asignarse a un proyecto | Lectura del catálogo de proyectos. |
| Rendiciones → **GC / GO / AO** | La aprobación la ejecutan otros roles | ⚠️ **Corregido el 27-08-2026.** Esta fila decía «la aprobación sigue operándose en el sistema actual», y eso solo era cierto compartiendo la base de Supabase. Con bases separadas (ADR-011) una rendición creada en el sistema nuevo es **invisible** para el actual. Decisión: el flujo de aprobación se queda en su fase normal (la del CM) y **no se adelanta**; durante el desarrollo las transiciones se hacen directo en la base. Queda abierto qué pasa entre el corte y esa fase — ver `gastos.md` §6. |
| Asesor → **Facturación / Cobertura** | El asesor las consulta, pero no son trabajo de terreno | **Doble acceso temporal** al sistema actual hasta la Fase 2. |
| Todo → **Matriz de capacidades** | Compartida con el sistema actual | Ambos leen la misma matriz; sin divergencia posible. |

---

## 4. Problemas detectados en la arquitectura actual

Ordenados por impacto sobre la capacidad de evolucionar el sistema.

### 4.1 La vista consulta la base de datos — 443 casos

`443` de las `926` llamadas `.from()` / `.rpc()` están dentro de archivos `.tsx`. Los módulos más afectados: `visitas` (89), `config` (74), `postventa` (56), `vendedores` (41), `unoauno` (24), `salas` (24).

**Consecuencia.** No se puede cambiar una regla sin abrir la UI, ni probar una regla sin renderizar. Cada `useEffect` + `.from()` + `useState` es una implementación independiente del mismo patrón, con su propia forma de manejar carga, error y refresco. Es la causa raíz de casi todo lo demás.

### 4.2 No hay dónde poner el negocio

Sin capa de dominio ni de casos de uso, una regla se implementa donde se necesita — y cuando se necesita en dos sitios, se duplica. La divergencia entre `MiDiaMovil` y el dashboard es la manifestación visible; la invisible son las reglas que solo existen dentro de un `useEffect` y que nadie recuerda haber decidido.

### 4.3 `App.tsx` es un cuello de botella de 916 líneas

En un solo archivo: enrutamiento por `useState<Tab>`, consultas a `rol_capacidades` y `usuario_roles`, resolución de permisos con fallbacks, bifurcación web/PWA, drenaje de la cola offline de boletas, aviso global de visita en curso con su lógica de "Ver como", y modo inducción. Todo cambio estructural pasa por ahí.

### 4.4 Vendor lock-in sin frontera medible

`getSupabase()` en **152 archivos**. No existe un punto donde medir el acoplamiento, así que no se puede estimar el costo de cambiar de proveedor — que es precisamente la decisión que la Dirección de TI tiene pendiente.

### 4.5 Dos aplicaciones que deberían ser una

`MiDiaMovil` (972 líneas, 7 pantallas) y el dashboard (12 pestañas) comparten **un** componente. Cada funcionalidad del asesor se implementa y se corrige dos veces.

### 4.6 Sin router, sin caché, sin gestión de estado

La navegación es estado local: no hay URLs, ni historial, ni enlaces compartibles, ni carga bajo demanda genuina por pantalla. Cada componente refetchea por su cuenta, sin invalidación coordinada ni reintentos.

### 4.7 Dos sistemas de permisos conviviendo

El tier `CM/GTE/FARMER` y la matriz de capacidades deciden lo mismo en paralelo, produciendo expresiones como `usuario.rol === 'CM' || ve('postventa', false)` y fallbacks que nadie puede razonar completos.

### 4.8 Offline resuelto con parches distribuidos

Drenaje de cola montado en `App.tsx` para funcionar "en cualquier pestaña"; implementación propia de IndexedDB; borrador de visita coordinado a mano en tres capas desde dentro del componente. Cada pantalla que necesita operar sin señal reinventa el mecanismo.

### 4.9 Manejo de errores improvisado

No hay jerarquía de errores. Los fallos de Supabase llegan a la UI con su forma original y cada componente decide qué mostrar, con riesgo de exponer detalles internos.

### 4.10 Riesgos de seguridad a verificar

- **La clave anónima es pública por diseño y RLS es la única defensa.** Una política mal escrita en cualquiera de las 128 tablas expone el dato. El repositorio ya contiene una prueba (`rlsLaxa.test.ts`) que detecta políticas demasiado permisivas — señal de que el riesgo se conoce. **Este riesgo desaparece en el sistema nuevo** (ADR-011: no hay clave pública en el navegador), pero se convierte en otro: las ~150 reglas que RLS garantizaba hay que reescribirlas como código de servidor, y el repo de la API no tiene proyectos de test.
- **El modo demo se implementa como guard del cliente** (`demoGuard.ts` envolviendo el cliente de Supabase). Es una protección de frontend: debe estar respaldada por RLS, no depender de ella.
- **"Ver como" (impersonación)** cruza la frontera de identidad y hoy se maneja con guards distribuidos por la UI, con comentarios en el código que documentan incidencias ya ocurridas. Necesita ser una regla de dominio, no una defensa dispersa.
- **Inyección de prompt** ya está contemplada (`promptInjeccion.test.ts`), lo que confirma que las funciones de IA reciben texto del usuario. Debe conservarse y extenderse a la bitácora y a la lectura de boletas.
- **Cobertura de pruebas desbalanceada**: 65 archivos de prueba sobre 455 de código, concentrados en utilidades y no en flujos de negocio.

---

## 5. Qué se conserva, qué se reconstruye

| Categoría | Contenido |
| --- | --- |
| **Se conserva sin tocar** | Todo el sistema actual: esquema (128 tablas, 364 migraciones), políticas RLS, las 46 Edge Functions, los datos y su despliegue. **Se conserva porque no se toca, no porque se reutilice** — el sistema nuevo tiene su propia base y sus propios endpoints (ADR-011). Del stack solo continúa Sentry. |
| **Se reimplementa** | La capa de aplicación de los 7 módulos de Fase 1, extrayendo reglas del código actual sin copiarlo |
| **Se rediseña** | Navegación · Acceso a datos · Experiencia web/móvil · Detección de PWA · Manejo de errores · Soporte offline · Resolución de permisos |
| **Se elimina** | Tier legacy · Carpetas vacías `farmer/` y `bitacora/` · `MiDiaMovilPreview` y `?midia` · `if (isPWA)` distribuido · Las 443 queries en vistas · Drenaje de cola desde `App.tsx` |
| **No se migra** | Ningún dato, y ya no por compartir base sino porque **la base nueva arranca vacía**: borrón y cuenta nueva. Consecuencia que hay que resolver: los catálogos de referencia (salas, vendedores de sala, clientes) hay que **poblarlos**, porque una visita es siempre a una sala. |

---

## 6. Método y limitaciones de este inventario

**Cómo se levantó.** Análisis estático del repositorio local: conteo de archivos y líneas por módulo, búsqueda de patrones de acceso a datos (`.from(`, `.rpc(`), de suscripciones Realtime (`.channel(`, `postgres_changes`, `broadcast`) y de detección de PWA; lectura de `App.tsx`, `src/types/index.ts`, `src/lib/supabase.ts`, `src/lib/pwa.ts` y las migraciones de roles y capacidades; e inspección de `package.json` y del árbol de `supabase/`.

**Qué no cubre.**

- No se ejecutó el sistema ni se observó su uso real en producción. La clasificación por fases se basa en la matriz de capacidades y en el código, no en telemetría de uso.
- No se auditaron las 364 migraciones una por una: se leyeron las de roles y capacidades. El modelo de datos completo y sus políticas RLS son entregable del PRD hermano de análisis técnico (PJ3896).
- No se revisó el contenido de las 46 Edge Functions, solo su nombre y su relación con los módulos.
- Las cifras de líneas de código incluyen comentarios y son indicativas del tamaño relativo, no una métrica de esfuerzo.
- El uso real de Mi Día por parte de los 10 roles distintos del AF que tienen la capacidad `midia` está sin verificar — es una pregunta abierta del PRD y condiciona el alcance del corte.
