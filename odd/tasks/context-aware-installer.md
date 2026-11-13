# Context-aware MentorKit Installer

## Objective

Allow users to select one or more agent contexts during installation: Claude Code, OpenCode, Codex, Cursor, Pi, and VS Code Copilot. Install the shared ODD core once and copy only the selected native adapters and their runtime dependencies.

## Specs

- **S1 — Interactive selection:** POSIX and PowerShell bootstraps present the six contexts and support multi-selection plus an all option.
- **S2 — Automation:** `MENTORKIT_CONTEXTS` accepts comma-separated names and `all`; a non-interactive invocation without the variable preserves backward compatibility by installing all contexts.
- **S3 — Shared core:** Install `odd/`, `.mentor/`, `AGENTS.md`, and a machine-readable `.mentorkit/install.json` manifest for every selection.
- **S4 — Selective adapters:** Install only selected context artifacts. Install `.opencode/`, its Python/uv runtime, and root `Makefile` only when OpenCode is selected.
- **S5 — Scoped MCP:** When OpenCode is selected, configure codebase-memory only for selected clients currently supported by the MCP installer (Claude, Codex, OpenCode, Cursor). Do not claim Pi/VS Code MCP support until their native adapters exist.
- **S6 — Cross-platform parity:** Bash and PowerShell accept the same context names and aliases, validate empty/unknown selections, and persist the same manifest shape.
- **S7 — Regression coverage:** CI tests each single-context installation and asserts selected artifacts exist while unselected adapter artifacts are absent.
- **S8 — Documentation:** README describes interactive selection, automation variables, shared vs adapter-specific files, and current MCP limitations.

## Tasks

- [x] **T1 — Define context map and installation boundaries.**
- [x] **T2 — Implement Bash context selection and selective file installation.**
- [x] **T3 — Implement PowerShell context selection and selective file installation.**
- [x] **T4 — Scope OpenCode runtime, Makefile, and MCP client configuration to selected contexts.**
- [x] **T5 — Persist selected contexts in `.mentorkit/install.json`.**
- [x] **T6 — Update README installation instructions and environment variable reference.**
- [x] **T7 — Add per-context CI smoke coverage.**
- [x] **T8 — Execute CI on Linux, macOS, and Windows and resolve failures.**
- [ ] **T9 — Validate interactive menu behavior manually in Bash and PowerShell.**

## Verification

- Each of the six single-context CI matrix entries installs the shared core and exactly its selected adapter.
- Non-OpenCode selections do not install `.opencode/`, Python 3.12, uv, or the OpenCode Makefile.
- OpenCode selection configures MCP only for selected supported clients.
- The manifest records the normalized selected context names and source branch.
- Existing all-context platform smoke tests remain green.

## Log

- 2026-11-12 — Added interactive multi-selection to `bootstrap.sh` and `bootstrap.ps1`.
- 2026-11-12 — Added `MENTORKIT_CONTEXTS` for scripted installs; non-interactive default remains `all` to preserve existing CI and one-liner behavior.
- 2026-11-12 — Selective copy rules: common ODD core is always installed; each native adapter is conditional; OpenCode runtime, Makefile, and MCP bootstrap are installed only with OpenCode.
- 2026-11-12 — Added `.mentorkit/install.json` and six-context CI matrix checks.
- 2026-11-12 — MCP for Pi and VS Code remains explicitly unsupported in this iteration; no false parity claim is made.
- 2026-11-13 — CI evidence: all six isolated context-selection jobs passed on Ubuntu; the Windows selective PowerShell scenario (Claude + Codex + Pi) passed; the full Linux, macOS, and Windows platform jobs also passed. Workflow: https://github.com/thewild001/MentorKit/actions/runs/43368185434 (all 10 jobs green at commit `712fbb8e`; the subsequent commit only updates this task log).

## Delivery

- Base: `feature/agent-adapters-pi-vscode`
- Working branch: `feature/agent-adapters-pi-vscode`
- Pull request: not created
- Merge: not authorized
- Status: implementation committed; CI and manual interactive validation pending
