<p align="center">
  <img src="./MentorKit5.0-Banner.png" alt="MentorKit" width="100%" />
</p>

# MentorKit

> **Agentic engineering workflow para desarrolladores**, construido sobre OpenCode y orientado a aplicar **Organic Driven Development (ODD)** de forma proporcional al cambio.

MentorKit no impone una ceremonia uniforme. Determina cuánto proceso necesita cada trabajo: desde un cambio pequeño y localizado hasta una feature sustancial que requiere contexto persistente, planificación, tareas, verificación y unidades de entrega revisables.

**Plataformas:** Linux · macOS · Windows  
**Runtime principal:** OpenCode + skills MentorKit  
**Agentes objetivo:** OpenCode · Cursor · Codex · Claude Code  
**Workflow:** ODD — SMALL / SUBSTANTIAL

---

## 🚀 Instalación

Desde la raíz del proyecto donde quieres utilizar MentorKit:

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/feature/odd-migration/bootstrap.sh")
```

Para instalar la rama experimental en Linux o macOS. El instalador prepara los componentes de MentorKit, el runtime Python administrado mediante `uv` y las verificaciones disponibles.

### Windows nativo

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Verificación:

```powershell
powershell -ExecutionPolicy Bypass -File .\.opencode\mentorkit-verify.ps1
```

Windows también puede utilizar Git Bash o WSL2, pero no son requisitos para el flujo nativo.

> **Importante:** esta es una rama experimental. Instálala primero en un repositorio de prueba y valida los flujos relevantes antes de adoptarla en proyectos críticos.

---

## 🧠 Organic Driven Development (ODD)

ODD es el modelo de orquestación de MentorKit. El proceso se adapta a la complejidad y al riesgo, no al revés.

```text
User Request
     ↓
Authorization
     ↓
Explore / Understand
     ↓
Resolve material uncertainty
     ↓
Classify
  ┌──┴───────────┐
 SMALL        SUBSTANTIAL
   │                │
   ▼                ▼
Implement       Durable ODD Task
   │            odd/tasks/<feature>.md
   │                │
   │           Plan / Route as needed
   │                │
   └───────┬────────┘
           ▼
        Verify
           ▼
   Commit / Review as authorized
           ▼
         Close
```

### SMALL

Cambio localizado, de bajo riesgo y suficientemente comprendido. Se implementa y verifica siguiendo los patrones existentes, sin crear documentación persistente por mera formalidad.

### SUBSTANTIAL

Feature, migración, cambio arquitectónico, refactor transversal, lógica no trivial o trabajo que requiere varias unidades, decisiones relevantes o continuidad entre sesiones. Antes de modificar el código se crea:

```text
odd/tasks/<feature-name>.md
```

El documento mantiene el objetivo, las especificaciones verificables (S#), las tareas (T#), la estrategia de verificación, el registro de avance y el estado de entrega.

### Autorización y control de alcance

- Una solicitud de análisis o explicación no autoriza por sí sola cambios de código.
- Un hallazgo no equivale a autorización.
- Los cambios de alcance requieren autorización.
- Generar un plan no autoriza automáticamente su implementación.
- Push, pull request, merge y despliegue siguen siendo decisiones de entrega independientes.

---

## 📄 PRD opcional y planificación de implementación

**Un PRD no es un requisito para utilizar ODD.** Una solicitud directa del usuario es una entrada de primera clase. La existencia de un PRD tampoco determina si el cambio es SMALL o SUBSTANTIAL.

### Ruta sin PRD

```text
User Request
     ↓
Authorization + Exploration
     ↓
Codebase Knowledge
     ↓
Plan / Route when justified
     ↓
ODD Feature Document, if SUBSTANTIAL
     ↓
S# / T# → Implementation
```

### Ruta con PRD

```text
User Request + optional PRD
             ↓
       document-extractor
             ↓
       Normalized PRD
             ↓
          prd-reader
             ↓
         PRD Analysis
             ↓
 Codebase Knowledge + Policies
             ↓
     Implementation Plan
             ↓
       ODD S# / T#
             ↓
        Implementation
```

El PRD aporta requisitos estructurados cuando existe; no sustituye la exploración del repositorio. El plan se genera cuando la complejidad o la solicitud del usuario lo justifican, no simplemente porque se haya adjuntado un documento.

### Formatos documentales

La capacidad de extracción contempla:

- PDF digital.
- PDF escaneado (puede requerir OCR; el contenido no extraído no se inventa).
- DOCX.
- DOC mediante el backend `anydoc`.
- ODT.

La extracción de documentos está separada del análisis semántico: `document-extractor` normaliza el contenido y `prd-reader` analiza los requisitos. La planificación sigue siendo independiente del formato.

### Artefactos

```text
odd/
├── CONTRACT.md
├── planning/
│   ├── CONTRACT.md
│   ├── README.md
│   ├── templates/
│   │   └── implementation-plan.md
│   └── <feature-name>.md       # si el plan es material o solicitado
└── tasks/
    └── <feature-name>.md       # trabajo SUBSTANTIAL
```

El **Implementation Plan** describe la ruta técnica y arquitectónica. El **ODD Feature Document** es la fuente de verdad del estado de ejecución. Un plan puede existir sin autorización para implementar.

---

## 🧭 Comprensión del codebase

La comprensión del repositorio es una capacidad central de MentorKit, no un paso que el PRD pueda reemplazar.

Orden de preferencia definido por el contrato de conocimiento:

```text
codebase-memory-mcp
        ↓ si no está disponible o no basta
Graphify
        ↓ si no está disponible o no basta
Fingerprinting + inspección directa
```

### ¿Qué se analiza?

- Arquitectura y límites entre módulos.
- Puntos de entrada y dependencias.
- Patrones existentes y *golden examples*.
- Módulos críticos y relaciones de dependencia.
- Impacto potencial (*blast radius*).
- Pruebas y mecanismos de verificación.
- Configuración, CI/CD y restricciones de ejecución.
- Políticas explícitas y decisiones arquitectónicas relevantes.

El proveedor de conocimiento acelera la exploración, pero **el repositorio observado sigue siendo la fuente de verdad**. Si el grafo está obsoleto o contradice el código, MentorKit valida el estado real y actualiza o descarta la inferencia.

### Niveles de evidencia

| Nivel | Significado |
|---|---|
| **Observed** | Evidencia directa en el repositorio o en la solicitud del usuario. |
| **Inferred** | Conclusión deducida a partir de evidencias. |
| **Proposed** | Solución o decisión sugerida por MentorKit. |
| **Confirmed** | Decisión aceptada explícitamente como política o requisito del proyecto. |

Una inferencia no se convierte silenciosamente en una política obligatoria.

Contrato: `odd/knowledge/CONTRACT.md`.

---

## 🧩 Arquitectura

```text
MentorKit
├── ODD Engine
│   ├── Authorize
│   ├── Explore
│   ├── Uncertainty
│   ├── Classify
│   ├── Track
│   ├── Plan / Route
│   ├── Implement
│   ├── Verify
│   └── Close
├── Engineering Capabilities
│   ├── Codebase Graph / Knowledge
│   ├── Fingerprinting
│   ├── Optional PRD Analysis
│   ├── Spec Writer
│   ├── TDD / Debugging
│   ├── Parallel Agents
│   ├── Code Review
│   └── Git
├── Durable Project Context
│   ├── Constitution / Policies
│   ├── Architecture / Patterns
│   ├── Implementation Plans
│   └── ODD Feature Documents
└── Runtime Adapters
    ├── OpenCode
    ├── Cursor
    ├── Codex
    └── Claude Code
```

La metodología ODD tiene un contrato común. Los archivos específicos de cada agente actúan como adaptadores nativos, no como implementaciones independientes de la metodología.

---

## 💾 Persistencia y continuidad

La persistencia de trabajo sustancial se basa en el documento local versionable:

```text
odd/tasks/<feature-name>.md
```

- **LocalFile:** mecanismo obligatorio para el estado durable de trabajo SUBSTANTIAL.
- **Engram:** backend de memoria opcional, cuando esté disponible.
- **Todo lists y scratchpads:** estado de ejecución temporal; no reemplazan el documento ODD.

Al reanudar una tarea, MentorKit lee el documento ODD, inspecciona el estado real del repositorio y el diff, y reconcilia cualquier memoria externa con lo observado. La memoria no autoriza cambios ni prevalece sobre el repositorio.

Detalles: `odd/PERSISTENCE.md`.

---

## 🤖 Compatibilidad con agentes

| Agente | Integración / instrucciones |
|---|---|
| **OpenCode** | `.opencode/skills/`, `.opencode/agents/`, `AGENTS.md` |
| **Cursor** | `.cursor/rules/`, `AGENTS.md` |
| **Codex** | `AGENTS.md`, `.agents/skills/` |
| **Claude Code** | `CLAUDE.md`, `.claude/skills/` |

`AGENTS.md` y los contratos bajo `odd/` describen la semántica compartida; cada runtime la adapta a sus convenciones. La profundidad de integración puede variar según las capacidades disponibles en cada agente, especialmente en proveedores MCP y conocimiento del codebase.

---

## 🖥️ Compatibilidad multiplataforma

La rama experimental incluye rutas de instalación y verificación para:

- **Linux:** scripts POSIX.
- **macOS:** scripts POSIX.
- **Windows:** PowerShell nativo, además de Git Bash/WSL2.
- **Runtime común:** `.opencode/mentorkit.py`.
- **Python:** entorno gestionado mediante `uv`.
- **CI:** workflow de smoke tests con matriz Ubuntu, macOS y Windows.

La compatibilidad está diseñada en torno a un núcleo compartido y launchers específicos por sistema operativo. La matriz de CI y las pruebas locales deben completarse antes de considerar la migración estable.

---

## 🧪 Verificación y entrega

Cuando existe un resultado determinista, se prefiere:

```text
RED → GREEN → REFACTOR
```

La verificación se ajusta al riesgo y a las prácticas reales del repositorio: pruebas, lint, typecheck, build, análisis estático y comprobaciones funcionales cuando corresponda.

Para una unidad sustancial, el flujo habitual es:

1. Implementar el T# autorizado.
2. Ejecutar las verificaciones aplicables.
3. Registrar evidencia y actualizar el documento ODD.
4. Crear un commit atómico y revisable cuando corresponda.
5. Registrar el SHA del commit en el T#.

Nunca se declara completado un trabajo sin evidencia de verificación. Un commit no implica permiso para hacer push, abrir un PR, fusionar o desplegar.

---

## 🛠️ Desarrollo y validación local

```bash
git clone --branch feature/odd-migration https://github.com/thewild001/MentorKit.git
cd MentorKit
make install
make verify
make odd-check
```

Consulta `make help` o el `Makefile` para los targets disponibles en esta versión.

Antes de probar la rama en un proyecto real, se recomienda validar al menos:

- cambio SMALL sin PRD;
- cambio SUBSTANTIAL sin PRD;
- planificación a partir de un PRD;
- PRD en PDF/DOCX/DOC/ODT;
- cambios que cruzan varios módulos;
- interrupción y reanudación;
- hallazgos fuera del alcance autorizado;
- proveedor MCP ausente o desactualizado;
- instalación y verificación en Linux, macOS y Windows;
- comportamiento de los adaptadores de los agentes disponibles.

---

## 📂 Estructura relevante

```text
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
│   │   └── spec-writer/
│   ├── mentorkit.py
│   └── requirements.lock
├── odd/
│   ├── CONTRACT.md
│   ├── PERSISTENCE.md
│   ├── knowledge/
│   │   └── CONTRACT.md
│   ├── planning/
│   │   ├── CONTRACT.md
│   │   ├── README.md
│   │   └── templates/
│   └── tasks/
├── AGENTS.md
├── CLAUDE.md
├── .cursor/
├── .agents/
├── .claude/
├── bootstrap.sh
├── bootstrap.ps1
└── Makefile
```

OpenSpec se conserva únicamente como compatibilidad legacy durante la migración experimental; el objetivo es retirar gradualmente la dependencia del flujo central una vez validados los casos reales.

---

## 🌱 Estado experimental

La evolución ODD se desarrolla en la rama:

**[`feature/odd-migration`](https://github.com/thewild001/MentorKit/tree/feature/odd-migration)**

Objetivos de esta rama:

- Adoptar ODD como capa central de orquestación.
- Mantener PRD y planificación como capacidades opcionales.
- Preservar los mecanismos de comprensión del codebase.
- Proporcionar persistencia durable y recuperación entre sesiones.
- Mantener un contrato ODD común para los agentes soportados.
- Dar soporte a Linux, macOS y Windows.
- Retirar OpenSpec progresivamente, no antes de validar la migración.

Esta rama es experimental y no debe considerarse estable solo por estar implementada. La validación funcional y el estado de CI deben comprobarse antes de integrar los cambios en `main`.

---

## 🤝 Contribuir

1. Comprende el contexto del repositorio antes de modificarlo.
2. Mantén los cambios dentro del alcance autorizado.
3. Adapta el proceso a la complejidad real del cambio.
4. Actualiza los artefactos ODD para trabajo sustancial.
5. Ejecuta las verificaciones aplicables y documenta su evidencia.
6. Utiliza commits atómicos y descriptivos.
7. Abre un PR cuando corresponda.

---

## 📜 Créditos

Desarrollado por [thewild001](https://github.com/thewild001).

Repositorio: https://github.com/thewild001/MentorKit
