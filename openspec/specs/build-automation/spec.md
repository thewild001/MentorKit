# Build Automation — Single-Path Migration to openspec/

## Dominio: build-automation

## Purpose

Shell scripts (archive-spec, init-constitution, verify), Makefile targets, and GitLab CI pipeline SHALL target `openspec/` exclusively. The `--target` flag, mirror logic, and `.specify/` verification SHALL be removed.

## Requirements

### Requirement: BLD-001 — archive-spec writes to openspec/ only

mentorkit-archive-spec.sh MUST remove the `--target` flag (previously `specify|openspec|both`) and write exclusively to `openspec/`. Mirror logic SHALL be removed.

#### Scenario: Archive writes to openspec/ without flag

- GIVEN a user runs `archive-spec.sh <path>` without `--target`
- WHEN the script archives the spec
- THEN it MUST write to `openspec/changes/archive/{date}-{slug}/`
- AND it MUST NOT reference or write to `.specify/`

#### Scenario: Dry-run shows openspec/ paths

- GIVEN a user runs `archive-spec.sh --dry-run <path>`
- WHEN the script previews the archive
- THEN it SHALL display `openspec/` destination paths
- AND it SHALL NOT display `.specify/` paths

### Requirement: BLD-002 — init-constitution writes to openspec/

mentorkit-init-constitution.sh MUST write to `openspec/memory/constitution.md` by default and read the template from `openspec/memory/constitution.template.md`.

#### Scenario: Constitution written to openspec/

- GIVEN a user runs `init-constitution.sh`
- WHEN the script generates the constitution
- THEN it MUST write to `openspec/memory/constitution.md`
- AND it MUST read the template from `openspec/memory/constitution.template.md`

### Requirement: BLD-003 — verify checks openspec/ only

mentorkit-verify.sh MUST remove the `.specify/` ↔ `openspec/` sync check and verify `openspec/` paths exclusively.

#### Scenario: Verify ignores .specify/

- GIVEN a user runs `make verify`
- WHEN the verify script validates spec store integrity
- THEN it MUST check `openspec/` content only
- AND it MUST NOT reference `.specify/`

### Requirement: BLD-004 — Makefile simplified

Makefile MUST remove the `sync-openspec` target. `archive-spec` and `init-constitution` targets MUST omit the `TARGET` or `--target` variable.

#### Scenario: Makefile targets use openspec/ default

- GIVEN a user runs `make archive-spec SPEC=<path>`
- WHEN the Makefile invokes the script
- THEN it SHALL NOT pass a `--target` flag
- AND `make sync-openspec` SHALL NOT exist

### Requirement: BLD-005 — CI checks openspec/ only

GitLab CI MUST remove the `verify-openspec` job. `verify-archive-spec` and `verify-spec-history` MUST read from `openspec/` exclusively.

#### Scenario: CI verify jobs target openspec/

- GIVEN the CI pipeline runs in the verify stage
- WHEN `verify-archive-spec` executes
- THEN it MUST list specs from `openspec/specs/[0-9]*-*/spec.md`
- AND `verify-spec-history` MUST check `git status openspec/`
- AND the `verify-openspec` desync-check job SHALL be removed
