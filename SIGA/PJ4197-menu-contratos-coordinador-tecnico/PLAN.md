# Plan de Desarrollo — Menú Contratos para Coordinador Técnico (PJ4197)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ4197-menu-contratos-coordinador-tecnico/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ4197-menu-contratos-coordinador-tecnico` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ4197` |
| Fecha de generación | 2026-08-14 |
| Estado | Validado |
| ID plan (BD) | 36 |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5`) — normal |

---

## 1. Resumen técnico

Habilitar el subítem de menú **"Listado"** (ruta `/Contratos/Contratos`) para el rol Identity **`Coordinador Tecnicos`** en el menú lateral de SIGA Web. El acceso a la vista **ya está autorizado** en `ContratosController`; el faltante es solo de visibilidad en la UI.

- **Arquitectura:** cambio puntual sobre el monolito SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). Sin microservicio, API, ni migración de BD.
- **Stack:** .NET 8 / C#, Razor TagHelpers (`sidebar-item` / `sidebar-subitem`), HTML + jQuery existente. PostgreSQL intacto.
- **Despliegue:** el mismo binario de GarantiplusWeb en los tres hubs (México, Colombia, Chile). El menú es **por archivo de país**, no por configuración en BD.

**Hallazgo técnico (cierra preguntas abiertas del PRD §14):**

| Pregunta PRD | Hallazgo en código (`develop`) |
|---|---|
| ¿Menú por BD (rol → opción)? | **No.** Visibilidad hardcodeada en Razor vía atributo `profiles="Rol1\|Rol2"` de los TagHelpers. |
| ¿Identificador del ítem y ruta? | Subítem `title="Listado"`, `controller="Contratos"`, `action="Contratos"` → `/Contratos/Contratos`. Rol exacto: **`Coordinador Tecnicos`** (sin acento, plural). |
| ¿Configuración compartida o por hub? | **Por hub.** Tres archivos Remake independientes. `_Layout.cshtml` carga `Remake/_LeftMenuBar_{hub}.cshtml` (`mex` / `col` / `chl`). |
| ¿El permiso de la vista ya existe? | **Sí.** `[Authorize]` de clase y de `Index` en `ContratosController` ya incluyen `Coordinador Tecnicos`. |
| ¿México ya lo muestra? | **Sí.** En `_LeftMenuBar_MEX.cshtml` el subítem Listado **no tiene** `profiles`, así que hereda la visibilidad del padre (que ya incluye el rol). |
| ¿Colombia / Chile? | **No muestran Listado.** El padre "Contratos" sí incluye el rol (ven el grupo y "Garantías"); el subítem Listado **omite** `Coordinador Tecnicos`. |

**Implicación:** el cambio es agregar `Coordinador Tecnicos` al `profiles` del subítem **Listado** en COL y CHL. México queda como verificación (sin cambio funcional). No se toca autorización ni el listado de contratos.

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Usuario de prueba con rol **`Coordinador Tecnicos`** en al menos Colombia y Chile (México para confirmar que no hay regresión)
- [ ] Usuario de otro rol (p. ej. Ejecutivo de Ventas / Tecnico) para probar no-regresión
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de navegación/UI sobre el componente de menú existente. Sin servicios nuevos ni ECS.

```
[Coordinador Tecnicos inicia sesión]
  → _Layout.cshtml
      → Remake/_LeftMenuBar_{mex|col|chl}.cshtml
          → <sidebar-item title="Contratos" profiles="…|Coordinador Tecnicos|…">
              → <sidebar-subitem title="Listado" action="Contratos" profiles="…|Coordinador Tecnicos">
  → GET /Contratos/Contratos
      → ContratosController.Index  [Authorize ya incluye Coordinador Tecnicos]
  → Listado existente (sin filtros nuevos por rol)
```

**Decisiones de diseño:**

1. **Solo el menú Remake activo.** `_Layout.cshtml` usa `_LeftMenuBar_*`. Los `_NavigationGPMX_*` son legado (`_LayoutOld`) y **no se modifican** (YAGNI; RF-05: no tocar visibilidad de otros caminos salvo el menú en uso).
2. **No agregar el rol `Tecnico`** al Listado. El PRD es exclusivamente Coordinador Técnico. En COL/CHL, Tecnico sigue viendo Contratos → Garantías, igual que hoy.
3. **No añadir `profiles` en el Listado de México.** Hoy, al no tener `profiles`, cualquier rol del padre ve Listado. Poner lista explícita arriesgaría ocultarlo a algún rol que hoy lo ve (RNF-03).
4. **No tocar `ContratosController` ni filtros de datos.** El PRD lo declara fuera de alcance (RNF-01, RF-03).
5. **Astara Chile** (`_NavigationAstara`, proyecto id=4 en CHL) queda fuera: es un layout especial, no el menú estándar de los tres hubs.

---

## 4. Tareas de desarrollo

### Fase 0 — Rama y confirmación del hallazgo

- [ ] **T-01** — Crear la rama funcional desde `develop`
  - Archivos a crear/modificar: ninguno (solo git)
  - Criterio de completitud: existe `feature/PJ4197-menu-contratos-coordinador-tecnico` en origin, basada en `origin/develop` actualizado

- [ ] **T-02** — Confirmar en runtime que el Coordinador Técnico entra a `/Contratos/Contratos` por URL y que en COL/CHL el menú muestra Contratos sin subítem Listado
  - Archivos a crear/modificar: ninguno
  - Criterio de completitud: evidencia (screenshot o nota) del estado *antes* en COL o CHL; MEX ya muestra Listado

### Fase 1 — Visibilidad del Listado (P1)

- [ ] **T-03** — Incluir `Coordinador Tecnicos` en el `profiles` del subítem Listado de Colombia
  - Archivos a crear/modificar: `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_COL.cshtml`
  - Cambio: en el `<sidebar-subitem title="Listado" … action="Contratos">`, agregar `|Coordinador Tecnicos` al atributo `profiles` existente. No añadir `Tecnico`. No tocar Cotizaciones, Órdenes de pago, Garantías ni el resto de ítems.
  - Criterio de completitud: el string de `profiles` del Listado COL contiene `Coordinador Tecnicos` y el diff no altera otros `profiles`

- [ ] **T-04** — Incluir `Coordinador Tecnicos` en el `profiles` del subítem Listado de Chile
  - Archivos a crear/modificar: `GarantiplusWeb/Views/Shared/Remake/_LeftMenuBar_CHL.cshtml`
  - Cambio: análogo a T-03 sobre el Listado CHL
  - Criterio de completitud: el string de `profiles` del Listado CHL contiene `Coordinador Tecnicos` y el diff no altera otros `profiles`

- [ ] **T-05** — Verificar México sin cambio de código (salvo que QA demuestre que Listado no se ve)
  - Archivos a crear/modificar: ninguno (esperado)
  - Criterio de completitud: `_LeftMenuBar_MEX.cshtml` Listado sigue sin `profiles` (visible vía padre); no hay diff en ese archivo

### Fase 2 — Validación multi-hub (P1)

- [ ] **T-06** — Probar Coordinador Técnico: menú Contratos → Listado abre `/Contratos/Contratos` en Colombia y Chile; México sigue igual
  - Archivos a crear/modificar: ninguno
  - Criterio de completitud: con un usuario solo-rol `Coordinador Tecnicos`, el menú lateral muestra Contratos > Listado; el clic llega al listado existente; no aparecen ítems nuevos (Cotizaciones, Órdenes de pago, etc.)

- [ ] **T-07** — Probar no-regresión de otros roles
  - Archivos a crear/modificar: ninguno
  - Criterio de completitud: un rol que ya veía Listado (p. ej. Ejecutivo de Ventas) lo sigue viendo; un rol que no debía verlo (p. ej. Tecnico en COL/CHL) sigue sin ver Listado; el resto del menú del Coordinador (Averías, Garantías, Reportes) no cambia

---

## 5. Cambios en base de datos *(si aplica)*

No aplica. El menú no se gobierna por tablas; no hay migración ni seed de `AspNetRoles`.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | — | Sin cambios de esquema ni de datos |

---

## 6. Endpoints nuevos o modificados *(si aplica)*

No aplica. Se reutiliza `GET /Contratos/Contratos` (`ContratosController.Index`), ya autorizado para el rol.

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `/Contratos/Contratos` | Listado de contratos (existente) | Sin cambio |

---

## 7. Variables de entorno y configuración *(si aplica)*

No aplica. El menú se selecciona por `Hub` (`mex`/`col`/`chl`) ya existente.

| Variable | Descripción | Ambiente |
|---|---|---|
| — | — | — |

---

## 8. Consideraciones de seguridad

- **No se conceden permisos nuevos.** El rol ya entra a la vista por URL; solo se expone la entrada de menú (RNF-01).
- **Nombre de rol exacto:** `Coordinador Tecnicos`. Un typo (`Coordinador Técnico`, acento, singular) dejaría el ítem invisible.
- **No ampliar `profiles` a `Tecnico`** ni a otros roles (RF-05 / fuera de alcance).
- **No tocar** `[Authorize(Roles = …)]` de `ContratosController` ni de acciones de alta/edición.
- Sin secrets, IAM ni cambios de CORS.

---

## 9. Consideraciones de infraestructura *(si aplica)*

- Sin servicios AWS nuevos. SIGA Web sigue en EC2 (Ubuntu + .NET 8 + Nginx) por consola/país.
- El mismo cambio de vistas viaja en el deploy habitual de GarantiplusWeb a México, Colombia y Chile. No hay feature flag.
- Sin cambios en ECS, RDS, S3, Cloudflare ni Route 53.

---

## 10. Criterios de aceptación

- [ ] **RF-01 / RF-04:** Un usuario con rol `Coordinador Tecnicos` ve "Contratos" → "Listado" en el menú lateral de Colombia, México y Chile.
- [ ] **RF-02:** Al hacer clic en Listado se abre la vista existente `/Contratos/Contratos` (la misma accesible hoy por URL).
- [ ] **RF-03:** El listado no cambia de columnas, filtros ni alcance de datos respecto a otros roles con acceso.
- [ ] **RF-05 / RNF-03:** Ningún otro rol gana o pierde ítems de menú. Tecnico en COL/CHL sigue sin Listado.
- [ ] **RNF-01:** `ContratosController` no se modifica.
- [ ] **RNF-04:** El ítem usa el mismo TagHelper, título "Listado" y posición que los demás roles (primer subítem de Contratos en COL; segundo en CHL, tras Cotizaciones).
- [ ] **RNF-05:** El cambio queda en git en la rama `feature/PJ4197-menu-contratos-coordinador-tecnico`.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Deploy parcial: un hub no recibe el binario nuevo | Baja | Medio | El código es el mismo repo; validar los tres hubs tras el deploy de GarantiplusWeb |
| Typo del nombre de rol → ítem sigue oculto | Baja | Alto | Copiar `Coordinador Tecnicos` tal cual aparece en el padre del mismo archivo |
| QA prueba con layout Astara (CHL proyecto 4) y no ve el cambio | Baja | Bajo | Documentar que Astara usa `_NavigationAstara` y está fuera de alcance |
| Alguien "completa" el `profiles` de Listado MEX y oculta el ítem a un rol actual | Baja | Medio | T-05: no editar `_LeftMenuBar_MEX.cshtml` |
| El solicitante esperaba también el rol Tecnico | Media | Bajo | Fuera de alcance del PRD; si operación lo pide, otro folio |

---

## 12. Notas para el programador

1. **Estado actual por hub (menú Remake, `develop`):**

   | Hub | Padre Contratos incluye el rol | Subítem Listado incluye el rol | Acción |
   |---|---|---|---|
   | México | Sí | Sí (sin `profiles` → visible) | Verificar, no cambiar |
   | Colombia | Sí (ven el grupo + Garantías) | **No** | T-03 |
   | Chile | Sí (ven el grupo + Garantías) | **No** | T-04 |

2. El Coordinador en COL/CHL **ya ve el grupo Contratos** (porque el padre lo incluye), pero solo el subítem **Garantías**. El dolor reportado encaja con "no aparece el listado de contratos" más que con un grupo totalmente ausente.

3. No refactorizar TagHelpers ni unificar los tres `_LeftMenuBar_*`. El PRD pide no rediseñar el menú.

4. Prueba local: cambiar `Hub:HubBaseCountryCode` / `CountryBase` con la skill `siga-cambio-pais-base` para validar COL y CHL; no mezclar diffs de país en esta rama.

5. Ticket de soporte del PRD §14: no hay folio asociado en el condensado PV-01; no bloquear por eso.

---

## 13. Relación de tareas y tiempos

Estimación en **días hábiles** por fase. El PRD no define P2/P3 ni fases posteriores: **todo el alcance es P1**.

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Rama y confirmación** | Rama funcional + evidencia del estado actual | T-01 a T-02 | 0.25 – 0.5 días | 90 |
| **Fase 1 — Visibilidad del Listado (P1)** | `profiles` Listado COL + CHL; verificación MEX | T-03 a T-05 | 0.25 – 0.5 días | 92 |
| **Fase 2 — Validación multi-hub (P1)** | Prueba Coordinador en 3 hubs + no-regresión | T-06 a T-07 | 0.5 – 1 día | 91 |
| **Total proyecto (P1)** | | 7 tareas | ~1 – 2 días hábiles (≈ 0.5 semanas) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 + Fase 2 | T-01 a T-07 | ~1 – 2 días hábiles (≈ 0.5 semanas) | — |

> **Notas sobre la tabla:**
> - No hay P2/P3: el PRD declara que no hay fases posteriores.
> - Los rangos salen de la complejidad real (dos atributos Razor + prueba manual en tres hubs).
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`); no editarla a mano.

> **Riesgo de deadline:** el PRD (2026-08-12) **no fija fecha límite**. Con ~1–2 días hábiles el alcance completo cabe en un solo desarrollador. No se recomienda segundo recurso ni recorte: P1 ya es el 100 % del MVP.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
