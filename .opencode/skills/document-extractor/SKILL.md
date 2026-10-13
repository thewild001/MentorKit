---
name: document-extractor
description: >
  Extrae y normaliza contenido de documentos para MentorKit. Soporta ODT, DOCX,
  PDF y DOC sin depender de aplicaciones de escritorio. ODT y DOCX usan el
  extractor nativo `.opencode/prd_extract.py` (solo biblioteca estándar) que
  conserva la estructura de tablas y detecta documentos DRP; DOC usa
  firecrawl-anydoc; PDF usa markitdown con fallback anydoc.
  Invocado por prd-reader para desacoplar ingestión de interpretación.
compatibility: opencode
metadata:
  version: "3.0"
  platform: linux-macos-windows
  system-deps: none
  pip-deps: "markitdown + firecrawl-anydoc"
---

# Document Extractor

Convierte documentos PRD a una representación normalizada para que el resto de
MentorKit no dependa del formato de entrada.

> **IMPORTANTE — Usar siempre el wrapper de MentorKit:** todo Python del skill
> debe ejecutarse mediante `.opencode/mentorkit-python.sh`.

## Matriz de cobertura

| Formato | Método | Texto | Imágenes | Observaciones |
|---------|--------|-------|----------|---------------|
| ODT | `prd_extract.py` | ✅ estructura de tablas | ✅ solo las referenciadas | Detecta DRP y emite `.drp.json` |
| DOCX | `prd_extract.py` | ✅ estructura de tablas | ✅ solo las referenciadas | Probado con fixture sintético; no con documentos reales |
| PDF digital | markitdown → anydoc | ✅ | ⚠️ | Las imágenes se conservan como referencia al PDF |
| PDF escaneado | markitdown/anydoc | ❌ | — | Se detecta y se reporta como `needs_ocr` |
| DOC | anydoc | ✅ | ⚠️ | Documento binario Word 97–2003; imágenes no se materializan en `ui-prototypes/` |

`firecrawl-anydoc` soporta actualmente Word `.doc`, `.docx` y otros formatos mediante una API común de Markdown. MentorKit usa esa capacidad para cubrir el formato binario `.doc` sin requerir Microsoft Word, LibreOffice, COM ni ejecutables específicos del SO.

## Paso 0 — Diagnóstico

Para validar dependencias:

```bash
.opencode/mentorkit-python.sh -c "
import sys
print(f'Python {sys.version.split()[0]}')
import markitdown
import anydoc
print('✓ markitdown')
print('✓ anydoc')
"
```

No instales dependencias desde el skill si ya están gestionadas por
`.opencode/requirements.lock`.

## Paso 1 — ODT y DOCX (comando `extract`)

```bash
.opencode/mentorkit-python.sh .opencode/mentorkit.py extract <archivo> \
  [--out DIR] [--from-heading REGEX]
```

Salida por defecto en `.mentorkit/runtime/extract/<nombre>/` (o `--out`):

| Archivo | Contenido |
|---------|-----------|
| `<stem>.normalized.md` | Markdown con jerarquía de encabezados, listas y tablas reales |
| `<stem>.drp.json` | Estructura de requisito (solo si se detecta DRP) |
| `assets/` | Imágenes referenciadas por el documento (prototipos) |

Al terminar imprime un resumen con conteos y **diagnósticos**
(`info` / `warning`). Los diagnósticos son hallazgos sobre el propio documento
(inconsistencias, saltos de numeración, validaciones sobre campos inexistentes).
`prd-reader` debe convertirlos en Open Questions; no los corrijas en silencio.

### Documentos DRP ("Descripción de Requisitos por Proceso")

Estos documentos mezclan información de control (portada, historial de
cambios, índice, introducción) con la parte normativa. **Solo la sección
«Descripción textual del requisito» es contrato.** El extractor:

- localiza ese encabezado (`--from-heading` permite cambiar la expresión);
- aplana la tabla de maquetación de 12 columnas y reconstruye: precondiciones,
  flujo básico (pasos), pos-condiciones, flujos alternativos (`3.a`, `4.b.2.a`),
  validaciones, conceptos, requisitos especiales, asuntos pendientes y prototipos;
- conserva la parte previa como contexto, marcada como informativa.

Limitaciones que debes respetar:

- los pasos del flujo básico **no están numerados en el archivo**; se numeran
  por fila. Los ids de flujos alternativos siguen la convención «el id es el
  paso que la alternativa sustituye» (con frecuencia, la fila siguiente a la
  comprobación): `numbering.alt_id_delta` lo documenta como información, no
  como error. Los ids se conservan tal como están escritos; no los renumeres;
- la convención se observó en varios DRP de la misma familia, pero no es un
  estándar: si una referencia «paso N» es ambigua, pregunta al analista;
- el extractor no interpreta imágenes. Abre cada imagen de `assets/` con la
  herramienta de lectura y compárala con `form_fields`; las contradicciones
  texto/prototipo son Open Questions.

## Paso 3 — PDF

Camino principal:

```python
from markitdown import MarkItDown
conversion = MarkItDown().convert(file_path)
text = conversion.text_content
```

Fallback:

```python
import anydoc
text = anydoc.to_markdown(file_path)
```

Si ambos fallan, devuelve un error explícito.

Si no existe texto extraíble, marca:

```yaml
warnings:
  - type: needs_ocr
    message: "PDF sin texto extraíble; requiere OCR."
```

No presentes un PDF escaneado como PRD procesado correctamente.

## Paso 4 — DOC

```python
import anydoc
text = anydoc.to_markdown(file_path)
```

El parser valida el contenido binario del documento y no ejecuta macros ni
objetos embebidos. Si falla, devuelve un error explícito con el motivo.

No conviertas silenciosamente el archivo mediante Word/LibreOffice ni dependas
de un ejecutable instalado en el sistema.

Las imágenes embebidas no se consideran extraídas por esta ruta. Si son
importantes para requisitos de UI, conserva la referencia al documento original
y repórtalo como warning para que prd-reader lo tenga en cuenta.

## Paso 5 — Dispatcher

```python
SUPPORTED_FORMATS = {
    ".odt": extract_odt,    # mentorkit.py extract → prd_extract.py
    ".docx": extract_docx,  # mentorkit.py extract → prd_extract.py
    ".pdf": extract_pdf,
    ".doc": extract_doc,
}
```

Devuelve siempre una estructura equivalente a:

```yaml
source:
  filename: "<name>"
  format: "<odt|docx|pdf|doc>"

content:
  text: "<normalized text>"

assets:
  images: []

metadata:
  extraction_method: "<method>"
  warnings: []
  errors: []
```

El resultado debe ser suficiente para que `prd-reader` trabaje sin conocer la
implementación específica del extractor.

## Retorno a prd-reader

```
Formato:      [ODT | DOCX | PDF | DOC]
Método:       [prd_extract | markitdown | anydoc]
Texto:        [N] caracteres
Imágenes:     [N]
OCR needed:   [sí/no]
Warnings:     [lista]
DRP:          [sí/no] · diagnósticos [info/warning]
Error:        [mensaje si falló]
```

## Seguridad y portabilidad

- tratar los documentos del usuario como entrada no confiable (el extractor no ejecuta nada, no usa `extractall`, limita el tamaño del XML y copia solo imágenes referenciadas);
- los documentos de ejemplo marcados como «USO INTERNO» no se versionan en el repositorio;
- no ejecutar macros;
- no invocar Word, LibreOffice, COM o aplicaciones del SO;
- mantener el flujo compatible con Linux, macOS y Windows;
- no usar lógica específica del shell para interpretar el contenido documental.
