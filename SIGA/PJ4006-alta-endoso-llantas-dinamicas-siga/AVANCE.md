# Registro de Avance — Alta y endoso de llantas dinámicas en SIGA web

> Actualizado por Claude Code conforme ejecuta el plan. Quien retome el trabajo debe leer este archivo primero.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `feature/cc_llantas_dinamicas_siga` (sin ticket ECX asignado) |
| Responsable actual | Carlos Castellanos |
| Última actualización | 2026-07-17 |
| Estado general | 🟢 Implementación COMPLETA (validada en local MEX); falta multi-país + deploy |

---

## Resumen de estado

**Feature COMPLETA e implementada en la rama `feature/cc_llantas_dinamicas_siga`** (creación + detalle + Emisión Especial + endoso). Validado end-to-end en local (MEX): contrato de llantas creado (795185) y endosado (marca/modelo/medida/DOT por N líneas). Falta: multi-país (COL/CHL), pruebas formales y el deploy QA→PROD (responsabilidad del usuario).

El rediseño de front (Tailwind + TagHelpers) ya está en `develop` y mergeado a la feature. La UI de llantas (alta y endoso) usa tarjetas por registro estilo BS, con **1 DOT por registro** + cantidad.

---

## Tareas completadas ✅ (commiteadas)

| Commit | Contenido |
|---|---|
| `49f899d` | T-01: `ContractTireLimitsOptions` (tope `MaxPerContract=100`) + `AddApplicationOptions` + appsettings |
| (merge) `4c1a857` | Merge de `develop` (rediseño) a la feature |
| `16e87d9` | T-04+T-05: alta de contrato con lista dinámica (Create.cshtml + controller `Create` → sobrecarga de lista + validación de tope) |
| `9c87119` | T-5c: sección de llantas (solo lectura) en el detalle del contrato (Details.cshtml) |
| `cd0adcb` + `565995b` | T-5b: refactor de la UI de llantas a partials compartidos (`_LlantasDinamicas` + `_LlantasDinamicasScripts`); Emisión Especial **bloquea** productos de llanta (aviso + Guardar deshabilitado); `_DatosTipoProducto` con "Tipo de producto" fuera de `.garantia_grupo`; `_DatosLlantas.cshtml` borrado |
| `4954953` | T-06→T-09: **endoso de llantas por N líneas** (SOLO edición de datos, 1 DOT/registro). Proto aditivo (`repeated lineas`, campos planos conservados); microservicio `TireLinesEndorsement` (update parametrizado por id_llantas/id_dot + auditoría por línea, verificado adversarialmente + 4 fixes); controller reutiliza `informacion_llantas`/`dot_llanta`; vistas Tailwind (modal editable + panel + detalle); Kestrel por config (`Kestrel_`→`Kestrel`); flag `Endosos:Llantas=true` |

**Decisión clave de UI:** el listado dinámico vive en 2 partials compartidos (markup + JS con `TIRES_MAX` vía `@inject`). Modelo por fila = un `informacion_llantas` (marca/modelo/medida + `numero_llantas`=Cantidad) con un DOT replicado `Cantidad` veces. Binding `informacion_llantas[i].*` + `dots[i]`, índices secuenciales.

**Emisión Especial:** NO soporta llantas (estaba pensada para vehículos; `poliza.garantia_fabrica.Value` truena con llantas). Se bloquea con aviso; backend revertido a original.

---

**Endoso (decidido y aplicado):** SOLO edición de datos (marca/modelo/medida/DOT), **sin agregar/quitar líneas, sin cambiar cantidad, sin recalcular precio** — como en producción hoy. **1 DOT por registro** (igual que el alta; el DOT editado se aplica a todas las `dot_llanta` de la línea, solo si cambió). Emisión Especial NO soporta llantas (backend revertido a original).

---

## Pendiente ⏳ — deploy y multi-país (responsabilidad del usuario)

| Tema | Detalle |
|---|---|
| Compilar/regenerar | Recompilar `Endosos` + `GarantiplusWeb` (+ `ElsaServer`) para regenerar tipos gRPC. Proto **aditivo** → deploy tolerante al orden. |
| Deploy | `feature/cc_llantas_dinamicas_siga` → pre-qa → qa → release → main (skill deploy). Desplegar `Endosos` + SIGA Web (coordinado, tolerante). QA: override `Kestrel__Endpoints__Http__Url` en el task-def. |
| T-10 multi-país | Confirmar que COL/CHL tengan las tablas (`informacion_llantas`/`dot_llanta` + `endoso_contrato`/`ajuste_endoso`). El microservicio usa SQL crudo contra la BD del país (sin cambio de esquema). Chile vía switch de país base. |
| Decisiones abiertas | Valor real del tope (hoy 100), formato/regex de DOT, ticket ECX (rama sin ticket) — ver Preguntas abiertas del PRD. |

---

## Notas para quien retome

- Commits incrementales, **con aprobación del responsable antes de cada commit** (regla del proyecto).
- git corre con `dangerouslyDisableSandbox` (el sandbox no puede escribir `.git/HEAD`).
- NO commitear la config local: `PDFGenerator/appsettings.json`, `FacturacionGarantiplus/appsettings.json`, `GarantiplusWeb/Program.cs` (país base del responsable).
- `Ventas.Core` (huérfano) NO compila — deuda vieja, no bloquea `GarantiplusWeb`; compilar por proyecto, no `gpmx_web.sln` completo.
- Pendiente aparte: estructura jerárquica de `CLAUDE.md` en `gp_4.0_siga`.

---

*Actualizado por Claude Code — Engine CX*
