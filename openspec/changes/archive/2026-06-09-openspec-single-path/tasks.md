# Tasks: openspec-single-path refactor

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~250 (additions + deletions) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (all 4 groups) |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: Yes
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Group 1 — Foundation (config, gitignore, migration, deletion)

- [ ] **1.1** `openspec/config.yaml` — Set `dual_path: true` → `false`; rewrite context lines 4-13 to reference `openspec/` as sole store (not `.specify/` as primary); remove rules.archive lines 41-45 referencing `.specify/` and dual_path mirror; remove rules.verify line 39 referencing `.specify/`.
- [ ] **1.2** `.gitignore` — Add `# OpenSpec legacy dual-path store\n.specify/` entry after line 21.
- [ ] **1.3** Migrate `.specify/` content → `openspec/` — Run `cp -a .specify/memory/constitution.md openspec/memory/constitution.md`, `cp -a .specify/memory/constitution.template.md openspec/memory/constitution.template.md`, `cp -a .specify/specs/000-auto-constitution/ openspec/specs/000-auto-constitution/`.
- [ ] **1.4** Delete `.specify/` directory — Run `rm -rf .specify/`.
- [ ] **1.5** Delete `sdd/openspec-dual-path/design.md` — Run `rm -rf sdd/openspec-dual-path/`.

## Group 2 — Build Automation (scripts + Makefile)

- [ ] **2.1** `.opencode/mentorkit-archive-spec.sh` — Remove `--target` flag parsing (lines 18-21 help text, ~12 lines flag parsing block), remove `TARGET_OPENSPEC` / `TARGET_BOTH` variables, change default `SYSTEM_SPEC` line 136 to `$REPO_ROOT/openspec/system-spec.md`, change `ARCHIVE_DIR` line 137 to `$REPO_ROOT/openspec/changes/archive`, remove Section 5 mirror block (lines ~542-569), remove mirror summary note line 575.
- [ ] **2.2** `.opencode/mentorkit-init-constitution.sh` — Change `TARGET` default line 61 from `.specify/memory/constitution.md` to `openspec/memory/constitution.md`; change `TEMPLATE_PATH` line 102 from `.specify/memory/constitution.template.md` to `openspec/memory/constitution.template.md`; update help text lines 4-6, 26.
- [ ] **2.3** `Makefile` — Remove `sync-openspec` target (lines 81-89); remove `TARGET` variable from archive-spec and init-constitution targets; update help text lines 10-11, 55-58 to reference `openspec/` paths; simplify `archive-spec` target to not pass `TARGET`.
- [ ] **2.4** `.opencode/mentorkit-verify.sh` — Remove OpenSpec mirror integrity check block (lines ~131-159, ~29 lines covering the mirror sync check between `.specify/` and `openspec/`).

## Group 3 — CI (depends on Group 2)

- [ ] **3.1** `.gitlab-ci.yml` — Remove job `verify-openspec` (lines ~357-407); replace `.specify/` paths in `verify-archive-spec` (lines 265, 286-296) with `openspec/` equivalents; replace `.specify/` paths in `verify-spec-history` (lines 317-347) with `openspec/`; update header comment line 19.

## Group 4 — Skills (parallel-safe within group, depends on Group 1 paths)

- [ ] **4.1** `.opencode/skills/codebase-conformist/SKILL.md` — Replace all `.specify/` paths (~8 sites): lines 42, 44, 83, 228, 229, 242, 410, 411 — change to `openspec/` equivalents; remove dual-path fallback comment on line 41 and 82; remove "or openspec/" fallback logic.
- [ ] **4.2** `.opencode/skills/spec-writer/SKILL.md` — Replace all `.specify/` paths (~7 sites): lines 42, 44, 50, 56, 58, 110, 113, 118, 119, 229 — change to `openspec/` equivalents; remove dual-path fallback comment on lines 41, 55; remove try/except mirror block (lines 111-115).
- [ ] **4.3** `.opencode/skills/prd-reader/SKILL.md` — Replace all `.specify/` paths (~11 sites): lines 9, 28, 48, 59, 61, 63, 65, 145, 150, 152, 204, 274, 275 — change to `openspec/` equivalents; remove dual-path fallback comment on lines 58, 149; remove mirror logic (lines 153-154).
- [ ] **4.4** `.opencode/skills/llm-council/SKILL.md` — Replace line 130 `.specify/` specs y constitution (preferir) → fallback `openspec/` with `openspec/` specs y constitution exclusively.
