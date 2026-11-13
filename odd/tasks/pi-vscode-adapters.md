# Pi and VS Code Native Adapter Support

## Objective

Extend MentorKit from four supported agent runtimes to six by adding first-class support for Pi Coding Agent and Visual Studio Code's GitHub Copilot agent harness, while preserving one runtime-neutral ODD contract and existing installations.

The target is not a second implementation of MentorKit. Native integrations must adapt the existing `AGENTS.md`, `odd/` contracts, and reusable MentorKit skills.

## Specs

- **S1 — Single ODD semantics:** Pi and VS Code consume the canonical `AGENTS.md` and `odd/CONTRACT.md`; no adapter may redefine authorization, SMALL/SUBSTANTIAL classification, durable tracking, verification, or delivery boundaries.
- **S2 — Pi native discovery:** Pi discovers MentorKit through its native project instruction and Agent Skills mechanisms. Reuse `.agents/skills/mentorkit/` where supported; do not create a second copy of the workflow.
- **S3 — VS Code native discovery:** GitHub Copilot in VS Code receives repository instructions and a selectable MentorKit custom agent, plus discoverable skills in the native workspace location.
- **S4 — Shared capability parity:** Both adapters expose the same core ODD workflow and relevant project skills; optional capabilities remain optional and must degrade gracefully.
- **S5 — Safe installation:** Existing user files and editor settings are preserved. Installation is idempotent, reports conflicts, and never silently overwrites malformed or user-owned configuration.
- **S6 — MCP compatibility:** Any codebase-memory MCP integration added for Pi/VS Code uses native configuration formats, merges only the MentorKit server entry, validates output, and is covered by tests. MCP remains optional.
- **S7 — Cross-platform:** Installation and verification continue to work on Linux, macOS, and Windows, including paths with spaces and platform-specific configuration locations.
- **S8 — Documentation and CI:** README, architecture, installer inventory, verification, and platform smoke tests accurately list all six runtimes and distinguish supported native integrations from unverified capabilities.

## Tasks

- [x] **T1 — Inspect and map native runtime contracts.** Confirm current Pi project instruction, skill, prompt/extension, and MCP discovery; confirm VS Code Copilot instruction, skill, custom-agent, and MCP discovery. Record exact supported locations and version caveats from official documentation.
- [x] **T2 — Design adapter boundaries.** Define the minimum native Pi and VS Code artifacts, canonical skill source, optional capabilities, and compatibility/degradation behavior.
- [x] **T3 — Implement Pi adapter.** Add native project integration using the existing shared ODD contract and reusable skills. Add optional runtime-specific commands/extensions only where they provide real value beyond the shared skill.
- [x] **T4 — Implement VS Code adapter.** Add Copilot workspace instructions and a native custom agent. Publish MentorKit skill(s) in the supported workspace skill location without introducing semantic drift or unmanaged duplicate sources.
- [ ] **T5 — Extend installer/runtime.** Include new artifacts in POSIX and PowerShell bootstraps, add safe/idempotent handling and optional MCP configuration for the new clients if supported by their current configuration contracts.
- [ ] **T6 — Extend verification.** Verify artifact presence, frontmatter/metadata, shared contract references, JSON/TOML validity where applicable, and MCP configuration/handshake where configured.
- [ ] **T7 — Add regression tests and CI coverage.** Cover fresh install, repeat install, pre-existing editor configuration, malformed configuration, skip-MCP mode, Windows paths, and all supported runtimes.
- [x] **T8 — Update documentation.** Update README, runtime architecture, compatibility matrix, install inventory, troubleshooting, and local validation scenarios. Keep claims aligned with tested behavior.
- [ ] **T9 — Final review.** Run applicable tests and platform smoke checks, inspect the complete diff, reconcile this task document, and record evidence and remaining limitations.

## Verification

- Existing test suite remains green.
- Fresh and repeated installation produce the same expected adapter files without damaging user configuration.
- Pi recognizes the MentorKit skill and loads `AGENTS.md` from a trusted project.
- VS Code Copilot lists the MentorKit custom agent and discovers the intended skills/instructions.
- ODD behavior is semantically consistent across all six runtimes for SMALL, SUBSTANTIAL, read-only requests, scope changes, resume, and delivery authorization.
- MCP configuration is optional, parseable, non-destructive, and verified when enabled.
- Linux, macOS, and Windows CI jobs pass.

## Log

- 2026-11-12 — Created from `feature/odd-migration` at base commit `08fcbd49df184168b9a67fa997c3399b93c5a1dc`.
- 2026-11-12 — T1/T2 completed: verified Pi's official discovery of `AGENTS.md`, `.agents/skills/`, and `.pi/mcp.json`; verified VS Code Copilot's `.github/copilot-instructions.md`, `.github/agents/*.agent.md`, and `.github/skills/`.
- 2026-11-12 — T3/T4 initial native adapters added. Pi reuses the existing portable Agent Skill (no duplicated workflow); VS Code gets a native custom agent, workspace instructions, and a Copilot skill.
- 2026-11-12 — POSIX and PowerShell bootstraps now install `.pi/` and only the Copilot customization paths under `.github/` (not repository workflows). Platform smoke workflow includes checks for adapter artifacts.
- 2026-11-12 — T8 completed: root README and runtime guide document the native integrations and explicitly disclose the MCP/validation gaps.
- 2026-11-12 — The context-aware installer is tracked separately in [context-aware-installer.md](context-aware-installer.md); native adapters are now installed only when selected.
- 2026-11-12 — T5 partially completed: POSIX and PowerShell bootstraps install the native adapter artifacts safely (the VS Code `.github` copy is intentionally selective). Pi/VS Code codebase-memory MCP configuration is still pending.
- 2026-11-12 — T6/T7 partially completed: CI now checks that native artifacts are installed and reference the shared contract, but it does not yet launch Pi or VS Code to test discovery or exercise MCP. No workflow run was returned for the current head.

## Delivery

- Base: `feature/odd-migration`
- Working branch: `feature/agent-adapters-pi-vscode`
- Pull request: not created
- Merge: not authorized
- Current state: native adapter scaffolding and bootstrap integration committed; MCP parity and functional runtime validation remain open
