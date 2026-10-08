---
name: odd-orchestrator
description: >
  Orquestador Organic Driven Development para MentorKit. Decide proporcionalmente
  cuánto proceso necesita cada cambio: autorización, exploración, clasificación
  SMALL/SUBSTANTIAL, persistencia recuperable, ejecución por unidades de trabajo,
  verificación y cierre. Sustituye el workflow obligatorio centrado en OpenSpec
  sin eliminar las capacidades de fingerprinting, investigación, TDD, council,
  revisión y Git.
compatibility: opencode
metadata:
  version: "1.0"
  workflow: "organic-driven-development"
---

# ODD Orchestrator — OpenCode Adapter

The runtime-neutral ODD semantics live in `odd/CONTRACT.md`. This skill is the OpenCode adapter that exposes those semantics through OpenCode's native skill/runtime mechanisms. It may add execution details, but must not redefine the contract.

ODD no es un formato de spec alternativo. Es la capa que decide **cuándo hace falta una spec, un plan, un documento persistente o ninguno**.

## 1. Authorization Gate

Primero determina si el mensaje autoriza un cambio.

### Read-only

No modifica archivos cuando el usuario pide:

- explicar
- investigar
- analizar
- revisar
- diagnosticar
- comparar
- estimar

Puede leer, buscar, inspeccionar y ejecutar comprobaciones no destructivas.

### Authorized change

Una solicitud explícita de:

- implementar
- corregir
- modificar
- refactorizar
- añadir
- eliminar
- migrar
- actualizar

autoriza el cambio dentro del alcance indicado.

Si existe una decisión material que no puede inferirse con seguridad, pregunta antes de escribir. No confundas una pregunta de diseño con una autorización general.

## 2. Explore

Antes de implementar:

1. Lee la constitución/gobernanza disponible.
2. Inspecciona el módulo objetivo.
3. Busca una plantilla de oro.
4. Comprueba callers/dependencias y blast radius.
5. Usa `codebase-graph` cuando esté disponible.
6. Usa `llm-council` solo si existe conflicto, riesgo alto o patrón nuevo.
7. Determina qué información falta para implementar con seguridad.

Constitución preferida:

```
.mentor/constitution.md
```

Compatibilidad legacy:

```
openspec/memory/constitution.md
```

No inicialices una constitución solo para completar el ritual. Si no existe, continúa con defaults seguros y ofrece crearla cuando el proyecto lo necesite.

## 3. Classify

Clasifica después de explorar.

### SMALL

Usa SMALL cuando:

- el cambio está completamente entendido;
- el alcance es contenido;
- existe un patrón claro;
- el blast radius es bajo;
- el contexto puede recuperarse razonablemente desde la solicitud + git diff;
- no hay decisiones abiertas relevantes.

Ejemplos: typo, ajuste localizado, test de regresión simple, cambio de configuración pequeño.

**Ruta:**

```
Implement → Verify → Commit → Close
```

No crees `odd/tasks/*.md` por defecto.

### SUBSTANTIAL

Usa SUBSTANTIAL cuando una o más condiciones impliquen pérdida de contexto o riesgo:

- cruza varios módulos;
- tiene lógica de negocio no trivial;
- requiere múltiples tareas;
- requiere investigación;
- necesita decisiones de arquitectura;
- tiene blast radius significativo;
- debe sobrevivir a una interrupción/sesión nueva;
- una revisión útil necesita una unidad de trabajo explícita.

**Ruta:**

```
Create feature document → Specs → Tasks → Implement task-by-task
→ Verify → Work-unit commit → Review/PR → Close
```

El heurístico de tamaño es orientativo, no una regla rígida.

## 4. Feature Document

Para SUBSTANTIAL crea **antes del primer source write**:

```
odd/tasks/<feature-name>.md
```

Debe contener:

- `## Objective`
- `## Specs`
- `## Tasks`
- `## Verification`
- `## Log`
- `## Delivery`

### Specs

Usa IDs estables `S1`, `S2`, etc.

Cada S# debe expresar comportamiento verificable. Conserva literalmente strings de error, ejemplos y restricciones que formen parte del contrato.

### Tasks

Usa IDs estables `T1`, `T2`, etc.

Cada tarea referencia uno o más S# y define una ruta concreta de implementación.

### Log

`L1` debe conservar la solicitud original literalmente.

Las correcciones, decisiones, hallazgos y evidencias se agregan como nuevas entradas. No reescribas la historia.

## 5. Spec Writer

`spec-writer` deja de producir obligatoriamente `openspec/.../spec.md`.

Para ODD:

- resuelve ambigüedades;
- propone S#;
- agrega criterios de aceptación;
- devuelve el contenido para `odd/tasks/<feature>.md`;
- no crea un system-spec;
- no requiere delta ADDED/MODIFIED/REMOVED.

Solo usa OpenSpec si el usuario pide explícitamente compatibilidad con el workflow legacy.

## 6. Execution

`TodoWrite` puede representar el estado de ejecución, pero el documento ODD es la persistencia durable.

Ejecuta las tareas en el orden necesario. Paraleliza solo tareas realmente independientes.

Superpowers siguen siendo capacidades de ejecución:

- brainstorming
- writing-plans
- TDD
- systematic-debugging
- parallel agents
- code review
- verification-before-completion
- finishing-a-development-branch

ODD decide **cuándo** usarlas; no las reemplaza.

## 7. Test-first

Cuando exista un test determinista con resultado esperado claro:

```
RED → GREEN → REFACTOR
```

Si no aplica, explica por qué y ejecuta las comprobaciones funcionales pertinentes.

## 8. Work-unit Commit

Cada unidad sustancial completada debe terminar con:

1. implementación;
2. verificación;
3. commit atómico Conventional Commit;
4. identidad del commit registrada en el T# correspondiente.

El commit es candidato natural de revisión. No uses un checkbox TODO como frontera de revisión.

Push, PR y merge requieren una decisión independiente.

## 9. Scope Control

Un hallazgo no equivale a autorización.

Si descubres:

- otro bug;
- deuda técnica;
- una refactorización conveniente;
- una mejora fuera del objetivo;

regístralo y no lo implementes salvo que el usuario amplíe el alcance.

Si el usuario cambia el alcance, actualiza los S#/T# afectados y preserva el trabajo válido ya completado.

## 10. Resume / Handoff

Para continuar una sesión:

1. lee el documento local completo;
2. inspecciona el código y git diff reales;
3. si existe espejo Engram, recupera el documento completo;
4. reconcilia ambos contra el estado observado;
5. nunca trates una memoria faltante como éxito;
6. continúa desde el siguiente T# incompleto.

La memoria nunca sobreescribe la realidad observada del repositorio.

## 11. Persistence Adapter

Conceptualmente:

```
ODD Persistence
├── LocalFile   ← obligatorio
├── Engram      ← opcional
└── Future      ← extensible
```

Si Engram no está disponible, marca el espejo como pendiente y continúa con el archivo local.

## 12. Close

Una feature queda cerrada cuando:

- los S# autorizados están implementados;
- los checks aplicables fueron ejecutados;
- los resultados están registrados;
- cada T# relevante tiene commit;
- el siguiente paso de delivery está explícito.

El cierre no implica merge automático.

## Anti-patrones

- Crear specs persistentes para cada cambio pequeño.
- Pedir confirmación para cada typo o cambio trivial ya autorizado.
- Escribir código antes de crear el feature document de trabajo sustancial.
- Tratar Engram como fuente de verdad superior al repositorio.
- Expandir scope por iniciativa propia.
- Convertir ODD en otro sistema rígido de plantillas.
- Eliminar OpenSpec de golpe durante la migración experimental.
