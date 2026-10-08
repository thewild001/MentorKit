<p align="center">
  <img src="./MentorKit5.0-Banner.png" alt="MentorKit" width="100%" />
</p>

# MentorKit

> **Agentic engineering workflow para desarrolladores**, construido sobre OpenCode y orientado a aplicar **Organic Driven Development (ODD)** de forma proporcional al cambio.

MentorKit no pretende imponer una ceremonia para cada modificación. Su objetivo es que el agente determine **cuánto proceso necesita realmente el trabajo**: desde un cambio pequeño y autocontenido hasta una feature sustancial que requiere contexto persistente, planificación, tareas, verificación y unidades de entrega revisables.

**Plataformas:** Linux · macOS · Windows (PowerShell nativo, además de Git Bash/WSL2)  
**Python:** 3.12.13  
**Runtime:** OpenCode + skills MentorKit  
**Workflow:** ODD — SMALL / SUBSTANTIAL

---

## 🚀 Instalación

Desde la raíz del proyecto donde quieres utilizar MentorKit:

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/main/bootstrap.sh")
```

El one-liner descarga el release, instala `.opencode/`, `odd/`, la plantilla `.mentor/` y los contratos de agentes, prepara el runtime Python aislado, instala las dependencias desde `requirements.lock` y verifica el entorno.

### Instalación nativa en Windows

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Después:

```powershell
powershell -ExecutionPolicy Bypass -File .\.opencode\mentorkit-verify.ps1
```

Git Bash y WSL2 continúan soportados, pero ya no son requisitos en Windows.

### Probar la rama experimental

```bash
MENTORKIT_BRANCH=feature/odd-migration \
bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/feature/odd-migration/bootstrap.sh")
```

El instalador no contiene credenciales ni depende de un GitLab privado.

---

## 🧠 ODD en MentorKit

**Organic Driven Development** es el modelo de orquestación de MentorKit.

> **No todos los cambios necesitan el mismo nivel de proceso.**

```
Request
   ↓
Authorization
   ↓
Explore
   ↓
Resolve uncertainty
   ↓
Classify
   ├────────────── SMALL
   │                 ↓
   │             Implement
   │                 ↓
   │              Verify
   │                 ↓
   │              Commit
   │                 ↓
   │              Close
   │
   └──────────── SUBSTANTIAL
                     ↓
             odd/tasks/<feature>.md
                     ↓
                Specs S#
                Tasks T#
                     ↓
             Implement task-by-task
                     ↓
                  Verify
                     ↓
             Work-unit Commit
                     ↓
                Review / PR
                     ↓
                  Close
```

### SMALL

Cambio localizado, de bajo riesgo, suficientemente entendido, con patrón claro y blast radius bajo. No se crea planificación persistente por defecto.

### SUBSTANTIAL

Feature, migración, cambio arquitectónico, refactor transversal, lógica no trivial, trabajo con incertidumbre material o que necesita continuidad entre sesiones. Requiere `odd/tasks/<feature-name>.md`.

---

## 📄 PRD → Implementation Plan

MentorKit conserva la capacidad de recibir un Product Requirements Document y convertirlo en un plan de implementación **adaptado al repositorio real**, no en una traducción mecánica del PRD a tareas.

### Formatos

- PDF
- DOCX
- DOC
- ODT

### Flujo

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
Implement
```

### Principio

> **El PRD define la intención. El codebase define el contexto de implementación.**

Antes de generar el plan, MentorKit considera arquitectura existente, políticas/constitución, patrones, dependencias, blast radius, verificación, riesgos y decisiones abiertas.

Para trabajo sustancial se persisten:

```
odd/planning/<feature-name>.md
odd/tasks/<feature-name>.md
```

El Implementation Plan representa la ruta técnica y arquitectónica; el ODD Feature Document representa el estado de ejecución. Un plan nunca implica autorización automática para implementar.

### Cobertura documental

| Formato | Soporte |
|---|---|
| PDF digital | ✅ |
| PDF escaneado | ⚠️ Requiere OCR |
| DOCX | ✅ |
| DOC | ✅ |
| ODT | ✅ |

La ruta `.doc` utiliza el backend `anydoc` ya presente en el runtime de MentorKit, sin depender de Microsoft Word, LibreOffice, COM ni ejecutables específicos del sistema.

---

## 🧭 Conformidad con el proyecto

Una de las ideas fundacionales de MentorKit se mantiene en esta versión:

> **El agente se adapta al proyecto; el proyecto no se adapta al agente.**

MentorKit explora y formaliza el conocimiento del repositorio mediante:

```
Codebase
   ↓
Architecture
   ↓
Policies / Constitution
   ↓
Patterns / Golden Examples
   ↓
ODD Planning
   ↓
Implementation
   ↓
Policy / Verification checks
```

Se mantiene la separación:

- **Observed:** lo que realmente hace el código.
- **Inferred:** lo que MentorKit deduce.
- **Confirmed:** lo que el proyecto acepta como política o decisión.
- **Proposed:** una alternativa de implementación.

Una inferencia nunca se convierte silenciosamente en una política obligatoria.

---

## 🧩 Arquitectura

```
MentorKit
  ├── ODD Engine
  │   ├── Authorize
  │   ├── Explore
  │   ├── Classify
  │   ├── Track
  │   ├── Plan / Route
  │   ├── Implement
  │   ├── Verify
  │   └── Close
  ├── Engineering capabilities
  │   ├── Codebase Graph
  │   ├── Fingerprinting
  │   ├── PRD Analysis
  │   ├── Spec Writer
  │   ├── TDD
  │   ├── Debugging
  │   ├── Parallel Agents
  │   ├── Code Review
  │   └── Git
  ├── Project knowledge
  │   ├── Constitution
  │   ├── Policies
  │   ├── Architecture
  │   ├── Feature Plans
  │   └── ODD Tasks
  └── Runtime adapters
      ├── OpenCode
      ├── Cursor
      ├── Codex
      └── Claude Code
```

---

## 📂 Persistencia

```
odd/
├── CONTRACT.md
├── planning/
│   ├── CONTRACT.md
│   ├── README.md
│   └── <feature-name>.md
├── templates/
└── tasks/
    └── <feature-name>.md
```

### LocalFile

Persistencia obligatoria para trabajo SUBSTANTIAL.

### Engram

Espejo opcional para continuidad entre sesiones. Nunca tiene precedencia sobre el estado observado del repositorio.

---

## 🧪 Verificación

Cuando existe un test determinista con resultado claro:

```
RED → GREEN → REFACTOR
```

Una unidad sustancial se cierra con implementación, evidencia de verificación, commit atómico y SHA registrado en su T#.

Nunca se declara completado sin evidencia.

---

## 🤖 Compatibilidad con agentes

| Agente | Integración nativa | Contrato compartido |
|---|---|---|
| **OpenCode** | `.opencode/skills/` + `.opencode/agents/` + `AGENTS.md` | Sí |
| **Cursor** | `.cursor/rules/` + `AGENTS.md` | Sí |
| **Codex** | `AGENTS.md` + `.agents/skills/` | Sí |
| **Claude Code** | `CLAUDE.md` + `.claude/skills/` | Sí |

El contrato común vive en `AGENTS.md` y `odd/`. Los archivos específicos de cada agente son adaptadores, no metodologías alternativas.

---

## 🖥️ Compatibilidad multiplataforma

- **Linux:** `bootstrap.sh` + launchers POSIX.
- **macOS:** `bootstrap.sh` + launchers POSIX.
- **Windows:** `bootstrap.ps1` + `install-mentorkit.ps1` + `mentorkit-verify.ps1`.
- **Runtime común:** `.opencode/mentorkit.py`.
- **Python:** gestionado mediante `uv`.
- **CI:** smoke tests reales en Ubuntu, macOS y Windows.

---

## 🛠️ Desarrollo de MentorKit

```bash
git clone https://github.com/thewild001/MentorKit.git
cd MentorKit
make install
make verify
```

Targets principales:

| Target | Descripción |
|---|---|
| `make install` | Prepara/repara el runtime |
| `make verify` | Verifica Python y dependencias |
| `make odd-check` | Valida la estructura ODD |
| `make odd-task FEATURE=x REQUEST="..."` | Crea una tarea ODD |
| `make clean` | Elimina el runtime local |
| `make ci` | Ejecuta las comprobaciones locales |

OpenSpec permanece disponible durante la migración experimental únicamente como **compatibilidad legacy**.

---

## 📦 Estructura relevante

```
MentorKit/
├── .mentor/
├── .opencode/
│   ├── agents/
│   ├── skills/
│   │   ├── odd-orchestrator/
│   │   ├── codebase-conformist/
│   │   ├── codebase-graph/
│   │   ├── prd-reader/
│   │   ├── document-extractor/
│   │   ├── spec-writer/
│   │   ├── llm-council/
│   │   └── superpowers/
│   ├── mentorkit.py
│   └── requirements.lock
├── odd/
│   ├── CONTRACT.md
│   ├── planning/
│   └── tasks/
├── openspec/                 # legacy durante la migración
├── AGENTS.md
├── CLAUDE.md
├── .cursor/
├── .agents/
├── .claude/
├── bootstrap.sh
├── bootstrap.ps1
└── Makefile
```

---

## 🌱 Estado de la migración

Esta implementación se encuentra en la rama experimental `feature/odd-migration`.

La migración se valida progresivamente con:

- cambios SMALL;
- features SUBSTANTIAL;
- PRD → Implementation Plan;
- documentos PDF/DOCX/DOC;
- cambios arquitectónicos;
- interrupciones y resume;
- cambios de scope;
- políticas y drift;
- compatibilidad con OpenCode, Cursor, Codex y Claude Code;
- instalación Linux/macOS/Windows.

OpenSpec no se retira hasta que el flujo ODD haya sido validado con casos reales.

---

## 🤝 Contribuir

1. Crea una rama.
2. Comprende el cambio antes de implementarlo.
3. Respeta el workflow ODD.
4. Mantén los cambios dentro del scope autorizado.
5. Verifica antes de declarar completado el trabajo.
6. Usa commits atómicos y descriptivos.
7. Abre un PR cuando corresponda.

---

## 📜 Créditos

Desarrollado por [thewild001](https://github.com/thewild001) · Universidad de las Ciencias Informáticas (UCI)

Repositorio: https://github.com/thewild001/MentorKit
