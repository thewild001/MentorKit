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
    "odd/CONTRACT.md",
    "odd/planning/CONTRACT.md",
    "odd/planning/templates/implementation-plan.md",
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

# ---------------------------------------------------------------------------
# codebase-memory-mcp: pinned install, per-agent configuration, verification
# ---------------------------------------------------------------------------
CBM_NAME = "codebase-memory-mcp"
CBM_VERSION = "v0.11.0"
CBM_BASE_URL = os.environ.get(
    "MENTORKIT_CBM_BASE_URL",
    f"https://github.com/DeusData/codebase-memory-mcp/releases/download/{CBM_VERSION}",
).rstrip("/")
# SHA-256 pinned here (taken from the upstream checksums.txt of CBM_VERSION), so
# a tampered download or release asset can never be installed. Linux uses the
# static "portable" build, which does not depend on the host libc.
CBM_ASSETS = {
    ("linux", "amd64"): ("codebase-memory-mcp-linux-amd64-portable.tar.gz",
                         "1f9e8293eb2bc5c05cfa27a7e8fc033da6d729ffad525ccfcdaa3fd606306683"),
    ("linux", "arm64"): ("codebase-memory-mcp-linux-arm64-portable.tar.gz",
                         "d62eeb224d5ee3eba3070938ec62cf1033f10b041ec1c4b2fb67f7aef390cc7b"),
    ("darwin", "amd64"): ("codebase-memory-mcp-darwin-amd64.tar.gz",
                          "dbf1c73bfcbde64e7dde4cd1320da7afc02e2c972ee1789ae039521411f5132e"),
    ("darwin", "arm64"): ("codebase-memory-mcp-darwin-arm64.tar.gz",
                          "4dee7f38b63740e6751d7a7ed7eb10291c1f2a3ea2415f599dc68370ca0a2d18"),
    ("windows", "amd64"): ("codebase-memory-mcp-windows-amd64.zip",
                           "6eb6beaf261b19e419766e78baf93cbc3cf1c6338cff8fb7c0234859f96d1685"),
    ("windows", "arm64"): ("codebase-memory-mcp-windows-arm64.zip",
                           "52b29881214fce47d529e098308b1de77c40f6812e20a34d588ee4c25b84fd1a"),
}
MCP_CLIENTS = ("claude", "codex", "opencode", "cursor")

def mcp_platform():
    system = platform.system().lower()
    machine = platform.machine().lower()
    arch = {"x86_64": "amd64", "amd64": "amd64", "x64": "amd64",
            "aarch64": "arm64", "arm64": "arm64"}.get(machine)
    return (system, arch)

def mcp_exe_name():
    return CBM_NAME + (".exe" if platform.system() == "Windows" else "")

def mcp_install_dir():
    override = os.environ.get("MENTORKIT_CBM_DIR")
    if override:
        return Path(override)
    if platform.system() == "Windows":
        base = os.environ.get("LOCALAPPDATA") or (Path.home() / "AppData/Local")
        return Path(base) / "Programs" / CBM_NAME
    return Path.home() / ".local/bin"

def mcp_version(binary):
    try:
        p = subprocess.run([str(binary), "--version"], text=True, capture_output=True, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return None
    out = (p.stdout or "").strip()
    return out.split()[-1] if p.returncode == 0 and out else None

def find_mcp_binary():
    """Prefers the MentorKit install location, then PATH and known locations."""
    candidates = [mcp_install_dir() / mcp_exe_name(), shutil.which(CBM_NAME),
                  Path.home() / ".local/bin" / mcp_exe_name(),
                  Path.home() / ".cargo/bin" / CBM_NAME,
                  Path("/usr/local/bin") / CBM_NAME,
                  Path("/opt/homebrew/bin") / CBM_NAME]
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return Path(candidate)
    return None

def _extract_member(archive, dest_dir, wanted):
    """Extracts exactly one member by basename (never extractall: no path traversal)."""
    import tarfile, zipfile
    out = dest_dir / wanted
    if str(archive).endswith(".zip"):
        with zipfile.ZipFile(archive) as z:
            for name in z.namelist():
                if Path(name).name == wanted and not name.endswith("/"):
                    out.write_bytes(z.read(name))
                    return out
    else:
        with tarfile.open(archive, "r:gz") as t:
            for m in t.getmembers():
                if m.isfile() and Path(m.name).name == wanted:
                    f = t.extractfile(m)
                    if f:
                        out.write_bytes(f.read())
                        return out
    return None

def install_mcp_binary():
    """Installs the pinned codebase-memory-mcp. Returns its path, or None on failure."""
    import hashlib
    pinned = CBM_VERSION.lstrip("v")
    existing = find_mcp_binary()
    if existing and mcp_version(existing) == pinned:
        log(f"  + {CBM_NAME} {pinned} ya instalado: {existing}")
        return existing
    key = mcp_platform()
    asset = CBM_ASSETS.get(key)
    if not asset:
        log(f"  x {CBM_NAME}: plataforma sin binario oficial ({key[0]}/{key[1] or platform.machine()})")
        return None
    name, expected = asset
    dest_dir = mcp_install_dir()
    dest = dest_dir / mcp_exe_name()
    with tempfile.TemporaryDirectory(prefix="mentorkit-cbm-") as tmp:
        tmpdir = Path(tmp)
        archive = tmpdir / name
        url = f"{CBM_BASE_URL}/{name}"
        log(f"  + descargando {CBM_NAME} {pinned} ({name})")
        try:
            digest = hashlib.sha256()
            with urllib.request.urlopen(url, timeout=120) as r, archive.open("wb") as f:
                while True:
                    chunk = r.read(1 << 20)
                    if not chunk:
                        break
                    digest.update(chunk)
                    f.write(chunk)
        except Exception as exc:
            log(f"  x no se pudo descargar {url}: {exc}")
            return None
        if digest.hexdigest() != expected:
            log(f"  x SHA-256 no coincide para {name}; instalación abortada")
            log(f"    esperado {expected}")
            log(f"    obtenido {digest.hexdigest()}")
            return None
        log("  + SHA-256 verificado")
        extracted = _extract_member(archive, tmpdir, mcp_exe_name())
        if not extracted:
            log(f"  x {mcp_exe_name()} no está en {name}")
            return None
        if platform.system() == "Darwin":
            subprocess.run(["xattr", "-d", "com.apple.quarantine", str(extracted)], capture_output=True)
            subprocess.run(["codesign", "--sign", "-", "--force", str(extracted)], capture_output=True)
        os.chmod(extracted, 0o755)
        got = mcp_version(extracted)
        if got != pinned:
            log(f"  x el binario descargado no se ejecuta o reporta versión inesperada ({got})")
            return None
        try:
            dest_dir.mkdir(parents=True, exist_ok=True)
            staged = dest_dir / (mcp_exe_name() + ".mentorkit-new")
            shutil.copy2(extracted, staged)
            if platform.system() == "Windows" and dest.exists():
                old = dest_dir / (mcp_exe_name() + ".old")
                old.unlink(missing_ok=True)
                try:
                    dest.rename(old)  # a running .exe can be renamed but not overwritten
                except OSError:
                    pass
            os.replace(staged, dest)
        except OSError as exc:
            log(f"  x no se pudo escribir {dest}: {exc}")
            return None
    log(f"  + {CBM_NAME} {pinned} instalado en {dest}")
    if not any(Path(p) == dest_dir for p in os.environ.get("PATH", "").split(os.pathsep) if p):
        log(f"  i {dest_dir} no está en PATH; los agentes usan la ruta absoluta, no hace falta")
    return dest

# --- agent configuration ----------------------------------------------------

def _read_json_object(path):
    """-> (data, error). A missing or empty file is {}; invalid JSON is never overwritten."""
    if not path.exists():
        return {}, None
    try:
        text = path.read_text(encoding="utf-8-sig")
        data = json.loads(text) if text.strip() else {}
    except (OSError, ValueError) as exc:
        return None, f"{path} no es JSON válido ({exc}); no se modifica"
    if not isinstance(data, dict):
        return None, f"{path} no contiene un objeto JSON; no se modifica"
    return data, None

def _write_atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_name(path.name + ".mentorkit.bak")
        if not backup.exists():
            shutil.copy2(path, backup)
    tmp = path.with_name(path.name + ".mentorkit-tmp")
    tmp.write_text(text, encoding="utf-8", newline="\n")
    os.replace(tmp, path)

def _merge_json(path, section, entry):
    data, err = _read_json_object(path)
    if err:
        return "error", err
    block = data.get(section)
    if block is None:
        block = data[section] = {}
    if not isinstance(block, dict):
        return "error", f"{path}: '{section}' no es un objeto; no se modifica"
    if block.get(CBM_NAME) == entry:
        return "ok", f"sin cambios ({path})"
    block[CBM_NAME] = entry
    _write_atomic(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    return "ok", f"configurado ({path})"

def claude_config_path():
    base = os.environ.get("CLAUDE_CONFIG_DIR")
    return (Path(base) if base else Path.home()) / ".claude.json"

def cursor_config_path():
    return Path.home() / ".cursor" / "mcp.json"

def opencode_config_paths():
    """opencode follows XDG on every OS (~/.config/opencode). Legacy paths this
    script used to write are refreshed only if they already exist."""
    base = os.environ.get("XDG_CONFIG_HOME")
    paths = [(Path(base) if base else Path.home() / ".config") / "opencode" / "opencode.json"]
    if platform.system() == "Windows":
        legacy = Path(os.environ.get("APPDATA") or (Path.home() / "AppData/Roaming")) / "opencode/opencode.json"
    elif platform.system() == "Darwin":
        legacy = Path.home() / "Library/Application Support/opencode/opencode.json"
    else:
        legacy = None
    if legacy and legacy.exists() and legacy not in paths:
        paths.append(legacy)
    return paths

def codex_config_path():
    base = os.environ.get("CODEX_HOME")
    return (Path(base) if base else Path.home() / ".codex") / "config.toml"

def _codex_section(binary):
    return f"[mcp_servers.{CBM_NAME}]\ncommand = {json.dumps(str(binary))}\nargs = []\n"

def _configure_codex(binary):
    import re
    try:
        import tomllib
    except ImportError:
        return "error", "Codex requiere Python >= 3.11 para validar config.toml; ejecuta el instalador con uv"
    path = codex_config_path()
    text = path.read_text(encoding="utf-8-sig") if path.exists() else ""
    try:
        tomllib.loads(text)
    except tomllib.TOMLDecodeError as exc:
        return "error", f"{path} no es TOML válido ({exc}); no se modifica"
    section = _codex_section(binary)
    pattern = re.compile(rf"^\[mcp_servers\.{re.escape(CBM_NAME)}\][ \t]*\r?\n(?:(?!\[).*(?:\r?\n|$))*", re.M)
    if pattern.search(text):
        new = pattern.sub(lambda _m: section + "\n", text, count=1)
    else:
        new = text + ("" if not text or text.endswith("\n") else "\n") + ("\n" if text.strip() else "") + section
    if new == text:
        return "ok", f"sin cambios ({path})"
    try:
        parsed = tomllib.loads(new)
    except tomllib.TOMLDecodeError as exc:
        return "error", f"{path}: el resultado no sería TOML válido ({exc}); no se modifica"
    if parsed.get("mcp_servers", {}).get(CBM_NAME, {}).get("command") != str(binary):
        return "error", f"{path}: no se pudo fijar la entrada; no se modifica"
    _write_atomic(path, new)
    return "ok", f"configurado ({path})"

def configure_client(client, binary):
    """-> (status, detail). Idempotent; never overwrites a file it cannot parse."""
    b = str(binary)
    try:
        if client == "claude":
            return _merge_json(claude_config_path(), "mcpServers",
                               {"type": "stdio", "command": b, "args": [], "env": {}})
        if client == "cursor":
            return _merge_json(cursor_config_path(), "mcpServers", {"command": b, "args": []})
        if client == "opencode":
            results = [_merge_json(p, "mcp", {"type": "local", "command": [b], "enabled": True})
                       for p in opencode_config_paths()]
            bad = [r for r in results if r[0] == "error"]
            return bad[0] if bad else results[0]
        if client == "codex":
            return _configure_codex(binary)
    except OSError as exc:
        return "error", f"{client}: {exc}"
    return "error", f"cliente desconocido: {client}"

def selected_clients():
    raw = os.environ.get("MENTORKIT_MCP_CLIENTS", ",".join(MCP_CLIENTS))
    wanted = [c.strip().lower() for c in raw.split(",") if c.strip()]
    unknown = [c for c in wanted if c not in MCP_CLIENTS]
    if unknown:
        die(f"MENTORKIT_MCP_CLIENTS contiene clientes no soportados: {', '.join(unknown)} "
            f"(válidos: {', '.join(MCP_CLIENTS)})")
    return wanted

def configure_mcp(install=True):
    """Installs (pinned + checksum) and configures codebase-memory-mcp. 0 = all good."""
    if os.environ.get("MENTORKIT_SKIP_MCP"):
        log("  i MENTORKIT_SKIP_MCP activo: se omite codebase-memory-mcp")
        return 0
    clients = selected_clients()
    binary = install_mcp_binary() if install else find_mcp_binary()
    if not binary:
        log(f"  x {CBM_NAME} no disponible; los agentes no quedan configurados")
        return 1
    failed = 0
    for client in clients:
        status, detail = configure_client(client, binary)
        log(f"  {'+' if status == 'ok' else 'x'} {client}: {detail}")
        failed += status != "ok"
    return 1 if failed else 0

# --- verification -------------------------------------------------------------

def mcp_handshake(binary, timeout=45):
    """Real MCP session over stdio: initialize + tools/list. -> (ok, info)."""
    import queue, threading
    cache = tempfile.mkdtemp(prefix="mentorkit-cbm-cache-")
    env = dict(os.environ, CBM_CACHE_DIR=cache)
    try:
        proc = subprocess.Popen([str(binary)], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, text=True, env=env)
    except OSError as exc:
        shutil.rmtree(cache, ignore_errors=True)
        return False, {"error": str(exc)}
    lines = queue.Queue()
    threading.Thread(target=lambda: [lines.put(l) for l in proc.stdout], daemon=True).start()
    msgs = [
        {"jsonrpc": "2.0", "id": 1, "method": "initialize",
         "params": {"protocolVersion": "2024-11-05", "capabilities": {},
                    "clientInfo": {"name": "mentorkit-verify", "version": "1"}}},
        {"jsonrpc": "2.0", "method": "notifications/initialized"},
        {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
    ]
    info, replies = {}, {}
    try:
        proc.stdin.write("".join(json.dumps(m) + "\n" for m in msgs))
        proc.stdin.flush()
        import time
        deadline = time.monotonic() + timeout
        while len(replies) < 2 and time.monotonic() < deadline:
            try:
                msg = json.loads(lines.get(timeout=1))
            except queue.Empty:
                continue
            except ValueError:
                continue
            if isinstance(msg, dict) and "id" in msg:
                replies[msg["id"]] = msg
        init = replies.get(1, {}).get("result", {})
        tools = replies.get(2, {}).get("result", {}).get("tools", [])
        info = {"server": init.get("serverInfo", {}), "tools": len(tools)}
        ok = bool(init) and len(tools) > 0
        if not ok:
            info["error"] = "el servidor no completó initialize/tools/list"
        return ok, info
    except OSError as exc:
        return False, {"error": str(exc)}
    finally:
        try:
            proc.stdin.close()
        except OSError:
            pass
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
        shutil.rmtree(cache, ignore_errors=True)

def _client_points_to(client):
    """-> (configured_command or None, config path) read back from disk."""
    def json_cmd(path, section):
        data, err = _read_json_object(path)
        cmd = ((data or {}).get(section) or {}).get(CBM_NAME, {}).get("command")
        return cmd[0] if isinstance(cmd, list) and cmd else cmd
    if client == "claude":
        p = claude_config_path(); return json_cmd(p, "mcpServers"), p
    if client == "cursor":
        p = cursor_config_path(); return json_cmd(p, "mcpServers"), p
    if client == "opencode":
        p = opencode_config_paths()[0]; return json_cmd(p, "mcp"), p
    if client == "codex":
        p = codex_config_path()
        try:
            text = p.read_text(encoding="utf-8-sig")
        except OSError:
            return None, p
        try:
            import tomllib
            return tomllib.loads(text).get("mcp_servers", {}).get(CBM_NAME, {}).get("command"), p
        except ImportError:  # Python < 3.11 (verify may run on a system interpreter)
            import re
            m = re.search(rf'^\[mcp_servers\.{re.escape(CBM_NAME)}\][^\[]*?^command\s*=\s*("(?:[^"\\]|\\.)*")', text, re.M | re.S)
            return (json.loads(m.group(1)) if m else None), p
        except ValueError:
            return None, p
    return None, None

def verify_mcp():
    """Checks binary, a live MCP handshake, and every selected agent config."""
    if os.environ.get("MENTORKIT_SKIP_MCP"):
        return {"skipped": True, "ok": True}
    binary = find_mcp_binary()
    out = {"binary": str(binary) if binary else None, "version": None, "handshake": None,
           "tools": 0, "clients": {}, "pinned": CBM_VERSION.lstrip("v")}
    if binary:
        out["version"] = mcp_version(binary)
        ok, info = mcp_handshake(binary)
        out["handshake"], out["tools"] = ok, info.get("tools", 0)
        if not ok:
            out["error"] = info.get("error")
    for client in selected_clients():
        cmd, path = _client_points_to(client)
        out["clients"][client] = {"ok": bool(cmd) and Path(cmd).is_file(),
                                  "command": cmd, "config": str(path) if path else None}
    out["ok"] = bool(binary and out["handshake"] and out["version"] == out["pinned"]
                     and all(c["ok"] for c in out["clients"].values()))
    return out

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
    data["mcp"] = verify_mcp()
    ok = data["python_ok"] and data["all_deps_ok"] and data["lock_exists"] and data["mcp"]["ok"]
    if json_mode:
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        log(f"  + Python: {data['python']}")
        log(f"  + Platform: {data['platform']}")
        for n,v in data["deps"].items():
            log(f"  + {n}: {v.get('version','?')}")
        m = data["mcp"]
        if m.get("skipped"):
            log("  i codebase-memory-mcp: omitido (MENTORKIT_SKIP_MCP)")
        else:
            log(f"  {'+' if m['handshake'] else 'x'} codebase-memory-mcp: {m['version'] or 'no encontrado'} "
                f"(esperado {m['pinned']}), handshake {'OK' if m['handshake'] else 'FALLO'}, {m['tools']} herramientas")
            for c, v in m["clients"].items():
                log(f"  {'+' if v['ok'] else 'x'} {c}: {v['config']}")
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
    sub.add_parser("configure-mcp")
    t=sub.add_parser("odd-task"); t.add_argument("feature"); t.add_argument("request")
    raw_args = sys.argv[1:]
    # Backward-compatible alias for older launchers that invoked --fix.
    if raw_args and raw_args[0] == "--fix":
        raw_args[0] = "fix"
    a=ap.parse_args(raw_args)
    if a.cmd in ("install","fix"):
        ensure_files(); uv=install_uv(); ensure_python(uv); py=ensure_venv(uv); install_deps(uv,py); mcp_rc=configure_mcp(); rc=verify(False); raise SystemExit(rc or mcp_rc)
    if a.cmd=="configure-mcp": raise SystemExit(configure_mcp())
    if a.cmd=="verify": raise SystemExit(verify(a.json))
    if a.cmd=="odd-task": odd_task(a.feature,a.request)

if __name__=="__main__":
    main()
