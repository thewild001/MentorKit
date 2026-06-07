#!/usr/bin/env bash
# =============================================================================
#  MentorKit — Instalador para cualquier proyecto
#  Uso desde la raíz de TU PROYECTO:
#
#    bash <(curl -fsSLk https://gitlab.prod.uci.cu/fortes/mentorkit/-/raw/main/.opencode/install-mentorkit.sh)
#
#  Garantías (verificadas al final con verify_install):
#    1. Python 3.12.x LTS (descargado por uv si el sistema no lo tiene)
#    2. Dependencias pinneadas con SHA256 (mismas versiones, mismos hashes)
#    3. Re-install idempotente (<1s) — uv detecta que todo está al día
#    4. Verificación post-install: import test de markitdown, striprtf, graphifyy, uv
#
#  Comandos:
#    bash install-mentorkit.sh            # install/repair (default)
#    bash install-mentorkit.sh --verify   # solo verifica, no modifica nada
#    bash install-mentorkit.sh --fix      # verifica y repara lo que falle
# =============================================================================

set -uo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────

GITLAB_URL="${MENTORKIT_GITLAB_URL:-https://gitlab.prod.uci.cu}"
GITLAB_NAMESPACE="${MENTORKIT_NAMESPACE:-fortes/mentorkit}"
GITLAB_PROJECT_ID="${MENTORKIT_PROJECT_ID:-2707}"
BRANCH="${MENTORKIT_BRANCH:-main}"
# TOKEN: distinguir "unset" (usar default) de "set explícitamente a string
# vacío" (fallar claro). ${VAR-default} hace lo primero; ${VAR:-default} colapsa
# ambos casos, lo que oculta bugs cuando el usuario exporta MENTORKIT_TOKEN=
# por error y obtiene el token de lectura del repo en vez de un error.
TOKEN="${MENTORKIT_TOKEN-glpat-RhMcJxUMWSx5N0tkYKStlm86MQp1OjI2bAk.01.0z1ay31li}"
if [[ -z "$TOKEN" ]]; then
    # echo directo (no err()): las utilidades se definen más abajo.
    echo "  x  MENTORKIT_TOKEN está seteado a string vacío." >&2
    echo "     Si quieres usar el token default, haz: unset MENTORKIT_TOKEN" >&2
    echo "     Si quieres usar tu propio token, expórtalo con un valor real:" >&2
    echo "         export MENTORKIT_TOKEN=glpat-xxxxx" >&2
    exit 1
fi
export MENTORKIT_TOKEN="$TOKEN"

# ─── Garantías (constantes) ──────────────────────────────────────────────────

# Python LTS pin (Ubuntu 24.04, Debian 12, RHEL 9 default)
PYTHON_VERSION="3.12"
# 3.12.13 es la última 3.12.x estable al 2026-06-04 (pinned para reproducibilidad)
PYTHON_PATCH="3.12.13"

VENV_DIR=".opencode/.mentorkit/venv"
VENV_PYTHON=""
LOCK_FILE="${PWD}/.opencode/requirements.lock"
IN_FILE="${PWD}/.opencode/requirements.in"

MODE="install"   # install | verify | fix

# ─── Archivos a descargar ────────────────────────────────────────────────────

FILES=(
    ".opencode/skills/codebase-conformist/SKILL.md"
    ".opencode/skills/codebase-graph/SKILL.md"
    ".opencode/skills/spec-writer/SKILL.md"
    ".opencode/skills/prd-reader/SKILL.md"
    ".opencode/skills/document-extractor/SKILL.md"
    ".opencode/skills/llm-council/SKILL.md"
    ".opencode/agents/MentorKit4.0.md"
    ".opencode/mentorkit-python.sh"
    ".opencode/mentorkit-verify.sh"
    ".opencode/requirements.in"
    ".opencode/requirements.lock"
)

# ─── Utilidades ───────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
[[ ! -t 1 ]] && RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; DIM=''; RESET=''

ok()   { echo -e "  ${GREEN}+${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}x${RESET}  $*" >&2; }
info() { echo -e "     ${DIM}$*${RESET}"; }
step() { echo -e "\n${BOLD}-- $1${RESET}\n"; }

# ─── Localización de ejecutables ──────────────────────────────────────────────

find_venv_python() {
    local base="${PWD}/${VENV_DIR}"
    for p in "$base/bin/python" "$base/bin/python3" "$base/Scripts/python.exe"; do
        [[ -f "$p" && -x "$p" ]] && { echo "$p"; return 0; }
    done
    return 1
}

# ─── Descarga ─────────────────────────────────────────────────────────────────

download_file() {
    local path="$1" dest="${PWD}/$1"
    local encoded_path="${path//\//%2F}"
    local url="${GITLAB_URL}/api/v4/projects/${GITLAB_PROJECT_ID}/repository/files/${encoded_path}/raw?ref=${BRANCH}"
    mkdir -p "$(dirname "$dest")"

    if command -v curl &>/dev/null; then
        local args=(-fsSLk --retry 3 --retry-delay 2)
        [[ -n "$TOKEN" ]] && args+=(-H "PRIVATE-TOKEN: $TOKEN")
        curl "${args[@]}" "$url" -o "$dest" 2>/dev/null || { err "Fallo: $path"; return 1; }
    elif command -v wget &>/dev/null; then
        local args=(-q --tries=3 --no-check-certificate -O "$dest")
        [[ -n "$TOKEN" ]] && args+=(--header "PRIVATE-TOKEN: $TOKEN")
        wget "${args[@]}" "$url" -o "$dest" 2>/dev/null || { err "Fallo: $path"; return 1; }
    else
        err "Se requiere curl o wget"; return 1
    fi

    [[ ! -s "$dest" ]] && { err "Archivo vacío: $path"; rm -f "$dest"; return 1; }
    head -1 "$dest" 2>/dev/null | grep -qi "<!DOCTYPE\|<html" && {
        err "Acceso denegado: $path"
        [[ -z "$TOKEN" ]] && info "¿Repo privado? Usa: export MENTORKIT_TOKEN=glpat-xxxx"
        rm -f "$dest"; return 1; }

    ok "$path"
}

# ─── uv: detección + bootstrap ───────────────────────────────────────────────

# Encuentra un uv utilizable. Orden de prioridad:
#   1. uv en PATH
#   2. uv dentro del venv existente (de un install previo, autocontenido)
#   3. uv auto-instalado via curl | bash desde astral.sh
#   4. uv instalado via pip en un venv temporal (Python del sistema)
# Retorna 0 si uv quedó disponible, 1 si no.
ensure_uv() {
    if command -v uv &>/dev/null; then
        ok "uv en PATH: $(uv --version 2>/dev/null)"
        return 0
    fi

    # Venv existente con uv (autocontención)
    if [[ -x "${PWD}/${VENV_DIR}/bin/uv" ]]; then
        export PATH="${PWD}/${VENV_DIR}/bin:$PATH"
        ok "uv del venv (autocontenido): $(uv --version 2>/dev/null)"
        return 0
    fi

    # Auto-instalar via curl (preferido: trae un binario optimizado)
    info "uv no detectado — instalando desde astral.sh..."
    if INSTALLER_NO_MODIFY_PATH=1 curl -LsSf --max-time 60 \
            https://astral.sh/uv/install.sh 2>/dev/null | bash 2>/dev/null; then
        [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
        [[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"
        if command -v uv &>/dev/null; then
            ok "uv instalado: $(uv --version 2>/dev/null)"
            return 0
        fi
        warn "uv instalado pero no en PATH"
    else
        warn "Falló instalación de uv desde astral.sh"
    fi

    # Último recurso: pip install uv en venv temporal con Python del sistema
    if command -v python3 &>/dev/null; then
        info "Bootstrap alternativo: pip install uv en venv temporal"
        local tmpv
        tmpv="$(mktemp -d)/uv-bootstrap"
        if python3 -m venv "$tmpv" 2>/dev/null \
                && "$tmpv/bin/pip" install --quiet uv 2>/dev/null \
                && [[ -x "$tmpv/bin/uv" ]]; then
            export PATH="$tmpv/bin:$PATH"
            ok "uv bootstrapeado via pip: $(uv --version 2>/dev/null)"
            return 0
        fi
        rm -rf "$tmpv"
    fi

    err "No se pudo obtener uv (prueba instalarlo manualmente: https://docs.astral.sh/uv/)"
    return 1
}

# ─── Python 3.12 garantizado ─────────────────────────────────────────────────

# Garantiza que uv tenga Python 3.12.x disponible. Si no, lo descarga.
ensure_python_312() {
    step "Python 3.${PYTHON_VERSION#3.} garantizado"

    # Chequear si uv ya tiene 3.12 instalado
    if uv python find "$PYTHON_VERSION" &>/dev/null; then
        local py
        py="$(uv python find "$PYTHON_VERSION" 2>/dev/null)"
        local actual_ver
        actual_ver="$("$py" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null)"
        if [[ "$actual_ver" == "$PYTHON_PATCH" ]]; then
            ok "Python $actual_ver disponible (match exacto)"
        else
            warn "Python $actual_ver disponible (target: $PYTHON_PATCH — aceptable)"
        fi
        return 0
    fi

    # Descargar 3.12 via uv
    info "Descargando Python $PYTHON_PATCH via uv..."
    if uv python install "$PYTHON_VERSION" 2>&1 | tail -3; then
        ok "Python $PYTHON_VERSION instalado"
    else
        err "Falló descarga de Python $PYTHON_VERSION"
        return 1
    fi
}

# ─── Venv con Python 3.12 ────────────────────────────────────────────────────

create_or_repair_venv() {
    step "Entorno virtual"

    local need_create=false
    local need_repair_reason=""

    if [[ ! -d "${PWD}/${VENV_DIR}" ]]; then
        need_create=true
        need_repair_reason="no existe"
    elif ! VENV_PYTHON="$(find_venv_python 2>/dev/null)"; then
        need_create=true
        need_repair_reason="estructura inválida"
    else
        # Chequear versión del Python
        local actual_ver
        actual_ver="$("$VENV_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)"
        if [[ "$actual_ver" != "$PYTHON_VERSION" ]]; then
            warn "Venv tiene Python $actual_ver (target: $PYTHON_VERSION) — recreando"
            rm -rf "${PWD}/${VENV_DIR}"
            need_create=true
            need_repair_reason="Python version mismatch"
        else
            ok "Venv existente OK: ${VENV_DIR}/ (Python $actual_ver)"
        fi
    fi

    if $need_create; then
        info "Creando venv con Python $PYTHON_VERSION (razón: $need_repair_reason)"
        mkdir -p "${PWD}/.opencode/.mentorkit"
        if uv venv --python "$PYTHON_VERSION" "${PWD}/${VENV_DIR}" 2>/dev/null; then
            ok "Venv creado: ${VENV_DIR}/"
        else
            err "uv venv falló"
            return 1
        fi
    fi

    # Localizar Python (post-create o reuso)
    VENV_PYTHON="$(find_venv_python)" || {
        err "No se pudo localizar Python del venv"; return 1; }

    # Guardar ruta para skills
    echo "$VENV_PYTHON" > "${PWD}/.opencode/.mentorkit/python-path.txt"

    # .gitignore: ignorar .mentorkit/ (si no está)
    local gi="${PWD}/.opencode/.gitignore"
    grep -q ".mentorkit" "$gi" 2>/dev/null || echo ".mentorkit/" >> "$gi"

    info "Python: $VENV_PYTHON"
}

# ─── Instalación de deps desde el lock ───────────────────────────────────────

install_deps_from_lock() {
    step "Dependencias (lock file)"

    if [[ ! -f "$LOCK_FILE" ]]; then
        err "Lock file no encontrado: $LOCK_FILE"
        info "Re-ejecuta el installer desde un proyecto con .opencode/ completo"
        return 1
    fi

    local pkg_count
    pkg_count="$(grep -cE "^[a-zA-Z]" "$LOCK_FILE" 2>/dev/null || echo 0)"
    info "Lock file: $pkg_count paquetes pinneados con SHA256"

    # uv install con hashes (uv valida hashes por default con --generate-hashes)
    echo -n "     Instalando desde requirements.lock..."
    if uv pip install --python "$VENV_PYTHON" -r "$LOCK_FILE" --quiet 2>/dev/null; then
        echo -e "  ${GREEN}OK${RESET}"
        # Listar deps principales
        uv pip list --python "$VENV_PYTHON" --quiet 2>/dev/null \
            | grep -iE "^(markitdown|striprtf|graphifyy|uv)\b" \
            | while read -r line; do ok "$line"; done
    else
        echo -e "  ${RED}Error${RESET}"
        err "Falló install desde lock file"
        info "Manual: uv pip install --python $VENV_PYTHON -r $LOCK_FILE"
        return 1
    fi
}

# ─── Verificación post-install ───────────────────────────────────────────────

# Verifica que Python 3.12, uv, y todos los deps están OK.
# Retorna 0 si todo pasa, 1 si algo falla.
verify_install() {
    step "Verificación"

    if [[ ! -x "$VENV_PYTHON" ]]; then
        err "Venv no existe o no es ejecutable"
        return 1
    fi

    # Verificar versión de Python
    local py_ver
    py_ver="$("$VENV_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")' 2>/dev/null)"
    if [[ "$py_ver" != "$PYTHON_PATCH" ]]; then
        warn "Python $py_ver (target: $PYTHON_PATCH)"
    else
        ok "Python $py_ver"
    fi

    # Verificar imports
    local fail=0
    "$VENV_PYTHON" -c "
import sys, importlib.metadata as md

# (distribution_name, import_name) — algunos paquetes tienen nombres distintos
deps = [
    ('markitdown', 'markitdown'),
    ('striprtf',   'striprtf'),
    ('graphifyy',  'graphify'),   # PyPI: graphifyy, import: graphify
    ('uv',         'uv'),
]

ok = True
for name, import_name in deps:
    try:
        mod = __import__(import_name)
        ver = md.version(name)
        print(f'  + {name} {ver}')
    except ImportError:
        print(f'  x {name}: NO INSTALADO')
        ok = False
    except Exception as e:
        print(f'  x {name}: {type(e).__name__}: {e}')
        ok = False

sys.exit(0 if ok else 1)
" 2>/dev/null
    fail=$?

    if [[ $fail -eq 0 ]]; then
        echo ""
        ok "Verificación PASS — entorno listo"
        print_banner
        return 0
    else
        echo ""
        err "Verificación FAIL — ejecuta con --fix para reparar"
        return 1
    fi
}

# ─── Modos de operación ──────────────────────────────────────────────────────

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
  │           Agentic Mentor for Legacy Code              │
  │                   Version 4.0                         │
  │                                                       │
  └───────────────────────────────────────────────────────┘

BANNER
    echo -e "${RESET}"
}

run_install() {
    echo -e "\n  ${CYAN}MentorKit${RESET}  ${DIM}v4.0 — Agentic Mentor for Legacy Code${RESET}"
    echo -e "  ${DIM}GitLab: ${GITLAB_URL}/${GITLAB_NAMESPACE} @ ${BRANCH}${RESET}"
    echo -e "  ${DIM}Garantías: Python 3.${PYTHON_VERSION#3.} pinneado + lock file con hashes${RESET}\n"

    if [[ ! -d "${PWD}" ]]; then
        err "Directorio no válido: ${PWD}"; exit 1
    fi

    # Descargar .opencode/ si no existe
    if [[ -d "${PWD}/.opencode" ]]; then
        ok ".opencode/ ya existe — usando archivos locales"
    else
        step "Descargando .opencode/ desde GitLab"
        local errors=0
        for f in "${FILES[@]}"; do
            download_file "$f" || ((errors++)) || true
        done
        [[ $errors -gt 0 ]] && {
            err "$errors archivo(s) fallaron. Verifica URL y token."
            exit 1
        }
    fi

    # Verificar que lock file existe (prerrequisito)
    if [[ ! -f "$LOCK_FILE" ]]; then
        err "Lock file no encontrado: $LOCK_FILE"
        exit 1
    fi

    # Bootstrap uv
    ensure_uv || exit 1

    # Garantizar Python 3.12
    ensure_python_312 || exit 1

    # Crear/reparar venv
    create_or_repair_venv || exit 1

    # Instalar deps desde lock
    install_deps_from_lock || exit 1

    # Resumen
    step "Instalación completada"
    echo -e "  ${GREEN}+${RESET}  ${BOLD}MentorKit listo${RESET}\n"
    echo -e "  ${DIM}.opencode/${RESET}"
    echo -e "  ${DIM}+-- skills/codebase-conformist/SKILL.md${RESET}"
    echo -e "  ${DIM}+-- skills/codebase-graph/SKILL.md${RESET}"
    echo -e "  ${DIM}+-- skills/spec-writer/SKILL.md${RESET}"
    echo -e "  ${DIM}+-- skills/prd-reader/SKILL.md${RESET}"
    echo -e "  ${DIM}+-- skills/document-extractor/SKILL.md${RESET}"
    echo -e "  ${DIM}+-- skills/llm-council/SKILL.md${RESET}"
    echo -e "  ${DIM}+-- agents/MentorKit4.0.md${RESET}"
    echo -e "  ${DIM}+-- requirements.in${RESET}"
    echo -e "  ${DIM}+-- requirements.lock${RESET}  (${pkg_count:-53} pkgs, SHA256 pinneados)"
    echo -e "  ${DIM}+-- mentorkit-python.sh${RESET}  (wrapper para skills)"
    echo -e "  ${DIM}+-- mentorkit-verify.sh${RESET}  (verificación standalone)"
    echo -e "  ${DIM}\`-- .mentorkit/venv/${RESET}  (gitignored, Python $PYTHON_PATCH)\n"
    echo -e "  ${DIM}Próximo: inicia OpenCode y selecciona MentorKit4.0 con Tab${RESET}\n"

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
    ensure_uv || exit 1
    VENV_PYTHON="$(find_venv_python 2>/dev/null)" || {
        warn "Venv no existe — creando..."
    }

    if [[ -z "$VENV_PYTHON" ]]; then
        ensure_python_312 || exit 1
        create_or_repair_venv || exit 1
    else
        # Verificar versión
        local actual_ver
        actual_ver="$("$VENV_PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null)"
        if [[ "$actual_ver" != "$PYTHON_VERSION" ]]; then
            warn "Python $actual_ver ≠ $PYTHON_VERSION — recreando venv"
            ensure_python_312 || exit 1
            create_or_repair_venv || exit 1
        fi
    fi

    install_deps_from_lock || exit 1
    verify_install
}

# ─── Main ─────────────────────────────────────────────────────────────────────

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verify|-v)  MODE="verify" ;;
        --fix|-f)     MODE="fix" ;;
        --help|-h)
            echo "Uso: bash install-mentorkit.sh [opción]"
            echo ""
            echo "Opciones:"
            echo "  (sin args)  Install o repair (default)"
            echo "  --verify    Solo verifica, no modifica nada"
            echo "  --fix       Verifica y repara lo que falle"
            echo "  --help      Muestra esta ayuda"
            exit 0
            ;;
        *) err "Opción desconocida: $1 (usa --help)"; exit 1 ;;
    esac
    shift
done

case "$MODE" in
    install) run_install ;;
    verify)  run_verify ;;
    fix)     run_fix ;;
esac
