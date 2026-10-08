# MentorKit — Claude Code Compatibility

The canonical project-wide agent contract is `AGENTS.md`.

Read and follow `AGENTS.md` before implementing changes. It defines MentorKit's Organic Driven Development (ODD) workflow, authorization boundaries, SMALL/SUBSTANTIAL classification, durable task tracking, verification, and delivery rules.

Do not create a separate Claude-specific development methodology. Claude Code is an execution surface for the same MentorKit ODD contract.

For Claude-specific reusable capabilities, use `.claude/skills/` as an adapter layer pointing to the canonical MentorKit workflow.
