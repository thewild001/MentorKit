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
#
# Nothing is hand-padded: every row is measured and padded to the same inner
# width, so the frame stays aligned whatever the content length.
#   - UTF-8 locale  -> rounded box drawing and accented copy
#   - other locales -> pure ASCII frame and copy (never mis-measured)
#   - truecolor / 256 / 16 colours; plain text when stdout is not a TTY or
#     NO_COLOR is set
#   - terminals narrower than 66 columns get a frameless compact layout
# ---------------------------------------------------------------------------

# _sp_fg <truecolor "r;g;b"> <256-colour index> <16-colour SGR code>
_sp_fg() {
    case "$_SP_COLOR" in
        3) printf '\033[38;2;%sm' "$1" ;;
        2) printf '\033[38;5;%sm' "$2" ;;
        1) printf '\033[%sm' "$3" ;;
    esac
}

# _sp_fit <max> <text> — keeps the tail of text when it is too long.
_sp_fit() {
    local max="$1" s="$2"
    if (( ${#s} > max )); then s="...${s: -$(( max - 3 ))}"; fi
    printf '%s' "$s"
}

# _sp_rule <left corner> <right corner>
_sp_rule() {
    printf '  %s%s%s%s%s\n' "$_SP_FRAME" "$1" "$_SP_HLINE" "$2" "$_SP_RESET"
}

# _sp_row <left pad> <visible length> <styled content>
_sp_row() {
    local lp="$1" len="$2" content="$3" rp
    rp=$(( _SP_W - lp - len ))
    if (( rp < 0 )); then rp=0; fi
    printf '  %s%s%s%*s%s%*s%s%s%s\n' \
        "$_SP_FRAME" "$_SP_V" "$_SP_RESET" \
        "$lp" "" "$content" "$rp" "" \
        "$_SP_FRAME" "$_SP_V" "$_SP_RESET"
}

show_success_splash() {
    local cols loc probe framed=1 i r g project origin msg url
    local tl tr bl br ml mr check
    local bold="" label accent ok row_color line
    local lw=13                       # label column width
    local ESC=$'\033'
    local -a art=() steps=() g256=(81 75 69 63 99)

    # --- terminal capabilities ------------------------------------------------
    cols="${COLUMNS:-}"
    [[ "$cols" =~ ^[0-9]+$ ]] || cols="$(tput cols 2>/dev/null || true)"
    [[ "$cols" =~ ^[0-9]+$ ]] || cols=80

    loc="${LC_ALL:-${LC_CTYPE:-${LANG:-}}}"
    case "$loc" in
        *[Uu][Tt][Ff]-8*|*[Uu][Tt][Ff]8*) _SP_UTF8=1 ;;
        *) _SP_UTF8=0 ;;
    esac
    # A UTF-8 locale name is not proof: when that locale is not installed, bash
    # falls back to byte counting and every multibyte glyph would be mis-measured.
    probe='·'
    if (( _SP_UTF8 )) && (( ${#probe} != 1 )); then _SP_UTF8=0; fi

    if [[ -n "${NO_COLOR:-}" || ! -t 1 || "${TERM:-dumb}" == "dumb" ]]; then
        _SP_COLOR=0
    elif [[ "${COLORTERM:-}" == *truecolor* || "${COLORTERM:-}" == *24bit* ]]; then
        _SP_COLOR=3
    elif [[ "${TERM:-}" == *256color* ]]; then
        _SP_COLOR=2
    else
        _SP_COLOR=1
    fi

    # --- palette (slate frame, sky-to-indigo wordmark, green status) -----------
    _SP_RESET=""
    if (( _SP_COLOR > 0 )); then _SP_RESET="${ESC}[0m"; bold="${ESC}[1m"; fi
    _SP_FRAME="$(_sp_fg '100;116;139' 244 90)"
    label="$(_sp_fg '148;163;184' 247 90)"
    accent="$(_sp_fg '56;189;248' 39 36)"
    ok="$(_sp_fg '74;222;128' 78 32)"

    # --- copy and frame glyphs --------------------------------------------------
    if (( _SP_UTF8 )); then
        tl='╭'; tr='╮'; bl='╰'; br='╯'; ml='├'; mr='┤'; _SP_V='│'; _SP_H='─'
        check='✓'; msg='Instalación completada'
    else
        tl='+'; tr='+'; bl='+'; br='+'; ml='+'; mr='+'; _SP_V='|'; _SP_H='-'
        check='OK'; msg='Instalacion completada'
    fi

    # --- geometry ----------------------------------------------------------------
    if (( cols >= 66 )); then
        _SP_W=66
    else
        framed=0; _SP_W=$(( cols - 4 )); (( _SP_W < 30 )) && _SP_W=30
        tl=''; tr=''; bl=''; br=''; ml=''; mr=''; _SP_V=''
    fi
    _SP_HLINE=""
    for (( i = 0; i < _SP_W; i++ )); do _SP_HLINE+="$_SP_H"; done

    project="$(_sp_fit $(( _SP_W - lw - 6 )) "$(pwd)")"
    origin="$(_sp_fit $(( _SP_W - lw - 6 )) "${REPO} @ ${BRANCH}")"
    url="github.com/${REPO}"
    local tagline='ORGANIC-DRIVEN DEVELOPMENT  ·  ODD'
    (( _SP_UTF8 )) || tagline='ORGANIC-DRIVEN DEVELOPMENT  |  ODD'

    # --- wordmark ------------------------------------------------------------------
    while IFS= read -r line; do art+=("$line"); done <<'ART'
 __  __            _             _  ___ _
|  \/  | ___ _ __ | |_ ___  _ __| |/ (_) |_
| |\/| |/ _ \ '_ \| __/ _ \| '__| ' /| | __|
| |  | |  __/ | | | || (_) | |  | . \| | |_
|_|  |_|\___|_| |_|\__\___/|_|  |_|\_\_|\__|
ART
    local art_w=0
    for line in "${art[@]}"; do
        if (( ${#line} > art_w )); then art_w=${#line}; fi
    done

    # --- render ---------------------------------------------------------------------
    echo ""
    if (( framed )); then _sp_rule "$tl" "$tr"; else _sp_rule "" ""; fi
    _sp_row 0 0 ""

    if (( framed )); then
        for (( i = 0; i < ${#art[@]}; i++ )); do
            r=$(( 56 + 73 * i / 4 )); g=$(( 189 - 49 * i / 4 ))
            row_color="$(_sp_fg "${r};${g};248" "${g256[$i]}" 36)"
            _sp_row $(( (_SP_W - art_w) / 2 )) "${#art[$i]}" "${row_color}${bold}${art[$i]}${_SP_RESET}"
        done
    else
        _sp_row 3 9 "${accent}${bold}MentorKit${_SP_RESET}"
    fi

    _sp_row 0 0 ""
    _sp_row $(( (_SP_W - ${#tagline}) / 2 )) "${#tagline}" "${label}${tagline}${_SP_RESET}"
    _sp_row 0 0 ""
    if (( framed )); then _sp_rule "$ml" "$mr"; else _sp_rule "" ""; fi
    _sp_row 0 0 ""
    _sp_row 3 $(( ${#check} + 2 + ${#msg} )) "${ok}${bold}${check}${_SP_RESET}  ${bold}${msg}${_SP_RESET}"
    _sp_row 0 0 ""
    _sp_row 3 $(( lw + ${#origin} )) "${label}$(printf '%-*s' "$lw" 'Origen')${_SP_RESET}${origin}"
    _sp_row 3 $(( lw + ${#project} )) "${label}$(printf '%-*s' "$lw" 'Proyecto')${_SP_RESET}${project}"
    _sp_row 0 0 ""
    if (( framed )); then _sp_rule "$ml" "$mr"; else _sp_rule "" ""; fi
    _sp_row 0 0 ""
    _sp_row 3 14 "${accent}${bold}PRIMEROS PASOS${_SP_RESET}"
    _sp_row 0 0 ""

    steps=(
        'Define el objetivo que quieres alcanzar.'
        'Describe la tarea y aporta el contexto necesario.'
        'Revisa las propuestas y valida los resultados.'
    )
    for (( i = 0; i < ${#steps[@]}; i++ )); do
        _sp_row 3 $(( 4 + ${#steps[$i]} )) "${accent}0$(( i + 1 ))${_SP_RESET}  ${steps[$i]}"
    done

    _sp_row 0 0 ""
    if (( framed )); then _sp_rule "$ml" "$mr"; else _sp_rule "" ""; fi
    _sp_row 3 $(( lw + ${#url} )) "${label}$(printf '%-*s' "$lw" 'Repositorio')${_SP_RESET}${accent}${url}${_SP_RESET}"
    if (( framed )); then _sp_rule "$bl" "$br"; else _sp_rule "" ""; fi
    echo ""
}
show_success_splash
