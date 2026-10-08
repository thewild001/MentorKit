---
name: spec-writer
description: >
  Clarifica requisitos y produce Specs S# y Tasks T# para el documento ODD de
  una unidad de trabajo sustancial. No crea automáticamente un spec.md ni
  requiere system-spec. Usa OpenSpec solo cuando se solicita compatibilidad legacy.
compatibility: opencode
metadata:
  version: "2.0"
  workflow: "odd"
---

# Spec Writer — ODD

Su función es convertir una solicitud sustancial o ambigua en requisitos verificables
sin imponer ceremonia innecesaria.

## Paso 1 — Contexto

Lee la constitución si existe:

```
.mentor/constitution.md
```

Si solo existe el legacy:

```
openspec/memory/constitution.md
```

Lee también el código relevante antes de formular decisiones técnicas.

## Paso 2 — Clarificación

Cubre, en orden:

1. comportamiento esperado;
2. actores/permisos;
3. datos/estado;
4. integraciones;
5. criterios de aceptación.

Marca internamente las preguntas que bloquean la implementación. No escribas
`[NEEDS CLARIFICATION]` como contenido final.

No preguntes algo que pueda resolverse con evidencia del codebase o una convención
existente.

## Paso 3 — Specs ODD

Produce:

```
S1. <comportamiento verificable>
- Acceptance: <resultado observable>
- Checks: <cómo se verificará>

S2. ...
```

Conserva literalmente strings de error, ejemplos y restricciones que formen parte
del contrato.

## Paso 4 — Tasks

Descompón en unidades revisables:

```
T1 — <unidad>
  Spec: S1
  Route: <archivo/módulo>
T2 — <unidad>
  Spec: S1,S2
  Route: <archivo/módulo>
```

Cada T# debe poder cerrarse con evidencia y un commit atómico cuando el trabajo sea
sustancial.

## Paso 5 — Documento

El documento canónico es:

```
odd/tasks/<feature-name>.md
```

Usa las secciones:

- Objective
- Specs
- Tasks
- Verification
- Log
- Delivery

L1 debe conservar la solicitud original literalmente.

## Compatibilidad OpenSpec

Si el usuario solicita explícitamente mantener OpenSpec:

- puedes generar `openspec/specs/.../spec.md`;
- conserva el formato delta legacy;
- no conviertas esta compatibilidad en el flujo ODD por defecto.

## Checklist

- [ ] no hay decisiones bloqueantes sin resolver;
- [ ] S# son verificables;
- [ ] T# referencian S#;
- [ ] acceptance/checks son observables;
- [ ] el documento existe antes del primer source write.
