# 10 · Anatomía de la PWA y del offline

| Campo | Detalle |
|---|---|
| Capítulo | C9 |
| Requerimiento(s) | RF-11 |
| Etapa | A — T-15 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Todo lo descrito es **Hecho** — leído de `vite.config.ts`, `src/lib/idbStore.ts`, `src/features/visitas/{useColaVisitas,visitaOffline,miDiaCache,bitacoraTerreno}.ts` y `src/App.tsx` (commit `3771e7f`).

---

## 1. Distinción central que el PRD exige documentar: "PWA" y "offline de datos" son dos mecanismos distintos

**Confirmado con el propio comentario del código** (`vite.config.ts`, en la configuración de `VitePWA`): *"PWA: app instalable (ícono en el inicio) + caché de la app para abrir sin conexión. El offline de DATOS (guardar visitas) es fase aparte."*

| Mecanismo | Qué resuelve | Tecnología | Dónde vive |
|---|---|---|---|
| **PWA (instalabilidad + shell offline)** | Que la app se instale como ícono y abra sin conexión (el *shell*: HTML/CSS/JS ya cacheados) | `vite-plugin-pwa` (Workbox), `registerType: 'autoUpdate'` | `vite.config.ts` |
| **Offline de datos** | Que una visita se pueda registrar sin señal y se suba cuando vuelva | IndexedDB **hecho a mano, sin dependencias** (`idbStore.ts`) + cola de sincronización | `src/lib/idbStore.ts`, `src/features/visitas/*` |

Son capas independientes: se podría tener la PWA instalable sin el offline de datos, o viceversa. El sistema tiene ambas, pero conviene no tratarlas como una sola pieza al estimar el costo de reponerlas (C17/T-25).

---

## 2. Configuración de la PWA (`vite.config.ts`)

- **Manifest:** nombre "GarantiMAX", `display: 'standalone'`, `orientation: 'portrait'`, tema oscuro (`#090D12`), 3 tamaños de ícono (incluido `maskable`).
- **`registerType: 'autoUpdate'`** — el service worker se actualiza solo, sin pedirle al usuario que recargue manualmente.
- **`navigateFallbackDenylist: [/^\/tv(\/|$)/]`** — hallazgo específico y documentado en el propio código: **el War Room público (`/tv`) está explícitamente excluido del caché del service worker**, "para que el kiosko siempre tome el build más nuevo tras un deploy" (evita mostrar un shell viejo en una pantalla 24/7 que nadie recarga a mano). Es una decisión de diseño correcta y no obvia — confirma que `/tv` es tratado como un caso especial en toda la arquitectura (visto también en C2/C8: vive dentro de `warroom`, con su propio canal Realtime).
- **`globIgnores`** — deliberadamente **no** precachea los chunks pesados de escritorio: `xlsx-*`, los generadores de PPTX de Facturación y Salas, el motor de logos (~262 KB gzip), `recharts-*`, `WelcomeScreen-*`. Mantiene la instalación del celular liviana; esos chunks se cargan de la red solo si se usan (y en el celular, en la práctica, no se usan). **Evidencia de que el equipo ya pensó el costo de peso de instalación como variable de diseño**, no algo que se descubrió después.
- **`manualChunks`** (confirma la regla que `CLAUDE.md` documenta como crítica): Recharts y sus dependencias de gráficos van a un chunk único (`recharts`); React/ReactDOM a su propio chunk (`react-vendor`) — separados explícitamente porque, si no, el bundler mete React dentro del chunk de Recharts (por ser su dependencia) y **cada carga inicial de la app terminaría descargando los ~112 KB gzip de Recharts completos**, incluso en el celular de un asesor que nunca abre un gráfico. El comentario del código es explícito: **"NO parte recharts"** — confirma textualmente la advertencia de `CLAUDE.md` sobre esta regla.

---

## 3. Offline de datos — mecanismo real

- **`src/lib/idbStore.ts`**: almacén clave-valor mínimo sobre IndexedDB, **sin ninguna dependencia externa** (ni Dexie, ni idb-keyval) — decisión deliberada según su propio comentario: "un solo object store genérico alcanza para ambos casos". Dos object stores: `kv` (snapshot de "Mi día" para abrir sin señal) y `cola-visitas` (cola con clave autoincremental, para fotos como blobs — "localStorage no soporta blobs", motivo explícito de usar IndexedDB y no algo más simple).
- **`useColaVisitas.ts`**: hook que expone pendientes/sincronizando/error a la UI. **Patrón de sincronización:** auto-sincroniza al montar el componente y **cada vez que vuelve la señal** (usa `useOnline()` de `src/lib/pwa`) — no depende de que el usuario dispare la sincronización a mano, aunque también ofrece un botón manual.
- **`visitaOffline.ts`** (funciones `contarCola`/`sincronizarCola`, consumidas por el hook anterior): resuelve el detalle de subir cada visita en cola, reportando cuántas se subieron (`ok`), cuántas fallaron (`fail`) y el último error.
- **`miDiaCache.ts`**: snapshot de la agenda del día en el store `kv`, para que "Mi Día" abra instantáneo incluso sin conexión al arrancar.
- **`bitacoraTerreno.ts`** (dentro de `visitas`, no de un módulo `bitacora` — ver el hallazgo de C2/T-07 sobre el módulo `bitacora` vacío): la bitácora diaria del asesor de terreno, con su propio ciclo de guardado.

---

## 4. Grado de acoplamiento con el sistema web (lo que RF-11 pide cuantificar)

**Es el mismo bundle, la misma build, el mismo árbol de React** — no hay una app separada. La evidencia es directa en `src/App.tsx`:

```ts
const standalone = usePwaStandalone()
// ...
if ((standalone || forzarMiDia) && !verDashboard) {
  return <MiDiaMovil ... />
}
```

Cuando la app detecta que corre en modo `standalone` (instalada como PWA) — o se fuerza con `?midia` para probar sin instalar — renderiza `MiDiaMovil` en lugar del dashboard de escritorio. **Es un `if` dentro del mismo componente raíz**, no una aplicación distinta desplegada aparte. `MiDiaMovil` y su vista previa (`MiDiaMovilPreview`) se cargan de forma perezosa (`lazyRecarga`) para no pesar en el dashboard de escritorio, pero viven en el mismo repositorio, el mismo módulo `visitas`, y comparten `AuthProvider`, `getSupabase()` y todos los hooks de datos con el resto del sistema.

**Qué costaría desacoplarla (evaluación, no hecho):** extraerla a un proyecto separado (opción de C17) no es "mover una carpeta" — implicaría separar `visitas` (70 archivos, el módulo con más dependencias salientes del sistema, C2/T-07: depende de `auth`, `config`, `induccion`, `resumen`, `salas`, `solicitudes`, `vendedores`, `warroom`) de su árbol de dependencias actual, más `idbStore.ts`, más re-implementar el bootstrapping de autenticación de forma independiente. **Esfuerzo alto**, no por la tecnología PWA en sí, sino por la centralidad de `visitas` en el grafo de módulos.

---

## 5. Cobertura declarada (RNF-11)

**100% de los mecanismos de PWA y offline identificados y documentados** con evidencia de código: configuración del manifest y el service worker, la estrategia de `manualChunks` (confirmando la advertencia de `CLAUDE.md`), el mecanismo de cola offline completo (IndexedDB → sincronización → reintento), y el punto exacto de acoplamiento con el resto de la app (`App.tsx`). **No se ejecutó la PWA en un dispositivo real** para verificar el comportamiento offline en la práctica (fuera de alcance de un análisis estático de código, RNF-01) — la descripción es de lo que el código implementa, no de una prueba de campo. Los datos de uso real (cuántos asesores la usan, qué tan crítico es el offline) siguen pendientes de A6, según lo previsto.
