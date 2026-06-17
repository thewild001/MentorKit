# Archive — Dual-Path Archive Script

## Purpose

The `archive-spec.sh` script SHOULD accept a `--target openspec` flag that archives specs to `openspec/` instead of (or in addition to) `.specify/`. The default target MUST remain `.specify/`.

## Requirements

### Requirement: ARC-001 — --target flag added

The `mentorkit-archive-spec.sh` script SHALL accept a `--target` flag with values `specify` (default), `openspec`, or `both`.

#### Scenario: Default target is .specify/

- GIVEN a user runs `archive-spec.sh <path>` without `--target`
- WHEN the script processes the spec
- THEN it MUST archive to `.specify/specs/archive/`
- AND the behavior SHALL be identical to the current implementation

#### Scenario: --target openspec archives to openspec/

- GIVEN a user runs `archive-spec.sh --target openspec <path>`
- WHEN the script processes the spec
- THEN it MUST archive to `openspec/changes/archive/{date}-{slug}/`
- AND it MUST merge the delta into `openspec/specs/{domain}/spec.md`
- AND it MUST NOT modify `.specify/` content

#### Scenario: --target both writes to both stores

- GIVEN a user runs `archive-spec.sh --target both <path>`
- WHEN the script processes the spec
- THEN it MUST archive to both `.specify/specs/archive/` and `openspec/changes/archive/{date}-{slug}/`
- AND it MUST merge the delta into both `system-spec.md` and `openspec/specs/{domain}/spec.md`
- AND a failure in the second target MUST NOT roll back the first target

### Requirement: ARC-002 — Makefile target updated

The Makefile `archive-spec` target SHALL forward `TARGET=<value>` as `--target <value>` to the script.

#### Scenario: Makefile forwards --target

- GIVEN a user runs `make archive-spec TARGET=openspec SPEC=<path>`
- WHEN the Makefile invokes the script
- THEN it SHALL pass `--target openspec` to `mentorkit-archive-spec.sh`
- AND the help text SHALL list `TARGET` as a recognized variable

### Requirement: ARC-003 — Dry-run supports --target

The `--dry-run` flag SHALL work with `--target` to preview where the spec would be archived.

#### Scenario: Dry-run with --target

- GIVEN a user runs `archive-spec.sh --dry-run --target openspec <path>`
- WHEN the script processes the spec
- THEN it SHALL print the archive destination paths for the chosen target
- AND it SHALL NOT write any files
