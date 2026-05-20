# MentorKit

> **An Agentic Mentor for Legacy Code**
>
> Un sistema de acompañamiento para trabajar con **opencode** de forma clara, consistente y altamente alineada con la base de código existente.

![Status](https://img.shields.io/badge/status-active-success)
![OpenCode](https://img.shields.io/badge/opencode-compatible-blue)
![Documentation](https://img.shields.io/badge/docs-ready-informational)

---

## Tabla de contenidos

- [Visión general](#visión-general)
- [Por qué existe MentorKit](#por-qué-existe-mentorkit)
- [Arquitectura](#arquitectura)
- [Cómo funciona](#cómo-funciona)
- [Puesta en marcha en opencode](#puesta-en-marcha-en-opencode)
- [Flujo de trabajo recomendado](#flujo-de-trabajo-recomendado)
- [Componentes principales](#componentes-principales)
- [Buenas prácticas](#buenas-prácticas)
- [Estructura de carpetas](#estructura-de-carpetas)
- [Instalación rápida](#instalación-rápida)
- [Contribución](#contribución)
- [Licencia](#licencia)

---

## Visión general

**MentorKit** ayuda a organizar el trabajo con opencode separando claramente:

- la **configuración del agente**,
- la **especificación del trabajo**,
- la **investigación técnica**,
- y la **implementación alineada al codebase**.

El objetivo es reducir ambigüedad, evitar decisiones improvisadas y mantener la coherencia del proyecto incluso cuando el sistema crece.

---

## Por qué existe MentorKit

En muchos proyectos legacy, el problema no es solo escribir código.  
El verdadero reto es:

- entender el contexto,
- respetar la arquitectura existente,
- evitar cambios innecesarios,
- y documentar correctamente cada decisión.

MentorKit propone un flujo de trabajo que prioriza:

1. **claridad antes que velocidad**,
2. **conformidad antes que innovación**,
3. **trazabilidad antes que improvisación**.

---

## Arquitectura

MentorKit separa el repositorio en dos capas funcionales:

### `.opencode/`
Contiene la configuración estable del agente.

- Define el comportamiento esperado.
- Describe reglas, límites y preferencias.
- Suele cambiar poco.

### `.specify/`
Contiene los artefactos vivos del trabajo.

- specs,
- research,
- descripciones de PR,
- decisiones documentadas.

> Esta carpeta evoluciona con cada feature o corrección.

---

## Cómo funciona

El mecanismo sigue una lógica sencilla:

```text
Tarea recibida
   ↓
¿La tarea es clara?
   ├─ Sí → implementación directa
   └─ No → spec-writer
              ↓
         ¿Hace falta investigación?
              ├─ Sí → research.md
              └─ No
              ↓
         plan de implementación
              ↓
         confirmación explícita
              ↓
         implementación + tests
              ↓
         descripción del PR
```

---

## Puesta en marcha en opencode

### 1. Copia la configuración al proyecto destino

Desde la raíz del repositorio de MentorKit:

```bash
cp -r .opencode/ tu-proyecto/.opencode/
```

Si prefieres hacerlo manualmente, conserva exactamente la misma estructura de carpetas.

---

### 2. Abre el proyecto en opencode

Verifica que el proyecto destino contenga:

```text
.opencode/
```

y que dentro estén disponibles los skills principales:

- `spec-writer`
- `codebase-conformist`

---

### 3. Ejecuta la primera sesión

En la primera sesión, MentorKit inicializa la memoria del proyecto.

#### Resultado esperado

Se crea:

```text
.opencode/memory/constitution.md
```

Este archivo define los principios, límites y preferencias del proyecto.

---

### 4. Trabaja según el tipo de tarea

#### Caso A — Tarea simple o bug fix claro
- Se resuelve directamente.
- No requiere spec formal.
- Se mantiene el cambio mínimo necesario.

#### Caso B — Feature compleja o ambigua
- Se activa `spec-writer`.
- Se documenta la intención.
- Se marca cualquier ambigüedad con claridad.
- Si hace falta, se agrega investigación.

---

## Flujo de trabajo recomendado

### Para tareas simples
1. Identificar el archivo involucrado.
2. Entender el comportamiento esperado.
3. Aplicar el cambio quirúrgico.
4. Ejecutar tests si corresponden.
5. Documentar si el cambio lo requiere.

### Para features complejas
1. Clarificar requisitos.
2. Generar una spec.
3. Investigar el contexto técnico si aplica.
4. Construir un plan de implementación.
5. Solicitar confirmación explícita.
6. Implementar.
7. Redactar el PR.

---

## Componentes principales

### `dev-guide init`
Inicializa la base constitucional del proyecto.

**Propósito:**
- crear `constitution.md`,
- fijar principios de trabajo,
- dar contexto estable al agente.

---

### `spec-writer`
Convierte descripciones ambiguas en una especificación estructurada.

**Cuándo usarlo:**
- hay múltiples actores,
- la lógica de negocio no es trivial,
- el cambio cruza varios módulos,
- existen reglas condicionales,
- faltan detalles importantes.

**Salida esperada:**
- `spec.md`
- criterios de aceptación
- supuestos documentados
- marcadores de clarificación cuando haga falta

---

### `codebase-conformist`
Gestiona la integración del cambio respetando el estilo y patrón del proyecto.

**Qué analiza:**
- naming,
- estructura,
- patrón dominante,
- archivos de alto impacto,
- riesgos de cambio,
- cobertura de tests.

**Regla central:**
> La nueva implementación debe encajar de forma natural en el codebase.

---

## Buenas prácticas

### Haz esto
- Mantén `.opencode/` para la configuración del agente.
- Usa `.specify/` para trabajo vivo y trazabilidad.
- Especifica antes de implementar cuando exista ambigüedad.
- Investiga cuando el contexto técnico no sea evidente.
- Respeta el estilo del repositorio.

### Evita esto
- asumir comportamiento no documentado,
- introducir patrones nuevos sin justificación,
- refactorizar fuera del scope,
- modificar archivos compartidos sin revisar impacto,
- cambiar firmas públicas sin analizar sus consumidores.

---

## Estructura de carpetas

```text
tu-proyecto/
├── .opencode/
│   ├── agents/
│   ├── skills/
│   │   ├── spec-writer/
│   │   │   └── SKILL.md
│   │   └── codebase-conformist/
│   │       └── SKILL.md
│   └── memory/
│       └── constitution.md
│
└── .specify/
    └── specs/
        └── [NNN]-[slug]/
            ├── spec.md
            ├── research.md
            └── pr-description.md
```

---

## Instalación rápida

```bash
cp -r .opencode/ tu-proyecto/.opencode/
```

Luego:

1. abre el proyecto en **opencode**,
2. ejecuta la inicialización de la primera sesión,
3. verifica la creación de `constitution.md`,
4. comienza a trabajar con el flujo de specs cuando sea necesario.

---

## Contribución

Si amplías MentorKit, intenta preservar estos principios:

- claridad antes que velocidad,
- conformidad antes que innovación,
- documentación antes que suposiciones,
- trazabilidad antes que improvisación.

---

## Licencia

Define la licencia según las políticas del repositorio o el criterio del proyecto.
