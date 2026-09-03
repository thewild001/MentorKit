# MentorKit — Mecanismo Agentico de Desarrollo

**Versión:** 5.0
**Compatibilidad:** OpenCode
**Orientado a:** Desarrollo y mantenimiento de sistemas legacy con soporte a desarrolladores junior

---

## Descripción

MentorKit es un mecanismo agentico de desarrollo diseñado para resolver el problema
del conocimiento implícito en sistemas legacy. Actúa como mentor computacional para
desarrolladores junior, extrayendo las convenciones arquitectónicas no documentadas
de una base de código existente y gobernando el proceso de desarrollo mediante un
workflow estructurado con gates de validación explícitos.

Esta versión (5.0) integra cuatro principios de diseño:

**1. Conformidad primero**
El código generado debe ser indistinguible del código existente del proyecto.
Las convenciones del codebase tienen precedencia sobre las buenas prácticas generales.

**2. Especificación antes de implementación**
Para features complejas, los requisitos se formalizan antes de tocar el codebase —
ya sea desde un PRD del equipo de análisis (opcional) o mediante clarificación
estructurada con spec-writer.

**3. Decisiones de alto riesgo escaladas al council**
Las ambigüedades arquitectónicas, conflictos de patrones y planes de alto impacto
son evaluados por un panel de 5 advisors independientes antes de comprometer
cualquier dirección.

**4. Flexibilidad sin fricción**
El mecanismo opera igual con o sin PRDs adjuntos, con o sin spec formal,
en cualquier lenguaje y framework.

---

## Estructura

```
# Lo que se instala en el proyecto:
.opencode/
├── skills/
│   ├── codebase-conformist/    # Skill principal — gobierna todo el ciclo
│   │   └── SKILL.md
│   ├── codebase-graph/         # Grafo de conocimiento del codebase
│   │   └── SKILL.md
│   ├── spec-writer/            # Clarificación de requisitos (opcional)
│   │   └── SKILL.md
│   ├── prd-reader/             # Parseo de PRDs adjuntos (opcional)
│   │   └── SKILL.md
│   ├── document-extractor/     # Extracción de texto de documentos
│   │   └── SKILL.md
│   └── llm-council/            # Panel multi-advisor para decisiones complejas
│       └── SKILL.md
├── agents/
│   └── MentorKit4.0.md         # Agente orquestador
├── requirements.in              # Top-level deps (constraints suaves)
├── requirements.lock            # Versiones exactas + SHA256 (LA GARANTÍA)
├── mentorkit-python.sh          # Wrapper: siempre ejecuta Python del venv
├── mentorkit-verify.sh          # Verificación standalone (exit 0/1)
└── install-mentorkit.sh         # Instalador one-liner

# Lo que se genera durante el install (gitignored):
.opencode/.mentorkit/
├── venv/                        # Python 3.12.13 + 60 paquetes
└── python-path.txt              # Ruta absoluta del Python del venv

# Lo que el agente genera durante el uso (no se instala):
.specify/
├── memory/
│   └── constitution.md         # Creado en sesión 1
└── specs/
    └── [NNN]-[feature-slug]/
        ├── spec.md             # Requisitos formalizados
        ├── ui-prototypes/      # Imágenes extraídas del PRD (si aplica)
        ├── research.md         # Investigación técnica (si aplica)
        └── pr-description.md   # Descripción del PR al cerrar el ciclo
```

A nivel raíz del repo:
```
.gitlab-ci.yml                   # CI: 4 jobs paralelos verifican las 7 garantías en cada push
```

---

## Componentes

### MentorKit5.0 (Agente primario)
Punto de entrada del desarrollador. Orquesta la secuencia completa:
inicializa la constitution en la primera sesión, detecta PRDs adjuntos de forma
silenciosa y condicional, carga codebase-conformist y gestiona la confirmation gate
y el tracking de progreso con TodoWrite.

### codebase-conformist (Skill principal)
Gobierna el ciclo completo de desarrollo en 5 pasos: constitution → intake →
fingerprinting → plan con Phase -1 Gates → implementación → git → PR description.
Decide cuándo invocar spec-writer, prd-reader y llm-council. Extrae el conocimiento
implícito del codebase mediante un protocolo de fingerprinting de 5 dimensiones y
lo codifica como restricciones de generación.

### codebase-graph (Skill de grafo)
Construye y mantiene un grafo de conocimiento del codebase usando Graphify.
Enriquece el fingerprinting con god nodes, rationale nodes, estructura de
comunidades y conexiones entre módulos. Persiste el grafo en graphify-out/
entre sesiones.

### spec-writer (Skill opcional)
Se activa para features complejas o ambiguas sin PRD disponible. Produce un spec.md
con marcadores explícitos `[NEEDS CLARIFICATION]` en lugar de asumir comportamientos
no especificados. No se invoca para bugs ni features con requisitos claros.

### prd-reader (Skill opcional)
Se activa cuando el equipo de análisis adjunta un PRD formal (odt, docx, pdf, doc).
Extrae el contenido estructurado (flujos, validaciones, conceptos, requisitos especiales)
y los prototipos de UI embebidos, y los traduce al formato spec.md. Cuando el PRD está
completo, reemplaza a spec-writer eliminando el paso de clarificación.

### document-extractor (Skill de soporte)
Extrae texto e imágenes de documentos (ODT, DOCX, PDF, DOC) sin dependencias del
sistema operativo. ODT y DOCX usan Python puro. PDF usa markitdown con fallback
a firecrawl-anydoc.

### llm-council (Skill de escalación)
Panel de 5 advisors independientes (Contrarian, First Principles, Expansionist,
Outsider, Executor) con peer review anónimo y síntesis por chairman. Se activa en
4 puntos específicos: conflicto de patrones en fingerprinting, plan de alto riesgo
antes de la confirmation gate, patrón nuevo sin precedente durante implementación,
y diagnóstico de síntoma en modo exploración.

### constitution.md (Memoria persistente del proyecto)
Documento creado en la primera sesión que codifica los principios inmutables del
proyecto: stack aprobado, patrones arquitectónicos establecidos, zonas sensibles,
restricciones de seguridad y convenciones de naming. Persiste entre sesiones y
resuelve el problema de continuidad de contexto.

---

## Ciclo completo

```
Sesión inicia
     │
     ├── ¿Existe constitution? ──NO──► Crear constitution.md
     │
     ├── ¿Hay PRD adjunto? ──SÍ──► prd-reader → spec.md
     │         │
     │         NO
     │
     ▼
codebase-conformist
     │
     ├── Paso -1: Leer constitution
     │
     ├── Paso 0:  ¿Existe spec.md? ──SÍ──► Consumir spec (saltando intake)
     │                │
     │               NO
     │                ├── Feature clara    → Paso 1
     │                ├── Feature compleja → spec-writer → Paso 1
     │                ├── Bug             → Paso 1
     │                └── Síntoma vago    → llm-council (P4) → Paso 1
     │
     ├── Paso 1:  Fingerprinting
     │                └── [Conflicto patrones] → llm-council (P1)
     │
     ├── Paso 1.5: Research phase (features complejas)
     │
     ├── Paso 2:  Plan de implementación con markers [P]
     │                └── [Alto riesgo / Gate fallido] → llm-council (P2)
     │
     ├── Paso 2.5: Phase -1 Constitutional Gates
     │
     ├── ⛔ CONFIRMATION GATE — esperar "go"
     │
     ├── Paso 3:  Implementación (TodoWrite tracking)
     │                └── [Patrón nuevo] → llm-council (P3)
     │
     ├── Paso 4:  Git commits atómicos
     │
     └── Paso 5:  PR description
```

---

## Instalación

### One-liner (recomendado)

Desde la raíz de cualquier proyecto:

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/main/bootstrap.sh")
```

El script descarga mentorkit (tarball, ~73KB), copia `.opencode/`, `Makefile`
y `.gitlab-ci.yml` al directorio actual, y luego corre el installer
end-to-end que **garantiza Python 3.12.13 LTS** (lo descarga si el sistema no
lo tiene), crea un venv aislado e instala las dependencias **pinneadas con
SHA256** desde `requirements.lock`.

### Modos del instalador

```bash
bash install-mentorkit.sh           # install / repair (default)
bash install-mentorkit.sh --verify  # solo verifica, no modifica nada
bash install-mentorkit.sh --fix     # verifica y repara lo que falle
bash install-mentorkit.sh --help    # ayuda
```

`--verify` y `--fix` son útiles en CI, pre-commit, y para diagnosticar
entornos rotos sin tocar nada hasta confirmar.

### Las 7 garantías

Después del install, el entorno está **garantizado** en 7 dimensiones:

| # | Garantía | Job CI |
|---|---|---|
| 1 | Python 3.12.13 pin exacto | `verify-install` |
| 2 | Lock con SHA256 (60 paquetes, `--universal`) | `verify-platform-coverage` |
| 3 | uv autocontenido en el venv | `verify-install` |
| 4 | `mentorkit-verify.sh` PASS (4 imports) | `verify-install` |
| 5 | Lock cross-platform (linux/macos/windows) | `verify-platform-coverage` |
| 6 | System-spec stays in sync | `verify-archive-spec` |
| 7 | Specs con historial en git | `verify-spec-history` |

Para los detalles de implementación de cada check, ver `.gitlab-ci.yml`.

Para regenerar el lock (después de editar `requirements.in`):

```bash
uv pip compile .opencode/requirements.in \
    --universal \
    --python-version 3.12 \
    --generate-hashes \
    -o .opencode/requirements.lock
```

### Setup rápido con Makefile (recomendado)

El repo incluye un `Makefile` raíz con los comandos más usados. Después de la
instalación inicial (o del one-liner remoto), los targets disponibles son:

```bash
make help      # mostrar todos los targets
make install   # crear/reparar el venv (idempotente)
make verify    # check rápido: Python + 4 imports críticos
make clean     # borrar venv (fuerza install fresh)
make ci        # simula el pipeline de GitLab CI localmente
```

### Instalación manual (sin el script)

```bash
# 1. Copiar estructura al proyecto
cp -r .opencode/ tu-proyecto/

# 2. Crear venv con Python 3.12 garantizado
uv python install 3.12                          # descarga Python 3.12 si falta
uv venv --python 3.12 tu-proyecto/.opencode/.mentorkit/venv

# 3. Instalar deps desde el lock (versiones + hashes exactos)
uv pip install --python tu-proyecto/.opencode/.mentorkit/venv/bin/python \
    -r tu-proyecto/.opencode/requirements.lock

# 4. Verificar
bash tu-proyecto/.opencode/mentorkit-verify.sh

# 5. Primera sesión — el agente crea automáticamente:
#    .specify/memory/constitution.md
#    Completar el stack y los patrones del proyecto en ese archivo
```

---

## Continuous Integration

El repo incluye `.gitlab-ci.yml` en la raíz. Define 4 jobs paralelos en
stage `verify` que ejecutan las 7 garantías en cada push (jobs sin
`needs:`, corren independientes y se cachean a sí mismos).

**Imagen:** `ubuntu:22.04` (sin Python preinstalado). El installer debe
traer todo desde cero. Si esto pasa, sabemos que cualquiera puede clonar el
repo en una máquina limpia y reproducir el entorno.

**Filosofía:** "probado en mi máquina" no es una garantía. El CI es la única
forma de mantener las 7 garantías en el tiempo — un PR futuro no podrá romper
el lock, degradar Python, dejar specs sin archivar, o tener un lock no
universal sin que CI lo detecte.

**Flujo del job:**

```
1) bash .opencode/install-mentorkit.sh --fix
   ↓
2) bash .opencode/mentorkit-verify.sh --json > verify.json
   ↓
3) jq -e '.python_ok and .all_deps_ok' verify.json
   ↓ PASS                          ↓ FAIL
   ✅ garantías OK                 ❌ diagnóstico: qué dep falla + exit 1
```

**Cache:** el venv (~334MB) se cachea entre runs. La key se invalida cuando
cambia `.opencode/requirements.lock`, garantizando install fresco al actualizar
deps. Si la cache se restaura corrupta (symlinks rotos entre máquinas),
`install --fix` auto-repara.

**Artifact:** `verify.json` se guarda por 1 semana (incluso si el job falla)
para inspección post-mortem.

**Lo que el CI NO hace** (intencional):

- No ejecuta los skills ni los agentes — eso es responsabilidad de las sesiones.
- No hace lint de los scripts bash — es defensivo (errores bash son ruidosos).
- No usa la imagen `python:3.12` — eso enmascararía bugs del installer.

Para ejecutarlo manualmente:

```bash
# Simula exactamente lo que hace CI
bash .opencode/install-mentorkit.sh --fix
bash .opencode/mentorkit-verify.sh --json | tee verify.json
jq -e '.python_ok and .all_deps_ok' verify.json > /dev/null
```

---

## Activación del agente

En OpenCode, seleccionar el agente `MentorKit4.0` con Tab antes de iniciar la sesión.

---

## Créditos metodológicos

- **Codebase fingerprinting y conformity-first:** diseño propio orientado a legacy systems
- **LLM Council:** adaptado de la metodología de Andrej Karpathy
- **Spec-driven development:** inspirado en github/spec-kit
- **Scaffolding para juniors:** basado en la teoría de Zona de Desarrollo Próximo (Vygotsky)
