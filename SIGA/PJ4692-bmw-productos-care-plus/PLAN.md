# Plan de Desarrollo — BMW productos: precios Jul 2026 + Care Plus + quitar filtro

> Generado a partir del PRD `bmw-productos-care-plus/PRD.md`. Plan aprobado en sesión (plan mode).

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/bmw-productos-care-plus/PRD.md` (v1.0) |
| Repositorios | `bmw_landing` (DB + front) · `gp_3.0_siga_api` (Contracts) |
| Rama | `feature/cc_bmw_productos_care_plus` (misma en ambos repos) |
| Rama base | `develop` (ambos repos ya están en develop) |
| Tipo | Feature |
| Responsable | Carlos Castellanos |
| Fecha | 2026-07-10 |
| Estado | Validado |

> Datos de precios extraídos del Excel de Mario en `scratchpad/bmw_pricing_jul2026.json` (33 modelos × {GarantiPlus, BMW Care Plus} × {12, 24}). No re-teclear; el seed toma de ahí.

---

## Fase 1 — Base de datos (`bmw_landing/db_bmw`)

- [ ] **T-01** — Equivalencia + seed con 2 líneas y precios nuevos
  - Archivo: `db_bmw/08_bmw_equivalencia_productos.sql`
  - `bmw_modelo_producto`: agregar `linea_producto varchar(40) NOT NULL`; cambiar constraint a `UNIQUE (marca, modelo, linea_producto)` (conservar columna `id_proyecto`).
  - Seed **66 filas** (33 modelos × 2 líneas). Excellence Mirror → producto `'BMW - {marca} - {modelo}'`, precios col GarantiPlus. Care Plus → producto `'BMW Care Plus - {marca} - {modelo}'`, precios col BMW Care Plus. `INSERT bmw_modelo_producto` con `linea_producto`.
  - Precio mensual `ROUND(total/meses,2)` (12 y 24), `producto_proyecto` con la misma config que hoy. **Quitar `i3 REX`.** Normalizar nombres Excel→catálogo (`1/2er→1/2 er`, `JCW→JCW (John Cooper Works)`, etc.).
  - Criterio: 66 equivalencias, 2 líneas, sin i3 REX, precios = Excel.

- [ ] **T-02** — Columna de trazabilidad en `bmw_registro`
  - Archivo: `db_bmw/02_schema_bmw_portal.sql`
  - Agregar `producto_bmw VARCHAR(80)` (guarda 'BMW Excellence Mirror' / 'MINI Excellence Mirror' / 'Care Plus').
  - Criterio: la columna existe tras re-correr el script.

## Fase 2 — API (`gp_3.0_siga_api/Services/Contracts`)

- [ ] **T-03** — Resolver por línea
  - `Services/Bmw/BmwRegistrationService.ProductResolution.cs`: `ResolveProductAsync` recibe `linea`; WHERE `AND lower(btrim(bmp.linea_producto))=lower(@linea)`.
  - `Controllers/BmwController.cs` `ResolveProductByVehicle`: `[FromQuery] string? linea` → pasar al servicio.
  - Criterio: `product-by-vehicle?...&linea=Care Plus` devuelve el producto Care Plus.

- [ ] **T-04** — Persistir trazabilidad
  - `DTOs/Bmw/Requests/CreateBmwLandingContractForm.cs`: campo `ProductoBmw`.
  - `Services/Bmw/BmwLandingContractRequestFactory.cs` (`BuildAsync`) + `BmwRegistrationPayload`: propagar el valor.
  - `Services/Bmw/BmwRegistrationService.cs` (`InsertRegistrationAsync`): agregar `producto_bmw` al INSERT + parámetro.
  - Criterio: al crear contrato, `bmw_registro.producto_bmw` = selección del dropdown.

## Fase 3 — Landing (`bmw_landing/src`)

- [ ] **T-05** — Catálogo: 3 opciones, sin filtro, sin i3 REX
  - `constants/vehicleCatalog.ts`: `BMW_PRODUCT_FAMILIES` → 3 opciones con su `linea`; `vehicleBrandsForFamily` deja de restringir (marca lista siempre `VEHICLE_BRANDS`); quitar `'i3 REX'`.
  - Criterio: dropdown 3 opciones; marca/modelo libres.

- [ ] **T-06** — Secciones de captura
  - `sections/ProductDetailSection.tsx`: 3ª opción; `onChange` de Producto ya no resetea marca/modelo (solo productId/quotedPrice).
  - `sections/VehicleInfoSection.tsx`: marcas siempre disponibles; quitar disabled/placeholder "Primero elige producto".
  - Criterio: selección libre sin cascade.

- [ ] **T-07** — Resolución con línea
  - `RegistrationPortal.tsx`: el efecto de resolución pasa la `linea` (derivada de `productFamily`).
  - `services/sigaService.ts`: `resolveProduct` agrega `linea` al query string.
  - Criterio: resuelve el producto de la línea correcta.

- [ ] **T-08** — Envío de trazabilidad + tipos
  - `lib/buildBmwContractFormData.ts`: enviar `ProductoBmw` (selección 3-way).
  - `types.ts`: `productFamily` con 3 valores + helper de línea. `validation.ts`: sigue requiriendo `productFamily`.
  - Criterio: el multipart incluye la familia; typecheck (`pnpm lint`) OK.

## Fase 4 — Verificación

1. DB local restaurada + `02` + `08`: `count(bmw_modelo_producto)=66`, 2 líneas, sin i3 REX, precios = Excel; `bmw_registro.producto_bmw` existe.
2. API: `product-by-vehicle?brand=BMW&model=iX&linea=Care Plus` vs `linea=Excellence Mirror` → productos distintos; `price` distinto por línea.
3. Landing (`pnpm dev`): 3 opciones, marca/modelo libres; Care Plus + BMW iX → precio Care Plus; crear contrato → `producto_bmw` correcto.
4. Care Plus vs Excellence Mirror del mismo modelo → productos/precios distintos, trazabilidad correcta.

## Notas

- Ejemplos de resolución (BMW/MINI/Care Plus) en el PRD y en el plan aprobado (`~/.claude/plans/imperative-swimming-moonbeam.md`).
- No ejecutar builds/DB automáticamente: el desarrollador restaura DB y compila/reinicia. Claude edita y (landing) puede correr `pnpm lint`.
- Flujo git: rama desde `develop`, commits incrementales por tarea; PRs los gestiona el desarrollador.
- **Fuera de alcance:** `bmw_registro.precio_producto` (precio cotizado) y nombres texto de gerente/F&I/asesor.

---

*Generado por Claude Code — Engine CX*
