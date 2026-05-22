#!/usr/bin/env bash
# =============================================================================
#  MentorKit — Instalador para Linux / macOS / Git Bash (Windows)
#  Descarga los archivos desde un repositorio GitLab
# =============================================================================

set -uo pipefail

# ─── Configuración por defecto ────────────────────────────────────────────────
# Puede sobreescribirse con flags o variables de entorno

GITLAB_URL="${MENTORKIT_GITLAB_URL:-https://gitlab.com}"
GITLAB_NAMESPACE="${MENTORKIT_NAMESPACE:-YOUR_GROUP/mentorkit}"
BRANCH="${MENTORKIT_BRANCH:-main}"
TOKEN="${MENTORKIT_TOKEN:-}"
TARGET="${PWD}"
YES=false
CHECK=false
SKIP_GITIGNORE=false

# ─── Archivos a instalar ──────────────────────────────────────────────────────

FILES=(
    ".opencode/skills/codebase-conformist/SKILL.md"
    ".opencode/skills/spec-writer/SKILL.md"
    ".opencode/skills/prd-reader/SKILL.md"
    ".opencode/skills/llm-council/SKILL.md"
    ".opencode/agents/dev-guide.md"
)

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

ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }
info() { echo -e "  ${DIM}$*${RESET}"; }
step() { echo -e "\n${BOLD}── $* $(printf '─%.0s' {1..50} | head -c $((56 - ${#1})))${RESET}\n"; }

ask() {
    local prompt="$1" default="${2:-n}"
    [[ "${YES}" == true ]] && { echo "${default}"; return; }
    echo -en "  ${CYAN}?${RESET}  ${prompt} [s/N] "
    read -r answer
    echo "${answer:-${default}}"
}

# ─── Banner ───────────────────────────────────────────────────────────────────

print_banner() {
    echo -e "${CYAN}"
    echo '  ███╗   ███╗███████╗███╗   ██╗████████╗ ██████╗ ██████╗ ██╗  ██╗██╗████████╗'
    echo '  ████╗ ████║██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗██╔══██╗██║ ██╔╝██║╚══██╔══╝'
    echo '  ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   ██║   ██║██████╔╝█████╔╝ ██║   ██║   '
    echo '  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██╔══██╗██╔═██╗ ██║   ██║   '
    echo '  ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   ╚██████╔╝██║  ██║██║  ██╗██║   ██║   '
    echo '  ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝   ╚═╝  '
    echo -e "${RESET}"
    echo -e "  ${BOLD}Agentic Mentor for Legacy Code${RESET}"
    echo -e "  ${DIM}Mecanismo agentico de desarrollo para OpenCode${RESET}"
    echo -e "  ${DIM}GitLab: ${GITLAB_URL}/${GITLAB_NAMESPACE} @ ${BRANCH}${RESET}\n"
}

# ─── Verificaciones previas ───────────────────────────────────────────────────

check_dependencies() {
    if command -v curl &>/dev/null; then
        DOWNLOADER="curl"
        ok "curl detectado"
    elif command -v wget &>/dev/null; then
        DOWNLOADER="wget"
        ok "wget detectado"
    else
        err "Se requiere curl o wget para la instalación"
        exit 1
    fi
}

check_opencode() {
    if command -v opencode &>/dev/null; then
        ok "OpenCode detectado: $(command -v opencode)"
    else
        warn "OpenCode no detectado en el PATH"
        info "  Instálalo desde https://opencode.ai"
        info "  MentorKit se instalará de todas formas"
    fi
}

check_git() {
    if ! command -v git &>/dev/null; then
        warn "git no detectado"; IS_GIT=false; return
    fi
    if git -C "${TARGET}" rev-parse --is-inside-work-tree &>/dev/null; then
        ok "Repositorio git detectado"
        IS_GIT=true
    else
        warn "El directorio no es un repositorio git"
        IS_GIT=false
    fi
}

detect_stack() {
    local hints=()
    [[ -f "${TARGET}/manage.py" ]]       && hints+=("Django")
    [[ -f "${TARGET}/package.json" ]]    && hints+=("Node.js")
    [[ -f "${TARGET}/go.mod" ]]          && hints+=("Go")
    [[ -f "${TARGET}/Cargo.toml" ]]      && hints+=("Rust")
    [[ -f "${TARGET}/composer.json" ]]   && hints+=("PHP")
    [[ -f "${TARGET}/pom.xml" ]]         && hints+=("Java/Maven")
    [[ -f "${TARGET}/pyproject.toml" ]]  && hints+=("Python")
    [[ -f "${TARGET}/requirements.txt" ]] && hints+=("Python")
    [[ -f "${TARGET}/Gemfile" ]]         && hints+=("Ruby")
    if [[ ${#hints[@]} -gt 0 ]]; then
        ok "Proyecto detectado: ${BOLD}$(IFS=', '; echo "${hints[*]}")${RESET}"
    fi
}

# ─── Descarga ─────────────────────────────────────────────────────────────────

build_url() {
    local path="$1"
    # GitLab raw URL: /GROUP/REPO/-/raw/BRANCH/PATH
    echo "${GITLAB_URL}/${GITLAB_NAMESPACE}/-/raw/${BRANCH}/${path}"
}

download_file() {
    local path="$1"
    local dest="${TARGET}/${path}"
    local url
    url="$(build_url "${path}")"

    # Crear directorio si no existe
    mkdir -p "$(dirname "${dest}")"

    if [[ "${DOWNLOADER}" == "curl" ]]; then
        local curl_args=(-fsSL --retry 3 --retry-delay 2)
        [[ -n "${TOKEN}" ]] && curl_args+=(-H "PRIVATE-TOKEN: ${TOKEN}")
        if ! curl "${curl_args[@]}" "${url}" -o "${dest}"; then
            err "Error descargando: ${path}"
            err "URL: ${url}"
            [[ -z "${TOKEN}" ]] && info "  ¿Repositorio privado? Usa --token o MENTORKIT_TOKEN"
            return 1
        fi
    else
        local wget_args=(--quiet --tries=3)
        [[ -n "${TOKEN}" ]] && wget_args+=(--header "PRIVATE-TOKEN: ${TOKEN}")
        if ! wget "${wget_args[@]}" -O "${dest}" "${url}"; then
            err "Error descargando: ${path}"
            [[ -z "${TOKEN}" ]] && info "  ¿Repositorio privado? Usa --token o MENTORKIT_TOKEN"
            return 1
        fi
    fi

    # Verificar que el archivo no está vacío y no es una página de error HTML
    if [[ ! -s "${dest}" ]]; then
        err "Archivo vacío: ${path}"
        rm -f "${dest}"
        return 1
    fi
    if head -1 "${dest}" | grep -qi "<!DOCTYPE\|<html"; then
        err "Respuesta HTML (¿acceso denegado?): ${path}"
        rm -f "${dest}"
        return 1
    fi

    ok "${path}"
}

# ─── Backup ───────────────────────────────────────────────────────────────────

backup_existing() {
    local opencode_dir="${TARGET}/.opencode"
    local timestamp
    timestamp="$(date +%Y%m%d_%H%M%S)"
    local backup="${TARGET}/.opencode_backup_${timestamp}"
    cp -r "${opencode_dir}" "${backup}"
    info "  Backup creado: ${backup}"
}

# ─── .gitignore ───────────────────────────────────────────────────────────────

update_gitignore() {
    local gitignore="${TARGET}/.gitignore"
    local marker="# MentorKit — generated artifacts"

    if [[ -f "${gitignore}" ]] && grep -q "${marker}" "${gitignore}"; then
        return 0  # ya está
    fi

    cat >> "${gitignore}" << GITIGNORE

${marker}
# Descomenta para mantener .specify/ solo local:
# .specify/
GITIGNORE
    ok ".gitignore actualizado"
}

# ─── Verificación ─────────────────────────────────────────────────────────────

check_installation() {
    step "Estado de la instalación"
    local all_ok=true

    for file in "${FILES[@]}"; do
        if [[ -f "${TARGET}/${file}" ]]; then
            ok "${file}"
        else
            err "${file}  ${DIM}← faltante${RESET}"
            all_ok=false
        fi
    done

    echo ""
    local optional=(
        ".specify/memory/constitution.md"
        ".specify/specs/"
    )
    for path in "${optional[@]}"; do
        if [[ -e "${TARGET}/${path}" ]]; then
            ok "${path}"
        else
            echo -e "  ${DIM}○  ${path}  ← se crea en primera sesión${RESET}"
        fi
    done

    echo ""
    if [[ "${all_ok}" == true ]]; then
        echo -e "  ${GREEN}MentorKit está correctamente instalado.${RESET}"
    else
        echo -e "  ${YELLOW}Instalación incompleta.${RESET} Ejecuta: ${CYAN}bash install.sh${RESET}"
    fi
    echo ""
}


# ─── Dependencias opcionales de prd-reader ───────────────────────────────────

check_prd_dependencies() {
    step "Dependencias de document-extractor"

    echo -e "  ${BOLD}Siempre disponibles — sin instalación:${RESET}"
    ok "Python puro (zipfile + xml)  → ODT: texto completo + imágenes"
    ok "Python puro (zipfile + xml)  → DOCX: texto completo + imágenes"

    echo ""
    echo -e "  ${BOLD}pip (una sola dependencia para PDF):${RESET}"

    # Verificar markitdown
    if python3 -c "import markitdown" &>/dev/null 2>&1; then
        local ver
        ver="$(python3 -c "import markitdown; print(markitdown.__version__)" 2>/dev/null)"
        ok "markitdown ${ver} ya instalado → PDF listo"
    else
        warn "markitdown no detectado → instalando..."
        if python3 -m pip install markitdown --quiet 2>/dev/null; then
            ok "markitdown instalado → PDF listo"
        else
            echo -e "  ${YELLOW}○  markitdown no pudo instalarse${RESET}"
            info "    Instala manualmente: pip install markitdown"
            info "    PDF no disponible hasta entonces"
        fi
    fi

    echo ""
    echo -e "  ${BOLD}Resumen de cobertura:${RESET}"
    info "  ODT  → Python puro  ✓ siempre"
    info "  DOCX → Python puro  ✓ siempre"
    info "  PDF  → markitdown   ✓ si instalado"
    info "  DOC  → pedir conversión a DOCX/ODT (formato obsoleto)"
    echo ""
}

# ─── Próximos pasos ───────────────────────────────────────────────────────────

show_next_steps() {
    step "Próximos pasos"
    echo -e "  ${BOLD}1.${RESET} Verificar el model ID en tu instalación:"
    echo -e "     ${CYAN}opencode models | grep sonnet${RESET}"
    echo -e "  ${BOLD}2.${RESET} Actualizar el model si difiere:"
    echo -e "     ${DIM}.opencode/agents/dev-guide.md → línea model:${RESET}"
    echo -e "  ${BOLD}3.${RESET} Versionar la instalación:"
    echo -e "     ${CYAN}git add .opencode/ && git commit -m \"feat: install MentorKit\"${RESET}"
    echo -e "  ${BOLD}4.${RESET} Iniciar OpenCode y seleccionar el agente ${BOLD}dev-guide${RESET} con Tab"
    echo -e "  ${BOLD}5.${RESET} En la primera sesión, confirmar la creación de ${DIM}constitution.md${RESET}"
    echo ""
}

# ─── Instalación principal ────────────────────────────────────────────────────

run_install() {
    local opencode_dir="${TARGET}/.opencode"
    local errors=0

    step "Verificaciones previas"
    check_dependencies
    check_opencode
    check_git
    detect_stack
    echo -e "  ${DIM}GitLab: ${GITLAB_URL}/${GITLAB_NAMESPACE} @ ${BRANCH}${RESET}"

    # Manejar instalación existente
    if [[ -d "${opencode_dir}" ]]; then
        warn "Ya existe .opencode/ en este proyecto"
        local ans
        ans="$(ask "¿Crear backup y reinstalar?" "n")"
        if [[ "${ans,,}" != "s" && "${ans,,}" != "si" && "${ans,,}" != "y" ]]; then
            info "Instalación cancelada."
            exit 0
        fi
        backup_existing
        rm -rf "${opencode_dir}"
    fi

    step "Descargando archivos desde GitLab"

    for file in "${FILES[@]}"; do
        download_file "${file}" || ((errors++))
    done

    if [[ ${errors} -gt 0 ]]; then
        err "${errors} archivo(s) no pudieron descargarse"
        err "Revisa la URL del repositorio y el token de acceso"
        exit 1
    fi

    # Dependencias opcionales
    check_prd_dependencies

    # .gitignore
    if [[ "${IS_GIT}" == true && "${SKIP_GITIGNORE}" == false ]]; then
        update_gitignore
    fi

    step "Instalación completada"
    echo -e "  ${GREEN}✓${RESET}  ${BOLD}MentorKit instalado correctamente${RESET}\n"
    echo -e "  ${DIM}.opencode/${RESET}"
    echo -e "  ${DIM}├── skills/${RESET}"
    echo -e "  ${DIM}│   ├── codebase-conformist/SKILL.md${RESET}"
    echo -e "  ${DIM}│   ├── spec-writer/SKILL.md${RESET}"
    echo -e "  ${DIM}│   ├── prd-reader/SKILL.md${RESET}"
    echo -e "  ${DIM}│   └── llm-council/SKILL.md${RESET}"
    echo -e "  ${DIM}└── agents/${RESET}"
    echo -e "  ${DIM}    └── dev-guide.md${RESET}"

    show_next_steps
}

# ─── Ayuda ────────────────────────────────────────────────────────────────────

usage() {
    echo ""
    echo -e "${BOLD}Uso:${RESET}"
    echo "  bash install.sh [opciones]"
    echo ""
    echo -e "${BOLD}Opciones:${RESET}"
    echo "  -y, --yes                Instalar sin confirmaciones"
    echo "  --check                  Verificar instalación existente"
    echo "  --target <dir>           Directorio destino (default: directorio actual)"
    echo "  --gitlab-url <url>       URL base de GitLab (default: https://gitlab.com)"
    echo "  --namespace <ns>         Namespace del repo (default: YOUR_GROUP/mentorkit)"
    echo "  --branch <branch>        Rama a usar (default: main)"
    echo "  --token <token>          Token de acceso para repos privados"
    echo "  --skip-gitignore         No modificar .gitignore"
    echo "  -h, --help               Mostrar esta ayuda"
    echo ""
    echo -e "${BOLD}Variables de entorno:${RESET}"
    echo "  MENTORKIT_GITLAB_URL     URL base de GitLab"
    echo "  MENTORKIT_NAMESPACE      Namespace/path del repositorio"
    echo "  MENTORKIT_BRANCH         Rama"
    echo "  MENTORKIT_TOKEN          Token de acceso privado"
    echo ""
    echo -e "${BOLD}Ejemplos:${RESET}"
    echo "  # Instalación básica (repo público)"
    echo "  bash install.sh"
    echo ""
    echo "  # Repo privado con token"
    echo "  bash install.sh --token glpat-xxxxxxxxxxxx"
    echo ""
    echo "  # GitLab self-hosted"
    echo "  bash install.sh --gitlab-url https://gitlab.empresa.com \\"
    echo "                  --namespace equipo/mentorkit --token TOKEN"
    echo ""
    echo "  # Instalar en directorio específico sin preguntas"
    echo "  bash install.sh --yes --target /ruta/al/proyecto"
    echo ""
    echo "  # One-liner desde GitLab público"
    echo "  bash <(curl -fsSL https://gitlab.com/GROUP/mentorkit/-/raw/main/install.sh)"
    echo ""
}

# ─── Parsing de argumentos ────────────────────────────────────────────────────

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -y|--yes)            YES=true ;;
            --check)             CHECK=true ;;
            --target)            TARGET="$2"; shift ;;
            --gitlab-url)        GITLAB_URL="$2"; shift ;;
            --namespace)         GITLAB_NAMESPACE="$2"; shift ;;
            --branch)            BRANCH="$2"; shift ;;
            --token)             TOKEN="$2"; shift ;;
            --skip-gitignore)    SKIP_GITIGNORE=true ;;
            -h|--help)           print_banner; usage; exit 0 ;;
            *)
                err "Argumento desconocido: $1"
                usage; exit 1 ;;
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

    echo -e "  ${DIM}Directorio destino: ${TARGET}${RESET}\n"

    if [[ "${CHECK}" == true ]]; then
        check_installation
    else
        run_install
    fi
}

main "$@"
