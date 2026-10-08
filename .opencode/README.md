# MentorKit — Runtime y Skills

Esta carpeta contiene la integración nativa de MentorKit con OpenCode. La metodología ODD y la planificación basada en PRD no pertenecen exclusivamente a OpenCode: sus contratos canónicos viven en `odd/` y `AGENTS.md`.

## Principios

### Conformidad primero

> **Las convenciones, arquitectura y políticas confirmadas del codebase tienen precedencia sobre las preferencias genéricas del agente.**

### ODD proporcional

SMALL no debe recibir la misma ceremonia que una migración o feature transversal. ODD decide cuándo persistir, planificar, investigar, probar y revisar.

### PRD como entrada

Un PRD expresa intención. MentorKit lo normaliza, interpreta y aterriza en el contexto real del repositorio.

```
PRD
 ↓
document-extractor
 ↓
Normalized PRD
 ↓
prd-reader
 ↓
PRD Analysis
 ↓
codebase-conformist + codebase-graph
 ↓
Implementation Plan
 ↓
spec-writer
 ↓
ODD S#/T#
 ↓
Implementation
```

## Codebase Knowledge

La comprensión del repositorio sigue siendo una capacidad central de MentorKit:

\`codebase-memory-mcp\` → **Graphify** → **Fingerprinting / inspección directa**.

`codebase-graph` conserva la integración MCP y el fallback local. Consulta `odd/knowledge/CONTRACT.md` para la semántica runtime-neutral.

## Skills

```
.opencode/skills/
├── odd-orchestrator/       # Orquestación ODD
├── codebase-conformist/    # Exploración, conformidad y ejecución
├── codebase-graph/         # Grafo, arquitectura y blast radius
├── prd-reader/             # Análisis semántico del PRD
├── document-extractor/     # PDF/DOCX/DOC/ODT → contenido normalizado
├── spec-writer/            # S#/T# verificables
├── llm-council/            # Escalación de decisiones complejas
└── superpowers/            # Capacidades de ejecución
```

## Formatos PRD

```
PDF digital   → markitdown → anydoc fallback
PDF escaneado → detectar needs_ocr; no inventar contenido
DOCX          → parser Python
DOC           → anydoc
ODT           → parser Python
```

La extracción es independiente de la interpretación: `prd-reader` no debe contener lógica específica de formato.

## Artefactos

Para trabajo SUBSTANTIAL impulsado por PRD:

```
odd/planning/<feature-name>.md
odd/tasks/<feature-name>.md
```

El Implementation Plan describe la ruta técnica y arquitectónica. El ODD Feature Document representa el estado de ejecución.

## Compatibilidad

- **OpenCode:** `.opencode/skills/` + `.opencode/agents/`
- **Cursor:** `.cursor/rules/`
- **Codex:** `AGENTS.md` + `.agents/skills/`
- **Claude Code:** `CLAUDE.md` + `.claude/skills/`

Todos consumen una misma semántica ODD.

## Runtime

- Python 3.12.13 mediante `uv`;
- dependencias bloqueadas en `.opencode/requirements.lock`;
- runtime aislado en `.opencode/.mentorkit/`;
- launchers POSIX y PowerShell;
- CI de smoke test Linux/macOS/Windows.

Contratos principales:

```
AGENTS.md
odd/CONTRACT.md
odd/planning/CONTRACT.md
```
