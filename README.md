# MentorKit — Mecanismo Agentico de Desarrollo

**Versión:** 2.0
**Compatibilidad:** OpenCode
**Orientado a:** Desarrollo y mantenimiento de sistemas legacy con soporte a desarrolladores junior

---

## Descripción

MentorKit es un mecanismo agentico de desarrollo diseñado para resolver el problema
del conocimiento implícito en sistemas legacy. Actúa como mentor computacional para
desarrolladores junior, extrayendo las convenciones arquitectónicas no documentadas
de una base de código existente y gobernando el proceso de desarrollo mediante un
workflow estructurado con gates de validación explícitos.

Esta versión (2.0) integra cuatro principios de diseño:

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
│   ├── spec-writer/            # Clarificación de requisitos (opcional)
│   │   └── SKILL.md
│   ├── prd-reader/             # Parseo de PRDs adjuntos (opcional)
│   │   └── SKILL.md
│   └── llm-council/            # Panel multi-advisor para decisiones complejas
│       └── SKILL.md
└── agents/
    └── dev-guide.md            # Agente orquestador — lleva la plantilla embebida

# Lo que el agente genera durante el uso (no se instala):
.specify/
├── memory/
│   └── constitution.md         # Creado en sesión 1 — plantilla embebida en dev-guide
└── specs/
    └── [NNN]-[feature-slug]/
        ├── spec.md             # Requisitos formalizados
        ├── ui-prototypes/      # Imágenes extraídas del PRD (si aplica)
        ├── research.md         # Investigación técnica (si aplica)
        └── pr-description.md  # Descripción del PR al cerrar el ciclo
```

---

## Componentes

### dev-guide (Agente primario)
Punto de entrada del desarrollador junior. Orquesta la secuencia completa:
inicializa la constitution en la primera sesión, detecta PRDs adjuntos de forma
silenciosa y condicional, carga codebase-conformist y gestiona la confirmation gate
y el tracking de progreso con TodoWrite.

### codebase-conformist (Skill principal)
Gobierna el ciclo completo de desarrollo en 5 pasos: constitution → intake →
fingerprinting → plan con Phase -1 Gates → implementación → git → PR description.
Decide cuándo invocar spec-writer, prd-reader y llm-council. Extrae el conocimiento
implícito del codebase mediante un protocolo de fingerprinting de 5 dimensiones y
lo codifica como restricciones de generación.

### spec-writer (Skill opcional)
Se activa para features complejas o ambiguas sin PRD disponible. Produce un spec.md
con marcadores explícitos `[NEEDS CLARIFICATION]` en lugar de asumir comportamientos
no especificados. No se invoca para bugs ni features con requisitos claros.

### prd-reader (Skill opcional)
Se activa cuando el equipo de análisis adjunta un PRD formal (odt, docx, pdf, doc).
Extrae el contenido estructurado (flujos, validaciones, conceptos, requisitos especiales)
y los prototipos de UI embebidos, y los traduce al formato spec.md. Cuando el PRD está
completo, reemplaza a spec-writer eliminando el paso de clarificación.

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

```bash
# 1. Copiar estructura al proyecto
cp -r .opencode/ tu-proyecto/

# 2. Verificar el model ID en tu instalación
opencode models | grep sonnet
# Actualizar model: en dev-guide.md si es necesario

# 3. Primera sesión — el agente crea automáticamente:
#    .specify/memory/constitution.md
#    Completar el stack y los patrones del proyecto en ese archivo

# 4. Para usar PRDs:
#    Adjuntar el archivo directamente en el chat al inicio de la sesión
```

---

## Activación del agente

En OpenCode, seleccionar el agente `dev-guide` con Tab antes de iniciar la sesión.

---

## Créditos metodológicos

- **Codebase fingerprinting y conformity-first:** diseño propio orientado a legacy systems
- **LLM Council:** adaptado de la metodología de Andrej Karpathy
- **Spec-driven development:** inspirado en github/spec-kit
- **Scaffolding para juniors:** basado en la teoría de Zona de Desarrollo Próximo (Vygotsky)
