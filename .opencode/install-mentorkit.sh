#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UV=""
for candidate in uv "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv"; do
  if command -v "$candidate" >/dev/null 2>&1; then UV="$candidate"; break; fi
  if [[ -x "$candidate" ]]; then UV="$candidate"; break; fi
done
if [[ -z "$UV" ]]; then
  command -v curl >/dev/null 2>&1 || { echo "curl es necesario para instalar uv." >&2; exit 1; }
  echo "[MentorKit] uv no encontrado; instalando..."
  curl -LsSf https://astral.sh/uv/install.sh | sh || exit 1
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  command -v uv >/dev/null 2>&1 || { echo "uv no quedó disponible en PATH." >&2; exit 1; }
  UV="uv"
fi

# Backward-compatible interface: older bootstraps called this script with
# `--fix`, while the Python CLI exposes the subcommand as `fix`.
ARGS=("$@")
if [[ "${#ARGS[@]}" -eq 1 && "${ARGS[0]}" == "--fix" ]]; then
  ARGS=()
fi

exec "$UV" run --python 3.12 "$SCRIPT_DIR/mentorkit.py" fix "${ARGS[@]}"
