# MentorKit Codebase Knowledge Contract

## Status

Runtime-neutral contract for discovering, building, reusing and validating knowledge about the repository.

## Objective

MentorKit must understand the repository **before** proposing or implementing a material change.

This capability is not replaced by ODD or PRD planning. It is a shared foundation consumed by ODD Explore, PRD planning, Constitution/Policy generation, impact analysis, implementation conformity, verification, and resume/handoff.

## Core principle

> **The repository is the source of truth. Knowledge systems accelerate understanding; they do not override observed repository state.**

## Knowledge providers

Use the strongest available provider in this order:

1. **codebase-memory-mcp** — preferred persistent semantic/code graph;
2. **Graphify** — local graph fallback;
3. **Fingerprinting / direct repository inspection** — mandatory final fallback.

Availability must be detected at runtime. A missing optional provider must never block MentorKit.

### codebase-memory-mcp

When available, prefer it for architecture/dependency queries, god nodes, rationale and implicit knowledge, semantic graph search, blast radius via `trace_path`, change/drift analysis via `detect_changes`, ADR knowledge via `manage_adr`, and persistent cross-session/project codebase knowledge.

### Graphify

When MCP is unavailable, use the existing Graphify capability for graph construction, god nodes, communities, rationale nodes, inferred relationships, and local graph reports.

### Fingerprinting

When neither graph provider is available, inspect the repository directly: manifests/lock files, source tree, entry points, configuration, CI/CD, scripts, tests, deployment/runtime files, representative modules, and git history.

## Knowledge snapshot

Before a material plan, MentorKit should assemble a **Codebase Knowledge Snapshot** containing, when available:

```
Repository identity
Stack / runtime
Architecture
Module boundaries
Entry points
Golden examples
Critical / god nodes
Rationale / implicit constraints
Dependency relationships
Blast radius
Testing patterns
Deployment/runtime constraints
Policies / Constitution
Evidence and freshness
Provider used
```

The snapshot is contextual knowledge, not authorization.

## Evidence levels

Every material conclusion should be classified as:

- **Observed** — directly evidenced by repository artifacts or graph data.
- **Inferred** — supported by multiple signals.
- **Proposed** — a MentorKit recommendation.
- **Confirmed** — explicitly accepted by the project/user.

An inferred graph relationship must not silently become a policy.

## Freshness

Before high-impact work:

- check whether the graph/index is available and current;
- refresh or incrementally update it when needed;
- compare relevant files/git state with the knowledge snapshot;
- use direct repository inspection when graph data is stale or contradictory.

For small, low-risk changes, a full graph rebuild is unnecessary when relevant context is already current.

## PRD planning integration

The PRD pipeline MUST consume repository knowledge:

```
PRD
 ↓
Normalize
 ↓
PRD Analysis
 ↓
Codebase Knowledge Snapshot
 ↓
Policies / Constitution
 ↓
Architecture + Patterns
 ↓
Blast Radius
 ↓
Implementation Plan
```

The planner must not design against a hypothetical greenfield architecture when the requested feature targets an existing repository.

## Constitution / Policy integration

The constitution generator may use the knowledge snapshot, but must distinguish:

- what the repository does;
- what MentorKit infers;
- what the project explicitly mandates.

Observed behavior alone is not sufficient to manufacture a mandatory policy.

## Implementation integration

Before source writes, use the knowledge snapshot to validate selected extension points, architectural boundaries, golden patterns, dependencies, affected callers, test strategy, and project policies.

After implementation, re-check affected knowledge when practical.

## Resume / handoff

When resuming work:

1. read durable ODD state;
2. inspect current git/repository state;
3. reuse persistent graph knowledge if fresh;
4. reconcile stale graph/memory data against the repository;
5. continue from observed state.

Memory is acceleration, not authority.

## Failure behavior

```
MCP unavailable/fails
    ↓
Graphify fallback
    ↓
Fingerprint/direct inspection
```

If all enhanced providers fail, MentorKit continues with direct repository analysis and explicitly records the degraded knowledge mode.

## Runtime adapters

Different agents may expose different mechanisms for accessing MCP, graph tools, files, or memory.

Adapters must map their native capabilities to this contract without redefining its semantics.

OpenCode currently has the richest native `codebase-memory-mcp` integration in MentorKit. Other runtimes may provide equivalent providers later.

## Non-goals

This contract does not authorize changes, replace ODD, replace the constitution, replace PRD analysis, require one MCP implementation for every runtime, or treat persistent memory as more authoritative than the repository.
