# 07 · Uso de SIGA — qué entra, cómo y con qué frecuencia

| Campo | Detalle |
|---|---|
| Capítulo | C6 |
| Requerimiento(s) | RF-08 |
| Etapa | A — T-13 |
| Versión | 1.0 |
| Fecha | 2026-08-24 |
| Estado | ✅ Cerrado |

> Todo lo descrito aquí es **Hecho** — leído directamente de `parseAverias.ts`, `parseContratos.ts`, `ImportarAverias.tsx`, `ImportarContratos.tsx` (commit `3771e7f`). **Confirmación explícita, verificada de nuevo en esta etapa:** no se encontró ninguna llamada HTTP a un host de SIGA ni en `src/` ni en las 46 Edge Functions (mismo resultado que el PRD original). **Hoy no hay consumo por API — la integración es 100% por archivo Excel.**

---

## 1. Reporte de contratos

| Campo | Detalle |
|---|---|
| Origen | Excel SIGA de contratos — **21-22 MB, ~70 000 contratos**, y "crece con el tiempo" (comentario del propio código, `parseContratos.ts`) |
| Encabezado | Fila 3 (`range: 2` en la lectura de SheetJS) |
| Columnas requeridas para aceptar el archivo | `Estatus`, `Distribuidor`, `Importe`, `F. Alta` |
| Destino | Tabla `contratos` (vía `contratos_staging` → RPC `aplicar_contratos_staging`/`aplicar_contratos_staging_anio` — patrón *staging → aplicar*, confirmado en C2) |
| Quién lo ejecuta | Restringido a **CM/GTE** (comentario explícito en `ImportarContratos.tsx`: *"Tarjeta de importación del Excel de contratos SIGA (solo CM/GTE)"*) |
| Frecuencia | **Manual, a demanda** — no hay cron ni automatización; el propio componente lleva un `CargaLog` (tabla `cargas_siga`: archivo, usuario, filas, fecha) con aviso anti-duplicado si ya se importó un archivo con el mismo nombre |
| Validación | **No se filtra al importar** — se guardan los contratos crudos; la validez (`Activo`/`Registrado` vs. `Caduco`/`Cancelado`) se aplica al *calcular* facturación, no al cargar. Decisión de diseño explícita en el comentario del archivo. |
| Continuidad histórica | El comentario dice literalmente: *"Lógica portada 1:1 del dashboard original (v18.94), función `cargarArchivoContratos`"* — confirma que esta importación existe desde antes del rediseño multiusuario y se preservó a propósito. |

**Los 22 campos que se extraen** (`ContratoRow`, `parseContratos.ts`): `id_siga`, `producto`, `importe`, `total`, `fecha_alta` (+ `fecha_alta_ts` con hora, "2026+"), `fecha_fin`, `distribuidor`, `punto_venta`, `canal`, `estado` (Activo/Registrado/Caduco/Cancelado), `vendedor` (columna "Asesor" del Excel), `marca`, `modelo`, `beneficiario`, `vin`, `patente`, `km_inicial` (columna "KM"), `anio`, `fecha_inicio`, `rut_beneficiario` (columna "R.F.C."), `telefono_beneficiario`, `email_beneficiario`. La columna "F. Fin" tolera 5 variantes de encabezado (`F. Fin`, `F.Fin`, `F Fin`, `Fecha Fin`, `F. Vencimiento`) — evidencia de que el formato del Excel de SIGA no es 100% estable entre exportaciones.

---

## 2. Reportes de averías (ACTIVAS y CERRADAS)

| Campo | Detalle |
|---|---|
| Origen | Dos variantes del mismo reporte SIGA — **comparten casi todas las columnas**; el de cerradas trae además `Fecha cierre` (así es como el parser distingue cuál es cuál, sin que el usuario lo indique) |
| Encabezado | Fila 3, igual que contratos |
| Columnas requeridas | `#`, `Estatus`, `Agencia`, `Importe indemnización` |
| Destino | Tabla `averias` (upsert directo, sin patrón *staging*, a diferencia de contratos) |
| Quién lo ejecuta | No se encontró la misma restricción de rol explícita que en contratos — a confirmar con Fabrizio si aplica igual (CM/GTE) o es más abierto |
| Frecuencia | Manual, a demanda (sin cron de importación) |

**Los 18 campos que se extraen** (`AveriaRow`, `parseAverias.ts`): `numero` (clave del upsert), `fecha_registro`, `fecha_cierre`, `cerrada` (derivado: `true` si trae `Fecha cierre`), `contrato`, `producto`, `agencia`, `modelo`, `anio`, `vin`, `estatus`, `asignacion`, `refacciones`, `total_presupuesto`, `importe_indemnizacion`, `motivo_rechazo`, `atencion_comercial`, `resolucion`, `taller` (columna "Taller Reg.").

---

## 3. Confirmación explícita para el dictamen (RF-08, obligatorio)

**No existe hoy ningún consumo de la API de SIGA.** Verificado dos veces (PRD original y esta etapa) sobre el código completo de `src/` y las 46 Edge Functions: cero llamadas HTTP a un host de SIGA. Toda la integración es:

```
Usuario CM/GTE descarga el Excel de SIGA (fuera de este sistema)
   → lo sube a GarantiMAX (ImportarContratos.tsx / ImportarAverias.tsx)
   → se parsea en el navegador (SheetJS, encabezado fila 3)
   → contratos: staging → aplicar (RPC) · averías: upsert directo
   → queda registrado en cargas_siga (contratos) con usuario y fecha
```

**Riesgo operativo confirmado, no solo teórico:** el archivo de contratos pesa 21-22 MB y "crece con el tiempo" — es una carga manual de un archivo cada vez más pesado, dependiente de que una persona lo descargue y suba correctamente. Es exactamente el punto frágil que el PRD identifica: *"todo lo que sigue — cierres, siniestralidad, proyecciones — cuelga de eso"*.

---

## 4. Insumo directo para T-36 (Etapa B) — matriz de cobertura de la API de SIGA

La matriz **dato requerido → endpoint que lo cubre** (C7/T-36) se rellena directamente con las dos listas de campos de este capítulo (22 de contratos + 18 de averías = **40 campos** en total) en cuanto llegue A3. No se necesita releer código en Etapa B para esto — es trabajo ya hecho aquí, tal como preveía `PLAN.md` §1.4 ("la Etapa B no está esperando el acceso por comodidad: necesita el resultado de la Etapa A para que la auditoría valga").

---

## 5. Cobertura declarada (RNF-11)

**100% de los campos consumidos por ambos parsers documentados** (40 campos totales), con su columna de origen en el Excel cuando el nombre interno difiere (`vendedor` ← "Asesor", `km_inicial` ← "KM", `rut_beneficiario` ← "R.F.C.", `taller` ← "Taller Reg."). **No se obtuvieron muestras reales de los archivos** (A4 pendiente) — la documentación de columnas sale del código del parser, que es la fuente de verdad de lo que el sistema realmente consume (más confiable que una muestra de archivo, que podría no reflejar todas las variantes de encabezado que el parser ya tolera). Frecuencia real de carga (¿diaria? ¿semanal?) y responsable exacto de averías (a diferencia de contratos, donde el rol restringido sí quedó confirmado) quedan en `preguntas-abiertas.md` para validar con Fabrizio Álvarez.
