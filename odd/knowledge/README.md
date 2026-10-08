# Codebase Knowledge

MentorKit preserves the original codebase-understanding layer as a first-class capability.

## Provider priority

```
codebase-memory-mcp
        ↓
     Graphify
        ↓
Fingerprinting + direct inspection
```

The first available provider is used, but the flow never blocks when an enhanced provider is missing.

## Consumers

Codebase knowledge feeds:

- ODD Explore;
- PRD Analysis → Implementation Plan;
- Constitution / Policy synthesis;
- Impact / blast radius analysis;
- Implementation conformity;
- Verification;
- Resume / handoff.

See:

- `odd/knowledge/CONTRACT.md`
- `.opencode/skills/codebase-graph/SKILL.md`
- `.opencode/skills/codebase-conformist/SKILL.md`

The existing `codebase-graph` skill remains the OpenCode adapter for codebase-memory-mcp + Graphify.
