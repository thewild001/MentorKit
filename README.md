<div align="center">

# MentorKit

**Ingeniería de software agéntica, con el proceso justo para cada cambio.**

Workflow para desarrolladores construido sobre OpenCode y orientado a *Organic Driven Development* (ODD).

[![Platform Smoke Test](https://github.com/thewild001/MentorKit/actions/workflows/platform-smoke.yml/badge.svg?branch=feature%2Fodd-migration)](https://github.com/thewild001/MentorKit/actions/workflows/platform-smoke.yml)
![Linux · macOS · Windows](https://img.shields.io/badge/plataformas-Linux%20%C2%B7%20macOS%20%C2%B7%20Windows-0b1220?style=flat-square&labelColor=0b1220&color=38bdf8)
![OpenCode · Cursor · Codex · Claude Code](https://img.shields.io/badge/agentes-OpenCode%20%C2%B7%20Cursor%20%C2%B7%20Codex%20%C2%B7%20Claude%20Code-0b1220?style=flat-square&labelColor=0b1220&color=6366f1)
![Estado experimental](https://img.shields.io/badge/estado-experimental-0b1220?style=flat-square&labelColor=0b1220&color=f59e0b)

[Instalación](#instalación) &nbsp;·&nbsp; [ODD](#organic-driven-development-odd) &nbsp;·&nbsp; [Codebase](#comprensión-del-codebase) &nbsp;·&nbsp; [Agentes](#compatibilidad-con-agentes) &nbsp;·&nbsp; [Plataformas](#compatibilidad-multiplataforma) &nbsp;·&nbsp; [Contribuir](#contribuir)

</div>

---

MentorKit no impone una ceremonia uniforme. Decide cuánto proceso necesita cada trabajo: desde un cambio pequeño y localizado hasta una feature sustancial que requiere contexto persistente, planificación, tareas, verificación y unidades de entrega revisables.

| | |
|---|---|
| **Workflow** | ODD, con dos rutas: `SMALL` y `SUBSTANTIAL` |
| **Runtime** | OpenCode + skills de MentorKit, con Python 3.12 gestionado por `uv` |
| **Agentes** | OpenCode · Cursor · Codex · Claude Code, con un contrato común |
| **Conocimiento del codebase** | `codebase-memory-mcp` → Graphify → fingerprinting |
| **Plataformas** | Linux · macOS · Windows (`amd64` y `arm64`) |

## Contenido

- [Instalación](#instalación)
- [Organic Driven Development (ODD)](#organic-driven-development-odd)
- [PRD opcional y planificación](#prd-opcional-y-planificación)
- [Comprensión del codebase](#comprensión-del-codebase)
- [Arquitectura](#arquitectura)
- [Persistencia y continuidad](#persistencia-y-continuidad)
- [Compatibilidad con agentes](#compatibilidad-con-agentes)
- [Compatibilidad multiplataforma](#compatibilidad-multiplataforma)
- [Verificación y entrega](#verificación-y-entrega)
- [Desarrollo y validación local](#desarrollo-y-validación-local)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Estado y alcance](#estado-y-alcance)
- [Contribuir](#contribuir)

---

## Instalación

Ejecuta el instalador desde la raíz del proyecto donde quieres usar MentorKit.

**Linux y macOS**

```bash
MENTORKIT_BRANCH=feature/odd-migration bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/feature/odd-migration/bootstrap.sh")
```

**Windows (PowerShell)**

```powershell
$env:MENTORKIT_BRANCH = "feature/odd-migration"
irm "https://raw.githubusercontent.com/thewild001/MentorKit/feature/odd-migration/bootstrap.ps1" -OutFile bootstrap.ps1
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

> [!IMPORTANT]
> `MENTORKIT_BRANCH` es obligatoria mientras esta rama no sea `main`. Sin ella, el bootstrap descarga `main`, detecta que es anterior a este flujo y se detiene con un mensaje explicativo. Windows también puede usar Git Bash o WSL2 con el comando de Linux, pero no son requisitos.

### Qué hace el instalador

| Paso | Acción |
|:---:|---|
| **1** | Descarga el release de la rama indicada y copia `.opencode/`, `odd/`, `.mentor/`, `AGENTS.md`, `CLAUDE.md`, `.cursor/`, `.claude/`, `.agents/` y `Makefile`. |
| **2** | Instala `uv` si falta y, con él, Python 3.12 y las dependencias de `requirements.lock` en un entorno aislado (`.opencode/.mentorkit/venv`). |
| **3** | Instala `codebase-memory-mcp` y lo configura en los cuatro agentes ([detalle](#codebase-memory-mcp)). |
| **4** | Verifica el conjunto (`VERIFY PASS`) y muestra el resumen final. |

Para verificar en cualquier momento:

```bash
bash .opencode/mentorkit-verify.sh          # Linux · macOS
```

```powershell
powershell -ExecutionPolicy Bypass -File .\.opencode\mentorkit-verify.ps1   # Windows
```

### Variables de entorno

| Variable | Efecto |
|---|---|
| `MENTORKIT_BRANCH` | Rama o tag a instalar (por defecto `main`). |
| `MENTORKIT_MCP_CLIENTS` | Agentes a configurar, separados por comas: `claude,codex,opencode,cursor` (por defecto, los cuatro). |
| `MENTORKIT_SKIP_MCP=1` | Omite la instalación y la verificación de `codebase-memory-mcp`. |
| `MENTORKIT_CBM_DIR` | Directorio del binario del MCP (por defecto `~/.local/bin`, o `%LOCALAPPDATA%\Programs\codebase-memory-mcp` en Windows). |

<details>
<summary><strong>Solución de problemas</strong></summary>

<br>

| Síntoma | Causa y solución |
|---|---|
| `404` al descargar, o `@ <rama>` con el nombre mal escrito | `MENTORKIT_BRANCH` viene de tu entorno con un valor incorrecto. Ejecuta `unset MENTORKIT_BRANCH` (PowerShell: `Remove-Item Env:MENTORKIT_BRANCH`) y vuelve a lanzar el comando. |
| `El release de '<rama>' es anterior a este bootstrap` | Esa rama no incluye `.opencode/mentorkit.py`. Indica una rama con la migración ODD en `MENTORKIT_BRANCH`. |
| `SHA-256 no coincide` | El binario descargado no es el esperado y no se instala nada. Reintenta y, si persiste, revisa proxies o cachés que alteren la descarga. |
| Un agente aparece como `x` en la verificación | Su archivo de configuración no es JSON/TOML válido (no se sobrescribe) o apunta a un binario inexistente. Corrígelo y ejecuta `uv run --python 3.12 .opencode/mentorkit.py configure-mcp`. |

</details>

> [!WARNING]
> Esta es una rama experimental. Instálala primero en un repositorio de prueba y valida los flujos relevantes antes de adoptarla en proyectos críticos.

---

## Organic Driven Development (ODD)

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

| Ruta | Cuándo | Qué implica |
|---|---|---|
| **SMALL** | Cambio localizado, de bajo riesgo y suficientemente comprendido. | Se implementa y verifica siguiendo los patrones existentes, sin documentación persistente por mera formalidad. |
| **SUBSTANTIAL** | Feature, migración, cambio arquitectónico, refactor transversal, lógica no trivial o trabajo que abarca varias unidades, decisiones relevantes o sesiones. | Antes de tocar código se crea `odd/tasks/<feature-name>.md`, con el objetivo, las especificaciones verificables (`S#`), las tareas (`T#`), la verificación, el registro de avance y el estado de entrega. |

### Autorización y control de alcance

- Pedir un análisis o una explicación no autoriza cambios de código.
- Un hallazgo no equivale a autorización, y los cambios de alcance la requieren.
- Generar un plan no autoriza implementarlo.
- Push, pull request, merge y despliegue son decisiones de entrega independientes.

---

## PRD opcional y planificación

**Un PRD no es un requisito para usar ODD.** Una solicitud directa es una entrada de primera clase, y la existencia de un PRD no determina si el cambio es `SMALL` o `SUBSTANTIAL`.

<table>
<tr>
<td width="50%" valign="top">

**Sin PRD**

```text
User Request
     ↓
Authorization + Exploration
     ↓
Codebase Knowledge
     ↓
Plan / Route when justified
     ↓
ODD Feature Document
(si es SUBSTANTIAL)
     ↓
S# / T# → Implementation
```

</td>
<td width="50%" valign="top">

**Con PRD**

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
 ODD S# / T# → Implementation
```

</td>
</tr>
</table>

El PRD aporta requisitos estructurados cuando existe; no sustituye la exploración del repositorio. El plan se genera cuando la complejidad o la solicitud lo justifican, no porque se haya adjuntado un documento.

**Formatos documentales.** `document-extractor` normaliza el contenido y `prd-reader` analiza los requisitos, de modo que la planificación no depende del formato:

| Formato | Notas |
|---|---|
| PDF digital | Extracción directa. |
| PDF escaneado | Puede requerir OCR. El contenido no extraído no se inventa. |
| DOCX · ODT | Extracción directa. |
| DOC | Mediante el backend `anydoc`. |

**Artefactos.** El *Implementation Plan* describe la ruta técnica y arquitectónica; el *ODD Feature Document* es la fuente de verdad del estado de ejecución. Un plan puede existir sin autorización para implementar.

```text
odd/
├── CONTRACT.md
├── planning/
│   ├── CONTRACT.md
│   ├── README.md
│   ├── templates/implementation-plan.md
│   └── <feature-name>.md       # si el plan es material o solicitado
└── tasks/
    └── <feature-name>.md       # trabajo SUBSTANTIAL
```

---

## Comprensión del codebase

Entender el repositorio es una capacidad central de MentorKit, y ningún PRD puede reemplazarla. El contrato de conocimiento define este orden de preferencia:

```text
codebase-memory-mcp
        ↓ si no está disponible o no basta
Graphify
        ↓ si no está disponible o no basta
Fingerprinting + inspección directa
```

**Qué se analiza:** arquitectura y límites entre módulos · puntos de entrada y dependencias · patrones y *golden examples* · módulos críticos y *blast radius* · pruebas y mecanismos de verificación · configuración, CI/CD y restricciones de ejecución · políticas y decisiones arquitectónicas.

El proveedor de conocimiento acelera la exploración, pero **el repositorio observado sigue siendo la fuente de verdad**. Si el grafo está obsoleto o contradice el código, MentorKit valida el estado real y actualiza o descarta la inferencia.

| Nivel de evidencia | Significado |
|---|---|
| **Observed** | Evidencia directa en el repositorio o en la solicitud del usuario. |
| **Inferred** | Conclusión deducida a partir de evidencias. |
| **Proposed** | Solución o decisión sugerida por MentorKit. |
| **Confirmed** | Decisión aceptada explícitamente como política o requisito del proyecto. |

Una inferencia nunca se convierte en silencio en una política obligatoria. Contrato: [`odd/knowledge/CONTRACT.md`](odd/knowledge/CONTRACT.md).

### codebase-memory-mcp

El instalador deja el MCP listo sin pasos manuales.

| Aspecto | Comportamiento |
|---|---|
| **Versión** | Fijada en `v0.11.0`, con el SHA-256 de cada plataforma embebido en `.opencode/mentorkit.py`. Si el hash no coincide, no se instala nada. |
| **Binario** | Linux usa el build estático `portable`. Compatible con `amd64` y `arm64` en Linux, macOS y Windows. |
| **Configuración** | Solo se escribe la entrada MCP y se conserva el resto del archivo. La primera vez se guarda una copia `.mentorkit.bak`. |
| **Verificación** | `mentorkit-verify` abre una sesión MCP real (`initialize` + `tools/list`) y comprueba que cada agente apunta a un binario existente. |
| **Seguridad** | Un archivo con JSON o TOML inválido nunca se sobrescribe, y el instalador termina con error. |

| Agente | Archivo de configuración |
|---|---|
| Claude Code | `~/.claude.json` (`mcpServers`; respeta `CLAUDE_CONFIG_DIR`) |
| Codex | `~/.codex/config.toml` (`[mcp_servers.codebase-memory-mcp]`; respeta `CODEX_HOME`) |
| OpenCode | `~/.config/opencode/opencode.json` (`mcp`; respeta `XDG_CONFIG_HOME`) |
| Cursor | `~/.cursor/mcp.json` (`mcpServers`) |

Para actualizar la versión, cambia `CBM_VERSION` y los hashes de `CBM_ASSETS` en `mentorkit.py`.

---

## Arquitectura

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

La metodología ODD tiene un contrato común. Los archivos de cada agente son adaptadores nativos, no implementaciones independientes.

---

## Persistencia y continuidad

El trabajo sustancial se persiste en un documento local y versionable: `odd/tasks/<feature-name>.md`.

| Mecanismo | Rol |
|---|---|
| **LocalFile** | Obligatorio para el estado durable de trabajo `SUBSTANTIAL`. |
| **Engram** | Backend de memoria opcional, cuando esté disponible. |
| **Todo lists y scratchpads** | Estado de ejecución temporal. No reemplazan el documento ODD. |

Al reanudar, MentorKit lee el documento ODD, inspecciona el estado real del repositorio y el diff, y reconcilia cualquier memoria externa con lo observado. La memoria no autoriza cambios ni prevalece sobre el repositorio. Detalles: [`odd/PERSISTENCE.md`](odd/PERSISTENCE.md).

---

## Compatibilidad con agentes

| Agente | Integración |
|---|---|
| **OpenCode** | `.opencode/skills/`, `.opencode/agents/`, `AGENTS.md` |
| **Cursor** | `.cursor/rules/`, `AGENTS.md` |
| **Codex** | `AGENTS.md`, `.agents/skills/` |
| **Claude Code** | `CLAUDE.md`, `.claude/skills/` |

`AGENTS.md` y los contratos bajo `odd/` describen la semántica compartida y cada runtime la adapta a sus convenciones. La profundidad de integración puede variar según las capacidades de cada agente, en especial en proveedores MCP y conocimiento del codebase.

---

## Compatibilidad multiplataforma

| Sistema | Instalación y verificación |
|---|---|
| **Linux** | Scripts POSIX |
| **macOS** | Scripts POSIX |
| **Windows** | PowerShell nativo (`bootstrap.ps1`, `install-mentorkit.ps1`), además de Git Bash y WSL2 |

El runtime común es `.opencode/mentorkit.py`, ejecutado por `uv` con Python 3.12.

### Integración continua

El workflow [`platform-smoke.yml`](.github/workflows/platform-smoke.yml) se ejecuta en Ubuntu, macOS y Windows con cada push a esta rama y con cada pull request hacia ella o hacia `main`. Instala **la rama bajo prueba**, no la base del PR, y comprueba:

- el bootstrap en un proyecto limpio;
- el runtime nativo y sus dependencias (`mentorkit-verify`);
- la instalación del MCP, el handshake real y la configuración de Claude, Codex, OpenCode y Cursor;
- la creación de documentos ODD (`odd-task`);
- los contratos de planificación, PRD multiformato, conocimiento del codebase y compatibilidad entre agentes.

Pendiente de validar a mano: Windows PowerShell 5.1 (CI usa PowerShell 7) y los escenarios funcionales de [Desarrollo y validación local](#desarrollo-y-validación-local).

---

## Verificación y entrega

Cuando hay un resultado determinista, se prefiere el ciclo `RED → GREEN → REFACTOR`. La verificación se ajusta al riesgo y a las prácticas reales del repositorio: pruebas, lint, typecheck, build, análisis estático y comprobaciones funcionales.

Para una unidad sustancial, el flujo habitual es:

1. Implementar el `T#` autorizado.
2. Ejecutar las verificaciones aplicables.
3. Registrar la evidencia y actualizar el documento ODD.
4. Crear un commit atómico y revisable cuando corresponda.
5. Registrar el SHA del commit en el `T#`.

Nunca se declara completado un trabajo sin evidencia de verificación. Un commit no implica permiso para hacer push, abrir un PR, fusionar o desplegar.

---

## Desarrollo y validación local

```bash
git clone --branch feature/odd-migration https://github.com/thewild001/MentorKit.git
cd MentorKit
make install
make verify
make odd-check
```

Consulta `make help` para ver los targets disponibles.

<details>
<summary><strong>Escenarios recomendados antes de adoptar la rama en un proyecto real</strong></summary>

<br>

- Cambio `SMALL` sin PRD.
- Cambio `SUBSTANTIAL` sin PRD.
- Planificación a partir de un PRD.
- PRD en PDF, DOCX, DOC y ODT.
- Cambios que cruzan varios módulos.
- Interrupción y reanudación.
- Hallazgos fuera del alcance autorizado.
- Proveedor MCP ausente o desactualizado.
- Instalación y verificación en Linux, macOS y Windows.
- Comportamiento de los adaptadores de cada agente disponible.

</details>

---

## Estructura del repositorio

```text
MentorKit/
├── .github/workflows/
│   └── platform-smoke.yml
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
│   ├── install-mentorkit.{sh,ps1,cmd}
│   ├── mentorkit-verify.{sh,ps1,cmd}
│   ├── mentorkit-odd-task.{sh,ps1,cmd}
│   ├── mentorkit.py                 # instalación, MCP y verificación
│   └── requirements.lock
├── odd/
│   ├── CONTRACT.md
│   ├── PERSISTENCE.md
│   ├── knowledge/CONTRACT.md
│   ├── planning/
│   └── tasks/
├── AGENTS.md
├── CLAUDE.md
├── .cursor/ · .agents/ · .claude/
├── bootstrap.sh
├── bootstrap.ps1
└── Makefile
```

OpenSpec se conserva solo por compatibilidad durante la migración. El objetivo es retirarlo del flujo central una vez validados los casos reales.

---

## Estado y alcance

La evolución ODD vive en [`feature/odd-migration`](https://github.com/thewild001/MentorKit/tree/feature/odd-migration).

| Objetivo | Estado |
|---|---|
| ODD como capa central de orquestación | Implementado |
| PRD y planificación como capacidades opcionales | Implementado |
| Comprensión del codebase con `codebase-memory-mcp` | Implementado, con CI en Linux, macOS y Windows |
| Persistencia durable y recuperación entre sesiones | Implementado |
| Contrato común para OpenCode, Cursor, Codex y Claude Code | Implementado |
| Retirada progresiva de OpenSpec | Pendiente de validar |
| Validación funcional con casos reales | Pendiente |

La rama es experimental y no debe considerarse estable solo por estar implementada. Cuando se integre en `main`, `MENTORKIT_BRANCH` dejará de ser necesaria en el comando de instalación.

---

## Contribuir

1. Comprende el contexto del repositorio antes de modificarlo.
2. Mantén los cambios dentro del alcance autorizado.
3. Adapta el proceso a la complejidad real del cambio.
4. Actualiza los artefactos ODD en trabajo sustancial.
5. Ejecuta las verificaciones aplicables y documenta su evidencia.
6. Usa commits atómicos y descriptivos.
7. Abre un PR cuando corresponda.

---

<div align="center">

Desarrollado por [thewild001](https://github.com/thewild001) · [github.com/thewild001/MentorKit](https://github.com/thewild001/MentorKit)

</div>
