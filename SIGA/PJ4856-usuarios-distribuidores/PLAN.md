# Plan de Desarrollo — Usuarios relacionados por distribuidor (PJ4856)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/SIGA/PJ4856-usuarios-distribuidores/PRD.md` |
| Repositorio | `gp_4.0_siga` (SIGA Web — GarantiplusWeb) |
| Rama base | `develop` |
| Rama | `feature/PJ4856-usuarios-distribuidores` |
| Tipo | Feature |
| Responsable | Alejandro Govea Hernandez |
| Folio PRD | `PJ4856` |
| Fecha de generación | 2026-07-24 |
| Estado | Borrador |
| ID plan (BD) | 27 |
| Modelo / esfuerzo | Claude Opus 4.8 (`claude-opus-4-8`) — normal |

---

## 1. Resumen técnico

Agregar en el **detalle de distribuidor** de SIGA Web una sección de **solo lectura** que liste **todos** los usuarios relacionados vía `usuario_distribuidor`, con columnas **UserName** y **nombre**, visible únicamente para **Administrador General**, **Gestor de Países** y **Auditor**.

- **Arquitectura:** modificación puntual sobre monolito existente SIGA Web (EC2 + .NET 8 + Razor/MVC Areas). Sin microservicio nuevo ni API REST nueva.
- **Stack:** .NET 8 / C#, Razor Views, Identity roles, PostgreSQL (sin migración).
- **Alcance de código:** principalmente UI (`_GeneralesDistribuidor.cshtml`) + verificación de que el include de usuarios en `GetDealerDetails` cubre el caso; sin escritura sobre la relación.

**Hallazgo técnico (cierra supuesto del PRD §5 / RF-01):**

| Afirmación del PRD | Hallazgo en código |
|---|---|
| Extender `GetAllUsers` con join a `usuario_distribuidor` | `GetAllUsers` (`CatalogosBusinessRules`) ya incluye `"distribuidores", "distribuidores.distribuidor"`, pero sirve al **catálogo de usuarios**, no al detalle de distribuidor. |
| Falta join para el detalle | `GetDealerDetails` / `GetDealerDetailsSalesRole` (p. ej. `PaisesService/Classes/MX/PaisMX.cs`) **ya cargan** `usuarios`, `usuarios.usuario` y roles. |
| Panel no muestra usuarios distribuidores | `_GeneralesDistribuidor.cshtml` solo lista **Gerente Comercial** y **Ejecutivo de Ventas** (por filtro de rol). El resto de usuarios relacionados (p. ej. `Usuario Distribuidor`, `Vendedor`) no se muestran. |

**Decisión de diseño del plan:** el MVP **no** requiere extender `GetAllUsers`. Se reutiliza `Model.usuarios` ya hidratado en Details y se agrega una card de lectura con gate por rol en la vista. Extender `GetAllUsers` queda fuera de alcance salvo que Operaciones pida filtrar el catálogo de usuarios por distribuidor (fase posterior).

---

## 2. Prerequisitos

- [ ] PRD validado por el responsable / solicitante (revisión: Alexis Salvador Herrera Garcia)
- [ ] Acceso al repositorio `gp_4.0_siga` confirmado
- [ ] Rama `develop` actualizada (completado al generar este plan — up to date con `origin/develop`)
- [ ] `CLAUDE.md` presente en el repositorio ✅
- [ ] Ambiente local con proyecto/distribuidor de prueba que tenga varios usuarios en `usuario_distribuidor` (idealmente roles distintos a Gerente/Ejecutivo)
- [ ] Usuario de prueba Admin / Gestor / Auditor y al menos un rol **no** autorizado (p. ej. Ejecutivo de Ventas) para validar RF-03
- [ ] No se requieren secrets ni variables de entorno nuevas

---

## 3. Arquitectura del cambio

Se respeta la arquitectura monolítica de SIGA Web (`rules/arquitectura.md`): feature de UI sobre componente existente, sin desplegar servicio nuevo.

```
[Admin / Gestor / Auditor]
  → GET Catalogos/Distribuidores/Details/{id}
      → IDealersBusinessRules.GetDealerDetails (incluye usuarios.usuario)
          → PostgreSQL.usuario_distribuidor ⋈ aspnetusers
      → View Details → Partial _GeneralesDistribuidor
          → Card "Usuarios relacionados" (solo si rol autorizado)
              → tabla UserName | nombre  (solo lectura)
```

**Decisiones de diseño:**

1. **Fuente de datos:** `Model.usuarios` (`usuario_distribuidor` → `usuario`). Columnas: `usuario.UserName` y `usuario.nombre` (fallback a `usuario_distribuidor.nombre` si `usuario`/`nombre` viniera vacío).
2. **Alcance de la lista:** **todos** los registros en `Model.usuarios` del distribuidor, no solo Gerente/Ejecutivo. Las cards existentes de Gerentes/Ejecutivos se **conservan** (no se eliminan en el MVP).
3. **Control de acceso (RF-03 / RNF-01):** renderizar la nueva card solo si  
   `User.IsInRole("Administrador General") || User.IsInRole("Gestor de Países") || User.IsInRole("Auditor")`.  
   Roles que hoy pueden ver Details pero **no** deben ver esta lista: Ejecutivo de Ventas, Gerente Comercial, Vendedor, Administrador General Externo (salvo que Operaciones confirme incluir Externo — ver §12).
4. **Solo consulta (RF-04):** sin botones, sin formularios, sin endpoints POST de asociación.
5. **Rendimiento (RNF-02):** no hay query adicional; los includes ya existen. Contenedor con `max-height` + scroll (patrón de Asesores) si hay muchos usuarios. Sin paginación en MVP (pregunta abierta PRD §14).
6. **Orden por defecto:** `UserName` ascendente (cerrar pregunta abierta de orden).
7. **Sin cambios de BD / infra / env.**

**Fuera de alcance (confirmado por PRD):** asociar/desasociar, editar usuario, filtros/búsqueda avanzada, roles distintos a Admin/Gestor/Auditor, cambios en API SIGA (`gp_3.0_siga_api`).

---

## 4. Tareas de desarrollo

### Fase 0 — Verificación y rama (P1)

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comandos: `git checkout develop && git pull origin develop && git checkout -b feature/PJ4856-usuarios-distribuidores`
  - Archivos a crear/modificar: ninguno (solo Git)
  - Criterio de completitud: rama local creada desde `develop` actualizado

- [ ] **T-02** — Confirmar includes de usuarios en todos los países usados
  - Verificar que `GetDealerDetails` en las clases de país relevantes al despliegue (mínimo `PaisMX`; si el hub activo es otro, la clase correspondiente) incluye `usuarios` + `usuarios.usuario`
  - Si algún país usado en producción carece del include, homogeneizar solo ese include (sin refactor)
  - Archivos a revisar: `PaisesService/Classes/*/Pais*.cs` (`GetDealerDetails`), `ClientsService` si delega
  - Criterio de completitud: nota en AVANCE de países verificados; Details con `Model.usuarios` no nulo y navegación a `usuario` disponible

### Fase 1 — UI de usuarios relacionados y permisos (P1)

- [ ] **T-03** — Agregar card «Usuarios relacionados» en el detalle
  - En `_GeneralesDistribuidor.cshtml`, debajo o junto a Gerentes/Ejecutivos: card con tabla columnas **UserName** y **Nombre**
  - Iterar `Model.usuarios` ordenado por `usuario.UserName`
  - Estado vacío: mensaje breve tipo «No hay usuarios relacionados» (o no mostrar card si count = 0 — preferir mensaje visible para Admin/Gestor/Auditor)
  - Contenedor scrollable (`max-height` ~300px) si hay muchos registros
  - Sin acciones de edición/asociación
  - Archivos: `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/_GeneralesDistribuidor.cshtml`
  - Criterio de completitud: con rol autorizado se ven todos los usuarios de `usuario_distribuidor` del distribuidor, no solo Gerente/Ejecutivo

- [ ] **T-04** — Restringir visibilidad por rol (RF-03)
  - Envolver la card con `User.IsInRole` para `Administrador General`, `Gestor de Países`, `Auditor`
  - No alterar el `[Authorize]` del action `Details` (otros roles siguen viendo el detalle general)
  - Archivos: `_GeneralesDistribuidor.cshtml` (y `Details.cshtml` solo si se limpia código muerto de gerentes/ejecutivos no usado — opcional, no requerido)
  - Criterio de completitud: Ejecutivo/Gerente/Vendedor abren Details y **no** ven la card; Admin/Gestor/Auditor sí

- [ ] **T-05** — Prueba manual de aceptación
  - Distribuidor con ≥2 usuarios de roles distintos; comparar lista vs. query BD / catálogo Usuarios
  - Verificar UserName + nombre correctos; solo lectura; sin regresión en Gerentes/Ejecutivos/Formas de pago
  - Archivos: ninguno (evidencia en AVANCE)
  - Criterio de completitud: checklist §10 marcado; sin errores en consola/UI

### Fase 2 — Cierre (documentación de avance)

- [ ] **T-06** — Actualizar `AVANCE.md` y cerrar fase
  - Copiar §13 a AVANCE; marcar tareas hechas; registrar desviaciones (p. ej. si se incluyó Admin Externo)
  - Archivos: `enginecx_prd/SIGA/PJ4856-usuarios-distribuidores/AVANCE.md` (al ejecutar el plan)
  - Criterio de completitud: AVANCE refleja estado real listo para PR del programador

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| — | Ninguno | Solo lectura de `usuario_distribuidor` / `aspnetusers` existentes |

---

## 6. Endpoints nuevos o modificados

| Método | Ruta | Descripción | Estado |
|---|---|---|---|
| GET | `Catalogos/Distribuidores/Details/{id}` | Sin cambio de contrato; misma vista, más sección condicional | Sin cambio de endpoint |

No se agregan endpoints JSON/API. Si en el futuro se necesitara AJAX paginado, sería un POST/GET dedicado con `[Authorize(Roles=...)]` estricto (fuera de MVP).

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| — | No aplica | — |

---

## 8. Consideraciones de seguridad

- Autorización por **rol Identity** en la vista (misma convención que el botón Modificar/Desactivar en el mismo partial).
- No exponer listado completo a roles comerciales que ya pueden abrir Details.
- Solo lectura: no hay superficie de escritura nueva.
- No registrar PII adicional en logs; no se añaden logs específicos (RNF-05).
- Secrets: no aplica.

---

## 9. Consideraciones de infraestructura

- Sin cambios en ECS, RDS, S3, Cloudflare ni Route 53.
- Despliegue: mismo pipeline / EC2 de SIGA Web existente.
- Sin costo AWS adicional.

---

## 10. Criterios de aceptación

- [ ] Al abrir Details de un distribuidor, Admin / Gestor / Auditor ven la lista de usuarios relacionados con **UserName** y **nombre**
- [ ] La lista incluye **todos** los vinculados en `usuario_distribuidor`, no solo Gerente Comercial / Ejecutivo de Ventas
- [ ] Roles no autorizados (p. ej. Ejecutivo de Ventas) **no** ven esa sección
- [ ] No hay UI ni acción para asociar, desasociar o editar usuarios desde esa vista
- [ ] Las secciones existentes (Gerentes, Ejecutivos, Formas de pago, etc.) siguen funcionando
- [ ] Sin migración de BD ni variables de entorno nuevas
- [ ] Sin degradación perceptible del detalle (sin query extra)

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Distribuidor con muchos usuarios: lista larga | Media | Bajo | `max-height` + scroll; paginación diferida (§14 PRD) |
| Datos inconsistentes en `usuario_distribuidor` / `usuario` null | Baja | Medio | Null-safe en vista; fallback a `nombre` de la relación |
| `Administrador General Externo` queda fuera y Operaciones lo necesitaba | Media | Bajo | Confirmar en §12; agregar un `IsInRole` si lo piden |
| PRD pide extender `GetAllUsers` y se espera ese cambio en code review | Media | Bajo | Documentar hallazgo en plan/AVANCE; reutilizar `Model.usuarios` |

---

## 12. Notas para el programador

1. **No refactorizar** `GetAllUsers` ni el catálogo de Usuarios en este MVP.
2. Roles exactos en código (nombres Identity): `"Administrador General"`, `"Gestor de Países"`, `"Auditor"` — alinear con el PRD («Admin/Gestor/Auditor»).
3. **Confirmar con Operaciones/Alexis:** ¿incluir `"Administrador General Externo"` en la visibilidad de la lista? Hoy Details lo autoriza; el PRD no lo nombra. Default del plan: **no incluir**.
4. `Details.cshtml` declara variables `gerentes`/`ejecutivos` que el partial vuelve a calcular; no limpiar en este ticket salvo que sea trivial y sin riesgo.
5. Multi-país: el cambio es en vista compartida; aplica a todos los países del hub. Validar al menos en el país base del ambiente del dev.
6. Preguntas abiertas del PRD (§14) **cerradas para MVP:** sin filtros/búsqueda; orden `UserName` ASC; columnas solo UserName + name; sin paginación.

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Verificación y rama (P1)** | Rama + verificación de includes `GetDealerDetails` | T-01 a T-02 | 0.25 – 0.5 días | 49 |
| **Fase 1 — UI y permisos (P1)** | Card usuarios relacionados + gate por rol + prueba manual | T-03 a T-05 | 0.5 – 1 día | 50 |
| **Fase 2 — Cierre** | AVANCE / evidencias | T-06 | 0.25 días | 51 |
| **Total proyecto** | | 6 tareas | ~1 – 1.75 días hábiles (≈ &lt; 1 semana) | — |
| **Solo P1 (guardarraíl del PRD)** | Fase 0 + Fase 1 | T-01 a T-05 | ~0.75 – 1.5 días hábiles | — |

> **Riesgo de deadline:** el PRD no fija fecha límite dura; el alcance es solo lectura y acotado. Con un desarrollador el MVP cabe cómodo en 1–2 días hábiles. No se requiere segundo recurso. Si se reabre el alcance hacia `GetAllUsers` filtrado o paginación, sumar ~0.5–1 día.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 4.8 (`claude-opus-4-8`) — esfuerzo: normal*
