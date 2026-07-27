# Plan de Desarrollo — Flags ODP/Pasarela por modalidad + renombre del acceso a SIGA (BMW)

> Generado por Claude Code a partir del PRD correspondiente.
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/bmw-desactivar-odp-enganche/PRD.md` (v0.2) |
| Repositorios | `gp_3.0_siga_api` (Contracts) · `bmw_landing` |
| Rama | `feature/cc_bmw_payment_flow_flags` (misma en ambos repos) |
| Rama base | `develop` (existe y actualizada en ambos repos) |
| Tipo | Feature (mejora sobre proyecto existente) |
| Responsable | Carlos Castellanos |
| Fecha de generación | 2026-07-09 |
| Estado | Validado |

---

## 1. Resumen técnico

Se introduce una **matriz de flags booleanos por modalidad de pago** (Contado, Enganche, Financiado) que gobierna, en la creación de contratos BMW, si se genera la Orden de Pago (ODP) y —solo para Contado— si se habilita la pasarela. El mecanismo de generación (`CreatePaymentOrderAsync`, `ApplyContadoBeneficiaryBillingAsync`, etc.) **no cambia**: cada bloque se envuelve en un `if (flag)`.

- **Backend** (`gp_3.0_siga_api` / servicio Contracts, .NET 8): nueva clase de Options bindeada desde `appsettings` (patrón idéntico a `BmwPaymentOrderOptions`), registro en `Program.cs`, y condicionamiento de los bloques de ODP/pasarela en `BmwController`.
- **Frontend** (`bmw_landing`, React 19 + TS + Vite): renombre del enlace "Ir a SIGA" → "Sistema de Gestión de Garantías" en dos vistas, y verificación de que un Enganche sin ODP no rompe el listado.

Arquitectura sin cambios: microservicio existente en ECS + Fargate; landing SPA que consume la API. No hay BD, endpoints ni infraestructura nueva.

**Estado inicial de los flags:** Enganche `GenerateOdp=false` (objetivo del cambio), Financiado `GenerateOdp=false` (cableado, preparado), Contado `GenerateOdp=true` + `EnableGateway=true` (comportamiento actual).

---

## 2. Prerequisitos

- [x] PRD validado por el responsable (v0.2)
- [x] Acceso a ambos repositorios confirmado
- [x] `CLAUDE.md` presente en ambos repos (generado en esta sesión)
- [x] Rama `develop` existe y está actualizada en ambos repos
- [x] Nombre de rama definido: `feature/cc_bmw_payment_flow_flags` (sin ticket, por decisión del responsable)
- [x] Sin variables de entorno/secrets nuevos requeridos

---

## 3. Arquitectura del cambio

Se respeta la arquitectura de microservicios existente (`rules/arquitectura.md`): el cambio vive dentro del servicio `Contracts` ya desplegado, sin nuevos componentes.

```
Landing BMW ──POST /bmw/.../contracts──▶ Contracts (BmwController)
                                              │
                          ┌───────────────────┼───────────────────┐
                          ▼                   ▼                    ▼
                  [flags: Contado]    [flags: Enganche]    [flags: Financiado]
                   GenerateOdp?        GenerateOdp?          GenerateOdp?
                   EnableGateway?          (false)              (false)
                          │                   │                    │
                          ▼                   ▼                    ▼
                CreatePaymentOrderAsync / ApplyContadoBeneficiaryBillingAsync (sin cambios)
```

Los valores de los flags se leen vía `IOptions<BmwPaymentFlowOptions>` desde `appsettings` (configurable por ambiente, sin hardcode — `rules/coding-guidelines.md` §11 y patrón de Options existente).

---

## 4. Tareas de desarrollo

### Fase 1 — Configuración (Options + registro + appsettings)

- [ ] **T-01** — Crear las clases de Options de flujo de pago BMW
  - Archivos a crear:
    - `Services/Contracts/Options/BmwPaymentFlowOptions.cs` — sección `BmwPaymentFlow`, `SectionName = "BmwPaymentFlow"`. **Una sola clase con props booleanas planas** (decisión del responsable): `ContadoGenerateOdp`, `ContadoEnableGateway`, `EngancheGenerateOdp`, `FinanciadoGenerateOdp`. La pasarela solo existe para Contado, por eso no hay `EnableGateway` para Enganche/Financiado.
  - Detalle: **defaults en `false`** (fail-safe RNF-02); el comportamiento de producción se fija explícitamente en `appsettings` (T-03). XML docs en inglés. Una clase pública por archivo (coding-guidelines §3).
  - Criterio de completitud: compila; documenta qué controla cada flag y que la pasarela solo aplica a Contado.

- [ ] **T-02** — Registrar las Options en el contenedor DI
  - Archivos a modificar: `Services/Contracts/Program.cs` (junto al bloque ~L194 de `BmwPaymentOrderOptions`).
  - Detalle: `builder.Services.Configure<BmwPaymentFlowOptions>(builder.Configuration.GetSection(BmwPaymentFlowOptions.SectionName));`
  - Criterio de completitud: la app resuelve `IOptions<BmwPaymentFlowOptions>` sin excepción.

- [ ] **T-03** — Agregar la sección de configuración en appsettings
  - Archivos a modificar: `Services/Contracts/appsettings.json` (y `appsettings.Development.json` si se quieren defaults distintos en local).
  - Contenido:
    ```json
    "BmwPaymentFlow": {
      "ContadoGenerateOdp": true,
      "ContadoEnableOpenPay": true,
      "EngancheGenerateOdp": false,
      "FinanciadoGenerateOdp": false
    }
    ```
  - Detalle: QA/PROD pueden sobrescribir por task-def de ECS con env vars (convención `BmwPaymentFlow__EngancheGenerateOdp=true`, etc.) sin tocar código — ver §7.
  - Criterio de completitud: la sección existe con los valores acordados; reactivar la ODP del Enganche = cambiar `false→true` aquí (o vía env var).

### Fase 2 — Lógica condicional en la creación de contratos

- [ ] **T-04** — Inyectar las Options
  - Archivos a modificar: `Services/Contracts/Controllers/BmwController.cs` (constructor ~L54-60, campos ~L36-42).
  - Detalle: inyectar `IOptions<BmwPaymentFlowOptions>` y guardar `.Value` en un campo (p. ej. `_paymentFlow`). Con la clase de props planas no hace falta resolver por modalidad: cada rama lee su flag directo (`_paymentFlow.EngancheGenerateOdp`, etc.). El alias `"Financiamiento"` ya cae en la rama de Financiado (lógica existente), así que usa `FinanciadoGenerateOdp` ahí.
  - Criterio de completitud: el controlador tiene acceso a los flags; compila.

- [ ] **T-05** — Condicionar los bloques de ODP y pasarela
  - Archivos a modificar: `Services/Contracts/Controllers/BmwController.cs` (rama post-creación ~L1705-1807).
  - Detalle:
    - **Contado**: envolver `ApplyContadoBeneficiaryBillingAsync` + timbrado + habilitación de pasarela en `if (_paymentFlow.ContadoEnableOpenPay)`; envolver la ODP alterna (`CreatePaymentOrderAsync`, ~L1730-1746) en `if (_paymentFlow.ContadoGenerateOdp)`.
    - **Enganche**: mantener `ApplyDealerBillingAsync` sin condición; envolver el bloque de ODP (~L1779-1798) en `if (_paymentFlow.EngancheGenerateOdp)` (default `false` → deja de generarse).
    - **Financiado**: mantener `ApplyFinancingBillingAsync`; **agregar** una llamada `CreatePaymentOrderAsync` (idéntica a la de Enganche) dentro de `if (_paymentFlow.FinanciadoGenerateOdp)` (default `false` → no genera, pero queda cableada).
  - No refactorizar el resto del flujo (coding-guidelines: no tocar código existente fuera del alcance). Conservar el manejo best-effort actual (try/catch, logs).
  - Criterio de completitud: con los defaults, crear un contrato de Enganche NO genera ODP y conserva facturación al distribuidor; Contado se comporta igual que hoy; Financiado igual que hoy pero con la ODP lista para activarse por flag.

### Fase 3 — Landing (renombre + verificación)

- [ ] **T-06** — Renombrar el acceso a SIGA
  - Archivos a modificar:
    - `src/features/warranty-registration/views/LandingView.tsx` (~L205): `Ir a SIGA` → `Sistema de Gestión de Garantías`.
    - `src/features/warranty-registration/views/DocumentsView.tsx` (~L96): `<span>Ir a SIGA</span>` → `<span>Sistema de Gestión de Garantías</span>`.
  - Detalle: solo cambia el texto visible; el `href` (`getSigaWebUrl()`) no se toca. Texto confirmado: **"Sistema de Gestión de Garantías"** (sin "Ir a").
  - Criterio de completitud: ambos enlaces muestran el nuevo texto y siguen apuntando a SIGA.

- [ ] **T-07** — Verificar el listado de contratos sin ODP
  - Archivos a revisar (sin modificar salvo hallazgo): `src/features/warranty-registration/views/CreatedContractsView.tsx`.
  - Detalle: confirmar que un contrato de Enganche sin ODP no muestra enlaces de descarga de ODP (`hasOdp` = false) ni errores, y que la pasarela sigue limitada a Contado.
  - Criterio de completitud: `pnpm lint` (`tsc --noEmit`) sin errores; revisión visual del flujo de Enganche en el listado.

---

## 5. Cambios en base de datos

No aplica. El cambio no altera esquema ni datos (RNF-03).

---

## 6. Endpoints nuevos o modificados

No hay endpoints nuevos ni cambios de contrato. Se modifica el comportamiento interno del endpoint existente de creación de contratos BMW (`POST` en `BmwController`), sin cambiar su request/response.

---

## 7. Variables de entorno y configuración

| Variable | Descripción | Ambiente |
|---|---|---|
| `BmwPaymentFlow:ContadoGenerateOdp` | Genera la ODP alterna en Contado (default `true`) | Todos |
| `BmwPaymentFlow:ContadoEnableOpenPay` | Habilita la pasarela OpenPay en Contado (default `true`) | Todos |
| `BmwPaymentFlow:EngancheGenerateOdp` | Genera la ODP del Enganche (default `false`) | Todos |
| `BmwPaymentFlow:FinanciadoGenerateOdp` | Genera la ODP del Financiado (default `false`) | Todos |

- En `appsettings.json` como sección `BmwPaymentFlow` (T-03).
- Override por ambiente en el **task-def de ECS** con la convención de doble guion bajo: `BmwPaymentFlow__EngancheGenerateOdp`. No requiere secrets (son flags no sensibles).

---

## 8. Consideraciones de seguridad

- No hay endpoints ni policies nuevas; la autorización del endpoint de creación no cambia.
- No hay secrets nuevos: los flags no son datos sensibles.
- No se registran datos sensibles adicionales en logs (se conserva el logging best-effort actual).

---

## 9. Consideraciones de infraestructura

- Sin nuevos servicios AWS. El cambio se despliega con el redeploy normal del contenedor `Contracts` en ECS + Fargate y el build de la landing (`pnpm build production`).
- La reactivación futura de la ODP (Enganche/Financiado) o de la pasarela de Contado se hace por configuración (appsettings o env var del task-def) + reinicio del servicio, **sin cambio de código**.

---

## 10. Criterios de aceptación

- [ ] Crear un contrato de Enganche con la config por defecto **no genera ODP** y conserva `tipo_facturacion = "Distribuidor"`.
- [ ] Poner `BmwPaymentFlow:Enganche:GenerateOdp=true` reactiva la generación de la ODP del Enganche sin cambios de código.
- [ ] Contado sigue generando ODP alterna y habilitando pasarela (sin regresión).
- [ ] Financiado sigue sin generar ODP; al poner su flag en `true`, la genera.
- [ ] Con config faltante/incompleta, el default es NO generar (fail-safe) para Enganche/Financiado.
- [ ] El enlace a SIGA muestra "Sistema de Gestión de Garantías" en login y en /documentos, apuntando al mismo destino.
- [ ] Un Enganche sin ODP no muestra enlaces de descarga de ODP en el listado ni provoca errores.
- [ ] `pnpm lint` (landing) sin errores; el servicio Contracts compila.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Config faltante en QA/PROD deje flags en default inesperado | Media | Medio | Documentar la sección en `appsettings.json` de base y en el task-def; criterio de aceptación de fail-safe; validar en QA antes de PROD. |
| Alias "Financiamiento" vs "Financiado" no mapee al flag correcto | Media | Medio | `ResolveModalityFlow` trata ambos como Financiado; probar creación con ambas etiquetas. |
| Contratos de Enganche previos con ODP en QA generen confusión al probar | Baja | Bajo | El cambio aplica a contratos nuevos; documentar y, si hace falta, limpiar casos de prueba (pregunta abierta del PRD). |
| Convergencia de ramas del feature BMW (guard temporal) | Baja | Bajo | Trabajar desde `develop` actualizado; no tocar el guard `GuardStrayLandingServices`. |

---

## 12. Notas para el programador

- **Dos repos, una rama por repo** con el mismo nombre `feature/cc_bmw_payment_flow_flags`. Los PRs los gestiona el programador (Claude Code no crea PRs); flujo estándar `feature → pre-qa → qa`.
- **Decisiones de negocio ya cerradas** (del PRD): Enganche mantiene facturación al distribuidor; la pasarela solo aplica a Contado; la ODP manual hacia BMW queda fuera de alcance.
- **Defaults fail-safe**: se decidió que las Options tengan default `false` y que `appsettings` fije explícitamente los valores de producción (Contado en `true`). Validar que la sección quede completa en todos los ambientes.
- **Preguntas abiertas: todas cerradas.** (1) Contratos Enganche con ODP en QA → se dejan como están (aplica solo a nuevos). (2) Identificación para ODP manual → sin acción ahora; los datos ya existen (modalidad/fecha_pago/estatus/fecha de creación) y a futuro podría hacerse un reporte en SIGA (fuera de alcance). (3) Texto del enlace → "Sistema de Gestión de Garantías".
- **No ejecutar builds automáticos**: el desarrollador compila/reinicia el servicio Contracts él mismo. Claude Code solo debe editar y, en la landing, correr `pnpm lint` para el typecheck.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
