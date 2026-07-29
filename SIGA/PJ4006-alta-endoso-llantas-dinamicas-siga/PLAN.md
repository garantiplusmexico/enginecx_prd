# Plan de Desarrollo — Alta y endoso de llantas dinámicas en SIGA web (estilo Bridgestone)

> Generado por Claude Code a partir de `PRD.md`. Punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | `enginecx_prd/alta-endoso-llantas-dinamicas-siga/PRD.md` |
| Repositorio | `gp_4.0_siga` |
| Rama base | `develop` (posicionado y actualizado el 2026-07-08) |
| Rama funcional | `feature/ECX-XXX-llantas-dinamicas-siga` (ECX-XXX por asignar) |
| Tipo | Feature / Mejora sobre sistema existente |
| Responsable | Carlos Castellanos |
| Fecha de generación | 2026-07-08 |
| Estado | Borrador |

---

## 1. Resumen técnico

Se convierte la captura de llantas de SIGA web (`GarantiplusWeb`) de una estructura fija (1 marca/modelo/medida + 4 DOT) a una **lista dinámica estilo Bridgestone** (`Marca/Modelo/Medida/DOT/Cantidad` por fila, agregar/quitar, tope 20). El cambio abarca **dos superficies**:

- **Creación de contrato**: el almacenamiento (`poliza → informacion_llantas → dot_llanta`) y el servicio `VentasService.CreateContract(IReadOnlyList<TireContractLine>)` **ya soportan N líneas**; el trabajo es UI + ViewModel como lista + cablear el controller a la sobrecarga de lista + validación de tope.
- **Endoso/modificación**: la ruta gRPC (`TiresEndorsementRequest` con `DotLlanta1..4`) y el microservicio `Endosos` (endosos atómicos `EndosoLlantaDotUno..Cuatro`) están **cableados a 4** y se rehacen para operar sobre la colección completa (add/update/delete de líneas y DOTs).

**Arquitectura:** se respeta la existente (monolito SIGA Web en EC2 + microservicio `Endosos` vía gRPC). **Stack:** .NET Core 8 / C# (backend), Razor + HTML/jQuery (frontend SIGA), PostgreSQL (sin cambio de esquema). No se introduce arquitectura nueva. Código nuevo sigue `coding-guidelines.md` (inglés, `IOptions<T>`, ≤200 líneas/archivo, mensajes de usuario en español, logs en inglés).

---

## 2. Prerequisitos

- [x] PRD validado por el responsable
- [x] Acceso al repositorio confirmado (`gp_4.0_siga`)
- [x] Rama base `develop` posicionada y actualizada
- [ ] **`CLAUDE.md` ausente en `gp_4.0_siga`** — el responsable pidió estructura jerárquica: un `CLAUDE.md` raíz orquestador + uno por proyecto (`GarantiplusWeb`, `PaisesServices`, `Endosos`, `VentasService`, etc.). Es un entregable propio, separado de este plan; se recomienda generarlo antes de una ejecución asistida amplia.
- [ ] Ticket `ECX-XXX` asignado para nombrar la rama y los commits
- [ ] Confirmar valor de negocio del tope (`MaxPerContract = 20`) y si difiere por país
- [ ] Confirmar reglas de DOT (regex/formato) — ver Riesgos y Preguntas abiertas del PRD

---

## 3. Arquitectura del cambio

Se mantiene la arquitectura vigente; no se crea ningún servicio nuevo (`rules/arquitectura.md` → "código existente no se modifica salvo solicitud; features respetan la estructura actual").

```
[GarantiplusWeb (Razor/jQuery) ]
   creación → ContratosController → VentasService.CreateContract(IReadOnlyList<TireContractLine>)
                                        → informacion_llantas (1 fila/línea) + dot_llanta (N)
   endoso   → EndososController → gRPC TiresEndorsementRequest(repeated líneas)
                                        → microservicio Endosos → informacion_llantas/dot_llanta (add/update/delete)
```

Modelo por fila (contrato full-BS): cada fila = un `informacion_llantas` (`marca`, `modelo`, `medida`, `numero_llantas = Cantidad`) con **un** `dot_llanta` (DOT compartido por las N llantas de esa cantidad, semántica idéntica a BS).

---

## 4. Tareas de desarrollo

### Fase 1 — Backend de creación: tope configurable + validación

- [ ] **T-01** — Crear `Options` de límites de llantas en SIGA web (espejo de `ContractTireLimitsOptions` de `gp_3.0_siga_api`).
  - Archivos: nuevo `GarantiplusWeb/Options/ContractTireLimitsOptions.cs` (`MinPerContract`, `MaxPerContract=20`); registrar en `Program.cs`/`Startup` con `GetSection("ContractTireLimits")`; agregar sección a `GarantiplusWeb/appsettings*.json`.
  - Criterio: `IOptions<ContractTireLimitsOptions>` inyectable; valor 20 leído de config sin hardcode.

- [ ] **T-02** — Validar la suma de cantidades contra el tope al crear/editar contrato de llantas.
  - Archivos: `VentasService/src/Ventas.Domain/Classes/VentasBusinessRules.cs` (o en `ContratosController` antes de invocar el servicio); mensaje de error al usuario en español.
  - Criterio: crear con suma > 20 se rechaza con mensaje claro; ≤ 20 pasa. Cubre línea única y múltiples líneas.

### Fase 2 — UI de creación dinámica

- [ ] **T-03** — Convertir el ViewModel de llantas a lista.
  - Archivos: `GarantiplusWeb/Areas/Contratos/Models/ContratoViewModel.cs:11` (de `informacion_llantas` único a `List<>` de líneas de llanta con `Marca/Modelo/Medida/Dot/Cantidad`).
  - Criterio: el modelo soporta N filas; compila.

- [ ] **T-04** — Reemplazar el bloque fijo de llantas por filas dinámicas en la vista de creación.
  - Archivos: `Areas/Contratos/Views/Contratos/Create.cshtml` (sección "Datos de la Garantía de Llanta", ~170-244; eliminar/ajustar `MostrarDots()` ~2679 y los `required` ~1148-1151) y el partial `Areas/Contratos/Views/Contratos/_DatosLlantas.cshtml` (usado también en `EmisionEspecial.cshtml:74`).
  - JS: reutilizar el patrón idiomático de Averías `Areas/Averias/Views/RefaccionesPermitidas/Create.cshtml` (`addSpare`/`deleteSpare`, binding `coleccion[KEY].prop` + `coleccion.Index`). Botón "Agregar llanta", borrar por fila (deshabilitar borrar si queda 1). Aviso de tope 20 antes de enviar (RNF/UX).
  - Criterio: se pueden agregar/quitar filas; cada fila captura Marca/Modelo/Medida/DOT/Cantidad; el POST envía la colección indexada.

- [ ] **T-05** — Cablear el controller a la sobrecarga de lista existente.
  - Archivos: `Areas/Contratos/Controllers/ContratosController.cs` (`Create` ~1406-1430, `Edit` ~2477+): bindear la lista de filas y mapear a `IReadOnlyList<TireContractLine>`; invocar `VentasBusinessRules.CreateContract(..., tireContractLines, ...)` (`VentasBusinessRules.cs:399-469`, interfaz `IVentasBusinessRules.cs:31-35`).
  - Criterio: un contrato con N líneas persiste N `informacion_llantas` + sus `dot_llanta`; el pricing sigue funcionando (`BuildAggregatedTiresInfoForPricing`).

### Fase 3 — Backend de endoso (gRPC + microservicio Endosos)

- [ ] **T-06** — Rediseñar el contrato gRPC de endoso de llantas.
  - Archivos: `Protos/Endosos.proto` (`TiresEndorsementRequest` ~122-140): sustituir `dot_llanta_1..4`/`id_dot_1..4`/marca/modelo/medida únicos por una **lista repetida** de líneas (`repeated TireLine`: `id_llanta`, `marca`, `modelo`, `medida`, `cantidad`, `repeated Dot { id_dot, dot }`), más `request_user`, `request_reason`, `id_contrato`.
  - Criterio: proto compila; clientes/servidor regeneran tipos sin `Dot1..4`.

- [ ] **T-07** — Rehacer la aplicación del endoso sobre la colección completa (add/update/delete).
  - Archivos: `Endosos/Services/EndososService.cs`, `Endosos/Vehiculo/EndosoLlantas.cs`, `Endosos/Models/ContratoLlantas.cs`, `DotsLlantas.cs`, `Endosos/Interfaces/IContratoLlantas.cs`; generalizar/retirar los atómicos fijos `EndosoLlantaDotUno..Cuatro.cs` y `EndosoLlantaMarca/Modelo/Medida.cs`.
  - Lógica: diff entre líneas existentes y entrantes → altas, bajas y ediciones de `informacion_llantas`/`dot_llanta`; conservar auditoría (solicitante, motivo) en el seguimiento de endosos; aplicar tope 20 (Options equivalente en el servicio Endosos o validación compartida).
  - Criterio: endoso que agrega, elimina y edita filas deja el contrato consistente (todo o nada, RNF-04) y auditado.

### Fase 4 — UI de endoso dinámica

- [ ] **T-08** — Cargar N líneas en el modal de endoso.
  - Archivos: `Areas/Contratos/Controllers/EndososController.cs` (`LoadTiresView` ~762-786) para proyectar **todas** las líneas del contrato; vista de solo lectura `Areas/Contratos/Views/Contratos/Endorsements/_Tire.cshtml`.
  - Criterio: contratos con >4 DOT y contratos previos (≤4) se cargan sin error (RNF-02).

- [ ] **T-09** — Formulario de endoso con filas dinámicas y envío de lista.
  - Archivos: `Areas/Contratos/Views/Endosos/_TiresEndorsement.cshtml` (reemplazar `DotLlanta1..4` por filas dinámicas + JS `updateTires()`), `Edit.cshtml` (`editTires()` ~291-294); `EndososController.EndosoLlantas` (~788-817) para armar el `TiresEndorsementRequest` con la lista.
  - Criterio: agregar/quitar/editar filas en el endoso persiste correctamente vía gRPC; conserva Solicitante/Motivo.

### Fase 5 — Multi-país, consistencia y pruebas

- [ ] **T-10** — Verificar espejo `DataAccess` ↔ `DataAccessColombia` y comportamiento en MEX/COL/CHL.
  - Archivos: entidades `informacion_llantas.cs`/`dot_llanta.cs` en `DataAccess` y `DataAccessColombia` (solo lectura salvo que se toque algún mapeo, entonces replicar). Confirmar que CHL corre sobre el contexto vía switch de país base.
  - Criterio: alta y endoso funcionan en los tres países; sin divergencia de modelos.

- [ ] **T-11** — Pruebas end-to-end de creación y endoso (ver §10).
  - Criterio: todos los criterios de aceptación cumplidos.

> Ejecución con commits incrementales: implementar tarea → validar → commit → push → siguiente (no batchear). El responsable compila/reinicia los proyectos; Claude no corre `dotnet build/run`, solo avisa cuándo compilar.

---

## 5. Cambios en base de datos

**Ninguno.** El esquema `poliza → informacion_llantas (1:N) → dot_llanta (1:N)` ya soporta N líneas y N DOTs. Sin migraciones.

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `informacion_llantas` / `dot_llanta` | Solo lectura | Se reutilizan tal cual (MEX y COL). |

---

## 6. Endpoints / contratos modificados

| Tipo | Ruta / mensaje | Descripción | Estado |
|---|---|---|---|
| MVC POST | `Contratos/Contratos/Create` y `.../Edit` | Reciben lista de líneas de llanta en vez de objeto único + `string[] dots` | Modificado |
| MVC GET | `Contratos/Endosos/LoadTiresView/{id}` | Proyecta N líneas | Modificado |
| MVC POST | `Contratos/Endosos/EndosoLlantas` | Envía lista de líneas al gRPC | Modificado |
| gRPC | `TiresEndorsement` / `TiresEndorsementRequest` | `repeated TireLine` con DOTs anidados | Modificado (breaking en el proto) |

---

## 7. Variables de entorno y configuración

| Variable / sección | Descripción | Ambiente |
|---|---|---|
| `ContractTireLimits:MinPerContract` | Mínimo de llantas por contrato (default 1) | Desarrollo / QA / Producción |
| `ContractTireLimits:MaxPerContract` | Máximo de llantas por contrato (**20**) | Desarrollo / QA / Producción |

Sin secrets nuevos. Todo en `appsettings*.json` (ajustable sin recompilar, RNF-01).

---

## 8. Consideraciones de seguridad

- Sin cambios de IAM/AWS. Autorización existente de contratos/endosos se mantiene.
- Validar y sanear todas las filas en backend (no confiar en el front); consultas EF parametrizadas (ya lo son).
- Mensajes de error visibles al usuario en **español**; logs técnicos en inglés.
- Sin secrets en código.

---

## 9. Consideraciones de infraestructura

- No hay nuevos servicios AWS. SIGA Web sigue en EC2; `Endosos` sigue como microservicio gRPC.
- El cambio de `Endosos.proto` implica **regenerar y redesplegar** cliente (SIGA Web) y servidor (`Endosos`) de forma coordinada (el proto es breaking).

---

## 10. Criterios de aceptación

- [ ] En creación, se pueden capturar > 4 llantas con marca/modelo/medida/DOT/cantidad por fila y se guardan como N `informacion_llantas` + `dot_llanta`.
- [ ] Se puede agregar y quitar filas; con 1 fila el botón de borrar se deshabilita.
- [ ] La suma de cantidades > 20 se rechaza en backend con mensaje en español; ≤ 20 se acepta.
- [ ] DOT obligatorio por fila; marca/modelo/medida requeridos; cantidad ≥ 1.
- [ ] El endoso carga todas las líneas existentes (incluye contratos previos ≤ 4 DOT sin error).
- [ ] El endoso permite agregar, eliminar y editar filas y persiste consistente y auditado (solicitante/motivo).
- [ ] Funciona en MEX, COL y CHL.
- [ ] El pricing de llantas sigue calculando correctamente.

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Cambio breaking en `Endosos.proto` desincroniza cliente/servidor | Media | Alto | Desplegar `Endosos` y SIGA Web de forma coordinada; versionar el mensaje si se requiere convivencia. |
| Rehacer los endosos atómicos (Dot1..4) rompe auditoría/seguimiento | Media | Alto | Mantener el registro por cambio en el seguimiento; pruebas de add/update/delete con verificación en BD. |
| Contratos previos con estructura ≤4 no cargan en el endoso nuevo | Media | Medio | Cargar líneas de forma genérica (N); prueba explícita con contrato viejo (RNF-02). |
| Desincronización `DataAccess` ↔ `DataAccessColombia` | Baja | Medio | Replicar cualquier toque de modelo/mapeo en ambos contextos. |
| Interfaz espejo `Ventas.Core` vs `Ventas.Domain` | Baja | Medio | Si se toca la interfaz, replicar en `Ventas.Core/Interfaces/Sales/IVentasBusinessRules.cs`. Nota: `Ventas.Core` tiene deuda de compilación previa (no bloquea `GarantiplusWeb`). |
| Chile sin `DataAccessChile` propio | Baja | Medio | Confirmar que CHL tiene el esquema y usa el contexto vía switch de país base. |

---

## 12. Notas para el programador

- El backend de **creación** ya está listo (sobrecarga de lista en `VentasService`); el grueso del trabajo nuevo es **UI + validación de tope + endoso completo (proto + microservicio)**.
- Semántica confirmada en el PRD: **1 DOT por fila**, `Cantidad` = cuántas llantas comparten ese DOT (igual que BS). El "Número de llantas" no se autocalcula; cada `Cantidad` se captura por fila.
- Referencia de UI: `bridgestone_landing/src/features/warranty-registration/sections/TiresSection.tsx`. Referencia de validación de tope: `gp_3.0_siga_api/Services/Contracts` (`ContractTireLimitsOptions`, `BridgestoneLandingContractRequestFactory`).
- Validar antes de ejecutar: valor del tope (20), reglas de formato de DOT, y si el endoso debe recalcular precio/póliza (Pregunta abierta del PRD).
- Prerequisito pendiente: estructura jerárquica de `CLAUDE.md` en `gp_4.0_siga`.

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`, y `PRD.md`*
