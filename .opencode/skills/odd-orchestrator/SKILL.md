---
name: odd-orchestrator
description: >
  Orquestador Organic Driven Development para MentorKit. Decide proporcionalmente
  cuánto proceso necesita cada cambio: autorización, detección opcional de PRD,
  exploración, clasificación SMALL/SUBSTANTIAL, persistencia recuperable,
  planificación, ejecución por unidades de trabajo, verificación y cierre.
compatibility: opencode
metadata:
  version: "1.1"
  workflow: "organic-driven-development"
---

# ODD Orchestrator — OpenCode Adapter

The runtime-neutral ODD semantics live in `odd/CONTRACT.md`. PRD-driven planning semantics live in `odd/planning/CONTRACT.md`.

This skill adapts those runtime-neutral contracts to OpenCode and must not redefine them.

## 1. Authorization Gate

Primero determina si el mensaje autoriza un cambio.

### Read-only

No modifica archivos cuando el usuario pide:

- explicar
- investigar
- analizar
- revisar
- diagnosticar
- comparar
- estimar
- generar un plan sin autorización de implementación

### Authorized change

Una solicitud explícita de:

- implementar
- corregir
- modificar
- refactorizar
- añadir
- eliminar
- migrar
- actualizar

autoriza el cambio dentro del alcance indicado.

Generar un Implementation Plan **no implica autorización de implementación**.

## 2. PRD Detection

Cuando el mensaje contiene un documento adjunto candidato a PRD, detecta silenciosamente:

- `.pdf`
- `.docx`
- `.doc`
- `.odt`

Invoca `prd-reader`, que delega la extracción a `document-extractor`.

Si no hay PRD, continúa con el flujo ODD normal.

## 3. Explore

Antes de implementar:

1. Lee la constitución/gobernanza disponible.
2. Inspecciona el módulo objetivo.
3. Busca una plantilla de oro.
4. Comprueba callers/dependencias y blast radius.
5. Usa `codebase-graph` cuando esté disponible.
6. Usa `llm-council` solo si existe conflicto, riesgo alto o patrón nuevo.
7. Determina qué información falta para implementar con seguridad.

Constitución preferida:

```
.mentor/constitution.md
```

Compatibilidad legacy:

```
openspec/memory/constitution.md
```

No inicialices una constitución solo para completar el ritual.

## 4. Classify

### SMALL

Usa SMALL cuando:

- el cambio está completamente entendido;
- el alcance es contenido;
- existe un patrón claro;
- el blast radius es bajo;
- no hay decisiones abiertas relevantes.

Ruta:

```
Implement → Verify → Commit → Close
```

Un PRD puede describir un cambio pequeño. No fuerces un plan persistente solo por existir un PRD.

### SUBSTANTIAL

Usa SUBSTANTIAL cuando:

- cruza varios módulos;
- tiene lógica no trivial;
- requiere múltiples tareas;
- requiere investigación;
- necesita decisiones de arquitectura;
- tiene blast radius significativo;
- debe sobrevivir a una interrupción;
- una revisión útil necesita una unidad de trabajo explícita.

## 5. Plan / Route

Planning is driven by complexity and user intent, not by PRD presence.

### With PRD

When a PRD exists and planning is justified:

```
prd-reader
   ↓
PRD Analysis
   ↓
codebase-conformist
   +
codebase-graph
   ↓
Implementation Plan
```

The plan must follow `odd/planning/CONTRACT.md`.

Persist the plan for SUBSTANTIAL work when it is material or explicitly requested:

```
odd/planning/<feature-name>.md
```

The plan must be reviewable before implementation.

If the user requested only a plan, the process ends at the plan and remains read-only.

### Without PRD

For substantial work without a PRD, derive the plan/route from the authorized user request, Codebase Knowledge Snapshot, project policies, architecture, patterns, blast radius, and verification strategy.

A PRD is optional enrichment, never a prerequisite for planning or implementation.

## 6. Feature Document

Para SUBSTANTIAL crea **antes del primer source write**:

```
odd/tasks/<feature-name>.md
```

El feature document contiene:

- Objective
- Specs
- Tasks
- Verification
- Log
- Delivery

### Specs

Usa IDs estables S1, S2, etc.

### Tasks

Usa IDs estables T1, T2, etc.

Cuando exista Implementation Plan, S#/T# deben poder trazarse a sus requisitos
y a las decisiones relevantes del plan.

## 7. Execution

`TodoWrite` puede representar el estado de ejecución, pero el documento ODD es la persistencia durable.

Superpowers siguen siendo capacidades de ejecución:

- brainstorming
- writing-plans
- TDD
- systematic-debugging
- parallel agents
- code review
- verification-before-completion
- finishing-a-development-branch

ODD decide **cuándo** usarlas.

## 8. Verification

Nunca declares completado sin evidencia.

## 9. Scope Control

Un hallazgo no equivale a autorización.

## 10. Resume / Handoff

Para continuar una sesión:

1. lee el documento local completo;
2. si existe Implementation Plan, léelo completo;
3. inspecciona el código y git diff reales;
4. si existe espejo Engram, recupera el documento completo;
5. reconcilia ambos contra el estado observado;
6. continúa desde el siguiente T# incompleto.

La memoria nunca sobreescribe la realidad observada.

## 11. Persistence

```
ODD Persistence
├── LocalFile   ← obligatorio
├── Engram      ← opcional
└── Future      ← extensible
```

## 12. Close

Una feature queda cerrada cuando:

- los S# autorizados están implementados;
- los checks aplicables fueron ejecutados;
- los resultados están registrados;
- cada T# relevante tiene commit;
- el siguiente paso de delivery está explícito.

El cierre no implica merge automático.
