"""Tests for .opencode/prd_extract.py using a synthetic DRP-like document.

The real sample PRD is internal ("USO INTERNO") and is intentionally NOT in the
repository. Set MENTORKIT_SAMPLE_PRD=/path/to/file.odt to also run it locally.
Run: python -m unittest discover -s tests -v   (stdlib only)
"""
import importlib.util
import json
import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
OPENCODE = Path(os.environ.get("MENTORKIT_OPENCODE_DIR", ROOT / ".opencode"))

spec = importlib.util.spec_from_file_location("prd_extract", OPENCODE / "prd_extract.py")
px = importlib.util.module_from_spec(spec)
sys.modules["prd_extract"] = px
spec.loader.exec_module(px)

# (label, content) rows of the layout table. Content "" = label only.
ROWS = [
    ("Precondiciones", "El usuario tiene sesión iniciada."),
    ("Flujo de eventos", ""),
    ("Flujo básico Crear vía de ingreso", ""),
    ("", "El usuario pulsa Nuevo."),
    ("", "El sistema muestra el formulario."),
    ("", "El usuario completa (*)Nombre: Campo de texto, máx. 50."),
    ("Pos-condiciones", "La vía queda registrada."),
    ("Flujos alternativos", ""),
    ("Flujo alternativo 3.a Cancelar", ""),
    ("", "El usuario cancela y no se guarda nada."),
    ("Validaciones", ""),
    ("", "Campo de texto Nombre: obligatorio, máximo 50 caracteres."),
    ("Conceptos", ""),
    ("", "Vía de ingreso: forma de acceso del aspirante."),
    ("Requisitos especiales", "Ninguno."),
    ("Asuntos pendientes", "Definir siglas."),
    ("Prototipo", ""),
]
HEADING = "2.1 Descripción textual del requisito"


def _odt_cell(text, span):
    # ODF emits covered-table-cell placeholders for the columns a spanned cell covers.
    return (f'<table:table-cell table:number-columns-spanned="{span}" office:value-type="string">'
            f"<text:p>{escape(text)}</text:p></table:table-cell>"
            + "<table:covered-table-cell/>" * (span - 1))


def build_odt(path, with_heading=True):
    rows = []
    for label, content in ROWS:
        cells = ""
        if label and content:
            cells = _odt_cell(label, 3) + _odt_cell(content, 9)
        elif label:
            cells = _odt_cell(label, 12)
        else:
            cells = _odt_cell(content, 12)
        rows.append(f"<table:table-row>{cells}</table:table-row>")
    cols = "<table:table-column/>" * 12
    heading = f'<text:h text:outline-level="2">{HEADING}</text:h>' if with_heading else ""
    content = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
        'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
        'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
        'xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" '
        'xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" '
        'xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" '
        'xmlns:xlink="http://www.w3.org/1999/xlink"><office:body><office:text>'
        '<text:h text:outline-level="1">Introducción</text:h>'
        "<text:p>Texto informativo que no es requisito.</text:p>"
        f"{heading}"
        f"<table:table>{cols}{''.join(rows)}</table:table>"
        "</office:text></office:body></office:document-content>"
    )
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("mimetype", "application/vnd.oasis.opendocument.text")
        z.writestr("content.xml", content)


W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"


def build_docx(path):
    def p(text, style=None):
        ppr = f'<w:pPr><w:pStyle w:val="{style}"/></w:pPr>' if style else ""
        return f"<w:p>{ppr}<w:r><w:t>{escape(text)}</w:t></w:r></w:p>"

    body = p("Introducción", "Heading1") + p("Texto informativo.") + p(HEADING, "Heading2")
    body += p("Precondiciones") + p("Sesión iniciada.")
    doc = (f'<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="{W}"><w:body>'
           f"{body}</w:body></w:document>")
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("[Content_Types].xml", '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>')
        z.writestr("word/document.xml", doc)


class ExtractOdt(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.odt = self.tmp / "drp.odt"
        build_odt(self.odt)

    def run_extract(self, **kw):
        return px.extract(self.odt, self.tmp / "out", **kw)

    def test_outputs_exist(self):
        _res, md, js = self.run_extract()
        self.assertTrue(md.exists() and js.exists())
        json.loads(js.read_text(encoding="utf-8"))

    def test_flow_structure(self):
        res, _md, _js = self.run_extract()
        req = res["requirement"]
        self.assertIsNotNone(req)
        self.assertEqual(req["preconditions"], ["El usuario tiene sesión iniciada."])
        steps = req["basic_flow"]["steps"]
        self.assertEqual([s["n"] for s in steps], [1, 2, 3])
        self.assertEqual(req["basic_flow"]["title"], "Crear vía de ingreso")
        self.assertEqual([f["id"] for f in req["alternative_flows"]], ["3.a"])
        self.assertEqual(req["special_requirements"], ["Ninguno."])
        self.assertEqual(req["pending_issues"], ["Definir siglas."])

    def test_context_is_informative_only(self):
        res, md, _js = self.run_extract()
        text = md.read_text(encoding="utf-8")
        self.assertIn("informativo", text)
        self.assertIn("Texto informativo que no es requisito.", text)
        self.assertEqual(len(res["requirement"]["basic_flow"]["steps"]), 3)

    def test_required_marker_preserved(self):
        _res, md, _js = self.run_extract()
        self.assertIn("\\*", md.read_text(encoding="utf-8"))

    def test_missing_heading_warns(self):
        build_odt(self.odt, with_heading=False)
        res, _md, _js = self.run_extract()
        self.assertTrue(any("Descripción textual" in w for w in res["warnings"]))

    def test_custom_heading(self):
        res, _md, _js = self.run_extract(from_heading=r"descripci[oó]n\s+textual")
        self.assertIsNotNone(res["requirement"])


class ExtractDocxAndErrors(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())

    def test_docx_generic_output(self):
        f = self.tmp / "a.docx"
        build_docx(f)
        res, md, _js = px.extract(f, self.tmp / "o")
        self.assertEqual(res["source"]["format"], "docx")
        self.assertIsNone(res["requirement"])
        self.assertIn("Sesión iniciada.", md.read_text(encoding="utf-8"))

    def test_unsupported_extension(self):
        f = self.tmp / "a.txt"
        f.write_text("x")
        with self.assertRaises(px.ExtractError):
            px.extract(f, self.tmp / "o")

    def test_not_a_zip(self):
        f = self.tmp / "bad.odt"
        f.write_text("no es un zip")
        with self.assertRaises(Exception):
            px.extract(f, self.tmp / "o")

    def test_zip_path_traversal_not_written(self):
        f = self.tmp / "evil.odt"
        build_odt(f)
        with zipfile.ZipFile(f, "a") as z:
            z.writestr("../escape.txt", "x")
        px.extract(f, self.tmp / "o")
        self.assertFalse((self.tmp / "escape.txt").exists())


@unittest.skipUnless(os.environ.get("MENTORKIT_SAMPLE_PRD"), "sample PRD not provided")
class RealSample(unittest.TestCase):
    def test_sample(self):
        out = Path(tempfile.mkdtemp())
        res, _md, _js = px.extract(os.environ["MENTORKIT_SAMPLE_PRD"], out)
        self.assertIsNotNone(res["requirement"])
        self.assertGreater(len(res["requirement"]["basic_flow"]["steps"]), 0)


if __name__ == "__main__":
    unittest.main()
