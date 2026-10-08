#!/usr/bin/env python3
"""MentorKit cross-platform runtime helper.

Stdlib-only bootstrap helper. Supports Windows, macOS and Linux.
It intentionally keeps OS-specific shell syntax out of the installation logic.
"""
from __future__ import annotations
import argparse, json, os, platform, shutil, subprocess, sys, tempfile, urllib.request
from pathlib import Path

REPO = "thewild001/MentorKit"
BRANCH = os.environ.get("MENTORKIT_BRANCH", "main")
PYTHON_VERSION = "3.12"
PYTHON_PATCH = "3.12.13"
ROOT = Path.cwd()
OPENCODE = ROOT / ".opencode"
RUNTIME = OPENCODE / ".mentorkit"
VENV = RUNTIME / "venv"
LOCK = OPENCODE / "requirements.lock"
RAW = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}/"

REQUIRED = [
    ".opencode/skills/odd-orchestrator/SKILL.md",
    ".opencode/skills/codebase-conformist/SKILL.md",
    ".opencode/skills/codebase-graph/SKILL.md",
    ".opencode/skills/spec-writer/SKILL.md",
    ".opencode/skills/prd-reader/SKILL.md",
    ".opencode/skills/document-extractor/SKILL.md",
    ".opencode/skills/llm-council/SKILL.md",
    ".opencode/agents/MentorKit5.0.md",
    ".opencode/mentorkit.py",
    ".opencode/mentorkit-odd-task.sh",
    ".opencode/mentorkit-verify.sh",
    ".opencode/requirements.in",
    ".opencode/requirements.lock",
]

def log(msg): print(msg, flush=True)
def die(msg, code=1):
    print(f"[MentorKit] ERROR: {msg}", file=sys.stderr)
    raise SystemExit(code)

def run(cmd, *, check=True, capture=False):
    return subprocess.run(cmd, check=check, text=True, capture_output=capture)

def python_exe():
    candidates = [VENV / "Scripts/python.exe", VENV / "bin/python", VENV / "bin/python3"]
    for p in candidates:
        if p.exists():
            return p
    return None

def uv_exe():
    candidates = [
        shutil.which("uv"),
        VENV / "Scripts/uv.exe",
        VENV / "bin/uv",
        Path.home() / ".local/bin/uv",
        Path.home() / ".cargo/bin/uv",
        Path.home() / ".local/bin/uv.exe",
    ]
    for p in candidates:
        if p and Path(p).exists():
            return Path(p)
    return None

def download(path):
    dest = ROOT / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    url = RAW + path
    log(f"  + recuperando {path} desde {BRANCH}")
    try:
        with urllib.request.urlopen(url, timeout=60) as r:
            data = r.read()
    except Exception as exc:
        die(f"no se pudo descargar {path}: {exc}")
    if not data or b"<html" in data[:512].lower() or b"<!doctype" in data[:512].lower():
        die(f"GitHub devolvió contenido inválido para {path}")
    dest.write_bytes(data)

def ensure_files():
    for rel in REQUIRED:
        if not (ROOT / rel).is_file():
            download(rel)

def install_uv():
    uv = uv_exe()
    if uv:
        return uv
    log("  + uv no encontrado; instalando con el instalador oficial")
    if platform.system() == "Windows":
        ps = shutil.which("powershell") or shutil.which("pwsh")
        if not ps:
            die("PowerShell no está disponible para instalar uv en Windows")
        script = "$ErrorActionPreference='Stop'; irm https://astral.sh/uv/install.ps1 | iex"
        run([ps, "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", script])
    else:
        curl = shutil.which("curl")
        if not curl:
            die("curl es necesario en macOS/Linux para instalar uv")
        run(["bash", "-lc", "curl -LsSf https://astral.sh/uv/install.sh | sh"])
        # The official installer may update ~/.local/bin or ~/.cargo/bin.
    uv = uv_exe()
    if not uv:
        die("uv no quedó disponible en PATH; reinicia la terminal o instala uv manualmente")
    return uv

def ensure_python(uv):
    try:
        p = subprocess.run([str(uv), "python", "find", PYTHON_VERSION], text=True, capture_output=True)
        if p.returncode == 0 and p.stdout.strip():
            return Path(p.stdout.strip().splitlines()[-1])
    except Exception:
        pass
    log(f"  + instalando Python {PYTHON_VERSION} mediante uv")
    run([str(uv), "python", "install", PYTHON_VERSION])
    p = subprocess.run([str(uv), "python", "find", PYTHON_VERSION], text=True, capture_output=True)
    if p.returncode != 0:
        die("uv no pudo localizar Python 3.12")
    return Path(p.stdout.strip().splitlines()[-1])

def ensure_venv(uv):
    py = python_exe()
    if py:
        probe = subprocess.run([str(py), "-c", "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"],
                               text=True, capture_output=True)
        if probe.returncode == 0 and probe.stdout.strip() == PYTHON_VERSION:
            return py
        shutil.rmtree(VENV, ignore_errors=True)
    VENV.parent.mkdir(parents=True, exist_ok=True)
    run([str(uv), "venv", "--python", PYTHON_VERSION, str(VENV)])
    py = python_exe()
    if not py:
        die("no se pudo crear el entorno virtual de MentorKit")
    return py

def install_deps(uv, py):
    if not LOCK.is_file():
        die(f"no existe {LOCK}")
    run([str(uv), "pip", "install", "--python", str(py), "-r", str(LOCK)])
    RUNTIME.mkdir(parents=True, exist_ok=True)
    (RUNTIME / "python-path.txt").write_text(str(py), encoding="utf-8")

def verify(json_mode=False):
    py = python_exe()
    if not py:
        return fail_verify("venv no encontrado", json_mode)
    code = (
        "import sys, importlib.metadata as md, json, platform;"
        "deps=[('markitdown','markitdown'),('firecrawl-anydoc','anydoc'),"
        "('striprtf','striprtf'),('graphifyy','graphify'),('uv','uv')];"
        "out={};"
        "[out.__setitem__(n, {'ok': True, 'version': md.version(n)}) if not "
        "(__import__(i) is None) else None for n,i in deps];"
        "print(json.dumps({'python':platform.python_version(),'platform':platform.platform(),'deps':out}))"
    )
    p = subprocess.run([str(py), "-c", code], text=True, capture_output=True)
    if p.returncode != 0:
        return fail_verify(p.stderr.strip() or "imports fallaron", json_mode)
    try:
        data = json.loads(p.stdout.strip())
    except Exception:
        return fail_verify("salida de verificación inválida", json_mode)
    data["python_ok"] = data.get("python") == PYTHON_PATCH or data.get("python","").startswith(PYTHON_VERSION + ".")
    data["all_deps_ok"] = all(x.get("ok") for x in data.get("deps", {}).values())
    data["lock"] = str(LOCK)
    data["lock_exists"] = LOCK.exists()
    ok = data["python_ok"] and data["all_deps_ok"] and data["lock_exists"]
    if json_mode:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        log(f"  + Python: {data['python']}")
        log(f"  + Platform: {data['platform']}")
        for n,v in data["deps"].items():
            log(f"  + {n}: {v.get('version','?')}")
        log("  + VERIFY PASS" if ok else "  x VERIFY FAIL")
    return 0 if ok else 1

def fail_verify(msg, json_mode):
    if json_mode:
        print(json.dumps({"ok": False, "error": msg}, ensure_ascii=False))
    else:
        print(f"  x VERIFY FAIL: {msg}", file=sys.stderr)
    return 1

def odd_task(feature, request):
    if not feature or not request:
        die('uso: odd-task <feature> "<request>"')
    if any(c not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_" for c in feature):
        die("feature-name solo admite letras, números, '-' y '_'")
    path = ROOT / "odd" / "tasks" / f"{feature}.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        die(f"ya existe: {path}", 2)
    branch = "unknown"
    try:
        p = subprocess.run(["git", "branch", "--show-current"], text=True, capture_output=True)
        if p.returncode == 0 and p.stdout.strip(): branch = p.stdout.strip()
    except FileNotFoundError:
        pass
    path.write_text(f"""# {feature}

## Objective

Pendiente de completar durante Explore.

## Specs

S1. Pendiente de definir tras Explore.
- Acceptance: pendiente
- Checks: pendiente

## Tasks

- [ ] T1 — Pendiente de descomponer
  - Spec: S1
  - Route: pendiente
  - Commit: pending

## Verification

- [ ] S1 — pendiente
- [ ] Tests/checks: pendiente
- [ ] Regressions: pendiente

## Log

L1. {request}

## Delivery

- Status: active
- Branch: {branch}
- Review candidate: pending
- Next step: Explore
""", encoding="utf-8")
    log(f"+ ODD task creado: {path}")

def main():
    ap=argparse.ArgumentParser(description="MentorKit cross-platform helper")
    sub=ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("install")
    sub.add_parser("verify").add_argument("--json", action="store_true")
    sub.add_parser("fix")
    t=sub.add_parser("odd-task"); t.add_argument("feature"); t.add_argument("request")
    raw_args = sys.argv[1:]
    # Backward-compatible alias for older launchers that invoked --fix.
    if raw_args and raw_args[0] == "--fix":
        raw_args[0] = "fix"
    a=ap.parse_args(raw_args)
    if a.cmd in ("install","fix"):
        ensure_files(); uv=install_uv(); ensure_python(uv); py=ensure_venv(uv); install_deps(uv,py); raise SystemExit(verify(False))
    if a.cmd=="verify": raise SystemExit(verify(a.json))
    if a.cmd=="odd-task": odd_task(a.feature,a.request)

if __name__=="__main__":
    main()
