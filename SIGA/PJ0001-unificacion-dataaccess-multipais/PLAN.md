# Plan de Desarrollo — Unificación del DataAccess multi-país (PJ0001)

> Generado por Claude Code a partir del análisis técnico del monorepo `gp_4.0_siga` y del diff de las 3 bases de datos (sesión 2026-08-18).
> Este documento es el punto de partida para la ejecución. El programador lo valida y refina antes de ejecutar.

| Campo | Detalle |
|---|---|
| PRD de origen | ⚠️ **No aplica.** Este plan nace de un análisis técnico, no de un PRD de negocio. No hay cambio funcional visible al usuario: es una unificación estructural de la capa de datos. Antecedente directo: `SIGA/PJ3636-implementacion-api-siga-ambos-hubs/PRD.md` — la API solo puede cubrir MEX mientras exista un DataAccess por país. |
| Folio PJ | ⚠️ **`PJ0001` es placeholder.** Renombrar la carpeta y actualizar `config.json` (`prd_id`) cuando se asigne el folio real. |
| Repositorio principal | `gp_4.0_siga` (SIGA Web + 9 proyectos consumidores + `DataAccess` / `DataAccessColombia`) |
| Repositorio afectado sin cambios de código | `gp_3.0_siga_api` (5 servicios: `Catalogs`, `Contracts`, `Claims`, `Authentication`, `Invoices`) — ganan capacidad COL/CHL sin tocarse. **Premisa pendiente de verificar (ver §2).** |
| Rama base | `develop` (verificada limpia y al día con `origin/develop` el 2026-08-18 — commit `eb220d2`) |
| Rama funcional | `refactor/PJ0001-unificacion-dataaccess-multipais` |
| Tipo | **Refactor estructural** (sin cambio funcional) — ⚠️ desviación consciente de `rules/version-control.md`, que solo define `feature/`, `bugfix/` y `hotfix/` |
| Responsable | Javier Oropeza |
| Fecha de generación | 2026-08-18 |
| Estado | Borrador |
| ID plan (BD) | — *(lo llena el flujo al registrar el plan)* |
| Modelo / esfuerzo | Claude Opus 5 (`claude-opus-5[1m]`) — normal |

---

## 1. Resumen técnico

En `gp_4.0_siga` existen dos proyectos duplicados que generan el **mismo assembly** (`DataAccess.dll`) con el **mismo namespace** (`mx.autocom.garantiplus.data`), a partir de dos `.csproj` **byte-idénticos**:

| | Archivos `.cs` | DbSets | Líneas de `garantiplus_dbContext.cs` |
|---|---|---|---|
| `DataAccess/` (MEX + CHL) | 188 | 136 | 3 551 + 3 carpetas de partials |
| `DataAccessColombia/` (COL) | 211 | 111 | 3 293 + partials en `Models/Hub` |

Son drop-in intercambiables — y por eso mismo no pueden coexistir en un build. La elección se hace **en tiempo de compilación** con `<CountryBase>` hardcodeado en 9 `.csproj`, lo que obliga a recompilar por país en cada despliegue y bloquea que la API de SIGA (`gp_3.0_siga_api`) cubra más de un país.

**El objetivo:** un solo `DataAccess`, un solo artefacto, país resuelto en runtime. Los 9 proyectos consumidores deben seguir compilando y comportándose **exactamente igual** que hoy.

- **Arquitectura:** modificación sobre el monolito SIGA (EC2 + .NET 8 + Razor/MVC Areas) y su capa de datos compartida. Sin microservicio nuevo, sin API nueva, sin infraestructura nueva.
- **Stack:** .NET 8 / C#, EF Core 8 + Npgsql 8, PostgreSQL. Nuevo proyecto de consola `DataAccess.SchemaTools/` (net8.0) como herramienta de validación.
- **Fuera de alcance:** limpieza de los mapeos fantasma, el ruteo de connection string por request (multi-país en un mismo proceso), y migrar el estado del país de estático a `DbContextOptions`.

### 1.1 El mecanismo ya existe a medias — hallazgo que define el alcance real

El análisis de código reveló que **ambos forks ya tienen una capa de ajuste por país** basada en `[NotMapped]`, que no estaba documentada:

| Fork | Carpeta | Archivos | Qué hace |
|---|---|---|---|
| `DataAccess/` (MEX) | `AjustesHub/` | 16 | Stubs `[NotMapped]` de entidades y propiedades de COL/CHL (`tributo`, `parametro`, `impuesto_poliza`, `responsabilidad_fiscal*`, `auto`, `auto_carga`, `factura.prefijo`, `distribuidor.entidad_bancaria`…) |
| `DataAccessColombia/` (COL) | `Models/Hub/` + `Models/Hub/Adecuaciones/` | 49 + 31 | Lo mismo en espejo: stubs de las entidades y propiedades de MEX |

Esto tiene dos consecuencias directas:

**A favor (el riesgo principal ya está mitigado de origen).** La superficie de tipos que consume el código **ya es el superconjunto de los 3 países**: cada fork declara los miembros ajenos y solo los marca `[NotMapped]`. Es la razón por la que los 9 consumidores compilan hoy contra MEX aunque el código toque miembros de COL. Se verificó que **ningún consumidor de este repo depende de un tipo exclusivo de COL**: `notacredito` y `placetopay_webhook_notification` se usan vía SQL crudo (`NpgsqlCommand`) y DTOs locales (`Pagos/Models/PlaceToPlay/`), no vía EF. El requisito "el código debe seguir funcionando igual" está estructuralmente resuelto de antemano.

**En contra (el volumen real es mayor al estimado).** El trabajo de fusión no son "16 entidades exclusivas + 13 compartidas". El inventario medido es:

- **~96 archivos** en las capas de ajuste de ambos forks.
- **84 archivos compartidos que difieren** entre forks (comparados ignorando whitespace).
- **10 archivos exclusivos de COL** (`cfdi_siigo`, `documento_fiscal`, `fiscales_poliza_impuesto`, `fiscales_poliza_responsabilidad_fiscal`, `impuesto_poliza_adicionales`, `notacredito`, `placetopay_webhook_notification`, `rango_facturacion`, `responsabilidad_fiscal`, `datos_fiscales_bancarios_taller`).
- **40 DbSets solo en MEX** y **15 solo en COL**.
- **~10 clases declaradas en ambos forks como `class` no `partial`** → al fusionar son **errores de compilación duros**: `tributo`, `tributo_distribuidor`, `responsabilidad_fiscal`, `responsabilidad_fiscal_distribuidor`, `impuesto_poliza`, `parametro`, `auto`, `auto_carga`, `momento_facturacion`, `version_vehiculo`.

### 1.2 Hallazgos que corrigen supuestos del análisis previo

| Supuesto del análisis previo | Realidad verificada en `develop` | Decisión de este plan |
|---|---|---|
| 3 hosts hacen `if (hubCountryCode.ToLower() != "col")` | Son **2**: `GarantiplusWeb/Program.cs:104` y `GarantiplusMobileAPI/Startup.cs:42`. `Pagos/Startup.cs` **no** tiene ese `if` | Borrar el `if` en 2 hosts (T-13) |
| `Pagos` se resuelve igual que los otros hosts; `#define MEXICO` fuera de alcance | `Pagos/Startup.cs:32-61` usa `#if MEXICO / #elif COLOMBIA` con **dos `ConfigureServices` completos**. La rama COLOMBIA dice literal *"NO configurar país (usar comportamiento por defecto)"* — mismo bug, otro mecanismo. Además registra servicios que MEXICO no (`EmailSettings`, `IEmailSender`) | **`Pagos` y `PasarelaPagos` entran en alcance** (T-14). Sin eso, COL en Pagos llega al modelo mexicano tras unificar |
| La regla obsoleta es `refaccion_averia.uat` | El `Ignore` real es **`mano_obra_averia.uat`** (`DataAccess:3545`, `DataAccessColombia:3286`). `refaccion_averia` aparece por separado como divergencia de *tipo* | Corregido en §5 y T-05 |
| `gpmx_web.sln` línea 16 tiene la entrada de `DataAccessColombia` | El archivo es **`gpmx.sln`** y la entrada está en la **línea 94**, apuntando a `DataAccess_co\DataAccess.csproj` — **ruta que no existe** (la carpeta es `DataAccessColombia`). Ya está roto hoy | T-22 la elimina y verifica que la solución cargue |
| Precedente de partials en `garantiplus_dbContext.cs:209-211` | Está en **`:201-205`**; el `switch` de país en **`:3516-3549`** | Referencias corregidas en §4 |
| COL y MEX ejecutan los mismos partials de `OnModelCreating` | COL llama **solo** `OnModelCreatingAverias` + `OnModelCreatingIncidencias` (`:172-175`). **No existe `CatalogosExtentions/` en COL** | T-17: al unificar, COL heredará la config de Catálogos (incluye `pais_tipo_moneda` y `tipo_cambio_moneda`, **exclusivas de MEX**) → requiere exclusiones nuevas |
| Las reglas de los 2 `switch` se migran "tal cual" | Son **disjuntas y contradictorias**: en el contexto MEX, `case "col"` **no** ignora `bmw_valor_uat`; en el de COL sí. Y el contexto COL ignora `replica`/`replica_contrato` para `case "mex"`, lo cual es incoherente (son tablas MEX+CHL) → código muerto | T-05 decide la **unión razonada** regla por regla, con evidencia del validador. No se copian literal |
| Las 185/208 archivos y 147/121 DbSets del conteo previo | Reales: **188/211** archivos y **136/111** DbSets | Corregido en §1 |

### 1.3 El modo de falla peligroso es el inverso al esperado

El análisis previo advertía sobre *"un país queda con una columna mapeada que su BD no tiene"* → excepción en la primera consulta de esa entidad. **Es el riesgo ruidoso y, por tanto, el menos grave.**

El riesgo serio es el inverso: **un `[NotMapped]` que sobrevive la fusión.** `[NotMapped]` es una anotación de clase/propiedad compilada en el assembly: aplica a los 3 países y no se puede condicionar por país. Si `factura.prefijo`, `distribuidor.entidad_bancaria` / `tipo_cuenta_bancaria` / `id_foraneo`, `tributo`, `parametro`, `impuesto_poliza`, `version_vehiculo` o `responsabilidad_fiscal*` quedan `[NotMapped]` en el assembly unificado, **COL no truena**: lee `default` y descarta escrituras silenciosamente, sin una sola excepción en el log.

El validador descrito originalmente (modelo EF vs `information_schema`, con las tablas sin mapear solo como *advertencia*) **no detecta ese caso**. Por eso la herramienta de la Fase 0 lleva el chequeo en ambas direcciones y la dirección inversa es **error, no advertencia** (T-02).

---

## 2. Prerequisitos

- [ ] Folio PJ real asignado (para renombrar la carpeta, actualizar `config.json` y nombrar rama/commits)
- [x] Acceso al repositorio `gp_4.0_siga` confirmado
- [x] Rama `develop` actualizada y limpia (verificado 2026-08-18, commit `eb220d2`)
- [ ] **`CLAUDE.md` NO existe en `gp_4.0_siga`** → ejecutar `/init` en el repo antes de la T-01 (requisito de `workflows/generar-plan.md`)
- [ ] Las 3 BD locales al día como reflejo de producción (`garantiplus_db` ~166 tablas, `garantiplus_colombia_db` ~161, `garantiplus_chile_db` ~129). Registrar fecha del reflejo en `AVANCE.md`
- [ ] Cadenas de conexión de lectura a las 3 BD disponibles para `SchemaTools` (variables de entorno, **nunca en el código**)
- [ ] Ambientes de QA por país accesibles para el gate de validación
- [ ] **Verificar la premisa sobre `gp_3.0_siga_api`**: que sus 5 servicios llamen `ConfigurePais(paisCode)` limpio (ej. `Services/Contracts/Program.cs:68`) y referencien `DataAccess` sin condición. No se pudo validar desde este repo y es de donde sale el beneficio principal del proyecto
- [ ] Ventana de mantenimiento y respaldo previo para los `ALTER` de la Fase 3 (3 BD de producción)
- [ ] Confirmar con Aldo Álvarez que no hay pipeline de CI que compile por `CountryBase` y que se rompa al eliminar la propiedad
- [ ] Sin secrets nuevos

---

## 3. Arquitectura del cambio

Se respeta el monolito SIGA (`rules/arquitectura.md`): la unificación es interna a la capa de datos y a los `.csproj`. El despliegue sigue en EC2 por país, con la diferencia de que el **artefacto pasa a ser único** y el país se resuelve por configuración.

```
ANTES (compile-time)                     DESPUÉS (runtime)
────────────────────                     ─────────────────
appsettings + <CountryBase>              appsettings
        │                                  Hub:HubBaseCountryCode
        ├── MEXICO   → DataAccess/                  │
        ├── COLOMBIA → DataAccessColombia/          ▼
        └── CHILE    → ruta absoluta (rota)   ConfigurePais("COL")
                                                    │
9 .csproj × 3 ItemGroup condicionales               ▼
= 9 builds distintos por país              DataAccess/ (único)
                                            garantiplus_dbContext
                                              OnModelCreating
                                                ├─ Fluent compartido (superconjunto)
                                                ├─ OnModelCreatingAverias
                                                ├─ OnModelCreatingIncidencias
                                                ├─ OnModelCreatingCatalogos
                                                └─ OnModelCreatingCountry
                                                     └─ CountryConfiguration/
                                                          ICountryModelConfiguration
                                                          ├─ MexicoModelConfiguration
                                                          ├─ ColombiaModelConfiguration
                                                          └─ ChileModelConfiguration
                                                                (solo restan e ajustan)
                                            + CountryModelCacheKeyFactory
                                                (país en la llave del caché del IModel)

                    1 artefacto → MEX | COL | CHL
```

**Decisiones de diseño:**

1. **Base: `DataAccess/` (MEX).** Es el que ya referencian los 9 proyectos de SIGA (todos con `CountryBase=MEXICO`) y los 5 servicios de la API. Fusionar hacia MEX minimiza el diff de consumidores a cero.
2. **Se reutiliza el precedente de partials.** `OnModelCreating` ya delega en `OnModelCreatingAverias/Incidencias/Catalogos` (`garantiplus_dbContext.cs:201-205`). El `switch` de `:3516-3549` se reemplaza por `OnModelCreatingCountry(modelBuilder)`. No se inventa mecanismo nuevo.
3. **El Fluent compartido se queda donde está** (es el superconjunto); las clases por país **solo restan (`Ignore`) y ajustan (`HasColumnType`)**. No se mueve el mapeo existente.
4. **Por qué no `IEntityTypeConfiguration<T>` por entidad:** implicaría reescribir ~3 400 líneas de Fluent API existente. Riesgo desproporcionado para el beneficio, y contra `coding-guidelines.md` (no refactorizar código existente).
5. **`[NotMapped]` se elimina y se traduce a `Ignore` por país.** Es la única forma de expresar "mapeado en COL, no en MEX". Cada eliminación queda cubierta por el chequeo inverso del validador (T-02).
6. **Estado del país: se blinda el estático ahora**, con la forma lista para inyectar por `DbContextOptions` después. No se tocan los 5 servicios de la API.
7. **Un solo mecanismo de selección de país.** Se eliminan los tres que coexisten hoy: `<CountryBase>` (compile-time), `#define MEXICO/COLOMBIA` (compile-time) y el `if != "col"` (runtime, con default de assembly). Queda solo `Hub:HubBaseCountryCode` → `ConfigurePais`.
8. **Entidades exclusivas por país → `Models/Country/{Mexico,Colombia,Chile}/`.** El resto **no se mueve**, para que el diff siga siendo legible.
9. **`DataAccessColombia/` se deprecia, no se borra.** Un ciclo de gracia para reversa fácil. Se retira el ciclo siguiente.
10. **El validador es parte del entregable, no un extra.** Sin él en el flujo de despliegue, la matriz se vuelve a pudrir: `bmw_valor_uat` y `mano_obra_averia.uat` existen hoy en las 3 bases y ambos contextos siguen ignorándolos — las reglas eran ciertas cuando se escribieron y nadie las actualizó.

---

## 4. Tareas de desarrollo

### Fase 0 — Línea base, inventario y herramienta (P1)

> No toca nada existente. Todo lo que produce es insumo verificable de las fases siguientes.

- [ ] **T-01** — Crear rama funcional desde `develop`
  - Comando: `git checkout develop && git pull origin develop && git checkout -b refactor/PJ0001-unificacion-dataaccess-multipais`
  - Tag de respaldo del estado actual: `git tag pre-unificacion-dataaccess` (el respaldo del DataAccess lo cubre git; no copiar carpetas)
  - Criterio de completitud: rama local basada en `develop` actualizado + tag empujado

- [ ] **T-02** — Crear `DataAccess.SchemaTools/` (net8.0, consola) con los tres modos
  - Archivos: `DataAccess.SchemaTools/` (`Program.cs`, `SchemaDiff.cs`, `SchemaValidator.cs`, `NotMappedInventory.cs`, `.csproj`)
  - Modos:
    - `diff` — conecta a las 3 BD y emite la matriz país × tabla × columna a `docs/dataaccess/schema-matrix.md`
    - `validate --country MEX --connection …` — construye el modelo EF real y lo compara contra `information_schema` en **ambas direcciones**:
      - entidad o propiedad **mapeada sin respaldo en la BD** → `exit != 0`
      - **columna existente en la BD sin propiedad mapeada** → `exit != 0`, con allowlist explícita en `docs/dataaccess/unmapped-allowlist.json` (es el chequeo que detecta un `[NotMapped]` sobreviviente; sin él la falla es silenciosa — §1.3)
      - tabla existente sin mapear → advertencia
    - `inventory` — emite el inventario de `[NotMapped]` y de clases duplicadas no-`partial` (insumo de T-10)
  - Cadenas de conexión **solo** por variable de entorno o argumento; nunca hardcodeadas
  - Criterio de completitud: los 3 modos corren contra las 3 BD locales; `validate` da verde para MEX y CHL contra `DataAccess/` actual y para COL contra `DataAccessColombia/` actual (línea base reproducible)

- [ ] **T-03** — Generar `docs/dataaccess/schema-matrix.md` con `diff`
  - **La matriz se genera, no se escribe a mano.** Sustituye al anexo redactado manualmente, que ya se demostró que se pudre
  - Verificar contra la matriz generada las cifras que el análisis previo usó como base: 18 tablas compartidas con divergencia estructural (13 COL, 4 CHL, 2 MEX), 6 pares con divergencia solo de tipo, ~38 tablas exclusivas
  - Criterio de completitud: matriz generada y commiteada; discrepancias contra el anexo previo documentadas en `AVANCE.md`

- [ ] **T-04** — Generar los inventarios de entrada de la fusión
  - `docs/dataaccess/notmapped-inventory.md` — todo `[NotMapped]` de `AjustesHub/`, `Models/Hub/` y `Models/Hub/Adecuaciones/`, con el país donde **sí** debe mapearse
  - `docs/dataaccess/class-collisions.md` — las clases declaradas en ambos forks, marcando `partial` vs no-`partial` (las no-`partial` son errores de compilación al fusionar)
  - `docs/dataaccess/phantom-mappings.md` — mapeos sin tabla en su BD: MEX (`venta_directa`, `producto_venta_directa`, `cotizacion_lead`, `producto_cotizacion_lead`, `openpay_payment`, `meses_sin_intereses`, `producto_erp`), COL (`documento_fiscal`), y el caso del DbSet `Parametros` (`garantiplus_dbContext.cs:184`) que apunta a `parametro`, tabla que solo existe en COL, con la clase marcada `[NotMapped]` en MEX. **Se documentan, no se tocan en esta feature**
  - Criterio de completitud: los 3 documentos generados por herramienta; el de fantasmas revisado a mano para confirmar que ninguno es consumido por código vivo

- [ ] **T-05** — Decidir la unión de reglas de país (tabla de decisión)
  - Insumo: los dos `switch` actuales, que son **disjuntos y contradictorios** (§1.2), más la matriz de T-03
  - Reglas actuales a resolver:

    | Regla | Contexto MEX | Contexto COL | Decisión requerida |
    |---|---|---|---|
    | `producto_proyecto.comision` | `Ignore` en `mex`+`col` | no existe | Confirmar con matriz: el anexo dice que a MEX le falta `comision` y COL+CHL la tienen |
    | `cotizacion_tarificador.beneficiario` / `id_beneficiario` | `Ignore` en `mex`+`col` | no existe | CHL tiene 19 columnas vs 18 → validar por país |
    | `beneficiario_poliza.cotizaciones` | `Ignore` en `mex`+`col` | no existe | Referencia circular; conservar |
    | `bmw_valor_uat` + `mano_obra_averia.uat` | `Ignore` solo en `chl` | `Ignore` solo en `col` | **Contradicción.** La matriz dice que existen en las 3 BD → candidatas a **eliminarse** como regla |
    | `replica` / `replica_contrato` / `contrato.replicas` | no existe | `Ignore` en `mex`+`chl` | **Incoherente**: son tablas MEX+CHL. El `case "mex"` es código muerto → no migrar literal; debe ser `Ignore` solo para `col` |

  - Cada decisión respaldada por la matriz generada, **no por la regla heredada**
  - Criterio de completitud: tabla de decisión cerrada por escrito en `AVANCE.md`, con la evidencia de la matriz por regla
  - **Commit de fase:** herramienta + docs generados + tabla de decisión

### Fase 1 — Capa de configuración por país (P1)

- [ ] **T-06** — Crear `DataAccess/CountryConfiguration/`
  - Archivos:
    - `ICountryModelConfiguration.cs` — `string CountryCode { get; }` + `void Apply(ModelBuilder modelBuilder)`
    - `CountryCodes.cs` — constantes `MEX` / `COL` / `CHL` + `SupportedCountries`
    - `MexicoModelConfiguration.cs`, `ColombiaModelConfiguration.cs`, `ChileModelConfiguration.cs`
    - `CountryModelConfigurationFactory.cs` — resuelve por código; **lanza** si el código no está soportado
    - `CountryModelCacheKeyFactory.cs` — mete el país en la llave del caché del `IModel`
  - Convenciones: código y comentarios **en inglés**, archivos > 200 líneas en partials (`GarantiplusWeb/Documentacion/CODING_GUIDELINES.md`)
  - **Cada regla lleva comentario de por qué existe** y referencia a la evidencia de T-05
  - Criterio de completitud: compila; el factory lanza con un código no soportado; las 3 clases están vacías de reglas todavía

- [ ] **T-07** — Reemplazar el `switch` por `OnModelCreatingCountry(modelBuilder)`
  - Archivo: `DataAccess/garantiplus_dbContext.cs:3516-3549`
  - Migrar las reglas según la **unión decidida en T-05**, no copiando literal
  - Eliminar las reglas obsoletas (`bmw_valor_uat`, `mano_obra_averia.uat`) solo si la matriz de T-03 confirma que las columnas existen en las 3 BD
  - Criterio de completitud: `validate` verde para MEX y CHL; el modelo de MEX es idéntico al de antes (comparar snapshot del `IModel`)

- [ ] **T-08** — Blindar `ConfigurePais` y registrar el cache key factory
  - Archivos: `DataAccess/garantiplus_dbContext.cs:14-34`
  - `ConfigurePais` **lanza** si: el código no está soportado, o si llega después de que el `IModel` ya se construyó (llegar tarde hoy cachea el modelo del país equivocado **sin un solo error en el log**)
  - Exponer `CountryCode` público de solo lectura para diagnóstico
  - `ReplaceService<IModelCacheKeyFactory, CountryModelCacheKeyFactory>()` en cada host
  - Dejar la forma lista para inyectar por `DbContextOptions` en un ciclo posterior (comentario `// ponytail: opción B` con referencia a este plan)
  - Criterio de completitud: arrancar un host con `Hub:HubBaseCountryCode` inválido falla rápido y con mensaje claro; con dos países en el mismo proceso, el caché no se contamina

- [ ] **T-09** — Borrar el `if != "col"` en los 2 hosts que lo tienen
  - Archivos: `GarantiplusWeb/Program.cs:104-108`, `GarantiplusMobileAPI/Startup.cs:42-46`
  - Hoy **para COL se saltan `ConfigurePais` a propósito**, confiando en que el default estático del assembly de Colombia dice `"COL"` (`DataAccessColombia/garantiplus_dbContext.cs:13`). Unificado hay un solo default (`"MEX"`, `DataAccess:14`), así que Colombia arrancaría con el modelo mexicano y pediría 57 columnas de `factura` a una tabla de 35
  - Criterio de completitud: los 2 hosts llaman `ConfigurePais(hubCountryCode)` sin condición; COL arranca con el modelo colombiano

- [ ] **T-10** — Eliminar `#define` de `Pagos` y `PasarelaPagos`
  - Archivos: `Pagos/Startup.cs:1-2` y `:32-61`, `PasarelaPagos/OpenpayGP/Program.cs:1` y `:29-33`
  - `Pagos` tiene **dos `ConfigureServices` completos** bajo `#if MEXICO / #elif COLOMBIA`. La rama COLOMBIA dice literal *"NO configurar país (usar comportamiento por defecto)"* — es el mismo bug de T-09 expresado con compilación condicional
  - Unificar en un solo `ConfigureServices` que llame `ConfigurePais(hubCountryCode)` sin condición
  - **Reconciliar los servicios que difieren entre ramas**: la rama COLOMBIA registra `EmailSettings` + `IEmailSender` y la MEXICO no → decidir registro en runtime (por país o siempre) y documentar la decisión
  - Criterio de completitud: cero directivas `#if` de país en ambos proyectos; ambos compilan y arrancan para los 3 países; el proveedor de correo correcto se resuelve por configuración
  - **Commit de fase**

### Fase 2 — Fusión de las entidades de Colombia (P1)

> El bloque grande. Se parte en commits por dominio para que cada uno compile de forma independiente.

- [ ] **T-11** — Resolver las colisiones de clase duplicada
  - Insumo: `docs/dataaccess/class-collisions.md` (T-04)
  - Las ~10 clases declaradas como `class` no-`partial` en ambos forks son **errores de compilación duros** al fusionar: `tributo`, `tributo_distribuidor`, `responsabilidad_fiscal`, `responsabilidad_fiscal_distribuidor`, `impuesto_poliza`, `parametro`, `auto`, `auto_carga`, `momento_facturacion`, `version_vehiculo`
  - Por cada una: conservar la definición **real de COL** (la que tiene el mapeo y las columnas), eliminar el stub de `AjustesHub/`, y sustituir su `[NotMapped]` por `Ignore<T>()` en las clases de MEX y CHL
  - Ojo con `DataAccess/AjustesHub/responabilidad_fiscal.cs` — **el archivo está mal escrito** (`responabilidad`) pero la clase dentro es `responsabilidad_fiscal`
  - Criterio de completitud: el proyecto unificado compila sin errores de tipo duplicado; `validate` verde para MEX y CHL

- [ ] **T-12** — Entidades exclusivas de COL: bloque fiscal DIAN
  - Entidades: `tributo`, `tributo_distribuidor`, `responsabilidad_fiscal`, `responsabilidad_fiscal_distribuidor`, `fiscales_poliza_impuesto`, `fiscales_poliza_responsabilidad_fiscal`, `rango_facturacion`, `notacredito`, `impuesto_poliza_adicionales`, `documento_fiscal`
  - Clases → `DataAccess/Models/Country/Colombia/`; Fluent en `ColombiaModelConfiguration`; `Ignore<T>()` en MEX y CHL
  - Criterio de completitud: compila; `validate` verde para los 3 países en este dominio

- [ ] **T-13** — Entidades exclusivas de COL: pasarela, Siigo y resto
  - Entidades: `placetopay_webhook_notification`, `cfdi_siigo`, `Homologation`, `Homologation_Type`, `Intagration`, `mas_colombia_pedido`, `parametro`, `resolucion_automatica_averia_mecanica`
  - Ojo: `Pagos/Models/PlaceToPlay/placetopay_webhook_notification.cs` es un **DTO local de `Pagos`**, distinto de la entidad EF. No confundirlos ni fusionarlos
  - Criterio de completitud: compila; `validate` verde; `Pagos` sigue usando su DTO local sin ambigüedad de tipos

- [ ] **T-14** — Tablas compartidas donde COL divirge (13)
  - Tablas: `asesor` (12/13), `beneficiario_poliza` (25/23), `contrato` (45/45 distintas), `distribuidor` (33/38), `factura` (57/35), `fiscales_poliza` (10/15), `impuesto` (5/6), `pago_factura` (44/39), `pago_pasarela`, `poliza` (29/30), `poliza_ordenpago` (7/9), `producto_adicional_poliza` (20/18), `taller` (22/21)
  - Agregar las propiedades faltantes al modelo compartido y excluirlas en los países que no las tienen
  - **Respetar el orden documentado** en `garantiplus_dbContext.cs:3527-3529`: primero la navegación, después el FK escalar (de lo contrario el `Ignore` no funciona)
  - Eliminar los `[NotMapped]` de propiedad correspondientes (`factura.prefijo`, `distribuidor.email_contacto_copia` / `entidad_bancaria` / `tipo_cuenta_bancaria` / `id_foraneo` / `responsabilidades_fiscales` / `tributos`, `vehiculo.id_version`…) y traducirlos a `Ignore` por país
  - Criterio de completitud: `validate` verde para los 3 países **en ambas direcciones**; cero `[NotMapped]` restantes sobre propiedades que algún país necesita mapear

- [ ] **T-15** — Divergencias de CHL (4) y de MEX (2)
  - CHL: `agencia_armadora` (8/10), `cotizacion_tarificador` (18/19), `orden_pago` (19/21), `refaccion` (7/8); exclusivas `auto`, `auto_carga`, `temp_autos`
  - MEX: `mano_obra` (4/5), `producto_proyecto` (43/44 — le falta `comision`)
  - CHL además **carece de 21 tablas que MEX y COL sí tienen** (`lead`, `cupon_*`, `partida_factura`, `impuesto_poliza`, `contrato_meli`…) → `Ignore` en `ChileModelConfiguration`
  - Criterio de completitud: `validate` verde para CHL, que es el país con menos tablas (~129) y por tanto el que más exclusiones necesita

- [ ] **T-16** — Aplanar los partials de 3 capas de COL
  - `DataAccessColombia/Models/`, `Models/Hub/` y `Models/Hub/Adecuaciones/` declaran la misma entidad en hasta 3 archivos (32 basenames duplicados)
  - Aplanar a **un archivo por entidad** en el proyecto unificado
  - `Models/Hub/Adecuaciones/garantiplus_dbContext.cs` de COL contiene `OnModelCreatingAverias` → reconciliar con `DataAccess/AveriasExtensions/garantiplus_dbContext.cs`
  - Criterio de completitud: una sola declaración por entidad; el `IModel` resultante no cambia respecto a T-15 (comparar snapshot)

- [ ] **T-17** — Catálogos: exclusiones para COL *(gap no contemplado en el análisis previo)*
  - COL **no ejecuta `OnModelCreatingCatalogos`** hoy: `DataAccessColombia/garantiplus_dbContext.cs:172-175` solo llama Averías e Incidencias, y no existe `CatalogosExtentions/` en ese fork
  - Al unificar sobre MEX, COL heredará la config de `pais`, `pais_tipo_moneda`, `precio_producto`, `precio_volumen`, `producto_proyecto`, `proyecto`, `tipo_cambio_moneda`, `tipo_moneda`, `tipo_vehiculo`
  - `pais_tipo_moneda` y `tipo_cambio_moneda` son **exclusivas de MEX** según la matriz → `Ignore` en `ColombiaModelConfiguration` (y verificar CHL)
  - Criterio de completitud: `validate` verde para COL con el partial de Catálogos activo

- [ ] **T-18** — Unificar `GarantiplusRepository.cs` e `IRepository.cs`
  - Idénticos entre forks salvo que COL agrega `.EnableSensitiveDataLogging(true)`
  - **No se propaga** — loguea parámetros SQL con datos sensibles. Conservar la versión de MEX y dejar la omisión anotada en `AVANCE.md`
  - Criterio de completitud: un solo repositorio; COL funciona sin el flag; nada de PII en los logs
  - **Commits por bloque de dominio** (T-11 a T-18)

### Fase 3 — Alinear tipos en las BD (P2)

> ⚠️ **Movida después de la fusión, a propósito.** El análisis previo la ponía antes, argumentando que la reversa es fácil porque `DataAccessColombia/` sigue en el repo. Eso es cierto para el código y **falso para la BD**: si los `ALTER` ya corrieron y luego se revierte el código, el fork viejo espera los tipos anteriores. Con la fusión ya validada, esta fase deja de ser un punto de no-retorno prematuro.

- [ ] **T-19** — Scripts `.sql` por país para las 6 divergencias accidentales
  - Tablas: `email_queue` (MEX vs COL+CHL), `estado` (CHL), `marca_vehiculo` (CHL), `refaccion_averia` (CHL: `causa_rechazo` `text` vs `varchar`), `impuesto` (MEX↔CHL), `taller` (MEX↔CHL)
  - Ubicación: `GarantiplusWeb/BD/2026-XX-XX_unificacion_dataaccess/` (siguiendo el patrón de `GarantiplusWeb/BD/`)
  - **Requisito de la fase (no observación):** cada `ALTER` debe ser una ampliación de tipo compatible con **ambos** modelos (el unificado y el fork viejo), para que la reversa siga siendo posible. Sin pérdida de datos, sin `DROP`
  - Criterio de completitud: scripts revisados; aplicados en local; `validate` verde en los 3 países después de aplicar

- [ ] **T-20** — Retirar las 6 reglas de tipo del código
  - Tras los `ALTER`, esas 6 tablas dejan de necesitar `HasColumnType` por país
  - Criterio de completitud: reglas eliminadas de las 3 clases de configuración; `validate` verde
  - **Commit:** los `.sql` + la limpieza de reglas

### Fase 4 — Eliminar CountryBase (P1)

- [ ] **T-21** — Limpiar los 9 `.csproj`
  - Archivos y líneas exactas:

    | Proyecto | `<CountryBase>` | `ItemGroup` condicionales |
    |---|---|---|
    | `GarantiplusWeb/GarantiplusWeb.csproj` | `:10` | `:72`, `:75`, `:78` |
    | `PaisesService/PaisesService.csproj` | `:8` | `:24`, `:27`, `:30` |
    | `ClientsService/ClientsService.csproj` | `:9` | `:21`, `:24`, `:27` |
    | `CatalogosBusinessRules/GeneralesBusinessRules.csproj` | `:9` | `:23`, `:26`, `:29` |
    | `ArmadorasBusinessRules/ArmadorasBusinessRules.csproj` | `:9` | `:23`, `:26`, `:29` |
    | `AveriasBusinessRules/src/AveriasBusinessRules/AveriasBusinessRules.csproj` | `:9` | `:38`, `:41`, `:44` |
    | `BusinessCentralService/BusinessCentralService.csproj` | `:10` | `:24`, `:27`, `:30` |
    | `VentasService/src/Ventas.Domain/Ventas.Domain.csproj` | `:12` | `:31`, `:34`, `:37` |
    | `Pagos/Pagos.csproj` | `:5` | `:16`, `:19`, `:22` |

  - Dejar un `ProjectReference` único sin condición a `$(GPProjectBasePath)/DataAccess/DataAccess.csproj`
  - Esto además elimina las **rutas absolutas a máquinas de desarrolladores** que hoy están rotas en la rama CHILE: `/Users/vosnaya/dotnet_projects/gp_chile/DataAccess/…` (en `CatalogosBusinessRules`, `ClientsService`, `PaisesService`, `Ventas.Domain`), `/Users/vosnaya/dotnet_projects/DataAccess/…` (en `GarantiplusWeb`) y `C:/Users/manuel.martinez/source/repos/gp_chile/DataAccess/…` (en `Pagos`). Nota: los otros 3 ya apuntaban CHILE al `DataAccess` local → la rama CHILE ya era incoherente
  - `CancelacionContratos` y `GarantiplusMobileAPI` ya apuntan sin condición → **sin cambio**
  - Criterio de completitud: cero ocurrencias de `CountryBase` en el repo; los 10 consumidores compilan

- [ ] **T-22** — Limpiar `gpmx.sln`
  - Quitar la entrada de la **línea 94**: `Project(…) = "DataAccess", "DataAccess_co\DataAccess.csproj"` — apunta a `DataAccess_co`, **carpeta que no existe** (es `DataAccessColombia`), así que la entrada ya está rota hoy
  - Quitar sus configuraciones de build asociadas (GUID `{C88566E1-FCB2-4B60-9CC9-7A50D6A652E1}`)
  - Criterio de completitud: `gpmx.sln` carga sin advertencias de proyecto faltante; `dotnet build gpmx.sln` verde

- [ ] **T-23** — Deprecar `DataAccessColombia/`
  - Agregar `DataAccessColombia/DEPRECATED.md` explicando: qué lo reemplaza, cómo revertir, y en qué ciclo se retira
  - **No borrar** — es la reversa (§11)
  - Criterio de completitud: `DEPRECATED.md` presente; la carpeta sigue en el repo pero fuera de la solución

- [ ] **T-24** — Corregir la documentación
  - `DataAccess/README.md:84-92` — dice que Colombia usa un DataAccess dentro de `gp_colombia`, **repo que ya no existe**. Reescribir describiendo el modelo unificado
  - `GarantiplusWeb/Readme.md` (sección "Cambiar de país" y "Configuración cambio de país", ~`:255-338`) — hoy indica actualizar `appsettings.json` **y el `.csproj`**. El cambio de país queda en: connection string + `Hub:HubBaseCountryCode` + provider de correo. **Ya no se toca ningún `.csproj`**
  - Documentar `CountryConfiguration/` y `SchemaTools` en `DataAccess/README.md`
  - Criterio de completitud: ninguna referencia viva a `CountryBase` ni a `gp_colombia` en la documentación
  - **Commit de fase**

### Fase 5 — Validación, gate y despliegue (P1)

- [ ] **T-25** — Gate de validación completo
  - `SchemaTools validate` para los 3 países, **0 errores en ambas direcciones**
  - Compilar los 10 consumidores y `gpmx.sln`
  - Verificar el `IModel` de MEX contra el snapshot pre-cambio: **MEX se comporta idéntico**
  - **Agregar el gate a la skill `deploy-qa-prod`** como paso obligatorio previo a cada despliegue por país. Sin esto la matriz se vuelve a pudrir en seis meses (§11)
  - Criterio de completitud: gate documentado y ejecutable; skill actualizada

- [ ] **T-26** — Smoke test manual por país
  - Orden por escenario: login → listado de contratos → crear contrato → avería con refacciones (toca `refaccion_averia`, `mano_obra`, `taller`) → facturación (`factura`, `fiscales_poliza`, tributos en COL) → orden de pago (`orden_pago`, `poliza_ordenpago`) → pasarela
  - En **COL**: verificar específicamente las entidades fiscales DIAN, `notacredito`, y que **las escrituras persistan** (el modo de falla de §1.3 es silencioso — comprobar en BD, no solo en pantalla)
  - En **CHL**: `auto` / `auto_carga` y `cotizacion_tarificador` (19 columnas vs 18)
  - En **MEX**: regresión completa, es el país con más cobertura
  - Criterio de completitud: matriz de smoke test firmada por país; cero regresiones en MEX

- [ ] **T-27** — Despliegue por país
  - Orden: **MEX** (ya corre, máxima cobertura) → **CHL** (comparte modelo hoy, cambio menor) → **COL** (el que más cambia)
  - `validate` en verde es requisito **antes de cada uno**
  - Criterio de completitud: los 3 países en producción con el artefacto unificado

- [ ] **T-28** — Commit, push y cierre
  - Mensaje estilo Engine: `[PJ0001-unificacion-dataaccess-multipais] Unificar DataAccess multi-país con configuración por país en runtime`
  - Avisar al usuario que la skill `siga-cambio-pais-base` **queda desactualizada** y hay que reescribirla (ya no hay `.csproj` que tocar)
  - Registrar en `AVANCE.md`: mapeos fantasma pendientes, `EnableSensitiveDataLogging` omitido, opción B (estado del país por `DbContextOptions`) diferida
  - Criterio de completitud: cambios en rama remota; el programador gestiona el PR → `pre-qa`

---

## 5. Cambios en base de datos

| Tabla | Tipo de cambio | Descripción |
|---|---|---|
| `email_queue` | Modificación de tipo | Divergencia accidental MEX vs COL+CHL — alinear (T-19) |
| `estado` | Modificación de tipo | Divergencia accidental en CHL |
| `marca_vehiculo` | Modificación de tipo | Divergencia accidental en CHL |
| `refaccion_averia` | Modificación de tipo | CHL: `causa_rechazo` `text` vs `varchar` |
| `impuesto` | Modificación de tipo | Divergencia accidental MEX ↔ CHL |
| `taller` | Modificación de tipo | Divergencia accidental MEX ↔ CHL |

- **Ninguna tabla nueva, ninguna columna nueva, ningún `DROP`.** Los 6 cambios son ampliaciones de tipo que nunca fueron intencionales; alinearlas quita 6 reglas del código (T-20).
- Se aplican en **las 3 BD de producción** → requieren ventana y respaldo previo. Validar en local → QA → prod.
- **Requisito de compatibilidad:** cada `ALTER` debe seguir funcionando con el fork viejo (`DataAccessColombia/`), para que la reversa del código no dependa de revertir la BD.
- Las 18 tablas con divergencia **estructural** (columnas distintas) **no se tocan**: se resuelven en el modelo con reglas por país, no con `ALTER`. No es "agregarle a MEX lo que le falta de COL".

---

## 6. Endpoints nuevos o modificados

**No aplica.** Este plan no crea ni modifica endpoints. Es un cambio en la capa de datos y en la configuración de build.

Los 5 servicios de `gp_3.0_siga_api` (`Catalogs`, `Contracts`, `Claims`, `Authentication`, `Invoices`) **ganan capacidad COL/CHL sin cambio de código ni de contrato** — su `ProjectReference` a `DataAccess` ya es incondicional y ya llaman `ConfigurePais(paisCode)`. ⚠️ Premisa pendiente de verificar (§2).

---

## 7. Variables de entorno y configuración

| Variable / clave | Descripción | Ambiente |
|---|---|---|
| `Hub:HubBaseCountryCode` | **Pasa a ser el único selector de país.** Valores soportados: `MEX`, `COL`, `CHL`. `ConfigurePais` lanza con cualquier otro (T-08) | Dev / QA / Prod, los 3 países |
| `ConnectionStrings:Garantiplus_Connection` | Apunta a la BD del país. Sin cambio de forma | Dev / QA / Prod |
| `EmailSettings` | Provider de correo por país (outlook / gmail). Hoy se resuelve por `#define` en `Pagos`; pasa a configuración (T-10) | Dev / QA / Prod |
| `SCHEMATOOLS_CONN_MEX` / `_COL` / `_CHL` | Cadenas de solo lectura para el validador. **Solo por variable de entorno**, nunca en el código | Local / CI / pre-despliegue |

**Se eliminan:**

| Mecanismo eliminado | Dónde vivía |
|---|---|
| `<CountryBase>` | 9 `.csproj` (T-21) |
| `#define MEXICO` / `#define COLOMBIA` | `Pagos/Startup.cs:1-2`, `PasarelaPagos/OpenpayGP/Program.cs:1` (T-10) |
| `if (hubCountryCode.ToLower() != "col")` | `GarantiplusWeb/Program.cs:104`, `GarantiplusMobileAPI/Startup.cs:42` (T-09) |

Sin secrets nuevos.

---

## 8. Consideraciones de seguridad

- **`EnableSensitiveDataLogging(true)`** existe hoy en el `GarantiplusRepository` de COL y **no se propaga** al unificado: loguea parámetros SQL, es decir datos de clientes y datos fiscales en texto claro (T-18). Es una mejora de seguridad colateral de este plan; dejarla anotada para que nadie la "restaure" por simetría.
- **Cadenas de conexión del validador solo por variable de entorno.** `SchemaTools` se conecta a las 3 BD, incluidas las de producción en el gate de despliegue: nada hardcodeado, nada en el repo (`rules/coding-guidelines.md`).
- **Los `ALTER` de la Fase 3 corren sobre 3 BD de producción**: respaldo previo verificado y ventana acordada. Son ampliaciones de tipo sin pérdida, pero el respaldo no es opcional.
- **Sin cambios de autorización.** No se toca ningún endpoint, rol ni política. Los guards de país existentes (`ViewBag.CodigoPais`, `[Authorize]`) siguen intactos.
- **Riesgo de fuga entre países en un mismo proceso:** el estado del país sigue siendo estático (`_paisGlobal`). Este plan lo blinda (lanza si llega tarde, país en la llave del caché del `IModel`) pero **no habilita** multi-país en un proceso. Si alguien intenta servir dos países desde el mismo host, ahora falla en lugar de mezclar datos silenciosamente — que es exactamente el comportamiento deseado.

---

## 9. Consideraciones de infraestructura

- **Sin recursos AWS nuevos.** Despliegue sigue en las EC2 existentes por país.
- **Beneficio directo:** el artefacto pasa a ser único. Se elimina la recompilación por país en cada despliegue (hoy: 9 proyectos × 3 valores de `CountryBase`).
- Aplicar los scripts de la Fase 3 en los RDS/PostgreSQL de los 3 países, con ventana y respaldo.
- `DataAccess.SchemaTools/` es una consola local / de CI: no se despliega, no consume infraestructura.
- **Costo incremental: nulo.**
- Confirmar con Aldo Álvarez que ningún pipeline de CI pasa `-p:CountryBase=…`; si existe, se rompe al eliminar la propiedad (T-21).

---

## 10. Criterios de aceptación

- [ ] Cero ocurrencias de `CountryBase` en el repo; cada consumidor tiene **un** `ProjectReference` sin condición
- [ ] Cero directivas `#if` de país en `Pagos` y `PasarelaPagos`
- [ ] Cero `if != "col"` en los hosts; los 3 países llaman `ConfigurePais` por la misma ruta
- [ ] `SchemaTools validate` en verde para MEX, COL y CHL, **en ambas direcciones** (mapeado sin respaldo **y** columna sin mapear)
- [ ] Cero `[NotMapped]` sobre propiedades o clases que algún país necesita mapear
- [ ] El `IModel` de MEX es equivalente al pre-cambio: **MEX se comporta idéntico**
- [ ] `gpmx.sln` carga sin proyecto faltante y `dotnet build gpmx.sln` en verde
- [ ] Los 10 consumidores compilan sin cambios en su código C#
- [ ] `docs/dataaccess/schema-matrix.md` **generado por herramienta**, no escrito a mano
- [ ] Inventario de mapeos fantasma documentado (no corregido — fuera de alcance)
- [ ] Smoke test completo en los 3 países, con verificación **en BD** de que las escrituras de COL persisten
- [ ] El gate de `validate` está incorporado a la skill `deploy-qa-prod`
- [ ] `DataAccess/README.md` y `GarantiplusWeb/Readme.md` sin referencias a `CountryBase` ni a `gp_colombia`
- [ ] `DataAccessColombia/DEPRECATED.md` presente; la carpeta sigue en el repo
- [ ] Los 5 servicios de `gp_3.0_siga_api` compilan y sirven COL/CHL **sin cambios de código**

---

## 11. Riesgos técnicos identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Un `[NotMapped]` sobrevive la fusión** → COL lee `default` y descarta escrituras **sin una sola excepción** (§1.3) | Alta | **Crítico** | Chequeo inverso del validador como **error**, no advertencia (T-02); inventario previo de `[NotMapped]` (T-04); smoke test que verifica persistencia en BD, no en pantalla (T-26) |
| Un país queda con una columna mapeada que su BD no tiene → falla en la primera consulta de esa entidad, en producción | Alta | Alto | `validate` como gate obligatorio; orden de despliegue MEX → CHL → COL (T-27) |
| **COL arranca con el modelo mexicano** porque algún host no llama `ConfigurePais` (pide 57 columnas de `factura` a una tabla de 35) | Alta | **Crítico** | T-09 y T-10 eliminan los 3 mecanismos que hoy saltan `ConfigurePais`; T-08 hace que lance si llega tarde |
| El `IModel` se cachea con el país equivocado si algo resuelve el contexto antes de `ConfigurePais` — **sin error en el log** | Media | Alto | `CountryModelCacheKeyFactory` + `ConfigurePais` que lanza si llega tarde (T-08) |
| **Migrar las reglas de los 2 `switch` "tal cual"** produce un modelo ambiguo para COL (son disjuntas y contradictorias) | Alta | Alto | T-05: tabla de decisión con evidencia de la matriz, regla por regla. No se copian literal |
| **COL hereda la config de Catálogos** que hoy no ejecuta, incluidas 2 tablas exclusivas de MEX | Alta | Medio | T-17 explícita para este gap |
| El volumen de la fusión (84 archivos divergentes + ~96 en capas de ajuste) se subestima y la fase se desborda | Alta | Medio | Inventario por herramienta antes de codificar (T-04); commits por dominio; cada commit compila |
| Colisiones de clase duplicada no-`partial` frenan el build a mitad de la fusión | Alta | Bajo | T-11 las resuelve **primero**, antes de cualquier fusión de dominio |
| **La matriz se vuelve a pudrir** — ya pasó con `bmw_valor_uat` y `mano_obra_averia.uat` | Alta | Alto | El gate en `deploy-qa-prod` es parte del entregable (T-25), no un extra |
| Los `ALTER` de la Fase 3 vuelven irreversible el código si se aplican antes de validar la fusión | Media | Alto | Fase movida **después** de la fusión; requisito de compatibilidad con ambos modelos (T-19) |
| La premisa sobre `gp_3.0_siga_api` es falsa y sus 5 servicios sí requieren cambios | Media | Medio | Verificación explícita en §2 antes de arrancar; si falla, es un plan aparte en ese repo |
| Un pipeline de CI pasa `-p:CountryBase=…` y se rompe al eliminar la propiedad | Baja | Medio | Confirmar con Aldo Álvarez (§2) |
| Alguien "restaura" `EnableSensitiveDataLogging` por simetría con el fork viejo | Baja | Alto | Decisión documentada en T-18 y §8 |

**Reversa:** `DataAccessColombia/` sigue en el repo (T-23 lo depreca, no lo borra). Revertir = restaurar el bloque `ItemGroup Condition` en el `.csproj` del servicio afectado y recompilar. Por eso la Fase 4 no lo elimina y la Fase 3 exige `ALTER` compatibles con ambos modelos.

---

## 12. Notas para el programador

1. **Ejecutar `/init` en `gp_4.0_siga` antes de la T-01** — no hay `CLAUDE.md` en el repo y `workflows/generar-plan.md` lo exige. Este plan se generó a partir de análisis directo del código; el `CLAUDE.md` sigue haciendo falta para la ejecución.
2. **`AjustesHub/` y `Models/Hub/` son el insumo principal de la Fase 2**, y no aparecían en el análisis original. No arrancar la fusión sin el inventario de T-04 en la mano: ahí está la lista real de qué se resta y para qué país.
3. **No refactorizar el Fluent existente** (`rules/coding-guidelines.md`). Las clases por país **solo restan (`Ignore`) y ajustan (`HasColumnType`)**. Reescribir 3 400 líneas a `IEntityTypeConfiguration<T>` es riesgo desproporcionado y está descartado (§3, decisión 4).
4. **El orden del `Ignore` importa**: primero la navegación, después el FK escalar. Está documentado en el código (`garantiplus_dbContext.cs:3527-3529`) y no es opcional — al revés no funciona.
5. **Código y comentarios en inglés** en `CountryConfiguration/` y `SchemaTools/`; mensajes al usuario en español (`GarantiplusWeb/Documentacion/CODING_GUIDELINES.md`). Archivos > 200 líneas en partials.
6. **Cada regla de país lleva comentario de por qué existe**, con la evidencia de la matriz. Las reglas sin justificación escrita son las que se pudren.
7. **Cada fase compila y se commitea.** El usuario compila y reinicia; este plan no asume builds automáticos. La Fase 2 se parte en commits por dominio precisamente para eso.
8. **Fuera de alcance, anotado:** el estado estático del país (opción B: inyección por `DbContextOptions`), el ruteo de connection string por request para multi-país en un proceso, y la limpieza de los mapeos fantasma. Registrar los tres en `AVANCE.md` como follow-up.
9. **La skill `siga-cambio-pais-base` queda inválida** al terminar (ya no hay `.csproj` que tocar). Avisar al usuario para reescribirla; no es parte de este plan pero sí un pendiente que este plan genera.
10. El programador gestiona el PR (`refactor/*` → `pre-qa` → `qa`); Claude Code no crea PRs.
11. Tras autorizar este plan: registrar en BD PM (`db-sync`) y luego "ejecuta el plan".

---

## 13. Relación de tareas y tiempos

| Fase | Incluye | Tareas | Días hábiles (rango) | ID (BD) |
|---|---|---|---|---|
| **Fase 0 — Línea base, inventario y herramienta (P1)** | Rama + tag, `SchemaTools` (3 modos), matriz generada, inventarios de `[NotMapped]` / colisiones / fantasmas, tabla de decisión de reglas | T-01 a T-05 | 3 – 4.5 días | — |
| **Fase 1 — Capa de configuración por país (P1)** | `CountryConfiguration/`, `OnModelCreatingCountry`, blindaje de `ConfigurePais`, cache key factory, limpieza de los 3 mecanismos de selección de país en 4 hosts | T-06 a T-10 | 2 – 3.5 días | — |
| **Fase 2 — Fusión de entidades de Colombia (P1)** | Colisiones de clase, 2 bloques de exclusivas COL, 13 compartidas COL, divergencias CHL+MEX, aplanado de partials, Catálogos para COL, repositorio unificado | T-11 a T-18 | 7 – 11 días | — |
| **Fase 3 — Alinear tipos en las BD (P2)** | 6 scripts `.sql`, aplicación local → QA → prod, retiro de las 6 reglas | T-19 a T-20 | 1 – 2 días *(+ ventanas de prod)* | — |
| **Fase 4 — Eliminar CountryBase (P1)** | 9 `.csproj`, `gpmx.sln`, `DEPRECATED.md`, documentación | T-21 a T-24 | 1 – 1.5 días | — |
| **Fase 5 — Validación, gate y despliegue (P1)** | Gate completo, skill `deploy-qa-prod`, smoke test 3 países, despliegue MEX → CHL → COL, cierre | T-25 a T-28 | 2.5 – 4 días | — |
| **Total proyecto** | | **28 tareas** | **~16.5 – 26.5 días hábiles (≈ 3.5 – 5.5 semanas)** | — |
| **Ruta crítica (sin Fase 3)** | Fase 0 + 1 + 2 + 4 + 5 | T-01 a T-18, T-21 a T-28 | **~15.5 – 24.5 días hábiles** | — |

> **Notas sobre la tabla:**
> - La estimación de la Fase 2 refleja el inventario **medido** (84 archivos divergentes + ~96 en capas de ajuste + 10 colisiones de clase), no la estimación original de "16 exclusivas + 13 compartidas". Es la fase con mayor incertidumbre: si T-04 revela que la mayoría de los 84 diffs son cosméticos (formato, `using`, partials mal emparejados), puede bajar al extremo inferior del rango.
> - La **Fase 3 es la única P2** y puede diferirse sin bloquear nada: sin ella quedan 6 reglas de tipo en el código, que es exactamente el estado de hoy.
> - Las ventanas de mantenimiento de la Fase 3 son tiempo de calendario, no de desarrollo, y dependen de la coordinación con operaciones de los 3 países.
> - La columna **ID (BD)** la llena el flujo al registrar el plan (`pm_plan_fase.id`).

> **Riesgo de deadline:** no hay fecha límite explícita — es deuda técnica que bloquea la expansión de `gp_3.0_siga_api` a COL/CHL (PJ3636). Si hubiera presión de calendario, el corte natural es **Fase 0 + Fase 1**: deja el mecanismo de configuración por país listo y blindado, con los dos DataAccess todavía separados. Eso ya elimina el bug de "COL arranca con el modelo mexicano" y produce el validador, sin asumir el riesgo de la fusión. La Fase 2 no se puede comprimir con un segundo desarrollador sin trabajar sobre el mismo `garantiplus_dbContext.cs`, así que paralelizar ahí genera conflictos más que velocidad; lo paralelizable es la Fase 0 (herramienta) contra la Fase 1 (configuración).

---

*Generado por Claude Code — Engine CX*
*Basado en: `rules/infraestructura.md`, `rules/coding-guidelines.md`, `rules/stack.md`, `rules/arquitectura.md`, `rules/version-control.md`*
*Modelo: Claude Opus 5 (`claude-opus-5[1m]`) — esfuerzo: normal*
