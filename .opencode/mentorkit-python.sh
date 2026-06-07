#!/usr/bin/env bash
# .opencode/mentorkit-python.sh
# SIEMPRE ejecuta Python con el venv de MentorKit.
#
# Por qué existe: el agente LLM corre comandos Bash en su propio shell, que
# puede tener cualquier Python en PATH (sistema, pyenv, conda, ninguno).
# Si la skill hace "python3 -c 'import markitdown'" sin este wrapper, el
# import puede fallar o caer en el Python equivocado. Este wrapper
# garantiza que SIEMPRE se use el Python del venv que el installer creó,
# leyendo la ruta desde .opencode/.mentorkit/python-path.txt.
#
# Uso:
#   .opencode/mentorkit-python.sh <args...>
#
# Ejemplos:
#   .opencode/mentorkit-python.sh -c "import markitdown; print(markitdown.__version__)"
#   .opencode/mentorkit-python.sh -m pip install foo
#   .opencode/mentorkit-python.sh script.py arg1 arg2
#
# Si el venv no está disponible, hace fallback a python3 del sistema
# con un WARNING explícito (no falla silenciosamente). Esto permite que
# el script siga funcionando en entornos donde el venv aún no se instaló,
# aunque markitdown/striprtf/graphify no estén disponibles.
#
# Compatibilidad: bash (Linux/macOS/Git Bash en Windows). En cmd.exe de
# Windows nativo, los skills deben invocar Python directamente.

set -uo pipefail

# Resolver ruta absoluta de este script (soporta ser invocado desde cualquier cwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_PATH_FILE="${SCRIPT_DIR}/.mentorkit/python-path.txt"

# Caso 1: venv disponible y Python ejecutable
if [[ -f "$PYTHON_PATH_FILE" ]]; then
    VENV_PYTHON="$(cat "$PYTHON_PATH_FILE" 2>/dev/null | tr -d '[:space:]')"
    if [[ -n "$VENV_PYTHON" && -x "$VENV_PYTHON" ]]; then
        exec "$VENV_PYTHON" "$@"
    fi
fi

# Caso 2: fallback a python3 del sistema (con WARNING explícito)
if command -v python3 >/dev/null 2>&1; then
    cat >&2 <<EOF
WARNING: venv de MentorKit no disponible
  - Esperado: ${PYTHON_PATH_FILE}
  - Usando python3 del sistema (markitdown/striprtf/graphify NO instalados)
  - Solución: ejecuta .opencode/install-mentorkit.sh
EOF
    exec python3 "$@"
fi

# Caso 3: ni venv ni python3 — falla dura con mensaje claro
cat >&2 <<EOF
ERROR: ni el venv de MentorKit ni python3 están disponibles.
  - ¿Está Python instalado en este sistema?
  - ¿Está creado el venv en .opencode/.mentorkit/venv/?
  - Solución: ejecuta .opencode/install-mentorkit.sh
EOF
exit 1
