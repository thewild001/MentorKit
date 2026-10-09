# MentorKit — Runtime y Skills

Esta carpeta contiene la integración de MentorKit con OpenCode: runtime, instaladores, agentes y skills. MentorKit es un **orquestador de desarrollo** que aplica Organic-Driven Development (ODD) y adapta el flujo al alcance del cambio y al contexto real del repositorio.

La metodología ODD y la planificación son agnósticas del agente. Sus contratos canónicos viven en `odd/` y `AGENTS.md`.

## Instalación y bienvenida

El one-liner installer descarga los artefactos, prepara el runtime y verifica las dependencias. Al concluir correctamente muestra un splash de bienvenida con la marca **MentorKit**, el estado de instalación y los pasos iniciales. El splash solo debe aparecer tras una instalación exitosa; los errores deben conservar su diagnóstico y código de salida.

En OpenCode, abre el proyecto y selecciona el agente `MentorKit5.0` con `Tab`.

## Principios

### Conformidad primero

> **Las convenciones, arquitectura y políticas confirmadas del codebase tienen precedencia sobre las preferencias genéricas del agente.**

### ODD proporcional

SMALL no debe recibir la misma ceremonia que una migración o feature transversal. ODD decide cuándo persistir, planificar, investigar, probar y revisar. Un hallazgo no autoriza por sí solo cambios de código, y planificar no autoriza implementar.

### La solicitud es la entrada principal; el PRD es opcional

MentorKit puede partir de una solicitud directa del usuario o de una solicitud acompañada de un PRD. La presencia de un PRD no determina la complejidad ni obliga a crear un plan persistente.

- **SMALL:** explorar, implementar y verificar de forma proporcional.
- **SUBSTANTIAL:** crear el documento de feature ODD en `odd/tasks/`; elaborar un Implementation Plan cuando la complejidad o el usuario lo justifiquen.
- Si existe un PRD, se usa como fuente adicional de requisitos; si no existe, la solicitud y el conocimiento del codebase son suficientes para comenzar.

Cuando se proporciona un PRD, el flujo de análisis puede ser:

```
PRD (opcional)
 ↓
document-extractor
 ↓
Contenido normalizado
 ↓
prd-reader
 ↓
Análisis de requisitos
 ↓
codebase-conformist + codebase-graph
 ↓
Implementation Plan (cuando corresponda)
 ↓
Documento de feature ODD / ejecución
```

La planificación no constituye autorización para implementar. Consulta `odd/CONTRACT.md` y `odd/planning/CONTRACT.md`.

## Codebase Knowledge

La comprensión del repositorio sigue siendo una capacidad central de MentorKit:

`codebase-memory-mcp` → **Graphify** → **Fingerprinting / inspección directa**.

El repositorio es la fuente de verdad. Los sistemas de conocimiento aceleran la exploración, pero no sustituyen el estado observado ni la evidencia directa. Consulta `odd/knowledge/CONTRACT.md`.

## Skills

```
.opencode/skills/
├── odd-orchestrator/       # Orquestación ODD
├── codebase-conformist/    # Exploración, conformidad y ejecución
├── codebase-graph/         # Grafo, arquitectura y blast radius
├── prd-reader/             # Análisis semántico del PRD (opcional)
├── document-extractor/     # PDF/DOCX/DOC/ODT → contenido normalizado
├── spec-writer/            # Specs y tareas verificables
├── llm-council/            # Escalación de decisiones complejas
└── superpowers/            # Capacidades de ejecución
```

## Formatos PRD

- **PDF digital:** extracción de texto.
- **PDF escaneado:** detectar si requiere OCR; nunca inventar contenido no legible.
- **DOCX:** parser Python.
- **DOC:** backend `anydoc`.
- **ODT:** parser Python.

La extracción es independiente de la interpretación: `prd-reader` no debe contener lógica específica de formato.

## Artefactos

Para trabajo SUBSTANTIAL:

```
odd/tasks/<feature-name>.md
odd/planning/<feature-name>.md   # cuando se justifique o se solicite
```

El Implementation Plan describe la ruta técnica y arquitectónica. El documento de feature ODD representa el estado durable de ejecución.

## Compatibilidad

- **OpenCode:** `.opencode/skills/` + `.opencode/agents/`
- **Cursor:** `.cursor/rules/`
- **Codex:** `AGENTS.md` + `.agents/skills/`
- **Claude Code:** `CLAUDE.md` + `.claude/skills/`

Todos consumen un contrato ODD común mediante adaptadores nativos; no son implementaciones independientes de la metodología.

## Runtime

- Python 3.12 mediante `uv`;
- dependencias bloqueadas en `requirements.lock`;
- runtime aislado en `.opencode/.mentorkit/`;
- instaladores POSIX y PowerShell;
- CI de smoke tests para Linux, macOS y Windows.

## Contratos principales

```
AGENTS.md
odd/CONTRACT.md
odd/knowledge/CONTRACT.md
odd/planning/CONTRACT.md
```
