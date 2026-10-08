#!/usr/bin/env bash
# Crea un documento ODD mínimo para trabajo SUBSTANTIAL.
# Uso: bash .opencode/mentorkit-odd-task.sh <feature-name> "<request>"
set -uo pipefail

FEATURE="${1:-}"
REQUEST="${2:-}"

if [[ -z "$FEATURE" || -z "$REQUEST" ]]; then
  echo "Uso: $0 <feature-name> \"<request>\"" >&2
  exit 1
fi

case "$FEATURE" in
  *[!a-zA-Z0-9_-]*)
    echo "feature-name debe usar solo letras, números, '-' o '_'" >&2
    exit 1
    ;;
esac

DIR="odd/tasks"
FILE="$DIR/$FEATURE.md"
mkdir -p "$DIR"

if [[ -e "$FILE" ]]; then
  echo "❌ Ya existe: $FILE" >&2
  exit 2
fi

cat > "$FILE" <<EOF
# $FEATURE

## Objective

Pendiente de completar durante Explore.

## Specs

S1. Pendiente de definir tras Explore.
- Acceptance: pendiente
- Checks: pendiente

## Tasks

- [ ] T1 — Pendiente de descomponer
  - Spec: S1
  - Route: pendiente
  - Commit: pending

## Verification

- [ ] S1 — pendiente
- [ ] Tests/checks: pendiente
- [ ] Regressions: pendiente

## Log

L1. $REQUEST

## Delivery

- Status: active
- Branch: $(git branch --show-current 2>/dev/null || echo "unknown")
- Review candidate: pending
- Next step: Explore
EOF

echo "✓ ODD task creado: $FILE"
