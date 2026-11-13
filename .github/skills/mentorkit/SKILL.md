---
name: mentorkit
description: Apply MentorKit's Organic Driven Development workflow proportionally to software engineering changes in this repository.
---

# MentorKit ODD

The canonical runtime-neutral contract is `odd/CONTRACT.md`; `AGENTS.md` is the repository-level agent contract.

Use ODD proportionally:

1. AUTHORIZE — distinguish read-only intent from explicit change authorization.
2. EXPLORE — inspect relevant architecture, patterns, tests, policies, and repository state.
3. UNCERTAINTY — resolve material unknowns before writing.
4. CLASSIFY — choose SMALL or SUBSTANTIAL based on complexity and risk.
5. TRACK — for SUBSTANTIAL work, create and maintain `odd/tasks/<feature>.md`.
6. IMPLEMENT — change only the authorized scope.
7. VERIFY — run applicable project checks and preserve evidence.
8. COMMIT — create reviewable work-unit commits when appropriate; do not infer permission to push.
9. CLOSE — report status, verification, and remaining risks.

A finding is not authorization. A plan is not authorization to implement. Never redefine the canonical ODD semantics in this skill.
