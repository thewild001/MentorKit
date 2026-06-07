#!/usr/bin/env bash
# .opencode/mentorkit-verify.sh
# Verificación standalone del entorno de MentorKit.
# Salida: exit 0 si todo OK, exit 1 si algo falla.
#
# Uso:
#   bash .opencode/mentorkit-verify.sh
#   bash .opencode/mentorkit-verify.sh --json    # salida JSON para CI

set -uo pipefail

VENV_DIR=".opencode/.mentorkit/venv"
PYTHON_VERSION="3.12"
PYTHON_PATCH="3.12.13"

# ─── Colores ─────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
[[ ! -t 1 ]] && RED=''; GREEN=''; YELLOW=''; BOLD=''; DIM=''; RESET=''

ok()   { echo -e "  ${GREEN}+${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}x${RESET}  $*"; }
info() { echo -e "     ${DIM}$*${RESET}"; }
step() { echo -e "\n${BOLD}-- $1${RESET}\n"; }

# ─── Localizar venv ──────────────────────────────────────────────────────────

VENV_PYTHON=""
for p in "$VENV_DIR/bin/python" "$VENV_DIR/bin/python3" "$VENV_DIR/Scripts/python.exe"; do
    [[ -f "$p" && -x "$p" ]] && { VENV_PYTHON="$p"; break; }
done

if [[ -z "$VENV_PYTHON" ]]; then
    err "Venv no encontrado en $VENV_DIR/"
    err "Ejecutá: bash .opencode/install-mentorkit.sh"
    exit 1
fi

# ─── Verificar ───────────────────────────────────────────────────────────────

JSON_OUTPUT=false
[[ "${1:-}" == "--json" ]] && JSON_OUTPUT=true

if $JSON_OUTPUT; then
    # Modo JSON: una sola llamada Python genera output válido
    "$VENV_PYTHON" -c "
import sys, os, importlib.metadata as md, json, subprocess, platform

py_ver = f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}'

# (distribution_name, import_name) — graphifyy (PyPI) se importa como 'graphify'
deps = [
    ('markitdown', 'markitdown'),
    ('striprtf',   'striprtf'),
    ('graphifyy',  'graphify'),
    ('uv',         'uv'),
]
result = {}
for dist_name, import_name in deps:
    try:
        ver = md.version(dist_name)
        # Verificar que el módulo también importa
        __import__(import_name)
        result[dist_name] = {'ok': True, 'version': ver, 'import': import_name}
    except Exception as e:
        result[dist_name] = {'ok': False, 'error': str(e)}

# Lock file platform coverage: dry-run install con el Python del venv
lock_file = '.opencode/requirements.lock'
lock_covers = False
lock_error = None
try:
    uv_bin = os.path.join(os.path.dirname(sys.executable), 'uv')
    proc = subprocess.run(
        [uv_bin, 'pip', 'install', '--dry-run', '--python', sys.executable, '-r', lock_file],
        capture_output=True, text=True, timeout=30
    )
    lock_covers = (proc.returncode == 0)
    if not lock_covers:
        lock_error = (proc.stderr or proc.stdout).strip().split('\n')[-1]
except Exception as e:
    lock_error = str(e)

output = {
    'python': py_ver,
    'target': '$PYTHON_PATCH',
    'python_ok': py_ver.startswith('$PYTHON_VERSION'),
    'lock_covers_platform': lock_covers,
    'platform': platform.platform(),
    'all_deps_ok': all(d.get('ok') for d in result.values()),
    'deps': result,
}
if lock_error:
    output['lock_error'] = lock_error
print(json.dumps(output, indent=2))
sys.exit(0 if output['python_ok'] and output['all_deps_ok'] and lock_covers else 1)
" 2>/dev/null
    exit $?
fi

# Modo human-readable
step "Verificación del entorno"

info "Python: $VENV_PYTHON"

# Chequear versión de Python
py_ver="$("$VENV_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null)"
if [[ "$py_ver" == "$PYTHON_PATCH" ]]; then
    ok "Python $py_ver (target exacto)"
elif [[ "$py_ver" == "$PYTHON_VERSION"* ]]; then
    warn "Python $py_ver (target: $PYTHON_PATCH — aceptable)"
else
    err "Python $py_ver (target: $PYTHON_VERSION.x) — ejecuta: bash .opencode/install-mentorkit.sh --fix"
    exit 1
fi

# Lock file platform coverage
echo ""
info "Verificando que el lock cubre esta plataforma..."
UV_BIN="$(dirname "$VENV_PYTHON")/uv"
if "$UV_BIN" pip install --dry-run --python "$VENV_PYTHON" -r .opencode/requirements.lock &>/dev/null; then
    ok "Lock file cubre $(uname -sm)"
else
    err "Lock file NO cubre $(uname -sm)"
    info "Regenerar con: uv pip compile .opencode/requirements.in --universal --python-version 3.12 --generate-hashes -o .opencode/requirements.lock"
    exit 1
fi

# Verificar imports
echo ""
info "Verificando imports..."
fail=0
"$VENV_PYTHON" -c "
import sys, importlib.metadata as md

deps = [
    ('markitdown', 'markitdown'),
    ('striprtf',   'striprtf'),
    ('graphifyy',  'graphify'),   # PyPI: graphifyy, import: graphify
    ('uv',         'uv'),
]

all_ok = True
for name, import_name in deps:
    try:
        __import__(import_name)
        ver = md.version(name)
        print(f'+ {name} {ver}')
    except ImportError:
        print(f'x {name} NO INSTALADO')
        all_ok = False
    except Exception as e:
        print(f'x {name} {type(e).__name__}: {e}')
        all_ok = False

sys.exit(0 if all_ok else 1)
" 2>/dev/null
fail=$?

echo ""
if [[ $fail -eq 0 ]]; then
    ok "PASS — entorno verificado"
    info "Re-install idempotente: bash .opencode/install-mentorkit.sh"
    exit 0
else
    err "FAIL — uno o más deps faltan o están rotos"
    info "Reparar: bash .opencode/install-mentorkit.sh --fix"
    exit 1
fi
