#!/usr/bin/env bash
# =============================================================================
# MentorKit — Instalador autónomo para cualquier proyecto
#
# Uso recomendado:
#   bash .opencode/install-mentorkit.sh
#
# Bootstrap directo desde GitHub:
#   bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/main/.opencode/install-mentorkit.sh")
#
# Para probar una rama:
#   MENTORKIT_BRANCH=feature/odd-migration \
#   bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/feature/odd-migration/.opencode/install-mentorkit.sh")
#
# El instalador:
#   1. Usa los archivos locales cuando existen.
#   2. Si faltan archivos, los recupera desde GitHub.
#   3. Prepara uv + Python 3.12.13.
#   4. Crea/repara .opencode/.mentorkit/venv.
#   5. Instala requirements.lock.
#   6. Verifica dependencias y MCP.
#
# No contiene credenciales ni depende de GitLab privado.
# =============================================================================

set -uo pipefail

REPO="thewild001/MentorKit"
GITHUB_RAW_HOST="https://raw.githubusercontent.com"
BRANCH="${MENTORKIT_BRANCH:-main}"

PYTHON_VERSION="3.12"
PYTHON_PATCH="3.12.13"
VENV_DIR=".opencode/.mentorkit/venv"
VENV_PYTHON=""
LOCK_FILE="${PWD}/.opencode/requirements.lock"

MODE="install"

# Archivos mínimos para que el runtime ODD quede operativo.
# Las demás skills pueden mantenerse/copiarse mediante bootstrap.sh.
REQUIRED_FILES=(
    ".opencode/skills/odd-orchestrator/SKILL.md"
    ".opencode/skills/codebase-conformist/SKILL.md"
    ".opencode/skills/codebase-graph/SKILL.md"
    ".opencode/skills/spec-writer/SKILL.md"
    ".opencode/skills/prd-reader/SKILL.md"
    ".opencode/skills/document-extractor/SKILL.md"
    ".opencode/skills/llm-council/SKILL.md"
    ".opencode/agents/MentorKit5.0.md"
    ".opencode/mentorkit-python.sh"
    ".opencode/mentorkit-verify.sh"
    ".opencode/requirements.in"
    ".opencode/requirements.lock"
)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
[[ ! -t 1 ]] && RED='' GREEN='' YELLOW='' CYAN='' BOLD='' DIM='' RESET=''

ok()   { echo -e "  ${GREEN}+ ${RESET} $*"; }
warn() { echo -e "  ${YELLOW}! ${RESET} $*"; }
err()  { echo -e "  ${RED}x ${RESET} $*" >&2; }
info() { echo -e "     ${DIM}$*${RESET}"; }
step() { echo -e "\n${BOLD}-- $1${RESET}\n"; }

find_first_executable() {
    local p
    for p in "$@"; do
        [[ -x "$p" ]] && { echo "$p"; return 0; }
    done
    return 1
}

find_venv_python() {
    local base="${PWD}/${VENV_DIR}"
    find_first_executable "$base/bin/python" "$base/bin/python3" "$base/Scripts/python.exe"
}

find_venv_uv() {
    local base="${PWD}/${VENV_DIR}"
    find_first_executable "$base/bin/uv" "$base/Scripts/uv.exe"
}

find_system_python() {
    local py
    for py in python3 python py; do
        command -v "$py" &>/dev/null && { echo "$py"; return 0; }
    done
    return 1
}

download_file() {
    local path="$1"
    local dest="${PWD}/$path"
    local url="${GITHUB_RAW_HOST}/${REPO}/${BRANCH}/$path"

    mkdir -p "$(dirname "$dest")"

    if command -v curl &>/dev/null; then
        curl -fsSL --retry 3 --retry-delay 2 --max-time 180 "$url" -o "$dest" 2>/dev/null ||
            { err "Fallo descargando: $path"; return 1; }
    elif command -v wget &>/dev/null; then
        wget -q --tries=3 --timeout=60 -O "$dest" "$url" 2>/dev/null ||
            { err "Fallo descargando: $path"; return 1; }
    else
        err "Se requiere curl o wget"
        return 1
    fi

    [[ ! -s "$dest" ]] && { err "Archivo vacío: $path"; rm -f "$dest"; return 1; }

    if head -5 "$dest" 2>/dev/null | grep -qiE "<!DOCTYPE|<html"; then
        err "GitHub devolvió contenido HTML en lugar de: $path"
        rm -f "$dest"
        return 1
    fi

    ok "$path"
}

ensure_runtime_files() {
    step "Archivos MentorKit"

    local missing=0
    local f

    for f in "${REQUIRED_FILES[@]}"; do
        if [[ -f "${PWD}/$f" ]]; then
            ok "local: $f"
        else
            info "faltante: $f — descargando desde GitHub (${BRANCH})"
            download_file "$f" || missing=$((missing + 1))
        fi
    done

    if (( missing > 0 )); then
        err "$missing archivo(s) requeridos no pudieron recuperarse"
        info "Repositorio: https://github.com/${REPO}"
        info "Rama: ${BRANCH}"
        return 1
    fi

    return 0
}

ensure_uv() {
    if command -v uv &>/dev/null; then
        ok "uv en PATH: $(uv --version 2>/dev/null)"
        return 0
    fi

    local venv_uv
    if venv_uv="$(find_venv_uv 2>/dev/null)"; then
        export PATH="$(dirname "$venv_uv"):$PATH"
        ok "uv del venv: $(uv --version 2>/dev/null)"
        return 0
    fi

    info "uv no detectado — instalando desde astral.sh..."
    if INSTALLER_NO_MODIFY_PATH=1 curl -LsSf --max-time 60         https://astral.sh/uv/install.sh 2>/dev/null | bash 2>/dev/null; then
        [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
        [[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
        command -v uv &>/dev/null && {
            ok "uv instalado: $(uv --version 2>/dev/null)"
            return 0
        }
    fi

    local system_python
    if system_python="$(find_system_python 2>/dev/null)"; then
        info "Bootstrap alternativo: pip install uv en venv temporal"
        local tmp_root tmpv tmp_pip tmp_uv
        tmp_root="$(mktemp -d)"
        tmpv="$tmp_root/uv-bootstrap"

        if "$system_python" -m venv "$tmpv" 2>/dev/null; then
            tmp_pip="$(find_first_executable "$tmpv/bin/pip" "$tmpv/bin/pip3" "$tmpv/Scripts/pip.exe" 2>/dev/null || true)"
            if [[ -n "$tmp_pip" ]] && "$tmp_pip" install --quiet uv 2>/dev/null; then
                tmp_uv="$(find_first_executable "$tmpv/bin/uv" "$tmpv/Scripts/uv.exe" 2>/dev/null || true)"
                if [[ -n "$tmp_uv" ]]; then
                    export PATH="$(dirname "$tmp_uv"):$PATH"
                    ok "uv bootstrapeado via pip: $(uv --version 2>/dev/null)"
                    return 0
                fi
            fi
        fi
        rm -rf "$tmp_root"
    fi

    err "No se pudo obtener uv"
    info "Instalación manual: https://docs.astral.sh/uv/"
    return 1
}

ensure_python_312() {
    step "Python $PYTHON_PATCH"

    if uv python find "$PYTHON_VERSION" &>/dev/null; then
        local py actual_ver
        py="$(uv python find "$PYTHON_VERSION" 2>/dev/null)"
        actual_ver="$("$py" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null)"
        if [[ "$actual_ver" == "$PYTHON_PATCH" ]]; then
            ok "Python $actual_ver disponible"
        else
            warn "Python $actual_ver disponible; objetivo $PYTHON_PATCH"
        fi
        return 0
    fi

    info "Descargando Python $PYTHON_VERSION mediante uv..."
    uv python install "$PYTHON_VERSION" >/dev/null 2>&1 || {
        err "Falló la instalación de Python $PYTHON_VERSION"
        return 1
    }
    ok "Python $PYTHON_VERSION instalado"
}

create_or_repair_venv() {
    step "Entorno virtual"

    local need_create=false
    local reason=""
    local actual_ver

    if [[ ! -d "${PWD}/${VENV_DIR}" ]]; then
        need_create=true
        reason="no existe"
    elif ! VENV_PYTHON="$(find_venv_python 2>/dev/null)"; then
        need_create=true
        reason="estructura inválida"
    else
        actual_ver="$("$VENV_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)"
        if [[ "$actual_ver" != "$PYTHON_VERSION" ]]; then
            warn "Venv usa Python $actual_ver; recreando con $PYTHON_VERSION"
            rm -rf "${PWD}/${VENV_DIR}"
            need_create=true
            reason="versión incompatible"
        else
            ok "Venv existente OK: $VENV_DIR"
        fi
    fi

    if $need_create; then
        info "Creando venv ($reason)..."
        mkdir -p "${PWD}/.opencode/.mentorkit"
        uv venv --python "$PYTHON_VERSION" "${PWD}/${VENV_DIR}" >/dev/null 2>&1 || {
            err "uv venv falló"
            return 1
        }
        ok "Venv creado"
    fi

    VENV_PYTHON="$(find_venv_python)" || {
        err "No se pudo localizar Python del venv"
        return 1
    }

    echo "$VENV_PYTHON" > "${PWD}/.opencode/.mentorkit/python-path.txt"

    local gi="${PWD}/.opencode/.gitignore"
    grep -q "^\.mentorkit/$" "$gi" 2>/dev/null || echo ".mentorkit/" >> "$gi"
}

install_deps_from_lock() {
    step "Dependencias"

    [[ -f "$LOCK_FILE" ]] || {
        err "No existe $LOCK_FILE"
        return 1
    }

    local pkg_count
    pkg_count="$(grep -cE "^[a-zA-Z]" "$LOCK_FILE" 2>/dev/null || echo 0)"
    info "$pkg_count paquetes pinneados en requirements.lock"

    uv pip install --python "$VENV_PYTHON" -r "$LOCK_FILE" --quiet 2>/dev/null || {
        err "Falló la instalación desde requirements.lock"
        info "Puedes diagnosticar con: uv pip install --python $VENV_PYTHON -r $LOCK_FILE"
        return 1
    }

    ok "Dependencias instaladas"
}

verify_install() {
    step "Verificación"

    [[ -x "$VENV_PYTHON" ]] || {
        err "Venv no existe o no es ejecutable"
        return 1
    }

    local py_ver
    py_ver="$("$VENV_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null)"
    [[ "$py_ver" == "$PYTHON_PATCH" ]] && ok "Python $py_ver" || warn "Python $py_ver (objetivo $PYTHON_PATCH)"

    local fail=0
    "$VENV_PYTHON" -c '
import importlib.metadata as md
deps = [
    ("markitdown", "markitdown"),
    ("firecrawl-anydoc", "anydoc"),
    ("striprtf", "striprtf"),
    ("graphifyy", "graphify"),
    ("uv", "uv"),
]
ok = True
for name, import_name in deps:
    try:
        __import__(import_name)
        print(f"  + {name} {md.version(name)}")
    except Exception as exc:
        print(f"  x {name}: {type(exc).__name__}: {exc}")
        ok = False
raise SystemExit(0 if ok else 1)
' || fail=1

    if command -v codebase-memory-mcp &>/dev/null; then
        ok "MCP codebase-memory-mcp: $(codebase-memory-mcp --version 2>/dev/null || echo OK)"
    else
        warn "MCP codebase-memory-mcp no encontrado"
        info "Opcional para el flujo ODD: instala codebase-memory-mcp si el proyecto lo utiliza"
    fi

    if (( fail == 0 )); then
        ok "Verificación PASS"
        return 0
    fi

    err "Verificación FAIL"
    return 1
}

print_banner() {
    echo -e "${CYAN}"
    cat <<'BANNER'

  ┌───────────────────────────────────────────────────────┐
  │                                                       │
  │   __  __            _             _  ___ _            │
  │  |  \/  | ___ _ __ | |_ ___  _ __| |/ (_) |_          │
  │  | |\/| |/ _ \ '_ \| __/ _ \| '__| ' /| | __|         │
  │  | |  | |  __/ | | | || (_) | |  | . \| | |_          │
  │  |_|  |_|\___|_| |_|\__\___/|_|  |_|\_\_|\__|         │
  │                                                       │
  │              Agentic Engineering Mentor              │
  │                       ODD                             │
  │                                                       │
  └───────────────────────────────────────────────────────┘

BANNER
    echo -e "${RESET}"
}

run_install() {
    echo -e "\n  ${CYAN}MentorKit${RESET}  ${DIM}ODD — Agentic Engineering Workflow${RESET}"
    echo -e "  ${DIM}GitHub: https://github.com/${REPO} @ ${BRANCH}${RESET}\n"

    ensure_runtime_files || exit 1
    ensure_uv || exit 1
    ensure_python_312 || exit 1
    create_or_repair_venv || exit 1
    install_deps_from_lock || exit 1

    step "Instalación completada"
    echo -e "  ${GREEN}+ ${RESET} ${BOLD}MentorKit listo${RESET}"
    echo -e "  ${DIM}Workflow: ODD (SMALL / SUBSTANTIAL)${RESET}"
    echo -e "  ${DIM}Runtime: .opencode/.mentorkit/venv/${RESET}"
    echo -e "  ${DIM}Siguiente: abre OpenCode en este proyecto y selecciona MentorKit5.0${RESET}\n"
    print_banner
}

run_verify() {
    echo -e "\n  ${CYAN}MentorKit — verify${RESET}\n"
    VENV_PYTHON="$(find_venv_python 2>/dev/null)" || {
        err "Venv no existe — ejecuta install primero"
        exit 1
    }
    verify_install
}

run_fix() {
    echo -e "\n  ${CYAN}MentorKit — fix${RESET}\n"
    ensure_runtime_files || exit 1
    ensure_uv || exit 1
    ensure_python_312 || exit 1
    create_or_repair_venv || exit 1
    install_deps_from_lock || exit 1
    verify_install
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verify|-v) MODE="verify" ;;
        --fix|-f) MODE="fix" ;;
        --help|-h)
            cat <<'HELP'
Uso: bash install-mentorkit.sh [opción]

Opciones:
  (sin args)  Instala o repara MentorKit.
  --verify    Verifica el entorno sin instalar dependencias.
  --fix       Recupera archivos faltantes y repara el entorno.
  --help      Muestra esta ayuda.

Variables:
  MENTORKIT_BRANCH=main|<branch>
      Rama de MentorKit desde la que recuperar archivos faltantes.

Ejemplo de prueba de una rama:
  MENTORKIT_BRANCH=feature/odd-migration bash install-mentorkit.sh
HELP
            exit 0
            ;;
        *) err "Opción desconocida: $1 (usa --help)"; exit 1 ;;
    esac
    shift
done

case "$MODE" in
    install) run_install ;;
    verify) run_verify ;;
    fix) run_fix ;;
esac
