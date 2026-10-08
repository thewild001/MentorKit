# MentorKit

> **Agentic engineering workflow para desarrolladores**, construido sobre OpenCode y orientado a aplicar **Organic Driven Development (ODD)** de forma proporcional al cambio.

MentorKit no pretende imponer una ceremonia para cada modificación. Su objetivo es que el agente determine **cuánto proceso necesita realmente el trabajo**: desde un cambio pequeño y autocontenido hasta una feature sustancial que requiere contexto persistente, planificación, tareas, verificación y unidades de entrega revisables.

**Plataformas:** Linux · macOS · Windows (PowerShell nativo, además de Git Bash/WSL2)  
**Compatibilidad:** instalación y runtime diseñados para los tres SO; CI de smoke test en runners Linux/macOS/Windows  
**Python:** 3.12.13  
**Runtime:** OpenCode + skills MentorKit  
**Workflow:** ODD — SMALL / SUBSTANTIAL

---

## 📄 PRD → Implementation Plan

MentorKit conserva la capacidad de recibir un Product Requirements Document y convertirlo en un plan de implementación **adaptado al repositorio real**, no en una traducción mecánica del PRD a tareas.

### Formatos de entrada

- PDF
- DOCX
- DOC
- ODT

La ingestión está desacoplada de la interpretación:

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
```

### Principio

> **El PRD define la intención. El codebase define el contexto de implementación.**

Por eso MentorKit analiza, antes de generar el plan:

- arquitectura existente;
- políticas y constitución;
- patrones y golden examples;
- dependencias y blast radius;
- estrategia de pruebas;
- integraciones;
- riesgos;
- decisiones abiertas.

El plan se persiste para trabajo sustancial en:

```
odd/planning/<feature-name>.md
```

y el estado de ejecución en:

```
odd/tasks/<feature-name>.md
```

Un plan nunca implica autorización automática para implementar.

### Cobertura documental

| Formato | Soporte |
|---|---|
| PDF digital | ✅ |
| PDF escaneado | ⚠️ Requiere OCR |
| DOCX | ✅ |
| DOC | ✅ |
| ODT | ✅ |

La ruta `.doc` utiliza `firecrawl-anydoc`, que soporta Word 97–2003 sin depender de Word, LibreOffice o ejecutables del sistema. citeturn859555search5turn859555search2

Consulta los contratos runtime-neutral en:

- `odd/CONTRACT.md`
- `odd/planning/CONTRACT.md`
