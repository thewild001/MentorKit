---
name: document-extractor
description: >
  Extrae texto e imágenes de documentos (ODT, DOCX, PDF, DOC) sin dependencias
  del sistema operativo. Compatible con Linux y Windows. ODT y DOCX usan Python
  puro (zipfile + xml, cero dependencias). PDF usa markitdown (pip install
  markitdown, sin tools del SO). DOC solicita conversión. Invocado por prd-reader
  para desacoplar la extracción del parseo.
compatibility: opencode
metadata:
  version: "2.0"
  platform: linux-windows
  pip-deps: "markitdown (solo para PDF)"
  system-deps: none
---

# Document Extractor

Extrae texto e imágenes de documentos. Sin herramientas del sistema operativo.

## Matriz de cobertura (validada en tests)

| Formato | Método | Dependencia | Resultado |
|---------|--------|-------------|-----------|
| ODT | Python puro (zipfile + xml) | Ninguna | Texto completo + imágenes |
| DOCX | Python puro (zipfile + xml) | Ninguna | Texto completo + imágenes |
| PDF digital | markitdown | pip install markitdown | Texto completo |
| PDF escaneado | — | — | Sin texto (imagen, no OCR) |
| DOC | — | — | Solicitar conversión |

---

## Paso 0 — Diagnóstico del entorno

Ejecuta con `Bash` antes de procesar:

```python
import sys, shutil
from pathlib import Path

print(f"Python {sys.version.split()[0]}")

# Siempre disponibles
import zipfile, xml.etree.ElementTree
print("✓  zipfile + xml.etree  → ODT y DOCX listos (Python puro)")

# Opcional para PDF
try:
    import markitdown
    print(f"✓  markitdown {markitdown.__version__}  → PDF listo")
    PDF_READY = True
except ImportError:
    print("○  markitdown no instalado → PDF no disponible")
    print("   Instalar: pip install markitdown")
    PDF_READY = False
```

Si el archivo es PDF y markitdown no está instalado, instálalo:

```python
import subprocess, sys
subprocess.run(
    [sys.executable, "-m", "pip", "install", "markitdown", "--quiet"],
    check=True
)
print("✓  markitdown instalado")
```

---

## Paso 1 — Extracción ODT (Python puro, cero dependencias)

```python
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

def extract_odt(file_path: str, images_dir: str) -> dict:
    result = {"text": "", "images": [], "format": "odt", "error": None}
    try:
        with zipfile.ZipFile(file_path, 'r') as z:

            # Imágenes embebidas
            img_dir = Path(images_dir)
            img_dir.mkdir(parents=True, exist_ok=True)
            for entry in z.namelist():
                if entry.startswith("Pictures/") or entry.startswith("media/"):
                    name = Path(entry).name
                    (img_dir / name).write_bytes(z.read(entry))
                    result["images"].append(str(img_dir / name))

            # Texto desde content.xml
            root = ET.parse(z.open("content.xml")).getroot()
            lines = []
            for elem in root.iter():
                tag = elem.tag.split("}")[-1] if "}" in elem.tag else elem.tag
                if tag in ("p", "h"):
                    text = "".join(elem.itertext()).strip()
                    if text:
                        lines.append(text)
                elif tag == "table-cell":
                    cell = "".join(elem.itertext()).strip()
                    if cell:
                        lines.append(f"| {cell}")

            result["text"] = "\n".join(lines)

    except zipfile.BadZipFile:
        result["error"] = "Archivo ODT inválido o corrupto"
    except KeyError as e:
        result["error"] = f"Estructura ODT inesperada: {e}"

    return result
```

---

## Paso 2 — Extracción DOCX (Python puro, cero dependencias)

```python
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

def extract_docx(file_path: str, images_dir: str) -> dict:
    result = {"text": "", "images": [], "format": "docx", "error": None}
    try:
        with zipfile.ZipFile(file_path, 'r') as z:

            # Imágenes embebidas
            img_dir = Path(images_dir)
            img_dir.mkdir(parents=True, exist_ok=True)
            for entry in z.namelist():
                if entry.startswith("word/media/"):
                    name = Path(entry).name
                    (img_dir / name).write_bytes(z.read(entry))
                    result["images"].append(str(img_dir / name))

            # Texto desde word/document.xml
            W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            root = ET.parse(z.open("word/document.xml")).getroot()
            lines = []
            for para in root.iter(f"{{{W}}}p"):
                text = "".join(
                    (t.text or "") for t in para.iter(f"{{{W}}}t")
                ).strip()
                if text:
                    lines.append(text)

            result["text"] = "\n".join(lines)

    except zipfile.BadZipFile:
        result["error"] = "Archivo DOCX inválido o corrupto"
    except KeyError as e:
        result["error"] = f"Estructura DOCX inesperada: {e}"

    return result
```

---

## Paso 3 — Extracción PDF (markitdown, pip, cross-platform)

```python
from pathlib import Path

def extract_pdf(file_path: str, images_dir: str) -> dict:
    """
    markitdown extrae texto de PDFs digitales sin herramientas del SO.
    No extrae imágenes embebidas — se referencia el PDF original.
    """
    result = {"text": "", "images": [], "format": "pdf",
              "warnings": [], "error": None}
    try:
        from markitdown import MarkItDown
        md = MarkItDown()
        conversion = md.convert(file_path)
        result["text"] = conversion.text_content

        if not result["text"].strip():
            result["warnings"].append(
                "PDF sin texto extraíble — posiblemente escaneado (imagen).\n"
                "  Convierte a ODT/DOCX en LibreOffice para extracción completa:\n"
                "  Archivo → Exportar como → ODT o DOCX"
            )
        else:
            result["warnings"].append(
                "Las imágenes del PDF no se extraen — referenciar el PDF original "
                "para los prototipos de UI."
            )

    except ImportError:
        result["error"] = (
            "markitdown no instalado.\n"
            "  Instalar: pip install markitdown"
        )
    except Exception as e:
        result["error"] = f"Error procesando PDF: {e}"

    return result
```

---

## Paso 4 — Formato DOC (binario legacy)

```python
def extract_doc(file_path: str, images_dir: str) -> dict:
    name = Path(file_path).name
    return {
        "text": "", "images": [], "format": "doc",
        "error": (
            f"El archivo '{name}' está en formato .doc (Word 97-2003).\n"
            f"Este formato binario no tiene extracción pip cross-platform.{CONVERSION_GUIDE}"
        )
    }
```

---

## Paso 5 — Dispatcher

```python
from pathlib import Path

SUPPORTED_FORMATS = {
    ".odt":  extract_odt,
    ".docx": extract_docx,
    ".pdf":  extract_pdf,
    ".doc":  extract_doc,
}

CONVERSION_GUIDE = """
  Los formatos soportados son: ODT, DOCX, PDF.

  Cómo convertir desde cualquier formato:
  ┌─────────────────────────────────────────────────────────┐
  │  Desde LibreOffice (Linux y Windows):                   │
  │    Abrir el archivo → Archivo → Guardar como → .odt     │
  │                                                         │
  │  Desde Microsoft Word (Windows):                        │
  │    Archivo → Guardar como → .docx                       │
  │                                                         │
  │  Desde Google Docs:                                     │
  │    Archivo → Descargar → OpenDocument (.odt)            │
  │                         o  Word (.docx)                 │
  └─────────────────────────────────────────────────────────┘
  Recomendación: ODT o DOCX para extracción completa
  (texto + imágenes). PDF si el archivo ya está en ese formato.
"""

def format_not_supported(file_path: str, ext: str) -> dict:
    name = Path(file_path).name
    return {
        "text": "", "images": [], "format": ext, "error": (
            f"El archivo '{name}' tiene formato '{ext}' "
            f"que no está soportado.{CONVERSION_GUIDE}"
        )
    }

def extract_document(file_path: str, output_dir: str) -> dict:
    images_dir = str(Path(output_dir) / "ui-prototypes")
    name = Path(file_path).name
    ext = Path(file_path).suffix.lower()

    print(f"\nProcesando {name} [{ext.upper() if ext else 'sin extensión'}]...")

    # Formato no reconocido
    if ext not in SUPPORTED_FORMATS:
        result = format_not_supported(file_path, ext)
        print(f"  ✗  {result['error']}")
        return result

    result = SUPPORTED_FORMATS[ext](file_path, images_dir)

    # Reporte unificado
    if result.get("error"):
        print(f"  ✗  {result['error']}")
    else:
        print(f"  ✓  Texto extraído: {len(result['text'])} caracteres")
        print(f"  ✓  Imágenes:       {len(result['images'])}")
        for w in result.get("warnings", []):
            print(f"  ⚠  {w}")

    return result
```

---

## Retorno a prd-reader

```
Formato:    [ODT | DOCX | PDF | DOC]
Método:     [Python puro | markitdown]
Texto:      [N] caracteres
Imágenes:   [N archivos en ui-prototypes/ | referencia al PDF]
Warnings:   [lista si hay]
Error:      [mensaje si falló — prd-reader detiene el flujo]
```
