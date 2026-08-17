# Plan de Desarrollo — Acceso de solo lectura a productos y precios para Ejecutivo de Ventas (PJ3423)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ3423-acceso-productos-precios-ejecutivo-ventas/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — Catalogos/Distribuidores) |
| Rama base | `develop` |
| Rama | `feature/PJ3423-acceso-productos-precios-ejecutivo-ventas` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ3423` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 43 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

El **Ejecutivo de Ventas** ya entra a **Catálogos → Distribuidores**, ve solo los asignados (`usuario_distribuidor`) y abre **Details** filtrado por `GetDealerDetailsSalesRole`. En Details ve **nombres de producto**, no la **matriz de precios**. Esa matriz vive en `precio_producto` (la misma tabla que `_PreciosDistribuidor.cshtml` del Administrador en `Catalogos/Productos`). Edit de distribuidor y el catálogo Productos siguen cerrados a AG/Gestor.

El cambio: con un **flag por país** (apagado si la key no existe), enriquecer Details en solo lectura con precios/vigencias de los productos asignados. No abrir `ProductosController`. No permitir editar ni exportar esa grilla.

- **Arquitectura:** feature sobre SIGA Web. Sin API nueva, sin PDFGenerator, sin BD.
- **Stack:** .NET 8, Razor, `appsettings` por país (mismo estilo que `AutorizacionAverias:{MEX}`).

**Hallazgo técnico (cierra la pregunta abierta del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| ¿Qué pantalla reutilizar? | **`/Catalogos/Distribuidores/Details/{id}`** (el Ejecutivo ya llega ahí). No `ProductosController` (`[Authorize]` = AG/Gestor/Auditor). No `Distribuidores/Edit` (solo AG/Gestor). |
| ¿Dónde están los precios? | `precio_producto` del `producto_proyecto` asignado al dealer (`producto_distribuidor`). Details hoy solo pinta `nombre_producto`. Llantas: `producto_distribuidor.precio`. Grupos con `precios_volumen`: Details dice “Precios por volúmen para el grupo” sin montos. |
| ¿Asignación ejecutivo→dealer? | `usuario_distribuidor`. `GetDealerDetailsSalesRole` exige que el username esté en `usuarios` del dealer; si no, `model == null` → redirect Index. Listado Index ya filtra igual. |
| ¿Flag por país? | No hay uno para esto. Patrón a copiar: sección `appsettings` indexada por código de país (`GetCountryCodeForCurrentProject()`). Default: **ausente o false = apagado**. |
| ¿Exportación hoy? | `Exportar` en Index **no tiene** `[Authorize]` extra (vale el de clase). El Ejecutivo **puede** bajar Excel de la lista de dealers (clave, nombre…), **no** de precios. `export-button` no filtra por rol. |
| ¿Edición hoy? | Ejecutivo no puede Edit/Create/CargaPrecios. RF-03 ya se cumple en servidor; hay que **no** abrir esos endpoints. |

**Implicación:** no duplicar el catálogo de Productos. Ampliar la card Productos de Details + enforcement del flag. México se enciende en config del hub MX; COL/CHL quedan en false.

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] `develop` actualizado; `CLAUDE.md` presente ✅
- [ ] Usuario **Ejecutivo de Ventas** con ≥1 dealer en `usuario_distribuidor` (hub MX)
- [ ] Mismo usuario sin dealers (o segundo user) para el mensaje vacío
- [ ] Un dealer de otro ejecutivo para probar 404/redirect
- [ ] No commitear `appsettings.json` sucio (correos, secrets); **sí** se puede añadir solo la sección del flag si el resto no se toca

---

## 3. Arquitectura del cambio

```
[Ejecutivo] Catálogos → Distribuidores
        │
        ├─ flag país OFF  → igual que hoy (lista asignados; Details sin matriz de precios)
        └─ flag país ON
              ├─ Index: lista asignados; si 0 filas → mensaje RF-09
              ├─ Details: GetDealerDetailsSalesRole (asignación)
              │     + include precio_producto
              │     + card Productos con misma tabla que _PreciosDistribuidor (solo lectura)
              └─ POST Edit / Productos / CargaPrecios → 403 (ya hoy)
```

**Decisiones de diseño:**

1. **No** añadir `Ejecutivo de Ventas` a `ProductosController`.
2. **No** abrir `Distribuidores/Edit`.
3. Flag: `Catalogos:EjecutivoVentasVerProductosPrecios:{MEX\|COL\|CHL\|…}` bool. Si falta la key → **false**.
4. Primer release: **MEX = true** en el appsettings del hub México (TI); resto false.
5. Precios de grupo (`precios_volumen`): en Details, si aplica, mostrar la matriz del **grupo** en solo lectura (misma idea); sin entrar a `GruposController`.
6. Export Excel de **lista de dealers**: no incluye precios; se deja (RF-08). No añadir export de la grilla de precios. Ocultar `window.print` no es un botón hoy; no inventar impresión.
7. Helper único `IsSalesExecutiveProductPricesEnabled(countryCode)` (p. ej. en `GeneralController` o clase chica en Catalogos). El flag se evalúa en **servidor** al armar ViewBag y al cargar precios (RNF-01).
8. No auditoría de consultas (fuera de alcance).

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — `feature/PJ3423-acceso-productos-precios-ejecutivo-ventas` desde `develop`
  - Criterio de completitud: rama en origin

### Fase 1 — Flag y carga de precios (P1)

- [ ] **T-02** — Setting por país
  - Archivos: `appsettings.json` (solo la sección nueva; no mezclar cambios locales); helper de lectura
  - Clave: `Catalogos:EjecutivoVentasVerProductosPrecios`
  - Criterio de completitud: sin key o `false` → ViewBag false; `true` para MEX en el hub MX

- [ ] **T-03** — Cargar `precio_producto` (e impuesto/vigencia si aplica) cuando el flag está on y el rol es Ejecutivo (o al pintar Details)
  - Archivos: `DistribuidoresController.Details`; query extra o include `productos.producto.precios` **sin** reescribir los N `Pais*.GetDealerDetailsSalesRole` si se puede hidratar en el controller
  - Criterio de completitud: el modelo de Details tiene filas de precio para los productos del dealer asignado; un dealer no asignado sigue en redirect Index

### Fase 2 — UI solo lectura (P1)

- [ ] **T-04** — Card Productos en `_GeneralesDistribuidor.cshtml` (y el bloque duplicado del fondo del archivo si sigue vivo)
  - Si flag off: tabla actual (solo nombre)
  - Si flag on: por cada producto, tabla tipo `_PreciosDistribuidor` (HP/km/años/contratación/precio formateado). Sin botones Cargar/Modificar. Llantas: mostrar `producto_distribuidor.precio`
  - Grupo volumen: tabla de precios del grupo o mensaje claro si no hay filas
  - Criterio de completitud: Ejecutivo en MX ve montos; AG/Gestor no pierden Edit

- [ ] **T-05** — Index vacío (RF-09)
  - Archivos: `IndexMEX/COL/CHL.cshtml` o JS del datagrid
  - Si Ejecutivo + 0 asignados: texto en español (“No tiene distribuidores asignados”)
  - Criterio de completitud: no se listan dealers ajenos

### Fase 3 — Bloqueos y no-regresión (P1)

- [ ] **T-06** — Confirmar (y endurecer si hace falta) que Ejecutivo no escribe
  - `Edit` GET/POST, `Create`, `CargaPrecios`, `ProductosController` siguen sin el rol
  - No añadir export de precios. No abrir Productos en el menú
  - Criterio de completitud: POST a Edit o a Productos/CargaPrecios → 403; menú Productos sigue sin Ejecutivo

- [ ] **T-07** — Flag off = comportamiento actual
  - COL/CHL (o MEX con false): Details sin matriz de precios (solo nombres, como hoy)
  - Criterio de completitud: un Ejecutivo COL no ve precios aunque conozca la URL de Details de un asignado

### Fase 4 — Validación (P1)

- [ ] **T-08** — MX flag on: asignado ve precios; no asignado redirect; sin dealers → mensaje
- [ ] **T-09** — Flag off + AG sin cambios (Modificar, Cargar precios, catálogo Productos, Excel de lista)

---

## 5. Cambios en base de datos *(si aplica)*

No aplica.

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Catalogos/Distribuidores/Details/{id}` | Precios en solo lectura si flag + asignación | Modificado |
| GET | `/Catalogos/Distribuidores` | Mensaje si 0 asignados | Modificado (vista) |
| POST | `/Catalogos/Distribuidores/Edit` | Sin Ejecutivo | Sin cambio de authorize |
| * | `/Catalogos/Productos/*` | Sin Ejecutivo | Sin cambio |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Catalogos:EjecutivoVentasVerProductosPrecios:MEX` | `true` en hub México (primer release) | QA/prod MX |
| `Catalogos:EjecutivoVentasVerProductosPrecios:COL` | `false` | hub CO |
| `Catalogos:EjecutivoVentasVerProductosPrecios:CHL` | `false` | hub CL |
| (cualquier otro código de país) | Ausente = apagado | — |

Administración = TI edita appsettings / parámetro del host. Sin pantalla de negocio.

---

## 8. Consideraciones de seguridad

- Assignment y flag en **servidor** (Details ya filtra; no cargar precios si flag off).
- No filtrar solo en Razor: si flag off, no hidratar `precios` en el modelo.
- No exponer `Productos/Details` ni JSON de `CargaPrecios` al Ejecutivo.
- IDOR: Details de un dealer no asignado ya redirige; no relajar `GetDealerDetailsSalesRole`.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin AWS. Tres binarios/hubs: el mismo código; el flag cambia por `appsettings` de cada país.
- No desplegar PDFGenerator ni API.

---

## 10. Criterios de aceptación

- [ ] **RF-01 / RNF-03 / RNF-04:** Ejecutivo MX ve en Details los productos del dealer y la matriz de precios (mismos campos que `_PreciosDistribuidor`: rangos + precio).
- [ ] **RF-02 / RNF-01:** No ve dealers ni precios de no asignados (URL directa → Index).
- [ ] **RF-03:** No crear/editar/cargar precios.
- [ ] **RF-04:** No hay botón de export/print de esa grilla.
- [ ] **RF-05 / RF-06 / RF-07 / RNF-06:** Flag por país; default off; MEX on en el release MX.
- [ ] **RF-08:** Flag off = solo nombres de producto, como hoy.
- [ ] **RF-09 / RNF-05:** Sin asignados → mensaje claro, sin datos.
- [ ] AG/Gestor/Usuario Distribuidor: sin regresión.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| `_GeneralesDistribuidor` duplicado (markup viejo abajo) | Alta | Medio | Cambiar ambos o borrar el bloque muerto si no se usa |
| `precios_volumen` de grupo no cargado | Media | Medio | T-04: query de precios de grupo o mensaje explícito |
| Include de precios pesado | Baja | Bajo | Cargar precios solo si flag on |
| Flag true commiteado en appsettings local de otro país | Media | Medio | Default false; documentar hub MX |
| Export Index se interpreta como fuga | Baja | Bajo | El Excel actual no trae precios; no ampliarlo |

---

## 12. Notas para el programador

1. Rol exacto: **`Ejecutivo de Ventas`**. Hay `[Authorize]` viejos con `"Ejecutivo Ventas"` (sin “de”); **no** “arreglarlos” salvo que se toque esa línea.
2. No mezclar con PJ9159 / PJ4197 / PJ0288.
3. Código nuevo en inglés; textos de UI en español.
4. No refactorizar `DistribuidoresController` (~1800 líneas) más de Details + helper.
5. No añadir el rol al menú **Productos**.

---

## 13. Relación de tareas y tiempos

Todo el PRD es **P1** (un solo alcance gobernado por flag).

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 127 |
| **Fase 1 — Flag y datos (P1)** | Setting + hidratar precios | T-02 a T-03 | 0.5 – 1 día | 128 |
| **Fase 2 — UI solo lectura (P1)** | Details + vacío Index | T-04 a T-05 | 0.75 – 1.5 días | 129 |
| **Fase 3 — Bloqueos (P1)** | 403 escritura + flag off | T-06 a T-07 | 0.25 – 0.5 días | 130 |
| **Fase 4 — Validación (P1)** | MX on / flag off / AG | T-08 a T-09 | 0.5 – 1 día | 131 |
| **Total proyecto (P1)** | | 9 tareas | ~2 – 4 días hábiles (≈ 0.5 – 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 4 | T-01 a T-09 | ~2 – 4 días hábiles | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre 2–4 días. No hay recorte P2. El único riesgo de calendario es validar MX con un ejecutivo real y dealers asignados.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
