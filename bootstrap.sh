#!/usr/bin/env bash
# MentorKit — Bootstrap (one-liner installer)
#
# Uso:
#   bash <(curl -fsSL "https://raw.githubusercontent.com/thewild001/MentorKit/main/bootstrap.sh")
#
# Lo que hace (sin que el usuario tenga que saber nada):
#   1. Descarga mentorkit como tarball desde GitHub
#   2. Extrae en /tmp
#   3. Copia al directorio actual del usuario:
#        .opencode/      (skills, installer, verify, requirements lock)
#        Makefile        (targets install/verify/clean/ci)
#        # NO se copian: openspec/ (store local de este repo)
#        # NO se copian: .specify/ (legacy, deprecated)
#        
#   4. Corre el installer: crea venv, instala 60 deps desde lock, verifica
#   5. Reporta éxito
#
# El usuario corre UN comando y obtiene mentorkit funcionando. No necesita
# make, jq, ni correr `make install` después. Toda la gestión de dependencias
# (Python 3.12.13 pin, lock con SHA256, cobertura cross-platform, idempotencia)
# ocurre DENTRO del installer — el usuario no la ve.

set -uo pipefail

REPO="thewild001/MentorKit"
BRANCH="main"
GITHUB_CODELOAD_HOST="https://codeload.github.com"

CYAN='\033[0;36m'; DIM='\033[2m'; GREEN='\033[0;32m'; RED='\033[0;31m'; RESET='\033[0m'
[[ ! -t 1 ]] && CYAN=''; DIM=''; GREEN=''; RED=''; RESET=''

# ─── Validaciones tempranas ────────────────────────────────────────────

if [[ -d ".opencode" ]] && [[ -f ".opencode/install-mentorkit.sh" ]]; then
    echo -e "  ${RED}x${RESET}  .opencode/ ya existe en $(pwd)"
    echo "     Para reinstalar, primero borra la carpeta .opencode/ (backup si lo necesitas)"
    exit 1
fi

# ─── Setup temporal ────────────────────────────────────────────────────

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

echo -e "\n  ${CYAN}MentorKit${RESET}  ${DIM}v5.0 — Instalador one-liner${RESET}\n"

# ─── 1) Descargar tarball ────────────────────────────────────────────────
TARBALL_URL="${GITHUB_CODELOAD_HOST}/${REPO}/tar.gz/refs/heads/${BRANCH}"
echo -e "  ${DIM}1/4${RESET}  Descargando mentorkit (tarball)..."

if ! curl -fsSL --max-time 180 \
        "$TARBALL_URL" -o "${TMP}/repo.tar.gz"; then
    echo -e "  ${RED}x${RESET}  Error descargando tarball desde GitHub"
    echo "     URL: $TARBALL_URL"
    echo "     ¿Tienes acceso a la red?"
    exit 1
fi

# ─── 2) Extraer ────────────────────────────────────────────────────────

echo -e "  ${DIM}2/4${RESET}  Extrayendo..."
if ! tar -xzf "${TMP}/repo.tar.gz" -C "$TMP"; then
    echo -e "  ${RED}x${RESET}  Error extrayendo tarball"
    echo "     ¿Está completo el archivo? Tamaño: $(stat -c %s "${TMP}/repo.tar.gz" 2>/dev/null || echo "?") bytes"
    exit 1
fi

# El tarball de GitHub extrae a '<repo>-<branch>/'
REPO_DIR=$(find "$TMP" -maxdepth 1 -mindepth 1 -type d | while read -r d; do
    [[ -d "$d/.opencode" ]] && { echo "$d"; break; }
done)
if [[ -z "$REPO_DIR" ]] || [[ ! -d "$REPO_DIR/.opencode" ]]; then
    echo -e "  ${RED}x${RESET}  Tarball extraído no contiene .opencode/"
    echo "     Contenido extraído:"
    ls -la "$TMP" | sed 's/^/       /'
    exit 1
fi

# ─── 3) Copiar al PWD del usuario ──────────────────────────────────────

echo -e "  ${DIM}3/4${RESET}  Instalando en $(pwd)..."

# .opencode/ — el producto en sí (skills, installer, verify, lock)
if ! cp -r "$REPO_DIR/.opencode" "./"; then
    echo -e "  ${RED}x${RESET}  Error copiando .opencode/"
    exit 1
fi

# Makefile — opcional pero útil (make verify, make clean, make ci)
if [[ -f "$REPO_DIR/Makefile" ]]; then
    cp "$REPO_DIR/Makefile" "./"
fi

# ─── 4) Install end-to-end (lo que el usuario NO ve) ──────────────────

echo -e "  ${DIM}4/4${RESET}  Configurando entorno Python (esto puede tardar 30s la primera vez)..."
if ! bash ".opencode/install-mentorkit.sh" --fix; then
    echo -e "  ${RED}x${RESET}  El installer falló. Tu .opencode/ quedó parcialmente instalado."
    echo "     Diagnóstico: bash .opencode/install-mentorkit.sh --verify"
    echo "     Reparar:     bash .opencode/install-mentorkit.sh --fix"
    exit 1
fi

# ─── Done ──────────────────────────────────────────────────────────────

echo ""
echo -e "  ${GREEN}✓${RESET}  ${GREEN}MentorKit instalado en${RESET} $(pwd)"
echo ""
echo "  ${DIM}Próximos pasos (todos opcionales):${RESET}"
echo "     make verify    # confirmar que el venv está OK"
echo "     make ci        # simular el pipeline de GitLab localmente"
echo ""
echo "  ${DIM}Para usar mentorkit:${RESET} abre OpenCode en este proyecto y selecciona el agente MentorKit5.0"
echo ""
