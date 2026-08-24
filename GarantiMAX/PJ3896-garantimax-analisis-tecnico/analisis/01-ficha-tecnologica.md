# 01 · Ficha tecnológica y de dependencias

| Campo | Detalle |
|---|---|
| Capítulo | C1 |
| Requerimiento(s) | RF-01 |
| Etapa | A — T-06 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Metodología: `00-metodologia-y-evidencia.md`. Commit analizado: `3771e7f` (`README.md`). Todas las cifras de uso son **Hecho** (conteo directo con `grep`/`find` sobre el repositorio, reproducible — comandos en `inventarios/00-comandos-de-extraccion.md`).

---

## 1. Inventario (hecho)

### Núcleo de la aplicación

| Dependencia | Versión | Para qué |
|---|---|---|
| `react` / `react-dom` | ^19.2.6 | Framework de UI. Toda la SPA. |
| `vite` | ^8.0.12 | Build tool y dev server. |
| `typescript` | ~6.0.2 | Tipado estático de todo `src/`. |
| `@tailwindcss/vite` + `tailwindcss` | ^4.3.0 | Estilos (tema oscuro, según `CLAUDE.md`). |
| `vite-plugin-pwa` | ^1.3.0 | Genera el manifest y el service worker. `registerType: 'autoUpdate'` (`vite.config.ts:51`). Detalle completo en C9 (T-15). |

### Datos y backend

| Dependencia | Versión | Uso medido |
|---|---|---|
| `@supabase/supabase-js` | ^2.107.0 | Cliente de Supabase (Postgres+RLS, Auth, Storage, Realtime, Edge Functions). Importado directamente en **5 archivos** — indicio de que el acceso a datos está centralizado, no disperso módulo por módulo (se confirma o refuta en C2/T-07). |
| `xlsx` (SheetJS, vía CDN `cdn.sheetjs.com`) | 0.20.3 | **22 archivos** lo usan — mucho más que solo los dos importadores de SIGA que documenta el PRD (`ImportarAverias.tsx`, `ImportarContratos.tsx`). También se usa para: exportar vendedores, exportar pagos, cargar presupuestos, cargar metas masivas, importar vendedores, ETL de postventa (bitácora/maestro), catálogo de productos semilla. **Hallazgo para C12/C1:** `xlsx` no viene de npm sino de un CDN externo (`https://cdn.sheetjs.com/...`) — es una dependencia fuera del registro estándar, sin auditoría de supply chain de npm. Se traslada a `hallazgos.md` en T-18/T-06. |

### Reportes y documentos generados

| Dependencia | Versión | Uso medido |
|---|---|---|
| `jspdf` | ^4.2.1 | **9 archivos**: proyecciones de facturación, rendición de gastos, cotizaciones de Hunter (dos versiones, v1 y v2 — candidato a duplicidad, ver C10), informes y dossiers de postventa, resolución de casos, metas de salas. |
| `pptxgenjs` | ^4.0.1 | **6 archivos**: cierre de mes (charts + vista + generador), cierre de salas, punto de control. Genera presentaciones ejecutivas — no está en el radar del PRD original pero es una pieza no trivial (generación de PPT en el navegador). |
| `html-to-image` | ^1.11.13 | **4 archivos**: captura de tablas/informes como imagen para incrustar en PDF/PPT (`InformeDiario.tsx`, `TablaResumen.tsx`, dos generadores de PDF de postventa). |

### Visualización y mapas

| Dependencia | Versión | Uso medido |
|---|---|---|
| `recharts` | ^3.8.1 | **8 archivos** (gráficos de KPIs, cierres, etc.). **Restricción de build activa:** `vite.config.ts` fuerza a Recharts a un chunk único (`manualChunks`) — partirlo rompe **solo en producción**, no en dev (`CLAUDE.md` §6). Regla verificada en `vite.config.ts` en T-18. |
| `leaflet` + `react-leaflet` | ^1.9.4 / ^5.0.0 | Un solo punto de uso: `src/features/salas/SalasMapa.tsx`. Mapa de salas/zonas. Superficie de migración pequeña si se sustituyera. |

### Comunicación e IA (cliente)

| Dependencia | Versión | Uso medido |
|---|---|---|
| `@twilio/voice-sdk` | ^2.18.3 | Un solo punto de uso: `src/features/callcenter/telefonoStore.ts`. Softphone del call center — es el cliente del lado navegador; el token y la lógica de servidor viven en las Edge Functions `callcenter-token`, `callcenter-ivr`, `callcenter-transcribir` (ver C4/T-11). |
| `framer-motion` | ^12.40.0 | 2 archivos con import directo del paquete — el uso real puede ser mayor vía componentes wrapper; se re-verifica si aparece relevante en C10. |
| `react-joyride` | ^3.1.0 | 5 archivos, todos en `induccion/` + `App.tsx`. Es el motor completo del tour "FABBRO" (`CLAUDE.md`), no una dependencia menor. |

### Observabilidad

| Dependencia | Versión | Uso medido |
|---|---|---|
| `@sentry/react` | ^10.57.0 | Un solo punto de inicialización: `src/lib/monitoreo.ts:13` (`Sentry.init`). Configuración centralizada — bueno para mantenibilidad, malo si `monitoreo.ts` no se importa temprano en algún flujo (a verificar en T-20). |

### Herramientas de desarrollo relevantes

| Dependencia | Versión | Para qué |
|---|---|---|
| `vitest` | ^4.1.8 | Motor de los 65 archivos de test (`inventarios/archivos-test.txt`). |
| `eslint` + `typescript-eslint` | ^10.3.0 / ^8.59.2 | Lint, corrido en CI (`.github/workflows/ci.yml`, ver C13/T-19). |

---

## 2. Veredicto por dependencia (evaluación)

| Dependencia | Equivalente en .NET | Veredicto | Razón |
|---|---|---|---|
| `react` / `vite` / `typescript` | — (frontend no tiene default único en Engine; ver `rules/stack.md`) | **Conservable** | Es el frontend completo; sustituirlo es re-escribir toda la SPA, no una migración de librería. La decisión real está en C16/C17, no aquí. |
| `@supabase/supabase-js` | `Npgsql` + Identity + `IHttpClientFactory` (para Storage/Edge equivalentes) | **Sustituible, con costo repartido en 5 servicios** | Ver C15 (T-23): no es una librería, es la puerta a cinco servicios distintos (Postgres+RLS, Auth, Storage, Edge Functions, Realtime). |
| `xlsx` (CDN) | `ClosedXML` / `EPPlus` | **Sustituible, y recomendable hacerlo pronto** | El equivalente .NET es maduro y del registro oficial de NuGet. Además, `xlsx` vía CDN es un riesgo de supply chain que no depende de la decisión de migración — se puede resolver hoy moviéndolo a npm si hay una versión publicada ahí. |
| `jspdf` | `QuestPDF` / `iText7` | **Sustituible, esfuerzo medio** | 9 puntos de uso, todos autocontenidos por módulo — no hay un servicio central de PDF, cada módulo genera el suyo. Migrar exige rehacer cada plantilla, no solo cambiar la librería. |
| `pptxgenjs` | No hay equivalente maduro y directo en .NET para generación de PPTX desde backend con la misma facilidad | **Riesgoso de sustituir** | Es de las piezas más específicas de la SPA. Generar PPT desde C# es viable (`DocumentFormat.OpenXml`) pero con una curva más alta; conviene dimensionarlo en C16 si algún escenario lo requiere. |
| `recharts` | Recharts no tiene análogo directo del lado servidor; en .NET normalmente se grafica en el propio frontend igual (Chart.js, etc.) | **Conservable si se conserva el front; sustituible si se rehace todo en Razor** | Depende enteramente del escenario de destino — no es una decisión aislada de librería. |
| `leaflet` / `react-leaflet` | Igual que `recharts`: es una librería de frontend | **Conservable / bajo riesgo de migración** | Un solo archivo de uso (`SalasMapa.tsx`); si el escenario exige Razor, el reemplazo (Leaflet vía CDN + JS interop, o un componente Blazor de mapas) es acotado. |
| `@twilio/voice-sdk` | Twilio también publica SDK de servidor para .NET (`Twilio.AspNet`) | **Conservable** | Twilio es agnóstico de framework; el softphone del navegador seguiría funcionando igual, cambiando solo el backend que emite el token. |
| `@sentry/react` | `Sentry.AspNetCore` | **Conservable, con migración trivial** | Sentry tiene SDK oficial para .NET; es de las piezas de menor fricción en cualquier escenario. |
| `react-joyride` | No hay equivalente directo en Razor/Blazor con la misma madurez | **Riesgoso de sustituir, bajo impacto de negocio** | Es UX de onboarding, no lógica de negocio — sustituible por una implementación ad-hoc si hiciera falta, sin bloquear ningún escenario. |
| `html-to-image` | Renderizado de imagen desde HTML no es un patrón nativo en .NET (se resolvería con un headless browser o una librería de renderizado server-side) | **Sustituible, esfuerzo no trivial** | Usado para capturas de tablas dentro de PDFs — de las piezas más "hack" del stack actual; conviene evaluarla junto con `jspdf` en cualquier escenario de migración. |

**Cobertura:** 14 dependencias de producción con veredicto (100%); 16 de desarrollo listadas sin veredicto individual (no aplica: son herramientas de build/test, no runtime del sistema — RNF-11).

---

## 3. Hallazgos preliminares para `hallazgos.md`

| Hallazgo | Severidad tentativa | Se traslada a |
|---|---|---|
| `xlsx` se instala desde un CDN externo (`cdn.sheetjs.com`), fuera del registro npm — sin control de versión reproducible garantizado ni auditoría de supply chain estándar | Media | T-18 (rendimiento/seguridad de build) |
| `jspdf` tiene dos generadores de cotización paralelos en Hunter (`cotizacionPdf.ts` y `cotizacionPdfV2.ts`) — posible duplicidad sin resolver | Baja–Media | C10 (T-16) |
| `xlsx` tiene una superficie de uso (22 archivos) mucho mayor de lo que documentaba el PRD original (solo mencionaba los 2 importadores de SIGA) — el "Excel" es un patrón de integración/exportación transversal a todo el sistema, no exclusivo de SIGA | Informativo | C2 (T-07), relevante para dimensionar cualquier escenario de migración |
