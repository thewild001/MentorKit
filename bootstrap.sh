#!/usr/bin/env bash
# =============================================================================
# MentorKit — One-liner bootstrap
#
# Uso:
#   bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/main/bootstrap.sh")
#
# Probar una rama:
#   MENTORKIT_BRANCH=feature/odd-migration \
#   bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/feature/odd-migration/bootstrap.sh")
#
# El bootstrap solo descarga el release del repo, copia los artefactos y delega
# la preparación del runtime al instalador local. No contiene credenciales.
# =============================================================================

set -euo pipefail

REPO="thewild001/MentorKit"
BRANCH="${MENTORKIT_BRANCH:-main}"
GITHUB_CODELOAD_HOST="https://codeload.github.com"

CYAN='\033[0;36m'; DIM='\033[2m'; GREEN='\033[0;32m'; RED='\033[0;31m'; RESET='\033[0m'
[[ ! -t 1 ]] && CYAN='' DIM='' GREEN='' RED='' RESET=''

fail() {
    echo -e "  ${RED}x${RESET} $*" >&2
    exit 1
}

echo -e "\n  ${CYAN}MentorKit${RESET}  ${DIM}ODD — One-liner installer${RESET}"
echo -e "  ${DIM}GitHub: ${REPO} @ ${BRANCH}${RESET}\n"

# ---------------------------------------------------------------------------
# Preconditions
# ---------------------------------------------------------------------------

command -v curl >/dev/null 2>&1 || fail "Se requiere curl."
command -v tar  >/dev/null 2>&1 || fail "Se requiere tar."
command -v bash >/dev/null 2>&1 || fail "Se requiere bash."

if [[ -e ".opencode" ]]; then
    fail ".opencode/ ya existe en $(pwd). Para evitar sobreescribir configuración existente, instala en un proyecto limpio o haz backup."
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TARBALL_URL="${GITHUB_CODELOAD_HOST}/${REPO}/tar.gz/refs/heads/${BRANCH}"
ARCHIVE="${TMP}/mentorkit.tar.gz"

# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------

echo -e "  ${DIM}1/3${RESET}  Descargando release..."
curl -fsSL --retry 3 --retry-delay 2 --max-time 180 "$TARBALL_URL" -o "$ARCHIVE" ||
    fail "No se pudo descargar MentorKit desde GitHub."

[[ -s "$ARCHIVE" ]] || fail "GitHub devolvió un archivo vacío."

# ---------------------------------------------------------------------------
# Extract
# ---------------------------------------------------------------------------

echo -e "  ${DIM}2/3${RESET}  Extrayendo..."
tar -xzf "$ARCHIVE" -C "$TMP" || fail "No se pudo extraer el tarball."

REPO_DIR=""
while IFS= read -r d; do
    if [[ -d "$d/.opencode" && -f "$d/.opencode/install-mentorkit.sh" ]]; then
        REPO_DIR="$d"
        break
    fi
done < <(find "$TMP" -mindepth 1 -maxdepth 1 -type d -print)

[[ -n "$REPO_DIR" ]] || fail "El release no contiene un instalador MentorKit válido."

# ---------------------------------------------------------------------------
# Install files
# ---------------------------------------------------------------------------

echo -e "  ${DIM}3/3${RESET}  Instalando en $(pwd)..."

cp -R "$REPO_DIR/.opencode" "./" || fail "No se pudo copiar .opencode/."

[[ -d "$REPO_DIR/odd" ]] &&
    cp -R "$REPO_DIR/odd" "./"

[[ -d "$REPO_DIR/.mentor" ]] &&
    cp -R "$REPO_DIR/.mentor" "./"

# Agent-neutral contract and native adapters.
for file in AGENTS.md CLAUDE.md; do
    [[ -f "$REPO_DIR/$file" ]] && cp "$REPO_DIR/$file" "./"
done

for dir in .cursor .claude .agents; do
    [[ -d "$REPO_DIR/$dir" ]] && cp -R "$REPO_DIR/$dir" "./"
done

[[ -f "$REPO_DIR/Makefile" ]] &&
    cp "$REPO_DIR/Makefile" "./"

# Shared agent contract and native adapters.
for file in AGENTS.md CLAUDE.md; do
    [[ -f "$REPO_DIR/$file" ]] && cp "$REPO_DIR/$file" "./"
done

for dir in .cursor .claude .agents; do
    [[ -d "$REPO_DIR/$dir" ]] && cp -R "$REPO_DIR/$dir" "./"
done

bash ".opencode/install-mentorkit.sh" ||
    fail "El instalador no pudo completar la preparación del entorno."

# ---------------------------------------------------------------------------
# Welcome splash — only reached after every installation step succeeds.
# ---------------------------------------------------------------------------

show_success_splash() {
    local project
    project="$(pwd)"
    if (( ${#project} > 48 )); then project="…${project: -47}"; fi
    echo ""
    echo -e "  ${CYAN}╭──────────────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "  ${CYAN}│                                                                      │${RESET}"
    printf '  \033[36m│\033[32m%s\033[36m│\033[0m\n' '        █   █               █               █   █   █     █           '
    printf '  \033[36m│\033[32m%s\033[36m│\033[0m\n' '        ██ ██  ███  ████  █████  ███  █ ██  █  █        █████         '
    printf '  \033[36m│\033[32m%s\033[36m│\033[0m\n' '        █ █ █ █   █ █   █   █   █   █ ██  █ ███    ██     █           '
    printf '  \033[36m│\033[32m%s\033[36m│\033[0m\n' '        █   █ █████ █   █   █   █   █ █     █  █    █     █           '
    printf '  \033[36m│\033[32m%s\033[36m│\033[0m\n' '        █   █  ████ █   █   ██   ███  █     █   █  ███    ██          '
    echo -e "  ${CYAN}│                   ORGANIC-DRIVEN DEVELOPMENT · ODD                   │${RESET}"
    echo -e "  ${CYAN}├──────────────────────────────────────────────────────────────────────┤${RESET}"
    echo -e "  ${CYAN}│                      ✓  Instalación completada                       │${RESET}"
    echo -e "  ${CYAN}│                         Proyecto: ${project}                         │${RESET}"
    echo -e "  ${CYAN}│                                                                      │${RESET}"
    echo -e "  ${CYAN}│                            PARA COMENZAR                             │${RESET}"
    echo -e "  ${CYAN}│             1. Define el objetivo que quieres alcanzar.              │${RESET}"
    echo -e "  ${CYAN}│         2. Describe la tarea y aporta el contexto necesario.         │${RESET}"
    echo -e "  ${CYAN}│          3. Revisa las propuestas y valida los resultados.           │${RESET}"
    echo -e "  ${CYAN}│                                                                      │${RESET}"
    echo -e "  ${CYAN}│                Docs: github.com/thewild001/MentorKit                 │${RESET}"
    echo -e "  ${CYAN}╰──────────────────────────────────────────────────────────────────────╯${RESET}"
    echo ""
}
show_success_splash
