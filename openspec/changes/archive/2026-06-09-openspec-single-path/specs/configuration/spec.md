# Configuration — Single-Path Migration to openspec/

## Dominio: configuration

## Purpose

`openspec/config.yaml` MUST declare `dual_path: false` and remove all `.specify/` references. The `.specify/` directory and `sdd/openspec-dual-path/` legacy design doc SHALL be deleted. `.specify/` SHALL be added to `.gitignore`.

## Requirements

### Requirement: CFG-001 — Dual-path disabled in config

`openspec/config.yaml` MUST set `dual_path: false` and purge all `.specify/` context and rules references.

#### Scenario: Config declares single canonical store

- GIVEN any tool reads `openspec/config.yaml`
- WHEN inspecting the dual_path setting
- THEN `dual_path` SHALL be `false`
- AND the `context` field SHALL mention only `openspec/` as the spec store
- AND `rules.archive` and `rules.verify` SHALL NOT reference `.specify/`

### Requirement: CFG-002 — .specify/ directory removed

The `.specify/` directory MUST be deleted after its content is migrated to `openspec/`. `.specify/` MUST be added to `.gitignore`.

#### Scenario: .specify/ absent from working tree

- GIVEN the migration is complete
- WHEN checking the working tree with `ls`
- THEN `.specify/` SHALL NOT exist as a directory
- AND `.gitignore` SHALL contain an entry for `.specify/`
- AND accidental `git add .specify/` shall be impossible

### Requirement: CFG-003 — Legacy design doc removed

The `sdd/openspec-dual-path/` design document SHALL be deleted as superseded by this change.

#### Scenario: Legacy doc deleted

- GIVEN the migration is complete
- WHEN checking the `sdd/` directory
- THEN `sdd/openspec-dual-path/` SHALL NOT exist
- AND its content SHALL remain accessible via `git log`

### Requirement: CFG-004 — Content migrated before deletion

Existing `.specify/` content (constitution, constitution.template, auto-constitution spec) MUST be copied to `openspec/` equivalents before `.specify/` is deleted.

#### Scenario: Migration preserves data

- GIVEN `.specify/memory/constitution.md` exists pre-migration
- WHEN the migration runs
- THEN it SHALL be copied to `openspec/memory/constitution.md`
- AND constitution.template.md SHALL be copied to `openspec/memory/constitution.template.md`
- AND `000-auto-constitution/` spec SHALL be copied to `openspec/specs/000-auto-constitution/`
