# Skills — Dual-Write and Read Fallback

## Purpose

Custom SDD skills MUST write specs to both `.specify/` (primary) and `openspec/` (secondary). Skills MUST read from `.specify/` first and fall back to `openspec/`. This covers spec-writer, prd-reader (write paths), and codebase-conformist, llm-council (read paths).

## Requirements

### Requirement: SKL-001 — spec-writer dual-write

spec-writer MUST write to `.specify/specs/{NNN}-{slug}/spec.md` as primary output, then mirror to `openspec/specs/{domain}/spec.md`.

#### Scenario: spec-writer produces spec

- GIVEN spec-writer produces a spec via `Write` tool
- WHEN the spec is written to `.specify/specs/{NNN}-{slug}/spec.md`
- THEN it MUST also write the same content to `openspec/specs/{domain}/spec.md`
- AND the primary write to `.specify/` MUST complete before the mirror write starts
- AND failure of the mirror write MUST NOT block or fail the primary write

### Requirement: SKL-002 — prd-reader dual-write

prd-reader MUST write the mergeable delta to `.specify/specs/{NNN}-{slug}/spec.md`, the context section to the same file, and mirror the full spec to `openspec/specs/{domain}/spec.md`.

#### Scenario: prd-reader produces spec

- GIVEN prd-reader produces a spec from PRD content
- WHEN the spec is written to `.specify/specs/{NNN}-{slug}/spec.md`
- THEN it MUST mirror the content to `openspec/specs/{domain}/spec.md`
- AND the `ui-prototypes/` directory SHALL remain in `.specify/` only

### Requirement: SKL-003 — codebase-conformist read fallback

codebase-conformist MUST glob `.specify/specs/*/spec.md` first. If no spec is found, it MUST fall back to globbing `openspec/specs/*/spec.md`.

#### Scenario: Spec in .specify/

- GIVEN a spec exists in `.specify/specs/`
- WHEN codebase-conformist checks for existing specs (Paso 0)
- THEN it MUST read from `.specify/specs/`
- AND it MUST NOT check `openspec/`

#### Scenario: Spec only in openspec/

- GIVEN no spec exists in `.specify/specs/`
- WHEN a spec exists in `openspec/specs/`
- THEN codebase-conformist MUST read from `openspec/specs/`
- AND it MUST note the spec source in the plan

#### Scenario: No spec in either location

- GIVEN neither `.specify/specs/` nor `openspec/specs/` contain a spec
- WHEN codebase-conformist checks for existing specs
- THEN it MUST proceed with normal intake
- AND it MUST NOT warn about missing `openspec/` — it is optional

### Requirement: SKL-004 — llm-council read fallback

When llm-council reads specs for context (Modo B — standalone or Modo A — from codebase-conformist), it MUST prefer `.specify/` and fall back to `openspec/`.

#### Scenario: Council reads spec context

- GIVEN llm-council needs spec context
- WHEN it reads the constitution and system-spec
- THEN it MUST read `.specify/memory/constitution.md` and `.specify/system-spec.md`
- AND if `system-spec.md` is absent, it MAY read `openspec/specs/` for domain specs

### Requirement: SKL-005 — Research and PR description stay in .specify/

Research files (`research.md`) and PR description (`pr-description.md`) SHALL remain in `.specify/` only. They MUST NOT be mirrored to `openspec/`.

#### Scenario: Research output

- GIVEN codebase-conformist produces research output
- WHEN it writes to `.specify/specs/{NNN}-{slug}/research.md`
- THEN it MUST NOT mirror to `openspec/`
