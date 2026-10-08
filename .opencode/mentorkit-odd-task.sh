#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${PYTHON:-}"
if [[ -z "$PY" ]]; then
  for candidate in python3 python py; do
    if command -v "$candidate" >/dev/null 2>&1; then PY="$candidate"; break; fi
  done
fi
[[ -n "$PY" ]] || { echo "Python no disponible. Ejecuta el instalador de MentorKit." >&2; exit 1; }
exec "$PY" "$SCRIPT_DIR/mentorkit.py" odd-task "$@"
