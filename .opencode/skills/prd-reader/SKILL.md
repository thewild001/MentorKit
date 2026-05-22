---
name: prd-reader
description: >
  Parsea documentos de requisitos (PRD) y produce un spec.md estructurado para
  codebase-conformist. Delega toda extracción de archivos a document-extractor
  (sin dependencias del SO, compatible Linux y Windows). prd-reader es lógica
  pura: mapea el contenido extraído a la estructura de spec.md, identifica gaps
  con [NEEDS CLARIFICATION] y produce los artefactos en .specify/specs/.
  Invocado opcionalmente desde dev-guide cuando el usuario adjunta un PRD formal.
compatibility: opencode
metadata:
  version: "2.0"
  platform: linux-windows
  system-deps: none
---

# PRD Reader

Convierte documentos de requisitos en `spec.md` estructurado.
No contiene lógica de extracción de archivos — eso lo hace `document-extractor`.

**Separación de responsabilidades:**
```
document-extractor  ← extrae texto e imágenes del archivo (sin deps del SO)
prd-reader          ← mapea el contenido extraído a spec.md (lógica pura)
```

---

## Paso 1 — Cargar document-extractor

```
skill({ name: "document-extractor" })
```

Invoca `extract_document(prd_path, output_dir)` con:
- `prd_path`: ruta del archivo PRD adjunto
- `output_dir`: `.specify/specs/[NNN]-[slug]/`

Si el resultado contiene `error` → reporta al junior y detente.
Si hay `warnings` → menciónalos pero continúa.

---

## Paso 2 — Leer la constitution (si existe)

```python
Read(".specify/memory/constitution.md")
```

El vocabulario de dominio de la constitution tiene precedencia sobre
términos ambiguos del PRD. Si hay conflicto, usa el término de la constitution
y anótalo como suposición documentada.

---

## Paso 3 — Identificar estructura del PRD

Con el texto extraído, localiza las secciones del documento.
El formato varía entre equipos — adapta el mapeo al documento real.

**Secciones comunes en PRDs formales:**

| Sección del PRD | Mapeo en spec.md |
|---|---|
| Precondiciones | Actores y Permisos + Contexto |
| Flujo básico | Comportamiento Esperado / Flujo Principal |
| Poscondiciones | Criterios de Aceptación |
| Flujos alternativos | Flujos Alternativos + Manejo de Errores |
| Validaciones | Datos / Campos y Validaciones |
| Conceptos | Vocabulario de Dominio |
| Requisitos especiales | Integraciones + Restricciones |
| Asuntos pendientes | `[NEEDS CLARIFICATION]` |

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

---

## Paso 5 — Analizar prototipos UI

Para cada imagen en `ui-prototypes/`:

1. Identifica a qué figura corresponde (Fig 1, Fig 2…) según el texto
2. Describe los elementos visibles: formularios, campos, botones, layout
3. Extrae información no presente en el flujo textual (labels, orden de campos)
4. Documenta discrepancias con el flujo → `[NEEDS CLARIFICATION]`

---

## Paso 6 — Producir spec.md

Determina el número con `Glob(".specify/specs/*/spec.md")` y escribe:

```python
from glob import glob
existing = glob(".specify/specs/*/spec.md")
nnn = str(len(existing) + 1).zfill(3)
spec_path = f".specify/specs/{nnn}-{slug}/spec.md"
```

### Formato

```markdown
# Spec: [Nombre del Requisito]

**Número:** [NNN]
**Fuente:** PRD — `[nombre-archivo]` v[versión]
**Elaborado por:** [analista del PRD]
**Estado:** [READY | CLARIFICATION_NEEDED]

---

## Contexto
[Objetivo y alcance extraídos del PRD]

---

## Vocabulario de Dominio

| Término | Definición |
|---------|------------|
| [término exacto del PRD] | [definición exacta] |

*Usar estos términos en nombres de variables, endpoints y modelos.*

---

## Actores y Permisos

| Actor | Precondición | Restricción |
|-------|-------------|-------------|
| [rol] | [precondición] | [restricción] |

---

## Comportamiento Esperado

### Flujo Principal
[Pasos numerados — vocabulario exacto del PRD]

### Flujos Alternativos
#### [ID] — [Descripción]
[Pasos del flujo]

### Manejo de Errores

| Situación | Comportamiento | Mensaje al usuario |
|-----------|---------------|-------------------|
| [error] | [qué hace] | "[mensaje exacto del PRD]" |

---

## Datos

### Campos y Validaciones

| Campo | Tipo | Obligatorio | Reglas | Mensaje de error |
|-------|------|-------------|--------|-----------------|
| [campo] | [tipo] | Sí/No | [reglas] | "[mensaje]" |

### Estado que cambia
[Entidades / tablas afectadas]

---

## Integraciones

| Sistema | Tipo | Detalle |
|---------|------|---------|
| [sistema] | [lectura/escritura/auth] | [detalle] |

---

## Prototipos de UI

### [Fig N]: [Nombre de pantalla]
**Archivo:** `ui-prototypes/[filename]`
**Elementos:** [descripción de lo visible]
**Discrepancias:** [NEEDS CLARIFICATION: ...] ← si las hay

---

## Criterios de Aceptación
- [ ] [Condición verificable derivada de poscondiciones del PRD]

---

## Marcadores de Clarificación Pendientes
[Lista consolidada — si hay alguno, estado = CLARIFICATION_NEEDED]
```

---

## Paso 7 — Retornar control

```
PRD procesado: [nombre-archivo]
Extracción:   document-extractor ([método: Python puro | pdfplumber])
Spec:         .specify/specs/[NNN]-[slug]/spec.md
Prototipos:   [N imágenes en ui-prototypes/]
Estado:       [READY | CLARIFICATION_NEEDED]
Gaps:         [N pendientes / ninguno]
Resumen:      [2-3 oraciones describiendo la feature]
```

Si `CLARIFICATION_NEEDED` → codebase-conformist invoca spec-writer
solo para los gaps marcados, no para re-especificar el PRD.

---

## Anti-Patrones

- ❌ Intentar extraer archivos directamente — usar document-extractor
- ❌ Parafrasear el flujo del PRD — transcribir el vocabulario exacto
- ❌ Interpretar ambigüedades — marcarlas como `[NEEDS CLARIFICATION]`
- ❌ Ignorar flujos alternativos — son la lógica de error real
- ❌ Describir prototipos de memoria — solo lo visible en la imagen
- ❌ Continuar si document-extractor reporta error
