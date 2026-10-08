# MentorKit — Agent Contract

MentorKit is an agentic software-engineering workflow built on top of an AI coding agent. Its orchestration model is Organic Driven Development (ODD).

## Core rule

Use ODD proportionally to the requested change:

1. AUTHORIZE — determine what the user explicitly authorized.
2. EXPLORE — inspect only the context needed to act safely.
3. UNCERTAINTY — resolve material ambiguity; do not invent requirements.
4. CLASSIFY — SMALL or SUBSTANTIAL.
5. TRACK — for SUBSTANTIAL work, maintain `odd/tasks/<feature>.md`.
6. IMPLEMENT — execute the authorized work.
7. VERIFY — validate behavior and regressions.
8. COMMIT — create a reviewable work-unit commit when appropriate.
9. CLOSE — report what changed, verification, and remaining risks.

A finding is not authorization. Do not expand scope without authorization.

## SMALL vs SUBSTANTIAL

- SMALL: localized, low-risk change with no meaningful architectural or cross-cutting impact. Do not manufacture planning ceremony.
- SUBSTANTIAL: feature, migration, architectural change, cross-cutting refactor, risky behavior change, or work spanning multiple meaningful units. Persist the feature document in `odd/tasks/<feature>.md`.

## Durable state

For SUBSTANTIAL work, the feature document is the durable source of truth. Todo lists, chat context, agent memory, or temporary plans do not replace it.

Use the existing MentorKit skills and project documentation as needed. Do not require reading every document before every change.

## Verification

Follow the repository's actual build, test, lint, typecheck, and deployment commands. Verify before claiming completion.

## Compatibility contract

This file is intentionally agent-neutral. Cursor, Codex, Claude Code, and OpenCode should consume this contract directly or through their native compatibility mechanisms. Do not create a competing workflow with different semantics in an agent-specific file.

## Agent-specific integration

- Cursor: may additionally use `.cursor/rules/`.
- Codex: consumes `AGENTS.md` from repository root and nested directories.
- Claude Code: may use `CLAUDE.md` and `.claude/skills/`.
- OpenCode: consumes `AGENTS.md`, `CLAUDE.md`, `.opencode/skills/`, and `.opencode/agents/`.

Agent-specific files are adapters; ODD semantics live in this contract and `odd/`.
