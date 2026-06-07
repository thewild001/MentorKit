#!/usr/bin/env bash
# MentorKit — Bootstrap (one-liner installer)
#
# Uso:
#   bash <(curl -fsSLk -H "PRIVATE-TOKEN: ${MENTORKIT_TOKEN:-glpat-RhMcJxUMWSx5N0tkYKStlm86MQp1OjI2bAk.01.0z1ay31li}" \
#       "https://gitlab.prod.uci.cu/api/v4/projects/fortes%2Fmentorkit/repository/files/bootstrap.sh/raw?ref=main")
#
# (El endpoint /-/raw/ de este GitLab no responde al PRIVATE-TOKEN header —
#  devuelve el sign-in. Por eso usamos el API endpoint con el token embebido.)
#
# Lo que hace (sin que el usuario tenga que saber nada):
#   1. Descarga mentorkit como tarball desde GitLab API
#   2. Extrae en /tmp
#   3. Copia al directorio actual del usuario:
#        .opencode/      (skills, installer, verify, requirements lock)
#        Makefile        (targets install/verify/clean/ci)
#        .gitlab-ci.yml  (jobs verify-* reutilizables)
#   4. Corre el installer: crea venv, instala 53 deps desde lock, verifica
#   5. Reporta éxito
#
# El usuario corre UN comando y obtiene mentorkit funcionando. No necesita
# make, jq, ni correr `make install` después. Toda la gestión de dependencias
# (Python 3.12.13 pin, lock con SHA256, cobertura cross-platform, idempotencia)
# ocurre DENTRO del installer — el usuario no la ve.

set -uo pipefail

REPO="fortes/mentorkit"
BRANCH="main"
GITLAB_HOST="https://gitlab.prod.uci.cu"

# Resolución del token (orden de prioridad):
#   1) MENTORKIT_TOKEN env var — recomendado para CI/CD y para que el usuario
#      pueda rotar el token sin tocar el script
#   2) Hardcoded PAT (read_api scope) — fallback de conveniencia para el
#      one-liner del usuario que no quiere/necesita configurar env vars.
#      El PAT solo puede LEER el repo, no mutar nada.
#
# Uso:   export MENTORKIT_TOKEN=glpat-xxxxx && bash bootstrap.sh
#   o:   bash bootstrap.sh                     (usa el default)
DEFAULT_TOKEN="glpat-RhMcJxUMWSx5N0tkYKStlm86MQp1OjI2bAk.01.0z1ay31li"

# Distinguimos "unset" de "set to empty string" para no caer al default
# silenciosamente si el usuario explícitamente exportó MENTORKIT_TOKEN=""
if [[ -n "${MENTORKIT_TOKEN+x}" ]]; then
    TOKEN="$MENTORKIT_TOKEN"
else
    TOKEN="$DEFAULT_TOKEN"
fi

CYAN='\033[0;36m'; DIM='\033[2m'; GREEN='\033[0;32m'; RED='\033[0;31m'; RESET='\033[0m'
[[ ! -t 1 ]] && CYAN=''; DIM=''; GREEN=''; RED=''; RESET=''

# ─── Validaciones tempranas ────────────────────────────────────────────

# El usuario explícitamente exportó MENTORKIT_TOKEN="" → fallar con mensaje
# claro en vez de caer al default silenciosamente
if [[ -n "${MENTORKIT_TOKEN+x}" ]] && [[ -z "$TOKEN" ]]; then
    echo -e "  ${RED}x${RESET}  MENTORKIT_TOKEN está seteado a string vacío."
    echo "     Para usar el default embebido, haz: unset MENTORKIT_TOKEN"
    echo "     Para usar tu propio token, haz:  export MENTORKIT_TOKEN=glpat-xxxxx"
    exit 1
fi

if [[ -d ".opencode" ]] && [[ -f ".opencode/install-mentorkit.sh" ]]; then
    echo -e "  ${RED}x${RESET}  .opencode/ ya existe en $(pwd)"
    echo "     Para reinstalar, primero borra la carpeta .opencode/ (backup si lo necesitas)"
    exit 1
fi

# ─── Setup temporal ────────────────────────────────────────────────────

TMP=$(mktemp -d)
trap "rm -rf $TMP" EXIT

echo -e "\n  ${CYAN}MentorKit${RESET}  ${DIM}v4.0 — Instalador one-liner${RESET}\n"

# ─── 1) Descargar tarball (vía API, requiere auth) ─────────────────────

# El endpoint /-/raw/ NO funciona con PRIVATE-TOKEN header en este GitLab
# (devuelve 302 a sign-in). El endpoint /api/v4/ SÍ funciona.
TARBALL_URL="${GITLAB_HOST}/api/v4/projects/$(printf '%s' "$REPO" | sed 's|/|%2F|g')/repository/archive.tar.gz?sha=${BRANCH}"
echo -e "  ${DIM}1/4${RESET}  Descargando mentorkit (tarball)..."

if ! curl -fsSLk -H "PRIVATE-TOKEN: $TOKEN" --max-time 180 \
        "$TARBALL_URL" -o "${TMP}/repo.tar.gz"; then
    echo -e "  ${RED}x${RESET}  Error descargando tarball desde GitLab API"
    echo "     URL: $TARBALL_URL"
    echo "     ¿Tienes acceso a la red y el TOKEN es válido?"
    exit 1
fi

# ─── 2) Extraer ────────────────────────────────────────────────────────

echo -e "  ${DIM}2/4${RESET}  Extrayendo..."
if ! tar -xzf "${TMP}/repo.tar.gz" -C "$TMP"; then
    echo -e "  ${RED}x${RESET}  Error extrayendo tarball"
    echo "     ¿Está completo el archivo? Tamaño: $(stat -c %s "${TMP}/repo.tar.gz" 2>/dev/null || echo "?") bytes"
    exit 1
fi

# El tarball extrae a 'mentorkit-main-<sha>/' (nombre con hash)
REPO_DIR=$(find "$TMP" -maxdepth 1 -mindepth 1 -type d -name "${REPO##*/}-${BRANCH}-*" | head -1)
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

# .gitlab-ci.yml — jobs verify-* reutilizables en el CI del usuario
if [[ -f "$REPO_DIR/.gitlab-ci.yml" ]]; then
    cp "$REPO_DIR/.gitlab-ci.yml" "./"
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
echo "  ${DIM}Para usar mentorkit:${RESET} abre OpenCode en este proyecto y selecciona el agente MentorKit4.0"
echo ""
