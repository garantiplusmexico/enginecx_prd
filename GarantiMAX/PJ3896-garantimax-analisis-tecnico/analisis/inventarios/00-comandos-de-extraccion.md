# Comandos de extracción — inventarios base (T-05)

> Reproducible por cualquiera con acceso de lectura al repositorio (RNF-02). Todos los comandos se corrieron sobre `garantiplus-dashboard` en el commit fijado **`3771e7f`** (2026-08-19 11:24 -0400), desde la raíz del repositorio.

| Salida | Comando | Resultado |
|---|---|---|
| `modulos.txt` | `ls src/features` | 24 módulos |
| `migraciones.txt` | `ls supabase/migrations/*.sql \| xargs -n1 basename` | 364 migraciones |
| `edge-functions.txt` | `ls supabase/functions` | 46 funciones |
| `dependencias.txt` | lectura de `package.json` (`dependencies` + `devDependencies`) | 14 dependencias de producción, 16 de desarrollo |
| `archivos-test.txt` | `find src -type f \( -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" -o -name "*.spec.tsx" \)` | 65 archivos |
| `canales-realtime.txt` | `grep -rn "\.channel(" src --include="*.ts" --include="*.tsx"` | 11 canales |
| `hosts-externos.txt` | `grep -rEho "https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" supabase/functions src \| sed -E 's#https?://##' \| sort -u` | 20 hosts distintos (algunos son enlaces salientes de UI, no integraciones con llamada de servidor — se depura en T-12) |

## Notas de lectura

- **`hosts-externos.txt` incluye falsos positivos para efectos de integración**: `wa.me`, `waze.com`, `maps.google.com`, `www.waze.com`, `www.w3.org`, `placehold.co` y `www.garantimax.com` son enlaces de salida en la UI (`<a href>`), no llamadas de servidor con llave. La depuración a "integración real vs. enlace de salida" se hace en **T-12 (Fase 1)**.
- **Host nuevo no listado en el PRD:** `nominatim.openstreetmap.org` (geocodificación) y `console.groq.com` (probablemente un enlace de documentación, no una llamada). Se investigan en T-12.
- Este archivo y sus salidas se re-generan si Etapa B necesita re-verificar contra un commit posterior (T-28, T-38).
