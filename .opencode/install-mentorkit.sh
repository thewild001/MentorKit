#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PY=""
for candidate in python3 python py; do
  if command -v "$candidate" >/dev/null 2>&1; then PY="$candidate"; break; fi
done
[[ -n "$PY" ]] || { echo "Python no disponible. En Windows usa install-mentorkit.ps1; en Linux/macOS usa bootstrap.sh." >&2; exit 1; }
exec "$PY" "$SCRIPT_DIR/mentorkit.py" fix "$@"
