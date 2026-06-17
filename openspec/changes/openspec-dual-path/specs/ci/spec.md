# CI — Dual-Path Verification

## Purpose

The CI pipeline MUST verify both `.specify/` and `openspec/` directories. It MUST warn on desync between stores, MUST NOT fail the pipeline on mismatch, and MUST fail on structural issues (e.g., unparseable spec files).

## Requirements

### Requirement: CI-001 — Both stores exist and are accessible

CI MUST verify that both `.specify/` and `openspec/` directories exist and are readable. Missing `openspec/` SHALL be a warning, not a failure.

#### Scenario: Both directories present

- GIVEN the CI runs the verify job
- WHEN both `.specify/` and `openspec/` exist
- THEN CI SHALL report both as present
- AND CI SHALL continue to spec integrity checks

#### Scenario: openspec/ missing

- GIVEN `openspec/` does not exist
- WHEN CI checks for dual-path stores
- THEN CI SHALL emit a warning: "openspec/ no encontrado — desactivar dual-path mode si es intencional"
- AND CI MUST NOT fail the pipeline

### Requirement: CI-002 — Desync detection with warning

CI MUST compare spec content between `.specify/` and `openspec/` for the same domains. Content differences SHALL produce a warning. Identical specs SHALL pass silently.

#### Scenario: Specs are in sync

- GIVEN both stores have matching spec content for the same domains
- WHEN CI compares them
- THEN CI SHALL report: "Specs sincronizados: .specify/ ↔ openspec/"
- AND CI SHALL pass

#### Scenario: Specs are desynced

- GIVEN `.specify/` and `openspec/` differ for the same domain
- WHEN CI compares them
- THEN CI SHALL emit a warning listing the differing files
- AND CI MUST NOT fail the pipeline
- AND the warning message SHALL be actionable: "Desync detectado en: {file}. Corre `make sync-openspec` para resincronizar."

### Requirement: CI-003 — Spec integrity check on both stores

The verify-archive-spec job MUST extend its spec integrity checks to include specs found in `openspec/specs/` if present.

#### Scenario: Spec in openspec/ is unparseable

- GIVEN a spec in `openspec/specs/{domain}/spec.md` has malformed headers
- WHEN the verify job parses it
- THEN CI SHALL fail with the same error format as `.specify/` spec failures
- AND the error SHALL indicate which store contains the broken spec

### Requirement: CI-004 — New CI job for sync check (optional)

A new CI job `verify-dual-path-sync` MAY be added to the verify stage alongside the existing 4 jobs, running in parallel with `needs: []`.

#### Scenario: Sync job runs independently

- GIVEN the dual-path CI job is configured
- WHEN the verify stage executes
- THEN the job SHALL run in parallel with other verify jobs
- AND it SHALL have `needs: []` (no dependencies)
- AND it SHALL complete in under 10 seconds (no heavy dependencies)
