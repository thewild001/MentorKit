# Orchestrator — MentorKit4.0 Dual-Path Support

## Purpose

The MentorKit orchestrator (`MentorKit4.0.md`) MUST support both `.specify/` and `openspec/` paths in Glob/Read operations. All session initialization and workflow routing SHALL understand dual-path resolution.

## Requirements

### Requirement: ORC-001 — Constitution read from .specify/

The constitution read path SHALL remain at `.specify/memory/constitution.md` as the single source of truth. The orchestrator MUST NOT add a secondary read path for constitution — it is not a spec artifact.

#### Scenario: Constitution read unchanged

- GIVEN the orchestrator initializes a session
- WHEN it checks for an existing constitution
- THEN it MUST Glob `.specify/memory/constitution.md` only
- AND it MUST NOT check `openspec/` for constitution files

### Requirement: ORC-002 — Spec read with dual-path fallback

When the orchestrator checks for existing specs (e.g., `spec.md` produced by `prd-reader` or `spec-writer`), it MUST first glob `.specify/specs/` and fall back to `openspec/specs/` if no match is found.

#### Scenario: Spec found in .specify/

- GIVEN a spec exists in `.specify/specs/*/spec.md`
- WHEN the orchestrator checks for existing specs
- THEN it MUST read from `.specify/specs/`
- AND it MUST NOT fall back to `openspec/`

#### Scenario: Spec not in .specify/, found in openspec/

- GIVEN no spec exists in `.specify/specs/`
- WHEN a spec exists in `openspec/specs/{domain}/spec.md`
- THEN the orchestrator MUST fall back to `openspec/specs/`
- AND it MUST signal to codebase-conformist that the spec source is `openspec/`

### Requirement: ORC-003 — PRD detection references .specify/ only

PRD detection and processing paths SHALL remain `.specify/`-only. The `openspec/` mirror SHALL receive spec content after `prd-reader` produces it, not during attachment detection.

#### Scenario: PRD detection

- GIVEN an attached PRD document
- WHEN the orchestrator detects it
- THEN the output path SHALL remain `.specify/specs/{NNN}-{slug}/spec.md`
- AND the mirror write to `openspec/` SHALL happen after the spec is produced

### Requirement: ORC-004 — .specify/ structure documentation updated

The "Estructura .specify/" section in `MentorKit4.0.md` MUST be updated to note that writes are mirrored to `openspec/`.

#### Scenario: Structure docs updated

- GIVEN a developer reads the orchestrator documentation
- WHEN they review the `.specify/` structure section
- THEN the docs SHALL note that `openspec/` is a secondary mirror
- AND the `openspec/` directory structure MAY be documented
