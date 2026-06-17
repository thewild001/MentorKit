# Tasks: OpenSpec Dual-Path Integration

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~195 (range: 175–220) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | All 12 tasks in dependency order | PR 1 (single) | All changes are tightly coupled — splitting would create half-working states |

---

## Phase 1 — Foundation (config + directory)

- [x] **1.1** `openspec/config.yaml` — Add archive rule: `dual_path: true` under `rules.archive` section. Add `- Mirror writes to openspec/specs/` entry. Risk: **Low** ~3 lines. No deps.
- [x] **1.2** `openspec/changes/` — Ensure `archive/` subdirectory exists for spec archives in openspec path. `openspec/specs/` already exists (empty). Risk: **Low** ~0 lines (mkdir). No deps.

---

## Phase 2 — Skill updates (code changes in skill files)

- [x] **2.1** `.opencode/skills/codebase-conformist/SKILL.md` — Added `openspec/` fallback for constitution read, spec Glob, research dual-write, plan PR description. 8 openspec references. Risk: **Low** ~12 lines. Depends on: 1.1.

- [x] **2.2** `.opencode/skills/spec-writer/SKILL.md` — Added dual-write: primary to `.specify/`, mirror to `openspec/` with try/except. Constitution and system-spec reads have openspec fallback. 7 openspec references. Risk: **Low** ~8 lines. Depends on: 1.1.

- [x] **2.3** `.opencode/skills/prd-reader/SKILL.md` — Added dual-write for spec output. Constitution and system-spec reads have openspec fallback. 7 openspec references. Risk: **Low** ~8 lines. Depends on: 1.1.

- [x] **2.4** `.opencode/skills/llm-council/SKILL.md` — Added openspec fallback for Modo B context loading. Council transcript saved to openspec/council/. 2 openspec references. Risk: **Low** ~5 lines. Depends on: 1.1.

---

## Phase 3 — Orchestrator + Scripts

- [x] **3.1** `.opencode/agents/MentorKit4.0.md` — Added openspec fallback for constitution Glob, openspec spec-reading mention. New "Estructura openspec/" documentation section. Risk: **Low** ~26 lines. Depends on: 2.1.

- [x] **3.2** `.opencode/mentorkit-archive-spec.sh` — Added `--target specify|openspec|both` flag:
  - `specify`: default, operates on `.specify/`
  - `openspec`: operates on `openspec/` (changes SYSTEM_SPEC, ARCHIVE_DIR, path references)
  - `both`: archives to `.specify/` + mirrors system-spec.md and archived specs to `openspec/`
  - Updated `--help` output
  Risk: **Medium** ~50 lines. Depends on: 1.1, 2.2.

- [x] **3.3** `.opencode/mentorkit-verify.sh` — Added OpenSpec mirror integrity check: compares `.specify/` vs `openspec/` for constitution and specs. Warns on desync, does NOT fail. Risk: **Low** ~30 lines. Depends on: 1.1.

- [x] **3.4** `.opencode/mentorkit-init-constitution.sh` — Added openspec auto-detection: when `openspec/` exists, appends mirror note to constitution. Updated `--help` output. Risk: **Low** ~5 lines. Depends on: 1.1.

---

## Phase 4 — CI + Make

- [x] **4.1** `Makefile` — Added `sync-openspec` target (mirrors `.specify/` → `openspec/`). Extended `archive-spec` with TARGET variable forwarding. Risk: **Low** ~25 lines. Depends on: 3.3.

- [x] **4.2** `.gitlab-ci.yml` — Added `verify-openspec` job in `verify` stage with `needs: []` (parallel). Checks both stores for sync. Warns on desync, exits 0. Risk: **Low** ~53 lines. Depends on: 4.1.

---

## Implementation Order

1. **Phase 1** first — config + directories are prerequisites for everything else.
2. **Phase 2** — skill files can be updated in any order; they all depend only on Phase 1.
3. **Phase 3** — scripts depend on Phase 1 (config shape) and Phase 2 (skill output paths); they can be done after or in parallel with Phase 2.
4. **Phase 4** — CI + Make depend on Phase 3 scripts being finalized.

Total: 12 tasks across 12 files, ~195 estimated lines. Well under the 400-line budget.
