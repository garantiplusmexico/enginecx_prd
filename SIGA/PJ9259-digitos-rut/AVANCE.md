# Registro de Avance — Dígitos RUT (Chile)

> Este documento lo actualiza Claude Code automáticamente conforme ejecuta tareas del plan. Si otro compañero retoma el trabajo, debe leer este archivo primero para entender el estado actual.

| Campo | Detalle |
|---|---|
| Plan de origen | `PLAN.md` |
| Repositorio | `gp_4.0_siga` |
| Rama | `feature/PJ9259-digitos-rut` (base: `develop`) |
| Responsable | Javier Antonio Oropeza Camacho |
| Ejecutado por | Javier Antonio Oropeza Camacho (Claude Code) |
| Fecha de inicio | 2026-08-11 |
| Última actualización | 2026-08-14 |
| Fecha de cierre | 2026-08-14 |
| Estado general | ✅ Finalizado — liberado a producción (2026-08-14) |

---

## Resumen de estado

Se implementó el alcance P1 completo (Fases 0 a 2): RUT de Chile pasa a 8–12 caracteres y HP acepta 1 o más dígitos incluido `0`. La causa raíz del bloqueo no era solo el rango de `PaisesService`: el plugin de máscara (`input_mask.js`) **borra el contenido del campo en `blur`** cuando el valor no llena la máscara completa, por lo que ningún RUT de menos de 12 caracteres ni ningún HP de menos de 3 dígitos podía capturarse, independientemente del rango configurado. Se eliminaron esas máscaras fijas en Chile y se reemplazó el formateo del RUT por un formateador de longitud variable.

Compila sin errores (`PaisesService` y `GarantiplusWeb`, 0 errores). El formateador tiene 18 casos verificados. La prueba manual end-to-end en ambiente Chile (T-09) y el smoke MX/CO (T-10) fueron ejecutados y validados por el programador. **Plan finalizado y liberado a producción el 2026-08-14.**

---

## Tareas completadas ✅

| ID | Tarea | Completada por | Fecha | Notas |
|---|---|---|---|---|
| T-01 | Confirmar regla de conteo de RUT y alcance de pantallas | Claude Code | 2026-08-11 | Decisión tomada por análisis de código (ver §Decisiones). No requirió bloqueo. |
| T-02 | Inventario de puntos de validación/máscara RUT y HP | Claude Code | 2026-08-11 | 9 puntos de captura CHL identificados; lista cerrada abajo. |
| T-03 | Rangos y mensajes de RUT en `PaisCL` | Claude Code | 2026-08-11 | `8/12` en dealer y beneficiario. `PaisMX`/`PaisCO` sin tocar. |
| T-04 | Alinear máscaras/inputs de RUT en emisión de contrato Chile | Claude Code | 2026-08-11 | Máscara fija eliminada + nuevo `rut-chl.js`. |
| T-05 | Catálogo de distribuidores (RUT Chile) | Claude Code | 2026-08-11 | `_EditCHL.cshtml` sirve tanto a `Create` como a `Edit`. |
| T-06 | Consistencia flag fiscal / backend Chile | Claude Code | 2026-08-11 | `IsEnabledFiscalIdValidation() => false`. |
| T-07 | Eliminar longitud fija de HP en emisión especial Chile | Claude Code | 2026-08-11 | Máscara `999` eliminada; regla `entero` ya permitía `0`. |
| T-08 | Verificar Create / cotizador Chile para HP | Claude Code | 2026-08-11 | Sin cambios necesarios: no tenían máscara fija. |
| T-09 | Prueba manual Chile (matriz RUT/HP de §10 del plan) | Javier Antonio Oropeza Camacho | 2026-08-14 | Validada por el programador. |
| T-10 | Smoke MX y CO (no regresión) | Javier Antonio Oropeza Camacho | 2026-08-14 | Sin regresión detectada. |

---

## Tareas pendientes ⏳

Ninguna. **Plan finalizado y liberado a producción el 2026-08-14.**

> Verificación estática de no-regresión ya hecha: ningún archivo de MX/CO/PER fue modificado; los dos archivos compartidos que se tocaron cambian solo dentro de ramas exclusivas de Chile (ver §Decisiones, punto 6).

---

## Tareas bloqueadas 🔴

| ID | Tarea | Motivo del bloqueo | Quién debe resolverlo |
|---|---|---|---|
| — | — | Ninguna | — |

---

## Decisiones tomadas durante la ejecución

| # | Decisión | Justificación | Impacto |
|---|---|---|---|
| 1 | **La máscara fija era el bloqueo real, no el rango.** Se elimina `data-mask="99.999.999-w"` (RUT) y `data_mask="999"` (HP) en Chile en lugar de solo relajar el rango. | `input_mask.js` (jasny inputmask v3.1.0) ejecuta `checkVal()` en `blur`, y si el valor no llena la máscara hace `this.$element.val("")`. El campo se vaciaba solo. Además la agrupación fija 2-3-3 no puede representar un RUT de 7 dígitos: forzaba `12.345.67-8` en vez de `1.234.567-8`. | Sin esto, cambiar `PaisCL` a 8–12 no habría desbloqueado nada. Riesgo §11 del plan ("máscara sigue forzando 12 chars") confirmado como real. |
| 2 | **Conteo del RUT: caracteres del valor con formato** (puntos y guion), como hoy. | Recomendación §12 del plan. Mantiene consistencia con los registros ya almacenados en 12 caracteres. | El rango 8–12 cubre cuerpos de 5 a 8 dígitos: `12.345-6` (8), `123.456-7` (9), `1.234.567-8` (11), `12.345.678-9` (12). Cubre los RUT chilenos reales (7 y 8 dígitos) que hoy se rechazan. |
| 3 | **Formateador nuevo alineado a la derecha** (`GarantiplusWeb/wwwroot/js/pages/contratos/rut-chl.js`), reemplazando el bloque inline de `Create.cshtml`. | El formateador que existía en `Create.cshtml` estaba cableado a exactamente 8 dígitos + verificador: truncaba a 9 caracteres y agrupaba desde la izquierda, así que con un RUT de 7 dígitos perdía el dígito verificador. El nuevo toma el último carácter como verificador y agrupa el cuerpo de 3 en 3 desde la derecha, lo que funciona para cualquier longitud. | Normaliza el formato almacenado en todas las pantallas CHL, de modo que la búsqueda por RUT sigue encontrando los contratos. La validación de longitud **no** se movió: sigue en el `rangelength` alimentado por `PaisCL`. |
| 4 | **`IsEnabledFiscalIdValidation() => false` en `PaisCL`.** | El flag no valida nada: su único consumidor es `ViewBag.ValidarRFC`, que habilita `calculaRFC()`. Esa función llama `CalculaRFCPersonaFisica` → `PaisCL.GenerateRFC` → `RFC.BuildRfc` (algoritmo **mexicano**) y **sobrescribe el RUT capturado** al cambiar nombre, apellidos o fecha de nacimiento. Era un bug activo en Chile. `AR`, `CO` y `PE` ya retornan `false`. | Emisión Chile deja de sobrescribir el RUT. No se agregó validación estructural ni dígito verificador (fuera de alcance por PRD §6). |
| 5 | **HP sin máximo de longitud.** Solo se quita la máscara; la regla `entero` existente ya acepta `>= 0`. | Recomendación §12 del plan. `entero` es `parseInt(value)==parseFloat(value) && parseInt(value)>=0`. No se tocó pricing. | HP acepta `0`, `5`, `99`, `450` y más dígitos. |
| 6 | **Alcance: los 9 puntos de captura de RUT de Chile**, no solo beneficiario y dealer. | T-01 dejaba abierto si cotizador/endosos/asesores entraban. Todos usaban la **misma** máscara fija, así que dejar alguno sin tocar solo reubica el bloqueo: un RUT de 11 caracteres emitido en contratos no se podría cotizar, endosar ni **buscar**. | Incluye `IndexCHL.cshtml` (búsqueda por RUT), que **no** estaba listado en el plan. Se agregó porque los RUT nuevos, más cortos, serían imposibles de buscar. Si el responsable prefiere excluirlo, es un cambio de 3 líneas. |
| 7 | Se dejó sin tocar `Asesores/_Edit.cshtml:288`, que aún tiene la máscara vieja. | Está dentro de un bloque Razor comentado (`@*` línea 186 → `*@` línea 323): es código muerto. | Ninguno. Si ese bloque se reactiva algún día, hay que aplicarle el mismo cambio que a la línea 154. |

---

## Archivos creados o modificados

| Archivo | Tipo de cambio | Tarea |
|---|---|---|
| `PaisesService/Classes/CL/PaisCL.cs` | Modificado | T-03, T-06 |
| `GarantiplusWeb/wwwroot/js/pages/contratos/rut-chl.js` | **Creado** | T-04 |
| `GarantiplusWeb/Areas/Contratos/Views/Contratos/_BeneficiarioCHL.cshtml` | Modificado | T-04 |
| `GarantiplusWeb/Areas/Contratos/Views/Contratos/Create.cshtml` | Modificado | T-04 (elimina formateador inline obsoleto) |
| `GarantiplusWeb/Areas/Catalogos/Views/Distribuidores/_EditCHL.cshtml` | Modificado | T-05 |
| `GarantiplusWeb/Areas/Contratos/Views/Cotizador/CreateCHL.cshtml` | Modificado | T-04b |
| `GarantiplusWeb/Areas/Contratos/Views/Endosos/_BeneficiaryEndorsementCHL.cshtml` | Modificado | T-04b |
| `GarantiplusWeb/Areas/Contratos/Views/Endosos/_TransferEndorsementCHL.cshtml` | Modificado | T-04b |
| `GarantiplusWeb/Areas/Contratos/Views/Contratos/IndexCHL.cshtml` | Modificado | T-04b |
| `GarantiplusWeb/Areas/Catalogos/Views/Asesores/_Edit.cshtml` | Modificado | T-04b |
| `GarantiplusWeb/Areas/Contratos/Views/Contratos/_DatosVehiculoEmEspecialCHL.cshtml` | Modificado | T-07 |

> Los `appsettings.json` modificados en el árbol de trabajo son configuración local de Chile del desarrollador (`HubBaseCountryCode=CHL`, base `garantiplus_chile_db`) y **no** se incluyeron en ningún commit.

---

## Inventario de puntos de captura de RUT en Chile (T-02)

| Pantalla | Archivo | Rango desde `PaisCL` | Estado |
|---|---|---|---|
| Emisión de contrato — beneficiario | `Contratos/_BeneficiarioCHL.cshtml` | Sí (`Create.cshtml` vía `CountryConfiguration`) | ✅ |
| Emisión especial — beneficiario | mismo partial, desde `EmisionEspecial.cshtml` | **No** — esta vista no cablea el `rangelength` del RUT | ✅ máscara quitada |
| Emisión especial — HP | `Contratos/_DatosVehiculoEmEspecialCHL.cshtml` | N/A (regla `entero`) | ✅ |
| Distribuidores alta y edición | `Distribuidores/_EditCHL.cshtml` | Sí (`Create.cshtml` / `Edit.cshtml`) | ✅ |
| Cotizador | `Cotizador/CreateCHL.cshtml` | No | ✅ |
| Endoso de beneficiario | `Endosos/_BeneficiaryEndorsementCHL.cshtml` | No | ✅ |
| Endoso de transferencia | `Endosos/_TransferEndorsementCHL.cshtml` | No | ✅ |
| Búsqueda de contratos por RUT (×2) | `Contratos/IndexCHL.cshtml` | No | ✅ |
| Asesores | `Catalogos/Asesores/_Edit.cshtml` línea 154 | No | ✅ |

**Hallazgo para el responsable:** `EmisionEspecial.cshtml` nunca aplicó el `rangelength` del RUT que viene de `PaisesService` (a diferencia de `Create.cshtml`). Ahí la única validación del RUT es `required`. No se agregó el `rangelength` porque ampliaría el alcance del MVP, pero significa que **en emisión especial no hay validación de longitud de RUT** — ni antes ni ahora. Vale decidir si se cablea en una tarea aparte.

---

## Verificación ejecutada

| Verificación | Resultado |
|---|---|
| `dotnet build PaisesService/PaisesService.csproj` | 0 errores (84 advertencias preexistentes) |
| `dotnet build GarantiplusWeb/GarantiplusWeb.csproj` | 0 errores (1172 advertencias preexistentes). Incluye compilación de Razor, por lo que las 9 vistas editadas quedan validadas sintácticamente. |
| Formateador `rut-chl.js` — 18 casos | Todos pasan: progresión al teclear, repegado de valor ya formateado, verificador `K`, entrada vacía, entrada no numérica, recorte al máximo |
| Longitudes resultantes vs rango 8–12 | Cuerpos de 5 a 8 dígitos aceptados; cuerpo de 4 dígitos rechazado (por debajo del mínimo, correcto) |
| Archivos de MX/CO/PER modificados | Ninguno |
| Bloques `.nit-col` / `.ced-col` de Colombia en `Create.cshtml` | Intactos |

---

## Matriz de prueba manual pendiente (T-09 / T-10)

Ambiente Chile (`CountryBase=CHILE`, `Hub:HubBaseCountryCode=CHL`):

| Caso | Esperado |
|---|---|
| RUT beneficiario `12.345-6` (8 car.) | Acepta |
| RUT beneficiario `1.234.567-8` (11 car.) | Acepta, **el campo no se vacía al salir** |
| RUT beneficiario `12.345.678-9` (12 car.) | Acepta |
| RUT `1.234-5` (7 car.) | Rechaza con *"El RUT debe tener entre 8 y 12 caracteres"* |
| RUT con verificador `K` | Acepta y formatea |
| Cambiar nombre/apellidos del beneficiario | El RUT capturado **no** se sobrescribe (regresión de `calculaRFC`) |
| HP `0` en emisión especial | Acepta, el campo no se vacía |
| HP `5`, `99`, `450` | Acepta |
| Alta y edición de distribuidor con RUT de 9 car. | Acepta |
| Búsqueda por RUT de 9 car. en índice de contratos | Encuentra el contrato |
| Post del contrato completo | Backend no rechaza el valor |

Smoke MX y CO: RFC/NIT conservan sus rangos y mensajes; HP sin cambios de comportamiento.

---

## Notas para quien retome el trabajo

- **Por dónde continuar:** levantar el ambiente Chile y correr la matriz de arriba. No queda código pendiente del alcance P1.
- **Contexto clave:** el mecanismo del bug es el `blur` del plugin de máscara, no la validación de longitud. Si aparece otro campo que "no deja capturar valores cortos" en cualquier país, buscar primero `data-mask` / `data_mask` en la vista.
- **Decisiones que conviene confirmar con el responsable:**
  1. Inclusión de `IndexCHL.cshtml` (búsqueda) en el alcance — no estaba en el plan (decisión 6).
  2. Que 8–12 se cuente **con** formato y no solo dígitos (decisión 2). Si negocio quiere contar solo dígitos, el rango tendría que ser 6–9 y hay que ajustar `PaisCL` y los `maxlength`.
  3. Si se cablea el `rangelength` del RUT en `EmisionEspecial.cshtml`, hoy ausente.
- **Fuera de alcance, confirmado no implementado:** dígito verificador / `ValidateRFC` estructural, cambios en MX/CO, rediseño de UI, cambios de pricing por HP.

---

*Actualizado automáticamente por Claude Code — Engine CX*
