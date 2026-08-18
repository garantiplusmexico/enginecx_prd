# Plan de Desarrollo — Ejecutivo de Ventas: alta de Asesores, Puntos de Venta y usuarios (PJ2613)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ2613-ejecutivo-ventas-crea-asesores-pdv-usuarios/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — Catalogos: Asesores, PuntoVenta, Usuarios) |
| Rama base | `develop` |
| Rama | `feature/PJ2613-ejecutivo-ventas-crea-asesores-pdv-usuarios` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ2613` |
| Fecha de generación | 2026-08-17 |
| Estado | Validado |
| ID plan (BD) | 45 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

El PRD asume que **solo el Administrador General** da de alta Asesores, PDV y usuarios. En `develop` eso es **cierto para PDV y Usuarios**, **falso para Asesores**: el Ejecutivo **ya** entra al catálogo, ya tiene **Registrar asesor** y `POST Create` (y `Edit` por URL). `SetupBags` ya limita el combo de dealers a `usuario_distribuidor`. PDV (`PuntoVentaController`) y Usuarios (`UsuariosController`) son AG/Gestor(/Auditor); el menú no se los muestra.

El trabajo real: **abrir PDV y Usuarios** al Ejecutivo con **flag por país**; **restringir roles** a `Ejecutivo de Ventas` y `Usuario Distribuidor`; **validar dealers en servidor**; **create-only** (no Edit/Delete/Export). En Asesores: **no quitar** el alta que ya existe (sería regresión); **sí** bloquear Edit para Ejecutivo y validar `id_distribuidor` en el POST.

- **Arquitectura:** feature sobre SIGA Web. Sin API, sin BD nueva.
- **Stack:** .NET 8, Razor, Identity, `usuario_distribuidor`, `appsettings` por país.

**Hallazgo técnico (cierra las preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en `develop` |
|---|---|
| Rol | **`Ejecutivo de Ventas`**. Usuario a crear: ese mismo o **`Usuario Distribuidor`**. |
| Asesores hoy | Menú MEX/COL/CHL ya incluye Ejecutivo. `AsesoresController` clase + Create GET/POST + Edit GET/POST incluyen el rol. Index: botón Registrar con `profiles` que incluyen Ejecutivo. Details **Modificar** solo AG/Gestor (el Ejecutivo igual puede `/Edit/{id}`). Listado ya filtra `solodistribuidores`. **Create no valida** que el `id_distribuidor` posted sea asignado. |
| PDV hoy | Menú y controller **sin** Ejecutivo. Create/Edit solo AG/Gestor. `GetAllPuntosVenta` **no** filtra por dealer. |
| Usuarios hoy | Menú y clase `[Authorize]` = AG, Gestor, Auditor. Create envía **correo con usuario/contraseña** (estándar o `correos_proyecto`). `SetupViewBags` para AG carga **todos** los roles (excepto Taller) y todos los dealers del proyecto. |
| Setting | No existe. Mismo patrón que PJ3423/PJ1255: `Catalogos:EjecutivoVentasAltas:{MEX\|COL\|CHL}` bool; ausente = **false**. |
| País de arranque | PRD encabezado = México; el pedido operativo = Chile. **Default false en todos**; TI enciende el hub (recomendado **CHL** primero). |
| Trazabilidad | `usuario_creador` solo si el alta la hace Gestor. **No** añadir para Ejecutivo (fuera de alcance). |
| Notificación | **Sí hay correo** al crear usuario. Reutilizar; no inventar otro. |
| Edit Asesores vs RF-07 | UI ya oculta Modificar al Ejecutivo; el `[Authorize]` de Edit **sí** lo deja. Hay que sacarlo del Edit (solo Ejecutivo; no tocar Usuario Distribuidor / Gerente / Vendedor). |

**Decisión sobre el flag vs Asesores (RF-06):** “comportamiento actual” de Asesores **incluye** el alta. El flag **no** apaga Asesores. El flag **sí** gobierna PDV + Usuarios (menú, botón, POST). Así no se rompe MX/COL/CHL donde el Ejecutivo ya registra asesores.

---

## 2. Prerequisitos

- [ ] PRD validado
- [ ] `develop` actualizado; `CLAUDE.md` presente ✅
- [ ] Usuario **Ejecutivo de Ventas** con ≥1 dealer en `usuario_distribuidor`
- [ ] Hub donde se encenderá el flag (CHL o MEX) para probar PDV/usuarios
- [ ] Un dealer no asignado (probar rechazo)
- [ ] AG para no-regresión
- [ ] No commitear `appsettings.json` sucio; sí la sección del flag

---

## 3. Arquitectura del cambio

```
[Ejecutivo] Catálogos
  ├─ Asesores (ya hoy)
  │     Create: combo dealers asignados + validar POST
  │     Edit: 403 (RF-07)
  └─ flag país ON
        ├─ menú Puntos de venta + Usuarios
        ├─ PDV Create (dealers asignados; Listado/Details solo los suyos)
        └─ Usuarios Create (roles: Ejecutivo | Usuario Distribuidor;
              dealers ⊆ asignados; correo existente)
     flag OFF → PDV/Usuarios como hoy (sin menú, POST 403)
```

**Decisiones de diseño:**

1. Clave: `Catalogos:EjecutivoVentasAltas`. Helper `IsSalesExecutiveCatalogCreatesEnabled(countryCode)`. Ausente → false.
2. Menú: **no** poner Ejecutivo a ciegas en `profiles` de PDV/Usuarios (se vería con flag off). En `_LeftMenuBar_{MEX,COL,CHL}.cshtml` mostrar esos subítems si rol + flag (`Hub:HubBaseCountryCode` o código de proyecto). Asesores no se toca en el menú.
3. PDV: añadir Ejecutivo a Index/Listado/Details/Create (no Edit/Delete/Exportar). Filtrar listado y Details por `usuario_distribuidor`. Create: combo = asignados; POST rechaza dealer ajeno.
4. Usuarios: añadir Ejecutivo solo a Index/Listado/Details/Create (no Edit/activar/Exportar). `SetupViewBags`: si Ejecutivo + flag → roles solo esos dos; dealers = asignados. POST: whitelist de rol **y** de IDs de dealer. Listado: usuarios ligados a esos dealers (no el padrón completo).
5. Asesores: validar dealer en Create POST; quitar Ejecutivo de Edit GET/POST (y Delete stub). No quitar Create.
6. AG/Gestor: cero cambios de alcance.
7. Correo de alta de usuario: el que ya existe. No auditoría nueva.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama

- [ ] **T-01** — `feature/PJ2613-ejecutivo-ventas-crea-asesores-pdv-usuarios` desde `develop`
  - Criterio de completitud: rama en origin

### Fase 1 — Flag y Asesores (P1)

- [ ] **T-02** — Setting + helper
  - Archivos: `appsettings` (solo la sección); helper reutilizable desde controllers y vistas/menú
  - Criterio de completitud: sin key → false; lectura por código de país

- [ ] **T-03** — Asesores create-only + dealer en servidor
  - Archivos: `AsesoresController.cs` (Create POST, Edit GET/POST); Details ya oculta Modificar
  - Ejecutivo: Create exige `id_distribuidor` ∈ asignados; Edit → 403
  - Criterio de completitud: POST Create con dealer ajeno falla; `/Asesores/Edit/{id}` 403; AG sigue editando

### Fase 2 — Puntos de Venta (P1)

- [ ] **T-04** — Acceso y alta PDV
  - Archivos: `PuntoVentaController.cs`; `Index.cshtml` (botón Registrar si flag); `_LeftMenuBar_*`; `CatalogosBusinessRules.GetAllPuntosVenta` o filtro en Listado
  - Create GET/POST: dealers asignados + flag; Edit/Exportar sin Ejecutivo
  - Details: 404/redirect si el PDV no es de un dealer asignado
  - Criterio de completitud: Ejecutivo + flag crea PDV de un asignado; sin flag 403; listado sin ajenos

### Fase 3 — Usuarios (P1)

- [ ] **T-05** — Acceso y alta de usuarios
  - Archivos: `UsuariosController.cs` (`SetupViewBags`, Create, Listado, Details); `Index.cshtml`; `_Edit.cshtml` (el combo usa ViewBag.Roles); menús
  - Roles permitidos en UI y POST: `Ejecutivo de Ventas`, `Usuario Distribuidor`
  - Dealers del POST ⊆ asignados; al menos uno
  - No Edit / no desactivar / no Exportar
  - Listado acotado a usuarios con `usuario_distribuidor` en los dealers del Ejecutivo
  - Criterio de completitud: POST con rol Tecnico o dealer ajeno no crea; correo de credenciales se envía como hoy; AG ve todos los roles

### Fase 4 — Validación (P1)

- [ ] **T-06** — Flag off: menú PDV/Usuarios oculto; POST 403; Asesores Create sigue
- [ ] **T-07** — Flag on: tres altas sobre asignados; Edit/Delete de las tres entidades 403 para Ejecutivo; AG intacto

---

## 5. Cambios en base de datos *(si aplica)*

No aplica (tablas `asesor`, `punto_venta`, `AspNetUsers`, `usuario_distribuidor`, `aspnetuserroles` existentes).

---

## 6. Endpoints nuevos o modificados *(si aplica)*

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| POST | `/Catalogos/Asesores/Create` | Valida dealer asignado | Modificado |
| GET/POST | `/Catalogos/Asesores/Edit/{id}` | Ejecutivo fuera | Modificado (authorize) |
| GET/POST | `/Catalogos/PuntoVenta/Create` | Ejecutivo + flag + dealers | Modificado |
| GET/POST | `/Catalogos/PuntoVenta/Listado\|Details` | Filtro asignación | Modificado |
| GET/POST | `/Catalogos/Usuarios/Create` | Ejecutivo + flag + roles + dealers | Modificado |
| POST | `/Catalogos/Usuarios/Listado` | Filtro por dealers del Ejecutivo | Modificado |
| GET/POST | `/Catalogos/Usuarios/Edit` | Sin Ejecutivo | Sin cambio de authorize (clase se abre con cuidado) |

---

## 7. Variables de entorno y configuración *(si aplica)*

| Variable | Descripción | Ambiente |
|---|---|---|
| `Catalogos:EjecutivoVentasAltas:CHL` | Recomendado `true` en el primer release (solicitante) | hub CL |
| `Catalogos:EjecutivoVentasAltas:MEX` | `true` si Operaciones MX lo pide; si no `false` | hub MX |
| `Catalogos:EjecutivoVentasAltas:COL` | `false` hasta que lo pidan | hub CO |
| (otro código) | Ausente = apagado | — |

TI edita appsettings del host. Sin pantalla de negocio.

---

## 8. Consideraciones de seguridad

- Flag, roles y dealers en **servidor** (Create POST). No basta con ocultar el combo.
- No añadir Ejecutivo al `[Authorize]` de Edit/Delete/Exportar/activar.
- Usuarios: un POST con `id_rol` de Administrador debe fallar aunque el combo esté filtrado.
- Listado/Details de PDV y Usuarios no pueden ser un IDOR al padrón global.
- El correo de alta ya manda la contraseña en claro (legado); no empeorar ni loguear el password.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin AWS nuevo. Tres hubs; el flag cambia por `appsettings`.
- No desplegar API ni PDFGenerator.

---

## 10. Criterios de aceptación

- [ ] **RF-01:** Ejecutivo crea Asesores (ya podía; queda dealer validado en POST).
- [ ] **RF-02:** Con flag on, crea PDV desde el catálogo existente.
- [ ] **RF-03:** Crea usuarios solo con roles Ejecutivo de Ventas o Usuario Distribuidor.
- [ ] **RF-04 / RNF-01:** No opera dealers no asignados (UI + POST).
- [ ] **RF-05 / RNF-02:** Setting por país; default off.
- [ ] **RF-06:** Flag off → sin menú/alta PDV ni Usuarios; Asesores como hoy.
- [ ] **RF-07:** Sin Edit/Delete (Asesores Edit 403; PDV/Usuarios sin botón ni authorize).
- [ ] **RF-08 / RNF-03 / RNF-04:** AG/Gestor iguales; mismas pantallas `_Edit`.
- [ ] **RNF-05:** Asesores y PDV siguen en el menú lateral.
- [ ] Alta de usuario dispara el correo de credenciales existente.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Meter Ejecutivo en `profiles` del menú sin flag | Alta | Alto | `@if` rol+flag; no profiles estáticos solos |
| Abrir `UsuariosController` a nivel de clase y dejar Edit | Alta | Alto | Authorize por método; Edit sin el rol |
| Listado PDV/Usuarios sin filtro | Alta | Alto | T-04 / T-05 |
| Apagar Asesores con el flag (regresión) | Media | Alto | Flag no gobierna Asesores Create |
| `action-button` profiles no entiende el flag | Media | Medio | Condición Razor aparte, como Usuarios Index |
| Primer país mal elegido (MEX vs CHL) | Media | Bajo | Default false; TI enciende el hub |

---

## 12. Notas para el programador

1. Rol exacto: **`Ejecutivo de Ventas`**. No “arreglar” `Ejecutivo Ventas` en otros `[Authorize]`.
2. Independiente de PJ3423 (precios) y PJ1255 (sin cobertura). Flags **distintos**.
3. Código nuevo en inglés; textos de UI en español (ya existen).
4. No refactorizar `UsuariosController` (~780 líneas) más de SetupViewBags + Create + Listado.
5. CHL: el menú Distribuidores **no** lista al Ejecutivo; no es este folio.
6. Delete de PDV/Asesores es stub (TODO); no implementarlo.
7. No commitear `appsettings.json` locales.

---

## 13. Relación de tareas y tiempos

Todo el PRD es **P1**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama** | Rama feature | T-01 | 0.25 días | 136 |
| **Fase 1 — Flag y Asesores (P1)** | Setting + Create dealer + bloquear Edit | T-02 a T-03 | 0.5 – 1 día | 137 |
| **Fase 2 — Puntos de Venta (P1)** | Menú + Create + listado filtrado | T-04 | 0.75 – 1.5 días | 138 |
| **Fase 3 — Usuarios (P1)** | Menú + Create roles/dealers + listado | T-05 | 1 – 1.5 días | 139 |
| **Fase 4 — Validación (P1)** | Flag on/off + AG | T-06 a T-07 | 0.5 – 1 día | 140 |
| **Total proyecto (P1)** | | 7 tareas | ~3 – 5.25 días hábiles (≈ 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 a Fase 4 | T-01 a T-07 | ~3 – 5.25 días hábiles | — |

> La columna **ID (BD)** la llena el flujo al registrar el plan.

> **Riesgo de deadline:** el PRD no fija fecha. Un desarrollador cubre ~3–5 días. No hay recorte P2: si aprieta, PDV y Usuarios son el MVP nuevo; Asesores (T-03) es endurecimiento de algo que ya existe.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
