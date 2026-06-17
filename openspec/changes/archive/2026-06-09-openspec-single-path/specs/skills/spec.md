# Skills — Single-Path Migration to openspec/

## Dominio: skills

## Purpose

The 4 custom SDD skills (codebase-conformist, spec-writer, prd-reader, llm-council) SHALL replace all `.specify/` path references with `openspec/` equivalents. Dual-path fallback logic and mirror writes SHALL be removed. Each skill SHALL target `openspec/` exclusively as the single canonical spec store.

## Requirements

### Requirement: SKL-001 — codebase-conformist paths use openspec/

codebase-conformist MUST replace all `.specify/` references (~8 sites) with `openspec/` equivalents. Dual-path fallback logic SHALL be removed.

#### Scenario: Constitution read targets openspec/

- GIVEN codebase-conformist reads the constitution (Paso -1)
- WHEN it reads the constitution file
- THEN it MUST read `openspec/memory/constitution.md`
- AND it MUST NOT fall back to `.specify/memory/constitution.md`

#### Scenario: Spec glob searches openspec/ only

- GIVEN codebase-conformist searches for existing specs (Paso 0)
- WHEN globbing for spec files
- THEN it MUST glob `openspec/specs/*/spec.md`
- AND it MUST NOT check `.specify/` for specs

### Requirement: SKL-002 — spec-writer paths use openspec/

spec-writer MUST replace all `.specify/` references (~7 sites) with `openspec/` equivalents.

#### Scenario: Spec write targets openspec/

- GIVEN spec-writer produces a spec (Paso 3)
- WHEN writing the spec file
- THEN it MUST write to `openspec/specs/{domain}/spec.md`
- AND all constitution and system-spec reads MUST target `openspec/`

### Requirement: SKL-003 — prd-reader paths use openspec/

prd-reader MUST replace all `.specify/` references (~11 sites) with `openspec/` equivalents.

#### Scenario: PRD spec output in openspec/

- GIVEN prd-reader produces a mergeable delta from PRD content
- WHEN writing the spec delta
- THEN it MUST write to `openspec/changes/{change-name}/specs/{domain}/spec.md`
- AND all reads (constitution, system-spec) MUST target `openspec/`

### Requirement: SKL-004 — llm-council paths use openspec/

llm-council MUST replace all `.specify/` fallback references with `openspec/` paths. Dual-path branching logic SHALL be removed.

#### Scenario: Council reads from openspec/ only

- GIVEN llm-council reads spec context (Modo B standalone or Modo A)
- WHEN accessing the constitution or system-spec
- THEN it MUST read from `openspec/` paths only
- AND dual-path fallback logic SHALL NOT exist
