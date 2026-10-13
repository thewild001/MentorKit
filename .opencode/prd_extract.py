#!/usr/bin/env python3
"""MentorKit PRD extractor (stdlib only, Linux / macOS / Windows).

Reads ODT and DOCX requirement documents and writes a normalized, structure-
preserving representation for `prd-reader`:

  <out>/<stem>.normalized.md   readable Markdown (context vs. normative part)
  <out>/<stem>.drp.json        the same content as data, plus diagnostics
  <out>/assets/                embedded images (prototypes, figures)

Why this exists: generic converters flatten the big layout tables used by
"Descripción de Requisitos por Proceso" (DRP) documents into wide, mostly empty
tables, losing the flow hierarchy and the implicit step numbering that the
alternative flows refer to ("Se pasa al paso 3 del flujo básico").

The documents are treated as untrusted input: nothing is executed, archives are
never extracted wholesale, and only declared image members are copied.
"""
from __future__ import annotations

import json
import re
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

NORMATIVE_HEADING = r"descripci[oó]n\s+textual\s+del\s+requisito"
MAX_XML_BYTES = 64 * 1024 * 1024  # refuse absurd members (zip bombs)

NS = {
    "office": "urn:oasis:names:tc:opendocument:xmlns:office:1.0",
    "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
    "table": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
    "draw": "urn:oasis:names:tc:opendocument:xmlns:drawing:1.0",
    "style": "urn:oasis:names:tc:opendocument:xmlns:style:1.0",
    "fo": "urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0",
    "xlink": "http://www.w3.org/1999/xlink",
    "svg": "urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0",
}
W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
R = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
A = "http://schemas.openxmlformats.org/drawingml/2006/main"
PR = "http://schemas.openxmlformats.org/package/2006/relationships"


def q(prefix, name):
    return "{%s}%s" % (NS[prefix], name)


def local(el):
    return el.tag.rsplit("}", 1)[-1]


class ExtractError(Exception):
    pass


# ---------------------------------------------------------------------------
# Inline text with bold / italic preserved
# ---------------------------------------------------------------------------

def _render_runs(runs):
    """runs: [(text, bold, italic)] -> markdown with markers outside whitespace."""
    merged = []
    for text, b, i in runs:
        if not text:
            continue
        text = text.replace("*", "\\*")  # literal asterisks (e.g. "(*)" = required) stay literal
        if merged and merged[-1][1] == b and merged[-1][2] == i:
            merged[-1][0] += text
        else:
            merged.append([text, b, i])
    out = []
    for text, b, i in merged:
        if (b or i) and text.strip():
            lead = text[: len(text) - len(text.lstrip())]
            trail = text[len(text.rstrip()):]
            core = text.strip()
            mark = ("**" if b else "") + ("*" if i else "")
            out.append(lead + mark + core + mark[::-1] + trail)
        else:
            out.append(text)
    return re.sub(r"[ \t]+", " ", "".join(out)).strip()


def _plain(md):
    s = md.replace("\\*", "\x00")
    return re.sub(r"\*{1,3}", "", s).replace("\x00", "*").strip()


def _all_bold(runs):
    body = [r for r in runs if r[0].strip()]
    return bool(body) and all(r[1] for r in body)


# ---------------------------------------------------------------------------
# Block model
#   {"type": "heading", "level": n, "text": md}
#   {"type": "p", "text": md}
#   {"type": "list", "items": [(level, marker, md)]}
#   {"type": "table", "rows": [[cell]], "width": n}
#   {"type": "image", "href": member}
#   cell = {"col": i, "span": n, "lines": [(kind, md)], "bold": bool, "images": [member]}
# ---------------------------------------------------------------------------

class OdtReader:
    def __init__(self, zf):
        self.zf = zf
        self.bold, self.italic, self.ordered = set(), set(), set()
        self._parent = {}
        self._styles = {}
        self.counters = {}
        content = self._xml("content.xml")
        if "styles.xml" in zf.namelist():
            self._scan_styles(self._xml("styles.xml"))
        self._scan_styles(content)
        self.body = content.find("office:body/office:text", NS)
        if self.body is None:
            raise ExtractError("content.xml no contiene office:text (¿es un ODT?)")

    def _xml(self, name):
        info = self.zf.getinfo(name)
        if info.file_size > MAX_XML_BYTES:
            raise ExtractError(f"{name} excede el tamaño permitido")
        return ET.fromstring(self.zf.read(name))

    def _scan_styles(self, root):
        for st in root.iter(q("style", "style")):
            name = st.get(q("style", "name"))
            self._parent[name] = st.get(q("style", "parent-style-name"))
            tp = st.find("style:text-properties", NS)
            if tp is not None:
                self._styles[name] = (tp.get(q("fo", "font-weight")) == "bold",
                                      tp.get(q("fo", "font-style")) == "italic")
        for ls in root.iter(q("text", "list-style")):
            lvl = ls.find("text:list-level-style-number", NS)
            self.ordered.add(ls.get(q("style", "name"))) if lvl is not None else None

    def _fmt(self, style):
        b = i = False
        seen = 0
        while style and seen < 20:
            sb, si = self._styles.get(style, (False, False))
            b, i = b or sb, i or si
            style = self._parent.get(style)
            seen += 1
        return b, i

    # -- inline -------------------------------------------------------------
    def runs(self, el, b0=False, i0=False, out=None, images=None):
        out = [] if out is None else out
        images = [] if images is None else images
        if el.text:
            out.append((el.text, b0, i0))
        for ch in el:
            tag = local(ch)
            if tag == "span":
                sb, si = self._fmt(ch.get(q("text", "style-name")))
                self.runs(ch, b0 or sb, i0 or si, out, images)
            elif tag == "s":
                out.append((" " * int(ch.get(q("text", "c"), "1")), b0, i0))
            elif tag == "tab":
                out.append((" ", b0, i0))
            elif tag == "line-break":
                out.append(("\n", b0, i0))
            elif tag in ("a", "number", "bookmark-ref", "span-ref"):
                self.runs(ch, b0, i0, out, images)
            elif tag == "frame":
                for img in ch.iter(q("draw", "image")):
                    href = img.get(q("xlink", "href"))
                    if href:
                        images.append(href)
            elif tag in ("note", "annotation", "bookmark", "bookmark-start", "bookmark-end",
                         "soft-page-break", "tracked-changes", "change", "change-start", "change-end"):
                pass
            else:
                self.runs(ch, b0, i0, out, images)
            if ch.tail:
                out.append((ch.tail, b0, i0))
        return out

    def para(self, p):
        pb, pi = self._fmt(p.get(q("text", "style-name")))
        images = []
        runs = self.runs(p, pb, pi, images=images)
        return _render_runs(runs), _all_bold(runs), images

    # -- blocks ---------------------------------------------------------------
    def blocks(self, container):
        out = []
        for ch in container:
            tag = local(ch)
            if tag == "h":
                md, _, imgs = self.para(ch)
                out.append({"type": "heading", "level": int(ch.get(q("text", "outline-level"), "1")),
                            "text": md})
                out += [{"type": "image", "href": h} for h in imgs]
            elif tag == "p":
                md, bold, imgs = self.para(ch)
                if md:
                    out.append({"type": "p", "text": md, "bold": bold})
                out += [{"type": "image", "href": h} for h in imgs]
            elif tag == "list":
                items = []
                self._list(ch, 0, items)
                if items:
                    out.append({"type": "list", "items": items})
            elif tag == "table":
                out.append(self.table(ch))
            elif tag == "section":
                out += self.blocks(ch)
            elif tag in ("table-of-content", "index-title", "tracked-changes"):
                continue
        return out

    def _list(self, lst, level, items):
        style = lst.get(q("text", "style-name"))
        ordered = style in self.ordered
        key = style
        if not ordered:
            n = 0
        elif lst.get(q("text", "continue-numbering")) == "true":
            n = self.counters.get(key, 0)
        else:
            n = 0
        for li in lst.findall("text:list-item", NS):
            n += 1
            first = True
            for ch in li:
                tag = local(ch)
                if tag in ("p", "h"):
                    md, _, _ = self.para(ch)
                    if md:
                        items.append((level, f"{n}." if ordered and first else "•", md))
                        first = False
                elif tag == "list":
                    self._list(ch, level + 1, items)
        if ordered:
            self.counters[key] = n

    def table(self, tbl):
        rows, width = [], 0
        for tr in tbl.iter(q("table", "table-row")):
            col, cells = 0, []
            for c in tr:
                tag = local(c)
                if tag not in ("table-cell", "covered-table-cell"):
                    continue
                rep = int(c.get(q("table", "number-columns-repeated"), "1"))
                span = int(c.get(q("table", "number-columns-spanned"), "1"))
                if tag == "table-cell":
                    cell = self._cell(c)
                    if cell["lines"] or cell["images"]:
                        cell["col"], cell["span"] = col, span
                        cells.append(cell)
                col += rep
            width = max(width, col)
            rows.append(cells)
        return {"type": "table", "rows": rows, "width": width}

    def _cell(self, c):
        lines, images, bolds = [], [], []
        for b in self.blocks(c):
            if b["type"] in ("p", "heading"):
                lines.append(("p", b["text"]))
                bolds.append(b.get("bold", False))
            elif b["type"] == "list":
                for _lvl, marker, md in b["items"]:
                    lines.append(("li", md))
                    bolds.append(False)
            elif b["type"] == "image":
                images.append(b["href"])
            elif b["type"] == "table":
                for row in b["rows"]:
                    txt = " | ".join(" ".join(t for _, t in cc["lines"]) for cc in row)
                    if txt:
                        lines.append(("p", txt))
                        bolds.append(False)
        return {"lines": lines, "images": images, "bold": bool(bolds) and all(bolds),
                "col": 0, "span": 1}


def read_odt(path):
    with zipfile.ZipFile(path) as zf:
        reader = OdtReader(zf)
        blocks = reader.blocks(reader.body)
        members = set(zf.namelist())
    return blocks, members


class DocxReader:
    def __init__(self, zf):
        self.zf = zf
        self.rels = {}
        name = "word/_rels/document.xml.rels"
        if name in zf.namelist():
            for rel in ET.fromstring(zf.read(name)):
                self.rels[rel.get("Id")] = "word/" + rel.get("Target", "").lstrip("/")
        info = zf.getinfo("word/document.xml")
        if info.file_size > MAX_XML_BYTES:
            raise ExtractError("document.xml excede el tamaño permitido")
        self.body = ET.fromstring(zf.read("word/document.xml")).find("{%s}body" % W)
        if self.body is None:
            raise ExtractError("document.xml no contiene w:body (¿es un DOCX?)")

    def _runs(self, p):
        runs, images = [], []
        for r in p.iter("{%s}r" % W):
            rpr = r.find("{%s}rPr" % W)
            b = rpr is not None and rpr.find("{%s}b" % W) is not None and \
                rpr.find("{%s}b" % W).get("{%s}val" % W) not in ("0", "false")
            i = rpr is not None and rpr.find("{%s}i" % W) is not None
            for ch in r:
                t = local(ch)
                if t == "t":
                    runs.append((ch.text or "", b, i))
                elif t == "tab":
                    runs.append((" ", b, i))
                elif t == "br":
                    runs.append(("\n", b, i))
            for blip in r.iter("{%s}blip" % A):
                target = self.rels.get(blip.get("{%s}embed" % R))
                if target:
                    images.append(target)
        return runs, images

    def para(self, p):
        runs, images = self._runs(p)
        ppr = p.find("{%s}pPr" % W)
        style, level, numbered = "", None, False
        if ppr is not None:
            ps = ppr.find("{%s}pStyle" % W)
            style = ps.get("{%s}val" % W) if ps is not None else ""
            numbered = ppr.find("{%s}numPr" % W) is not None
            ol = ppr.find("{%s}outlineLvl" % W)
            if ol is not None:
                level = int(ol.get("{%s}val" % W)) + 1
        m = re.match(r"(?:heading|t[ií]tulo|ttulo)\s*(\d)", style or "", re.I)
        if m:
            level = int(m.group(1))
        return _render_runs(runs), _all_bold(runs), images, level, numbered

    def blocks(self, container):
        out = []
        for ch in container:
            tag = local(ch)
            if tag == "p":
                md, bold, imgs, level, numbered = self.para(ch)
                if md and level:
                    out.append({"type": "heading", "level": level, "text": md})
                elif md and numbered:
                    out.append({"type": "list", "items": [(0, "•", md)]})
                elif md:
                    out.append({"type": "p", "text": md, "bold": bold})
                out += [{"type": "image", "href": h} for h in imgs]
            elif tag == "tbl":
                out.append(self.table(ch))
        return _merge_lists(out)

    def table(self, tbl):
        rows, width = [], 0
        for tr in tbl.findall("{%s}tr" % W):
            col, cells = 0, []
            for tc in tr.findall("{%s}tc" % W):
                pr = tc.find("{%s}tcPr" % W)
                gs = pr.find("{%s}gridSpan" % W) if pr is not None else None
                span = int(gs.get("{%s}val" % W)) if gs is not None else 1
                lines, images, bolds = [], [], []
                for b in self.blocks(tc):
                    if b["type"] in ("p", "heading"):
                        lines.append(("p", b["text"]))
                        bolds.append(b.get("bold", False))
                    elif b["type"] == "list":
                        for _l, _m, md in b["items"]:
                            lines.append(("li", md))
                            bolds.append(False)
                    elif b["type"] == "image":
                        images.append(b["href"])
                if lines or images:
                    cells.append({"col": col, "span": span, "lines": lines, "images": images,
                                  "bold": bool(bolds) and all(bolds)})
                col += span
            width = max(width, col)
            rows.append(cells)
        return {"type": "table", "rows": rows, "width": width}


def _merge_lists(blocks):
    out = []
    for b in blocks:
        if b["type"] == "list" and out and out[-1]["type"] == "list":
            out[-1]["items"] += b["items"]
        else:
            out.append(b)
    return out


def read_docx(path):
    with zipfile.ZipFile(path) as zf:
        reader = DocxReader(zf)
        return reader.blocks(reader.body), set(zf.namelist())


# ---------------------------------------------------------------------------
# Tables
# ---------------------------------------------------------------------------

def cell_text(cell):
    return "\n".join(t for _k, t in cell["lines"])


def is_layout_table(tbl):
    rows = [r for r in tbl["rows"] if r]
    if tbl["width"] < 8 or len(rows) < 10:
        return False
    small = sum(1 for r in rows if len(r) <= 3)
    return small / len(rows) >= 0.9


def table_to_md(tbl):
    rows = [r for r in tbl["rows"] if r]
    if not rows:
        return ""
    cols = sorted({c["col"] for r in rows for c in r})
    index = {c: i for i, c in enumerate(cols)}
    grid = []
    for r in rows:
        line = [""] * len(cols)
        for c in r:
            line[index[c["col"]]] = cell_text(c).replace("\n", "<br>").replace("|", "\\|")
        grid.append(line)
    if len(cols) == 1:
        return "\n".join(l[0] for l in grid)
    head = grid[0]
    out = ["| " + " | ".join(head) + " |", "|" + "---|" * len(cols)]
    out += ["| " + " | ".join(l) + " |" for l in grid[1:]]
    return "\n".join(out)


# ---------------------------------------------------------------------------
# DRP (Descripción de Requisitos por Proceso) semantic layer
# ---------------------------------------------------------------------------

LABELS = [
    ("pre", re.compile(r"^precondiciones?$", re.I)),
    ("events", re.compile(r"^flujo\s+de\s+eventos$", re.I)),
    ("alts_header", re.compile(r"^flujos\s+alternativos$", re.I)),
    ("post", re.compile(r"^pos-?\s?condiciones?$", re.I)),
    ("val", re.compile(r"^validaciones?$", re.I)),
    ("concepts", re.compile(r"^conceptos$", re.I)),
    ("special", re.compile(r"^requisitos\s+especiales$", re.I)),
    ("pending", re.compile(r"^asuntos\s+pendientes$", re.I)),
    ("proto", re.compile(r"^prototipo", re.I)),
]
RE_BASIC = re.compile(r"^flujo\s+b[aá]sico\s*(.*)$", re.I)
RE_ALT = re.compile(r"^flujo\s+alternativo\s+([0-9][\w.]*)\s*(.*)$", re.I)
RE_STEP_REF = re.compile(r"paso\s+(\d+)\s+del\s+flujo\s+(b[aá]sico|alternativo\s+([0-9][\w.]*))", re.I)
RE_DOC_REF = re.compile(r"pasa\s+a\s+(?:la\s+pantalla\s+de\s+procedencia\s+correspondiente\s+a\s+)?"
                        r"(.+?\.(?:odt|docx?|pdf))", re.I)
RE_FIELD = re.compile(r"^(?:\(\*\)\s*)?(.+?):\s*((?:Campo|Switch|Lista|Casilla|Bot[oó]n|Fecha)\b.*)$", re.I)
RE_VAL = re.compile(r"^(Campo de texto|Campo de selecci[oó]n (?:simple|m[uú]ltiple)|"
                    r"Switch \(Bot[oó]n de cambio de estado\)|Casilla de verificaci[oó]n|Campo de fecha)\s+"
                    r"(.+?):\s*(.*)$", re.I | re.S)


def _lines(cells):
    out = []
    for c in cells:
        out += c["lines"]
    return out


def _new_flow(fid, title):
    return {"id": fid, "title": title, "steps": [], "postconditions": []}


def parse_requirement(table):
    """Walk the layout table row by row and build the structured requirement."""
    req = {"preconditions": [], "basic_flow": _new_flow("básico", ""), "alternative_flows": [],
           "validations": [], "concepts": [], "special_requirements": [], "pending_issues": [],
           "prototypes": [], "unclassified": []}
    flow, section, post_target = None, None, None

    def add_text(target, cells):
        for k, t in _lines(cells):
            if re.fullmatch(r"\d+\.", t.strip()):  # stray list marker left by the source
                continue
            target.append(t)

    for row in table["rows"]:
        if not row:
            continue
        first = _plain(cell_text(row[0]))
        rest = row[1:]
        matched = None
        for key, rx in LABELS:
            if rx.match(first):
                matched = key
                break
        if matched == "pre":
            section = "pre"
            add_text(req["preconditions"], rest)
            continue
        if matched == "events":
            section = "events"
            continue
        if matched == "alts_header":
            section = "alts"
            continue
        if matched == "post":
            section, post_target = "post", flow if flow is not None else None
            if rest:
                add_text((post_target or req["basic_flow"])["postconditions"], rest)
            continue
        if matched == "val":
            section, flow = "val", None
            continue
        if matched == "concepts":
            section, flow = "concepts", None
            if len(rest) >= 2:
                req["concepts"].append({"name": _plain(cell_text(rest[0])), "lines": _lines(rest[1:])})
            continue
        if matched in ("special", "pending"):
            section, flow = matched, None
            target = req["special_requirements" if matched == "special" else "pending_issues"]
            add_text(target, rest)
            continue
        if matched == "proto":
            section, flow = "proto", None
            continue
        m = RE_BASIC.match(first)
        if m:
            flow, section = req["basic_flow"], "flow"
            flow["title"] = m.group(1).strip()
            continue
        m = RE_ALT.match(first)
        if m:
            flow = _new_flow(m.group(1).rstrip("."), m.group(2).strip())
            req["alternative_flows"].append(flow)
            section = "flow"
            continue
        # body rows
        if section == "flow" and flow is not None:
            cells = row
            flow["steps"].append({"n": len(flow["steps"]) + 1,
                                  "lines": [{"kind": k, "text": t} for k, t in _lines(cells)]})
        elif section == "post":
            tgt = (post_target or flow or req["basic_flow"])
            add_text(tgt["postconditions"], row)
        elif section == "pre":
            add_text(req["preconditions"], row)
        elif section == "val":
            for k, t in _lines(row):
                if k == "li" and req["validations"]:
                    req["validations"][-1]["items"].append(t)
                else:
                    req["validations"].append({"raw": t, "items": []})
        elif section == "concepts":
            if len(row) >= 2:
                req["concepts"].append({"name": _plain(cell_text(row[0])), "lines": _lines(row[1:])})
            else:
                req["unclassified"].append(cell_text(row[0]))
        elif section in ("special", "pending"):
            add_text(req["special_requirements" if section == "special" else "pending_issues"], row)
        elif section == "proto":
            for c in row:
                for k, t in c["lines"]:
                    req["prototypes"].append({"caption": t, "images": list(c["images"])})
                if not c["lines"] and c["images"]:
                    req["prototypes"].append({"caption": "", "images": list(c["images"])})
        else:
            req["unclassified"].append(cell_text(row[0]))
    return req


def step_text(step):
    return " ".join(l["text"] for l in step["lines"] if l["kind"] == "p")


def parse_fields(req):
    """Form fields announced by 'Se muestran los siguientes campos' (any flow)."""
    fields, controls = [], []
    for flow in [req["basic_flow"]] + req["alternative_flows"]:
        in_fields = False
        for step in flow["steps"]:
            for l in step["lines"]:
                if l["kind"] == "p":
                    in_fields = bool(re.search(r"campos", l["text"], re.I)) and \
                        not re.search(r"tambi[eé]n", l["text"], re.I)
                    continue
                m = RE_FIELD.match(_plain(l["text"]))
                if in_fields and m:
                    fields.append({"name": _plain(m.group(1)),
                                   "required": _plain(l["text"]).startswith("(*)"),
                                   "type": m.group(2).strip(), "flow": flow["id"]})
                else:
                    controls.append({"text": _plain(l["text"]), "flow": flow["id"]})
    return fields, controls


def parse_validations(req):
    out = []
    for item in req["validations"]:
        raw = item["raw"]
        text = _plain(raw)
        values = [_plain(i) for i in item["items"]]
        m = RE_VAL.match(text)
        if m:
            rule = m.group(3).strip()
            if values:
                rule += " " + " | ".join(values)
            out.append({"field": _plain(m.group(2)), "kind": m.group(1), "rule": rule,
                        "required": bool(re.search(r"obligatorio", rule, re.I)) and
                        not re.search(r"obligatorio\s+si", rule, re.I),
                        "conditional": bool(re.search(r"obligatorio\s+si", rule, re.I)),
                        "values": values, "raw": raw})
        else:
            out.append({"field": None, "kind": None, "rule": text, "required": False,
                        "conditional": False, "values": values, "raw": raw})
    return out


NUMBERING_KEYS = [
    (re.compile(r"incompleta", re.I), re.compile(r"campos\s+obligatorios", re.I)),
    (re.compile(r"incorrect", re.I), re.compile(r"datos\s+est[eé]n\s+correctos", re.I)),
    (re.compile(r"ya\s+existe", re.I), re.compile(r"no\s+exista", re.I)),
]


def numbering_evidence(req):
    """Compare the step number an alternative flow is anchored to (6.a -> 6) with the
    row that performs the matching check. A constant delta of 1 is the DRP convention
    "the alternative id is the step it REPLACES" (the outcome after the check), seen in
    several documents of the same family; it is reported as information, not as an error."""
    flows = {"básico": req["basic_flow"]}
    flows.update({f["id"]: f for f in req["alternative_flows"]})
    evidence = []
    for f in req["alternative_flows"]:
        parts = f["id"].split(".")
        if len(parts) < 2 or not parts[-2].isdigit():
            continue
        anchor = int(parts[-2])
        parent = flows.get(".".join(parts[:-2]) or "básico")
        if not parent:
            continue
        for title_rx, step_rx in NUMBERING_KEYS:
            if title_rx.search(f["title"]):
                rows = [s["n"] for s in parent["steps"] if step_rx.search(step_text(s))]
                if rows:
                    evidence.append({"flow": f["id"], "anchor": anchor, "parent": parent["id"],
                                     "row": rows[0], "delta": anchor - rows[0]})
    deltas = {e["delta"] for e in evidence}
    offset = deltas.pop() if len(deltas) == 1 and evidence else None
    return {"alt_id_delta": offset if offset else None, "evidence": evidence}


def collect_refs(req, offset=None):
    refs, docs = [], []
    flows = {"básico": req["basic_flow"]}
    for f in req["alternative_flows"]:
        flows[f["id"]] = f
    for flow in [req["basic_flow"]] + req["alternative_flows"]:
        for step in flow["steps"]:
            text = " ".join(l["text"] for l in step["lines"])
            step["refs"] = []
            for m in RE_STEP_REF.finditer(_plain(text)):
                target = "básico" if m.group(2).lower().startswith("b") else m.group(3).rstrip(".")
                tgt = flows.get(target)
                n = int(m.group(1))
                resolved = bool(tgt and 1 <= n <= len(tgt["steps"]))
                alt_n = n - offset if offset else None
                ref = {"from": f"{flow['id']}#{step['n']}", "flow": target, "step": n,
                       "resolved": resolved,
                       "target_text": step_text(tgt["steps"][n - 1]) if resolved else None}
                if resolved and offset and tgt and 1 <= alt_n <= len(tgt["steps"]):
                    ref["target_text_if_offset"] = step_text(tgt["steps"][alt_n - 1])
                refs.append(ref)
                step["refs"].append(ref)
            for m in RE_DOC_REF.finditer(_plain(text)):
                name = m.group(1).strip()
                docs.append({"from": f"{flow['id']}#{step['n']}", "document": name})
    return refs, docs


def diagnostics(req, fields, vals, refs, docs, change_log, numbering):
    diags = []

    def add(code, severity, msg, where=""):
        diags.append({"code": code, "severity": severity, "message": msg, "where": where})

    if req["basic_flow"]["steps"]:
        add("implicit-numbering", "info",
            "El documento no numera los pasos: se numeran por orden de fila (1..N). "
            "Los identificadores de flujos alternativos (p. ej. 4.b, 6.a) se conservan tal como "
            "están escritos y no se reinterpretan.", "flujo básico")
    if numbering["alt_id_delta"]:
        ev = "; ".join(f"{e['flow']}→fila {e['row']}" for e in numbering["evidence"])
        add("alt-id-convention", "info",
            f"Los ids de flujos alternativos van {numbering['alt_id_delta']} paso(s) por encima de la fila "
            f"que hace la comprobación ({ev}). Es coherente con la convención «el id es el paso que "
            "la alternativa sustituye» (el resultado posterior a la comprobación). No es un error por "
            "sí solo; solo preguntar al analista si una referencia «paso N» es ambigua.",
            "flujos alternativos")
    for r in refs:
        if r["resolved"] and r["flow"] != "básico":
            add("reference-to-alternative-flow", "info",
                f"{r['from']} salta al paso {r['step']} del flujo alternativo {r['flow']}: "
                f"«{(r['target_text'] or '')[:70]}». Verificar que es el destino previsto.", r["from"])
    for r in refs:
        if not r["resolved"]:
            add("unresolved-step-reference", "warning",
                f"Referencia al paso {r['step']} del flujo {r['flow']} que no existe.", r["from"])
    known = {f["name"].lower() for f in fields}
    seen = {}
    for v in vals:
        if not v["field"]:
            continue
        key = v["field"].lower()
        seen.setdefault(key, []).append(v)
        if known and key not in known and key != "eliminar":
            add("validation-for-unknown-field", "warning",
                f"Hay una validación para «{v['field']}», un campo que ningún flujo muestra "
                "(posible resto de otro requisito o campo sin documentar).", "Validaciones")
    for key, items in seen.items():
        if len(items) > 1:
            same = len({i["rule"] for i in items}) == 1
            add("duplicate-validation" if same else "conflicting-validation",
                "info" if same else "warning",
                f"«{items[0]['field']}» tiene {len(items)} validaciones" +
                (" idénticas." if same else " con reglas distintas: " +
                 " ≠ ".join(i["rule"] for i in items)), "Validaciones")
    validated = set(seen)
    for f in fields:
        if f["name"].lower() not in validated and f["name"].lower() != "eliminar":
            add("field-without-validation", "info",
                f"El campo «{f['name']}» se muestra pero no tiene validación documentada.",
                f"flujo {f['flow']}")
    for d in sorted({x["document"] for x in docs}):
        add("external-dependency", "info", f"Depende de otro requisito documentado: {d}", "flujos")
    if req["prototypes"] or any(img for p in req["prototypes"] for img in p["images"]):
        newest = [c for c in change_log if "prototipo" in c.get("description", "").lower()]
        if newest:
            add("prototype-changed", "info",
                f"El control de cambios menciona el prototipo (v{newest[-1]['version']}, "
                f"{newest[-1].get('date', '')}): el texto y la imagen pueden no estar alineados.", "prototipo")
    for n in ("special_requirements", "pending_issues"):
        items = [t for t in req[n] if _plain(t).upper() not in ("N/A", "NA", "")]
        if items:
            add("open-" + n.replace("_", "-"), "warning", f"{len(items)} entrada(s) en {n}.", n)
    if req["unclassified"]:
        add("unclassified-rows", "warning",
            f"{len(req['unclassified'])} fila(s) no se pudieron clasificar; revisar el original.", "")
    return diags


def parse_context(blocks):
    """Document control data that sits before the normative section."""
    meta = {"title": None, "version": None, "approved_by": None, "prepared_by": None,
            "classification": None}
    change_log = []
    for b in blocks:
        if b["type"] == "p":
            t = _plain(b["text"])
            m = re.match(r"^(T[ií]tulo|Versi[oó]n)\s*:\s*(.+)$", t, re.I)
            if m:
                meta["title" if m.group(1).lower().startswith("t") else "version"] = m.group(2).strip()
            m = re.match(r"^Clasificaci[oó]n\s*:\s*(.+)$", t, re.I)
            if m:
                meta["classification"] = m.group(1).strip().rstrip(".")
        elif b["type"] == "table":
            for row in b["rows"]:
                texts = [_plain(cell_text(c)) for c in row]
                if texts and texts[0].lower().startswith("elaborado por"):
                    meta["prepared_by"] = " / ".join(t for t in texts[1:] if t)
                if texts and texts[0].lower().startswith("aprobado por"):
                    meta["approved_by"] = " / ".join(t for t in texts[1:] if t)
                if texts and re.match(r"^\d+(\.\d+)+$", texts[0]):
                    pad = texts + [""] * 6
                    change_log.append({"version": pad[0], "section": pad[1], "type": pad[2],
                                       "date": pad[3], "author": pad[4], "description": pad[5]})
    return meta, change_log


# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

def _heading_text(md):
    return _plain(md)


def blocks_to_md(blocks, asset_map, skip_tables=()):
    out = []
    for b in blocks:
        t = b["type"]
        if t == "heading":
            out.append("\n" + "#" * min(b["level"] + 1, 6) + " " + _heading_text(b["text"]) + "\n")
        elif t == "p":
            out.append(b["text"] + "\n")
        elif t == "list":
            for lvl, marker, md in b["items"]:
                out.append("  " * lvl + f"{marker} {md}")
            out.append("")
        elif t == "image":
            if b["href"] in asset_map:
                out.append(f"![figura]({asset_map[b['href']]})\n")
        elif t == "table" and id(b) not in skip_tables:
            md = table_to_md(b)
            if md:
                out.append(md + "\n")
    return "\n".join(out)


def _fmt_lines(lines, indent="   "):
    out = []
    for i, l in enumerate(lines):
        if i == 0:
            out.append(l["text"])
        elif l["kind"] == "li":
            out.append(f"{indent}- {l['text']}")
        else:
            out.append(f"{indent}{l['text']}")
    return "\n".join(out)


def render_flow(flow, level):
    out = []
    head = "Flujo básico" if flow["id"] == "básico" else f"Flujo alternativo {flow['id']}"
    out.append(f"{'#' * level} {head}" + (f" — {_plain(flow['title'])}" if flow["title"] else ""))
    out.append("")
    for s in flow["steps"]:
        out.append(f"{s['n']}. {_fmt_lines(s['lines'])}")
    if flow["postconditions"]:
        out.append("")
        out.append("**Pos-condiciones:** " + "; ".join(_plain(p) for p in flow["postconditions"]))
    out.append("")
    return "\n".join(out)


def render_requirement(name, req, fields, controls, vals, diags, docs):
    o = [f"## Requisito normativo: {name}", ""]
    if req["preconditions"]:
        o += ["### Precondiciones", ""] + [f"- {t}" for t in req["preconditions"]] + [""]
    if fields:
        o += ["### Campos del formulario", "", "| Campo | Obligatorio | Tipo | Flujo |", "|---|---|---|---|"]
        o += [f"| {f['name']} | {'sí' if f['required'] else 'no'} | {f['type']} | {f['flow']} |"
              for f in fields]
        o.append("")
    o.append(render_flow(req["basic_flow"], 3))
    if req["alternative_flows"]:
        o += ["### Flujos alternativos", ""]
        for f in req["alternative_flows"]:
            o.append(render_flow(f, 4))
    if vals:
        o += ["### Validaciones", "", "| Campo | Regla | Obligatorio |", "|---|---|---|"]
        for v in vals:
            req_txt = "condicional" if v["conditional"] else ("sí" if v["required"] else "")
            o.append(f"| {v['field'] or '—'} | {v['rule'].replace('|', '/')} | {req_txt} |")
        o.append("")
    if req["concepts"]:
        o += ["### Conceptos (modelo)", ""]
        for c in req["concepts"]:
            o.append(f"- **{c['name']}**")
            for k, t in c["lines"]:
                o.append(f"  - {t}" if k == "li" else f"  {t}")
        o.append("")
    for title, key in (("Requisitos especiales", "special_requirements"),
                       ("Asuntos pendientes", "pending_issues")):
        o += [f"### {title}", ""] + ([f"- {t}" for t in req[key]] or ["- N/A"]) + [""]
    if req["prototypes"]:
        o += ["### Prototipo de interfaz", ""]
        for p in req["prototypes"]:
            for img in p["images"]:
                o.append(f"![{_plain(p['caption']) or 'prototipo'}]({img})")
            if p["caption"]:
                o.append(f"*{_plain(p['caption'])}*")
        o.append("")
    if docs:
        o += ["### Documentos referenciados", ""] + \
             [f"- {d}" for d in sorted({x['document'] for x in docs})] + [""]
    if diags:
        o += ["## Diagnósticos de lectura", "", "| Gravedad | Código | Detalle |", "|---|---|---|"]
        for d in diags:
            o.append(f"| {d['severity']} | `{d['code']}` | {d['message'].replace('|', '/')}"
                     + (f" ({d['where']})" if d['where'] else "") + " |")
        o.append("")
    return "\n".join(o)


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def extract(path, out_dir, from_heading=NORMATIVE_HEADING):
    path, out_dir = Path(path), Path(out_dir)
    ext = path.suffix.lower()
    if ext == ".odt":
        blocks, members = read_odt(path)
        fmt = "odt"
    elif ext == ".docx":
        blocks, members = read_docx(path)
        fmt = "docx"
    else:
        raise ExtractError(f"formato no soportado por el extractor nativo: {ext}")

    out_dir.mkdir(parents=True, exist_ok=True)
    warnings = []

    # copy only the images the document actually references
    wanted = []
    def collect(bs):
        for b in bs:
            if b["type"] == "image":
                wanted.append(b["href"])
            elif b["type"] == "table":
                for r in b["rows"]:
                    for c in r:
                        wanted.extend(c["images"])
    collect(blocks)
    asset_map = {}
    if wanted:
        assets = out_dir / "assets"
        assets.mkdir(exist_ok=True)
        with zipfile.ZipFile(path) as zf:
            for href in dict.fromkeys(wanted):
                member = href.lstrip("./") if fmt == "odt" else href
                if member not in members:
                    warnings.append(f"imagen referenciada pero ausente: {href}")
                    continue
                name = re.sub(r"[^\w.\-]", "_", Path(member).name)
                dest = assets / name
                dest.write_bytes(zf.read(member))
                asset_map[href] = f"assets/{name}"

    # split context / normative part
    rx = re.compile(from_heading, re.I)
    start = next((i for i, b in enumerate(blocks)
                  if b["type"] == "heading" and rx.search(_plain(b["text"]))), None)
    context_blocks = blocks[:start] if start is not None else []
    normative = blocks[start:] if start is not None else blocks
    if start is None:
        warnings.append("no se encontró el encabezado «Descripción textual del requisito»; "
                        "se procesa el documento completo")

    meta, change_log = parse_context(context_blocks or blocks)
    layout = next((b for b in normative if b["type"] == "table" and is_layout_table(b)), None)

    req_name = ""
    for b in reversed(context_blocks):
        if b["type"] == "heading":
            m = re.search(r"especificaci[oó]n\s+de\s+requisito\s+(.+)$", _plain(b["text"]), re.I)
            if m:
                req_name = m.group(1).strip()
                break

    result = {"source": {"filename": path.name, "format": fmt},
              "document": meta, "change_log": change_log,
              "requirement": None, "diagnostics": [], "warnings": warnings,
              "assets": sorted(asset_map.values())}

    md = [f"# {req_name or meta['title'] or path.stem}", "",
          f"> Normalizado por `mentorkit.py extract` desde `{path.name}` ({fmt.upper()}). "
          "La parte normativa es la sección «Descripción textual del requisito»; "
          "el contexto previo es informativo.", ""]

    if layout is not None:
        req = parse_requirement(layout)
        fields, controls = parse_fields(req)
        vals = parse_validations(req)
        numbering = numbering_evidence(req)
        refs, docs = collect_refs(req, numbering["alt_id_delta"])
        diags = diagnostics(req, fields, vals, refs, docs, change_log, numbering)
        for p in req["prototypes"]:
            p["images"] = [asset_map.get(i, i) for i in p["images"]]
        req.update({"name": req_name, "form_fields": fields, "controls": controls,
                    "validation_rules": vals, "references": refs, "external_documents": docs,
                    "numbering": numbering})
        result["requirement"] = req
        result["diagnostics"] = diags
        ctx_rows = [f"- **Versión:** {meta['version'] or '—'}",
                    f"- **Elaborado por:** {meta['prepared_by'] or '—'}",
                    f"- **Aprobado por:** {meta['approved_by'] or '—'}",
                    f"- **Clasificación:** {meta['classification'] or '—'}"]
        md += ["## Contexto del documento (informativo)", ""] + ctx_rows + [""]
        if change_log:
            md += ["| Versión | Sección | Tipo | Fecha | Descripción |", "|---|---|---|---|---|"]
            md += [f"| {c['version']} | {c['section']} | {c['type']} | {c['date']} | {c['description']} |"
                   for c in change_log]
            md.append("")
        first_h = next((i for i, b in enumerate(context_blocks) if b["type"] == "heading"), None)
        intro = context_blocks[first_h:] if first_h is not None else []
        while intro and intro[-1]["type"] == "heading":
            intro.pop()
        if intro:
            md += [blocks_to_md(intro, asset_map), ""]
        md.append(render_requirement(req_name or "(sin nombre)", req, fields, controls, vals, diags, docs))
    else:
        md.append(blocks_to_md(normative if start is not None else blocks, asset_map))
        result["warnings"].append("no se detectó la tabla de requisito (DRP); salida genérica")

    stem = path.stem
    (out_dir / f"{stem}.normalized.md").write_text("\n".join(md).rstrip() + "\n", encoding="utf-8")
    (out_dir / f"{stem}.drp.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                                                encoding="utf-8")
    return result, out_dir / f"{stem}.normalized.md", out_dir / f"{stem}.drp.json"


def summarize(result, md_path, json_path):
    req = result["requirement"]
    lines = [f"Formato:      {result['source']['format'].upper()}",
             "Método:       Python puro (prd_extract)",
             f"Salida:       {md_path}", f"Datos:        {json_path}",
             f"Imágenes:     {len(result['assets'])}"]
    if req:
        lines += [f"Requisito:    {req.get('name') or '—'}",
                  f"Pasos:        {len(req['basic_flow']['steps'])} (flujo básico)",
                  f"Alternativos: {len(req['alternative_flows'])}",
                  f"Campos:       {len(req['form_fields'])}",
                  f"Validaciones: {len(req['validation_rules'])}",
                  f"Conceptos:    {len(req['concepts'])}"]
    sev = {}
    for d in result["diagnostics"]:
        sev[d["severity"]] = sev.get(d["severity"], 0) + 1
    lines.append("Diagnósticos: " + (", ".join(f"{n} {s}" for s, n in sorted(sev.items())) or "ninguno"))
    lines.append("Warnings:     " + ("; ".join(result["warnings"]) or "ninguno"))
    return "\n".join(lines)


def main(argv=None):
    import argparse
    ap = argparse.ArgumentParser(description="MentorKit PRD extractor (ODT/DOCX)")
    ap.add_argument("file")
    ap.add_argument("--out", required=True, help="directorio de salida")
    ap.add_argument("--from-heading", default=NORMATIVE_HEADING,
                    help="regex del encabezado donde empieza la parte normativa")
    a = ap.parse_args(argv)
    try:
        result, md, js = extract(a.file, a.out, a.from_heading)
    except (ExtractError, zipfile.BadZipFile, ET.ParseError, OSError, KeyError) as exc:
        print(f"[MentorKit] ERROR: no se pudo extraer {a.file}: {exc}", file=sys.stderr)
        return 1
    print(summarize(result, md, js))
    return 0


if __name__ == "__main__":
    sys.exit(main())
