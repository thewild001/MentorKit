---
name: document-extractor
description: >
  Extrae y normaliza contenido de documentos para MentorKit. Soporta ODT, DOCX,
  PDF y DOC sin depender de aplicaciones de escritorio. ODT y DOCX usan Python
  puro; DOC usa firecrawl-anydoc; PDF usa markitdown con fallback anydoc.
  Invocado por prd-reader para desacoplar ingestión de interpretación.
compatibility: opencode
metadata:
  version: "2.1"
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
| ODT | Python puro | ✅ | ✅ | Extrae `Pictures/` |
| DOCX | Python puro | ✅ | ✅ | Extrae `word/media/` |
| PDF digital | markitdown → anydoc | ✅ | ⚠️ | Las imágenes se conservan como referencia al PDF |
| PDF escaneado | markitdown/anydoc | ❌ | — | Se detecta y se reporta como `needs_ocr` |
| DOC | anydoc | ✅ | ⚠️ | Documento binario Word 97–2003; imágenes no se materializan en `ui-prototypes/` |

`firecrawl-anydoc` soporta actualmente Word `.doc`, `.docx` y otros formatos mediante una API común de Markdown. MentorKit usa esa capacidad para cubrir el formato binario `.doc` sin requerir Microsoft Word, LibreOffice, COM ni ejecutables específicos del SO. citeturn859555search5turn859555search7

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

## Paso 1 — ODT

Usa el parser Python puro existente:

- extrae párrafos y encabezados;
- conserva contenido de tablas;
- extrae imágenes embebidas a `ui-prototypes/`.

## Paso 2 — DOCX

Usa el parser Python puro existente:

- extrae párrafos;
- conserva texto;
- extrae imágenes embebidas a `ui-prototypes/`.

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
    ".odt": extract_odt,
    ".docx": extract_docx,
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
Método:       [Python puro | markitdown | anydoc]
Texto:        [N] caracteres
Imágenes:     [N]
OCR needed:   [sí/no]
Warnings:     [lista]
Error:        [mensaje si falló]
```

## Seguridad y portabilidad

- tratar los documentos del usuario como entrada no confiable;
- no ejecutar macros;
- no invocar Word, LibreOffice, COM o aplicaciones del SO;
- mantener el flujo compatible con Linux, macOS y Windows;
- no usar lógica específica del shell para interpretar el contenido documental.
