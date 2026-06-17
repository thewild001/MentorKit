# Tasks: Superpowers en Bootstrap

> **Derived from**: `openspec/changes/superpowers-en-bootstrap/proposal.md`
> **Change**: Bundle 14 superpower skills (47 files, ~11.4K lines) into the MentorKit repo
> **Source**: `~/.config/opencode/skills/superpowers/` → **Target**: `.opencode/skills/superpowers/`

---

## ⚠️ Discrepancies detected vs proposal

The proposal states **46 files / ~8.4K lines** — actual source has **47 files / ~11,376 lines**:

| Skill | Proposal stated | Actual files | Delta |
|---|---|---|---|
| brainstorming | 7 files | **8 files** | +1 (extra `spec-document-reviewer-prompt.md`; scripts differ in name) |
| systematic-debugging | 2 files | **11 files** | +9 (extra: `CREATION-LOG.md`, `defense-in-depth.md`, `test-*.md`, `condition-based-waiting*`, `find-polluter.sh`) |
| Others | matches | matches | — |

Updated file list in Task 3 accounts for actual source.

---

## Task Dependency Graph

```
[1. Copy files] ───→ ┌─ [2. Agent config] ─┐
                     ├─ [3. Installer] ─────┤──→ [5. Verify]
                     └─ [4. README] ────────┘
```

Tasks 2, 3, 4 can execute in parallel after Task 1 completes.

---

## Task 1 — Copy superpower files into repo

**ID**: `task-01-copy-files`
**Effort**: Small (~2 minutes)
**Changed lines**: ~11,376 new lines (47 new files)
**Dependencies**: None (source files at `~/.config/opencode/skills/superpowers/` are stable)

### Pre-conditions
- Source directory `~/.config/opencode/skills/superpowers/` exists with all 14 skill subdirectories
- Target root `.opencode/skills/superpowers/` does NOT yet exist
- Current branch has no uncommitted changes (clean working tree)

### Steps
1. Create target directory: `mkdir -p .opencode/skills/superpowers/`
2. Copy each skill directory:
   ```bash
   for dir in ~/.config/opencode/skills/superpowers/*/; do
     name=$(basename "$dir")
     cp -r "$dir" ".opencode/skills/superpowers/$name/"
   done
   ```
3. Verify count:
   ```bash
   # Should report 14
   ls -d .opencode/skills/superpowers/*/ | wc -l
   # Should report 47
   find .opencode/skills/superpowers/ -type f | wc -l
   ```

### Post-conditions
- `ls .opencode/skills/superpowers/*/SKILL.md` returns 14 lines
- Each subdirectory has the same file listing as its source counterpart
- `.gitignore` does NOT ignore `.opencode/skills/superpowers/` (it's tracked content)

---

## Task 2 — Update agent config (MentorKit4.0.md)

**ID**: `task-02-agent-config`
**Effort**: Trivial (~1 minute)
**Changed lines**: +13 lines (insert 13 skill names into `permission.skill` block)
**Dependencies**: Task 1 (needs skill names confirmed from copy)

### Pre-conditions
- Task 1 completed (or at least the skill names are known)
- `.opencode/agents/MentorKit4.0.md` is readable

### Changes
Current `permission.skill` block (7 entries):

```yaml
  skill:
    "codebase-conformist": allow
    "spec-writer": allow
    "prd-reader": allow
    "document-extractor": allow
    "llm-council": allow
    "codebase-graph": allow
    "using-superpowers": allow      # ← already present
```

Add these 13 superpower names (alphabetically, after `codebase-graph`):

```yaml
    "brainstorming": allow
    "dispatching-parallel-agents": allow
    "executing-plans": allow
    "finishing-a-development-branch": allow
    "receiving-code-review": allow
    "requesting-code-review": allow
    "subagent-driven-development": allow
    "systematic-debugging": allow
    "test-driven-development": allow
    "using-git-worktrees": allow
    "verification-before-completion": allow
    "writing-plans": allow
    "writing-skills": allow
```

### Verification
```bash
# Count "allow" entries under skill: — should be 20 (7 existing + 13 new)
grep -c '": allow"' .opencode/agents/MentorKit4.0.md
# Count superpower-specific entries — should be 14
grep -E '"(brainstorming|dispatching-parallel-agents|executing-plans|finishing-a-development-branch|receiving-code-review|requesting-code-review|subagent-driven-development|systematic-debugging|test-driven-development|using-git-worktrees|using-superpowers|verification-before-completion|writing-plans|writing-skills)": allow' .opencode/agents/MentorKit4.0.md | wc -l
```

### Post-conditions
- `MentorKit4.0.md` YAML frontmatter is valid (no indentation errors)
- All 14 superpower names are listed in `permission.skill`
- `opencode run skill <any-superpower>` resolves from this project

---

## Task 3 — Update installer (install-mentorkit.sh)

**ID**: `task-03-installer`
**Effort**: Medium (~5 minutes, careful with paths)
**Changed lines**: +47 new paths + 1 comment header to `FILES` array
**Dependencies**: Task 1 (needs actual file list)

### Pre-conditions
- Task 1 completed
- `.opencode/install-mentorkit.sh` is readable

### Changes

Add a `# ─── Superpowers ─────────────────────────────────────────────────` comment before the superpower entries, then insert all 47 paths into the `FILES` array.

The updated array will look like:

```bash
FILES=(
    ".opencode/skills/codebase-conformist/SKILL.md"
    ".opencode/skills/codebase-graph/SKILL.md"
    ".opencode/skills/spec-writer/SKILL.md"
    ".opencode/skills/prd-reader/SKILL.md"
    ".opencode/skills/document-extractor/SKILL.md"
    ".opencode/skills/llm-council/SKILL.md"
    ".opencode/agents/MentorKit4.0.md"
    ".opencode/mentorkit-python.sh"
    ".opencode/mentorkit-verify.sh"
    ".opencode/requirements.in"
    ".opencode/requirements.lock"

    # ─── Superpowers ─────────────────────────────────────────────────
    ".opencode/skills/superpowers/brainstorming/SKILL.md"
    ".opencode/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md"
    ".opencode/skills/superpowers/brainstorming/visual-companion.md"
    ".opencode/skills/superpowers/brainstorming/scripts/frame-template.html"
    ".opencode/skills/superpowers/brainstorming/scripts/helper.js"
    ".opencode/skills/superpowers/brainstorming/scripts/server.cjs"
    ".opencode/skills/superpowers/brainstorming/scripts/start-server.sh"
    ".opencode/skills/superpowers/brainstorming/scripts/stop-server.sh"
    ".opencode/skills/superpowers/dispatching-parallel-agents/SKILL.md"
    ".opencode/skills/superpowers/executing-plans/SKILL.md"
    ".opencode/skills/superpowers/finishing-a-development-branch/SKILL.md"
    ".opencode/skills/superpowers/receiving-code-review/SKILL.md"
    ".opencode/skills/superpowers/requesting-code-review/SKILL.md"
    ".opencode/skills/superpowers/requesting-code-review/code-reviewer.md"
    ".opencode/skills/superpowers/subagent-driven-development/SKILL.md"
    ".opencode/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md"
    ".opencode/skills/superpowers/subagent-driven-development/implementer-prompt.md"
    ".opencode/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md"
    ".opencode/skills/superpowers/systematic-debugging/SKILL.md"
    ".opencode/skills/superpowers/systematic-debugging/root-cause-tracing.md"
    ".opencode/skills/superpowers/systematic-debugging/CREATION-LOG.md"
    ".opencode/skills/superpowers/systematic-debugging/defense-in-depth.md"
    ".opencode/skills/superpowers/systematic-debugging/condition-based-waiting.md"
    ".opencode/skills/superpowers/systematic-debugging/condition-based-waiting-example.ts"
    ".opencode/skills/superpowers/systematic-debugging/test-academic.md"
    ".opencode/skills/superpowers/systematic-debugging/test-pressure-1.md"
    ".opencode/skills/superpowers/systematic-debugging/test-pressure-2.md"
    ".opencode/skills/superpowers/systematic-debugging/test-pressure-3.md"
    ".opencode/skills/superpowers/systematic-debugging/find-polluter.sh"
    ".opencode/skills/superpowers/test-driven-development/SKILL.md"
    ".opencode/skills/superpowers/test-driven-development/testing-anti-patterns.md"
    ".opencode/skills/superpowers/using-git-worktrees/SKILL.md"
    ".opencode/skills/superpowers/using-superpowers/SKILL.md"
    ".opencode/skills/superpowers/using-superpowers/references/copilot-tools.md"
    ".opencode/skills/superpowers/using-superpowers/references/codex-tools.md"
    ".opencode/skills/superpowers/using-superpowers/references/gemini-tools.md"
    ".opencode/skills/superpowers/verification-before-completion/SKILL.md"
    ".opencode/skills/superpowers/writing-plans/SKILL.md"
    ".opencode/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md"
    ".opencode/skills/superpowers/writing-skills/SKILL.md"
    ".opencode/skills/superpowers/writing-skills/anthropic-best-practices.md"
    ".opencode/skills/superpowers/writing-skills/testing-skills-with-subagents.md"
    ".opencode/skills/superpowers/writing-skills/persuasion-principles.md"
    ".opencode/skills/superpowers/writing-skills/render-graphs.js"
    ".opencode/skills/superpowers/writing-skills/graphviz-conventions.dot"
    ".opencode/skills/superpowers/writing-skills/examples/CLAUDE_MD_TESTING.md"
)
```

### Verification
```bash
# Count paths — should be 58 (11 existing + 47 superpowers)
grep -c '".opencode/' .opencode/install-mentorkit.sh
# Check comment header exists
grep 'Superpowers' .opencode/install-mentorkit.sh
```

### Post-conditions
- `FILES` array has 58 entries total (11 existing + 47 superpowers)
- Superpower entries are grouped under `# ─── Superpowers ─────────────────────────────` comment
- All paths use Unix forward slashes (verify no backslashes)
- `bash -n .opencode/install-mentorkit.sh` passes syntax check

---

## Task 4 — Update README.md

**ID**: `task-04-readme`
**Effort**: Trivial (~1 minute)
**Changed lines**: ~15 (localize path references in "Skills Superpower" section)
**Dependencies**: Task 1

### Pre-conditions
- `README.md` is readable

### Changes

The "Skills Superpower" section (lines 102–117) currently documents superpowers
as a feature. The section is already accurate about *usage* — no changes needed
to how tips/integration are described.

Changes needed:
1. **Line 123** — Update `.opencode/skills/` description: change "8 skills" to "22 skills"
   (8 core + 14 superpowers):
   ```
   - **`.opencode/skills/`** — 22 skills especializados (8 core + 14 superpowers)
   ```
2. **Remove global-path assumptions** — check if any text references
   `~/.config/opencode/skills/superpowers/` as an external dependency.
   Current README has none (superpowers are described as integrated, not by path),
   so this may be a no-op verification only.

### Verification
```bash
# Must return empty (no references to global config path)
grep -r '\.config.*superpower' README.md || echo "CLEAN — no global paths"
```

### Post-conditions
- `README.md` accurately reflects that superpowers are bundled in `.opencode/skills/superpowers/`
- No references to `~/.config/opencode/skills/superpowers/` exist in the file
- The skill count in the "¿Qué contiene el repo?" section is updated

---

## Task 5 — Verify Makefile tips

**ID**: `task-05-verify-makefile`
**Effort**: Trivial (~1 minute)
**Changed lines**: 0 (verification only)
**Dependencies**: Tasks 1–4

### Pre-conditions
- Tasks 1, 2, 3, 4 completed

### Verification steps

1. **Run `make help`** and confirm superpower tips print:
   ```
   💡 Tips de uso con Skills Superpower:
     - Antes de especificar: opencode run skill brainstorming
     - Antes de implementar: opencode run skill verification-before-completion
     - Durante desarrollo: opencode run skill using-git-worktrees
     - En PRs: opencode run skill work-unit-commits
   ```

2. **Check `work-unit-commits` reference** — this is NOT one of the 14 superpowers
   (it's a separate skill at `~/.config/opencode/skills/work-unit-commits/`).
   It does NOT need to be in the superpowers directory, but:
   - If the user has `work-unit-commits` in their global config, `opencode run skill`
     will find it there. No change needed.
   - If we want it bundled too, that would be a scope creep (proposal says out of scope).

   **Recommendation**: Leave as-is. The tip references a skill that may or may not exist
   in the user's global config — same behavior as before.

3. **Verify `opencode run skill` command format**: The Makefile uses
   `opencode run skill <name>` (not a file path), so it will resolve via the agent's
   `permission.skill` + OpenCode skill registry. No file-path dependency.

### Post-conditions
- `make help` exits 0 and prints all 4 tips
- No changes to `Makefile` needed

---

## Summary

| # | Task | Files changed | Lines changed | Risk | Effort |
|---|------|--------------|---------------|------|--------|
| 1 | Copy files | +47 new | +11,376 | Low (bulk copy) | 2 min |
| 2 | Agent config | 1 modified | +13 | Low | 1 min |
| 3 | Installer | 1 modified | +48 (47 paths + 1 comment) | Medium (typo risk on 47 paths) | 5 min |
| 4 | README | 1 modified | ~15 | Low | 1 min |
| 5 | Verify | 0 | 0 | Low | 1 min |

---

## Review Workload Forecast

| Metric | Value |
|--------|-------|
| **Total files changed** | 49 (47 new + 2 modified) |
| **Total lines added** | ~11,452 |
| **Lines of structural change** | ~76 (agent config + installer + README) |
| **Lines of bulk copy** | ~11,376 (skill content — no logic review needed) |
| **Review complexity** | Low — bulk is verbatim copy from global config |

### Chained PR Recommendation

**Recommendation: Single PR.**

Rationale:
- ~11,376 of ~11,452 lines are verbatim file copies from global config — they
  require minimal review (spot-check that copy was faithful + file count matches).
- Splitting 47 new files into multiple PRs adds management overhead without
  meaningful review benefit.
- The structural changes (agent config + installer + README) are only ~76 lines —
  too small to justify a separate PR.

However, if the reviewer wants to split, the natural boundary is:
- **PR 1**: Copy files + agent config (Task 1 + 2) — the "availability" change
- **PR 2**: Installer + README (Task 3 + 4) — the "distribution" change
- **PR 3**: Verify (Task 5) — standalone verification

### Rollback
Single `git revert` of the merge commit restores the previous state.
