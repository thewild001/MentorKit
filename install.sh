#!/usr/bin/env bash
# =============================================================================
#  MentorKit — Instalador para Linux / macOS / Git Bash (Windows)
#  Descarga los archivos desde un repositorio GitLab e instala dependencias pip
# =============================================================================

set -uo pipefail

# ─── Configuración ────────────────────────────────────────────────────────────

GITLAB_URL="${MENTORKIT_GITLAB_URL:-https://gitlab.com}"
GITLAB_NAMESPACE="${MENTORKIT_NAMESPACE:-YOUR_GROUP/mentorkit}"
BRANCH="${MENTORKIT_BRANCH:-main}"
TOKEN="${MENTORKIT_TOKEN:-}"
TARGET="${PWD}"
YES=false
CHECK=false
SKIP_GITIGNORE=false
SKIP_DEPS=false
IS_GIT=false
PYTHON=""
DOWNLOADER=""

# ─── Archivos a instalar ──────────────────────────────────────────────────────

FILES=(
    ".opencode/skills/codebase-conformist/SKILL.md"
    ".opencode/skills/spec-writer/SKILL.md"
    ".opencode/skills/prd-reader/SKILL.md"
    ".opencode/skills/document-extractor/SKILL.md"
    ".opencode/skills/llm-council/SKILL.md"
    ".opencode/agents/dev-guide.md"
)

PIP_DEPS=("markitdown" "firecrawl-anydoc" "striprtf")

# ─── Colores ──────────────────────────────────────────────────────────────────

setup_colors() {
    if [[ -t 1 ]]; then
        RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
        CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
    else
        RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; DIM=''; RESET=''
    fi
}

# ─── Helpers ──────────────────────────────────────────────────────────────────

ok()   { echo -e "  ${GREEN}+${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
err()  { echo -e "  ${RED}x${RESET}  $*" >&2; }
info() { echo -e "     ${DIM}$*${RESET}"; }
step() {
    local title="$1"
    local dashes="------------------------------------------------------------"
    echo -e "\n${BOLD}-- ${title} ${dashes:${#title}}${RESET}\n"
}
ask() {
    local prompt="$1" default="${2:-n}"
    [[ "${YES}" == true ]] && { echo "${default}"; return; }
    echo -en "  ${CYAN}?${RESET}  ${prompt} [s/N] "
    read -r answer
    echo "${answer:-${default}}"
}

# ─── Banner (ASCII puro — funciona en todos los terminales) ───────────────────

print_banner() {
    echo ""
    echo -e "${CYAN}  __  __ _____ _   _ _____ ___  ____  _  _____ _____ ${RESET}"
    echo -e "${CYAN} |  \\/  | ____| \\ | |_   _/ _ \\|  _ \\| |/ /_ _|_   _|${RESET}"
    echo -e "${CYAN} | |\\/| |  _| |  \\| | | || | | | |_) | ' / | |  | |  ${RESET}"
    echo -e "${CYAN} | |  | | |___| |\\  | | || |_| |  _ <| . \\ | |  | |  ${RESET}"
    echo -e "${CYAN} |_|  |_|_____|_| \\_| |_| \\___/|_| \\_\\_|\\_\\___| |_|  ${RESET}"
    echo ""
    echo -e "  ${BOLD}Agentic Mentor for Legacy Code${RESET}  ${DIM}v2.0${RESET}"
    echo -e "  ${DIM}Mecanismo agentico de desarrollo para OpenCode${RESET}"
    echo -e "  ${DIM}GitLab: ${GITLAB_URL}/${GITLAB_NAMESPACE} @ ${BRANCH}${RESET}"
    echo ""
}

# ─── Verificaciones ───────────────────────────────────────────────────────────

find_python() {
    for py in python3 python py; do
        if command -v "${py}" &>/dev/null 2>&1; then
            local major
            major="$("${py}" -c 'import sys; print(sys.version_info.major)' 2>/dev/null)"
            local minor
            minor="$("${py}" -c 'import sys; print(sys.version_info.minor)' 2>/dev/null)"
            if [[ "${major:-0}" -ge 3 && "${minor:-0}" -ge 8 ]]; then
                echo "${py}"; return 0
            fi
        fi
    done
    return 1
}

check_dependencies() {
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"; ok "curl detectado"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"; ok "wget detectado"
    else
        err "Se requiere curl o wget"; exit 1
    fi

    PYTHON="$(find_python)" || {
        err "Se requiere Python 3.8+"; exit 1
    }
    local pyver; pyver="$("${PYTHON}" --version 2>&1)"
    ok "${pyver}"
}

check_opencode() {
    if command -v opencode &>/dev/null; then
        ok "OpenCode: $(command -v opencode)"
    else
        warn "OpenCode no detectado  ->  https://opencode.ai"
    fi
}

check_git() {
    command -v git &>/dev/null || { IS_GIT=false; return; }
    if git -C "${TARGET}" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
        ok "Repositorio git detectado"; IS_GIT=true
    else
        warn "Directorio sin git"; IS_GIT=false
    fi
}

detect_stack() {
    local hints=()
    [[ -f "${TARGET}/manage.py" ]]         && hints+=("Django")
    [[ -f "${TARGET}/package.json" ]]      && hints+=("Node.js")
    [[ -f "${TARGET}/go.mod" ]]            && hints+=("Go")
    [[ -f "${TARGET}/Cargo.toml" ]]        && hints+=("Rust")
    [[ -f "${TARGET}/composer.json" ]]     && hints+=("PHP")
    [[ -f "${TARGET}/pom.xml" ]]           && hints+=("Java/Maven")
    [[ -f "${TARGET}/requirements.txt" ||
       -f "${TARGET}/pyproject.toml" ]]    && hints+=("Python")
    [[ -f "${TARGET}/Gemfile" ]]           && hints+=("Ruby")
    [[ ${#hints[@]} -gt 0 ]] && ok "Stack: ${BOLD}${hints[*]}${RESET}"
}

# ─── Dependencias pip (automáticas, sin interacción del junior) ───────────────

install_pip_deps() {
    step "Dependencias pip"

    echo -e "  ${BOLD}Python puro (sin instalacion):${RESET}"
    info "ODT   -> texto completo + imagenes"
    info "DOCX  -> texto completo + imagenes"
    info "TXT   -> lectura directa"
    info "MD    -> lectura directa"
    echo ""
    echo -e "  ${BOLD}pip (instalando automaticamente):${RESET}"

    local dep mod
    for dep in "${PIP_DEPS[@]}"; do
        mod="${dep//-/_}"
        [[ "${dep}" == "striprtf" ]] && mod="striprtf.striprtf"
        [[ "${dep}" == "firecrawl-anydoc" ]] && mod="anydoc"

        if "${PYTHON}" -c "import ${mod}" &>/dev/null 2>&1; then
            local ver
            ver="$("${PYTHON}" -m pip show "${dep}" 2>/dev/null \
                | awk '/^Version:/{print $2}')"
            ok "${dep} ${DIM}${ver:-?}${RESET}  ya instalado"
        else
            echo -en "     Instalando ${dep}..."
            if "${PYTHON}" -m pip install "${dep}" \
                    --quiet --no-warn-script-location 2>/dev/null; then
                echo -e "  ${GREEN}OK${RESET}"
            else
                echo -e "  ${YELLOW}no disponible${RESET}"
                info "Instalar manualmente: pip install ${dep}"
            fi
        fi
    done

    echo ""
    echo -e "  ${BOLD}Formatos soportados:${RESET}"
    info "ODT   texto + imagenes   Python puro"
    info "DOCX  texto + imagenes   Python puro"
    info "PDF   texto              markitdown (+ fallback anydoc)"
    info "HTML  texto              markitdown"
    info "TXT   texto              Python puro"
    info "MD    texto              Python puro"
    info "RTF   texto              striprtf"
    info "DOC   conversion manual  (formato obsoleto)"
    echo ""
}

# ─── Descarga ─────────────────────────────────────────────────────────────────

download_file() {
    local path="$1"
    local dest="${TARGET}/${path}"
    local url="${GITLAB_URL}/${GITLAB_NAMESPACE}/-/raw/${BRANCH}/${path}"
    mkdir -p "$(dirname "${dest}")"

    if [[ "${DOWNLOADER}" == "curl" ]]; then
        local args=(-fsSL --retry 3 --retry-delay 2)
        [[ -n "${TOKEN}" ]] && args+=(-H "PRIVATE-TOKEN: ${TOKEN}")
        curl "${args[@]}" "${url}" -o "${dest}" 2>/dev/null \
            || { err "Fallo al descargar: ${path}"; return 1; }
    else
        local args=(--quiet --tries=3 -O "${dest}")
        [[ -n "${TOKEN}" ]] && args+=(--header "PRIVATE-TOKEN: ${TOKEN}")
        wget "${args[@]}" "${url}" 2>/dev/null \
            || { err "Fallo al descargar: ${path}"; return 1; }
    fi

    [[ ! -s "${dest}" ]] && {
        err "Archivo vacio: ${path}"; rm -f "${dest}"; return 1; }

    head -1 "${dest}" 2>/dev/null | grep -qi "<!DOCTYPE\|<html" && {
        err "Acceso denegado (HTML): ${path}"
        [[ -z "${TOKEN}" ]] && info "Repo privado? usa --token glpat-xxxx"
        rm -f "${dest}"; return 1; }

    ok "${path}"
}

# ─── .gitignore ───────────────────────────────────────────────────────────────

update_gitignore() {
    local gi="${TARGET}/.gitignore"
    local marker="# MentorKit"
    grep -q "${marker}" "${gi}" 2>/dev/null && return 0
    cat >> "${gi}" << 'GI'

# MentorKit - artefactos generados en sesion
# Descomenta para mantener .specify/ solo local:
# .specify/
GI
    ok ".gitignore actualizado"
}

# ─── Verificacion de instalacion ──────────────────────────────────────────────

check_installation() {
    step "Estado de la instalacion"
    local all_ok=true

    for f in "${FILES[@]}"; do
        if [[ -f "${TARGET}/${f}" ]]; then
            ok "${f}"
        else
            err "${f}  ${DIM}(faltante)${RESET}"
            all_ok=false
        fi
    done

    echo ""
    for p in ".specify/memory/constitution.md" ".specify/specs/"; do
        if [[ -e "${TARGET}/${p}" ]]; then
            ok "${p}"
        else
            echo -e "  ${DIM}o  ${p}  <- generado en primera sesion${RESET}"
        fi
    done

    echo ""
    if [[ "${all_ok}" == true ]]; then
        echo -e "  ${GREEN}MentorKit instalado correctamente.${RESET}"
    else
        echo -e "  ${YELLOW}Instalacion incompleta.${RESET}"
        echo -e "  Ejecuta: ${CYAN}bash install.sh${RESET}"
    fi
    echo ""
}

# ─── Próximos pasos ───────────────────────────────────────────────────────────

show_next_steps() {
    step "Proximos pasos"
    echo -e "  ${BOLD}1.${RESET} Verificar el model ID:"
    echo -e "     ${CYAN}opencode models | grep sonnet${RESET}"
    echo -e "  ${BOLD}2.${RESET} Ajustar si difiere:"
    echo -e "     ${DIM}.opencode/agents/dev-guide.md -> linea model:${RESET}"
    echo -e "  ${BOLD}3.${RESET} Versionar la instalacion:"
    echo -e "     ${CYAN}git add .opencode/ && git commit -m \"feat: install MentorKit\"${RESET}"
    echo -e "  ${BOLD}4.${RESET} Iniciar OpenCode y seleccionar ${BOLD}dev-guide${RESET} con Tab"
    echo -e "  ${BOLD}5.${RESET} Primera sesion: confirmar creacion de constitution.md"
    echo ""
}

# ─── Instalacion principal ────────────────────────────────────────────────────

run_install() {
    step "Verificaciones"
    check_dependencies
    check_opencode
    check_git
    detect_stack

    # Manejo de instalacion existente
    if [[ -d "${TARGET}/.opencode" ]]; then
        warn "Ya existe .opencode/ en este proyecto"
        local ans; ans="$(ask "Crear backup y reinstalar?" "n")"
        if [[ "${ans,,}" != "s" && "${ans,,}" != "y" ]]; then
            info "Cancelado."; exit 0
        fi
        local bk="${TARGET}/.opencode_backup_$(date +%Y%m%d_%H%M%S)"
        cp -r "${TARGET}/.opencode" "${bk}"
        info "Backup creado: ${bk}"
        rm -rf "${TARGET}/.opencode"
    fi

    # Descarga de archivos
    step "Descargando desde GitLab"
    local errors=0
    for f in "${FILES[@]}"; do
        download_file "${f}" || ((errors++)) || true
    done
    [[ ${errors} -gt 0 ]] && {
        err "${errors} archivo(s) fallaron. Revisa URL y token."
        exit 1
    }

    # Dependencias pip
    [[ "${SKIP_DEPS}" == false ]] && install_pip_deps

    # .gitignore
    [[ "${IS_GIT}" == true && "${SKIP_GITIGNORE}" == false ]] \
        && update_gitignore

    # Resumen final
    step "Instalacion completada"
    echo -e "  ${GREEN}+${RESET}  ${BOLD}MentorKit listo${RESET}\n"
    echo -e "  ${DIM}.opencode/${RESET}"
    echo -e "  ${DIM}+-- skills/${RESET}"
    echo -e "  ${DIM}|   +-- codebase-conformist/SKILL.md${RESET}"
    echo -e "  ${DIM}|   +-- spec-writer/SKILL.md${RESET}"
    echo -e "  ${DIM}|   +-- prd-reader/SKILL.md${RESET}"
    echo -e "  ${DIM}|   +-- document-extractor/SKILL.md${RESET}"
    echo -e "  ${DIM}|   \`-- llm-council/SKILL.md${RESET}"
    echo -e "  ${DIM}\`-- agents/${RESET}"
    echo -e "  ${DIM}    \`-- dev-guide.md${RESET}"

    show_next_steps
}

# ─── Ayuda ────────────────────────────────────────────────────────────────────

usage() {
    echo ""
    echo -e "${BOLD}Uso:${RESET}  bash install.sh [opciones]"
    echo ""
    echo -e "${BOLD}Opciones:${RESET}"
    echo "  -y, --yes              Sin confirmaciones"
    echo "  --check                Verificar instalacion existente"
    echo "  --target <dir>         Directorio destino (default: .)"
    echo "  --gitlab-url <url>     URL GitLab (default: https://gitlab.com)"
    echo "  --namespace <ns>       Namespace del repositorio"
    echo "  --branch <branch>      Rama (default: main)"
    echo "  --token <token>        Token para repos privados"
    echo "  --skip-deps            No instalar dependencias pip"
    echo "  --skip-gitignore       No modificar .gitignore"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo -e "${BOLD}Variables de entorno:${RESET}"
    echo "  MENTORKIT_GITLAB_URL     URL base de GitLab"
    echo "  MENTORKIT_NAMESPACE      Namespace del repositorio"
    echo "  MENTORKIT_BRANCH         Rama"
    echo "  MENTORKIT_TOKEN          Token de acceso privado"
    echo ""
    echo -e "${BOLD}Ejemplos:${RESET}"
    echo "  # One-liner (repo publico)"
    echo "  bash <(curl -fsSL https://gitlab.com/GROUP/mentorkit/-/raw/main/install.sh)"
    echo ""
    echo "  # GitLab self-hosted + token"
    echo "  bash install.sh \\"
    echo "    --gitlab-url https://gitlab.empresa.cu \\"
    echo "    --namespace equipo/mentorkit \\"
    echo "    --token glpat-xxxx"
    echo ""
    echo "  # Silencioso para CI/CD"
    echo "  bash install.sh --yes --skip-gitignore"
    echo ""
}

# ─── Parsing de argumentos ────────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)           YES=true ;;
            --check)            CHECK=true ;;
            --target)           TARGET="$2"; shift ;;
            --gitlab-url)       GITLAB_URL="$2"; shift ;;
            --namespace)        GITLAB_NAMESPACE="$2"; shift ;;
            --branch)           BRANCH="$2"; shift ;;
            --token)            TOKEN="$2"; shift ;;
            --skip-deps)        SKIP_DEPS=true ;;
            --skip-gitignore)   SKIP_GITIGNORE=true ;;
            -h|--help)          print_banner; usage; exit 0 ;;
            *) err "Argumento desconocido: $1"; usage; exit 1 ;;
        esac
        shift
    done
    TARGET="$(cd "${TARGET}" 2>/dev/null && pwd || echo "${TARGET}")"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    setup_colors
    parse_args "$@"
    print_banner
    echo -e "  ${DIM}Destino: ${TARGET}${RESET}\n"
    if [[ "${CHECK}" == true ]]; then
        check_installation
    else
        run_install
    fi
}

main "$@"