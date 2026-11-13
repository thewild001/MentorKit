# MentorKit for Pi

Pi Coding Agent is supported through its native project customization mechanisms; a separate MentorKit runtime or fork of ODD is not required.

## Native discovery

- **Project instructions:** Pi loads `AGENTS.md` from the current directory and parent directories. MentorKit's root `AGENTS.md` points to the canonical ODD contract.
- **Skills:** Pi implements Agent Skills and discovers project skills in `.agents/skills/`. The existing `.agents/skills/mentorkit/SKILL.md` is the canonical portable entry point; do not duplicate it under `.pi/skills/`.
- **Durable state:** ODD tasks remain in `odd/tasks/`, independent of Pi sessions, compaction, or model provider.
- **Extensions and prompts:** No custom Pi extension or prompt is required for core ODD behavior. Add one only for a verified Pi-specific capability that cannot be expressed by the shared skill.

## Setup

1. Install Pi Coding Agent using the official Pi instructions.
2. Open the repository root in Pi.
3. Trust the project when prompted so project skills can be loaded.
4. Confirm that the `mentorkit` skill is discoverable and that `AGENTS.md` is included in project context.
5. Ask Pi to classify a representative task as SMALL or SUBSTANTIAL and verify that it follows `odd/CONTRACT.md`.

Pi's native MCP configuration is separate from MentorKit's existing four-client `codebase-memory-mcp` installer. Until a dedicated Pi MCP adapter is implemented and tested, use MentorKit without that optional MCP capability; codebase understanding must fall back to Graphify or direct repository inspection.

Official references:
- https://pi.dev/docs/latest/skills
- https://pi.dev/docs/latest/extensions
- https://pi.dev/
