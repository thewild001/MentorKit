# Config — Dual-Path Spec Resolution

## Purpose

The `openspec/config.yaml` SHALL declare the dual-path resolution strategy between `.specify/` (primary) and `openspec/` (secondary) stores. This ensures all tools and skills resolve spec paths consistently.

## Requirements

### Requirement: CFG-001 — Dual-path mode declaration

The `context` field in `openspec/config.yaml` MUST explicitly state that MentorKit operates in dual-path mode, identifying `.specify/` as the primary spec store and `openspec/` as the secondary mirror.

#### Scenario: Config declares dual-path

- GIVEN the project uses OpenSpec
- WHEN a tool reads `openspec/config.yaml`
- THEN the `context` field SHALL mention `.specify/` as primary store
- AND the `context` SHALL mention `openspec/` as secondary mirror
- AND the `context` SHALL declare the read path preference: `.specify/` first, fallback to `openspec/`

### Requirement: CFG-002 — Archive rules prefer .specify/ convention

The `rules.archive` section MUST prefer the existing `.specify/` convention for spec storage and archival, treating `openspec/` as a secondary mirror.

#### Scenario: Archive rules documented

- GIVEN a developer reviews `config.yaml`'s archive rules
- WHEN the archive phase runs
- THEN the primary archive target SHALL remain `.specify/`
- AND the rules SHALL mention that `openspec/` receives mirrored writes

### Requirement: CFG-003 — Write path documented

Config SHALL document the dual-write strategy: all spec writes go to `.specify/` first, then mirror to `openspec/`.

#### Scenario: Write path resolution

- GIVEN a skill writes a spec file
- WHEN it checks config.yaml for path rules
- THEN the config SHOULD specify the write order (`.specify/` then `openspec/`)
- AND the config MAY document that mirror failures MUST NOT block the primary write

### Requirement: CFG-004 — CI verification rules

Config.yaml `rules.verify` SHOULD include a note that CI verification checks both stores and warns on desync.

#### Scenario: CI rules in config

- GIVEN CI is configured via `.gitlab-ci.yml`
- WHEN `rules.verify` is present in config.yaml
- THEN it SHOULD reference that CI verifies both `.specify/` and `openspec/` on desync

### Requirement: CFG-005 — Existing content preservation

The dual-path integration MUST NOT modify or remove any existing `.specify/` content. Config MUST document this invariant.

#### Scenario: Existing content untouched

- GIVEN `.specify/` contains archived specs and `system-spec.md`
- WHEN the dual-path mode is enabled
- THEN all existing `.specify/` content SHALL remain unmodified
- AND no migration SHALL be required
