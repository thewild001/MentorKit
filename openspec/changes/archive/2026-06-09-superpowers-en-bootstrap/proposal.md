# Proposal: Superpowers en Bootstrap

## Intent

14 superpower skills (46 files, ~8.4K lines) live only in the user's global
`~/.config/opencode/skills/superpowers/`. The MentorKit installer downloads
files from GitLab — but superpowers aren't in the repo, so fresh installs
get an incomplete agent config (MentorKit4.0 already references
`using-superpowers` but can't load it). Bundling them makes the installer
self-contained and the superpowers available on first run.

## Scope

### In Scope
- Copy all 14 superpower directories into `.opencode/skills/superpowers/`
- Allow all 14 skill names in `MentorKit4.0.md` `permission.skill`
- Add all 46 superpower file paths to `install-mentorkit.sh` `FILES` array
- Update `README.md` — document local bundling, remove global-path assumptions
- Verify `Makefile` tips resolve with `opencode run skill` (already pathless)

### Out of Scope
- Modifying superpower SKILL.md content, logic, or dependencies
- Adding/removing superpower skills
- Changing the installer download mechanism (still per-file via FILES array)
- Registering superpowers in the SDD skill registry

## Capabilities

### New Capabilities
- `superpowers-bootstrap`: The installer fetches superpower files so they
  exist in `.opencode/skills/superpowers/` after `make install`.

### Modified Capabilities
- None — existing skill specs are unchanged; this is a packaging/infrastructure change.

## Approach

1. **Copy**: `cp -r` each superpower from `~/.config/opencode/skills/superpowers/<name>/`
   to `.opencode/skills/superpowers/<name>/` in the repo.
2. **Agent config**: Add 14 `"<skill-name>": allow` lines to
   `permission.skill` block in `MentorKit4.0.md`.
3. **Installer**: Add 46 file paths to `FILES` array in
   `install-mentorkit.sh`. Group under a `# Superpowers` comment.
4. **README**: Update the "Skills Superpower" section to reflect that
   superpowers are now bundled locally (no global path needed).
5. **Verify**: Run `make help` and confirm tips still print.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `.opencode/skills/superpowers/` | New (46 files) | 14 skill dirs copied from global config |
| `.opencode/agents/MentorKit4.0.md` | Modified | +14 skill allows in `permission.skill` |
| `.opencode/install-mentorkit.sh` | Modified | +46 paths to `FILES` array |
| `README.md` | Modified | Document local superpowers bundling |
| `Makefile` | Verified | Tips use pathless `opencode run skill` — should resolve fine |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| FILES array gets unwieldy (46 new entries) | High — expected | Group under comment header; consider future switch to dir-batch download |
| Superpower skills drift from upstream global copies | Medium | Document that `.opencode/` copy is the canonical repo version; sync manually |
| `opencode run skill` may not find skills in `.opencode/skills/superpowers/` | Low | CC resolves `skill()` by name via `permission.skill` + registry; path is automatic |
| Makefile tips reference `work-unit-commits` which isn't a superpower but a separate skill | Low | Verify during implementation — it's not in the 14 superpowers |

## Rollback Plan

- Git revert the commit that adds superpowers/ dir, agent config, and installer changes.
- Existing installs are unaffected (they don't have superpowers yet).
- Revert README changes.

## Dependencies

- Source superpower skills at `~/.config/opencode/skills/superpowers/` (read-only, stable)
- No runtime dependencies — pure file-copy + config update

## Success Criteria

- [ ] `make install` on a fresh project fetches all 46 superpower files
- [ ] `MentorKit4.0.md` lists all 14 superpowers in `permission.skill: allow`
- [ ] `ls .opencode/skills/superpowers/` shows all 14 directories with expected files
- [ ] `make help` prints superpower tips with no errors
- [ ] `grep -r '\.config.*superpower' README.md` returns nothing
