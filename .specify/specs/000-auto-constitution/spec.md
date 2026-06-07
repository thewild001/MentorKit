# Auto-generate constitution from skill outputs

## Status: Active
## Dominio: constitution
## Fecha: 2026-06-06

## ADDED Requirements

### Requirement: CONST-001 — Ground truth (mentorkit self-host)
#### Scenario: User runs `make init-constitution` on the mentorkit repo itself
- The system SHALL produce a `constitution.md` whose Stack section matches the real project: Python 3.12.13, uv, GitLab CI
- The Stack values SHALL be validated against the real `uv.lock` and `.gitlab-ci.yml` of the mentorkit repo
- The output SHALL be used as ground truth for the multi-stack isolation test (CONST-003)

### Requirement: CONST-002 — Four-stack coverage
#### Scenario: User runs the command on a Python project
- The system SHALL detect Python from `uv.lock`, `pyproject.toml`, or `.python-version`
#### Scenario: User runs the command on a Go project
- The system SHALL detect Go from `go.mod`
#### Scenario: User runs the command on a Node.js project
- The system SHALL detect Node.js from `package.json`
#### Scenario: User runs the command on a Rust project
- The system SHALL detect Rust from `Cargo.toml`
#### Scenario: Each of the 4 stacks runs the command
- The system SHALL produce a constitution with the correct Stack of the target project (not mentorkit's)

### Requirement: CONST-003 — Multi-stack isolation test
#### Scenario: The CI runs the isolation test against the 4 hypothetical projects
- Mentorkit's Python stack details (Python 3.12.13, uv, GitLab CI) SHALL NOT appear in the generated constitution of the Go, Node.js, or Rust projects
- A `grep` over each generated constitution SHALL return 0 matches for "Python" or "uv" in non-Python stacks
- The test SHALL run as part of the CI matrix

### Requirement: CONST-004 — CONSTITUCIONAL sections preserved verbatim
#### Scenario: User runs the command and the destination has CONSTITUCIONAL sections
- Those sections SHALL be copied verbatim from `constitution.template.md`
- A `diff` between the generated section and the template section SHALL be empty

### Requirement: CONST-005 — IDENTIDAD sections empty by default
#### Scenario: The generated constitution includes IDENTIDAD sections (project name, description, owners, license, URLs)
- Those sections SHALL be left empty with a `<!-- llenar manualmente -->` marker

### Requirement: CONST-006 — Fingerprint detection signals
#### Scenario: Project has `pyproject.toml` with `requires-python = ">=3.12"`
- The system SHALL detect Python 3.12
#### Scenario: Project has `uv.lock` or `[tool.uv]` block in `pyproject.toml`
- The system SHALL detect uv as the package manager
#### Scenario: Multiple signals are present
- The system SHALL prefer lock files over declarative manifests (defensive fingerprint)

### Requirement: CONST-007 — engram handling (seed + graceful)
#### Scenario: engram is available on the system
- The system SHALL seed engram with at least 2 stable topics: `architecture/<project>-stack` and `discovery/<project>-god-modules`
#### Scenario: engram is NOT available
- The system SHALL print: "engram no detectado, sección engram omitida"
- The system SHALL NOT fail or error out

### Requirement: CONST-008 — Idempotency
#### Scenario: User runs the command twice in a row on the same project
- Both runs SHALL produce byte-identical `constitution.md` (same SHA256)
- No files SHALL be modified on the second run unless fingerprint detection changes

### Requirement: CONST-009 — Human-controlled writes (Confirmation gate)
#### Scenario: The destination `constitution.md` does not exist
- The system SHALL ask: "¿Crear? [Y/n]"
#### Scenario: The destination exists and the diff is non-empty
- The system SHALL display the diff and ask: "¿Aplicar? [Y/n]"
#### Scenario: The user answers N or aborts
- The system SHALL NOT write and SHALL exit non-zero
#### Scenario: The user answers Y
- The system SHALL write but SHALL NOT auto-commit (see CONST-010)

### Requirement: CONST-010 — No auto-commit
#### Scenario: The user approves the write
- The system SHALL write `constitution.md` to disk
- The system SHALL NOT run `git add` or `git commit`
- The human SHALL run `git add` and `git commit` manually

### Requirement: CONST-011 — Tracked in git (not ephemeral)
#### Scenario: First write of `constitution.md` after `make init-constitution`
- The file SHALL live at `.specify/memory/constitution.md` in the project repo
- The file SHALL NOT be in `.gitignore`
- The file SHALL NOT be in `archive/`
- The file SHALL be committable (not ignored by any pre-commit hook)

### Requirement: CONST-012 — Agent reads constitution first
#### Scenario: An agent starts any operation in a project that has a `constitution.md`
- The agent SHALL read `.specify/memory/constitution.md` BEFORE running any fingerprinting
- The agent SHALL NOT re-run fingerprinting on every operation (the constitution already contains the relevant info)
- The agent SHALL surface any conflict between constitution and live code as drift (see CONST-013)

### Requirement: CONST-013 — Drift detection (not conflict resolution)
#### Scenario: Constitution and live code differ (e.g., constitution says Python 3.12, pyproject says 3.11)
- The agent SHALL display the diff and ask the human: "¿Actualizo constitución a 3.11, o arreglo pyproject a 3.12?"
- The agent SHALL NOT auto-resolve drift
- The agent SHALL NOT block on drift (it's a warning, not an error)
- Drift is a human-update reminder, NOT a conflict to resolve

### Requirement: CONST-014 — Constitution priority over fingerprint
#### Scenario: Both constitution and fingerprint are present and they disagree
- The constitution SHALL be treated as the source of truth
- The fingerprint SHALL be advisory only
- The agent SHALL suggest updating the constitution if fingerprint detects drift

### Requirement: CONST-015 — ENRICH without re-running init
#### Scenario: User manually edits `constitution.md` to add a new section (Capa 3 ENRICH)
- The next `make init-constitution` run SHALL preserve the manual edits
- The system SHALL NOT re-render from scratch
- The system SHALL preserve any section that does NOT have an `<!-- auto-derivado -->` marker
- The system SHALL update only the auto-derivado sections (Stack, Architecture from graph)

### Requirement: CONST-016 — Distribution A: Version manifest
#### Scenario: `bootstrap.sh` installs mentorkit on a fresh project
- The system SHALL write `.opencode/MENTORKIT_VERSION` with the installed version (e.g., `5`)
#### Scenario: A subsequent run of `bash <(curl ...)` upgrades mentorkit
- The system SHALL update `.opencode/MENTORKIT_VERSION` to the new version (e.g., `6`)

### Requirement: CONST-017 — Distribution B: Smart-update on bootstrap
#### Scenario: User runs `bash <(curl ...)` and `.opencode/` already exists in the project
- The system SHALL NOT fail
- The system SHALL ask: "¿Actualizar de v3 a v5? Preservaré tu constitution.md. [Y/n]"
#### Scenario: The user answers Y
- The system SHALL smart-merge: preserve the project's `constitution.md` and any other customizations
- The system SHALL overwrite `.opencode/skills/`, `install-mentorkit.sh`, and `requirements.lock` from the new mentorkit tarball
#### Scenario: The user answers N
- The system SHALL exit cleanly without modifying anything

### Requirement: CONST-018 — Distribution D: CI version gate
#### Scenario: A MR is pushed to a project whose `MENTORKIT_VERSION` is older than the latest
- The CI job `verify-mentorkit-version` SHALL fail the pipeline
- The failure message SHALL be actionable: "MentorKit v3 instalado, v5 disponible. Corre `bash <(curl ...)` para actualizar."
- The failure SHALL be one-command-fixable (no manual merge work)

---

## Contexto

El diseño completo de esta feature (lifecycle de la constitución en 5
fases, drift detection vs. conflict resolution, distribution model
A+B+D, risks + mitigations, dependencias, open questions) vive en
`research.md` en este mismo directorio. Este `spec.md` se enfoca
exclusivamente en los acceptance criteria formales que el CI puede
verificar.
