# MentorKit — GitHub Copilot in Visual Studio Code

Follow the repository-level contract in `AGENTS.md` and the canonical methodology in `odd/CONTRACT.md`. This file is a VS Code Copilot discovery adapter, not a second workflow.

- Treat requests to analyze, explain, review, or plan as read-only unless implementation is explicitly authorized.
- Explore the relevant code and resolve material uncertainty before classifying work.
- Apply ODD proportionally: SMALL for localized low-risk changes; SUBSTANTIAL for cross-cutting, multi-unit, architectural, or high-risk work.
- For SUBSTANTIAL work, create and maintain `odd/tasks/<feature>.md` before the first source-code write.
- A finding is not authorization. A plan is not authorization to implement.
- Preserve confirmed project architecture, policies, conventions, and existing patterns.
- Verify using the repository's actual checks before claiming completion.
- Push, pull request, merge, and deployment remain separate delivery decisions.

Use the native `MentorKit` custom agent and the `mentorkit` skill when they are available. The ODD contract remains authoritative if any editor-specific instruction conflicts with it.
