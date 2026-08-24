# 00 · Metodología y criterio de evidencia

| Campo | Detalle |
|---|---|
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | Cerrado (T-04, Fase 0) |

> Este documento se publica **antes** de producir cualquier hallazgo o dictamen, siguiendo el mismo principio que el árbol de decisión del PRD (§7.3): fijar el criterio antes de conocer el resultado, para que la conclusión no se acomode al criterio. No se modifica una vez que Fase 1 arranca — cualquier ajuste necesario se documenta como excepción fechada al final de este archivo, nunca por edición silenciosa.

---

## 1. Principio rector

**Nada se afirma sin evidencia** (PRD, principio rector del MVP). Toda afirmación de este análisis pertenece a una de tres categorías, marcadas explícitamente en el texto:

| Marca | Significado | Ejemplo |
|---|---|---|
| **Hecho** | Verificable por un tercero con el mismo acceso, con fuente citada | "El módulo `averias` tiene 41 archivos `.tsx` (`src/features/averias/`)." |
| **Inferido** | Derivado de una fuente indirecta legítima pero no autoritativa — típicamente el historial de migraciones en vez del catálogo real de Supabase | "La tabla `av_casos` existe (inferido de `supabase/migrations/`); pendiente de confirmar contra el catálogo real en Etapa B (T-31)." |
| **Supuesto / Opinión** | Juicio de valor o hipótesis no verificable con los accesos actuales | "Se supone que el volumen de `av_casos` es bajo, dado el tamaño de la operación; sin acceso a la base, no se puede confirmar." |

Un hallazgo o cifra sin una de estas tres marcas explícitas o implícitas por contexto **no está listo para publicarse**.

---

## 2. Formato de cita de evidencia (RF-23, RNF-02)

Cada afirmación técnica cita su fuente en una de estas formas:

- **Código:** `archivo:línea` — ej. `src/features/warroom/visitasRealtime.ts:29`
- **Base de datos** *(solo Etapa B)*: la consulta exacta corrida, o su resumen si es larga, más la fecha en que se corrió
- **Configuración:** el archivo de config y la clave — ej. `vite.config.ts`, clave `manualChunks`
- **Migración:** número y nombre del archivo — ej. `supabase/migrations/0350_estado_sin_ingreso.sql`
- **Interlocutor:** nombre, fecha de la conversación y una síntesis de lo dicho — nunca una cita textual sin confirmación de la persona
- **Documento previo:** ruta del documento en `docs/` del repositorio, con la advertencia de que es insumo a verificar, no verdad asentada (ver §7)

Cualquier afirmación sin una de estas fuentes se marca **Supuesto** o se traslada a `preguntas-abiertas.md`.

---

## 3. Escala de severidad (RNF-09)

Aplica a todo hallazgo de `hallazgos.md`, sea de seguridad, rendimiento, testing u observabilidad.

| Severidad | Criterio |
|---|---|
| **Crítico** | Explotable o con impacto inmediato en datos de negocio o datos personales; o bloquea por completo un escenario de migración si no se resuelve antes. Ej.: tabla con datos personales sin RLS. |
| **Alto** | Impacto significativo pero no inmediato, o que exige trabajo no trivial para mitigar. Ej.: lógica de negocio crítica sin ningún test. |
| **Medio** | Deuda técnica con impacto acotado o mitigable con esfuerzo moderado. Ej.: componente de más de 500 líneas sin descomponer. |
| **Bajo** | Mejora deseable sin impacto operativo apreciable. Ej.: nomenclatura inconsistente entre módulos. |

El criterio de asignación es la combinación de **probabilidad de que ocurra o ya esté ocurriendo** y **daño si ocurre** — nunca solo uno de los dos. Un hallazgo de probabilidad baja pero daño catastrófico (ej. una RPC `security definer` sin control de permisos) se clasifica **Alto** o **Crítico**, no **Bajo**.

**Vulnerabilidad activa detectada durante la auditoría → protocolo de escalamiento inmediato** (no esperar al cierre de fase ni al documento final):
1. Detener la exploración de esa vulnerabilidad puntual en cuanto se confirma que es explotable (no profundizar más de lo necesario para describirla).
2. Notificar a Javier Oropeza y, a través de él, a Aldo Álvarez, el mismo día.
3. Registrar el hallazgo en `hallazgos.md` con severidad **Crítico** y la fecha de escalamiento.
4. No publicar el detalle explotable en ningún canal abierto; el documento final la describe en términos de impacto y remediación, no como guía de explotación.

---

## 4. Separación entre hecho y opinión (RNF-07)

Cada capítulo de `analisis/` se estructura en dos bloques diferenciados quando aplica:

- **Inventario** — lo observado, sin juicio. "El módulo `mora` tiene 3 pantallas y toca 4 tablas."
- **Evaluación** — lo juzgado, con su razón. "La lógica de cálculo de mora vive en el front (`src/features/mora/calculo.ts`), lo cual es un riesgo de integridad porque permite manipular el resultado antes de guardarlo — RECOMENDACIÓN: mover a RPC o Edge Function."

Un desacuerdo de criterio sobre la evaluación no debe invalidar el inventario: por eso viven separados.

---

## 5. Criterio de cobertura declarada (RNF-11)

Cada capítulo cierra con una línea de **cobertura**: qué fracción del universo correspondiente se revisó y qué quedó fuera, con su causa. Formato:

> **Cobertura:** 24/24 módulos con ficha completa. 0 módulos sin alcanzar.

o, si hay huecos:

> **Cobertura:** 40/46 Edge Functions con detalle completo; 6 pendientes de profundizar por ventana de tiempo — ver lista en `preguntas-abiertas.md`.

Nunca se declara "análisis exhaustivo" sin esta línea explícita. La ausencia de la línea de cobertura se trata como un defecto del capítulo, no como cobertura implícita del 100%.

---

## 6. Tratamiento de datos personales (RNF-04) y de secretos (RNF-03)

- **Ningún ejemplo, captura o cita reproduce datos personales reales** (nombres de clientes, RUT, teléfonos, direcciones) — se sustituyen por marcadores (`[nombre]`, `[RUT]`) o por datos de prueba evidentes.
- **Ninguna llave, token, cadena de conexión o secreto se transcribe**, ni siquiera parcialmente ni ofuscado — se referencia por **nombre de la variable de entorno y dónde vive** (ej. "la Edge Function `wa-enviar` requiere el secreto `TWILIO_AUTH_TOKEN`, definido en las variables de entorno de la función").
- Los archivos en `analisis/inventarios/` se revisan contra esta regla antes de cada commit, con el mismo rigor que los capítulos narrativos — un CSV de exportación es tan publicable como un párrafo.

---

## 7. Tratamiento de la documentación previa en `docs/`

El repositorio analizado ya contiene documentación (`docs/auditoria-2026-06-21/`, `docs/auditoria-2026-07-11/`, `docs/averias-v6/`, entre otra). Se usa como **insumo de arranque, nunca como verdad asentada** (PRD, supuestos): cualquier afirmación que provenga de ahí se re-verifica contra el código o la base antes de citarse en este análisis, y se marca su origen si se usa como pista.

---

## 8. Excepciones a este documento

*(vacío al cierre de T-04 — cualquier ajuste posterior a este método se registra aquí con fecha y justificación, nunca por edición silenciosa de las secciones anteriores)*
