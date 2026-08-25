# Anexo A2 — Architecture Decision Records

> Complemento del PRD `manager/PRD.md` (Reconstrucción de GarantiMAX — Fase 1).
> Cada ADR sigue el formato exigido por el requerimiento: **decisión · problema · alternativas · motivo · consecuencias · costo de cambio futuro**.
> Versión v0.1 — 25-08-2026. Estado de todos: **propuesto**, pendiente de aprobación de TI.

| # | Decisión | Estado |
| --- | --- | --- |
| [ADR-001](#adr-001--arquitectura-por-features-con-capas-internas) | Arquitectura por features con capas internas | Propuesto |
| [ADR-002](#adr-002--se-conserva-supabase-encapsulado-tras-contratos) | Se conserva Supabase, encapsulado tras contratos | Propuesto |
| [ADR-003](#adr-003--repositorios-por-agregado-no-por-tabla) | Repositorios por agregado, no por tabla | Propuesto |
| [ADR-004](#adr-004--acceso-directo-frontendsupabase-con-lista-cerrada-de-excepciones) | Acceso directo frontend→Supabase con lista cerrada de excepciones | Propuesto |
| [ADR-005](#adr-005--realtime-contrato-definido-implementación-diferida) | Realtime: contrato definido, implementación diferida | Propuesto |
| [ADR-006](#adr-006--navegación-datos-y-estado-como-tres-responsabilidades-separadas) | Navegación, datos y estado como tres responsabilidades separadas | Propuesto |
| [ADR-007](#adr-007--layout-adaptativo-en-lugar-de-dos-aplicaciones) | Layout adaptativo en lugar de dos aplicaciones | Propuesto |
| [ADR-008](#adr-008--autorización-por-capacidades-eliminando-el-tier-legacy) | Autorización por capacidades, eliminando el tier legacy | Propuesto |
| [ADR-009](#adr-009--offline-como-decorador-de-repositorio-no-como-rama-en-la-ui) | Offline como decorador de repositorio, no como rama en la UI | Propuesto |
| [ADR-010](#adr-010--reconstrucción-con-corte-único) | Reconstrucción con corte único | Propuesto |

---

## ADR-001 — Arquitectura por features con capas internas

**Decisión.** Organizar el código por **feature de dominio** en el primer nivel (`visitas`, `tareas`, `agenda`, `bitacora`, `gastos`, `identidad`, `referencia`) y por **capa** dentro de cada uno (`domain`, `application`, `ports`, `infrastructure`, `ui`). Los features se nombran por capacidad de negocio, nunca por rol ni por pantalla.

**Problema.** El código actual se organiza por módulo de UI y mezcla todo dentro: `src/features/visitas/` tiene 70 archivos donde conviven componentes, queries, reglas y utilidades sin separación. No hay dónde poner una regla de negocio, así que termina en el componente. Y como los módulos se nombran por pantalla (`midia`, `warroom`), la estructura refleja la navegación y no el dominio.

**Alternativas consideradas.**
- **Por capas puras** (`domain/`, `application/`, `infrastructure/`, `ui/` en el primer nivel). Ordenado en teoría; en la práctica obliga a tocar cuatro carpetas lejanas para cualquier cambio y no escala: `domain/` acaba con 40 entidades sin agrupación.
- **Por features planos**, sin capas internas. Es lo que hay hoy. No resuelve el problema original.
- **Híbrido** (elegido).

**Motivo.** Este producto crece por capacidad de negocio: primero visitas, luego facturación, luego post-venta. La estructura debe hacer que agregar un módulo sea agregar una carpeta, no editar cuatro. Las capas internas garantizan la separación que el requerimiento exige, y el feature garantiza que el código relacionado esté junto.

**Consecuencias.** Cada feature tiene cinco subcarpetas, lo que se ve verboso para features pequeños — es el costo aceptado. Se necesita una regla de linter que impida que un feature importe la `ui/` o la `infrastructure/` de otro; sin ella, la estructura se degrada sola. El dominio compartido (`domain/`) requiere criterio: se promueve ahí solo lo que dos features ya necesitan, nunca por anticipación.

**Costo de cambio futuro.** Bajo. Reorganizar carpetas es mecánico si las capas están respetadas. El costo real sería cambiar el criterio de separación, no la disposición de archivos.

---

## ADR-002 — Se conserva Supabase, encapsulado tras contratos

**Decisión.** Mantener Supabase como proveedor de datos, autenticación y almacenamiento, con su SDK confinado exclusivamente a la capa de infraestructura. El dominio y los casos de uso no conocen su existencia.

**Problema.** Supabase está hoy en **152 archivos** y **926 llamadas**. No hay forma de estimar qué costaría reemplazarlo porque no existe una frontera que medir. Al mismo tiempo, hay una decisión pendiente sobre migrar al estándar corporativo .NET 8 que este proyecto no puede ni debe resolver.

**Alternativas consideradas.**
- **Migrar ahora al estándar corporativo.** Convierte el proyecto en una re-plataforma completa, con backend nuevo, autenticación nueva y las 46 Edge Functions por portar. Multiplica el alcance y el riesgo, y decide algo que corresponde al análisis técnico en curso.
- **Seguir con Supabase sin abstraer.** Es lo actual. Barato hoy, imposible de revertir mañana.
- **Encapsular** (elegido).

**Motivo.** La encapsulación convierte una decisión irreversible en una reversible. Permite avanzar hoy sin comprometer el futuro, y —lo más valioso a corto plazo— hace que el negocio sea probable sin red. El requerimiento lo dice sin ambigüedad: *"Supabase puede ser reemplazado"*. Eso no significa reemplazarlo ahora.

**Consecuencias.** Aparece una capa de mapeo entre filas y entidades que hoy no existe: más código y algo de indirección. A cambio, cambiar de proveedor pasa de "reescribir la aplicación" a "reescribir diez implementaciones de repositorio". Advertencia importante: **RLS no es portable**. Si Supabase se sustituye, la autorización hay que reconstruirla en la nueva plataforma; la abstracción no protege de eso.

**Costo de cambio futuro.** Medio. Diez implementaciones de repositorio y cuatro providers. La parte cara no es el código de acceso a datos sino RLS y las Edge Functions (ver ADR-004 y la matriz de lock-in en A1 §13).

---

## ADR-003 — Repositorios por agregado, no por tabla

**Decisión.** Definir un repositorio por **agregado del dominio**, no por tabla de base de datos. `VisitaRepository` gestiona `visitas`, `visitas_abiertas` y `visitas_en_curso`. La interfaz habla en lenguaje de negocio.

**Problema.** El esquema actual tiene 128 tablas, muchas de ellas fragmentos de un mismo concepto por razones de rendimiento o histórico. Un repositorio por tabla trasladaría esa fragmentación al dominio, que es justamente lo que hay que evitar: el dominio no debe saber que una visita en curso vive en otra tabla que una visita cerrada.

**Alternativas consideradas.**
- **Un repositorio por tabla.** Mecánico y fácil de generar, pero filtra el diseño de la base al negocio y produce casos de uso que orquestan tres repositorios para una sola operación.
- **Un repositorio genérico** con operaciones CRUD parametrizadas. Ahorra código y no aporta nada: es el SDK de Supabase con otro nombre, sin lenguaje de dominio y sin posibilidad de expresar invariantes.
- **Por agregado** (elegido).

**Motivo.** El repositorio existe para que el dominio hable su propio idioma. `obtenerVisitaEnCursoDe(asesor)` es una pregunta del negocio; `selectFromVisitasEnCursoWhereUsuarioId` es un detalle de persistencia. Además permite que el esquema evolucione —fusionar dos tablas, por ejemplo— sin tocar nada fuera de la implementación.

**Consecuencias.** Requiere decidir dónde están las fronteras de agregado, que es un ejercicio de diseño real y no mecánico. Algunas implementaciones serán más complejas que un `select`. A cambio, los casos de uso quedan legibles y el esquema deja de dictar el diseño.

**Costo de cambio futuro.** Bajo. Redefinir una frontera de agregado afecta a una implementación y a la interfaz que la declara.

---

## ADR-004 — Acceso directo frontend→Supabase con lista cerrada de excepciones

**Decisión.** Conservar el acceso directo desde el cliente a Supabase, protegido por RLS, para lecturas y escrituras del asesor sobre sus propios datos. Definir una **lista cerrada** de operaciones que obligatoriamente pasan por función de servidor. No construir un backend intermedio.

**Problema.** Hoy **todo** va directo con la clave anónima. Eso es correcto para los datos del propio asesor —RLS lo protege— pero deja la pregunta abierta de qué operaciones no deberían ir así, y el requerimiento exige responderla explícitamente.

**Alternativas consideradas.**
- **BFF / backend propio para todo el acceso.** Máxima seguridad y máximo desacople del proveedor. Pero es construir una pieza que hoy no existe, con su despliegue, su autenticación, su observabilidad y su mantenimiento — multiplicando el alcance de una Fase 1 que ya es grande. Y no elimina RLS: se necesitaría igual como defensa en profundidad.
- **Todo directo, sin excepciones.** Es lo actual, y ya se viola en la práctica: `leer-boleta` y `mejorar-bitacora` existen precisamente porque hay operaciones que no pueden ir en el cliente.
- **Directo + lista cerrada de excepciones** (elegido).

**Motivo.** El criterio no es la conveniencia sino el riesgo. Cuatro condiciones obligan al servidor: (1) usar credenciales de un proveedor externo, (2) escribir algo que cruce la frontera del propio usuario, (3) escrituras masivas o procesos programados, (4) reglas de autorización que RLS no puede expresar. Todo lo demás es el asesor operando sobre lo suyo, y RLS lo cubre. Formalizar esas cuatro condiciones convierte una práctica implícita en una regla auditable.

**Consecuencias.** La seguridad del sistema **depende íntegramente de que RLS esté bien escrita** en las 26 tablas de Fase 1. La clave anónima es pública por diseño: una política mal escrita expone el dato a cualquiera. Por eso la auditoría de RLS es criterio de aceptación (A1 §15) y no una tarea opcional. Contrapartida positiva: no se construye ni se mantiene un backend, y el rendimiento no paga un salto de red adicional.

**Costo de cambio futuro.** Medio-alto si se decide introducir un BFF más adelante — hay que reimplementar los repositorios contra el nuevo backend. Pero **solo los repositorios**: el dominio, los casos de uso y la UI no se enteran. Esa es exactamente la propiedad que ADR-002 compra.

---

## ADR-005 — Realtime: contrato definido, implementación diferida

**Decisión.** Definir el contrato `RealtimeProvider` como decisión arquitectónica documentada, y **no implementarlo en Fase 1**.

**Problema.** El requerimiento pide tratar Realtime como capacidad independiente de la base de datos y abstraerlo. Pero también prohíbe las abstracciones prematuras. Ambas cosas son ciertas y hay que resolver la tensión con datos.

Los datos: Realtime aparece en **9 archivos** —War Room, Post-Venta y Call Center—. **Ningún módulo del asesor lo usa.** Lo que en Mi Día parece "en vivo" es refetch al recuperar el foco.

**Alternativas consideradas.**
- **Implementar el provider en Fase 1.** Construir contrato e implementación Supabase para que Fase 2 los encuentre listos. Sería código sin un solo consumidor, imposible de validar contra un caso real y probablemente mal dimensionado — el requerimiento lo prohíbe explícitamente.
- **Ignorar Realtime por completo.** Deja al primer módulo que lo necesite improvisando, y reproduce el acoplamiento actual.
- **Contrato sí, implementación no** (elegido).

**Motivo.** Es la aplicación literal de *"considerar no significa implementar"*. Documentar el contrato tiene valor real hoy: fija la regla de que la UI nunca conocerá `postgres_changes` ni `.channel()`, y deja registrado el mapa de qué módulos lo necesitan y por qué. Implementarlo no tendría ninguno.

**Consecuencias.** El primer módulo que necesite Realtime —previsiblemente War Room— paga el costo de construir la implementación. Ese costo es menor que el de mantener una abstracción especulativa durante meses. Riesgo real: que el contrato definido hoy, sin consumidor, resulte inadecuado cuando llegue el primero; se acepta explícitamente y el contrato se revisará entonces.

**Costo de cambio futuro.** Bajo. No hay implementación que reemplazar. Si el contrato resulta equivocado, se rehace antes de tener consumidores.

---

## ADR-006 — Navegación, datos y estado como tres responsabilidades separadas

**Decisión.** Separar explícitamente tres responsabilidades que hoy están fundidas en `useState`:

| Responsabilidad | Herramienta | Alcance |
| --- | --- | --- |
| Navegación | **React Router** | Rutas, historial, URLs compartibles, carga bajo demanda por ruta |
| Datos de servidor | **TanStack Query** | Caché, deduplicación, invalidación, reintentos, refetch al recuperar foco |
| Estado de UI transversal | **Zustand**, solo donde el estado cruce ramas del árbol | Cola de sincronización, aviso de visita en curso, preferencias de vista |
| Estado de UI local | `useState` / `useReducer` | Modales, campos, pestañas |

**Problema.** El proyecto **no tiene router, ni librería de estado, ni capa de datos**. La navegación es `useState<Tab>` dentro de `App.tsx` —sin URL, sin historial, sin enlaces compartibles—. Cada componente hace su propio `useEffect` + `.from()` + `useState`, sin caché, sin invalidación y sin reintentos. Eso explica tanto las 916 líneas de `App.tsx` como las 443 queries dentro de vistas: no había dónde ponerlas.

**Alternativas consideradas.**
- **Seguir sin librerías**, resolviendo todo con hooks propios. Es reimplementar a mano lo que estas herramientas ya resuelven, con menos garantías. El resultado actual es la evidencia.
- **Un único store global** (Redux o equivalente) para todo. Trata los datos de servidor como estado del cliente, que es la confusión de origen: obliga a escribir a mano sincronización, invalidación y caducidad.
- **Tres responsabilidades, tres herramientas** (elegido).

**Motivo.** Son problemas distintos con soluciones maduras y distintas. Los datos de servidor no son estado del cliente: son una **caché** de algo que vive en otro lado, con caducidad, revalidación y reintentos. Tratarlos como estado local es la raíz del problema actual. Se nombran las librerías en el PRD, como se acordó, para que la decisión no quede abierta a interpretación en implementación.

**Regla que evita que TanStack Query rompa la arquitectura:** la función que se le pasa **siempre invoca un caso de uso**, nunca un repositorio ni el SDK. La caché es un detalle de presentación; la operación es de aplicación. Sin esta regla, TanStack Query se convierte en la nueva forma de meter queries en las vistas.

**Consecuencias.** Tres dependencias nuevas, todas ampliamente adoptadas y estables. Se gana navegación real, con URLs que el asesor puede compartir y carga bajo demanda genuina por ruta. Zustand se usa con parsimonia: si algo puede ser local, es local — no es un store global por defecto.

**Costo de cambio futuro.** Bajo para el router y el estado. Medio para la capa de datos, porque el patrón de consumo permea los hooks de UI — pero no llega a la aplicación ni al dominio.

---

## ADR-007 — Layout adaptativo en lugar de dos aplicaciones

**Decisión.** Adoptar la **alternativa C** del requerimiento: una sola aplicación cuya presentación se adapta a escritorio y móvil. La detección de contexto —tamaño, instalación como PWA, capacidades del dispositivo, conexión— se centraliza en un único proveedor.

**Problema.** Hoy hay dos aplicaciones. `App.tsx:454` bifurca: si detecta PWA instalada monta `MiDiaMovil` (972 líneas, 7 pantallas propias); si no, monta el dashboard de 12 pestañas. Comparten exactamente **un** componente (`GastosView`). Cada funcionalidad del asesor se implementa dos veces, se corrige dos veces y diverge según cómo entró el usuario.

**Alternativas consideradas.**
- **A — `WebLayout` + `AppLayout` separados**, ambos sobre los mismos casos de uso. Formaliza lo existente y es honesto respecto a que escritorio y terreno son contextos distintos. Pero conserva dos árboles de UI que hay que mantener en paralelo, que es el costo actual.
- **B — Experiencia app-like única.** Máxima consistencia, pero castiga el uso en escritorio: Facturación, Salas y Cobertura son densos en datos y una navegación móvil los degrada. (Menos crítico en Fase 1, decisivo en Fase 2.)
- **C — Layout adaptativo** (elegido).

**Motivo.** La diferencia entre el asesor en su escritorio y el asesor en la sala es de **presentación y navegación**, no de aplicación: las mismas visitas, las mismas tareas, las mismas reglas. `GastosView` ya demuestra que un componente puede servir a ambos contextos. La alternativa A conservaría el problema con mejor nombre; la B sacrificaría el escritorio que Fase 2 va a necesitar.

**Consecuencias.** Los componentes deben diseñarse desde el principio para ambos contextos, lo que exige más disciplina en el sistema de componentes que escribir dos versiones. Se necesita una regla de linter que prohíba `matchMedia` y `navigator.standalone` fuera del provider; sin ella, el `if (isPWA)` vuelve. La migración de `MiDiaMovil` no es una copia: hay que decidir, pantalla por pantalla, cuál es su equivalente adaptativo.

**Costo de cambio futuro.** Medio. Volver a dos layouts sería extraer presentación, sin tocar casos de uso ni dominio. La decisión es reversible precisamente porque la lógica no vive en el layout.

---

## ADR-008 — Autorización por capacidades, eliminando el tier legacy

**Decisión.** El sistema nuevo resuelve permisos **exclusivamente** contra la matriz `roles × capacidades`. El tier `CM/GTE/FARMER` se ignora por completo. La resolución ocurre una vez, en un punto central, y la UI recibe una decisión ya tomada.

**Problema.** Conviven dos sistemas. El actual —13 roles reales en `usuarios.rol_principal`, roles funcionales en `usuario_roles`, capacidades en `rol_capacidades`— y el anterior de tres niveles, que el propio código documenta como *"plumbing para módulos legacy"*. El resultado es que `App.tsx` contiene expresiones como `usuario.rol === 'CM' || ve('postventa', false)`: dos sistemas decidiendo lo mismo, con fallbacks que nadie puede razonar completos.

**Alternativas consideradas.**
- **Conservar ambos** para compatibilidad con el sistema actual. Traslada la deuda exacta que el requerimiento pide no trasladar.
- **Eliminar el tier también del sistema actual.** Correcto a largo plazo, pero obliga a tocar módulos fuera de alcance mientras están en producción para otros roles.
- **El sistema nuevo lo ignora; la eliminación en el actual se difiere** (elegido).

**Motivo.** El tier es plumbing declarado, no un concepto de negocio. La matriz de capacidades ya es la fuente de verdad en base de datos y RLS ya la usa (`puede()`, `app_rol()`). No hay razón para que el sistema nuevo nazca conociendo el sistema viejo. Y como ambos leen la misma matriz, no hay riesgo de divergencia durante la convivencia.

**Consecuencias.** Desaparecen los fallbacks del tipo `ve('config', puedeImportar(usuario))`: si la matriz no carga, es un error de infraestructura, no una excusa para adivinar permisos. Requiere verificar que las capacidades del AF en la matriz (`facturacion`, `salas`, `midia`, `cobertura`, `datos:operativo`) sean completas y correctas antes del corte. La columna `usuarios.rol` sigue existiendo en la base para el sistema actual; el nuevo simplemente no la lee.

**Costo de cambio futuro.** Bajo. Es eliminar código, no agregarlo. La limpieza definitiva del tier ocurre cuando el sistema actual se apague.

---

## ADR-009 — Offline como decorador de repositorio, no como rama en la UI

**Decisión.** El soporte offline se implementa como un **decorador sobre el repositorio**: si no hay conexión, la operación se encola localmente con identificador de idempotencia y se drena al reconectar. La decisión de encolar pertenece a la capa de aplicación; la UI solo refleja el estado.

**Problema.** Hoy el offline es un conjunto de parches distribuidos: `useSincronizarBoletas` se monta en `App.tsx` para drenar la cola "en cualquier pestaña", `idbStore.ts` es una implementación propia de IndexedDB, y el borrador de visita se guarda en tres capas (servidor, local y marca de visita abierta) con la coordinación escrita a mano dentro del componente. Cada pantalla que necesita funcionar sin señal reinventa el mecanismo.

**Alternativas consideradas.**
- **Rama `if (online)` dentro de cada caso de uso.** Duplica la decisión en cada operación y hace que los casos de uso conozcan el estado de la red, que es infraestructura.
- **Sincronización a nivel de service worker**, interceptando peticiones. Transparente para la aplicación, pero opaco para el usuario: no permite mostrar qué está pendiente ni reintentar manualmente, y las operaciones con imágenes se vuelven difíciles de razonar.
- **Decorador de repositorio** (elegido).

**Motivo.** El offline es una característica de la **persistencia**, no del negocio ni de la pantalla. Un decorador lo expresa exactamente: la misma interfaz, otro comportamiento cuando no hay red. El caso de uso pide guardar; qué ocurre si no hay señal es responsabilidad de quien guarda. Y como el decorador está en infraestructura, se prueba sin navegador.

**Consecuencias.** Cada operación encolable necesita un identificador de idempotencia — es la única forma de garantizar RNF-09 (no duplicar al reintentar). El estado de la cola debe ser observable por el asesor (RNF-21), lo que exige exponerlo como estado transversal. Hay que decidir explícitamente qué operaciones son encolables y cuáles exigen conexión: iniciar sesión no se encola; registrar un avance de tarea sí. Y la política de reintentos —espera creciente hasta un tope, luego acción manual— debe ser única para toda la aplicación.

**Costo de cambio futuro.** Bajo. Cambiar la estrategia de sincronización afecta al decorador y a su almacenamiento local, no a los casos de uso ni a la UI.

---

## ADR-010 — Reconstrucción con corte único

**Decisión.** Construir la aplicación nueva completa para el alcance de Fase 1 y migrar a los asesores en un **corte único**, con doble acceso temporal al sistema actual para los módulos que la Fase 1 no cubre (Facturación, Salas, Cobertura).

**Problema.** Hay que llevar a los asesores del sistema actual al nuevo sin interrumpir su trabajo de terreno, y sin afectar a los demás roles, que siguen operando en el sistema actual.

**Alternativas consideradas.**
- **Strangler — migrar módulo por módulo.** La aplicación nueva convive con la actual y absorbe módulos progresivamente. Entrega valor antes y permite revertir por módulo, pero exige mantener dos códigos vivos durante meses, con el riesgo de que la convivencia se vuelva permanente.
- **Refactor in-place** del repositorio actual. Un solo código, sin duplicación, más barato en esfuerzo total. Pero arrastra la estructura y las convenciones actuales, y separar el trabajo del asesor obliga a tocar módulos fuera de alcance — `IncentivosView` incrustado dentro de `SalasView` es el ejemplo. En un repositorio con 443 queries en vistas, el refactor tiende a quedarse a medio camino.
- **Corte único** (elegido).

**Motivo.** Es la opción que garantiza que la arquitectura objetivo se cumpla sin concesiones: no hay compatibilidad hacia atrás que respetar ni tentación de heredar. Decisión tomada por el responsable del proyecto con conocimiento explícito de que concentra el riesgo.

**Consecuencias.** Es la decisión de mayor exposición del proyecto y se acepta como tal. Durante la construcción no hay entrega visible al usuario, lo que retrasa la retroalimentación. El día del corte, todos los asesores cambian a la vez y en terreno. Las mitigaciones no son opcionales sino criterios de aceptación:

1. Lista de paridad funcional verificada y firmada antes del corte (RF-25).
2. Procedimiento de reversión probado, ejecutable dentro de la misma jornada (RNF-21).
3. Piloto con un grupo reducido de asesores antes del corte general.
4. Corte programado en un día de baja actividad.
5. Validaciones periódicas con asesores reales durante la construcción, sin esperar al corte.

El doble acceso temporal a Facturación, Salas y Cobertura se declara **con fecha de vencimiento**, y su cierre es criterio de aceptación de la Fase 2 — para que la convivencia no se normalice.

**Costo de cambio futuro.** Alto una vez ejecutado el corte: volver atrás significa la reversión de emergencia, no un cambio de estrategia. Por eso el procedimiento de reversión se prueba antes, no se improvisa después. Antes del corte la decisión sí es reversible: si durante la construcción aparece evidencia de que el riesgo es inasumible, todavía se puede pasar a un corte escalonado por país o por grupo de asesores.
