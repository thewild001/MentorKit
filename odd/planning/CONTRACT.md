# MentorKit Implementation Planning Contract

## Status

This document is the runtime-neutral contract for generating an **Implementation Plan** from an authorized user request, optionally enriched by a user-provided PRD.

It is independent of the PRD file format and of the agent runtime.

## Objective

Transform user intent into an implementation approach that is compatible with the repository where the change will be implemented.

A PRD may provide structured product requirements, but it is never required.

The plan MUST combine:

```
user intent
+
optional PRD intent
+
repository reality
+
architecture
+
project policies
+
existing patterns
+
risk / blast radius
+
verification strategy
```

The plan MUST NOT invent architecture merely because it is common elsewhere.

## Core principle

> The PRD describes what the user wants. The repository determines how that intent should be implemented safely.

Existing repository patterns and confirmed project policies take precedence over generic agent preferences.

## Input

The planning pipeline may receive:

- a direct user request;
- an optional PDF;
- an optional DOCX;
- an optional DOC;
- an optional ODT;
- other formats supported by `document-extractor`.

The format MUST be normalized before semantic analysis.

The planner consumes a normalized PRD representation, not format-specific parsing logic.

## Planning phases

### Without PRD

```
AUTHORIZE
  ↓
EXPLORE REPOSITORY
  ↓
CHECK POLICIES / ARCHITECTURE
  ↓
RESOLVE MATERIAL UNCERTAINTY
  ↓
DESIGN / ROUTE
  ↓
GENERATE IMPLEMENTATION PLAN
  ↓
MAP TO ODD SPECS / TASKS
```

### With PRD

```
INGEST
  ↓
NORMALIZE
  ↓
ANALYZE PRD
  ↓
EXPLORE REPOSITORY
  ↓
CHECK POLICIES / ARCHITECTURE
  ↓
RESOLVE MATERIAL UNCERTAINTY
  ↓
DESIGN / ROUTE
  ↓
GENERATE IMPLEMENTATION PLAN
  ↓
MAP TO ODD SPECS / TASKS
```

### Important rule

PRD presence MUST NOT change whether a change is SMALL or SUBSTANTIAL by itself.

## PRD analysis

When a PRD is present, the analysis should identify, when present:

- objectives;
- actors;
- functional requirements;
- acceptance criteria;
- business rules;
- data and state;
- integrations;
- UI / UX requirements;
- validations;
- error handling;
- non-functional requirements;
- constraints;
- terminology;
- unresolved questions.

The original PRD vocabulary should be preserved where it is part of the user contract.

## Repository knowledge

Before material planning, use `odd/knowledge/CONTRACT.md`. Prefer `codebase-memory-mcp`, then Graphify, then direct fingerprinting/inspection. Record the provider and freshness of material evidence. The knowledge layer accelerates understanding but never overrides the repository.

## Repository exploration

The plan should use the available engineering capabilities to determine:

- codebase knowledge snapshot from the available provider;
- existing architecture;
- module boundaries;
- relevant entry points;
- golden examples;
- naming and structural conventions;
- data access patterns;
- API patterns;
- integration mechanisms;
- testing patterns;
- deployment/runtime constraints;
- blast radius;
- relevant project policies / constitution.

Use codebase graph and council/research only when justified by uncertainty or risk.

## Evidence levels

Planning must distinguish:

- **Observed** — directly evidenced by the repository or PRD.
- **Inferred** — reasonable conclusion from multiple pieces of evidence.
- **Proposed** — implementation choice suggested by MentorKit.
- **Confirmed** — explicitly accepted by the user/project policy.

Do not silently convert an inference into a project rule.

## Implementation Plan

A plan should normally contain:

1. Objective and scope.
2. Requirements traceability when a PRD exists.
3. Existing architecture and patterns.
4. Applicable policies and constraints.
5. Proposed solution/design.
6. Components/files/modules affected.
7. Data/API/integration changes.
8. Implementation sequence and dependencies.
9. Verification strategy.
10. Risks and blast radius.
11. Open decisions.
12. ODD S#/T# mapping.

## Planning proportionality

A PRD does not automatically imply a large plan.

- SMALL implementation: a lightweight plan may be sufficient, and persistent planning is normally unnecessary unless explicitly requested.
- SUBSTANTIAL implementation without PRD: plan/route directly from the user request and repository knowledge; persist the plan when complexity or user request justifies it.
- SUBSTANTIAL implementation with PRD: persist the repository-aware plan under `odd/planning/<feature-name>.md`.
- Explicit user request for a plan: produce the plan even when implementation is not yet authorized, with or without a PRD.

A plan is not authorization to implement.

## Relationship with ODD

The plan answers:

> How should the authorized intent be implemented in this repository?

The ODD feature document answers:

> What authorized units of work are we executing now?

Therefore:

```
User Request
    ↓
[Optional PRD]
    ↓
Implementation Plan
  ↓
ODD Feature Document
  ↓
S#/T#
  ↓
Implementation
```

A direct request without PRD is a first-class ODD input.

A direct request without PRD is a first-class ODD input.

The same PRD or request may generate multiple ODD tasks or work units.

## Scope control

The plan MUST preserve the requested scope.

Discovered opportunities, technical debt, or unrelated bugs are recorded as findings, not silently included.

## Human control

Before implementation of a substantial change, material architectural choices, scope changes, and unresolved business decisions remain under human control.

## Completion

A PRD-driven planning operation is complete when:

- the user intent is understood;
- if a PRD exists, it was normalized successfully;
- requirements and material uncertainties are identified;
- repository context has been considered;
- the implementation approach is explicit;
- verification is defined;
- open decisions are visible;
- the plan can be traced to the source request and, when present, PRD requirements.
