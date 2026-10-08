# MentorKit ODD Core Contract

## Status

This document is the **runtime-neutral source of truth** for MentorKit's Organic Driven Development (ODD) semantics.

It is intentionally independent of OpenCode, Cursor, Codex, Claude Code, or any other agent runtime. Runtime-specific files may adapt these rules to native mechanisms, but must not redefine them.

## 1. Objective

ODD is a proportional engineering workflow.

Its purpose is not to maximize ceremony. Its purpose is to ensure that the amount of exploration, planning, persistence, verification, and delivery control is appropriate to the risk and complexity of the requested change.

The core principle is:

> The workflow adapts to the work; the work does not adapt to a rigid workflow.

## 2. Canonical lifecycle

Every change follows this conceptual lifecycle:

```
AUTHORIZE
    ↓
EXPLORE
    ↓
UNCERTAINTY
    ↓
CLASSIFY
    ├── SMALL
    │     ↓
    │  IMPLEMENT
    │     ↓
    │  VERIFY
    │     ↓
    │  COMMIT
    │     ↓
    │  CLOSE
    │
    └── SUBSTANTIAL
          ↓
       TRACK
          ↓
       PLAN / ROUTE
          ↓
       IMPLEMENT
          ↓
       VERIFY
          ↓
       COMMIT
          ↓
       REVIEW / DELIVERY
          ↓
       CLOSE
```

The lifecycle is conceptual. A runtime may combine or expose steps differently, but the semantics must remain equivalent.

## 3. Authorization

Determine whether the user's request authorizes modification.

### Read-only intent

Requests to explain, investigate, analyze, review, compare, diagnose, or estimate do not authorize source changes.

### Change intent

Explicit requests to implement, fix, modify, refactor, add, remove, migrate, or update authorize the described scope unless a material decision cannot be resolved safely.

### Boundary

> A finding is not authorization.

Discovering a bug, debt, refactoring opportunity, security concern, or architectural improvement does not authorize implementing it when it is outside the requested scope.

A material scope change requires renewed authorization.

## 4. Explore

Explore only enough context to act safely.

Typical exploration includes:

- project governance and invariants;
- target module and entry points;
- callers and dependencies;
- existing patterns and golden examples;
- tests and verification mechanisms;
- blast radius;
- relevant documentation;
- repository state and current diff.

Do not impose a ritual that requires reading every project document for every change.

## 5. Uncertainty

Resolve material uncertainty before writing code.

Use evidence from the repository first.

Research, codebase graph analysis, specialist skills, council/review agents, or user clarification are escalation mechanisms—not mandatory steps.

Do not invent requirements to eliminate uncertainty.

## 6. Classification

Classify the work after exploration.

### SMALL

Use SMALL when the change is:

- localized;
- low risk;
- sufficiently understood;
- consistent with an existing pattern;
- unlikely to have meaningful cross-cutting impact;
- recoverable from the request plus repository state.

Examples:

- typo;
- localized configuration adjustment;
- simple regression test;
- isolated bug fix;
- small documentation correction.

SMALL work should not create persistent planning artifacts merely to satisfy process.

### SUBSTANTIAL

Use SUBSTANTIAL when the work:

- crosses meaningful modules;
- contains non-trivial business logic;
- requires multiple implementation units;
- requires architectural decisions;
- requires research or significant uncertainty resolution;
- has meaningful blast radius;
- must survive interruption or session handoff;
- benefits from explicit reviewable work units.

The heuristic is judgment-based, not a rigid score.

## 7. Durable tracking

SUBSTANTIAL work must create:

```
odd/tasks/<feature-name>.md
```

before the first source-code write.

The feature document is the durable, versioned source of truth for that work.

Minimum sections:

- Objective
- Specs
- Tasks
- Verification
- Log
- Delivery

## 8. Optional PRD and Implementation Planning

A user-provided PRD is an **optional input**, not a prerequisite for ODD, planning, or implementation.

ODD must work correctly from a direct user request alone.

When a PRD exists, it is an additional structured source of user intent and requirements. It must be normalized and analyzed before being used for implementation planning.

The planning decision is independent from PRD presence:

- **No PRD + SMALL** → normally implement directly after exploration.
- **No PRD + SUBSTANTIAL** → create the ODD feature document and plan/route from the request plus codebase knowledge.
- **PRD + SMALL** → do not force persistent planning merely because a PRD exists.
- **PRD + SUBSTANTIAL** → use PRD analysis as an additional input to the repository-aware Implementation Plan.
- **User explicitly asks for a plan** → a plan may be produced without authorization to implement, with or without a PRD.

When a PRD is present, the optional pipeline is:

```
PRD
  ↓
NORMALIZE
  ↓
PRD ANALYSIS
  ↓
EXPLORE CODEBASE
  ↓
POLICIES / ARCHITECTURE
  ↓
IMPLEMENTATION PLAN
  ↓
ODD S# / T#
```

Without a PRD, the corresponding route is:

```
USER REQUEST
  ↓
EXPLORE CODEBASE
  ↓
POLICIES / ARCHITECTURE
  ↓
PLAN / ROUTE WHEN JUSTIFIED
  ↓
ODD S# / T#
```

The Implementation Plan answers:

> How should the authorized intent be implemented in this repository?

When a PRD exists, it contributes product intent and requirements. When it does not, the authorized user request is the primary intent source.

The ODD feature document answers:

> What authorized work units are being executed?

For substantial work:

```
odd/tasks/<feature-name>.md
```

A separate `odd/planning/<feature-name>.md` is created when an explicit or material Implementation Plan is justified, not merely because the work exists.

A plan never authorizes implementation by itself.

The runtime-neutral planning semantics are defined in:

```
odd/planning/CONTRACT.md
```

## 9. Ephemeral vs durable state

Todo lists, chat context, agent scratchpads, and runtime memory are execution aids.

They do not replace `odd/tasks/<feature-name>.md` for SUBSTANTIAL work.

## 10. Specification proportionality

A specification is a capability, not a mandatory ceremony.

For SMALL work, no persistent specification is normally required.

For SUBSTANTIAL work, S# entries live inside the feature document.

Legacy specification systems such as OpenSpec may be used only for explicit compatibility requirements during migration.

ODD must never recreate a rigid system-spec ceremony under another name.

## 11. Engineering capabilities

ODD is the orchestration layer. It does not replace engineering capabilities.

Runtimes may expose capabilities such as:

- codebase graph;
- fingerprinting;
- research;
- TDD;
- systematic debugging;
- parallel agents;
- code review;
- security analysis;
- verification;
- Git;
- delivery automation.

ODD decides when a capability is justified.

## 12. Implementation

Implement only the authorized scope.

For deterministic behavior with a clear expected result, prefer:

```
RED → GREEN → REFACTOR
```

For changes where TDD is not useful or practical, use the most appropriate verification strategy and record the rationale when material.

For SUBSTANTIAL work, update the feature document as work units progress.

## 13. Verification

Never claim completion without evidence.

Use the repository's actual applicable checks:

- unit/integration/e2e tests;
- lint;
- typecheck;
- build;
- static analysis;
- functional checks;
- deployment checks;
- regression checks.

Verification depth should be proportional to risk.

## 14. Work-unit commits

A completed SUBSTANTIAL work unit should normally have:

1. implementation;
2. verification;
3. an atomic reviewable commit;
4. its commit identity recorded in the T#.

Push, pull request, and merge are separate delivery decisions.

A commit does not imply permission to push or merge.

## 15. Scope control

When an out-of-scope finding appears:

1. record it;
2. preserve evidence;
3. do not silently implement it;
4. ask for authorization if it should become part of the current work.

When scope is expanded, update affected S#/T# entries before proceeding.

## 16. Resume and handoff

When resuming SUBSTANTIAL work:

1. read the local feature document;
2. inspect the actual repository state and Git diff;
3. recover optional external memory if available;
4. reconcile memory with repository reality;
5. continue from the next incomplete T#.

Repository state has precedence over stale memory.

Memory can preserve context; it cannot authorize changes or override observed code.

## 17. Persistence

The persistence abstraction is:

```
ODD Persistence
├── LocalFile   ← mandatory
├── Engram      ← optional
└── Future      ← extensible
```

LocalFile is the minimum durable mechanism.

Optional backends must preserve the same semantics and must never become a hidden source of authorization.

## 18. Human control

The human remains in control of:

- material architectural decisions;
- scope changes;
- external side effects when policy requires confirmation;
- push;
- pull request;
- merge;
- production delivery.

The agent may recommend the next action but must not infer authorization from its own findings.

## 19. Runtime adapter contract

Every supported agent runtime should provide, directly or through native mechanisms:

- access to this contract;
- repository exploration;
- change authorization handling;
- SMALL/SUBSTANTIAL classification;
- access to durable ODD tasks;
- implementation capabilities;
- verification;
- Git/delivery integration.

Runtime adapters may add syntax, file locations, permissions, or invocation details.

They must not introduce conflicting ODD semantics.

## 20. Compatibility rule

MentorKit has one ODD model.

```
                 ODD CORE CONTRACT
                         │
        ┌────────────────┼────────────────┐
        │                │                │
     OpenCode          Cursor           Codex
        │                │                │
     adapter           adapter          adapter
        │                │                │
        └────────────────┼────────────────┘
                         │
                   Claude Code
                      adapter
```

The adapter is an execution surface, not a fork of the methodology.

## 21. Completion

A change is complete when:

- the authorized scope is implemented;
- applicable verification has evidence;
- durable tracking is consistent for SUBSTANTIAL work;
- remaining risks are explicit;
- the delivery state is clear.

Completion never means “merge automatically”.
