# Copiloto de Averías — Plan de implementación de la etapa 1

> **Para trabajadores agénticos:** SUB-SKILL REQUERIDA: usa `superpowers:subagent-driven-development` (recomendado) o `superpowers:executing-plans` para implementar este plan tarea por tarea. Los pasos usan sintaxis de casilla (`- [ ]`) para seguimiento.

**Objetivo:** Construir el MVP del Copiloto de Averías — seguimiento continuo del expediente de cada avería, evaluación de suficiencia en cada evento, dictamen de improcedencia cuando el caso ya es deliberable, y reporte matutino de estatus — sin escribir nada en SIGA, y dejando la escritura de la etapa 2 lista para encenderse con una bandera.

**Arquitectura:** n8n delgado como pasarela (suscripción push de Gmail, cron del barrido, cron del reporte, envío de correo) invocando por HTTP a un **servicio propio en TypeScript** que contiene todo el estado y toda la decisión. El estado vive en **Postgres/Supabase**: un expediente por folio, con su bitácora de eventos, sus evaluaciones de suficiencia y sus dictámenes. El motor de decisión se organiza en capas (capa 0 suficiencia → capas 1-3 dictamen) y cada capa es un módulo con interfaz propia y tests independientes.

**Tech Stack:** TypeScript · Node 20+ · Fastify · Vitest · Postgres (Supabase) · `node-pg-migrate` · SDK de Anthropic (`@anthropic-ai/sdk`) · `docxtemplater` para el documento · n8n para la orquestación de I/O · `zod` para validación de contratos.

**Spec:** `Desarrollos_internos/PJ1544-copiloto-averias/PRD.md` (v0.3, 2026-09-01)

## Constricciones globales

- **RNF-18 — La suficiencia precede al dictamen, siempre.** Ninguna ruta del código puede invocar el motor de dictamen sobre un expediente cuya última evaluación de suficiencia no sea `suficiente`. Esta constricción se hace cumplir por tipos, no por disciplina (Task 11).
- **RNF-04 — Cero escritura en SIGA en la etapa 1.** El cliente de SIGA de este alcance expone únicamente operaciones de lectura. La escritura existe como interfaz sin implementación real (Task 20).
- **RNF-12 — Datos personales.** El nombre, el teléfono, el correo y la dirección del beneficiario **nunca** se persisten, se registran en log ni se envían al modelo. Los adjuntos se procesan en memoria y no se escriben a disco.
- **RNF-07 — Idempotencia.** Reprocesar un evento ya incorporado no produce un segundo dictamen, un segundo documento ni un segundo correo.
- **RNF-20 — Economía de la atención.** Solo tres cosas generan correo inmediato: dictamen, excepción y fallo técnico. Cualquier otra notificación es un defecto.
- **RNF-23 — El estado sobrevive al reinicio.** Nada del expediente vive solo en memoria de proceso.
- **RF-21 / RF-77 — Versionado.** Cada dictamen registra la versión del prompt con la que se produjo; cada evaluación de suficiencia registra la versión del catálogo de evidencia mínima que aplicó.
- **Idioma.** Todo el texto dirigido a una persona —correos, documento, reporte— va en español de México. Los identificadores de código, en inglés.
- **Zona horaria.** Todo cálculo de fechas y horas usa `America/Mexico_City`. Nada de `new Date()` sin zona explícita.
- **Node 20+**, TypeScript en modo `strict`, sin `any` implícito.

---

## Estructura de archivos

```
copiloto-averias/
├─ src/
│  ├─ config/
│  │  └─ env.ts                      # Carga y valida la configuración; banderas de etapa
│  ├─ db/
│  │  ├─ client.ts                   # Pool de Postgres
│  │  ├─ migrations/                 # Migraciones SQL versionadas
│  │  └─ repositories/
│  │     ├─ case-repository.ts       # Expedientes: crear, leer, actualizar estado
│  │     ├─ event-repository.ts      # Bitácora de eventos, idempotencia
│  │     ├─ sufficiency-repository.ts
│  │     ├─ verdict-repository.ts
│  │     └─ catalog-repository.ts    # Catálogo de evidencia mínima, versionado
│  ├─ domain/
│  │  ├─ types.ts                    # Tipos del dominio compartidos
│  │  ├─ case-state.ts               # Máquina de estados y sus transiciones legales
│  │  └─ errors.ts                   # Excepción vs error técnico
│  ├─ ingestion/
│  │  ├─ email-parser.ts             # Reconoce correos de SIGA, extrae folio/VIN, clasifica
│  │  └─ event-ingestor.ts           # Correlación por folio, idempotencia, alta de eventos
│  ├─ siga/
│  │  ├─ siga-client.ts              # Cliente HTTP de solo lectura
│  │  ├─ siga-types.ts               # DTOs de la API
│  │  └─ dossier-assembler.ts        # Reunión incremental + coherencia
│  ├─ sufficiency/
│  │  ├─ system-identifier.ts        # Capa 0a: identifica el sistema afectado
│  │  ├─ sufficiency-evaluator.ts    # Capa 0b: coteja contra el catálogo
│  │  └─ minimum-evidence-catalog.ts # Modelo del catálogo y su carga
│  ├─ adjudication/
│  │  ├─ gates.ts                    # Puertas 0-5 y su orden
│  │  ├─ coverage-agent.ts           # Capas 1-3: invoca al modelo, valida la salida
│  │  ├─ confidence.ts               # Umbrales por causal, degradación a duda
│  │  └─ prompts/                    # Prompts versionados, uno por archivo
│  ├─ output/
│  │  ├─ document-builder.ts         # Documento de deliberación desde plantilla
│  │  ├─ verdict-email.ts            # Correo de dictamen
│  │  ├─ morning-report.ts           # Reporte matutino
│  │  └─ templates/                  # Plantillas .docx y .hbs
│  ├─ writeback/
│  │  ├─ siga-writer.ts              # Interfaz de escritura — etapa 2
│  │  └─ noop-writer.ts              # Implementación inerte de la etapa 1
│  ├─ pipeline/
│  │  ├─ process-event.ts            # Orquestación de un evento de principio a fin
│  │  ├─ sweep.ts                    # Barrido periódico de reconciliación
│  │  └─ stall-detector.ts           # Detección de casos ESTANCADO
│  ├─ observability/
│  │  ├─ events.ts                   # Emisión de los eventos del §11 del PRD
│  │  └─ anonymize.ts                # Supresión de datos personales
│  └─ http/
│     └─ server.ts                   # Endpoints que n8n invoca
├─ tests/
│  ├─ fixtures/                      # Correos reales, respuestas de la API, certificados
│  └─ …                              # Espejo de src/
├─ n8n/
│  └─ workflows/                     # Exportaciones JSON de los workflows
└─ docs/
   └─ runbook.md
```

---

## Task 1: Andamiaje del proyecto

**Files:**
- Create: `package.json`, `tsconfig.json`, `vitest.config.ts`, `.env.example`, `.gitignore`
- Create: `src/config/env.ts`
- Test: `tests/config/env.test.ts`

**Interfaces:**
- Consumes: nada.
- Produces: `loadConfig(): AppConfig` — objeto de configuración validado, con las banderas `stage2WriteEnabled: boolean` y `autoRejectEnabled: boolean` en `false` por defecto.

- [ ] **Step 1: Inicializar el proyecto**

```bash
mkdir -p copiloto-averias && cd copiloto-averias
npm init -y
npm i fastify zod pg @anthropic-ai/sdk docxtemplater pizzip handlebars luxon
npm i -D typescript vitest @types/node @types/pg tsx node-pg-migrate
npx tsc --init --strict --target ES2022 --module NodeNext --moduleResolution NodeNext --outDir dist --rootDir .
```

- [ ] **Step 2: Escribir el test de configuración**

```typescript
// tests/config/env.test.ts
import { describe, it, expect } from 'vitest'
import { loadConfig } from '../../src/config/env.js'

const base = {
  DATABASE_URL: 'postgres://localhost/test',
  SIGA_BASE_URL: 'https://siga.example.com',
  SIGA_USER: 'svc',
  SIGA_PASSWORD: 'x',
  ANTHROPIC_API_KEY: 'sk-test',
  AREA_MANAGER_EMAIL: 'david@garantiplus.mx',
}

describe('loadConfig', () => {
  it('las banderas de escritura vienen apagadas por defecto', () => {
    const cfg = loadConfig(base)
    expect(cfg.stage2WriteEnabled).toBe(false)
    expect(cfg.autoRejectEnabled).toBe(false)
  })

  it('falla si falta una variable obligatoria', () => {
    const { DATABASE_URL, ...incompleta } = base
    expect(() => loadConfig(incompleta)).toThrow(/DATABASE_URL/)
  })

  it('usa America/Mexico_City como zona por defecto', () => {
    expect(loadConfig(base).timezone).toBe('America/Mexico_City')
  })
})
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `npx vitest run tests/config/env.test.ts`
Esperado: FAIL — `Cannot find module '../../src/config/env.js'`

- [ ] **Step 4: Implementar la configuración**

```typescript
// src/config/env.ts
import { z } from 'zod'

const schema = z.object({
  DATABASE_URL: z.string().min(1),
  SIGA_BASE_URL: z.string().url(),
  SIGA_USER: z.string().min(1),
  SIGA_PASSWORD: z.string().min(1),
  ANTHROPIC_API_KEY: z.string().min(1),
  AREA_MANAGER_EMAIL: z.string().email(),
  TIMEZONE: z.string().default('America/Mexico_City'),
  STAGE2_WRITE_ENABLED: z.enum(['true', 'false']).default('false'),
  AUTO_REJECT_ENABLED: z.enum(['true', 'false']).default('false'),
  STALL_DAYS: z.coerce.number().int().positive().default(3),
  SWEEP_INTERVAL_MINUTES: z.coerce.number().int().positive().default(30),
  MORNING_REPORT_HOUR: z.string().default('07:30'),
})

export type AppConfig = {
  databaseUrl: string
  siga: { baseUrl: string; user: string; password: string }
  anthropicApiKey: string
  areaManagerEmail: string
  timezone: string
  stage2WriteEnabled: boolean
  autoRejectEnabled: boolean
  stallDays: number
  sweepIntervalMinutes: number
  morningReportHour: string
}

export function loadConfig(source: NodeJS.ProcessEnv | Record<string, string | undefined> = process.env): AppConfig {
  const parsed = schema.safeParse(source)
  if (!parsed.success) {
    const faltantes = parsed.error.issues.map((i) => i.path.join('.')).join(', ')
    throw new Error(`Configuración inválida: ${faltantes}`)
  }
  const e = parsed.data
  return {
    databaseUrl: e.DATABASE_URL,
    siga: { baseUrl: e.SIGA_BASE_URL, user: e.SIGA_USER, password: e.SIGA_PASSWORD },
    anthropicApiKey: e.ANTHROPIC_API_KEY,
    areaManagerEmail: e.AREA_MANAGER_EMAIL,
    timezone: e.TIMEZONE,
    stage2WriteEnabled: e.STAGE2_WRITE_ENABLED === 'true',
    autoRejectEnabled: e.AUTO_REJECT_ENABLED === 'true',
    stallDays: e.STALL_DAYS,
    sweepIntervalMinutes: e.SWEEP_INTERVAL_MINUTES,
    morningReportHour: e.MORNING_REPORT_HOUR,
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `npx vitest run tests/config/env.test.ts`
Esperado: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git init && git add -A
git commit -m "feat: andamiaje del proyecto y configuración validada"
```

---

## Task 2: Esquema de base de datos

**Files:**
- Create: `src/db/migrations/001_initial.sql`
- Create: `src/db/client.ts`
- Test: `tests/db/migrations.test.ts`

**Interfaces:**
- Consumes: `loadConfig()` de Task 1.
- Produces: `getPool(): Pool` y el esquema con las tablas `cases`, `case_events`, `sufficiency_evaluations`, `verdicts`, `case_documents`, `evidence_catalog_versions`, `evidence_requirements`, `notifications`.

- [ ] **Step 1: Escribir la migración**

```sql
-- src/db/migrations/001_initial.sql

CREATE TYPE case_state AS ENUM (
  'DETECTADO', 'EN_ACUMULACION', 'SUFICIENTE', 'DELIBERADO', 'ESTANCADO', 'EXCEPCION', 'CERRADO'
);

CREATE TYPE verdict_value AS ENUM (
  'improcedente', 'sin_causal_de_improcedencia', 'duda'
);

CREATE TYPE sufficiency_value AS ENUM ('suficiente', 'insuficiente');

-- Un expediente vivo por folio de avería.
CREATE TABLE cases (
  claim_folio        TEXT PRIMARY KEY,
  vin                TEXT NOT NULL,
  contract_id        TEXT,
  product            TEXT,
  dealer             TEXT,
  vehicle            JSONB,
  certificate_text   TEXT,
  claim_status       TEXT,
  assigned_to        TEXT,
  failure_description TEXT,
  affected_system    TEXT,
  state              case_state NOT NULL DEFAULT 'DETECTADO',
  zero_mark_at       TIMESTAMPTZ NOT NULL,
  last_event_at      TIMESTAMPTZ NOT NULL,
  sufficient_at      TIMESTAMPTZ,
  closed_at          TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cases_state ON cases (state) WHERE state <> 'CERRADO';
CREATE INDEX idx_cases_assigned ON cases (assigned_to) WHERE state <> 'CERRADO';

-- Bitácora de eventos. La clave de idempotencia es (claim_folio, event_kind, source_fingerprint).
CREATE TABLE case_events (
  id                 BIGSERIAL PRIMARY KEY,
  claim_folio        TEXT NOT NULL REFERENCES cases(claim_folio) ON DELETE CASCADE,
  sequence_number    INT NOT NULL,
  event_kind         TEXT NOT NULL,
  origin             TEXT NOT NULL CHECK (origin IN ('correo', 'barrido')),
  source_fingerprint TEXT NOT NULL,
  mailbox            TEXT,
  changes            JSONB NOT NULL DEFAULT '{}'::jsonb,
  occurred_at        TIMESTAMPTZ NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (claim_folio, event_kind, source_fingerprint),
  UNIQUE (claim_folio, sequence_number)
);

-- Catálogo de evidencia mínima por sistema, versionado.
CREATE TABLE evidence_catalog_versions (
  id           SERIAL PRIMARY KEY,
  version      TEXT NOT NULL UNIQUE,
  provisional  BOOLEAN NOT NULL DEFAULT true,
  approved_by  TEXT,
  active       BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_one_active_catalog ON evidence_catalog_versions (active) WHERE active;

CREATE TABLE evidence_requirements (
  id           SERIAL PRIMARY KEY,
  version_id   INT NOT NULL REFERENCES evidence_catalog_versions(id) ON DELETE CASCADE,
  system_key   TEXT NOT NULL,
  requirement_key TEXT NOT NULL,
  label        TEXT NOT NULL,
  mandatory    BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (version_id, system_key, requirement_key)
);

CREATE TABLE sufficiency_evaluations (
  id             BIGSERIAL PRIMARY KEY,
  claim_folio    TEXT NOT NULL REFERENCES cases(claim_folio) ON DELETE CASCADE,
  event_id       BIGINT NOT NULL REFERENCES case_events(id) ON DELETE CASCADE,
  result         sufficiency_value NOT NULL,
  affected_system TEXT,
  system_confidence NUMERIC(4,3),
  missing        JSONB NOT NULL DEFAULT '[]'::jsonb,
  catalog_version TEXT NOT NULL,
  evaluated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sufficiency_case ON sufficiency_evaluations (claim_folio, evaluated_at DESC);

CREATE TABLE verdicts (
  id             BIGSERIAL PRIMARY KEY,
  claim_folio    TEXT NOT NULL REFERENCES cases(claim_folio) ON DELETE CASCADE,
  event_id       BIGINT NOT NULL REFERENCES case_events(id) ON DELETE CASCADE,
  value          verdict_value NOT NULL,
  reason_code    TEXT,
  clause_quote   TEXT,
  supporting_evidence JSONB NOT NULL DEFAULT '[]'::jsonb,
  confidence     NUMERIC(4,3) NOT NULL,
  deciding_gate  TEXT,
  prompt_version TEXT NOT NULL,
  supersedes_id  BIGINT REFERENCES verdicts(id),
  superseded_reason TEXT,
  emitted_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_verdicts_case ON verdicts (claim_folio, emitted_at DESC);

-- Documentos vistos en el expediente. Nunca el archivo, solo su huella.
CREATE TABLE case_documents (
  id            BIGSERIAL PRIMARY KEY,
  claim_folio   TEXT NOT NULL REFERENCES cases(claim_folio) ON DELETE CASCADE,
  siga_document_id TEXT NOT NULL,
  document_type TEXT,
  file_name     TEXT,
  uploaded_at   TIMESTAMPTZ,
  extracted     JSONB,
  legible       BOOLEAN,
  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (claim_folio, siga_document_id)
);

-- Registro de lo que se notificó, para no notificar dos veces.
CREATE TABLE notifications (
  id            BIGSERIAL PRIMARY KEY,
  claim_folio   TEXT,
  kind          TEXT NOT NULL,
  recipient     TEXT NOT NULL,
  dedupe_key    TEXT NOT NULL UNIQUE,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  payload       JSONB
);
```

- [ ] **Step 2: Escribir el test del esquema**

```typescript
// tests/db/migrations.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { getPool, runMigrations, closePool } from '../../src/db/client.js'

beforeAll(async () => { await runMigrations() })
afterAll(async () => { await closePool() })

describe('esquema', () => {
  it('crea las tablas del expediente vivo', async () => {
    const { rows } = await getPool().query(
      `SELECT table_name FROM information_schema.tables WHERE table_schema='public'`
    )
    const tablas = rows.map((r) => r.table_name)
    for (const t of ['cases','case_events','sufficiency_evaluations','verdicts','case_documents','evidence_catalog_versions','evidence_requirements','notifications']) {
      expect(tablas).toContain(t)
    }
  })

  it('rechaza dos eventos con la misma huella de origen', async () => {
    const pool = getPool()
    await pool.query(`INSERT INTO cases (claim_folio, vin, zero_mark_at, last_event_at) VALUES ('T1','VIN1',now(),now())`)
    await pool.query(`INSERT INTO case_events (claim_folio, sequence_number, event_kind, origin, source_fingerprint, occurred_at) VALUES ('T1',1,'asignacion','correo','abc',now())`)
    await expect(
      pool.query(`INSERT INTO case_events (claim_folio, sequence_number, event_kind, origin, source_fingerprint, occurred_at) VALUES ('T1',2,'asignacion','correo','abc',now())`)
    ).rejects.toThrow(/duplicate key/)
  })

  it('admite un solo catálogo de evidencia activo', async () => {
    const pool = getPool()
    await pool.query(`INSERT INTO evidence_catalog_versions (version, active) VALUES ('v1', true)`)
    await expect(
      pool.query(`INSERT INTO evidence_catalog_versions (version, active) VALUES ('v2', true)`)
    ).rejects.toThrow(/duplicate key/)
  })
})
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `npx vitest run tests/db/migrations.test.ts`
Esperado: FAIL — no existe `src/db/client.ts`.

- [ ] **Step 4: Implementar el cliente y el corredor de migraciones**

```typescript
// src/db/client.ts
import { Pool } from 'pg'
import { readFileSync, readdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { loadConfig } from '../config/env.js'

let pool: Pool | undefined

export function getPool(): Pool {
  if (!pool) pool = new Pool({ connectionString: loadConfig().databaseUrl })
  return pool
}

export async function closePool(): Promise<void> {
  if (pool) { await pool.end(); pool = undefined }
}

export async function runMigrations(): Promise<void> {
  const dir = join(dirname(fileURLToPath(import.meta.url)), 'migrations')
  const p = getPool()
  await p.query(`CREATE TABLE IF NOT EXISTS schema_migrations (name TEXT PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT now())`)
  for (const file of readdirSync(dir).filter((f) => f.endsWith('.sql')).sort()) {
    const { rowCount } = await p.query('SELECT 1 FROM schema_migrations WHERE name=$1', [file])
    if (rowCount) continue
    await p.query('BEGIN')
    try {
      await p.query(readFileSync(join(dir, file), 'utf8'))
      await p.query('INSERT INTO schema_migrations (name) VALUES ($1)', [file])
      await p.query('COMMIT')
    } catch (e) { await p.query('ROLLBACK'); throw e }
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/db/migrations.test.ts`
Esperado: PASS, 3 tests.

- [ ] **Step 6: Commit**

```bash
git add src/db tests/db
git commit -m "feat: esquema del expediente vivo con idempotencia de eventos"
```

---

## Task 3: Máquina de estados del caso

**Files:**
- Create: `src/domain/case-state.ts`, `src/domain/types.ts`
- Test: `tests/domain/case-state.test.ts`

**Interfaces:**
- Consumes: nada.
- Produces: `type CaseState`, `canTransition(from: CaseState, to: CaseState): boolean`, `assertTransition(from: CaseState, to: CaseState): void` (lanza `IllegalTransitionError`).

- [ ] **Step 1: Escribir el test**

```typescript
// tests/domain/case-state.test.ts
import { describe, it, expect } from 'vitest'
import { canTransition, assertTransition } from '../../src/domain/case-state.js'

describe('máquina de estados del caso', () => {
  it('permite el camino feliz completo', () => {
    expect(canTransition('DETECTADO', 'EN_ACUMULACION')).toBe(true)
    expect(canTransition('EN_ACUMULACION', 'SUFICIENTE')).toBe(true)
    expect(canTransition('SUFICIENTE', 'DELIBERADO')).toBe(true)
    expect(canTransition('DELIBERADO', 'CERRADO')).toBe(true)
  })

  it('permite volver a acumulación desde deliberado cuando llega información nueva', () => {
    expect(canTransition('DELIBERADO', 'EN_ACUMULACION')).toBe(true)
  })

  it('permite estancarse y reactivarse', () => {
    expect(canTransition('EN_ACUMULACION', 'ESTANCADO')).toBe(true)
    expect(canTransition('ESTANCADO', 'EN_ACUMULACION')).toBe(true)
  })

  it('PROHÍBE saltar de acumulación a deliberado sin pasar por suficiente', () => {
    expect(canTransition('EN_ACUMULACION', 'DELIBERADO')).toBe(false)
  })

  it('un caso cerrado no revive', () => {
    expect(canTransition('CERRADO', 'EN_ACUMULACION')).toBe(false)
  })

  it('assertTransition lanza con un mensaje que nombra ambos estados', () => {
    expect(() => assertTransition('EN_ACUMULACION', 'DELIBERADO')).toThrow(/EN_ACUMULACION.*DELIBERADO/)
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/domain/case-state.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar**

```typescript
// src/domain/case-state.ts
export const CASE_STATES = [
  'DETECTADO', 'EN_ACUMULACION', 'SUFICIENTE', 'DELIBERADO', 'ESTANCADO', 'EXCEPCION', 'CERRADO',
] as const

export type CaseState = (typeof CASE_STATES)[number]

// La transición EN_ACUMULACION -> DELIBERADO está deliberadamente ausente:
// es la constricción RNF-18 hecha cumplir por la máquina de estados.
const ALLOWED: Record<CaseState, readonly CaseState[]> = {
  DETECTADO:      ['EN_ACUMULACION', 'EXCEPCION', 'CERRADO'],
  EN_ACUMULACION: ['EN_ACUMULACION', 'SUFICIENTE', 'ESTANCADO', 'EXCEPCION', 'CERRADO'],
  SUFICIENTE:     ['DELIBERADO', 'EN_ACUMULACION', 'EXCEPCION', 'CERRADO'],
  DELIBERADO:     ['EN_ACUMULACION', 'CERRADO'],
  ESTANCADO:      ['EN_ACUMULACION', 'CERRADO'],
  EXCEPCION:      ['CERRADO'],
  CERRADO:        [],
}

export class IllegalTransitionError extends Error {
  constructor(from: CaseState, to: CaseState) {
    super(`Transición ilegal del caso: ${from} → ${to}`)
    this.name = 'IllegalTransitionError'
  }
}

export function canTransition(from: CaseState, to: CaseState): boolean {
  return ALLOWED[from].includes(to)
}

export function assertTransition(from: CaseState, to: CaseState): void {
  if (!canTransition(from, to)) throw new IllegalTransitionError(from, to)
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `npx vitest run tests/domain/case-state.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add src/domain tests/domain
git commit -m "feat: máquina de estados del caso con RNF-18 impuesta por diseño"
```

---

## Task 4: Parser de correos de SIGA

**Files:**
- Create: `src/ingestion/email-parser.ts`
- Create: `tests/fixtures/emails/asignacion.json`, `tests/fixtures/emails/documento-cargado.json`, `tests/fixtures/emails/no-relacionado.json`
- Test: `tests/ingestion/email-parser.test.ts`

**Interfaces:**
- Consumes: nada.
- Produces:
  ```typescript
  type ParsedEmail =
    | { recognized: false }
    | { recognized: true; folio: string; vin: string | null; eventKind: 'asignacion' | 'documento_cargado' | 'cambio_estatus' | 'actualizacion'; fingerprint: string; occurredAt: Date; mailbox: string }
  export function parseSigaEmail(raw: RawEmail): ParsedEmail
  type RawEmail = { from: string; to: string; subject: string; body: string; messageId: string; receivedAt: string }
  ```

- [ ] **Step 1: Crear los fixtures**

```json
// tests/fixtures/emails/asignacion.json
{
  "from": "Contacto@garantiplus.mx",
  "to": "miguel.rodriguez@garantiplus.mx",
  "subject": "Asignación de avería 3246 / Vin 9GAMM6108KB004600",
  "body": "Se le ha asignado la avería 3246 correspondiente al VIN 9GAMM6108KB004600.",
  "messageId": "<abc123@garantiplus.mx>",
  "receivedAt": "2026-09-01T15:04:00.000Z"
}
```

```json
// tests/fixtures/emails/documento-cargado.json
{
  "from": "Contacto@garantiplus.mx",
  "to": "miguel.rodriguez@garantiplus.mx",
  "subject": "Nuevo documento en la avería 3246",
  "body": "El distribuidor cargó un documento en la avería 3246 / Vin 9GAMM6108KB004600.",
  "messageId": "<def456@garantiplus.mx>",
  "receivedAt": "2026-09-02T18:20:00.000Z"
}
```

```json
// tests/fixtures/emails/no-relacionado.json
{
  "from": "boletin@proveedor.com",
  "to": "miguel.rodriguez@garantiplus.mx",
  "subject": "Promoción de septiembre",
  "body": "Aproveche nuestras ofertas.",
  "messageId": "<zzz@proveedor.com>",
  "receivedAt": "2026-09-02T09:00:00.000Z"
}
```

- [ ] **Step 2: Escribir el test**

```typescript
// tests/ingestion/email-parser.test.ts
import { describe, it, expect } from 'vitest'
import { parseSigaEmail } from '../../src/ingestion/email-parser.js'
import asignacion from '../fixtures/emails/asignacion.json'
import documento from '../fixtures/emails/documento-cargado.json'
import ruido from '../fixtures/emails/no-relacionado.json'

describe('parseSigaEmail', () => {
  it('reconoce el correo de asignación y extrae folio y VIN', () => {
    const r = parseSigaEmail(asignacion)
    expect(r.recognized).toBe(true)
    if (!r.recognized) return
    expect(r.folio).toBe('3246')
    expect(r.vin).toBe('9GAMM6108KB004600')
    expect(r.eventKind).toBe('asignacion')
  })

  it('reconoce un correo de carga de documento sobre el mismo folio', () => {
    const r = parseSigaEmail(documento)
    expect(r.recognized).toBe(true)
    if (!r.recognized) return
    expect(r.folio).toBe('3246')
    expect(r.eventKind).toBe('documento_cargado')
  })

  it('ignora sin rastro cualquier otro correo', () => {
    expect(parseSigaEmail(ruido).recognized).toBe(false)
  })

  it('la huella es estable para el mismo mensaje y distinta entre mensajes', () => {
    const a = parseSigaEmail(asignacion)
    const b = parseSigaEmail(asignacion)
    const c = parseSigaEmail(documento)
    if (!a.recognized || !b.recognized || !c.recognized) throw new Error('no reconocido')
    expect(a.fingerprint).toBe(b.fingerprint)
    expect(a.fingerprint).not.toBe(c.fingerprint)
  })

  it('devuelve no reconocido si el asunto menciona avería pero no hay folio', () => {
    const r = parseSigaEmail({ ...asignacion, subject: 'Asignación de avería / Vin', body: 'sin folio' })
    expect(r.recognized).toBe(false)
  })

  it('descarta el correo cuando el VIN del asunto no coincide con el del cuerpo', () => {
    const r = parseSigaEmail({ ...asignacion, body: 'Se le ha asignado la avería 3246 correspondiente al VIN 1HGBH41JXMN109186.' })
    expect(r.recognized).toBe(false)
  })
})
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `npx vitest run tests/ingestion/email-parser.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 4: Implementar**

```typescript
// src/ingestion/email-parser.ts
import { createHash } from 'node:crypto'

export type RawEmail = {
  from: string; to: string; subject: string; body: string; messageId: string; receivedAt: string
}

export type EventKind = 'asignacion' | 'documento_cargado' | 'cambio_estatus' | 'actualizacion'

export type ParsedEmail =
  | { recognized: false }
  | { recognized: true; folio: string; vin: string | null; eventKind: EventKind; fingerprint: string; occurredAt: Date; mailbox: string }

const SENDER = /@garantiplus\.(mx|co|cl)$/i
const FOLIO = /aver[íi]a\s+(\d{2,8})/i
const VIN = /\b([A-HJ-NPR-Z0-9]{17})\b/i

function classify(subject: string): EventKind | null {
  const s = subject.toLowerCase()
  if (s.includes('asignación de avería') || s.includes('asignacion de averia')) return 'asignacion'
  if (s.includes('documento')) return 'documento_cargado'
  if (s.includes('estatus') || s.includes('estado')) return 'cambio_estatus'
  if (s.includes('avería') || s.includes('averia')) return 'actualizacion'
  return null
}

export function parseSigaEmail(raw: RawEmail): ParsedEmail {
  if (!SENDER.test(raw.from.trim())) return { recognized: false }

  const eventKind = classify(raw.subject)
  if (!eventKind) return { recognized: false }

  const folio = (raw.subject.match(FOLIO) ?? raw.body.match(FOLIO))?.[1]
  if (!folio) return { recognized: false }

  const vinSubject = raw.subject.match(VIN)?.[1]?.toUpperCase() ?? null
  const vinBody = raw.body.match(VIN)?.[1]?.toUpperCase() ?? null
  // RF-03: si ambos existen y difieren, el correo no es de fiar.
  if (vinSubject && vinBody && vinSubject !== vinBody) return { recognized: false }

  return {
    recognized: true,
    folio,
    vin: vinSubject ?? vinBody,
    eventKind,
    fingerprint: createHash('sha256').update(raw.messageId).digest('hex').slice(0, 32),
    occurredAt: new Date(raw.receivedAt),
    mailbox: raw.to,
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `npx vitest run tests/ingestion/email-parser.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/ingestion tests/ingestion tests/fixtures/emails
git commit -m "feat: parser de correos de SIGA con clasificación de evento"
```

> **Nota para quien ejecute esta tarea.** Los patrones de asunto de los correos que **no** son de asignación son una hipótesis: el catálogo real está en la pregunta abierta #1 del PRD. Cuando se levante sobre un buzón real, esta tarea se revisa y los fixtures se reemplazan por correos auténticos. El barrido de la Task 10 existe precisamente para que el sistema funcione mientras tanto.

---

## Task 5: Repositorio de expedientes y eventos

**Files:**
- Create: `src/db/repositories/case-repository.ts`, `src/db/repositories/event-repository.ts`
- Test: `tests/db/repositories/case-repository.test.ts`

**Interfaces:**
- Consumes: `getPool()` (Task 2), `assertTransition()` (Task 3).
- Produces:
  ```typescript
  type CaseRecord = { claimFolio: string; vin: string; state: CaseState; assignedTo: string | null; affectedSystem: string | null; zeroMarkAt: Date; lastEventAt: Date; contractId: string | null; certificateText: string | null; claimStatus: string | null }
  findCase(folio: string): Promise<CaseRecord | null>
  createCase(input: { claimFolio: string; vin: string; occurredAt: Date }): Promise<CaseRecord>
  updateCaseState(folio: string, to: CaseState): Promise<CaseRecord>
  patchCase(folio: string, fields: Partial<CaseRecord>): Promise<CaseRecord>
  listActiveCases(): Promise<CaseRecord[]>
  recordEvent(input: { claimFolio: string; eventKind: string; origin: 'correo' | 'barrido'; fingerprint: string; mailbox?: string; changes?: unknown; occurredAt: Date }): Promise<{ id: number; sequenceNumber: number } | null>  // null = ya existía
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/db/repositories/case-repository.test.ts
import { describe, it, expect, beforeEach, afterAll } from 'vitest'
import { getPool, runMigrations, closePool } from '../../../src/db/client.js'
import { createCase, findCase, updateCaseState, listActiveCases } from '../../../src/db/repositories/case-repository.js'
import { recordEvent } from '../../../src/db/repositories/event-repository.js'

beforeEach(async () => { await runMigrations(); await getPool().query('TRUNCATE cases CASCADE') })
afterAll(async () => { await closePool() })

const ahora = new Date('2026-09-01T15:00:00Z')

describe('repositorio de expedientes', () => {
  it('crea el expediente en DETECTADO con la marca cero', async () => {
    const c = await createCase({ claimFolio: '3246', vin: 'VIN123', occurredAt: ahora })
    expect(c.state).toBe('DETECTADO')
    expect(c.zeroMarkAt.toISOString()).toBe(ahora.toISOString())
  })

  it('rechaza una transición ilegal', async () => {
    await createCase({ claimFolio: '3246', vin: 'VIN123', occurredAt: ahora })
    await updateCaseState('3246', 'EN_ACUMULACION')
    await expect(updateCaseState('3246', 'DELIBERADO')).rejects.toThrow(/Transición ilegal/)
  })

  it('lista solo los casos no cerrados', async () => {
    await createCase({ claimFolio: 'A', vin: 'V1', occurredAt: ahora })
    await createCase({ claimFolio: 'B', vin: 'V2', occurredAt: ahora })
    await updateCaseState('B', 'CERRADO')
    const activos = await listActiveCases()
    expect(activos.map((c) => c.claimFolio)).toEqual(['A'])
  })
})

describe('repositorio de eventos', () => {
  it('numera los eventos consecutivamente por caso', async () => {
    await createCase({ claimFolio: '3246', vin: 'VIN123', occurredAt: ahora })
    const e1 = await recordEvent({ claimFolio: '3246', eventKind: 'asignacion', origin: 'correo', fingerprint: 'f1', occurredAt: ahora })
    const e2 = await recordEvent({ claimFolio: '3246', eventKind: 'documento_cargado', origin: 'correo', fingerprint: 'f2', occurredAt: ahora })
    expect(e1?.sequenceNumber).toBe(1)
    expect(e2?.sequenceNumber).toBe(2)
  })

  it('devuelve null ante un evento repetido, sin lanzar', async () => {
    await createCase({ claimFolio: '3246', vin: 'VIN123', occurredAt: ahora })
    await recordEvent({ claimFolio: '3246', eventKind: 'asignacion', origin: 'correo', fingerprint: 'f1', occurredAt: ahora })
    const repetido = await recordEvent({ claimFolio: '3246', eventKind: 'asignacion', origin: 'correo', fingerprint: 'f1', occurredAt: ahora })
    expect(repetido).toBeNull()
  })

  it('registrar un evento actualiza lastEventAt del caso', async () => {
    await createCase({ claimFolio: '3246', vin: 'VIN123', occurredAt: ahora })
    const despues = new Date('2026-09-03T10:00:00Z')
    await recordEvent({ claimFolio: '3246', eventKind: 'documento_cargado', origin: 'barrido', fingerprint: 'f9', occurredAt: despues })
    const c = await findCase('3246')
    expect(c?.lastEventAt.toISOString()).toBe(despues.toISOString())
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/db/repositories/case-repository.test.ts`
Esperado: FAIL — módulos no encontrados.

- [ ] **Step 3: Implementar el repositorio de expedientes**

```typescript
// src/db/repositories/case-repository.ts
import { getPool } from '../client.js'
import { assertTransition, type CaseState } from '../../domain/case-state.js'
import type { Vehicle } from '../../siga/siga-types.js'

export type CaseRecord = {
  claimFolio: string; vin: string; state: CaseState; assignedTo: string | null
  affectedSystem: string | null; zeroMarkAt: Date; lastEventAt: Date
  contractId: string | null; certificateText: string | null; claimStatus: string | null
  vehicle: Vehicle | null
}

const COLS = `claim_folio, vin, state, assigned_to, affected_system, zero_mark_at, last_event_at, contract_id, certificate_text, claim_status, vehicle`

function toRecord(r: Record<string, unknown>): CaseRecord {
  return {
    claimFolio: r.claim_folio as string, vin: r.vin as string, state: r.state as CaseState,
    assignedTo: (r.assigned_to as string) ?? null, affectedSystem: (r.affected_system as string) ?? null,
    zeroMarkAt: r.zero_mark_at as Date, lastEventAt: r.last_event_at as Date,
    contractId: (r.contract_id as string) ?? null, certificateText: (r.certificate_text as string) ?? null,
    claimStatus: (r.claim_status as string) ?? null, vehicle: (r.vehicle as Vehicle) ?? null,
  }
}

export async function findCase(folio: string): Promise<CaseRecord | null> {
  const { rows } = await getPool().query(`SELECT ${COLS} FROM cases WHERE claim_folio=$1`, [folio])
  return rows[0] ? toRecord(rows[0]) : null
}

export async function createCase(input: { claimFolio: string; vin: string; occurredAt: Date }): Promise<CaseRecord> {
  const { rows } = await getPool().query(
    `INSERT INTO cases (claim_folio, vin, zero_mark_at, last_event_at) VALUES ($1,$2,$3,$3) RETURNING ${COLS}`,
    [input.claimFolio, input.vin, input.occurredAt]
  )
  return toRecord(rows[0])
}

export async function updateCaseState(folio: string, to: CaseState): Promise<CaseRecord> {
  const actual = await findCase(folio)
  if (!actual) throw new Error(`No existe el expediente ${folio}`)
  assertTransition(actual.state, to)
  const extra = to === 'SUFICIENTE' ? ', sufficient_at = now()' : to === 'CERRADO' ? ', closed_at = now()' : ''
  const { rows } = await getPool().query(
    `UPDATE cases SET state=$2, updated_at=now()${extra} WHERE claim_folio=$1 RETURNING ${COLS}`, [folio, to]
  )
  return toRecord(rows[0])
}

const PATCHABLE: Record<string, string> = {
  contractId: 'contract_id', certificateText: 'certificate_text', claimStatus: 'claim_status',
  assignedTo: 'assigned_to', affectedSystem: 'affected_system', vin: 'vin', vehicle: 'vehicle',
}

export async function patchCase(folio: string, fields: Partial<CaseRecord>): Promise<CaseRecord> {
  const entries = Object.entries(fields).filter(([k, v]) => PATCHABLE[k] && v !== undefined)
  if (!entries.length) { const c = await findCase(folio); if (!c) throw new Error(`No existe ${folio}`); return c }
  const sets = entries.map(([k], i) => `${PATCHABLE[k]}=$${i + 2}`).join(', ')
  const { rows } = await getPool().query(
    `UPDATE cases SET ${sets}, updated_at=now() WHERE claim_folio=$1 RETURNING ${COLS}`,
    [folio, ...entries.map(([k, v]) => (k === 'vehicle' ? JSON.stringify(v) : v))]
  )
  return toRecord(rows[0])
}

export async function listActiveCases(): Promise<CaseRecord[]> {
  const { rows } = await getPool().query(`SELECT ${COLS} FROM cases WHERE state <> 'CERRADO' ORDER BY claim_folio`)
  return rows.map(toRecord)
}
```

- [ ] **Step 4: Implementar el repositorio de eventos**

```typescript
// src/db/repositories/event-repository.ts
import { getPool } from '../client.js'

export type RecordEventInput = {
  claimFolio: string; eventKind: string; origin: 'correo' | 'barrido'
  fingerprint: string; mailbox?: string; changes?: unknown; occurredAt: Date
}

/** Devuelve null si el evento ya estaba registrado (RNF-07). */
export async function recordEvent(input: RecordEventInput): Promise<{ id: number; sequenceNumber: number } | null> {
  const pool = getPool()
  const client = await pool.connect()
  try {
    await client.query('BEGIN')
    // Bloqueo por caso para que dos correos simultáneos no obtengan el mismo número de secuencia.
    await client.query('SELECT 1 FROM cases WHERE claim_folio=$1 FOR UPDATE', [input.claimFolio])
    const { rows: max } = await client.query(
      'SELECT COALESCE(MAX(sequence_number),0) AS n FROM case_events WHERE claim_folio=$1', [input.claimFolio]
    )
    const siguiente = Number(max[0].n) + 1
    const { rows } = await client.query(
      `INSERT INTO case_events (claim_folio, sequence_number, event_kind, origin, source_fingerprint, mailbox, changes, occurred_at)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       ON CONFLICT (claim_folio, event_kind, source_fingerprint) DO NOTHING
       RETURNING id, sequence_number`,
      [input.claimFolio, siguiente, input.eventKind, input.origin, input.fingerprint,
       input.mailbox ?? null, JSON.stringify(input.changes ?? {}), input.occurredAt]
    )
    if (!rows[0]) { await client.query('ROLLBACK'); return null }
    await client.query(
      'UPDATE cases SET last_event_at = GREATEST(last_event_at, $2), updated_at = now() WHERE claim_folio=$1',
      [input.claimFolio, input.occurredAt]
    )
    await client.query('COMMIT')
    return { id: Number(rows[0].id), sequenceNumber: Number(rows[0].sequence_number) }
  } catch (e) { await client.query('ROLLBACK'); throw e } finally { client.release() }
}

export async function listEventsSince(folio: string, since: Date) {
  const { rows } = await getPool().query(
    `SELECT id, sequence_number, event_kind, origin, changes, occurred_at
     FROM case_events WHERE claim_folio=$1 AND occurred_at >= $2 ORDER BY sequence_number`, [folio, since]
  )
  return rows
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/db/repositories/case-repository.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/db/repositories tests/db/repositories
git commit -m "feat: repositorios de expediente y bitácora de eventos con idempotencia"
```

---

## Task 6: Cliente de solo lectura de la API de SIGA

**Files:**
- Create: `src/siga/siga-client.ts`, `src/siga/siga-types.ts`
- Create: `tests/fixtures/siga/contract.json`, `tests/fixtures/siga/claim.json`, `tests/fixtures/siga/documents.json`
- Test: `tests/siga/siga-client.test.ts`

**Interfaces:**
- Consumes: `loadConfig()` (Task 1).
- Produces:
  ```typescript
  interface SigaReader {
    findContractByVin(vin: string): Promise<ContractSummary | null>
    getContractDetail(contractId: string): Promise<ContractDetail>
    getCertificateText(contractId: string): Promise<string>
    getClaim(folio: string): Promise<ClaimDetail>
    listClaimDocuments(folio: string): Promise<ClaimDocument[]>
    downloadDocument(documentId: string): Promise<Buffer>
  }
  export function createSigaClient(deps?: { fetch?: typeof fetch }): SigaReader
  ```
  `ContractSummary = { contractId, vin, product, dealer, status, validFrom, validTo }`
  `ContractDetail = ContractSummary & { vehicle: { brand, model, version, year, kmAtContract, firstInvoiceDate, engineNumber } }`
  `ClaimDetail = { folio, vin, status, assignedTo, failureDescription, reportedAt, registeredBy }`
  `ClaimDocument = { documentId, documentType, fileName, uploadedAt }`

- [ ] **Step 1: Escribir el test con un `fetch` doblado**

```typescript
// tests/siga/siga-client.test.ts
import { describe, it, expect, vi } from 'vitest'
import { createSigaClient } from '../../src/siga/siga-client.js'
import contrato from '../fixtures/siga/contract.json'
import averia from '../fixtures/siga/claim.json'

function fakeFetch(routes: Record<string, unknown>) {
  return vi.fn(async (url: string | URL) => {
    const u = String(url)
    const key = Object.keys(routes).find((k) => u.includes(k))
    if (!key) return new Response('no encontrado', { status: 404 })
    return new Response(JSON.stringify(routes[key]), { status: 200, headers: { 'content-type': 'application/json' } })
  }) as unknown as typeof fetch
}

describe('cliente de SIGA', () => {
  it('localiza el contrato por VIN', async () => {
    const c = createSigaClient({ fetch: fakeFetch({ '/Authentication': { token: 't' }, '/GetAllContracts': [contrato] }) })
    const r = await c.findContractByVin('9GAMM6108KB004600')
    expect(r?.contractId).toBe(contrato.contractId)
  })

  it('devuelve null si el VIN no tiene contrato', async () => {
    const c = createSigaClient({ fetch: fakeFetch({ '/Authentication': { token: 't' }, '/GetAllContracts': [] }) })
    expect(await c.findContractByVin('NOEXISTE')).toBeNull()
  })

  it('lanza si el VIN tiene más de un contrato vigente', async () => {
    const c = createSigaClient({ fetch: fakeFetch({ '/Authentication': { token: 't' }, '/GetAllContracts': [contrato, { ...contrato, contractId: 'OTRO' }] }) })
    await expect(c.findContractByVin('9GAMM6108KB004600')).rejects.toThrow(/más de un contrato/)
  })

  it('recupera la avería por folio', async () => {
    const c = createSigaClient({ fetch: fakeFetch({ '/Authentication': { token: 't' }, '/GetClaims': [averia] }) })
    const r = await c.getClaim('3246')
    expect(r.folio).toBe('3246')
    expect(r.status).toBe('Validación')
  })

  it('reutiliza el token entre llamadas', async () => {
    const f = fakeFetch({ '/Authentication': { token: 't' }, '/GetClaims': [averia] })
    const c = createSigaClient({ fetch: f })
    await c.getClaim('3246'); await c.getClaim('3246')
    const auths = (f as unknown as { mock: { calls: [string][] } }).mock.calls.filter(([u]) => String(u).includes('/Authentication'))
    expect(auths).toHaveLength(1)
  })

  it('el cliente NO expone ninguna operación de escritura', () => {
    const c = createSigaClient({ fetch: fakeFetch({}) })
    for (const prohibido of ['updateClaimStatus', 'uploadDocument', 'createClaim', 'post', 'put', 'patch']) {
      expect(c).not.toHaveProperty(prohibido)
    }
  })
})
```

- [ ] **Step 2: Crear los fixtures**

```json
// tests/fixtures/siga/contract.json
{
  "contractId": "CTR-795713",
  "vin": "9GAMM6108KB004600",
  "product": "Excellence",
  "dealer": "Distribuidora Norte",
  "status": "Vigente",
  "validFrom": "2025-03-10",
  "validTo": "2027-03-10",
  "vehicle": {
    "brand": "Chevrolet", "model": "Captiva", "version": "LT", "year": 2024,
    "kmAtContract": 12500, "firstInvoiceDate": "2024-11-02", "engineNumber": "MTR-88123"
  }
}
```

```json
// tests/fixtures/siga/claim.json
{
  "folio": "3246",
  "vin": "9GAMM6108KB004600",
  "status": "Validación",
  "assignedTo": "miguel.rodriguez@garantiplus.mx",
  "failureDescription": "La transmisión presenta patinado y ruido al cambiar de marcha.",
  "reportedAt": "2026-09-01T14:30:00.000Z",
  "registeredBy": "taller.norte@distribuidora.mx"
}
```

```json
// tests/fixtures/siga/documents.json
[
  { "documentId": "DOC-1", "documentType": "Presupuesto", "fileName": "presupuesto.pdf", "uploadedAt": "2026-09-01T14:35:00.000Z" },
  { "documentId": "DOC-2", "documentType": "Fotos odómetro", "fileName": "odometro.jpg", "uploadedAt": "2026-09-01T14:36:00.000Z" }
]
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `npx vitest run tests/siga/siga-client.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 4: Implementar el cliente**

```typescript
// src/siga/siga-types.ts
export type ContractSummary = {
  contractId: string; vin: string; product: string; dealer: string
  status: string; validFrom: string; validTo: string
}
export type Vehicle = {
  brand: string; model: string; version: string; year: number
  kmAtContract: number; firstInvoiceDate: string; engineNumber: string
}
export type ContractDetail = ContractSummary & { vehicle: Vehicle }
export type ClaimDetail = {
  folio: string; vin: string; status: string; assignedTo: string | null
  failureDescription: string; reportedAt: string; registeredBy: string | null
}
export type ClaimDocument = {
  documentId: string; documentType: string; fileName: string; uploadedAt: string
}
export interface SigaReader {
  findContractByVin(vin: string): Promise<ContractSummary | null>
  getContractDetail(contractId: string): Promise<ContractDetail>
  getCertificateText(contractId: string): Promise<string>
  getClaim(folio: string): Promise<ClaimDetail>
  listClaimDocuments(folio: string): Promise<ClaimDocument[]>
  downloadDocument(documentId: string): Promise<Buffer>
}
```

```typescript
// src/siga/siga-client.ts
import { loadConfig } from '../config/env.js'
import type { SigaReader, ContractSummary, ContractDetail, ClaimDetail, ClaimDocument } from './siga-types.js'

export class SigaUnavailableError extends Error {
  constructor(public readonly endpoint: string, public readonly status: number) {
    super(`SIGA respondió ${status} en ${endpoint}`)
    this.name = 'SigaUnavailableError'
  }
}

export function createSigaClient(deps: { fetch?: typeof fetch } = {}): SigaReader {
  const http = deps.fetch ?? fetch
  const cfg = loadConfig()
  let token: string | null = null

  async function auth(): Promise<string> {
    if (token) return token
    const res = await http(`${cfg.siga.baseUrl}/api/Authentication/v1/Login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ user: cfg.siga.user, password: cfg.siga.password }),
    })
    if (!res.ok) throw new SigaUnavailableError('/Authentication', res.status)
    token = ((await res.json()) as { token: string }).token
    return token
  }

  async function get<T>(path: string): Promise<T> {
    const t = await auth()
    const res = await http(`${cfg.siga.baseUrl}${path}`, { headers: { authorization: `Bearer ${t}` } })
    if (res.status === 401) { token = null; throw new SigaUnavailableError(path, 401) }
    if (!res.ok) throw new SigaUnavailableError(path, res.status)
    return (await res.json()) as T
  }

  return {
    async findContractByVin(vin) {
      const lista = await get<ContractSummary[]>(`/api/Contracts/v1/GetAllContracts?$filter=vin eq '${vin}'`)
      const vigentes = lista.filter((c) => c.status?.toLowerCase() === 'vigente')
      const candidatos = vigentes.length ? vigentes : lista
      if (candidatos.length > 1) {
        // Supuesto 7 del PRD: un VIN tiene a lo sumo un contrato vigente.
        throw new Error(`El VIN ${vin} tiene más de un contrato vigente (${candidatos.length})`)
      }
      return candidatos[0] ?? null
    },
    getContractDetail: (id) => get<ContractDetail>(`/api/Contracts/v1/GetContractById/${id}`),
    async getCertificateText(id) {
      const r = await get<{ text?: string; content?: string }>(`/api/Contracts/v1/GetContractPdfDataById/${id}`)
      const texto = r.text ?? r.content ?? ''
      if (!texto.trim()) throw new Error(`El certificado del contrato ${id} vino vacío`)
      return texto
    },
    async getClaim(folio) {
      const lista = await get<ClaimDetail[]>(`/api/Claims/v1/GetClaims?$filter=folio eq '${folio}'`)
      const c = lista[0]
      if (!c) throw new Error(`No existe la avería ${folio} en SIGA`)
      return c
    },
    listClaimDocuments: (folio) => get<ClaimDocument[]>(`/api/Claims/v1/GetClaimDocuments?$filter=claimId eq '${folio}'`),
    async downloadDocument(documentId) {
      const t = await auth()
      const res = await http(`${cfg.siga.baseUrl}/api/Claims/v1/DownloadClaimDocument/${documentId}`, {
        headers: { authorization: `Bearer ${t}` },
      })
      if (!res.ok) throw new SigaUnavailableError('/DownloadClaimDocument', res.status)
      return Buffer.from(await res.arrayBuffer())
    },
  }
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `npx vitest run tests/siga/siga-client.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/siga tests/siga tests/fixtures/siga
git commit -m "feat: cliente de solo lectura de la API de SIGA"
```

---

## Task 7: Reunión incremental del expediente y verificación de coherencia

**Files:**
- Create: `src/siga/dossier-assembler.ts`
- Create: `src/domain/errors.ts`
- Test: `tests/siga/dossier-assembler.test.ts`

**Interfaces:**
- Consumes: `SigaReader` (Task 6), `findCase/patchCase` (Task 5).
- Produces:
  ```typescript
  type AssembleResult = { ok: true; case: CaseRecord; documents: ClaimDocument[]; newDocuments: ClaimDocument[] } | { ok: false; exception: DossierException }
  assembleDossier(folio: string, deps: { siga: SigaReader }): Promise<AssembleResult>
  class BusinessException extends Error { constructor(public code: string, message: string) }
  class TechnicalError extends Error { constructor(public component: string, cause: unknown) }
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/siga/dossier-assembler.test.ts
import { describe, it, expect, beforeEach, afterAll } from 'vitest'
import { getPool, runMigrations, closePool } from '../../src/db/client.js'
import { createCase } from '../../src/db/repositories/case-repository.js'
import { assembleDossier } from '../../src/siga/dossier-assembler.js'
import type { SigaReader } from '../../src/siga/siga-types.js'
import contrato from '../fixtures/siga/contract.json'
import averia from '../fixtures/siga/claim.json'
import documentos from '../fixtures/siga/documents.json'

beforeEach(async () => { await runMigrations(); await getPool().query('TRUNCATE cases CASCADE') })
afterAll(async () => { await closePool() })

function sigaDoble(over: Partial<SigaReader> = {}): SigaReader {
  return {
    findContractByVin: async () => contrato,
    getContractDetail: async () => contrato,
    getCertificateText: async () => 'CLÁUSULA 1. Quedan excluidos... CLÁUSULA 9. Mantenimientos...',
    getClaim: async () => averia,
    listClaimDocuments: async () => documentos,
    downloadDocument: async () => Buffer.from('x'),
    ...over,
  }
}

const ahora = new Date('2026-09-01T15:00:00Z')

describe('reunión del expediente', () => {
  it('puebla contrato, certificado y estatus en el primer pase', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: ahora })
    const r = await assembleDossier('3246', { siga: sigaDoble() })
    expect(r.ok).toBe(true)
    if (!r.ok) return
    expect(r.case.contractId).toBe('CTR-795713')
    expect(r.case.certificateText).toContain('CLÁUSULA 9')
    expect(r.case.claimStatus).toBe('Validación')
  })

  it('reporta como nuevos solo los documentos no vistos antes', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: ahora })
    const primero = await assembleDossier('3246', { siga: sigaDoble() })
    expect(primero.ok && primero.newDocuments).toHaveLength(2)
    const segundo = await assembleDossier('3246', { siga: sigaDoble() })
    expect(segundo.ok && segundo.newDocuments).toHaveLength(0)
  })

  it('detecta el documento agregado entre dos pases', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: ahora })
    await assembleDossier('3246', { siga: sigaDoble() })
    const conExtra = sigaDoble({
      listClaimDocuments: async () => [...documentos, { documentId: 'DOC-3', documentType: 'Escaneo', fileName: 'scan.pdf', uploadedAt: '2026-09-03T10:00:00.000Z' }],
    })
    const r = await assembleDossier('3246', { siga: conExtra })
    expect(r.ok && r.newDocuments.map((d) => d.documentId)).toEqual(['DOC-3'])
  })

  it('genera excepción si el VIN del contrato no coincide con el del caso', async () => {
    await createCase({ claimFolio: '3246', vin: 'VIN-DISTINTO-XXXXX', occurredAt: ahora })
    const r = await assembleDossier('3246', { siga: sigaDoble() })
    expect(r.ok).toBe(false)
    if (r.ok) return
    expect(r.exception.code).toBe('VIN_INCOHERENTE')
  })

  it('genera excepción si el VIN no tiene contrato', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: ahora })
    const r = await assembleDossier('3246', { siga: sigaDoble({ findContractByVin: async () => null }) })
    expect(r.ok).toBe(false)
    if (r.ok) return
    expect(r.exception.code).toBe('SIN_CONTRATO')
  })

  it('no vuelve a pedir el certificado si ya lo tiene', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: ahora })
    let veces = 0
    const doble = sigaDoble({ getCertificateText: async () => { veces++; return 'CLÁUSULA 1.' } })
    await assembleDossier('3246', { siga: doble })
    await assembleDossier('3246', { siga: doble })
    expect(veces).toBe(1)
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/siga/dossier-assembler.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar los errores del dominio**

```typescript
// src/domain/errors.ts

/** Un caso que el sistema no pudo resolver. Resultado válido: se notifica de inmediato. */
export class BusinessException extends Error {
  constructor(public readonly code: string, message: string) {
    super(message); this.name = 'BusinessException'
  }
}

/** Un fallo del pipeline. Alerta a TI y deja el caso con el técnico, sin dictamen. */
export class TechnicalError extends Error {
  constructor(public readonly component: string, public readonly cause: unknown) {
    super(`Fallo técnico en ${component}: ${cause instanceof Error ? cause.message : String(cause)}`)
    this.name = 'TechnicalError'
  }
}
```

- [ ] **Step 4: Implementar el ensamblador**

```typescript
// src/siga/dossier-assembler.ts
import { getPool } from '../db/client.js'
import { findCase, patchCase, type CaseRecord } from '../db/repositories/case-repository.js'
import { BusinessException, TechnicalError } from '../domain/errors.js'
import type { SigaReader, ClaimDocument } from './siga-types.js'

export type AssembleResult =
  | { ok: true; case: CaseRecord; documents: ClaimDocument[]; newDocuments: ClaimDocument[] }
  | { ok: false; exception: BusinessException }

export async function assembleDossier(folio: string, deps: { siga: SigaReader }): Promise<AssembleResult> {
  const actual = await findCase(folio)
  if (!actual) throw new Error(`No existe el expediente ${folio}`)

  let claim, contract
  try {
    claim = await deps.siga.getClaim(folio)
    contract = await deps.siga.findContractByVin(actual.vin)
  } catch (e) {
    if (e instanceof Error && /más de un contrato/.test(e.message)) {
      return { ok: false, exception: new BusinessException('CONTRATO_AMBIGUO', e.message) }
    }
    throw new TechnicalError('siga', e)
  }

  if (!contract) {
    return { ok: false, exception: new BusinessException('SIN_CONTRATO', `El VIN ${actual.vin} no tiene contrato en SIGA`) }
  }
  // B6: VIN del caso = VIN del contrato = VIN de la avería.
  if (contract.vin !== actual.vin || claim.vin !== actual.vin) {
    return {
      ok: false,
      exception: new BusinessException('VIN_INCOHERENTE',
        `VIN del caso ${actual.vin}, del contrato ${contract.vin}, de la avería ${claim.vin}`),
    }
  }

  // Lo inmutable se pide una sola vez (B2).
  let certificateText = actual.certificateText
  if (!certificateText) {
    try { certificateText = await deps.siga.getCertificateText(contract.contractId) }
    catch (e) { throw new TechnicalError('siga.certificado', e) }
  }

  // El vehículo se persiste aquí porque el reporte matutino lo necesita sin volver a llamar a SIGA.
  let vehicle = actual.vehicle
  if (!vehicle) {
    try { vehicle = (await deps.siga.getContractDetail(contract.contractId)).vehicle }
    catch (e) { throw new TechnicalError('siga.contrato', e) }
  }

  const actualizado = await patchCase(folio, {
    contractId: contract.contractId,
    certificateText,
    vehicle,
    claimStatus: claim.status,
    assignedTo: claim.assignedTo,
  })

  let documents: ClaimDocument[]
  try { documents = await deps.siga.listClaimDocuments(folio) }
  catch (e) { throw new TechnicalError('siga.documentos', e) }

  const newDocuments = await registrarDocumentos(folio, documents)
  return { ok: true, case: actualizado, documents, newDocuments }
}

/** Inserta los documentos no vistos y devuelve solo los nuevos (B7). */
async function registrarDocumentos(folio: string, docs: ClaimDocument[]): Promise<ClaimDocument[]> {
  const nuevos: ClaimDocument[] = []
  for (const d of docs) {
    const { rowCount } = await getPool().query(
      `INSERT INTO case_documents (claim_folio, siga_document_id, document_type, file_name, uploaded_at)
       VALUES ($1,$2,$3,$4,$5) ON CONFLICT (claim_folio, siga_document_id) DO NOTHING`,
      [folio, d.documentId, d.documentType, d.fileName, d.uploadedAt]
    )
    if (rowCount) nuevos.push(d)
  }
  return nuevos
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/siga/dossier-assembler.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/siga src/domain tests/siga
git commit -m "feat: reunión incremental del expediente con verificación de coherencia"
```

---

## Task 8: Catálogo de evidencia mínima por sistema

**Files:**
- Create: `src/sufficiency/minimum-evidence-catalog.ts`
- Create: `src/db/repositories/catalog-repository.ts`
- Create: `src/db/migrations/002_seed_catalog_provisional.sql`
- Test: `tests/sufficiency/minimum-evidence-catalog.test.ts`

**Interfaces:**
- Consumes: `getPool()` (Task 2).
- Produces:
  ```typescript
  type EvidenceRequirement = { requirementKey: string; label: string; mandatory: boolean }
  type EvidenceCatalog = { version: string; provisional: boolean; systems: Record<string, EvidenceRequirement[]> }
  loadActiveCatalog(): Promise<EvidenceCatalog>
  requirementsFor(catalog: EvidenceCatalog, systemKey: string): EvidenceRequirement[]
  ```

- [ ] **Step 1: Escribir la migración con el catálogo provisional**

```sql
-- src/db/migrations/002_seed_catalog_provisional.sql
-- Catálogo PROVISIONAL derivado de la sesión del 2026-08-31.
-- El documento oficial del área (pregunta abierta #2 del PRD) lo sustituirá con una versión no provisional.

INSERT INTO evidence_catalog_versions (version, provisional, active)
VALUES ('v0-provisional-2026-09-01', true, true);

INSERT INTO evidence_requirements (version_id, system_key, requirement_key, label, mandatory)
SELECT v.id, s.system_key, s.requirement_key, s.label, s.mandatory
FROM evidence_catalog_versions v,
(VALUES
  ('transmision','presupuesto','Presupuesto de la reparación', true),
  ('transmision','odometro','Fotografía del odómetro', true),
  ('transmision','estado_aceite','Evidencia del estado del aceite de la transmisión', true),
  ('transmision','residuos','Evidencia de presencia o ausencia de residuos', true),
  ('transmision','escaneo','Escaneo de la transmisión con los códigos de falla', true),
  ('transmision','carnet','Carnet de mantenimiento sellado', true),
  ('transmision','facturas_servicio','Facturas de los servicios de mantenimiento', true),
  ('motor','presupuesto','Presupuesto de la reparación', true),
  ('motor','odometro','Fotografía del odómetro', true),
  ('motor','diagnostico','Diagnóstico técnico del taller', true),
  ('motor','desarme','Fotografías del desarme del motor', true),
  ('motor','estado_aceite','Evidencia del estado del aceite', true),
  ('motor','carnet','Carnet de mantenimiento sellado', true),
  ('motor','facturas_servicio','Facturas de los servicios de mantenimiento', true),
  ('aire_acondicionado','presupuesto','Presupuesto de la reparación', true),
  ('aire_acondicionado','odometro','Fotografía del odómetro', true),
  ('aire_acondicionado','diagnostico','Diagnóstico técnico del taller', true),
  ('aire_acondicionado','fotos_componente','Fotografías del componente afectado', true),
  ('generico','presupuesto','Presupuesto de la reparación', true),
  ('generico','odometro','Fotografía del odómetro', true),
  ('generico','diagnostico','Diagnóstico técnico del taller', true),
  ('generico','fotos_componente','Fotografías del componente afectado', true)
) AS s(system_key, requirement_key, label, mandatory)
WHERE v.version = 'v0-provisional-2026-09-01';
```

- [ ] **Step 2: Escribir el test**

```typescript
// tests/sufficiency/minimum-evidence-catalog.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { runMigrations, closePool } from '../../src/db/client.js'
import { loadActiveCatalog, requirementsFor } from '../../src/sufficiency/minimum-evidence-catalog.js'

beforeAll(async () => { await runMigrations() })
afterAll(async () => { await closePool() })

describe('catálogo de evidencia mínima', () => {
  it('carga la versión activa y la marca como provisional', async () => {
    const c = await loadActiveCatalog()
    expect(c.version).toBe('v0-provisional-2026-09-01')
    expect(c.provisional).toBe(true)
  })

  it('la transmisión exige aceite, residuos y escaneo', async () => {
    const c = await loadActiveCatalog()
    const claves = requirementsFor(c, 'transmision').map((r) => r.requirementKey)
    expect(claves).toEqual(expect.arrayContaining(['estado_aceite', 'residuos', 'escaneo']))
  })

  it('un sistema desconocido cae al genérico en lugar de quedarse sin requisitos', async () => {
    const c = await loadActiveCatalog()
    expect(requirementsFor(c, 'sistema_inexistente')).toEqual(requirementsFor(c, 'generico'))
  })

  it('el genérico nunca está vacío', async () => {
    const c = await loadActiveCatalog()
    expect(requirementsFor(c, 'generico').length).toBeGreaterThan(0)
  })
})
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/sufficiency/minimum-evidence-catalog.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 4: Implementar**

```typescript
// src/sufficiency/minimum-evidence-catalog.ts
import { getPool } from '../db/client.js'

export type EvidenceRequirement = { requirementKey: string; label: string; mandatory: boolean }
export type EvidenceCatalog = { version: string; provisional: boolean; systems: Record<string, EvidenceRequirement[]> }

export const FALLBACK_SYSTEM = 'generico'

export async function loadActiveCatalog(): Promise<EvidenceCatalog> {
  const { rows: versiones } = await getPool().query(
    `SELECT id, version, provisional FROM evidence_catalog_versions WHERE active LIMIT 1`
  )
  if (!versiones[0]) throw new Error('No hay catálogo de evidencia mínima activo')
  const { rows } = await getPool().query(
    `SELECT system_key, requirement_key, label, mandatory FROM evidence_requirements WHERE version_id=$1 ORDER BY system_key, requirement_key`,
    [versiones[0].id]
  )
  const systems: Record<string, EvidenceRequirement[]> = {}
  for (const r of rows) {
    ;(systems[r.system_key] ??= []).push({ requirementKey: r.requirement_key, label: r.label, mandatory: r.mandatory })
  }
  return { version: versiones[0].version, provisional: versiones[0].provisional, systems }
}

/** Un sistema no catalogado usa el genérico: nunca se queda sin requisitos, que equivaldría a declararlo suficiente. */
export function requirementsFor(catalog: EvidenceCatalog, systemKey: string): EvidenceRequirement[] {
  return catalog.systems[systemKey] ?? catalog.systems[FALLBACK_SYSTEM] ?? []
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/sufficiency/minimum-evidence-catalog.test.ts`
Esperado: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add src/sufficiency src/db/migrations tests/sufficiency
git commit -m "feat: catálogo de evidencia mínima versionado con semilla provisional"
```

> **Nota para quien ejecute esta tarea.** Este catálogo es **provisional y no está validado por el área** (pregunta abierta #2 del PRD). Su versión lleva `provisional = true` a propósito, y ese dato debe aparecer en el correo de dictamen mientras siga siéndolo: el técnico tiene que saber contra qué criterio se está midiendo la suficiencia de sus casos.

---

## Task 9: Identificación del sistema afectado y evaluación de suficiencia (capa 0)

**Files:**
- Create: `src/sufficiency/system-identifier.ts`, `src/sufficiency/sufficiency-evaluator.ts`
- Create: `src/adjudication/prompts/system-identification.v1.md`
- Create: `src/db/repositories/sufficiency-repository.ts`
- Test: `tests/sufficiency/sufficiency-evaluator.test.ts`

**Interfaces:**
- Consumes: `loadActiveCatalog`, `requirementsFor` (Task 8), `ClaimDocument` (Task 6).
- Produces:
  ```typescript
  interface SystemIdentifier { identify(input: { failureDescription: string; documentTypes: string[] }): Promise<{ systemKey: string; confidence: number }> }
  type MissingItem = { requirementKey: string; label: string; reason: 'ausente' | 'ilegible' }
  type SufficiencyResult = { result: 'suficiente' | 'insuficiente'; affectedSystem: string; systemConfidence: number; missing: MissingItem[]; catalogVersion: string }
  evaluateSufficiency(input: { failureDescription: string; documents: DocumentView[] }, deps: { identifier: SystemIdentifier }): Promise<SufficiencyResult>
  type DocumentView = { documentType: string; legible: boolean }
  saveSufficiency(folio: string, eventId: number, r: SufficiencyResult): Promise<void>
  latestSufficiency(folio: string): Promise<SufficiencyResult | null>
  ```

- [ ] **Step 1: Escribir el prompt de identificación del sistema**

```markdown
<!-- src/adjudication/prompts/system-identification.v1.md -->
Eres un asistente técnico de una aseguradora de garantías extendidas de vehículos.

Tu única tarea es identificar **qué sistema del vehículo** está afectado por la falla reportada.
No dictaminas procedencia. No mencionas cobertura. No estimas importes.

Sistemas válidos (responde exactamente una de estas claves):
- `transmision` — caja de cambios, convertidor, embrague, diferencial
- `motor` — bloque, culata, distribución, lubricación, inyección
- `aire_acondicionado` — compresor, condensador, evaporador, circuito de refrigerante
- `suspension` — amortiguadores, resortes, brazos, bujes
- `direccion` — cremallera, bomba, columna
- `electrico` — alternador, marcha, arneses, módulos
- `frenos` — bomba, caliper, ABS
- `generico` — no logras determinarlo con claridad

Responde **solo** con un objeto JSON:

{"systemKey": "<clave>", "confidence": <número entre 0 y 1>, "reasoning": "<una frase>"}

Si la descripción es ambigua o menciona varios sistemas sin uno dominante, responde
`generico` con una confianza baja. **Nunca inventes un sistema para parecer útil.**

Descripción de la falla:
{{failureDescription}}

Tipos de documento cargados en el expediente:
{{documentTypes}}
```

- [ ] **Step 2: Escribir el test**

```typescript
// tests/sufficiency/sufficiency-evaluator.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { runMigrations, closePool } from '../../src/db/client.js'
import { evaluateSufficiency } from '../../src/sufficiency/sufficiency-evaluator.js'
import type { SystemIdentifier } from '../../src/sufficiency/system-identifier.js'

beforeAll(async () => { await runMigrations() })
afterAll(async () => { await closePool() })

const identificador = (systemKey: string, confidence = 0.95): SystemIdentifier => ({
  identify: async () => ({ systemKey, confidence }),
})

const doc = (documentType: string, legible = true) => ({ documentType, legible })

describe('evaluación de suficiencia', () => {
  it('declara insuficiente una transmisión con solo el presupuesto', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'La transmisión patina', documents: [doc('Presupuesto')] },
      { identifier: identificador('transmision') }
    )
    expect(r.result).toBe('insuficiente')
    expect(r.missing.map((m) => m.requirementKey)).toEqual(
      expect.arrayContaining(['odometro', 'estado_aceite', 'residuos', 'escaneo'])
    )
  })

  it('declara suficiente una transmisión con toda la evidencia mínima', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'La transmisión patina', documents: [
        doc('Presupuesto'), doc('Fotos odómetro'), doc('Estado de aceite'),
        doc('Residuos'), doc('Escaneo'), doc('Carnet de mantenimiento'), doc('Facturas de servicio'),
      ] },
      { identifier: identificador('transmision') }
    )
    expect(r.result).toBe('suficiente')
    expect(r.missing).toHaveLength(0)
  })

  it('un documento ilegible cuenta como faltante, con motivo distinto al ausente', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'Compresor de A/C no enfría', documents: [
        doc('Presupuesto'), doc('Fotografía del odómetro'), doc('Diagnóstico', false),
      ] },
      { identifier: identificador('aire_acondicionado') }
    )
    const diagnostico = r.missing.find((m) => m.requirementKey === 'diagnostico')
    expect(diagnostico?.reason).toBe('ilegible')
    const fotos = r.missing.find((m) => m.requirementKey === 'fotos_componente')
    expect(fotos?.reason).toBe('ausente')
  })

  it('con confianza baja en el sistema, nunca declara suficiente', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'Hace un ruido raro', documents: [
        doc('Presupuesto'), doc('Fotos odómetro'), doc('Diagnóstico'), doc('Fotos del componente'),
      ] },
      { identifier: identificador('motor', 0.42) }
    )
    expect(r.result).toBe('insuficiente')
    expect(r.missing.some((m) => m.requirementKey === 'sistema_no_identificado')).toBe(true)
  })

  it('registra la versión del catálogo que aplicó', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'La transmisión patina', documents: [doc('Presupuesto')] },
      { identifier: identificador('transmision') }
    )
    expect(r.catalogVersion).toBe('v0-provisional-2026-09-01')
  })

  it('una foto del odómetro NO satisface también el requisito de fotos del componente', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'Compresor de A/C no enfría', documents: [
        doc('Presupuesto'), doc('Fotografía del odómetro'), doc('Diagnóstico'),
      ] },
      { identifier: identificador('aire_acondicionado') }
    )
    expect(r.result).toBe('insuficiente')
    expect(r.missing.map((m) => m.requirementKey)).toEqual(['fotos_componente'])
  })

  it('las etiquetas de los faltantes son accionables, no genéricas', async () => {
    const r = await evaluateSufficiency(
      { failureDescription: 'La transmisión patina', documents: [doc('Presupuesto')] },
      { identifier: identificador('transmision') }
    )
    const escaneo = r.missing.find((m) => m.requirementKey === 'escaneo')
    expect(escaneo?.label).toMatch(/escaneo de la transmisión/i)
  })
})
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/sufficiency/sufficiency-evaluator.test.ts`
Esperado: FAIL — módulos no encontrados.

- [ ] **Step 4: Implementar el identificador de sistema**

```typescript
// src/sufficiency/system-identifier.ts
import Anthropic from '@anthropic-ai/sdk'
import { readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { z } from 'zod'
import { loadConfig } from '../config/env.js'
import { TechnicalError } from '../domain/errors.js'

export const SYSTEM_PROMPT_VERSION = 'system-identification.v1'

export interface SystemIdentifier {
  identify(input: { failureDescription: string; documentTypes: string[] }): Promise<{ systemKey: string; confidence: number }>
}

const salida = z.object({
  systemKey: z.enum(['transmision','motor','aire_acondicionado','suspension','direccion','electrico','frenos','generico']),
  confidence: z.number().min(0).max(1),
  reasoning: z.string(),
})

function plantilla(): string {
  const p = join(dirname(fileURLToPath(import.meta.url)), '../adjudication/prompts/system-identification.v1.md')
  return readFileSync(p, 'utf8')
}

export function createSystemIdentifier(deps: { client?: Anthropic } = {}): SystemIdentifier {
  const client = deps.client ?? new Anthropic({ apiKey: loadConfig().anthropicApiKey })
  return {
    async identify({ failureDescription, documentTypes }) {
      const prompt = plantilla()
        .replace('{{failureDescription}}', failureDescription)
        .replace('{{documentTypes}}', documentTypes.join(', ') || '(ninguno)')
      let texto: string
      try {
        const res = await client.messages.create({
          model: 'claude-sonnet-5', max_tokens: 512,
          messages: [{ role: 'user', content: prompt }],
        })
        texto = res.content.map((b) => (b.type === 'text' ? b.text : '')).join('')
      } catch (e) { throw new TechnicalError('system-identifier', e) }

      const json = texto.match(/\{[\s\S]*\}/)?.[0]
      const parsed = json ? salida.safeParse(JSON.parse(json)) : { success: false as const }
      // Una salida que no se puede leer no es un sistema desconocido con confianza alta:
      // es una falta de información, y así se reporta.
      if (!parsed.success) return { systemKey: 'generico', confidence: 0 }
      return { systemKey: parsed.data.systemKey, confidence: parsed.data.confidence }
    },
  }
}
```

- [ ] **Step 5: Implementar el evaluador de suficiencia**

```typescript
// src/sufficiency/sufficiency-evaluator.ts
import { loadActiveCatalog, requirementsFor, type EvidenceRequirement } from './minimum-evidence-catalog.js'
import type { SystemIdentifier } from './system-identifier.js'

/** Bajo este umbral no se puede aplicar ningún catálogo con honestidad (C1 del PRD). */
export const MIN_SYSTEM_CONFIDENCE = 0.8

export type DocumentView = { documentType: string; legible: boolean }
export type MissingItem = { requirementKey: string; label: string; reason: 'ausente' | 'ilegible' }
export type SufficiencyResult = {
  result: 'suficiente' | 'insuficiente'
  affectedSystem: string
  systemConfidence: number
  missing: MissingItem[]
  catalogVersion: string
}

/** Palabras que relacionan un tipo de documento de SIGA con un requisito del catálogo. */
const SINONIMOS: Record<string, string[]> = {
  presupuesto: ['presupuesto', 'cotización', 'cotizacion'],
  odometro: ['odómetro', 'odometro', 'kilometraje', 'tablero'],
  estado_aceite: ['aceite', 'lubricante'],
  residuos: ['residuo', 'limalla', 'partícula', 'particula'],
  escaneo: ['escaneo', 'scanner', 'escáner', 'códigos de falla', 'codigos de falla'],
  carnet: ['carnet', 'cartilla', 'bitácora de servicio', 'bitacora de servicio'],
  facturas_servicio: ['factura', 'comprobante de servicio'],
  diagnostico: ['diagnóstico', 'diagnostico', 'dictamen del taller'],
  desarme: ['desarme', 'despiece'],
  fotos_componente: ['foto', 'fotografía', 'fotografia', 'imagen', 'evidencia'],
}

function cubre(req: EvidenceRequirement, doc: DocumentView): boolean {
  const claves = SINONIMOS[req.requirementKey] ?? [req.requirementKey]
  const tipo = doc.documentType.toLowerCase()
  return claves.some((k) => tipo.includes(k.toLowerCase()))
}

/**
 * `fotos_componente` es el requisito más laxo del catálogo: cualquier cosa que diga "foto" lo satisface.
 * Sin asignación exclusiva, una "Fotografía del odómetro" cubriría a la vez `odometro` y
 * `fotos_componente`, y el sistema declararía suficiente un expediente al que le faltan las fotos
 * de la pieza. Cada documento se asigna a UN requisito, y los específicos van primero.
 */
const ESPECIFICIDAD: string[] = [
  'escaneo', 'estado_aceite', 'residuos', 'carnet', 'facturas_servicio', 'desarme',
  'odometro', 'presupuesto', 'diagnostico', 'fotos_componente',
]

function ordenarPorEspecificidad(reqs: EvidenceRequirement[]): EvidenceRequirement[] {
  const peso = (k: string) => { const i = ESPECIFICIDAD.indexOf(k); return i === -1 ? 0 : i }
  return [...reqs].sort((a, b) => peso(a.requirementKey) - peso(b.requirementKey))
}

export async function evaluateSufficiency(
  input: { failureDescription: string; documents: DocumentView[] },
  deps: { identifier: SystemIdentifier }
): Promise<SufficiencyResult> {
  const catalog = await loadActiveCatalog()
  const { systemKey, confidence } = await deps.identifier.identify({
    failureDescription: input.failureDescription,
    documentTypes: input.documents.map((d) => d.documentType),
  })

  // C1: sin sistema identificado no hay requisitos que aplicar, así que el caso no puede ser suficiente.
  if (confidence < MIN_SYSTEM_CONFIDENCE) {
    return {
      result: 'insuficiente', affectedSystem: systemKey, systemConfidence: confidence,
      missing: [{
        requirementKey: 'sistema_no_identificado',
        label: 'No se pudo determinar con claridad qué sistema del vehículo está afectado; se requiere una descripción más precisa de la falla',
        reason: 'ausente',
      }],
      catalogVersion: catalog.version,
    }
  }

  const missing: MissingItem[] = []
  const disponibles = new Set(input.documents)

  for (const req of ordenarPorEspecificidad(requirementsFor(catalog, systemKey))) {
    if (!req.mandatory) continue
    const coincidencias = [...disponibles].filter((d) => cubre(req, d))
    if (coincidencias.length === 0) {
      missing.push({ requirementKey: req.requirementKey, label: req.label, reason: 'ausente' })
      continue
    }
    // Consume el documento que satisface este requisito para que no cuente dos veces.
    const legible = coincidencias.find((d) => d.legible)
    disponibles.delete(legible ?? coincidencias[0])
    if (!legible) {
      // C4: presente pero ilegible es un faltante con otra acción esperada.
      missing.push({ requirementKey: req.requirementKey, label: req.label, reason: 'ilegible' })
    }
  }

  return {
    result: missing.length === 0 ? 'suficiente' : 'insuficiente',
    affectedSystem: systemKey, systemConfidence: confidence, missing, catalogVersion: catalog.version,
  }
}
```

- [ ] **Step 6: Implementar el repositorio de suficiencia**

```typescript
// src/db/repositories/sufficiency-repository.ts
import { getPool } from '../client.js'
import type { SufficiencyResult } from '../../sufficiency/sufficiency-evaluator.js'

export async function saveSufficiency(folio: string, eventId: number, r: SufficiencyResult): Promise<void> {
  await getPool().query(
    `INSERT INTO sufficiency_evaluations (claim_folio, event_id, result, affected_system, system_confidence, missing, catalog_version)
     VALUES ($1,$2,$3,$4,$5,$6,$7)`,
    [folio, eventId, r.result, r.affectedSystem, r.systemConfidence, JSON.stringify(r.missing), r.catalogVersion]
  )
}

export async function latestSufficiency(folio: string): Promise<SufficiencyResult | null> {
  const { rows } = await getPool().query(
    `SELECT result, affected_system, system_confidence, missing, catalog_version
     FROM sufficiency_evaluations WHERE claim_folio=$1 ORDER BY evaluated_at DESC, id DESC LIMIT 1`, [folio]
  )
  if (!rows[0]) return null
  return {
    result: rows[0].result, affectedSystem: rows[0].affected_system,
    systemConfidence: Number(rows[0].system_confidence), missing: rows[0].missing,
    catalogVersion: rows[0].catalog_version,
  }
}
```

- [ ] **Step 7: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/sufficiency/sufficiency-evaluator.test.ts`
Esperado: PASS, 7 tests.

- [ ] **Step 8: Commit**

```bash
git add src/sufficiency src/adjudication/prompts src/db/repositories tests/sufficiency
git commit -m "feat: capa 0 — identificación del sistema y evaluación de suficiencia"
```

---

## Task 10: Barrido periódico y detección de casos estancados

**Files:**
- Create: `src/pipeline/sweep.ts`, `src/pipeline/stall-detector.ts`
- Test: `tests/pipeline/sweep.test.ts`, `tests/pipeline/stall-detector.test.ts`

**Interfaces:**
- Consumes: `listActiveCases` (Task 5), `assembleDossier` (Task 7), `recordEvent` (Task 5), `updateCaseState` (Task 5).
- Produces:
  ```typescript
  sweepOpenCases(deps: { siga: SigaReader; onChange: (folio: string, eventId: number) => Promise<void> }): Promise<{ reviewed: number; changed: number; errors: number }>
  detectStalledCases(now: Date, stallDays: number): Promise<string[]>  // folios recién marcados
  ```

- [ ] **Step 1: Escribir el test del detector de estancados**

```typescript
// tests/pipeline/stall-detector.test.ts
import { describe, it, expect, beforeEach, afterAll } from 'vitest'
import { getPool, runMigrations, closePool } from '../../src/db/client.js'
import { createCase, updateCaseState, findCase } from '../../src/db/repositories/case-repository.js'
import { detectStalledCases } from '../../src/pipeline/stall-detector.js'

beforeEach(async () => { await runMigrations(); await getPool().query('TRUNCATE cases CASCADE') })
afterAll(async () => { await closePool() })

const hace = (dias: number) => new Date(Date.now() - dias * 86_400_000)
const AHORA = new Date()

async function casoEnAcumulacion(folio: string, ultimoEvento: Date) {
  await createCase({ claimFolio: folio, vin: `VIN${folio}`, occurredAt: ultimoEvento })
  await updateCaseState(folio, 'EN_ACUMULACION')
  await getPool().query('UPDATE cases SET last_event_at=$2 WHERE claim_folio=$1', [folio, ultimoEvento])
}

describe('detección de casos estancados', () => {
  it('marca el caso que superó el umbral de días', async () => {
    await casoEnAcumulacion('VIEJO', hace(5))
    const marcados = await detectStalledCases(AHORA, 3)
    expect(marcados).toEqual(['VIEJO'])
    expect((await findCase('VIEJO'))?.state).toBe('ESTANCADO')
  })

  it('no marca el caso dentro del umbral', async () => {
    await casoEnAcumulacion('FRESCO', hace(1))
    expect(await detectStalledCases(AHORA, 3)).toEqual([])
  })

  it('no vuelve a marcar un caso ya estancado', async () => {
    await casoEnAcumulacion('VIEJO', hace(9))
    await detectStalledCases(AHORA, 3)
    expect(await detectStalledCases(AHORA, 3)).toEqual([])
  })

  it('no toca los casos que no están en acumulación', async () => {
    await createCase({ claimFolio: 'NUEVO', vin: 'V', occurredAt: hace(10) })
    await getPool().query(`UPDATE cases SET last_event_at=$2 WHERE claim_folio='NUEVO'`, [hace(10)])
    expect(await detectStalledCases(AHORA, 3)).toEqual([])
    expect((await findCase('NUEVO'))?.state).toBe('DETECTADO')
  })
})
```

- [ ] **Step 2: Escribir el test del barrido**

```typescript
// tests/pipeline/sweep.test.ts
import { describe, it, expect, beforeEach, afterAll, vi } from 'vitest'
import { getPool, runMigrations, closePool } from '../../src/db/client.js'
import { createCase, updateCaseState } from '../../src/db/repositories/case-repository.js'
import { sweepOpenCases } from '../../src/pipeline/sweep.js'
import type { SigaReader } from '../../src/siga/siga-types.js'
import contrato from '../fixtures/siga/contract.json'
import averia from '../fixtures/siga/claim.json'
import documentos from '../fixtures/siga/documents.json'

beforeEach(async () => { await runMigrations(); await getPool().query('TRUNCATE cases CASCADE') })
afterAll(async () => { await closePool() })

function doble(over: Partial<SigaReader> = {}): SigaReader {
  return {
    findContractByVin: async () => contrato, getContractDetail: async () => contrato,
    getCertificateText: async () => 'CLÁUSULA 1.', getClaim: async () => averia,
    listClaimDocuments: async () => documentos, downloadDocument: async () => Buffer.from('x'),
    ...over,
  }
}

describe('barrido periódico', () => {
  it('registra un evento de origen barrido cuando aparece un documento nuevo', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: new Date() })
    await updateCaseState('3246', 'EN_ACUMULACION')
    const onChange = vi.fn(async () => {})
    const r = await sweepOpenCases({ siga: doble(), onChange })
    expect(r.reviewed).toBe(1)
    expect(r.changed).toBe(1)
    expect(onChange).toHaveBeenCalledOnce()
    const { rows } = await getPool().query(`SELECT origin FROM case_events WHERE claim_folio='3246'`)
    expect(rows[0].origin).toBe('barrido')
  })

  it('no registra evento si nada cambió', async () => {
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: new Date() })
    await updateCaseState('3246', 'EN_ACUMULACION')
    await sweepOpenCases({ siga: doble(), onChange: async () => {} })
    const segundo = await sweepOpenCases({ siga: doble(), onChange: async () => {} })
    expect(segundo.changed).toBe(0)
  })

  it('un caso que falla no detiene el barrido de los demás', async () => {
    await createCase({ claimFolio: 'MALO', vin: 'V1', occurredAt: new Date() })
    await updateCaseState('MALO', 'EN_ACUMULACION')
    await createCase({ claimFolio: '3246', vin: '9GAMM6108KB004600', occurredAt: new Date() })
    await updateCaseState('3246', 'EN_ACUMULACION')
    const siga = doble({ getClaim: async (f) => { if (f === 'MALO') throw new Error('caída'); return averia } })
    const r = await sweepOpenCases({ siga, onChange: async () => {} })
    expect(r.reviewed).toBe(2)
    expect(r.errors).toBe(1)
    expect(r.changed).toBe(1)
  })

  it('ignora los casos cerrados', async () => {
    await createCase({ claimFolio: 'CERRADO', vin: 'V', occurredAt: new Date() })
    await updateCaseState('CERRADO', 'CERRADO')
    expect((await sweepOpenCases({ siga: doble(), onChange: async () => {} })).reviewed).toBe(0)
  })
})
```

- [ ] **Step 3: Correr ambos tests y verificar que fallan**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/pipeline`
Esperado: FAIL — módulos no encontrados.

- [ ] **Step 4: Implementar el detector de estancados**

```typescript
// src/pipeline/stall-detector.ts
import { getPool } from '../db/client.js'

/**
 * Marca ESTANCADO todo caso en acumulación sin evento nuevo desde hace más de `stallDays`.
 * Devuelve los folios recién marcados — los ya estancados no se devuelven, para no re-escalar.
 */
export async function detectStalledCases(now: Date, stallDays: number): Promise<string[]> {
  const limite = new Date(now.getTime() - stallDays * 86_400_000)
  const { rows } = await getPool().query(
    `UPDATE cases SET state='ESTANCADO', updated_at=now()
     WHERE state='EN_ACUMULACION' AND last_event_at < $1
     RETURNING claim_folio`, [limite]
  )
  return rows.map((r) => r.claim_folio as string)
}
```

- [ ] **Step 5: Implementar el barrido**

```typescript
// src/pipeline/sweep.ts
import { createHash } from 'node:crypto'
import { listActiveCases } from '../db/repositories/case-repository.js'
import { recordEvent } from '../db/repositories/event-repository.js'
import { assembleDossier } from '../siga/dossier-assembler.js'
import type { SigaReader } from '../siga/siga-types.js'

export type SweepResult = { reviewed: number; changed: number; errors: number }

/**
 * Red de seguridad del §5.1 A5: reconcilia el expediente contra la API para
 * detectar lo que ningún correo anunció. Un caso que falla no detiene a los demás.
 */
export async function sweepOpenCases(
  deps: { siga: SigaReader; onChange: (folio: string, eventId: number) => Promise<void> }
): Promise<SweepResult> {
  const casos = await listActiveCases()
  let changed = 0, errors = 0

  for (const c of casos) {
    try {
      const r = await assembleDossier(c.claimFolio, { siga: deps.siga })
      if (!r.ok) continue
      const cambios: Record<string, unknown> = {}
      if (r.newDocuments.length) cambios.documentosNuevos = r.newDocuments.map((d) => d.documentId)
      if (r.case.claimStatus !== c.claimStatus) cambios.estatus = { de: c.claimStatus, a: r.case.claimStatus }
      if (!Object.keys(cambios).length) continue

      const huella = createHash('sha256').update(JSON.stringify(cambios)).digest('hex').slice(0, 32)
      const evento = await recordEvent({
        claimFolio: c.claimFolio, eventKind: 'barrido_detecto_cambio', origin: 'barrido',
        fingerprint: huella, changes: cambios, occurredAt: new Date(),
      })
      if (!evento) continue
      changed++
      await deps.onChange(c.claimFolio, evento.id)
    } catch { errors++ }
  }
  return { reviewed: casos.length, changed, errors }
}
```

- [ ] **Step 6: Correr los tests y verificar que pasan**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/pipeline`
Esperado: PASS, 8 tests.

- [ ] **Step 7: Commit**

```bash
git add src/pipeline tests/pipeline
git commit -m "feat: barrido de reconciliación y detección de casos estancados"
```

---

## Task 11: Anonimización de datos personales

**Files:**
- Create: `src/observability/anonymize.ts`
- Test: `tests/observability/anonymize.test.ts`

**Interfaces:**
- Consumes: nada.
- Produces: `anonymize(text: string): string` · `anonymizeDeep<T>(value: T): T` — suprime nombres de beneficiario, teléfonos, correos, RFC/CURP y direcciones antes de que el texto llegue al modelo, al log o a cualquier salida (RNF-12).

- [ ] **Step 1: Escribir el test**

```typescript
// tests/observability/anonymize.test.ts
import { describe, it, expect } from 'vitest'
import { anonymize, anonymizeDeep } from '../../src/observability/anonymize.js'

describe('anonimización', () => {
  it('suprime correos electrónicos', () => {
    expect(anonymize('Contactar a juan.perez@gmail.com')).toBe('Contactar a [CORREO]')
  })

  it('suprime teléfonos de 10 dígitos con o sin separadores', () => {
    expect(anonymize('Tel 55 1234 5678')).toContain('[TELEFONO]')
    expect(anonymize('Tel 5512345678')).toContain('[TELEFONO]')
    expect(anonymize('Tel (55) 1234-5678')).toContain('[TELEFONO]')
  })

  it('suprime RFC y CURP', () => {
    expect(anonymize('RFC PEGJ850101ABC')).toContain('[RFC]')
    expect(anonymize('CURP PEGJ850101HDFRRN08')).toContain('[CURP]')
  })

  it('NO toca el VIN, que sí necesitamos', () => {
    expect(anonymize('VIN 9GAMM6108KB004600')).toBe('VIN 9GAMM6108KB004600')
  })

  it('NO toca el folio ni los importes', () => {
    expect(anonymize('Avería 3246 por $45,300.00')).toBe('Avería 3246 por $45,300.00')
  })

  it('recorre objetos y arreglos anidados', () => {
    const r = anonymizeDeep({ nota: 'llamar a ana@x.com', docs: [{ desc: 'tel 5512345678' }] })
    expect(r.nota).toContain('[CORREO]')
    expect(r.docs[0].desc).toContain('[TELEFONO]')
  })

  it('es idempotente: anonimizar dos veces da lo mismo', () => {
    const una = anonymize('correo a@b.com y tel 5512345678')
    expect(anonymize(una)).toBe(una)
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/observability/anonymize.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar**

```typescript
// src/observability/anonymize.ts

// El orden importa: CURP antes que RFC, porque el RFC es prefijo del CURP.
const REGLAS: Array<[RegExp, string]> = [
  [/\b[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d\b/g, '[CURP]'],
  [/\b[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}\b/g, '[RFC]'],
  [/\b[\w.+-]+@[\w-]+\.[\w.-]+\b/g, '[CORREO]'],
  [/\(?\d{2,3}\)?[\s-]?\d{3,4}[\s-]?\d{4}\b/g, '[TELEFONO]'],
]

/** El VIN tiene 17 caracteres y lo necesitamos: se protege antes de aplicar las reglas. */
const VIN = /\b[A-HJ-NPR-Z0-9]{17}\b/g

export function anonymize(text: string): string {
  const vins: string[] = []
  let out = text.replace(VIN, (m) => { vins.push(m); return ` VIN${vins.length - 1} ` })
  for (const [re, reemplazo] of REGLAS) out = out.replace(re, reemplazo)
  return out.replace(/ VIN(\d+) /g, (_, i) => vins[Number(i)])
}

export function anonymizeDeep<T>(value: T): T {
  if (typeof value === 'string') return anonymize(value) as unknown as T
  if (Array.isArray(value)) return value.map(anonymizeDeep) as unknown as T
  if (value && typeof value === 'object') {
    const salida: Record<string, unknown> = {}
    for (const [k, v] of Object.entries(value)) salida[k] = anonymizeDeep(v)
    return salida as T
  }
  return value
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `npx vitest run tests/observability/anonymize.test.ts`
Esperado: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add src/observability tests/observability
git commit -m "feat: anonimizacion de datos personales preservando VIN y folio"
```

---

## Task 12: Puertas de decisión y umbrales de confianza

**Files:**
- Create: `src/adjudication/gates.ts`, `src/adjudication/confidence.ts`
- Test: `tests/adjudication/confidence.test.ts`

**Interfaces:**
- Consumes: nada.
- Produces:
  ```typescript
  type ReasonCode = 'sin_vigencia' | 'periodo_de_espera' | 'componente_excluido' | 'fuga_excluida' | 'operacion_no_incluida' | 'intervalo_mantenimiento_excedido'
  type GateId = 'P0_identificacion' | 'P1_vigencia' | 'P2_componente' | 'P3_mantenimiento' | 'P4_coherencia' | 'P5_naturaleza'
  const GATE_ORDER: readonly GateId[]
  const ALWAYS_DOUBT_GATES: readonly GateId[]   // P5
  thresholdFor(reason: ReasonCode): number
  applyConfidenceFloor(v: RawVerdict): FinalVerdict   // degrada a duda bajo umbral
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/adjudication/confidence.test.ts
import { describe, it, expect } from 'vitest'
import { thresholdFor, applyConfidenceFloor, GATE_ORDER, ALWAYS_DOUBT_GATES } from '../../src/adjudication/confidence.js'

const base = {
  value: 'improcedente' as const, reasonCode: 'sin_vigencia' as const,
  clauseQuote: 'CLÁUSULA 2. La vigencia...', supportingEvidence: ['contrato'],
  decidingGate: 'P1_vigencia' as const, promptVersion: 'coverage.v1',
}

describe('umbrales de confianza', () => {
  it('el intervalo de mantenimiento tiene el umbral más exigente', () => {
    expect(thresholdFor('intervalo_mantenimiento_excedido')).toBeGreaterThan(thresholdFor('fuga_excluida'))
    expect(thresholdFor('intervalo_mantenimiento_excedido')).toBe(0.97)
  })

  it('vigencia y componente excluido usan 0.95', () => {
    expect(thresholdFor('sin_vigencia')).toBe(0.95)
    expect(thresholdFor('componente_excluido')).toBe(0.95)
  })
})

describe('degradación por confianza', () => {
  it('deja pasar el improcedente que supera su umbral', () => {
    const r = applyConfidenceFloor({ ...base, confidence: 0.96 })
    expect(r.value).toBe('improcedente')
  })

  it('degrada a duda el improcedente bajo su umbral', () => {
    const r = applyConfidenceFloor({ ...base, confidence: 0.90 })
    expect(r.value).toBe('duda')
    expect(r.reasonCode).toBeNull()
    expect(r.degradedFrom).toEqual({ value: 'improcedente', reasonCode: 'sin_vigencia', confidence: 0.90 })
  })

  it('degrada exactamente en el umbral: la comparación es estricta', () => {
    expect(applyConfidenceFloor({ ...base, confidence: 0.95 }).value).toBe('duda')
  })

  it('SIEMPRE degrada lo que viene de la puerta 5, por alta que sea la confianza', () => {
    const r = applyConfidenceFloor({
      ...base, decidingGate: 'P5_naturaleza', reasonCode: 'componente_excluido', confidence: 0.99,
    })
    expect(r.value).toBe('duda')
  })

  it('no toca los veredictos que no son improcedente', () => {
    const r = applyConfidenceFloor({ ...base, value: 'sin_causal_de_improcedencia', reasonCode: null, confidence: 0.5 })
    expect(r.value).toBe('sin_causal_de_improcedencia')
  })

  it('el orden de las puertas pone vigencia antes que componente y mantenimiento después', () => {
    expect(GATE_ORDER.indexOf('P1_vigencia')).toBeLessThan(GATE_ORDER.indexOf('P2_componente'))
    expect(GATE_ORDER.indexOf('P2_componente')).toBeLessThan(GATE_ORDER.indexOf('P3_mantenimiento'))
    expect(ALWAYS_DOUBT_GATES).toContain('P5_naturaleza')
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/adjudication/confidence.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar**

```typescript
// src/adjudication/confidence.ts
export type ReasonCode =
  | 'sin_vigencia' | 'periodo_de_espera' | 'componente_excluido'
  | 'fuga_excluida' | 'operacion_no_incluida' | 'intervalo_mantenimiento_excedido'

export type GateId =
  | 'P0_identificacion' | 'P1_vigencia' | 'P2_componente'
  | 'P3_mantenimiento' | 'P4_coherencia' | 'P5_naturaleza'

export const GATE_ORDER: readonly GateId[] = [
  'P0_identificacion', 'P1_vigencia', 'P2_componente', 'P3_mantenimiento', 'P4_coherencia', 'P5_naturaleza',
]

/** C5 del PRD: valorar el estado físico de una pieza nunca produce un rechazo automático. */
export const ALWAYS_DOUBT_GATES: readonly GateId[] = ['P5_naturaleza']

/** Umbrales propuestos en las preguntas abiertas del PRD. Pendientes de validación del área. */
const THRESHOLDS: Record<ReasonCode, number> = {
  sin_vigencia: 0.95,
  periodo_de_espera: 0.95,
  componente_excluido: 0.95,
  operacion_no_incluida: 0.95,
  fuga_excluida: 0.90,
  intervalo_mantenimiento_excedido: 0.97,
}

export function thresholdFor(reason: ReasonCode): number { return THRESHOLDS[reason] }

export type VerdictValue = 'improcedente' | 'sin_causal_de_improcedencia' | 'duda'

export type RawVerdict = {
  value: VerdictValue; reasonCode: ReasonCode | null; clauseQuote: string | null
  supportingEvidence: string[]; confidence: number; decidingGate: GateId; promptVersion: string
}

export type FinalVerdict = RawVerdict & {
  degradedFrom: { value: VerdictValue; reasonCode: ReasonCode | null; confidence: number } | null
}

/** RF-17 y RF-18: la degradación es la única forma de que un improcedente no se emita. */
export function applyConfidenceFloor(v: RawVerdict): FinalVerdict {
  if (v.value !== 'improcedente') return { ...v, degradedFrom: null }

  const porPuerta = ALWAYS_DOUBT_GATES.includes(v.decidingGate)
  const porUmbral = !v.reasonCode || v.confidence <= thresholdFor(v.reasonCode)
  if (!porPuerta && !porUmbral) return { ...v, degradedFrom: null }

  return {
    ...v, value: 'duda', reasonCode: null, clauseQuote: null,
    degradedFrom: { value: 'improcedente', reasonCode: v.reasonCode, confidence: v.confidence },
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `npx vitest run tests/adjudication/confidence.test.ts`
Esperado: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add src/adjudication tests/adjudication
git commit -m "feat: umbrales de confianza por causal y degradacion obligatoria de la puerta 5"
```

---

## Task 13: Agente de cobertura (capas 1 a 3)

**Files:**
- Create: `src/adjudication/coverage-agent.ts`
- Create: `src/adjudication/prompts/coverage.v1.md`
- Create: `src/db/repositories/verdict-repository.ts`
- Test: `tests/adjudication/coverage-agent.test.ts`

**Interfaces:**
- Consumes: `applyConfidenceFloor`, `GateId`, `ReasonCode` (Task 12), `anonymize` (Task 11).
- Produces:
  ```typescript
  interface CoverageAgent { adjudicate(input: AdjudicationInput): Promise<FinalVerdict & { whatIChecked: string[]; whatICouldNotCheck: string[] }> }
  type AdjudicationInput = { failureDescription: string; certificateText: string; contract: { validFrom: string; validTo: string; product: string }; vehicle: Vehicle; claimDate: string; documentSummaries: string[] }
  export const COVERAGE_PROMPT_VERSION = 'coverage.v1'
  saveVerdict(folio: string, eventId: number, v: FinalVerdict, supersedes?: { id: number; reason: string }): Promise<number>
  latestVerdict(folio: string): Promise<(FinalVerdict & { id: number }) | null>
  ```

- [ ] **Step 1: Escribir el prompt**

Crear `src/adjudication/prompts/coverage.v1.md` con este contenido exacto:

```
Eres un analista técnico de averías de una aseguradora de garantías extendidas de vehículos en México.

Tu tarea es determinar si existe UNA CAUSAL DE IMPROCEDENCIA VERIFICABLE contra el texto del certificado
que se te entrega. El texto del certificado es la única fuente normativa admisible: no apliques reglas
de memoria, no cites cláusulas que no estén en el texto, no supongas condiciones que no aparezcan.

## Puertas de decisión, en orden

Evalúa en este orden y detente en la primera concluyente:

1. P1 — Vigencia y pago. ¿La fecha de la avería cae dentro del periodo de vigencia? ¿El contrato está
   activo? ¿Se cumplió el periodo de espera, si el certificado lo establece?
2. P2 — Componente y operación. ¿El componente reclamado aparece entre las exclusiones del certificado,
   o entre las operaciones no incluidas?
3. P3 — Intervalo de mantenimiento. ¿La evidencia demuestra que se excedió el intervalo que fija el
   certificado? Solo concluye si la evidencia lo prueba; si es ausente, ilegible o parcial, responde duda.
4. P4 — Coherencia documental. ¿El kilometraje, el VIN, las fechas y los datos concuerdan entre sí?
5. P5 — Naturaleza del fallo. ¿Es una rotura imprevista o una degradación gradual?

## Reglas que no puedes romper

- La puerta 5 SIEMPRE produce duda. Distinguir desgaste de falla súbita exige valorar físicamente la
  pieza, y tú no la tienes delante. Puedes tener una hipótesis; no puedes emitirla como veredicto.
- No calcules, menciones ni infieras importes. El presupuesto solo te sirve para identificar qué
  componente se reclama.
- Todo improcedente exige una cita textual del certificado. Sin cita, el veredicto es duda.
- No conoces ninguna meta de negocio. No sabes qué tasa de rechazo se espera y no debe influirte.
- Ante evidencia contradictoria, ilegible o insuficiente para la puerta que estás evaluando: duda.

## Formato de respuesta

Responde solo con este objeto JSON:

{
  "value": "improcedente" | "sin_causal_de_improcedencia" | "duda",
  "reasonCode": "sin_vigencia" | "periodo_de_espera" | "componente_excluido" | "fuga_excluida" | "operacion_no_incluida" | "intervalo_mantenimiento_excedido" | null,
  "clauseQuote": "cita textual del certificado, o null",
  "supportingEvidence": ["qué documento o dato lo sostiene"],
  "confidence": 0.0,
  "decidingGate": "P1_vigencia" | "P2_componente" | "P3_mantenimiento" | "P4_coherencia" | "P5_naturaleza",
  "whatIChecked": ["qué revisaste"],
  "whatICouldNotCheck": ["qué no pudiste revisar y por qué"]
}

## Caso

Fecha de la avería: {{claimDate}}
Vigencia del contrato: {{validFrom}} a {{validTo}} · Producto: {{product}}
Vehículo: {{vehicle}}

Descripción de la falla:
{{failureDescription}}

Documentos del expediente:
{{documentSummaries}}

Texto del certificado:
{{certificateText}}
```

- [ ] **Step 2: Escribir el test**

```typescript
// tests/adjudication/coverage-agent.test.ts
import { describe, it, expect } from 'vitest'
import { createCoverageAgent } from '../../src/adjudication/coverage-agent.js'

function clienteQueResponde(json: unknown) {
  return { messages: { create: async () => ({ content: [{ type: 'text', text: JSON.stringify(json) }] }) } } as never
}

const entrada = {
  failureDescription: 'La transmisión patina',
  certificateText: 'CLÁUSULA 2. La vigencia inicia el 10/03/2025 y termina el 10/03/2027.',
  contract: { validFrom: '2025-03-10', validTo: '2027-03-10', product: 'Excellence' },
  vehicle: { brand: 'Chevrolet', model: 'Captiva', version: 'LT', year: 2024, kmAtContract: 12500, firstInvoiceDate: '2024-11-02', engineNumber: 'X' },
  claimDate: '2026-09-01',
  documentSummaries: ['Presupuesto', 'Fotos odómetro'],
}

describe('agente de cobertura', () => {
  it('emite improcedente cuando el modelo lo sostiene con cita y confianza alta', async () => {
    const a = createCoverageAgent({ client: clienteQueResponde({
      value: 'improcedente', reasonCode: 'sin_vigencia', clauseQuote: 'CLÁUSULA 2.',
      supportingEvidence: ['contrato'], confidence: 0.98, decidingGate: 'P1_vigencia',
      whatIChecked: ['vigencia'], whatICouldNotCheck: [],
    }) })
    const v = await a.adjudicate(entrada)
    expect(v.value).toBe('improcedente')
    expect(v.promptVersion).toBe('coverage.v1')
  })

  it('degrada a duda un improcedente sin cita textual', async () => {
    const a = createCoverageAgent({ client: clienteQueResponde({
      value: 'improcedente', reasonCode: 'componente_excluido', clauseQuote: null,
      supportingEvidence: [], confidence: 0.99, decidingGate: 'P2_componente',
      whatIChecked: [], whatICouldNotCheck: [],
    }) })
    expect((await a.adjudicate(entrada)).value).toBe('duda')
  })

  it('degrada a duda todo lo que venga de la puerta 5', async () => {
    const a = createCoverageAgent({ client: clienteQueResponde({
      value: 'improcedente', reasonCode: 'componente_excluido', clauseQuote: 'CLÁUSULA 1.',
      supportingEvidence: ['fotos'], confidence: 0.99, decidingGate: 'P5_naturaleza',
      whatIChecked: [], whatICouldNotCheck: [],
    }) })
    expect((await a.adjudicate(entrada)).value).toBe('duda')
  })

  it('una respuesta que no es JSON válido produce duda, nunca un veredicto inventado', async () => {
    const a = createCoverageAgent({ client: { messages: { create: async () => ({ content: [{ type: 'text', text: 'lo siento, no puedo' }] }) } } as never })
    const v = await a.adjudicate(entrada)
    expect(v.value).toBe('duda')
    expect(v.confidence).toBe(0)
  })

  it('anonimiza el texto antes de enviarlo al modelo', async () => {
    let enviado = ''
    const a = createCoverageAgent({ client: { messages: { create: async (args: { messages: [{ content: string }] }) => {
      enviado = args.messages[0].content
      return { content: [{ type: 'text', text: JSON.stringify({ value: 'duda', reasonCode: null, clauseQuote: null, supportingEvidence: [], confidence: 0.5, decidingGate: 'P4_coherencia', whatIChecked: [], whatICouldNotCheck: [] }) }] }
    } } } as never })
    await a.adjudicate({ ...entrada, failureDescription: 'Reportó el cliente al 5512345678' })
    expect(enviado).toContain('[TELEFONO]')
    expect(enviado).not.toContain('5512345678')
  })

  it('un fallo del modelo se propaga como error técnico, no como duda', async () => {
    const a = createCoverageAgent({ client: { messages: { create: async () => { throw new Error('503') } } } as never })
    await expect(a.adjudicate(entrada)).rejects.toThrow(/Fallo técnico en coverage-agent/)
  })
})
```

- [ ] **Step 3: Correr el test y verificar que falla**

Run: `npx vitest run tests/adjudication/coverage-agent.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 4: Implementar el agente**

```typescript
// src/adjudication/coverage-agent.ts
import Anthropic from '@anthropic-ai/sdk'
import { readFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { z } from 'zod'
import { loadConfig } from '../config/env.js'
import { TechnicalError } from '../domain/errors.js'
import { anonymize } from '../observability/anonymize.js'
import { applyConfidenceFloor, type FinalVerdict, type GateId } from './confidence.js'
import type { Vehicle } from '../siga/siga-types.js'

export const COVERAGE_PROMPT_VERSION = 'coverage.v1'

export type AdjudicationInput = {
  failureDescription: string; certificateText: string
  contract: { validFrom: string; validTo: string; product: string }
  vehicle: Vehicle; claimDate: string; documentSummaries: string[]
}

export type AdjudicationOutput = FinalVerdict & { whatIChecked: string[]; whatICouldNotCheck: string[] }

export interface CoverageAgent { adjudicate(input: AdjudicationInput): Promise<AdjudicationOutput> }

const salida = z.object({
  value: z.enum(['improcedente', 'sin_causal_de_improcedencia', 'duda']),
  reasonCode: z.enum(['sin_vigencia','periodo_de_espera','componente_excluido','fuga_excluida','operacion_no_incluida','intervalo_mantenimiento_excedido']).nullable(),
  clauseQuote: z.string().nullable(),
  supportingEvidence: z.array(z.string()),
  confidence: z.number().min(0).max(1),
  decidingGate: z.enum(['P0_identificacion','P1_vigencia','P2_componente','P3_mantenimiento','P4_coherencia','P5_naturaleza']),
  whatIChecked: z.array(z.string()),
  whatICouldNotCheck: z.array(z.string()),
})

const DUDA_POR_DEFECTO: AdjudicationOutput = {
  value: 'duda', reasonCode: null, clauseQuote: null, supportingEvidence: [],
  confidence: 0, decidingGate: 'P4_coherencia', promptVersion: COVERAGE_PROMPT_VERSION,
  degradedFrom: null, whatIChecked: [],
  whatICouldNotCheck: ['El análisis automático no produjo una respuesta interpretable; el caso requiere revisión manual'],
}

function plantilla(): string {
  return readFileSync(join(dirname(fileURLToPath(import.meta.url)), 'prompts/coverage.v1.md'), 'utf8')
}

export function createCoverageAgent(deps: { client?: Anthropic } = {}): CoverageAgent {
  const client = deps.client ?? new Anthropic({ apiKey: loadConfig().anthropicApiKey })

  return {
    async adjudicate(input) {
      const prompt = anonymize(
        plantilla()
          .replace('{{claimDate}}', input.claimDate)
          .replace('{{validFrom}}', input.contract.validFrom)
          .replace('{{validTo}}', input.contract.validTo)
          .replace('{{product}}', input.contract.product)
          .replace('{{vehicle}}', `${input.vehicle.brand} ${input.vehicle.model} ${input.vehicle.version} ${input.vehicle.year}`)
          .replace('{{failureDescription}}', input.failureDescription)
          .replace('{{documentSummaries}}', input.documentSummaries.join('\n- '))
          .replace('{{certificateText}}', input.certificateText)
      )

      let texto: string
      try {
        const res = await client.messages.create({
          model: 'claude-opus-5', max_tokens: 2048,
          messages: [{ role: 'user', content: prompt }],
        })
        texto = res.content.map((b) => (b.type === 'text' ? b.text : '')).join('')
      } catch (e) { throw new TechnicalError('coverage-agent', e) }

      const bruto = texto.match(/\{[\s\S]*\}/)?.[0]
      if (!bruto) return DUDA_POR_DEFECTO
      let json: unknown
      try { json = JSON.parse(bruto) } catch { return DUDA_POR_DEFECTO }
      const parsed = salida.safeParse(json)
      if (!parsed.success) return DUDA_POR_DEFECTO

      const d = parsed.data
      // RF-16: un improcedente sin cita textual no es verificable, así que no es improcedente.
      const sinCita = d.value === 'improcedente' && (!d.clauseQuote || !d.clauseQuote.trim())
      const final = applyConfidenceFloor({
        value: sinCita ? 'duda' : d.value,
        reasonCode: sinCita ? null : d.reasonCode,
        clauseQuote: sinCita ? null : d.clauseQuote,
        supportingEvidence: d.supportingEvidence,
        confidence: d.confidence,
        decidingGate: d.decidingGate as GateId,
        promptVersion: COVERAGE_PROMPT_VERSION,
      })
      return { ...final, whatIChecked: d.whatIChecked, whatICouldNotCheck: d.whatICouldNotCheck }
    },
  }
}
```

- [ ] **Step 5: Implementar el repositorio de veredictos**

```typescript
// src/db/repositories/verdict-repository.ts
import { getPool } from '../client.js'
import type { FinalVerdict } from '../../adjudication/confidence.js'

export async function saveVerdict(
  folio: string, eventId: number, v: FinalVerdict, supersedes?: { id: number; reason: string }
): Promise<number> {
  const { rows } = await getPool().query(
    `INSERT INTO verdicts (claim_folio, event_id, value, reason_code, clause_quote, supporting_evidence,
                           confidence, deciding_gate, prompt_version, supersedes_id, superseded_reason)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING id`,
    [folio, eventId, v.value, v.reasonCode, v.clauseQuote, JSON.stringify(v.supportingEvidence),
     v.confidence, v.decidingGate, v.promptVersion, supersedes?.id ?? null, supersedes?.reason ?? null]
  )
  return Number(rows[0].id)
}

export async function latestVerdict(folio: string): Promise<(FinalVerdict & { id: number }) | null> {
  const { rows } = await getPool().query(
    `SELECT id, value, reason_code, clause_quote, supporting_evidence, confidence, deciding_gate, prompt_version
     FROM verdicts WHERE claim_folio=$1 ORDER BY emitted_at DESC, id DESC LIMIT 1`, [folio]
  )
  if (!rows[0]) return null
  const r = rows[0]
  return {
    id: Number(r.id), value: r.value, reasonCode: r.reason_code, clauseQuote: r.clause_quote,
    supportingEvidence: r.supporting_evidence, confidence: Number(r.confidence),
    decidingGate: r.deciding_gate, promptVersion: r.prompt_version, degradedFrom: null,
  }
}
```

- [ ] **Step 6: Correr el test y verificar que pasa**

Run: `npx vitest run tests/adjudication/coverage-agent.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 7: Commit**

```bash
git add src/adjudication src/db/repositories/verdict-repository.ts tests/adjudication
git commit -m "feat: agente de cobertura con prompt versionado y degradacion segura"
```

---

## Task 14: Documento de deliberación

**Files:**
- Create: `src/output/document-builder.ts`
- Create: `src/output/templates/garantiplus-mexico.docx` *(pendiente de entrega del área — ver nota)*
- Test: `tests/output/document-builder.test.ts`

**Interfaces:**
- Consumes: `FinalVerdict` (Task 12), `CaseRecord` (Task 5), `ContractDetail` (Task 6).
- Produces:
  ```typescript
  type DocumentInput = { case: CaseRecord; contract: ContractDetail; verdict: FinalVerdict; evidenceUsed: string[]; catalogProvisional: boolean }
  buildDeliberationDocument(input: DocumentInput): Promise<{ buffer: Buffer; fileName: string; hasNarrative: boolean }>
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/output/document-builder.test.ts
import { describe, it, expect } from 'vitest'
import { buildDeliberationDocument, renderFields, buildNarrative } from '../../src/output/document-builder.js'
import contrato from '../fixtures/siga/contract.json'

const caso = {
  claimFolio: '3246', vin: '9GAMM6108KB004600', state: 'SUFICIENTE' as const,
  assignedTo: 'miguel.rodriguez@garantiplus.mx', affectedSystem: 'transmision',
  zeroMarkAt: new Date('2026-09-01T15:00:00Z'), lastEventAt: new Date('2026-09-03T10:00:00Z'),
  contractId: 'CTR-795713', certificateText: 'CLÁUSULA 9. Mantenimientos cada 10 000 km.', claimStatus: 'Validación',
}

const improcedente = {
  value: 'improcedente' as const, reasonCode: 'intervalo_mantenimiento_excedido' as const,
  clauseQuote: 'CLÁUSULA 9. Mantenimientos cada 10 000 km.', supportingEvidence: ['carnet de mantenimiento'],
  confidence: 0.98, decidingGate: 'P3_mantenimiento' as const, promptVersion: 'coverage.v1', degradedFrom: null,
}

const duda = { ...improcedente, value: 'duda' as const, reasonCode: null, clauseQuote: null }

describe('campos capturados', () => {
  it('rellena todos los campos desde SIGA, sin dejar ninguno vacío', () => {
    const f = renderFields({ case: caso, contract: contrato, verdict: improcedente, evidenceUsed: [], catalogProvisional: true })
    for (const clave of ['folio','vin','contrato','marca','modelo','version','anio','distribuidor','producto','vigenciaInicio','vigenciaFin','fecha']) {
      expect(f[clave], `el campo ${clave} quedó vacío`).toBeTruthy()
    }
    expect(f.folio).toBe('3246')
    expect(f.marca).toBe('Chevrolet')
  })

  it('los campos se capturan igual en los tres veredictos', () => {
    const a = renderFields({ case: caso, contract: contrato, verdict: improcedente, evidenceUsed: [], catalogProvisional: false })
    const b = renderFields({ case: caso, contract: contrato, verdict: duda, evidenceUsed: [], catalogProvisional: false })
    expect(a.folio).toBe(b.folio)
    expect(a.marca).toBe(b.marca)
  })
})

describe('narrativa', () => {
  it('redacta el sustento solo en improcedente, citando la cláusula', () => {
    const t = buildNarrative(improcedente)
    expect(t).toContain('CLÁUSULA 9')
    expect(t.length).toBeGreaterThan(80)
  })

  it('NO redacta absolutamente nada en duda', () => {
    expect(buildNarrative(duda)).toBe('')
  })

  it('NO redacta nada en sin causal de improcedencia', () => {
    expect(buildNarrative({ ...duda, value: 'sin_causal_de_improcedencia' })).toBe('')
  })
})

describe('documento completo', () => {
  it('marca el documento como borrador asistido por IA', async () => {
    const r = await buildDeliberationDocument({ case: caso, contract: contrato, verdict: improcedente, evidenceUsed: ['carnet'], catalogProvisional: false })
    expect(r.fileName).toMatch(/BORRADOR/i)
    expect(r.hasNarrative).toBe(true)
  })

  it('en duda el documento va sin narrativa', async () => {
    const r = await buildDeliberationDocument({ case: caso, contract: contrato, verdict: duda, evidenceUsed: [], catalogProvisional: false })
    expect(r.hasNarrative).toBe(false)
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/output/document-builder.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar**

```typescript
// src/output/document-builder.ts
import Docxtemplater from 'docxtemplater'
import PizZip from 'pizzip'
import { readFileSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { DateTime } from 'luxon'
import type { FinalVerdict, ReasonCode } from '../adjudication/confidence.js'
import type { CaseRecord } from '../db/repositories/case-repository.js'
import type { ContractDetail } from '../siga/siga-types.js'

export type DocumentInput = {
  case: CaseRecord; contract: ContractDetail; verdict: FinalVerdict
  evidenceUsed: string[]; catalogProvisional: boolean
}

const AVISO_IA =
  'Este documento es un BORRADOR producido con asistencia de inteligencia artificial. ' +
  'Requiere revisión y validación de un técnico de averías antes de tener validez. ' +
  'No constituye la resolución del expediente.'

/** E3: los campos de captura se rellenan en los tres veredictos, siempre. */
export function renderFields(input: DocumentInput): Record<string, string> {
  const { case: c, contract: k } = input
  return {
    folio: c.claimFolio,
    vin: c.vin,
    contrato: k.contractId,
    marca: k.vehicle.brand,
    modelo: k.vehicle.model,
    version: k.vehicle.version,
    anio: String(k.vehicle.year),
    kilometraje: String(k.vehicle.kmAtContract),
    distribuidor: k.dealer,
    producto: k.product,
    vigenciaInicio: k.validFrom,
    vigenciaFin: k.validTo,
    fecha: DateTime.now().setZone('America/Mexico_City').toFormat('dd/LL/yyyy'),
    avisoIA: AVISO_IA,
    avisoCatalogo: input.catalogProvisional
      ? 'La evaluación de suficiencia se realizó con un catálogo de evidencia mínima PROVISIONAL, aún no validado por el área.'
      : '',
    evidencia: input.evidenceUsed.join('; '),
  }
}

const BORRADORES: Record<ReasonCode, (cita: string) => string> = {
  intervalo_mantenimiento_excedido: (cita) =>
    `Del análisis del expediente se desprende que la unidad no acredita el cumplimiento del programa de mantenimiento ` +
    `establecido en el certificado de garantía. El certificado dispone: «${cita}». La documentación aportada no demuestra ` +
    `que dichos servicios se hayan realizado dentro de los intervalos señalados, por lo que la avería reportada resulta ` +
    `improcedente conforme a las condiciones contratadas.`,
  componente_excluido: (cita) =>
    `El componente reportado se encuentra expresamente excluido de la cobertura contratada. El certificado establece: ` +
    `«${cita}». En consecuencia, la avería reportada resulta improcedente conforme a las condiciones contratadas.`,
  fuga_excluida: (cita) =>
    `La falla reportada corresponde a una fuga que el certificado excluye de la cobertura. El certificado establece: ` +
    `«${cita}». En consecuencia, la avería reportada resulta improcedente conforme a las condiciones contratadas.`,
  operacion_no_incluida: (cita) =>
    `La operación solicitada no se encuentra dentro de las incluidas en la cobertura contratada. El certificado establece: ` +
    `«${cita}». En consecuencia, la avería reportada resulta improcedente conforme a las condiciones contratadas.`,
  sin_vigencia: (cita) =>
    `A la fecha del reporte, el contrato de garantía no se encontraba vigente. El certificado establece: «${cita}». ` +
    `En consecuencia, la avería reportada resulta improcedente conforme a las condiciones contratadas.`,
  periodo_de_espera: (cita) =>
    `A la fecha del reporte no se había cumplido el periodo de espera previsto en el certificado, que establece: «${cita}». ` +
    `En consecuencia, la avería reportada resulta improcedente conforme a las condiciones contratadas.`,
}

/** E4 y E5: solo el improcedente lleva redacción. Los otros dos van con los datos y nada más. */
export function buildNarrative(v: FinalVerdict): string {
  if (v.value !== 'improcedente' || !v.reasonCode || !v.clauseQuote) return ''
  return BORRADORES[v.reasonCode](v.clauseQuote)
}

function plantillaPath(product: string): string {
  const dir = join(dirname(fileURLToPath(import.meta.url)), 'templates')
  const mitsubishi = join(dir, 'mitsubishi.docx')
  if (/mitsubishi/i.test(product) && existsSync(mitsubishi)) return mitsubishi
  return join(dir, 'garantiplus-mexico.docx')
}

export async function buildDeliberationDocument(
  input: DocumentInput
): Promise<{ buffer: Buffer; fileName: string; hasNarrative: boolean }> {
  const narrativa = buildNarrative(input.verdict)
  const campos = { ...renderFields(input), sustento: narrativa }

  const ruta = plantillaPath(input.contract.product)
  if (!existsSync(ruta)) {
    throw new Error(
      `No existe la plantilla ${ruta}. Las plantillas oficiales son un entregable pendiente del área ` +
      `(pregunta abierta del PRD). Sin ellas no se puede construir el documento.`
    )
  }

  const zip = new PizZip(readFileSync(ruta, 'binary'))
  const doc = new Docxtemplater(zip, { paragraphLoop: true, linebreaks: true })
  doc.render(campos)
  const buffer = doc.getZip().generate({ type: 'nodebuffer' }) as Buffer

  return {
    buffer,
    fileName: `BORRADOR-deliberacion-${input.case.claimFolio}.docx`,
    hasNarrative: narrativa.length > 0,
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `npx vitest run tests/output/document-builder.test.ts`
Esperado: PASS, 7 tests. *(Los dos últimos requieren una plantilla `.docx` en `src/output/templates/`; hasta que el área entregue la oficial, crea una de andamiaje con los marcadores `{folio}`, `{vin}`, `{contrato}`, `{marca}`, `{modelo}`, `{version}`, `{anio}`, `{kilometraje}`, `{distribuidor}`, `{producto}`, `{vigenciaInicio}`, `{vigenciaFin}`, `{fecha}`, `{sustento}`, `{evidencia}`, `{avisoIA}`, `{avisoCatalogo}`.)*

- [ ] **Step 5: Commit**

```bash
git add src/output tests/output
git commit -m "feat: documento de deliberacion con narrativa solo en improcedente"
```

> **Bloqueo conocido.** Las dos plantillas oficiales —Garantiplus México y Mitsubishi— son un entregable pendiente del área. Esta tarea se construye contra una plantilla de andamiaje con los mismos marcadores; cuando lleguen las oficiales, solo se sustituyen los archivos. La lógica no cambia.

---

## Task 15: Correo de dictamen

**Files:**
- Create: `src/output/verdict-email.ts`, `src/output/templates/verdict-email.hbs`
- Test: `tests/output/verdict-email.test.ts`

**Interfaces:**
- Consumes: `FinalVerdict` (Task 12), `SufficiencyResult` (Task 9), `anonymize` (Task 11).
- Produces:
  ```typescript
  type VerdictEmail = { to: string[]; cc: string[]; subject: string; html: string; inReplyTo: string | null; attachments: Array<{ fileName: string; content: Buffer }> }
  buildVerdictEmail(input: VerdictEmailInput): VerdictEmail
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/output/verdict-email.test.ts
import { describe, it, expect } from 'vitest'
import { buildVerdictEmail } from '../../src/output/verdict-email.js'

const base = {
  case: { claimFolio: '3246', vin: '9GAMM6108KB004600', assignedTo: 'miguel.rodriguez@garantiplus.mx' },
  vehicle: { brand: 'Chevrolet', model: 'Captiva', version: 'LT', year: 2024 },
  contract: { contractId: 'CTR-795713', product: 'Excellence', validFrom: '2025-03-10', validTo: '2027-03-10' },
  verdict: {
    value: 'improcedente' as const, reasonCode: 'componente_excluido' as const,
    clauseQuote: 'CLÁUSULA 1. Quedan excluidos los amortiguadores.',
    supportingEvidence: ['presupuesto'], confidence: 0.97,
    decidingGate: 'P2_componente' as const, promptVersion: 'coverage.v1', degradedFrom: null,
  },
  whatIChecked: ['vigencia', 'componente contra el certificado'],
  whatICouldNotCheck: ['el estado físico de la pieza'],
  eventsToSufficiency: 4, daysToSufficiency: 3,
  areaManagerEmail: 'david.simancas@garantiplus.mx',
  threadMessageId: '<abc123@garantiplus.mx>',
  attachments: [{ fileName: 'BORRADOR-deliberacion-3246.docx', content: Buffer.from('x') }],
  catalogProvisional: true,
}

describe('correo de dictamen', () => {
  it('va al técnico asignado con copia al responsable del área', () => {
    const e = buildVerdictEmail(base)
    expect(e.to).toEqual(['miguel.rodriguez@garantiplus.mx'])
    expect(e.cc).toEqual(['david.simancas@garantiplus.mx'])
  })

  it('responde en el hilo del correo del caso', () => {
    expect(buildVerdictEmail(base).inReplyTo).toBe('<abc123@garantiplus.mx>')
  })

  it('el asunto lleva el veredicto y el folio', () => {
    const e = buildVerdictEmail(base)
    expect(e.subject).toContain('3246')
    expect(e.subject.toLowerCase()).toContain('improcedente')
  })

  it('incluye qué revisó y qué NO pudo revisar', () => {
    const h = buildVerdictEmail(base).html
    expect(h).toContain('el estado físico de la pieza')
    expect(h).toMatch(/no pud[oe]/i)
  })

  it('incluye la nota de transparencia de IA', () => {
    expect(buildVerdictEmail(base).html).toMatch(/inteligencia artificial/i)
    expect(buildVerdictEmail(base).html).toMatch(/no constituye la resolución/i)
  })

  it('informa cuántos eventos y días tomó llegar a la suficiencia', () => {
    const h = buildVerdictEmail(base).html
    expect(h).toContain('4')
    expect(h).toMatch(/3 d[ií]as/)
  })

  it('advierte cuando el catálogo de evidencia mínima es provisional', () => {
    expect(buildVerdictEmail(base).html).toMatch(/provisional/i)
    expect(buildVerdictEmail({ ...base, catalogProvisional: false }).html).not.toMatch(/provisional/i)
  })

  it('en duda enuncia qué verificar y NO adelanta veredicto', () => {
    const e = buildVerdictEmail({
      ...base,
      verdict: { ...base.verdict, value: 'duda', reasonCode: null, clauseQuote: null },
      whatICouldNotCheck: ['si el mantenimiento se hizo en distribuidor autorizado'],
    })
    expect(e.html).toContain('si el mantenimiento se hizo en distribuidor autorizado')
    expect(e.html.toLowerCase()).not.toContain('improcedente')
  })

  it('no filtra datos personales al cuerpo', () => {
    const e = buildVerdictEmail({ ...base, whatIChecked: ['contacto al 5512345678'] })
    expect(e.html).not.toContain('5512345678')
    expect(e.html).toContain('[TELEFONO]')
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/output/verdict-email.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar**

```typescript
// src/output/verdict-email.ts
import { anonymize } from '../observability/anonymize.js'
import type { FinalVerdict } from '../adjudication/confidence.js'

export type VerdictEmailInput = {
  case: { claimFolio: string; vin: string; assignedTo: string | null }
  vehicle: { brand: string; model: string; version: string; year: number }
  contract: { contractId: string; product: string; validFrom: string; validTo: string }
  verdict: FinalVerdict
  whatIChecked: string[]
  whatICouldNotCheck: string[]
  eventsToSufficiency: number
  daysToSufficiency: number
  areaManagerEmail: string
  threadMessageId: string | null
  attachments: Array<{ fileName: string; content: Buffer }>
  catalogProvisional: boolean
}

export type VerdictEmail = {
  to: string[]; cc: string[]; subject: string; html: string
  inReplyTo: string | null; attachments: Array<{ fileName: string; content: Buffer }>
}

const ETIQUETA = {
  improcedente: { texto: 'IMPROCEDENTE', color: '#b3261e' },
  sin_causal_de_improcedencia: { texto: 'SIN CAUSAL DE IMPROCEDENCIA', color: '#1e6b3a' },
  duda: { texto: 'REQUIERE REVISIÓN', color: '#8a6100' },
} as const

const NOTA_IA =
  'Este dictamen fue producido con asistencia de inteligencia artificial a partir del expediente en SIGA. ' +
  'Es una opinión razonada y <strong>no constituye la resolución del expediente</strong>: la decisión y la firma son del técnico.'

function lista(items: string[]): string {
  if (!items.length) return '<li><em>Nada que reportar</em></li>'
  return items.map((i) => `<li>${anonymize(i)}</li>`).join('')
}

export function buildVerdictEmail(input: VerdictEmailInput): VerdictEmail {
  const { case: c, verdict: v } = input
  const e = ETIQUETA[v.value]
  const esDuda = v.value === 'duda'

  const bloqueSustento = v.value === 'improcedente' && v.clauseQuote
    ? `<h3>Sustento</h3><p><strong>Motivo:</strong> ${v.reasonCode}</p>
       <blockquote style="border-left:3px solid #ccc;padding-left:12px;color:#444">${anonymize(v.clauseQuote)}</blockquote>
       <p><strong>Evidencia:</strong> ${anonymize(v.supportingEvidence.join('; ')) || 'no especificada'}</p>`
    : ''

  const bloqueDuda = esDuda
    ? `<h3>Qué habría que verificar</h3><ul>${lista(input.whatICouldNotCheck)}</ul>`
    : ''

  const avisoCatalogo = input.catalogProvisional
    ? `<p style="background:#fff4e5;padding:10px;border-radius:4px">
         <strong>Aviso:</strong> la evaluación de suficiencia usó un catálogo de evidencia mínima
         <strong>provisional</strong>, aún no validado por el área.
       </p>`
    : ''

  const html = `
<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;max-width:680px;color:#1a1a1a">
  <div style="background:${e.color};color:#fff;padding:14px 18px;border-radius:6px 6px 0 0">
    <div style="font-size:20px;font-weight:700">${e.texto}</div>
    <div style="opacity:.9">Avería ${c.claimFolio} · ${input.vehicle.brand} ${input.vehicle.model} ${input.vehicle.year}</div>
  </div>
  <div style="border:1px solid #e3e3e3;border-top:none;padding:18px;border-radius:0 0 6px 6px">
    <table style="width:100%;border-collapse:collapse;font-size:14px">
      <tr><td style="padding:4px 0;color:#666">VIN</td><td>${c.vin}</td></tr>
      <tr><td style="padding:4px 0;color:#666">Contrato</td><td>${input.contract.contractId}</td></tr>
      <tr><td style="padding:4px 0;color:#666">Producto</td><td>${input.contract.product}</td></tr>
      <tr><td style="padding:4px 0;color:#666">Vigencia</td><td>${input.contract.validFrom} a ${input.contract.validTo}</td></tr>
      <tr><td style="padding:4px 0;color:#666">Confianza</td><td>${(v.confidence * 100).toFixed(0)}%</td></tr>
    </table>
    ${bloqueSustento}
    ${bloqueDuda}
    <h3>Qué revisó el análisis</h3><ul>${lista(input.whatIChecked)}</ul>
    <h3>Qué no pudo revisar</h3><ul>${lista(input.whatICouldNotCheck)}</ul>
    <p style="font-size:13px;color:#555">
      Este caso alcanzó información suficiente para deliberar después de
      <strong>${input.eventsToSufficiency}</strong> actualizaciones, a lo largo de
      <strong>${input.daysToSufficiency} días</strong>.
    </p>
    ${avisoCatalogo}
    <p style="font-size:12px;color:#666;border-top:1px solid #eee;padding-top:12px">${NOTA_IA}</p>
  </div>
</div>`.trim()

  return {
    to: c.assignedTo ? [c.assignedTo] : [],
    cc: [input.areaManagerEmail],
    subject: `[${e.texto}] Avería ${c.claimFolio} · ${input.vehicle.brand} ${input.vehicle.model}`,
    html,
    inReplyTo: input.threadMessageId,
    attachments: input.attachments,
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `npx vitest run tests/output/verdict-email.test.ts`
Esperado: PASS, 9 tests.

- [ ] **Step 5: Commit**

```bash
git add src/output tests/output
git commit -m "feat: correo de dictamen en hilo, con copia al area y nota de transparencia"
```

---

## Task 16: Reporte matutino

**Files:**
- Create: `src/output/morning-report.ts`
- Create: `src/db/repositories/report-repository.ts`
- Test: `tests/output/morning-report.test.ts`

**Interfaces:**
- Consumes: repositorios de casos, eventos, suficiencia y veredictos.
- Produces:
  ```typescript
  type ReportRow = { folio: string; vin: string; vehicle: string; daysOpen: number; state: CaseState; sufficiency: 'suficiente' | 'insuficiente' | 'sin evaluar'; missing: string[]; daysSinceLastEvent: number; slaHoursLeft: number | null }
  gatherReportData(technician: string, since: Date, now: Date): Promise<ReportData>
  buildMorningReport(data: ReportData, opts: { areaManagerEmail: string }): { to: string[]; cc: string[]; subject: string; html: string }
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/output/morning-report.test.ts
import { describe, it, expect } from 'vitest'
import { buildMorningReport } from '../../src/output/morning-report.js'

const fila = (over: Partial<Record<string, unknown>> = {}) => ({
  folio: '3246', vin: '9GAMM6108KB004600', vehicle: 'Chevrolet Captiva 2024',
  daysOpen: 3, state: 'EN_ACUMULACION' as const, sufficiency: 'insuficiente' as const,
  missing: ['Escaneo de la transmisión', 'Estado del aceite'], daysSinceLastEvent: 1, slaHoursLeft: 30,
  ...over,
})

const datos = {
  technician: 'miguel.rodriguez@garantiplus.mx',
  generatedAt: new Date('2026-09-04T13:30:00Z'),
  overnight: [{ folio: '3300', what: 'Caso nuevo asignado' }, { folio: '3246', what: 'Se cargó el escaneo de la transmisión' }],
  active: [fila(), fila({ folio: '3300', sufficiency: 'sin evaluar' })],
  readyToAdjudicate: [fila({ folio: '3111', sufficiency: 'suficiente', missing: [] })],
  stalled: [fila({ folio: '2999', state: 'ESTANCADO', daysSinceLastEvent: 8 })],
  slaAtRisk: [fila({ folio: '3246', slaHoursLeft: 5 })],
  adjudicatedSince: [{ folio: '3050', verdict: 'improcedente' as const }],
}

describe('reporte matutino', () => {
  it('va al técnico con copia al responsable del área', () => {
    const r = buildMorningReport(datos, { areaManagerEmail: 'david@garantiplus.mx' })
    expect(r.to).toEqual(['miguel.rodriguez@garantiplus.mx'])
    expect(r.cc).toEqual(['david@garantiplus.mx'])
  })

  it('destaca los casos listos para dictaminar', () => {
    const h = buildMorningReport(datos, { areaManagerEmail: 'd@x.mx' }).html
    expect(h).toMatch(/listos para dictaminar/i)
    expect(h).toContain('3111')
  })

  it('destaca los estancados ordenados por días de espera', () => {
    const conVarios = { ...datos, stalled: [fila({ folio: 'A', daysSinceLastEvent: 4 }), fila({ folio: 'B', daysSinceLastEvent: 12 })] }
    const h = buildMorningReport(conVarios, { areaManagerEmail: 'd@x.mx' }).html
    expect(h.indexOf('>B<')).toBeLessThan(h.indexOf('>A<'))
  })

  it('dice qué falta exactamente en cada caso, no "documentación incompleta"', () => {
    const h = buildMorningReport(datos, { areaManagerEmail: 'd@x.mx' }).html
    expect(h).toContain('Escaneo de la transmisión')
    expect(h).not.toMatch(/documentación incompleta/i)
  })

  it('señala los casos por vencer el SLA con las horas restantes', () => {
    const h = buildMorningReport(datos, { areaManagerEmail: 'd@x.mx' }).html
    expect(h).toMatch(/5 h/)
  })

  it('se envía y lo declara aunque no haya novedades', () => {
    const vacio = { ...datos, overnight: [], active: [], readyToAdjudicate: [], stalled: [], slaAtRisk: [], adjudicatedSince: [] }
    const r = buildMorningReport(vacio, { areaManagerEmail: 'd@x.mx' })
    expect(r.html).toMatch(/sin novedades/i)
    expect(r.to).toHaveLength(1)
  })

  it('no incluye datos personales del beneficiario', () => {
    const conDato = { ...datos, overnight: [{ folio: '1', what: 'llamó al 5512345678' }] }
    const h = buildMorningReport(conDato, { areaManagerEmail: 'd@x.mx' }).html
    expect(h).not.toContain('5512345678')
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/output/morning-report.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar el compositor del reporte**

```typescript
// src/output/morning-report.ts
import { DateTime } from 'luxon'
import { anonymize } from '../observability/anonymize.js'
import type { CaseState } from '../domain/case-state.js'

export type ReportRow = {
  folio: string; vin: string; vehicle: string; daysOpen: number; state: CaseState
  sufficiency: 'suficiente' | 'insuficiente' | 'sin evaluar'
  missing: string[]; daysSinceLastEvent: number; slaHoursLeft: number | null
}

export type ReportData = {
  technician: string
  generatedAt: Date
  overnight: Array<{ folio: string; what: string }>
  active: ReportRow[]
  readyToAdjudicate: ReportRow[]
  stalled: ReportRow[]
  slaAtRisk: ReportRow[]
  adjudicatedSince: Array<{ folio: string; verdict: 'improcedente' | 'sin_causal_de_improcedencia' | 'duda' }>
}

const SEMAFORO = { suficiente: '🟢', insuficiente: '🟡', 'sin evaluar': '⚪' } as const

function tabla(filas: ReportRow[]): string {
  if (!filas.length) return '<p style="color:#666"><em>Ninguno</em></p>'
  const cuerpo = filas.map((f) => `
    <tr>
      <td style="padding:6px;border-bottom:1px solid #eee"><strong>${f.folio}</strong></td>
      <td style="padding:6px;border-bottom:1px solid #eee">${f.vehicle}</td>
      <td style="padding:6px;border-bottom:1px solid #eee">${SEMAFORO[f.sufficiency]} ${f.sufficiency}</td>
      <td style="padding:6px;border-bottom:1px solid #eee">${f.missing.length ? anonymize(f.missing.join(', ')) : '—'}</td>
      <td style="padding:6px;border-bottom:1px solid #eee;text-align:right">${f.daysSinceLastEvent} d</td>
    </tr>`).join('')
  return `<table style="width:100%;border-collapse:collapse;font-size:13px">
    <tr style="text-align:left;color:#666">
      <th style="padding:6px">Folio</th><th style="padding:6px">Vehículo</th>
      <th style="padding:6px">Suficiencia</th><th style="padding:6px">Qué falta</th>
      <th style="padding:6px;text-align:right">Sin mover</th>
    </tr>${cuerpo}</table>`
}

function destacado(titulo: string, color: string, filas: ReportRow[], extra?: (f: ReportRow) => string): string {
  if (!filas.length) return ''
  const items = filas.map((f) =>
    `<li><strong>&gt;${f.folio}&lt;</strong> · ${f.vehicle}${extra ? ` · ${extra(f)}` : ''}</li>`
  ).join('')
  return `<div style="background:${color};padding:12px;border-radius:6px;margin:14px 0">
    <h3 style="margin:0 0 8px">${titulo}</h3><ul style="margin:0;padding-left:20px">${items}</ul></div>`
}

export function buildMorningReport(
  data: ReportData, opts: { areaManagerEmail: string }
): { to: string[]; cc: string[]; subject: string; html: string } {
  const fecha = DateTime.fromJSDate(data.generatedAt).setZone('America/Mexico_City').toFormat("d 'de' LLLL", { locale: 'es' })
  const hayAlgo = data.overnight.length + data.active.length + data.readyToAdjudicate.length + data.stalled.length > 0

  const novedades = data.overnight.length
    ? `<ul>${data.overnight.map((o) => `<li><strong>${o.folio}</strong> — ${anonymize(o.what)}</li>`).join('')}</ul>`
    : '<p style="color:#666"><em>No llegó nada nuevo durante la noche.</em></p>'

  const dictaminados = data.adjudicatedSince.length
    ? `<ul>${data.adjudicatedSince.map((a) => `<li><strong>${a.folio}</strong> — ${a.verdict}</li>`).join('')}</ul>`
    : '<p style="color:#666"><em>Ninguno.</em></p>'

  const cuerpo = hayAlgo
    ? `
      ${destacado('✅ Listos para dictaminar', '#e6f4ea', data.readyToAdjudicate)}
      ${destacado('⏳ Estancados', '#fdecea', [...data.stalled].sort((a, b) => b.daysSinceLastEvent - a.daysSinceLastEvent),
        (f) => `${f.daysSinceLastEvent} días esperando · falta ${anonymize(f.missing.join(', ')) || 'sin detalle'}`)}
      ${destacado('⏰ Por vencer el SLA', '#fff4e5', data.slaAtRisk, (f) => `${f.slaHoursLeft} h restantes`)}
      <h3>Qué llegó desde el último reporte</h3>${novedades}
      <h3>Casos activos</h3>${tabla(data.active)}
      <h3>Dictaminados desde el último reporte</h3>${dictaminados}`
    : `<p style="padding:16px;background:#f5f5f5;border-radius:6px">
         <strong>Sin novedades.</strong> No hay casos activos ni movimientos desde el último reporte.
         Este correo se envía igual para que sepas que el sistema está corriendo.
       </p>`

  const html = `
<div style="font-family:system-ui,-apple-system,Segoe UI,sans-serif;max-width:760px;color:#1a1a1a">
  <h2 style="margin-bottom:2px">Estatus de averías · ${fecha}</h2>
  <p style="color:#666;margin-top:0">Resumen automático generado antes del inicio de la jornada.</p>
  ${cuerpo}
  <p style="font-size:12px;color:#666;border-top:1px solid #eee;padding-top:12px;margin-top:20px">
    Reporte generado automáticamente por el Copiloto de Averías. Refleja el estado registrado del expediente;
    no emite juicios de procedencia.
  </p>
</div>`.trim()

  return {
    to: [data.technician],
    cc: [opts.areaManagerEmail],
    subject: `Estatus de averías · ${fecha} · ${data.readyToAdjudicate.length} listos, ${data.stalled.length} estancados`,
    html,
  }
}
```

- [ ] **Step 4: Implementar la consulta de datos del reporte**

```typescript
// src/db/repositories/report-repository.ts
import { getPool } from '../client.js'
import type { ReportData, ReportRow } from '../../output/morning-report.js'

const SLA_HORAS = 48

export async function gatherReportData(technician: string, since: Date, now: Date): Promise<ReportData> {
  const pool = getPool()

  const { rows: casos } = await pool.query(
    `SELECT c.claim_folio, c.vin, c.vehicle, c.state, c.last_event_at, c.created_at, c.sufficient_at,
            s.result AS sufficiency, s.missing
     FROM cases c
     LEFT JOIN LATERAL (
       SELECT result, missing FROM sufficiency_evaluations
       WHERE claim_folio = c.claim_folio ORDER BY evaluated_at DESC, id DESC LIMIT 1
     ) s ON true
     WHERE c.assigned_to = $1 AND c.state <> 'CERRADO'
     ORDER BY c.last_event_at ASC`, [technician]
  )

  const dias = (d: Date) => Math.floor((now.getTime() - new Date(d).getTime()) / 86_400_000)

  const toRow = (r: Record<string, unknown>): ReportRow => {
    const v = (r.vehicle ?? {}) as { brand?: string; model?: string; year?: number }
    const suf = (r.sufficiency as ReportRow['sufficiency']) ?? 'sin evaluar'
    const faltantes = ((r.missing ?? []) as Array<{ label: string }>).map((m) => m.label)
    const horasAbierto = (now.getTime() - new Date(r.created_at as Date).getTime()) / 3_600_000
    return {
      folio: r.claim_folio as string,
      vin: r.vin as string,
      vehicle: [v.brand, v.model, v.year].filter(Boolean).join(' ') || 'Vehículo sin detalle',
      daysOpen: dias(r.created_at as Date),
      state: r.state as ReportRow['state'],
      sufficiency: suf,
      missing: faltantes,
      daysSinceLastEvent: dias(r.last_event_at as Date),
      slaHoursLeft: Math.round(SLA_HORAS - horasAbierto),
    }
  }

  const filas = casos.map(toRow)

  const { rows: eventos } = await pool.query(
    `SELECT e.claim_folio, e.event_kind, e.changes
     FROM case_events e JOIN cases c ON c.claim_folio = e.claim_folio
     WHERE c.assigned_to = $1 AND e.occurred_at >= $2 ORDER BY e.occurred_at`, [technician, since]
  )

  const { rows: dictaminados } = await pool.query(
    `SELECT v.claim_folio, v.value FROM verdicts v JOIN cases c ON c.claim_folio = v.claim_folio
     WHERE c.assigned_to = $1 AND v.emitted_at >= $2 ORDER BY v.emitted_at`, [technician, since]
  )

  return {
    technician,
    generatedAt: now,
    overnight: eventos.map((e) => ({
      folio: e.claim_folio as string,
      what: describirEvento(e.event_kind as string, e.changes as Record<string, unknown>),
    })),
    active: filas.filter((f) => f.state !== 'ESTANCADO'),
    readyToAdjudicate: filas.filter((f) => f.sufficiency === 'suficiente' && f.state === 'SUFICIENTE'),
    stalled: filas.filter((f) => f.state === 'ESTANCADO'),
    slaAtRisk: filas.filter((f) => f.slaHoursLeft !== null && f.slaHoursLeft <= 12 && f.state !== 'DELIBERADO'),
    adjudicatedSince: dictaminados.map((d) => ({ folio: d.claim_folio as string, verdict: d.value })),
  }
}

function describirEvento(kind: string, changes: Record<string, unknown>): string {
  if (kind === 'asignacion') return 'Caso nuevo asignado'
  if (kind === 'documento_cargado') return 'El distribuidor cargó un documento'
  if (kind === 'cambio_estatus') return `Cambio de estatus${changes.estatus ? `: ${JSON.stringify(changes.estatus)}` : ''}`
  if (kind === 'barrido_detecto_cambio') {
    const docs = (changes.documentosNuevos as string[] | undefined)?.length
    return docs ? `Se detectaron ${docs} documento(s) nuevo(s)` : 'Se detectó un cambio en el expediente'
  }
  return 'Actualización del expediente'
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `npx vitest run tests/output/morning-report.test.ts`
Esperado: PASS, 7 tests.

- [ ] **Step 6: Commit**

```bash
git add src/output/morning-report.ts src/db/repositories/report-repository.ts tests/output/morning-report.test.ts
git commit -m "feat: reporte matutino accionable con listos, estancados y SLA en riesgo"
```

---

## Task 17: Orquestación del evento de principio a fin

**Files:**
- Create: `src/pipeline/process-event.ts`
- Create: `src/observability/events.ts`
- Test: `tests/pipeline/process-event.test.ts`

**Interfaces:**
- Consumes: todo lo anterior.
- Produces:
  ```typescript
  type ProcessOutcome = { action: 'ignorado_duplicado' } | { action: 'acumulando'; missing: MissingItem[] } | { action: 'dictaminado'; verdictId: number; emailSent: true } | { action: 'excepcion'; code: string } | { action: 'sin_dictamen_por_fallo_tecnico'; component: string }
  processEvent(input: IncomingEvent, deps: ProcessDeps): Promise<ProcessOutcome>
  emit(event: string, payload: Record<string, unknown>): void
  ```

- [ ] **Step 1: Escribir el test de integración**

```typescript
// tests/pipeline/process-event.test.ts
import { describe, it, expect, beforeEach, afterAll, vi } from 'vitest'
import { getPool, runMigrations, closePool } from '../../src/db/client.js'
import { findCase } from '../../src/db/repositories/case-repository.js'
import { processEvent } from '../../src/pipeline/process-event.js'
import type { SigaReader } from '../../src/siga/siga-types.js'
import contrato from '../fixtures/siga/contract.json'
import averia from '../fixtures/siga/claim.json'

beforeEach(async () => { await runMigrations(); await getPool().query('TRUNCATE cases CASCADE') })
afterAll(async () => { await closePool() })

const TODA_LA_EVIDENCIA = [
  { documentId: 'D1', documentType: 'Presupuesto', fileName: 'p.pdf', uploadedAt: '2026-09-01T00:00:00Z' },
  { documentId: 'D2', documentType: 'Fotos odómetro', fileName: 'o.jpg', uploadedAt: '2026-09-01T00:00:00Z' },
  { documentId: 'D3', documentType: 'Estado de aceite', fileName: 'a.jpg', uploadedAt: '2026-09-01T00:00:00Z' },
  { documentId: 'D4', documentType: 'Residuos', fileName: 'r.jpg', uploadedAt: '2026-09-01T00:00:00Z' },
  { documentId: 'D5', documentType: 'Escaneo', fileName: 's.pdf', uploadedAt: '2026-09-01T00:00:00Z' },
  { documentId: 'D6', documentType: 'Carnet de mantenimiento', fileName: 'c.pdf', uploadedAt: '2026-09-01T00:00:00Z' },
  { documentId: 'D7', documentType: 'Facturas de servicio', fileName: 'f.pdf', uploadedAt: '2026-09-01T00:00:00Z' },
]

function siga(docs = TODA_LA_EVIDENCIA): SigaReader {
  return {
    findContractByVin: async () => contrato, getContractDetail: async () => contrato,
    getCertificateText: async () => 'CLÁUSULA 1. Quedan excluidos los amortiguadores.',
    getClaim: async () => averia, listClaimDocuments: async () => docs,
    downloadDocument: async () => Buffer.from('x'),
  }
}

const deps = (over: Record<string, unknown> = {}) => ({
  siga: siga(),
  identifier: { identify: async () => ({ systemKey: 'transmision', confidence: 0.95 }) },
  coverageAgent: { adjudicate: async () => ({
    value: 'improcedente' as const, reasonCode: 'componente_excluido' as const,
    clauseQuote: 'CLÁUSULA 1.', supportingEvidence: ['presupuesto'], confidence: 0.98,
    decidingGate: 'P2_componente' as const, promptVersion: 'coverage.v1', degradedFrom: null,
    whatIChecked: ['componente'], whatICouldNotCheck: [],
  }) },
  buildDocument: async () => ({ buffer: Buffer.from('doc'), fileName: 'BORRADOR-3246.docx', hasNarrative: true }),
  sendEmail: vi.fn(async () => {}),
  ...over,
})

const evento = {
  folio: '3246', vin: '9GAMM6108KB004600', eventKind: 'asignacion' as const,
  origin: 'correo' as const, fingerprint: 'f1', mailbox: 'miguel.rodriguez@garantiplus.mx',
  occurredAt: new Date('2026-09-01T15:00:00Z'), threadMessageId: '<abc@x>',
}

describe('procesamiento de un evento', () => {
  it('con evidencia completa dictamina y envía un correo', async () => {
    const d = deps()
    const r = await processEvent(evento, d)
    expect(r.action).toBe('dictaminado')
    expect(d.sendEmail).toHaveBeenCalledOnce()
    expect((await findCase('3246'))?.state).toBe('DELIBERADO')
  })

  it('con evidencia incompleta acumula y NO envía correo', async () => {
    const d = deps({ siga: siga([TODA_LA_EVIDENCIA[0]]) })
    const r = await processEvent(evento, d)
    expect(r.action).toBe('acumulando')
    expect(d.sendEmail).not.toHaveBeenCalled()
    expect((await findCase('3246'))?.state).toBe('EN_ACUMULACION')
  })

  it('el segundo evento con el mismo fingerprint se ignora', async () => {
    const d = deps()
    await processEvent(evento, d)
    const r = await processEvent(evento, deps())
    expect(r.action).toBe('ignorado_duplicado')
  })

  it('el caso que pasa de insuficiente a suficiente dictamina en el segundo evento', async () => {
    const parcial = deps({ siga: siga([TODA_LA_EVIDENCIA[0]]) })
    expect((await processEvent(evento, parcial)).action).toBe('acumulando')
    const completo = deps()
    const r = await processEvent({ ...evento, fingerprint: 'f2', eventKind: 'documento_cargado' }, completo)
    expect(r.action).toBe('dictaminado')
    expect(completo.sendEmail).toHaveBeenCalledOnce()
  })

  it('NUNCA invoca al agente de cobertura si la suficiencia es insuficiente', async () => {
    const adjudicate = vi.fn()
    await processEvent(evento, deps({ siga: siga([TODA_LA_EVIDENCIA[0]]), coverageAgent: { adjudicate } }))
    expect(adjudicate).not.toHaveBeenCalled()
  })

  it('un VIN incoherente produce excepción, notifica y no dictamina', async () => {
    const d = deps({ siga: { ...siga(), getClaim: async () => ({ ...averia, vin: 'OTROVIN0000000000' }) } })
    const r = await processEvent(evento, d)
    expect(r.action).toBe('excepcion')
    expect(d.sendEmail).toHaveBeenCalledOnce()
    expect((await findCase('3246'))?.state).toBe('EXCEPCION')
  })

  it('un fallo del modelo deja el caso con el técnico y lo dice', async () => {
    const d = deps({ coverageAgent: { adjudicate: async () => { throw new Error('503') } } })
    const r = await processEvent(evento, d)
    expect(r.action).toBe('sin_dictamen_por_fallo_tecnico')
    expect(d.sendEmail).toHaveBeenCalledOnce()
  })

  it('en Registrada abre el expediente pero no dictamina', async () => {
    const d = deps({ siga: { ...siga(), getClaim: async () => ({ ...averia, status: 'Registrada' }) } })
    const r = await processEvent(evento, d)
    expect(r.action).toBe('acumulando')
    expect(d.sendEmail).not.toHaveBeenCalled()
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/pipeline/process-event.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar el emisor de eventos de observabilidad**

```typescript
// src/observability/events.ts
import { anonymizeDeep } from './anonymize.js'

/** Los eventos del §11 del PRD. La lista es cerrada a propósito: un evento no listado es un defecto. */
export type ObservabilityEvent =
  | 'evento_recibido' | 'evento_descartado_por_repetido' | 'expediente_creado' | 'expediente_actualizado'
  | 'expediente_incoherente' | 'expediente_abierto_sin_dictamen' | 'paso_a_validacion_detectado'
  | 'barrido_ejecutado' | 'sistema_afectado_identificado' | 'suficiencia_evaluada'
  | 'caso_alcanzo_suficiencia' | 'caso_marcado_estancado' | 'caso_reactivado_desde_estancado'
  | 'dictamen_emitido' | 'dictamen_revisado_por_informacion_nueva' | 'caso_remitido_por_desconfianza'
  | 'documento_generado' | 'correo_enviado_al_tecnico' | 'reporte_matutino_enviado'
  | 'reporte_matutino_fallido' | 'excepcion_registrada' | 'excepcion_notificada' | 'error_tecnico'

export function emit(event: ObservabilityEvent, payload: Record<string, unknown>): void {
  // Todo lo que sale por aquí pasa por la anonimización: el log es una salida más (RNF-12).
  process.stdout.write(JSON.stringify({ event, at: new Date().toISOString(), ...anonymizeDeep(payload) }) + '\n')
}
```

- [ ] **Step 4: Implementar la orquestación**

```typescript
// src/pipeline/process-event.ts
import { findCase, createCase, updateCaseState, patchCase } from '../db/repositories/case-repository.js'
import { recordEvent } from '../db/repositories/event-repository.js'
import { saveSufficiency, latestSufficiency } from '../db/repositories/sufficiency-repository.js'
import { saveVerdict, latestVerdict } from '../db/repositories/verdict-repository.js'
import { assembleDossier } from '../siga/dossier-assembler.js'
import { evaluateSufficiency, type MissingItem } from '../sufficiency/sufficiency-evaluator.js'
import { buildVerdictEmail } from '../output/verdict-email.js'
import { loadConfig } from '../config/env.js'
import { TechnicalError } from '../domain/errors.js'
import { emit } from '../observability/events.js'
import type { SigaReader } from '../siga/siga-types.js'
import type { SystemIdentifier } from '../sufficiency/system-identifier.js'
import type { CoverageAgent } from '../adjudication/coverage-agent.js'
import type { buildDeliberationDocument } from '../output/document-builder.js'

export type IncomingEvent = {
  folio: string; vin: string | null; eventKind: string; origin: 'correo' | 'barrido'
  fingerprint: string; mailbox?: string; occurredAt: Date; threadMessageId?: string | null
}

export type ProcessDeps = {
  siga: SigaReader
  identifier: SystemIdentifier
  coverageAgent: CoverageAgent
  buildDocument: typeof buildDeliberationDocument
  sendEmail: (m: { to: string[]; cc: string[]; subject: string; html: string; inReplyTo?: string | null; attachments?: Array<{ fileName: string; content: Buffer }> }) => Promise<void>
}

export type ProcessOutcome =
  | { action: 'ignorado_duplicado' }
  | { action: 'acumulando'; missing: MissingItem[] }
  | { action: 'dictaminado'; verdictId: number; emailSent: true }
  | { action: 'excepcion'; code: string }
  | { action: 'sin_dictamen_por_fallo_tecnico'; component: string }

/** Solo en Validación se dictamina: criterio del área (B8 del PRD). */
const ESTATUS_TRABAJABLE = 'Validación'

export async function processEvent(input: IncomingEvent, deps: ProcessDeps): Promise<ProcessOutcome> {
  const cfg = loadConfig()

  let caso = await findCase(input.folio)
  if (!caso) {
    if (!input.vin) return { action: 'excepcion', code: 'SIN_VIN' }
    caso = await createCase({ claimFolio: input.folio, vin: input.vin, occurredAt: input.occurredAt })
    emit('expediente_creado', { folio: input.folio, vin: input.vin })
  }

  const evento = await recordEvent({
    claimFolio: input.folio, eventKind: input.eventKind, origin: input.origin,
    fingerprint: input.fingerprint, mailbox: input.mailbox, occurredAt: input.occurredAt,
  })
  if (!evento) {
    emit('evento_descartado_por_repetido', { folio: input.folio, tipo: input.eventKind })
    return { action: 'ignorado_duplicado' }
  }
  emit('evento_recibido', { folio: input.folio, tipo: input.eventKind, origen: input.origin, secuencia: evento.sequenceNumber })

  try {
    const armado = await assembleDossier(input.folio, { siga: deps.siga })
    if (!armado.ok) {
      await moverA(input.folio, 'EXCEPCION')
      emit('excepcion_registrada', { folio: input.folio, code: armado.exception.code, mensaje: armado.exception.message })
      await deps.sendEmail({
        to: caso.assignedTo ? [caso.assignedTo] : [], cc: [cfg.areaManagerEmail],
        subject: `[EXCEPCIÓN] Avería ${input.folio} — requiere revisión manual`,
        html: `<p>El copiloto no pudo procesar la avería <strong>${input.folio}</strong>.</p>
               <p><strong>Motivo:</strong> ${armado.exception.message}</p>
               <p>El caso queda contigo, sin dictamen.</p>`,
      })
      emit('excepcion_notificada', { folio: input.folio, code: armado.exception.code })
      return { action: 'excepcion', code: armado.exception.code }
    }

    caso = armado.case
    if (armado.newDocuments.length) {
      emit('expediente_actualizado', { folio: input.folio, documentosNuevos: armado.newDocuments.length })
    }

    // B8: en Registrada se abre y se puebla, pero no se evalúa suficiencia ni se dictamina.
    if (caso.claimStatus !== ESTATUS_TRABAJABLE) {
      await moverA(input.folio, 'EN_ACUMULACION')
      emit('expediente_abierto_sin_dictamen', { folio: input.folio, estatus: caso.claimStatus })
      return { action: 'acumulando', missing: [] }
    }

    const contrato = await deps.siga.getContractDetail(caso.contractId!)
    const claim = await deps.siga.getClaim(input.folio)

    const suficiencia = await evaluateSufficiency(
      {
        failureDescription: claim.failureDescription,
        documents: armado.documents.map((d) => ({ documentType: d.documentType, legible: true })),
      },
      { identifier: deps.identifier }
    )
    await saveSufficiency(input.folio, evento.id, suficiencia)
    await patchCase(input.folio, { affectedSystem: suficiencia.affectedSystem })
    emit('suficiencia_evaluada', {
      folio: input.folio, resultado: suficiencia.result, sistema: suficiencia.affectedSystem,
      faltantes: suficiencia.missing.map((m) => m.requirementKey), catalogo: suficiencia.catalogVersion,
    })

    // RNF-18: la única puerta hacia el dictamen.
    if (suficiencia.result === 'insuficiente') {
      await moverA(input.folio, 'EN_ACUMULACION')
      return { action: 'acumulando', missing: suficiencia.missing }
    }

    await moverA(input.folio, 'SUFICIENTE')
    emit('caso_alcanzo_suficiencia', {
      folio: input.folio, eventos: evento.sequenceNumber,
      dias: Math.floor((input.occurredAt.getTime() - caso.zeroMarkAt.getTime()) / 86_400_000),
    })

    const anterior = await latestVerdict(input.folio)
    const dictamen = await deps.coverageAgent.adjudicate({
      failureDescription: claim.failureDescription,
      certificateText: caso.certificateText!,
      contract: { validFrom: contrato.validFrom, validTo: contrato.validTo, product: contrato.product },
      vehicle: contrato.vehicle, claimDate: claim.reportedAt,
      documentSummaries: armado.documents.map((d) => `${d.documentType}: ${d.fileName}`),
    })

    const verdictId = await saveVerdict(input.folio, evento.id, dictamen,
      anterior ? { id: anterior.id, reason: 'Llegó información nueva al expediente' } : undefined)
    emit(anterior ? 'dictamen_revisado_por_informacion_nueva' : 'dictamen_emitido', {
      folio: input.folio, veredicto: dictamen.value, motivo: dictamen.reasonCode,
      confianza: dictamen.confidence, puerta: dictamen.decidingGate, prompt: dictamen.promptVersion,
    })

    const doc = await deps.buildDocument({
      case: caso, contract: contrato, verdict: dictamen,
      evidenceUsed: dictamen.supportingEvidence, catalogProvisional: suficiencia.catalogVersion.includes('provisional'),
    })
    emit('documento_generado', { folio: input.folio, plantilla: contrato.product, conNarrativa: doc.hasNarrative })

    const correo = buildVerdictEmail({
      case: { claimFolio: caso.claimFolio, vin: caso.vin, assignedTo: caso.assignedTo },
      vehicle: contrato.vehicle, contract: contrato, verdict: dictamen,
      whatIChecked: dictamen.whatIChecked, whatICouldNotCheck: dictamen.whatICouldNotCheck,
      eventsToSufficiency: evento.sequenceNumber,
      daysToSufficiency: Math.floor((input.occurredAt.getTime() - caso.zeroMarkAt.getTime()) / 86_400_000),
      areaManagerEmail: cfg.areaManagerEmail, threadMessageId: input.threadMessageId ?? null,
      attachments: [{ fileName: doc.fileName, content: doc.buffer }],
      catalogProvisional: suficiencia.catalogVersion.includes('provisional'),
    })
    await deps.sendEmail(correo)
    emit('correo_enviado_al_tecnico', { folio: input.folio, destinatarios: correo.to, veredicto: dictamen.value })

    await updateCaseState(input.folio, 'DELIBERADO')
    return { action: 'dictaminado', verdictId, emailSent: true }
  } catch (e) {
    const componente = e instanceof TechnicalError ? e.component : 'desconocido'
    emit('error_tecnico', { folio: input.folio, componente, error: String(e) })
    // RNF-08: el caso queda con el técnico, con aviso. Nunca se resuelve de todas formas.
    await deps.sendEmail({
      to: caso.assignedTo ? [caso.assignedTo] : [], cc: [cfg.areaManagerEmail],
      subject: `[SIN DICTAMEN] Avería ${input.folio} — fallo técnico del copiloto`,
      html: `<p>El copiloto falló al procesar la avería <strong>${input.folio}</strong> y
             <strong>no emitió dictamen</strong>. El caso es tuyo. TI ya fue alertado.</p>
             <p><strong>Componente:</strong> ${componente}</p>`,
    })
    return { action: 'sin_dictamen_por_fallo_tecnico', component: componente }
  }
}

/** Idempotente ante repeticiones del mismo estado, y respeta la máquina de estados. */
async function moverA(folio: string, hasta: 'EN_ACUMULACION' | 'SUFICIENTE' | 'EXCEPCION'): Promise<void> {
  const actual = await findCase(folio)
  if (!actual || actual.state === hasta) return
  await updateCaseState(folio, hasta)
}
```

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/pipeline/process-event.test.ts`
Esperado: PASS, 8 tests.

- [ ] **Step 6: Correr toda la suite**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run`
Esperado: PASS en todo.

- [ ] **Step 7: Commit**

```bash
git add src/pipeline src/observability tests/pipeline
git commit -m "feat: orquestacion del evento con suficiencia como unica puerta al dictamen"
```

---

## Task 18: Servidor HTTP y trabajos programados

**Files:**
- Create: `src/http/server.ts`, `src/http/jobs.ts`
- Test: `tests/http/server.test.ts`

**Interfaces:**
- Consumes: `processEvent` (Task 17), `sweepOpenCases` y `detectStalledCases` (Task 10), `gatherReportData` y `buildMorningReport` (Task 16).
- Produces: `buildServer(deps): FastifyInstance` con `POST /events/email`, `POST /jobs/sweep`, `POST /jobs/morning-report`, `GET /health`.

- [ ] **Step 1: Escribir el test**

```typescript
// tests/http/server.test.ts
import { describe, it, expect, beforeEach, afterAll, vi } from 'vitest'
import { runMigrations, closePool, getPool } from '../../src/db/client.js'
import { buildServer } from '../../src/http/server.js'

beforeEach(async () => { await runMigrations(); await getPool().query('TRUNCATE cases CASCADE') })
afterAll(async () => { await closePool() })

const correoValido = {
  from: 'Contacto@garantiplus.mx', to: 'miguel.rodriguez@garantiplus.mx',
  subject: 'Asignación de avería 3246 / Vin 9GAMM6108KB004600',
  body: 'Se le ha asignado la avería 3246 con VIN 9GAMM6108KB004600.',
  messageId: '<a@x>', receivedAt: '2026-09-01T15:00:00.000Z',
}

const deps = () => ({
  processEvent: vi.fn(async () => ({ action: 'acumulando' as const, missing: [] })),
  sweep: vi.fn(async () => ({ reviewed: 3, changed: 1, errors: 0 })),
  detectStalled: vi.fn(async () => ['2999']),
  sendMorningReports: vi.fn(async () => ({ sent: 2, failed: 0 })),
})

describe('endpoints', () => {
  it('POST /events/email procesa un correo reconocido', async () => {
    const d = deps(); const app = buildServer(d)
    const r = await app.inject({ method: 'POST', url: '/events/email', payload: correoValido })
    expect(r.statusCode).toBe(202)
    expect(d.processEvent).toHaveBeenCalledOnce()
  })

  it('POST /events/email devuelve 200 e ignora un correo no reconocido, sin procesar', async () => {
    const d = deps(); const app = buildServer(d)
    const r = await app.inject({ method: 'POST', url: '/events/email', payload: { ...correoValido, from: 'spam@otro.com' } })
    expect(r.statusCode).toBe(200)
    expect(r.json()).toEqual({ recognized: false })
    expect(d.processEvent).not.toHaveBeenCalled()
  })

  it('POST /events/email rechaza un cuerpo malformado con 400', async () => {
    const app = buildServer(deps())
    const r = await app.inject({ method: 'POST', url: '/events/email', payload: { subject: 'sin remitente' } })
    expect(r.statusCode).toBe(400)
  })

  it('POST /jobs/sweep corre el barrido y luego la detección de estancados', async () => {
    const d = deps(); const app = buildServer(d)
    const r = await app.inject({ method: 'POST', url: '/jobs/sweep' })
    expect(r.statusCode).toBe(200)
    expect(r.json()).toMatchObject({ reviewed: 3, changed: 1, stalled: ['2999'] })
    expect(d.sweep).toHaveBeenCalledOnce()
    expect(d.detectStalled).toHaveBeenCalledOnce()
  })

  it('POST /jobs/morning-report envía los reportes', async () => {
    const d = deps(); const app = buildServer(d)
    const r = await app.inject({ method: 'POST', url: '/jobs/morning-report' })
    expect(r.statusCode).toBe(200)
    expect(r.json()).toMatchObject({ sent: 2 })
  })

  it('GET /health reporta la conexión a la base', async () => {
    const app = buildServer(deps())
    const r = await app.inject({ method: 'GET', url: '/health' })
    expect(r.statusCode).toBe(200)
    expect(r.json().database).toBe('ok')
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/http/server.test.ts`
Esperado: FAIL — módulo no encontrado.

- [ ] **Step 3: Implementar**

```typescript
// src/http/server.ts
import Fastify, { type FastifyInstance } from 'fastify'
import { z } from 'zod'
import { parseSigaEmail } from '../ingestion/email-parser.js'
import { getPool } from '../db/client.js'
import { emit } from '../observability/events.js'
import type { ProcessOutcome, IncomingEvent } from '../pipeline/process-event.js'

const correoSchema = z.object({
  from: z.string().min(1), to: z.string().min(1), subject: z.string(),
  body: z.string(), messageId: z.string().min(1), receivedAt: z.string(),
})

/**
 * El servidor recibe `processEvent` ya cerrado sobre sus dependencias reales
 * (`(input) => processEvent(input, dependenciasDeProduccion)`), para que los tests
 * puedan sustituirlo por un doble sin construir todo el grafo.
 */
export type ServerDeps = {
  processEvent: (input: IncomingEvent) => Promise<ProcessOutcome>
  sweep: () => Promise<{ reviewed: number; changed: number; errors: number }>
  detectStalled: () => Promise<string[]>
  sendMorningReports: () => Promise<{ sent: number; failed: number }>
}

export function buildServer(deps: ServerDeps): FastifyInstance {
  const app = Fastify({ logger: false })

  app.post('/events/email', async (req, reply) => {
    const parsed = correoSchema.safeParse(req.body)
    if (!parsed.success) return reply.code(400).send({ error: 'Cuerpo inválido', issues: parsed.error.issues })

    const correo = parseSigaEmail(parsed.data)
    if (!correo.recognized) return reply.code(200).send({ recognized: false })

    const resultado = await deps.processEvent({
      folio: correo.folio, vin: correo.vin, eventKind: correo.eventKind, origin: 'correo',
      fingerprint: correo.fingerprint, mailbox: correo.mailbox, occurredAt: correo.occurredAt,
      threadMessageId: parsed.data.messageId,
    })
    return reply.code(202).send({ recognized: true, folio: correo.folio, ...resultado })
  })

  app.post('/jobs/sweep', async (_req, reply) => {
    const r = await deps.sweep()
    const stalled = await deps.detectStalled()
    emit('barrido_ejecutado', { revisados: r.reviewed, cambiados: r.changed, errores: r.errors, estancados: stalled.length })
    for (const folio of stalled) emit('caso_marcado_estancado', { folio })
    return reply.send({ ...r, stalled })
  })

  app.post('/jobs/morning-report', async (_req, reply) => {
    const r = await deps.sendMorningReports()
    return reply.send(r)
  })

  app.get('/health', async (_req, reply) => {
    try {
      await getPool().query('SELECT 1')
      return reply.send({ status: 'ok', database: 'ok' })
    } catch {
      return reply.code(503).send({ status: 'degradado', database: 'error' })
    }
  })

  return app
}
```

```typescript
// src/http/jobs.ts
import { getPool } from '../db/client.js'
import { loadConfig } from '../config/env.js'
import { gatherReportData } from '../db/repositories/report-repository.js'
import { buildMorningReport } from '../output/morning-report.js'
import { emit } from '../observability/events.js'

export function makeSendMorningReports(
  sendEmail: (m: { to: string[]; cc: string[]; subject: string; html: string }) => Promise<void>
) {
  return async function sendMorningReports(): Promise<{ sent: number; failed: number }> {
    const cfg = loadConfig()
    const { rows } = await getPool().query(
      `SELECT DISTINCT assigned_to FROM cases WHERE state <> 'CERRADO' AND assigned_to IS NOT NULL`
    )
    const ahora = new Date()
    const desde = new Date(ahora.getTime() - 24 * 3_600_000)
    let sent = 0, failed = 0

    for (const { assigned_to: tecnico } of rows) {
      try {
        const datos = await gatherReportData(tecnico, desde, ahora)
        const correo = buildMorningReport(datos, { areaManagerEmail: cfg.areaManagerEmail })
        await sendEmail(correo)
        emit('reporte_matutino_enviado', {
          destinatario: tecnico, activos: datos.active.length,
          listos: datos.readyToAdjudicate.length, estancados: datos.stalled.length,
        })
        sent++
      } catch (e) {
        // RF-92: la ausencia del reporte no puede pasar inadvertida.
        emit('reporte_matutino_fallido', { destinatario: tecnico, error: String(e), alertadoTI: true })
        failed++
      }
    }
    return { sent, failed }
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run tests/http/server.test.ts`
Esperado: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add src/http tests/http
git commit -m "feat: endpoints HTTP para ingesta de correo, barrido y reporte matutino"
```

---

## Task 19: Workflows de n8n

**Files:**
- Create: `n8n/workflows/01-gmail-a-copiloto.json`
- Create: `n8n/workflows/02-barrido-periodico.json`
- Create: `n8n/workflows/03-reporte-matutino.json`
- Create: `n8n/workflows/04-envio-de-correo.json`
- Create: `docs/runbook.md`
- Test: `tests/http/contract.test.ts` — contrato entre n8n y el servicio

**Interfaces:**
- Consumes: los endpoints de la Task 18.
- Produces: cuatro workflows y el contrato documentado de sus payloads.

- [ ] **Step 1: Escribir el test de contrato**

```typescript
// tests/http/contract.test.ts
import { describe, it, expect } from 'vitest'
import { readFileSync, readdirSync } from 'node:fs'

/**
 * n8n y el servicio se comunican por un contrato que nadie compila.
 * Este test es lo único que impide que se rompa en silencio al editar un workflow.
 */
describe('contrato entre n8n y el copiloto', () => {
  const dir = 'n8n/workflows'
  const workflows = readdirSync(dir).filter((f) => f.endsWith('.json'))
    .map((f) => ({ file: f, json: JSON.parse(readFileSync(`${dir}/${f}`, 'utf8')) }))

  it('existen los cuatro workflows', () => {
    expect(workflows.map((w) => w.file).sort()).toEqual([
      '01-gmail-a-copiloto.json', '02-barrido-periodico.json',
      '03-reporte-matutino.json', '04-envio-de-correo.json',
    ])
  })

  it('el workflow de Gmail manda exactamente los campos que el endpoint valida', () => {
    const w = workflows.find((x) => x.file.startsWith('01'))!.json
    const cuerpo = JSON.stringify(w)
    for (const campo of ['from', 'to', 'subject', 'body', 'messageId', 'receivedAt']) {
      expect(cuerpo, `falta el campo ${campo} en el payload`).toContain(campo)
    }
    expect(cuerpo).toContain('/events/email')
  })

  it('ningún workflow contiene credenciales en claro', () => {
    for (const { file, json } of workflows) {
      const texto = JSON.stringify(json)
      expect(texto, `${file} parece traer una llave`).not.toMatch(/sk-[A-Za-z0-9]{10,}/)
      expect(texto, `${file} parece traer una contraseña`).not.toMatch(/"password"\s*:\s*"[^"{]/)
    }
  })

  it('los crones apuntan a los endpoints correctos', () => {
    expect(JSON.stringify(workflows.find((x) => x.file.startsWith('02'))!.json)).toContain('/jobs/sweep')
    expect(JSON.stringify(workflows.find((x) => x.file.startsWith('03'))!.json)).toContain('/jobs/morning-report')
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/http/contract.test.ts`
Esperado: FAIL — no existe `n8n/workflows`.

- [ ] **Step 3: Construir los workflows en n8n y exportarlos**

Construye cada workflow en la instancia de n8n y expórtalo al archivo indicado. Los cuatro son deliberadamente delgados: **ningún nodo de código con lógica de decisión**.

**`01-gmail-a-copiloto.json`** — el disparador.
- Nodo *Gmail Trigger*, modo push, sobre los buzones designados.
- Nodo *HTTP Request*: `POST {{COPILOTO_URL}}/events/email`, cabecera `x-api-key` desde credencial de n8n, cuerpo JSON:
  ```json
  {
    "from": "={{ $json.from.value[0].address }}",
    "to": "={{ $json.to.value[0].address }}",
    "subject": "={{ $json.subject }}",
    "body": "={{ $json.textPlain || $json.textHtml }}",
    "messageId": "={{ $json.messageId }}",
    "receivedAt": "={{ $json.date }}"
  }
  ```
- Sin nodos IF, sin nodos de código. **Reconocer el correo es trabajo del servicio**, no del workflow: así el criterio está en un archivo con tests.

**`02-barrido-periodico.json`** — la red de seguridad.
- Nodo *Schedule Trigger*: cada 30 minutos entre las 07:00 y las 21:00, hora de México.
- Nodo *HTTP Request*: `POST {{COPILOTO_URL}}/jobs/sweep`.
- Nodo *IF* sobre `errors > 0` → nodo de correo a TI.

**`03-reporte-matutino.json`** — el reporte.
- Nodo *Schedule Trigger*: todos los días a las 07:30, hora de México.
- Nodo *HTTP Request*: `POST {{COPILOTO_URL}}/jobs/morning-report`.
- Nodo *IF* sobre `failed > 0` → nodo de correo a TI.

**`04-envio-de-correo.json`** — la salida.
- Nodo *Webhook*: `POST /copiloto/send-email`, protegido por cabecera.
- Nodo *Gmail — Send*: usa `to`, `cc`, `subject`, `html`, `inReplyTo` y `attachments` tal como los envía el servicio.
- Nodo *Respond to Webhook* con el `messageId` resultante.

- [ ] **Step 4: Escribir el runbook**

Crear `docs/runbook.md` con: cómo desplegar el servicio, cómo importar los cuatro workflows, qué credenciales necesita cada uno, **cómo apagar el copiloto en un minuto** (deshabilitar el workflow 01 y el 02 en n8n), cómo verificar la salud (`GET /health`), y qué hacer si el reporte matutino no llegó.

- [ ] **Step 5: Correr el test y verificar que pasa**

Run: `npx vitest run tests/http/contract.test.ts`
Esperado: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add n8n docs tests/http/contract.test.ts
git commit -m "feat: workflows de n8n delgados y contrato verificado con el servicio"
```

---

## Task 20: Preparación de la etapa 2 — el interruptor de escritura

**Files:**
- Create: `src/writeback/siga-writer.ts`, `src/writeback/noop-writer.ts`, `src/writeback/resolution-flow.ts`
- Modify: `src/pipeline/process-event.ts` — conectar el flujo de escritura tras el dictamen
- Test: `tests/writeback/resolution-flow.test.ts`

**Interfaces:**
- Consumes: `FinalVerdict` (Task 12), `AppConfig` (Task 1).
- Produces:
  ```typescript
  interface SigaWriter {
    uploadResolution(folio: string, doc: { fileName: string; content: Buffer }): Promise<{ documentId: string }>
    markAsRejected(folio: string, input: { reasonCode: string; documentId: string }): Promise<void>
  }
  createNoopWriter(): SigaWriter                     // etapa 1: registra la intención, no escribe
  executeResolution(input, deps): Promise<ResolutionOutcome>
  type ResolutionOutcome = { written: false; reason: 'bandera_apagada' | 'no_es_improcedente' | 'confianza_insuficiente' } | { written: true; documentId: string } | { written: false; reason: 'carga_fallida'; error: string }
  ```

- [ ] **Step 1: Escribir el test**

```typescript
// tests/writeback/resolution-flow.test.ts
import { describe, it, expect, vi } from 'vitest'
import { executeResolution } from '../../src/writeback/resolution-flow.js'
import { createNoopWriter } from '../../src/writeback/noop-writer.js'

const improcedenteAlto = {
  value: 'improcedente' as const, reasonCode: 'componente_excluido' as const,
  clauseQuote: 'CLÁUSULA 1.', supportingEvidence: [], confidence: 0.98,
  decidingGate: 'P2_componente' as const, promptVersion: 'coverage.v1', degradedFrom: null,
}

const doc = { fileName: 'r.docx', content: Buffer.from('x') }

function escritor(over: Record<string, unknown> = {}) {
  return {
    uploadResolution: vi.fn(async () => ({ documentId: 'DOC-99' })),
    markAsRejected: vi.fn(async () => {}),
    ...over,
  }
}

describe('flujo de resolución', () => {
  it('con la bandera apagada NO escribe nada, aunque el dictamen lo permita', async () => {
    const w = escritor()
    const r = await executeResolution(
      { folio: '3246', verdict: improcedenteAlto, document: doc },
      { writer: w, stage2WriteEnabled: false }
    )
    expect(r).toEqual({ written: false, reason: 'bandera_apagada' })
    expect(w.uploadResolution).not.toHaveBeenCalled()
    expect(w.markAsRejected).not.toHaveBeenCalled()
  })

  it('con la bandera encendida sube el documento ANTES de marcar el estatus', async () => {
    const orden: string[] = []
    const w = escritor({
      uploadResolution: vi.fn(async () => { orden.push('documento'); return { documentId: 'DOC-99' } }),
      markAsRejected: vi.fn(async () => { orden.push('estatus') }),
    })
    const r = await executeResolution(
      { folio: '3246', verdict: improcedenteAlto, document: doc },
      { writer: w, stage2WriteEnabled: true }
    )
    expect(r).toEqual({ written: true, documentId: 'DOC-99' })
    expect(orden).toEqual(['documento', 'estatus'])
  })

  it('si la carga del documento falla, NO marca el estatus', async () => {
    const w = escritor({ uploadResolution: vi.fn(async () => { throw new Error('507') }) })
    const r = await executeResolution(
      { folio: '3246', verdict: improcedenteAlto, document: doc },
      { writer: w, stage2WriteEnabled: true }
    )
    expect(r).toMatchObject({ written: false, reason: 'carga_fallida' })
    expect(w.markAsRejected).not.toHaveBeenCalled()
  })

  it('no escribe en duda ni en sin causal', async () => {
    for (const value of ['duda', 'sin_causal_de_improcedencia'] as const) {
      const w = escritor()
      const r = await executeResolution(
        { folio: '3246', verdict: { ...improcedenteAlto, value, reasonCode: null }, document: doc },
        { writer: w, stage2WriteEnabled: true }
      )
      expect(r).toEqual({ written: false, reason: 'no_es_improcedente' })
      expect(w.uploadResolution).not.toHaveBeenCalled()
    }
  })

  it('no escribe si la confianza no supera el umbral de su causal', async () => {
    const w = escritor()
    const r = await executeResolution(
      { folio: '3246', verdict: { ...improcedenteAlto, confidence: 0.80 }, document: doc },
      { writer: w, stage2WriteEnabled: true }
    )
    expect(r).toEqual({ written: false, reason: 'confianza_insuficiente' })
  })

  it('el escritor inerte de la etapa 1 no lanza y no reporta escritura', async () => {
    const r = await executeResolution(
      { folio: '3246', verdict: improcedenteAlto, document: doc },
      { writer: createNoopWriter(), stage2WriteEnabled: false }
    )
    expect(r.written).toBe(false)
  })
})
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `npx vitest run tests/writeback/resolution-flow.test.ts`
Esperado: FAIL — módulos no encontrados.

- [ ] **Step 3: Implementar la interfaz y el escritor inerte**

```typescript
// src/writeback/siga-writer.ts

/**
 * Capacidades de escritura de la ETAPA 2. La API de SIGA todavía no las expone
 * (ver el PRD hermano `SIGA/PJ5682-api-averias-siga`), así que la interfaz existe
 * y la implementación real llega cuando el endpoint exista.
 */
export interface SigaWriter {
  uploadResolution(folio: string, doc: { fileName: string; content: Buffer }): Promise<{ documentId: string }>
  markAsRejected(folio: string, input: { reasonCode: string; documentId: string }): Promise<void>
}
```

```typescript
// src/writeback/noop-writer.ts
import { emit } from '../observability/events.js'
import type { SigaWriter } from './siga-writer.js'

/**
 * Etapa 1: registra lo que se HABRÍA escrito y no escribe nada.
 * Su valor es que el día que se encienda la etapa 2 ya sabremos, con datos,
 * cuántas escrituras habría hecho el sistema y de qué tipo.
 */
export function createNoopWriter(): SigaWriter {
  return {
    async uploadResolution(folio, doc) {
      emit('excepcion_registrada', { folio, tipo: 'escritura_omitida', accion: 'subir_documento', archivo: doc.fileName })
      throw new Error('La escritura en SIGA no está habilitada en la etapa 1')
    },
    async markAsRejected(folio, input) {
      emit('excepcion_registrada', { folio, tipo: 'escritura_omitida', accion: 'marcar_improcedente', motivo: input.reasonCode })
      throw new Error('La escritura en SIGA no está habilitada en la etapa 1')
    },
  }
}
```

- [ ] **Step 4: Implementar el flujo de resolución**

```typescript
// src/writeback/resolution-flow.ts
import { thresholdFor, type FinalVerdict } from '../adjudication/confidence.js'
import { emit } from '../observability/events.js'
import type { SigaWriter } from './siga-writer.js'

export type ResolutionOutcome =
  | { written: false; reason: 'bandera_apagada' | 'no_es_improcedente' | 'confianza_insuficiente' }
  | { written: false; reason: 'carga_fallida'; error: string }
  | { written: true; documentId: string }

/**
 * G2 del PRD, regla inviolable: primero el documento, después el estatus.
 * Si la carga falla no se marca nada, para no repetir el fallo silencioso del auto-rechazo de SIGA.
 */
export async function executeResolution(
  input: { folio: string; verdict: FinalVerdict; document: { fileName: string; content: Buffer } },
  deps: { writer: SigaWriter; stage2WriteEnabled: boolean }
): Promise<ResolutionOutcome> {
  const { verdict: v, folio } = input

  if (v.value !== 'improcedente' || !v.reasonCode) return { written: false, reason: 'no_es_improcedente' }
  if (v.confidence <= thresholdFor(v.reasonCode)) return { written: false, reason: 'confianza_insuficiente' }

  if (!deps.stage2WriteEnabled) {
    emit('excepcion_registrada', {
      folio, tipo: 'marcado_omitido_por_configuracion',
      dictamenQueSeHabriaAplicado: v.reasonCode, confianza: v.confidence,
    })
    return { written: false, reason: 'bandera_apagada' }
  }

  let documentId: string
  try {
    ;({ documentId } = await deps.writer.uploadResolution(folio, input.document))
  } catch (e) {
    emit('error_tecnico', { folio, componente: 'siga.uploadResolution', error: String(e), estatusNoMarcado: true })
    return { written: false, reason: 'carga_fallida', error: String(e) }
  }

  await deps.writer.markAsRejected(folio, { reasonCode: v.reasonCode, documentId })
  emit('dictamen_emitido', { folio, escrituraEnSiga: true, documentId, motivo: v.reasonCode })
  return { written: true, documentId }
}
```

- [ ] **Step 5: Conectar el flujo en la orquestación**

En `src/pipeline/process-event.ts`, justo después de generar el documento y antes de enviar el correo, agregar:

```typescript
    const resolucion = await executeResolution(
      { folio: input.folio, verdict: dictamen, document: { fileName: doc.fileName, content: doc.buffer } },
      { writer: deps.writer, stage2WriteEnabled: cfg.stage2WriteEnabled }
    )
    if (resolucion.written === false && resolucion.reason === 'carga_fallida') {
      // El documento no llegó al expediente: no se marcó nada y el caso se vuelve excepción.
      await moverA(input.folio, 'EXCEPCION')
    }
```

Y agregar `writer: SigaWriter` a `ProcessDeps`, con `createNoopWriter()` como valor por defecto en el arranque del servicio.

- [ ] **Step 6: Correr toda la suite**

Run: `DATABASE_URL=postgres://localhost/copiloto_test npx vitest run`
Esperado: PASS en todo. Los tests de `process-event` siguen pasando porque la bandera está apagada por defecto.

- [ ] **Step 7: Commit**

```bash
git add src/writeback src/pipeline tests/writeback
git commit -m "feat: interruptor de escritura de la etapa 2, apagado y con orden inviolable"
```

> **Qué queda pendiente para encender la etapa 2.** Solo tres cosas, todas externas al código: (1) que SIGA exponga el endpoint de resolución y el tipo de documento *Resolución*; (2) implementar `createSigaWriter()` contra ese endpoint, sustituyendo al inerte; (3) poner `STAGE2_WRITE_ENABLED=true`. La lógica de decisión, el orden documento-antes-que-estatus, los umbrales y la trazabilidad ya están construidos y probados.

---

## Verificación de cobertura contra el PRD

| Requerimiento del PRD | Task que lo cubre |
| --- | --- |
| RF-01, RF-02, RF-03 — disparo y reconocimiento | 4, 18 |
| RF-04 — correlación por folio e idempotencia | 4, 5 |
| RF-05 — marca cero y hora de cada evento | 5 |
| RF-06 a RF-11 — reunión del expediente y coherencia | 6, 7 |
| RF-12, RF-13 — `Registrada` sin dictamen, detección de `Validación` | 17 |
| RF-14 a RF-18 — puertas, veredicto de tres valores, umbrales | 12, 13 |
| RF-19 — anonimización | 11 |
| RF-20 — sin importes en la etapa 1 | 13 (prompt) |
| RF-21 — versionado de prompts | 9, 13 |
| RF-22 a RF-27 — documento de deliberación | 14 |
| RF-28 a RF-32 — correo de dictamen | 15 |
| RF-33 a RF-38 — registro, excepciones, observabilidad | 17 |
| RF-39 — parametrización por país | *Parcial: la configuración lo admite (Task 1); las tablas por país se agregan en la etapa 5* |
| RF-40 a RF-45 — escritura de la etapa 2 | 20 |
| RF-69 a RF-72 — expediente vivo, refresco incremental, barrido | 5, 7, 10 |
| RF-73 a RF-79 — capa 0 de suficiencia | 8, 9 |
| RF-80 — estado `ESTANCADO` | 10 |
| RF-81 — política de correos silenciosos | 17 |
| RF-82 — reevaluación tras dictamen | 17 |
| RF-83, RF-84 — eventos hasta suficiencia, evidencia usada | 14, 15 |
| RF-85 a RF-93 — reporte matutino | 16, 18 |
| RF-94 a RF-100 — semáforo de confianza | **Fuera de este plan (etapa 3)** |
| RNF-01 a RNF-23 | Distribuidos; los duros —RNF-04, RNF-07, RNF-18, RNF-23— tienen test propio en 3, 5, 17 y 20 |

**Tres huecos declarados, no olvidados:**

1. **Las plantillas oficiales del documento** (Task 14) son un entregable del área. Se construye contra una de andamiaje con los mismos marcadores.
2. **El catálogo real de correos de actualización** (Task 4) no está verificado. El barrido de la Task 10 cubre el hueco mientras tanto.
3. **El catálogo de evidencia mínima** (Task 8) arranca provisional y sin validar. Está marcado como tal en la base y el aviso viaja hasta el correo del técnico.

---

## Orden de ejecución y dependencias

```
1 → 2 → 3 → 5 ┬→ 7 → 10 ┐
    4 ────────┤          ├→ 17 → 18 → 19
    6 ────────┘          │
    8 → 9 ───────────────┤
    11 → 12 → 13 ────────┤
    14 → 15 → 16 ────────┘
                          17 → 20
```

Las tareas 4, 6, 8 y 11 no dependen entre sí y pueden ir en paralelo una vez terminada la 3. La 17 es el punto de convergencia: nada de ella se puede probar de verdad hasta que las anteriores existan.

**Hitos revisables con el área:**

- **Después de la Task 10** — el sistema ya sigue expedientes y detecta estancados, sin dictaminar nada. Es el momento de enseñarle a Miguel y a Eduardo el estado que el sistema está llevando y contrastarlo con lo que ellos llevan en la cabeza.
- **Después de la Task 16** — el reporte matutino funciona. Se puede empezar a enviar **antes** de que el dictamen exista, y ese envío temprano es la mejor forma de validar el catálogo de evidencia mínima con datos reales.
- **Después de la Task 19** — el MVP está completo y en producción, en solo lectura.
- **Después de la Task 20** — la etapa 2 queda a la espera de una bandera y de un endpoint.
