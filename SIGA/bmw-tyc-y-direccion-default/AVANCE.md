# Registro de Avance — BMW: quitar el T&C de carátula negra y neutralizar la dirección por defecto

> Este documento lo actualiza Claude Code conforme ejecuta tareas del plan. Si otro compañero retoma
> el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Rama | `bugfix/bmw-tyc-y-direccion-default` — **local en los dos repos, sin push** (el responsable revisa antes) |
| Responsable actual | Juan Carlos Castellanos Solis |
| Folio PRD | *(sin asignar — no hay PRD; ver §12 nota 1 del plan)* |
| ID plan (BD) | *(no registrado — decisión explícita del responsable)* |
| Última actualización | 2026-08-27 |
| Estado general | 🟡 En progreso |
| Modelo / esfuerzo | `claude-opus-5` — esfuerzo normal |

---

## Resumen de estado

**Código terminado y verificado; nada commiteado ni empujado, por instrucción del responsable.**
Fases 0, 1 y 2 completas: la landing ya no publica el T&C, y el domicilio por defecto de BMW quedó
neutralizado en `appsettings.json` sin tocar Bridgestone. El typecheck de la landing pasa limpio.
La Fase 3 (validación en QA) **no puede ejecutarse todavía**: requiere que los cambios estén
desplegados. El texto genérico es el que Aldo escribió en su correo — `"Para posición únicamente"` —
así que de **T-01** solo sigue abierto el **alcance**: si esperaba que también desaparecieran colonia,
CP y estado, esto lo resuelve a medias.

---

## Relación de tareas y tiempos (seguimiento)

| Fase | ID (BD) | Tareas | Días est. (rango) | Fecha inicio | Fecha fin | Días ejecutados | Días restantes | Estatus |
|---|---|---|---|---|---|---|---|---|
| **Fase 0 — Confirmaciones previas** | — | T-01 a T-02 | 0.5 – 1 | 2026-08-27 | 2026-08-27 | 0.5 | 0 | ✅ Completada *(T-01 con el alcance aún abierto)* |
| **Fase 1 — Landing: quitar el T&C (P1)** | — | T-03 a T-06 | 0.5 | 2026-08-27 | 2026-08-27 | 0.5 | 0 | ✅ Completada *(sin T-06: commit no autorizado)* |
| **Fase 2 — API: dirección por defecto** | — | T-07 a T-10 | 0.5 | 2026-08-27 | 2026-08-27 | 0.5 | 0 | ✅ Completada *(sin T-10: commit no autorizado)* |
| **Fase 3 — Validación en QA** | — | T-11 a T-13 | 0.5 – 1 | | | 0 | 0.5 – 1 | 🔴 Bloqueada — requiere despliegue |
| **Total proyecto** | — | 13 tareas | ~2 – 3 | 2026-08-27 | | 1.5 | 0.5 – 1 | 🟡 En progreso |
| **Solo P1 (mínimo entregable)** | — | T-03 a T-06 | ~0.5 | 2026-08-27 | 2026-08-27 | 0.5 | 0 | ✅ Completada |

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-02 | Verificar que `appsettings.json` es la fuente efectiva en QA y PROD | Claude Code | 2026-08-27 | **Sin overrides.** Revisadas las dos task definitions: los únicos `Address` son `Grpc__PDFService__Address` y `Grpc__InvoicesService__Address`, ajenos al domicilio. **Riesgo R-2 descartado** |
| T-03 | Eliminar el enlace "T&C (PDF)" del listado de contratos | Claude Code | 2026-08-27 | Quitado el `<li>`, el import y actualizado el comentario del componente |
| T-04 | Limpiar el catálogo de PDFs estáticos y borrar el archivo | Claude Code | 2026-08-27 | `mockContractDocuments.ts` tenía **un solo consumidor**: quedó sin uso y se eliminó entero en lugar de dejar código muerto. `public/docs/` queda vacío |
| T-05 | Subir la versión de la landing | Claude Code | 2026-08-27 | `v1.0.19` → `v1.0.20` en los tres `.env` |
| T-07 | Cambiar los valores del domicilio por defecto de BMW | Claude Code | 2026-08-27 | `Address` y `Colony` = `"Para posición únicamente"`. Solo 2 líneas del bloque BMW. Guardarraíl automático en el script: aborta si toca Bridgestone. Verificado que BS sigue con "Sierra Candela 80". JSON revalidado y BOM preservado |
| T-08 | Verificar que ningún otro punto hornee la dirección | Claude Code | 2026-08-27 | Cero literales en C#. Fuera de `appsettings.json`, solo aparece en una colección Postman de Omega (documentación, no producción) |
| T-09 | Subir la versión del servicio `Contracts` | Claude Code | 2026-08-27 | → `v0.28` en los 4 lugares. **No v0.27**: ver decisiones |

## Tareas completadas bajo supuesto ⚠️

| ID | Tarea | Fecha | Notas |
|---|---|---|---|
| T-01 | Confirmar con Aldo el alcance de la "dirección por defecto" | 2026-08-27 | **Texto resuelto con el propio correo**, sin esperar respuesta: Aldo ofreció dos ejemplos y el segundo sí es viable ⇒ `Address` y `Colony` = `"Para posición únicamente"` (24 caracteres, cumple el mínimo de 5). **Sigue abierto** el alcance: solo se neutralizó calle y colonia, los ids de catálogo quedan intactos |

---

## Tareas pendientes ⏳

| ID | Tarea | Bloqueada por (si aplica) |
|---|---|---|
| T-06 | Commit 1 (landing) | El responsable quiere revisar antes de commitear |
| T-10 | Commit 2 (API) | Ídem |
| T-11 | Validar el cambio 1 en QA | Requiere despliegue |
| T-12 | Validar el cambio 2 de punta a punta en QA (Física y Moral) | Requiere despliegue + resolver R-4 |
| T-13 | Responder el hilo de correo | Conviene hacerlo ya, aunque sea acuse de recibo |

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| T-12 | Validación end-to-end en QA | El deploy de `gp_3.0_siga_api` a QA está detenido esperando aprobación de la **PR #283** (Chile/Colombia) | El responsable (Claude no aprueba PRs) |

---

## Decisiones tomadas durante la ejecución

| Decisión | Justificación | Impacto |
|---|---|---|
| **Eliminar `src/constants/mockContractDocuments.ts` completo**, no solo la entrada `terminos` | Su único consumidor era el enlace de T&C. Sin él, el módulo entero (`MOCK_CONTRACT_PDF` y `mockContractPdfHref`) quedaba sin uso. Las entradas `contrato`/`odp` ya estaban marcadas en el propio archivo como "solo referencia" porque el API real las provee | Un archivo menos en lugar de código muerto. `pnpm lint` confirma que no quedaron imports huérfanos |
| **Versión del servicio `Contracts` = `v0.28`, no `v0.27`** | `v0.26` ya está construida y en QA; `v0.27` está reservada por el despliegue de Chile/Colombia, ya mergeado en `pre-qa` con la PR #283 pendiente. Reusar una etiqueta **sobreescribe la imagen en el ECR en silencio** | Evita el riesgo R-4. Provoca un conflicto previsible en `build.ps1` al mergear a `pre-qa`: resolver quedándose con `v0.28` |
| **Corregir el estado obsoleto de `build.ps1` en `develop`** y trasladar el comentario de advertencia | `develop` seguía en `v0.24 → v0.25` mientras QA ya iba en `v0.26`: construir desde ahí habría sobreescrito la **v0.25 que referencia PROD**. El aviso existía solo en `pre-qa` | Cierra un pie de fallo real y silencioso en la rama base |
| **No neutralizar `PostalCode`, `StateId`, `MunicipalityId` ni `ColonyId`** | Los tres ids son llaves de catálogo obligatorias (`[Required]`, `Range(1..)`); el CP es `[Required]` con mínimo 5 caracteres y se usa en el ámbito fiscal | El contrato seguirá mostrando CP 11000 / CDMX. **Es el riesgo R-5 y sigue vivo**: si Aldo quería el domicilio completo neutralizado, hace falta su confirmación (T-01) |
| **Usar `"Para posición únicamente"` y no `"FPO"`** | Son los **dos ejemplos que dio Aldo en su correo**. "FPO" no es viable: `BeneficiaryInfoRequest.Address` declara `MinimumLength = 5` y son 3 caracteres — además es jerga que el cliente final no entiende. El segundo ejemplo cumple la longitud y se lee en español | Cero cambios de código, y el texto es literalmente el que pidió el solicitante: no requiere validación adicional |

---

## Archivos creados o modificados

### `bmw_landing` — rama `bugfix/bmw-tyc-y-direccion-default`

| Archivo | Tipo de cambio | Tarea |
|---|---|---|
| `src/lib/registrationDocuments.tsx` | Modificado | T-03 |
| `src/constants/mockContractDocuments.ts` | **Eliminado** | T-04 |
| `public/docs/Terminos y condiciones BMW.pdf` | **Eliminado** (5 MB) | T-04 |
| `.env`, `.env.qa`, `.env.production` | Modificados | T-05 |

### `gp_3.0_siga_api` — rama `bugfix/bmw-tyc-y-direccion-default`

| Archivo | Tipo de cambio | Tarea |
|---|---|---|
| `Services/Contracts/appsettings.json` | Modificado (2 líneas, solo bloque BMW) | T-07 |
| `Services/Contracts/build.ps1` | Modificado | T-09 |
| `Infrastructure/local/docker-compose.yml` | Modificado | T-09 |
| `Infrastructure/qa/deploy-services-v2.ps1` | Modificado | T-09 |
| `Infrastructure/prod/deploy-services-v2.ps1` | Modificado | T-09 |

---

## Commits realizados

*(ninguno — el responsable pidió revisar antes de commitear)*

---

## Verificaciones ejecutadas

| Verificación | Resultado |
|---|---|
| `pnpm lint` (typecheck, única verificación automática del repo) | ✅ Sin errores |
| Bridgestone intacto en `appsettings.json` | ✅ Sigue con "Sierra Candela 80" |
| `appsettings.json` parsea como JSON válido y conserva el BOM UTF-8 | ✅ Sí; el diff son exactamente 2 líneas |
| Overrides de la dirección en task definitions de QA/PROD | ✅ No existen |
| Referencias huérfanas a `/docs/` o `public/docs` | ✅ Ninguna |
| Literales de dirección en código C# | ✅ Ninguno |

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** revisar los dos diffs, autorizar los commits (T-06 y T-10) y desplegar.
  Las ramas existen **solo en local**, en los dos repos.
- **Lo que no se pudo hacer:** la Fase 3 completa. La validación real —que el PDF del contrato ya no
  diga "Sierra Candela 80", en Física **y** en Moral— solo se puede hacer con los cambios desplegados.
  Hasta entonces el cambio 2 está implementado pero **no verificado**.
- **Decisión pendiente del solicitante (T-01):** el **texto** ya no está en duda — es el que Aldo
  escribió en su correo. Lo que sigue abierto es el **alcance**: si "la dirección" para él incluía
  también colonia, CP y estado, esto lo resuelve a medias, porque los ids de catálogo son
  obligatorios. Vale la pena preguntárselo al responderle el correo.
- **`PLAN.md` quedó desfasado en un detalle:** su T-01 documenta el supuesto `"NO APLICA"`, anterior
  a releer el correo. Lo implementado es `"Para posición únicamente"`. Actualizar el plan si se
  quiere dejar consistente (implica un commit más a `enginecx_prd`).
- **Trampa a la vista:** al mergear a `pre-qa` habrá conflicto en `Services/Contracts/build.ps1`
  contra el despliegue de Chile/Colombia. Resolver **quedándose con `v0.28`**; nunca reusar `v0.27`.
- **Urgencia:** Alexis pidió esto para el 26-ago. Aunque no se despliegue hoy, conviene acusar recibo
  en el hilo "Modificación BMW".

---

*Actualizado automáticamente por Claude Code — Engine CX*
