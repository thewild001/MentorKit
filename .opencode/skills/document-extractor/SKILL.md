---
name: document-extractor
description: >
  Extrae texto e imágenes de documentos (ODT, DOCX, PDF, HTML, TXT, MD, RTF)
  sin dependencias del sistema operativo. Compatible con Linux y Windows.
  ODT, DOCX, TXT y MD usan Python puro (cero dependencias). PDF y HTML usan
  markitdown (pip). RTF usa striprtf (pip). DOC solicita conversión con guía
  clara. Ambas dependencias pip se instalan automáticamente por el instalador.
  Invocado por prd-reader para desacoplar extracción del parseo.
compatibility: opencode
metadata:
  version: "3.0"
  platform: linux-windows
  pip-deps: "markitdown, striprtf"
  system-deps: none
---

# Document Extractor

Extrae texto e imágenes de documentos. Sin herramientas del sistema operativo.

## Cobertura de formatos

| Formato | Texto | Imágenes | Dependencia |
|---------|-------|----------|-------------|
| ODT | ✓ completo | ✓ completo | Python puro |
| DOCX | ✓ completo | ✓ completo | Python puro |
| TXT | ✓ completo | — | Python puro |
| MD | ✓ completo | — | Python puro |
| PDF digital | ✓ completo | referencia | markitdown (pip) |
| HTML | ✓ completo | — | markitdown (pip) |
| RTF | ✓ completo | — | striprtf (pip) |
| PDF escaneado | — sin texto | referencia | markitdown (pip) |
| DOC | — | — | solicitar conversión |

---

## Paso 0 — Diagnóstico del entorno

Ejecuta al inicio con `Bash`:

```python
import sys, shutil
from pathlib import Path

print(f"Python {sys.version.split()[0]}")

# Python puro — siempre disponibles
for mod, desc in [
    ("zipfile",              "ODT y DOCX — texto + imagenes"),
    ("xml.etree.ElementTree","ODT y DOCX — parseo XML"),
]:
    __import__(mod.split(".")[0])
    print(f"  + {mod:30} {desc}")

# pip — instaladas por el instalador de MentorKit
for pkg, mod, desc in [
    ("markitdown", "markitdown",         "PDF y HTML"),
    ("striprtf",   "striprtf.striprtf",  "RTF"),
]:
    try:
        __import__(mod.split(".")[0])
        import importlib.metadata
        ver = importlib.metadata.version(pkg)
        print(f"  + {pkg:30} {desc} ({ver})")
    except ImportError:
        print(f"  ! {pkg:30} NO instalado — pip install {pkg}")
```

Si falta alguna dependencia pip, instálala automáticamente:

```python
import subprocess, sys
for pkg in ["markitdown", "striprtf"]:
    subprocess.run(
        [sys.executable, "-m", "pip", "install", pkg, "--quiet"],
        check=False
    )
```

---

## Paso 1 — ODT (Python puro, cero dependencias)

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
        result["error"] = "Archivo ODT invalido o corrupto"
    except KeyError as e:
        result["error"] = f"Estructura ODT inesperada: {e}"
    return result
```

---

## Paso 2 — DOCX (Python puro, cero dependencias)

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
        result["error"] = "Archivo DOCX invalido o corrupto"
    except KeyError as e:
        result["error"] = f"Estructura DOCX inesperada: {e}"
    return result
```

---

## Paso 3 — PDF y HTML (markitdown, pip, cross-platform)

```python
def extract_with_markitdown(file_path: str, fmt: str) -> dict:
    """
    PDF  -> texto de PDFs digitales (sin tools del SO)
    HTML -> texto de páginas web o documentos HTML
    """
    result = {"text": "", "images": [], "format": fmt,
              "warnings": [], "error": None}
    try:
        from markitdown import MarkItDown
        conversion = MarkItDown().convert(file_path)
        result["text"] = conversion.text_content

        if fmt == "pdf":
            if not result["text"].strip():
                result["warnings"].append(
                    "PDF sin texto extraible — posiblemente escaneado.\n"
                    "     Convierte a ODT/DOCX en LibreOffice para extraccion completa."
                )
            else:
                result["warnings"].append(
                    "Imagenes del PDF no extraidas — referencia el PDF original."
                )
    except ImportError:
        result["error"] = (
            "markitdown no instalado.\n"
            "     Instala: pip install markitdown"
        )
    except Exception as e:
        result["error"] = f"Error procesando {fmt.upper()}: {e}"
    return result
```

---

## Paso 4 — RTF (striprtf, pip, cross-platform)

```python
def extract_rtf(file_path: str, images_dir: str) -> dict:
    """
    RTF -> texto usando striprtf (pure Python, pip, sin tools del SO)
    """
    result = {"text": "", "images": [], "format": "rtf", "error": None}
    try:
        from striprtf.striprtf import rtf_to_text
        with open(file_path, encoding="utf-8", errors="replace") as f:
            raw = f.read()
        result["text"] = rtf_to_text(raw)
        if not result["text"].strip():
            result["error"] = (
                "RTF sin texto extraible.\n"
                "     Convierte a ODT/DOCX en LibreOffice."
            )
    except ImportError:
        result["error"] = (
            "striprtf no instalado.\n"
            "     Instala: pip install striprtf"
        )
    except Exception as e:
        result["error"] = f"Error procesando RTF: {e}"
    return result
```

---

## Paso 5 — TXT y MD (Python puro, cero dependencias)

```python
def extract_text_file(file_path: str, fmt: str) -> dict:
    """
    TXT y MD -> lectura directa con Python built-in
    """
    result = {"text": "", "images": [], "format": fmt, "error": None}
    try:
        with open(file_path, encoding="utf-8", errors="replace") as f:
            result["text"] = f.read()
    except Exception as e:
        result["error"] = f"Error leyendo {fmt.upper()}: {e}"
    return result
```

---

## Paso 6 — DOC (solicitar conversión con guía clara)

```python
CONVERSION_GUIDE = """
  Formatos soportados: ODT, DOCX, PDF, HTML, TXT, MD, RTF

  Como convertir a un formato soportado:
  +----------------------------------------------------------+
  |  LibreOffice (Linux y Windows):                         |
  |    Abrir -> Archivo -> Guardar como -> .odt  o  .docx   |
  |                                                          |
  |  Microsoft Word (Windows):                              |
  |    Archivo -> Guardar como -> .docx                     |
  |                                                          |
  |  Google Docs:                                           |
  |    Archivo -> Descargar -> OpenDocument (.odt)          |
  |                        o  Word (.docx)                  |
  +----------------------------------------------------------+
  Recomendacion: ODT o DOCX (texto completo + imagenes)
"""

def extract_doc(file_path: str, images_dir: str) -> dict:
    from pathlib import Path
    name = Path(file_path).name
    return {
        "text": "", "images": [], "format": "doc",
        "error": (
            f"'{name}' esta en formato .doc (Word 97-2003).\n"
            f"Este formato binario no tiene solucion pip cross-platform."
            f"{CONVERSION_GUIDE}"
        )
    }
```

---

## Paso 7 — Dispatcher principal

```python
from pathlib import Path

DISPATCHERS = {
    ".odt":  lambda p, d: extract_odt(p, d),
    ".docx": lambda p, d: extract_docx(p, d),
    ".pdf":  lambda p, d: extract_with_markitdown(p, "pdf"),
    ".html": lambda p, d: extract_with_markitdown(p, "html"),
    ".htm":  lambda p, d: extract_with_markitdown(p, "html"),
    ".rtf":  lambda p, d: extract_rtf(p, d),
    ".txt":  lambda p, d: extract_text_file(p, "txt"),
    ".md":   lambda p, d: extract_text_file(p, "md"),
    ".doc":  lambda p, d: extract_doc(p, d),
}

def extract_document(file_path: str, output_dir: str) -> dict:
    name = Path(file_path).name
    ext  = Path(file_path).suffix.lower()
    images_dir = str(Path(output_dir) / "ui-prototypes")

    print(f"\nProcesando {name}...")

    if ext not in DISPATCHERS:
        result = {
            "text": "", "images": [], "format": ext,
            "error": (
                f"'{name}' tiene formato '{ext}' no soportado."
                f"{CONVERSION_GUIDE}"
            )
        }
    else:
        result = DISPATCHERS[ext](file_path, images_dir)

    # Reporte unificado
    if result.get("error"):
        print(f"  x  {result['error']}")
    else:
        print(f"  +  Texto:    {len(result['text'])} caracteres")
        print(f"  +  Imagenes: {len(result['images'])}")
        for w in result.get("warnings", []):
            print(f"  !  {w}")

    return result
```

---

## Retorno a prd-reader

```
Formato:    [ODT|DOCX|PDF|HTML|TXT|MD|RTF|DOC]
Metodo:     [Python puro | markitdown | striprtf]
Texto:      [N] caracteres
Imagenes:   [N] archivos en ui-prototypes/
Warnings:   [lista si hay]
Error:      [mensaje con guia de conversion si aplica]
```

Si hay `error` → prd-reader detiene el flujo y muestra el mensaje al junior.