# 13 · Auditoría de rendimiento y escalabilidad

| Campo | Detalle |
|---|---|
| Capítulo | C12 |
| Requerimiento(s) | RF-14 |
| Etapa | A — T-18 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Análisis **estático y de lectura** (RNF-01, PRD §6) — sin pruebas de carga contra producción. No se ejecutó `npm install`/`npm run build` para no exceder el alcance de solo lectura (instalar dependencias toca red y filesystem fuera del repositorio); el tamaño de bundle real queda como pendiente explícito, no estimado.

---

## 1. Estrategia de bundle — confirma y detalla la regla crítica de `CLAUDE.md`

Ya documentada en C1/T-06 y C9/T-15 con evidencia completa: `manualChunks` separa `recharts` (~112 KB gzip, según el propio comentario del código) en un chunk único y aísla `react-vendor`, **"NO parte recharts"** (comentario textual). `globIgnores` del service worker excluye deliberadamente los chunks pesados de escritorio (`xlsx`, generadores de PPTX, `recharts`, `WelcomeScreen`) del precaché móvil.

**No medido en esta etapa:** el tamaño real del bundle final (KB por chunk, tamaño total de la primera carga). Requiere `npm run build`, fuera de alcance de un análisis puramente estático sin instalar dependencias. **Recomendación:** correr `npm run build` con acceso autorizado como primer paso de cualquier PRD de ejecución posterior — es información barata de obtener y de alto valor para dimensionar cualquier escenario.

## 2. Consultas y el límite de 1000 filas de PostgREST

**Hecho:** 10 archivos usan `.range()` (paginación explícita) y 28 usan `.limit()`. Los cálculos agregados de mayor volumen (facturación diaria/mensual, siniestralidad, KPIs de call center) se resuelven vía **RPC** (confirmado en C2/C3), que devuelven resultados agregados, no las filas crudas — esquivan el límite de 1000 filas por diseño, no por casualidad.

**Riesgo residual identificado (informativo, severidad Baja):** `useVentasSimuladas.ts` (War Room) consulta `contratos` filtrando por 1-3 días recientes (`fecha_alta` in [...]) **sin `.limit()` explícito** — se apoya implícitamente en que ningún día tiene más de 1000 contratos nuevos. Es una asunción razonable hoy (el archivo completo de contratos son ~70 000 en total histórico, no por día), pero **no está garantizada por código** — si el volumen de ventas diario creciera, PostgREST truncaría en silencio a 1000 filas sin error visible. Se traslada a `hallazgos.md` como hallazgo Bajo.

## 3. El archivo de contratos como cuello de botella conocido (ya documentado en C6/T-13)

El propio código advierte: el Excel de contratos pesa **21-22 MB (~70 000 filas) y "crece con el tiempo"**. Es carga manual, en el navegador, con SheetJS — el parseo de un archivo de ese tamaño en el cliente (no en un servidor) es la operación de mayor consumo de memoria/CPU del lado del navegador de todo el sistema. No se encontró un límite de tamaño de archivo distinto al genérico (`validarArchivo(file, 60, 'planilla')` — 60 MB, visto en C6/T-13) que anticipe este crecimiento.

## 4. Realtime — volumen y costo (remite a C8/T-14 y C15/T-23)

Ya cuantificado: 11 canales, de los cuales 3 (`postventa`) escalan **por caso abierto**, no por un techo fijo. El dimensionamiento de costo real (conexiones concurrentes en hora pico) es exclusivo de T-35 (Etapa B, requiere A1/A2) — aquí se deja señalado como el principal factor de crecimiento a vigilar, no cuantificado.

## 5. Comportamiento ante crecimiento de datos y usuarios — evaluación cualitativa

| Vector de crecimiento | Qué lo absorbe hoy | Riesgo si crece |
|---|---|---|
| Más contratos históricos | Nada explícito — el Excel completo se re-sube cada vez | El archivo de 22 MB seguirá creciendo; en algún punto se vuelve inmanejable de descargar/subir manualmente (es, en el fondo, el mismo problema de fondo que motiva el PRD sobre la integración por Excel) |
| Más casos de avería simultáneos | Canales Realtime por `casoId` (C8) | Más conexiones concurrentes de Realtime, costo de Supabase crece linealmente |
| Más usuarios concurrentes en War Room/`tv` | Canal único consolidado (`visitasRealtime.ts`, ya optimizado, C8/C10) | Bajo — el sistema ya resolvió este caso específico una vez |
| Más asesores de terreno (PWA) | IndexedDB local por dispositivo, sin límite server-side aparente | Bajo — el cuello de botella sería de red/sincronización individual, no del servidor central |

## 6. Cobertura declarada (RNF-11)

Cubierto con evidencia: estrategia de chunks, manejo del límite de 1000 filas (con un hallazgo puntual Bajo), el archivo de contratos como cuello de botella físico conocido, y una evaluación cualitativa de crecimiento por vector. **No cubierto, declarado explícitamente:** tamaño real de bundle (requiere build), comportamiento bajo carga real (requiere pruebas de carga, fuera de alcance por PRD §6), y costo/volumen exacto de Realtime (Etapa B).
