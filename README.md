# MentorKit
MentorKit: "An Agentic Mentor for Legacy Code"

tu-proyecto/├── .opencode/ ← configuración del agente (estático)│ ├── skills/│ │ ├── spec-writer/│ │ │ └── SKILL.md│ │ ├── codebase-conformist/│ │ │ └── SKILL.md│ │ └── llm-council/│ │ └── SKILL.md│ └── agents/│ └── dev-guide.md│├── .specify/ ← artefactos del proyecto (dinámico)│ ├── memory/│ │ └── constitution.md ← creado en primera sesión│ └── specs/│ ├── 001-login-feature/│ │ ├── spec.md│ │ ├── research.md│ │ └── pr-description.md│ └── 002-payment-fix/│ └── spec.md│├── apps/└── ...


------------------------------------------------------------
La separación tiene una lógica clara

.opencode/ — le dice al agente cómo comportarse. Es configuración. Va al repositorio pero rara vez cambia.

.specify/ — documenta qué se está construyendo. Son artefactos de trabajo. Va al repositorio y evoluciona con cada feature.

------------------------------------------------------------

# Copiar la estructura al proyectocp -r .opencode/ tu-proyecto/.opencode/
# En la primera sesión, el dev-guide crea automáticamente:# .opencode/memory/constitution.md ← desde el template# .specify/ ← cuando se genera la primera spec


------------------------------------------------------------


Primera sesión, cualquier tarea:  dev-guide init → crea .opencode/memory/constitution.md 
Tarea simple o bug fix:  .specify/ → no se crea (correcto, no se necesita)
Feature compleja:  spec-writer → crea .specify/specs/NNN-slug/spec.md   research → crea .specify/specs/NNN-slug/research.md (si aplica)  fin ciclo → crea .specify/specs/NNN-slug/pr-description.md 



