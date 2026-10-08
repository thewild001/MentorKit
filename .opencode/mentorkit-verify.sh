#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PY=""
for candidate in "$SCRIPT_DIR/.mentorkit/venv/bin/python" "$SCRIPT_DIR/.mentorkit/venv/Scripts/python.exe" python3 python py; do
  if [[ -x "$candidate" ]] || command -v "$candidate" >/dev/null 2>&1; then PY="$candidate"; break; fi
done
[[ -n "$PY" ]] || { echo "Python no disponible. Ejecuta el instalador de MentorKit." >&2; exit 1; }
exec "$PY" "$SCRIPT_DIR/mentorkit.py" verify "$@"
