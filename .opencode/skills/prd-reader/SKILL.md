---
name: prd-reader
description: >
  Parsea documentos de requisitos (PRD) y produce un spec.md estructurado para
  codebase-conformist. Delega toda extracción de archivos a document-extractor
  (sin dependencias del SO, compatible Linux y Windows). prd-reader es lógica
  pura: mapea el contenido extraído a la estructura de spec.md (formato delta),
  identifica gaps con [NEEDS CLARIFICATION] y produce los artefactos en
  openspec/changes/. Invocado opcionalmente desde MentorKit cuando el usuario
  adjunta un PRD formal.
compatibility: opencode
metadata:
  version: "2.1"
  platform: linux-windows
  system-deps: none
  format: delta-based
---

# PRD Reader

Convierte documentos de requisitos en `spec.md` estructurado (formato delta).
No contiene lógica de extracción de archivos — eso lo hace `document-extractor`.

**Separación de responsabilidades:**
```
document-extractor  ← extrae texto e imágenes del archivo (sin deps del SO)
prd-reader          ← mapea el contenido extraído a spec.md (lógica pura)
archive-spec        ← mergea la spec en openspec/system-spec.md (delta-based)
```

**Principio de output (v2.1):** La spec que produces se mergea al
`system-spec.md` mediante `make archive-spec`. Por eso la parte
mergeable está en formato delta (ADDED/MODIFIED/REMOVED). El contexto
PRD completo (vocabulario, prototipos UI, validaciones, mensajes)
se preserva en la sección `## Contexto` al final del archivo, que
NO se mergea al system-spec pero queda archivada para referencia futura.

---

## Paso 1 — Cargar document-extractor

```
skill({ name: "document-extractor" })
```

Invoca `extract_document(prd_path, output_dir)` con:
- `prd_path`: ruta del archivo PRD adjunto
- `output_dir`: `openspec/changes/[NNN]-[slug]/`

Si el resultado contiene `error` → reporta al junior y detente.
Si hay `warnings` → menciónalos pero continúa.

---

## Paso 2 — Leer la constitution y el system-spec

```python
constitution = Read("openspec/memory/constitution.md")

system_spec = Read("openspec/system-spec.md")
```

El vocabulario de dominio de la constitution tiene precedencia sobre
términos ambiguos del PRD. Si hay conflicto, usa el término de la constitution
y anótalo como suposición documentada.

Si `system-spec.md` existe (desde cualquiera de los dos paths), identifica los **dominios ya establecidos**
para que el `## Dominio` de la spec use uno existente si encaja.
NO crees un dominio nuevo si el requirement cabe en uno existente.

---

## Paso 3 — Identificar estructura del PRD

Con el texto extraído, localiza las secciones del documento.
El formato varía entre equipos — adapta el mapeo al documento real.

**Secciones comunes en PRDs formales y a qué parte de la spec van:**

| Sección del PRD | Va a... | Por qué |
|---|---|---|
| Precondiciones | `## Contexto` (rich) | No es mergeable, es contexto del PRD |
| Flujo básico | Requirements ADDED (scenarios) | El "happy path" se modela como scenarios WHEN/THEN |
| Poscondiciones | Requirements ADDED (scenarios) | Cada poscondición es un scenario verificable |
| Flujos alternativos | Requirements ADDED (scenarios) | Un scenario adicional por cada flujo alternativo |
| Validaciones | Requirements ADDED (scenarios) | Cada validación es un scenario con WHEN/THEN |
| Mensajes de error | Requirements ADDED (texto del req) | Texto literal va en el cuerpo del requirement |
| Conceptos | `## Contexto > Vocabulario` | No es mergeable |
| Requisitos especiales | Requirements ADDED | Casos con dependencias externas van como requirements separados |
| Prototipos UI | `## Contexto > Prototipos` | No es mergeable (imágenes + descripción) |
| Asuntos pendientes | NO van al archivo | Se resuelven en chat, no en el spec archivado |

**Regla de transcripción:** Mantén el vocabulario exacto del PRD.
Usa los mismos nombres de campos, botones, mensajes y entidades.
No parafrasees — transcribe.

---

## Paso 4 — Identificar gaps

Marca ambigüedades con `[NEEDS CLARIFICATION: pregunta específica]`:

```
Activar cuando:
  □ El flujo menciona comportamiento pero no especifica el resultado exacto
  □ Una validación referencia un sistema externo sin detallar el contrato
  □ Los prototipos muestran elementos no descritos en el flujo textual
  □ Los "asuntos pendientes" del PRD están sin resolver
  □ Hay inconsistencias entre flujo básico y flujos alternativos
  □ El PRD referencia otro documento no disponible

NO activar para:
  □ Decisiones de implementación (cómo, no qué)
  □ Patrones de código — los cubre el fingerprinting
  □ Stack tecnológico — lo cubre la constitution
```

**Importante:** los `[NEEDS CLARIFICATION]` se resuelven en el chat con
el dev. NO los dejes en el archivo final — el spec archivado debe estar
libre de ambigüedades.

---

## Paso 5 — Analizar prototipos UI

Para cada imagen en `ui-prototypes/`:

1. Identifica a qué figura corresponde (Fig 1, Fig 2…) según el texto
2. Describe los elementos visibles: formularios, campos, botones, layout
3. Extrae información no presente en el flujo textual (labels, orden de campos)
4. Documenta discrepancias con el flujo → `[NEEDS CLARIFICATION]`

Toda la info de prototipos va en `## Contexto > Prototipos de UI`, no
en el delta. Los prototipos son metadata del feature, no requirements.

---

## Paso 6 — Producir spec.md (formato delta + contexto rico)

Determina el número con `Glob` en `openspec/specs/` y escribe en openspec/changes/:

```python
from glob import glob
existing = glob("openspec/specs/*/spec.md")
nnn = str(len(existing) + 1).zfill(3)
spec_path = f"openspec/changes/{nnn}-{slug}/spec.md"
```

Escribe el contenido en `spec_path`:

### Formato (delta arriba + contexto rico abajo)

```markdown
# Spec: [Nombre del Requisito]

**Número:** [NNN]
**Fuente:** PRD — `[nombre-archivo]` v[versión]
**Slug:** [kebab-case-slug]

---

## Status: Active
## Dominio: [nombre-del-dominio]
## Fecha: [YYYY-MM-DD de hoy]

## ADDED Requirements

### Requirement: [nombre-corto-y-descriptivo]
[Cuerpo del requirement — 1-3 párrafos con la semántica del feature.
Incluye el vocabulario del PRD literal: nombres de campos, mensajes,
botones. NO parafrasees.]

#### Scenario: [happy-path-derivado-del-flujo-basico]
- **WHEN** [precondición + acción del usuario]
- **THEN** [poscondición esperada]

#### Scenario: [flujo-alternativo-1]
- **WHEN** [condición alternativa]
- **THEN** [resultado alternativo]

#### Scenario: [validacion-1]
- **WHEN** [input que viola validación]
- **THEN** [mensaje literal del PRD: "[texto exacto]"]

### Requirement: [otro-requirement-si-hay-uno-separable]
[Cuerpo.]

#### Scenario: [escenario]
- **WHEN** ...
- **THEN** ...

---

## Contexto (NO se mergea al system-spec)

> Esta sección se preserva en el spec archivado (`openspec/specs/archive/.../spec.md`)
> para referencia futura del equipo. NO aparece en el system-spec.

### Vocabulario de Dominio

| Término | Definición |
|---------|------------|
| [término exacto del PRD] | [definición exacta] |

*Usar estos términos en nombres de variables, endpoints y modelos.*

### Actores y Permisos

| Actor | Precondición | Restricción |
|-------|-------------|-------------|
| [rol] | [precondición] | [restricción] |

### Flujo Principal (transcripción literal)
[Pasos numerados del PRD — vocabulario exacto]

### Flujos Alternativos (transcripción literal)
[Cada flujo del PRD]

### Manejo de Errores

| Situación | Comportamiento | Mensaje al usuario |
|-----------|---------------|-------------------|
| [error] | [qué hace] | "[mensaje exacto del PRD]" |

### Campos y Validaciones

| Campo | Tipo | Obligatorio | Reglas | Mensaje de error |
|-------|------|-------------|--------|-----------------|
| [campo] | [tipo] | Sí/No | [reglas] | "[mensaje]" |

### Integraciones

| Sistema | Tipo | Detalle |
|---------|------|---------|
| [sistema] | [lectura/escritura/auth] | [detalle] |

### Prototipos de UI

#### [Fig N]: [Nombre de pantalla]
**Archivo:** `ui-prototypes/[filename]`
**Elementos:** [descripción de lo visible]
```

### Reglas del formato:

- **Top (mergeable):** `## Status` + `## Dominio` + `## Fecha` + `## ADDED Requirements`
  (o MODIFIED/REMOVED si aplica). Esta es la parte que `archive-spec` parsea.
- **`---` separador:** la línea `---` antes de `## Contexto` indica el límite
  entre el delta mergeable y el contexto del PRD. No la omitas.
- **Bottom (no mergeable):** toda la transcripción rica del PRD. Vive en
  el archivo archivado, no contamina el system-spec.
- **`## Dominio`:** usa uno existente del system-spec si encaja. Solo crea
  un dominio nuevo si el feature no cabe en ninguno existente.
- **Vocabulary literal:** mensajes de error, nombres de campos, labels
  de botones — todo transcrito entre comillas del PRD, no parafraseado.
- **Sin `[NEEDS CLARIFICATION]` en el archivo:** los resuelves en chat
  con el dev. El spec archivado está libre de ambigüedades.

---

## Paso 7 — Retornar control

```
PRD procesado:     [nombre-archivo]
Extracción:        document-extractor ([método: Python puro | markitdown])
Spec:              openspec/changes/[NNN]-[slug]/spec.md
Dominio:           [nombre]
ADDED:             [N]   MODIFIED: [N]   REMOVED: [N]
Prototipos:        [N imágenes en ui-prototypes/]
Gaps:              [resueltos en chat | N pendientes]
Formato:           delta (listo para 'make archive-spec')

Resumen:           [2-3 oraciones describiendo la feature]
```

Si quedaron gaps sin resolver → codebase-conformist los trabaja con
el dev ANTES de archivar. No archivar un spec con `[NEEDS CLARIFICATION]`.

---

## Anti-Patrones

- ❌ Intentar extraer archivos directamente — usar document-extractor
- ❌ Parafrasear el flujo del PRD — transcribir el vocabulario exacto
- ❌ Dejar `[NEEDS CLARIFICATION]` en el archivo (se resuelven en chat)
- ❌ Mezclar el contexto del PRD dentro del delta (sección `## Contexto`
   después de `---`, no antes)
- ❌ Crear dominios nuevos sin justificación (reusar los del system-spec)
- ❌ Omitir la línea `---` antes de `## Contexto` (sin ella, el script
   intenta parsear el vocabulario como si fuera un requirement)
- ❌ Continuar si document-extractor reporta error
