---
name: prd-reader
description: >
  Interpreta PRDs previamente normalizados por document-extractor y produce un
  análisis de requisitos independiente del formato. Identifica objetivos,
  requisitos, criterios de aceptación, actores, flujos, integraciones,
  restricciones y ambigüedades para alimentar el Implementation Plan de ODD.
  Mantiene OpenSpec únicamente como adapter legacy explícito.
compatibility: opencode
metadata:
  version: "3.0"
  workflow: "odd"
  input-formats: "pdf,docx,doc,odt"
---

# PRD Reader — ODD

`prd-reader` responde a:

> **¿Qué quiere construir el usuario según el PRD?**

No responde por sí solo a:

> **¿Cómo debe implementarse en este repositorio?**

Esa segunda pregunta pertenece al Implementation Plan, generado después de
explorar el codebase.

## Responsabilidad

Separación de responsabilidades:

```
document-extractor
  ↓
normaliza PDF / DOCX / DOC / ODT
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
ODD S# / T#
```

## Paso 1 — Cargar document-extractor

Invoca:

```
skill({ name: "document-extractor" })
```

con el archivo PRD adjunto.

Si el extractor devuelve error → detén el procesamiento y reporta el motivo.

Si devuelve `needs_ocr` para un PDF escaneado → no inventes contenido. Indica que
el texto requiere OCR antes de poder generar un plan confiable.

## Paso 2 — Normalizar la entrada

Trabaja sobre una representación conceptual:

```yaml
source:
  filename: ...
  format: pdf|docx|doc|odt

content:
  text: ...

assets:
  images: ...

metadata:
  extraction_method: ...
  warnings: ...
```

El análisis semántico no debe contener ramas específicas para PDF, DOCX o DOC
salvo cuando la fidelidad de una evidencia dependa del formato.

## Paso 3 — Identificar estructura del PRD

Localiza, cuando existan:

- objetivo / problema;
- alcance;
- usuarios y actores;
- flujo principal;
- flujos alternativos;
- requisitos funcionales;
- requisitos no funcionales;
- reglas de negocio;
- datos / estado;
- validaciones;
- mensajes de error;
- integraciones;
- UI / prototipos;
- criterios de aceptación;
- dependencias;
- restricciones;
- asuntos pendientes.

El formato del PRD puede variar. Adapta el mapeo al documento real.

## Paso 4 — Construir PRD Analysis

Entrega una estructura equivalente a:

```text
PRD Analysis
├── Source
├── Objective
├── Scope
├── Actors
├── Requirements R#
├── Acceptance Criteria
├── Business Rules
├── Data / State
├── Integrations
├── UI / UX
├── Constraints
├── Terminology
└── Open Questions
```

Los identificadores R# son internos al análisis del PRD.

Mantén literalmente nombres de campos, mensajes, botones, entidades y strings
que formen parte del contrato del usuario.

## Paso 5 — Uncertainty

Marca como pregunta abierta cualquier ambigüedad material.

Ejemplos:

- comportamiento esperado no definido;
- integración externa sin contrato;
- contradicción entre dos secciones;
- prototipo que contradice el texto;
- documento referenciado pero no disponible.

No uses las preguntas abiertas para bloquear decisiones que el codebase puede
resolver de forma segura.

No conviertas una decisión de implementación en un requisito del PRD.

## Paso 6 — Transferir el control al Implementation Plan

El PRD Analysis debe alimentar a `codebase-conformist`.

El siguiente paso es:

```
PRD Analysis
+
Architecture
+
Policies / Constitution
+
Codebase Patterns
+
Graph / Blast Radius
    ↓
Implementation Plan
```

El Plan debe seguir `odd/planning/CONTRACT.md`.

Para trabajo SUBSTANTIAL, se persiste en:

```
odd/planning/<feature-name>.md
```

No conviertas automáticamente el PRD en T# sin antes analizar cómo encaja en el
repositorio.

## Compatibilidad OpenSpec

Si el usuario solicita explícitamente OpenSpec:

- puede producirse el antiguo `openspec/changes/.../spec.md`;
- se conserva el formato delta legacy;
- el análisis del PRD sigue siendo reutilizable para el flujo ODD.

OpenSpec no es el destino por defecto.

## Retorno

```
PRD procesado:     [archivo]
Formato:            [pdf|docx|doc|odt]
Extracción:         [método]
Requisitos R#:      [N]
Criterios:          [N]
Preguntas abiertas: [N]
Assets:             [N]
Plan:               [generado|pendiente]
ODD:                [SMALL|SUBSTANTIAL|pendiente]
```

## Anti-patrones

- ❌ Parsear PDF/DOCX/DOC directamente desde esta skill.
- ❌ Inventar requisitos para tapar una ambigüedad.
- ❌ Generar arquitectura sin explorar el repositorio.
- ❌ Convertir automáticamente todos los R# en T#.
- ❌ Crear un `system-spec.md` como efecto secundario.
- ❌ Asumir que una propuesta del plan ya está autorizada.
