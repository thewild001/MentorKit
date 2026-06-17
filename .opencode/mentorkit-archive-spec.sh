#!/usr/bin/env bash
# .opencode/mentorkit-archive-spec.sh
#
# Aplica un spec.md (formato delta) al system-spec.md y archiva el original.
#
# Uso:
#   bash .opencode/mentorkit-archive-spec.sh [opciones] <path-to-spec.md>
#   make archive-spec SPEC=<path>
#
# Opciones:
#   --dry-run       Parsea y computa, pero NO escribe nada. Útil para previsualizar.
#   --force         Re-archiva aunque el spec destino ya exista (sobrescribe).
#   --commit        Tras archivar, hacer git add + git commit con mensaje derivado
#                   del spec (system-spec.md + nueva carpeta archive/).
#   --no-commit     No hacer commit, aunque COMMIT=1 esté en env (override).
#   --force-dirty   Permitir commit aunque el working tree tenga cambios no
#                   relacionados con este archive (normalmente aborta).
#
# Variables de entorno (alternativas a las flags):
#   DRY_RUN=1       Equivale a --dry-run
#   FORCE=1         Equivale a --force
#   COMMIT=1        Equivale a --commit
#   FORCE_DIRTY=1   Equivale a --force-dirty
#   SPEC=<path>     Equivale a pasar el path como argumento posicional
#
# El spec debe seguir formato delta:
#   ## Status: Active
#   ## Dominio: <nombre>
#   ## Fecha:   <YYYY-MM-DD>           (opcional, default = hoy)
#   ## ADDED Requirements
#     ### Requirement: <nombre>
#       <cuerpo con scenarios>
#   ## MODIFIED Requirements
#     ### Requirement: <nombre>
#       <cuerpo nuevo>
#   ## REMOVED Requirements
#     ### Requirement: <nombre>
#       (Deprecated: <razón>)
#
# Exit codes:
#   0  - éxito
#   1  - error de uso (args faltantes, no es repo git, archivo no existe)
#   2  - spec mal formado (sin Status/Dominio/Requirements)
#   3  - error de I/O (no se pudo escribir system-spec, mover spec, o commit)
#   4  - spec ya archivado (usar --force para re-archivar)

set -uo pipefail

# ──────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────
err()  { echo "❌ $*" >&2; }
ok()   { echo "✅ $*"; }
note() { echo "ℹ  $*"; }

# ──────────────────────────────────────────────────────────────────────
# 1. Parsear flags + args
# ──────────────────────────────────────────────────────────────────────
# Defaults desde env (permite `DRY_RUN=1 make archive-spec` desde Makefile)
DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"
COMMIT="${COMMIT:-0}"
FORCE_DIRTY="${FORCE_DIRTY:-0}"
SPEC_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)      DRY_RUN=1 ;;
    --force)        FORCE=1   ;;
    --commit)       COMMIT=1  ;;
    --no-commit)    COMMIT=0  ;;
    --force-dirty)  FORCE_DIRTY=1 ;;
    -h|--help)
      sed -n '2,/^set -uo pipefail/p' "$0" | sed '$d'
      exit 0
      ;;
    --*)
      err "Flag desconocida: $1"
      err "Usa --help para ver las opciones."
      exit 1
      ;;
    *)
      SPEC_PATH="$1"
      ;;
  esac
  shift
done

# Permitir también SPEC=<path> (para compatibilidad con make)
if [ -z "$SPEC_PATH" ] && [ -n "${SPEC:-}" ]; then
  SPEC_PATH="$SPEC"
fi

if [ -z "$SPEC_PATH" ]; then
  err "Uso: $0 [opciones] <path-to-spec.md>"
  err "     make archive-spec SPEC=<path>"
  exit 1
fi

if [ ! -f "$SPEC_PATH" ]; then
  err "Spec no existe: $SPEC_PATH"
  exit 1
fi

# ──────────────────────────────────────────────────────────────────────
# 2. Detectar repo root y paths
# ──────────────────────────────────────────────────────────────────────
if ! REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  err "No estamos dentro de un repo git"
  exit 1
fi

SYSTEM_SPEC="$REPO_ROOT/openspec/system-spec.md"
ARCHIVE_DIR="$REPO_ROOT/openspec/changes/archive"
SPECS_TMP="$(mktemp -d)"
trap 'rm -rf "$SPECS_TMP"' EXIT

# ──────────────────────────────────────────────────────────────────────
# 3. Parsear el spec (Python inline)
# ──────────────────────────────────────────────────────────────────────
note "Procesando: ${SPEC_PATH#$REPO_ROOT/}"
[ "$DRY_RUN" = "1" ] && note "Modo DRY RUN: no se escribirá nada"
[ "$FORCE"   = "1" ] && note "Modo FORCE: se sobrescribirá si ya existe"

PARSE_OUT="$SPECS_TMP/parsed.json"

if python3 <<PY
import re, sys, json
from pathlib import Path

spec_path = Path("$SPEC_PATH")
content = spec_path.read_text()

# --- Metadata ---
status_m = re.search(r'^##\s+Status:\s*(.+)$', content, re.MULTILINE)
domain_m = re.search(r'^##\s+Dominio:\s*(.+)$', content, re.MULTILINE)
date_m   = re.search(r'^##\s+Fecha:\s*(.+)$',   content, re.MULTILINE)

if not status_m:
    print("Spec sin '## Status:' header", file=sys.stderr); sys.exit(2)
if not domain_m:
    print("Spec sin '## Dominio:' header", file=sys.stderr); sys.exit(2)

status = status_m.group(1).strip()
domain = domain_m.group(1).strip()
spec_date = date_m.group(1).strip() if date_m else str(Path().cwd())  # fallback dummy

from datetime import date as _date
spec_date = date_m.group(1).strip() if date_m else _date.today().isoformat()

# --- Parse requirements ---
def parse_section(text, section_name):
    pattern = rf'^##\s+{section_name}\s+Requirements\s*$\n(.*?)(?=^##\s+|\Z)'
    m = re.search(pattern, text, re.MULTILINE | re.DOTALL)
    if not m:
        return []
    block = m.group(1)
    parts = re.split(r'^###\s+Requirement:\s+', block, flags=re.MULTILINE)
    parts = [p.strip() for p in parts if p.strip()]
    result = []
    for p in parts:
        lines = p.split('\n', 1)
        name = lines[0].strip()
        body = lines[1].strip() if len(lines) > 1 else ""
        result.append({"name": name, "body": body})
    return result

added    = parse_section(content, "ADDED")
modified = parse_section(content, "MODIFIED")
removed  = parse_section(content, "REMOVED")

Path("$PARSE_OUT").write_text(json.dumps({
    "status": status,
    "domain": domain,
    "date":   spec_date,
    "added":    added,
    "modified": modified,
    "removed":  removed,
}, indent=2))
PY
then
  :  # success
else
  err "Error parseando el spec"
  exit 2
fi

# Mostrar resumen
STATUS=$(python3 -c "import json; print(json.load(open('$PARSE_OUT'))['status'])")
DOMAIN=$(python3 -c "import json; print(json.load(open('$PARSE_OUT'))['domain'])")
SPEC_DATE=$(python3 -c "import json; print(json.load(open('$PARSE_OUT'))['date'])")
N_ADDED=$(python3 -c "import json; print(len(json.load(open('$PARSE_OUT'))['added']))")
N_MODIFIED=$(python3 -c "import json; print(len(json.load(open('$PARSE_OUT'))['modified']))")
N_REMOVED=$(python3 -c "import json; print(len(json.load(open('$PARSE_OUT'))['removed']))")

note "Status=$STATUS  Dominio=$DOMAIN  Fecha=$SPEC_DATE"
note "ADDED=$N_ADDED  MODIFIED=$N_MODIFIED  REMOVED=$N_REMOVED"

# ──────────────────────────────────────────────────────────────────────
# 4. Aplicar el delta y archivar
# ──────────────────────────────────────────────────────────────────────
# Exportar vars para el Python (heredoc single-quoted no expande)
export REPO_ROOT SYSTEM_SPEC ARCHIVE_DIR SPEC_PATH PARSE_OUT DRY_RUN FORCE COMMIT FORCE_DIRTY

if python3 <<'PY'
import json, re, sys, shutil, os, subprocess
from pathlib import Path
from datetime import date

dry_run = os.environ.get("DRY_RUN", "0") == "1"
force   = os.environ.get("FORCE",   "0") == "1"

with open(os.environ["PARSE_OUT"]) as f:
    data = json.load(f)

status    = data["status"]
domain    = data["domain"]
spec_date = data["date"]
added     = data["added"]
modified  = data["modified"]
removed   = data["removed"]

system_path  = Path(os.environ["SYSTEM_SPEC"])
archive_dir  = Path(os.environ["ARCHIVE_DIR"])
repo_root    = Path(os.environ["REPO_ROOT"])
spec_path    = Path(os.environ["SPEC_PATH"]).resolve()

# --- Cargar o crear system-spec.md ---
if system_path.exists():
    system = system_path.read_text()
else:
    system = f"""# System Spec

> AUTO-GENERATED. No editar a mano.
> Para proponer cambios, crear un spec en `openspec/specs/<NNN>-<slug>/spec.md`
> con formato delta y correr `make archive-spec SPEC=<path>`.

**Última actualización**: {date.today().isoformat()}
**Specs mergeados**: 0

---
"""

# --- Split por dominio ---
def split_by_domain(text):
    sections = {}
    pattern = r'(##\s+Dominio:\s+[^\n]+\n.*?)(?=^##\s+Dominio:|\Z)'
    for m in re.finditer(pattern, text, re.MULTILINE | re.DOTALL):
        header_m = re.match(r'##\s+Dominio:\s+([^\n]+)', m.group(1))
        if header_m:
            name = header_m.group(1).strip()
            content = m.group(1).rstrip()
            # Strip trailing '---' separator (lo añade el loop de rebuild)
            if content.rstrip().endswith('---'):
                content = content.rstrip()[:-3].rstrip()
            sections[name] = content + '\n'
    return sections

# --- Update metadata ---
def update_metadata(text):
    today = date.today().isoformat()
    text = re.sub(
        r'\*\*Última actualización\*\*:\s*\S+',
        f'**Última actualización**: {today}',
        text
    )
    m = re.search(r'\*\*Specs mergeados\*\*:\s*(\d+)', text)
    if m:
        count = int(m.group(1)) + 1
        text = re.sub(
            r'(\*\*Specs mergeados\*\*:\s*)\d+',
            rf'\g<1>{count}',
            text
        )
    return text

sections = split_by_domain(system)
errors = []

# --- Calcular destino del archive (necesario para idempotency check temprano) ---
slug = spec_path.parent.name
archive_name = f"{spec_date}-{slug}"
archive_target = archive_dir / archive_name
archive_spec_target = archive_target / "spec.md"
# Guardar la ruta relativa de la carpeta origen ANTES del move (luego ya no existirá)
try:
    spec_parent_rel = spec_path.parent.relative_to(repo_root)
except ValueError:
    spec_parent_rel = spec_path.parent

# --- Chequear idempotencia (temprano, antes de iterar) ---
if archive_target.exists() and not force:
    rel = archive_target.relative_to(repo_root)
    print(f"Spec ya archivado en {rel}/", file=sys.stderr)
    print("Usa --force para re-archivar (sobrescribe el destino).", file=sys.stderr)
    sys.exit(4)

# --- ADDED ---
for req in added:
    sec = sections.get(domain, f"## Dominio: {domain}\n\n")
    new_req = f"\n\n### Requirement: {req['name']}\n{req['body']}\n"
    sections[domain] = sec.rstrip() + new_req
    print(f"  + ADDED: {req['name']}")

# --- MODIFIED ---
for req in modified:
    if domain not in sections:
        print(f"  ! MODIFIED '{req['name']}': dominio '{domain}' no existe → tratado como ADDED")
        sections[domain] = f"## Dominio: {domain}\n\n### Requirement: {req['name']}\n{req['body']}\n"
        continue
    sec = sections[domain]
    pattern = rf'(###\s+Requirement:\s+{re.escape(req["name"])}\s*\n.*?)(?=^###\s+Requirement:|^##\s+|\Z)'
    new_block = f"### Requirement: {req['name']}\n{req['body']}\n"
    new_sec, n = re.subn(pattern, new_block, sec, flags=re.MULTILINE | re.DOTALL)
    if n == 0:
        print(f"  ! MODIFIED '{req['name']}': no encontrado en '{domain}' → tratado como ADDED")
        new_sec = sec.rstrip() + f"\n\n### Requirement: {req['name']}\n{req['body']}\n"
        errors.append(f"MODIFIED no encontrado: {req['name']}")
    else:
        print(f"  ~ MODIFIED: {req['name']}")
    sections[domain] = new_sec

# --- REMOVED ---
for req in removed:
    if domain not in sections:
        print(f"  ! REMOVED '{req['name']}': dominio '{domain}' no existe → ignorado")
        continue
    sec = sections[domain]
    pattern = rf'\n*###\s+Requirement:\s+{re.escape(req["name"])}\s*\n.*?(?=\n###\s+Requirement:|\n##\s+|\Z)'
    new_sec, n = re.subn(pattern, '', sec, flags=re.MULTILINE | re.DOTALL)
    if n == 0:
        print(f"  ! REMOVED '{req['name']}': no encontrado en '{domain}' → ignorado")
        errors.append(f"REMOVED no encontrado: {req['name']}")
    else:
        print(f"  - REMOVED: {req['name']}")
    sections[domain] = new_sec

# --- Reconstruir system-spec.md ---
header_end = re.search(r'^---\s*$', system, re.MULTILINE)
if header_end:
    header = system[:header_end.end()] + '\n'
else:
    header = system.split('## Dominio:')[0]

header = update_metadata(header)

result = header
for name, body in sections.items():
    if not body.startswith('## Dominio:'):
        result += f"## Dominio: {name}\n\n"
    result += body.rstrip() + '\n\n---\n\n'

result = result.rstrip() + '\n'

# --- DRY RUN: previsualizar y salir sin escribir ---
if dry_run:
    print(f"\n  [DRY RUN] system-spec.md quedaría en {len(result)} bytes")
    print(f"  [DRY RUN] spec se archivaría en: {archive_target.relative_to(repo_root)}/")
    if errors:
        print(f"\n  ⚠ {len(errors)} advertencia(s):", file=sys.stderr)
        for e in errors:
            print(f"    - {e}", file=sys.stderr)
    print(f"\n  [DRY RUN] No se escribió nada.")
    sys.exit(0)

# --- Optional: pre-flight safety check (solo si COMMIT=1) ---
# El check va ANTES de escribir cualquier archivo, para no dejar el repo
# en estado inconsistente si abortamos.
commit      = os.environ.get("COMMIT",      "0") == "1"
force_dirty = os.environ.get("FORCE_DIRTY", "0") == "1"

if commit:
    # --untracked-files=all expande directorios untracked a sus archivos,
    # para que podamos matchear contra paths específicos en expected_rel_paths.
    status_result = subprocess.run(
        ["git", "status", "--porcelain", "--untracked-files=all"],
        cwd=str(repo_root), capture_output=True, text=True
    )
    if status_result.returncode != 0:
        print(f"Error corriendo git status: {status_result.stderr}", file=sys.stderr)
        sys.exit(3)

    # Paths que esperamos haber cambiado (los calculamos ANTES para comparar)
    expected_rel_paths = {
        str(system_path.relative_to(repo_root)),
        str(archive_target.relative_to(repo_root)),
        str(spec_path.relative_to(repo_root)),  # será eliminado
    }
    stray = []
    for line in status_result.stdout.splitlines():
        if not line.strip():
            continue
        parts = line.split(maxsplit=1)
        if len(parts) < 2:
            continue
        file_path = parts[1].rstrip("/")
        if file_path in expected_rel_paths:
            continue
        stray.append(line)
    if stray and not force_dirty:
        print("❌ Working tree tiene cambios no relacionados con este archive:", file=sys.stderr)
        for s in stray:
            print(f"   {s}", file=sys.stderr)
        print("Commitea/stage/limpia primero, o usa FORCE_DIRTY=1 para forzar.", file=sys.stderr)
        sys.exit(3)

# --- Escribir system-spec.md ---
try:
    system_path.write_text(result)
    print(f"\n  ✓ system-spec.md actualizado ({len(result)} bytes)")
except Exception as e:
    print(f"Error escribiendo system-spec.md: {e}", file=sys.stderr)
    sys.exit(3)

# --- Mover spec a archive/ ---
try:
    if force and archive_target.exists():
        # Limpiar destino para que move sea atómico
        shutil.rmtree(archive_target)
    archive_target.mkdir(parents=True, exist_ok=False)
    shutil.move(str(spec_path), archive_spec_target)
    rel = archive_target.relative_to(repo_root)
    print(f"  ✓ spec archivado en: {rel}/")
except Exception as e:
    print(f"Error archivando spec: {e}", file=sys.stderr)
    sys.exit(3)

# --- Limpiar carpeta vacía del spec original ---
try:
    spec_path.parent.rmdir()
    print(f"  ✓ carpeta origen eliminada: {spec_parent_rel}/")
except OSError:
    pass  # No estaba vacía, no hay nada que limpiar

# --- Optional: git add + commit ---
if commit:
    # Construir mensaje de commit a partir del delta
    msg_lines = [f"docs(specs): archive {spec_date} {slug} ({domain})"]
    if added:
        msg_lines.append("")
        msg_lines.append(f"ADDED ({len(added)}):")
        for req in added:
            msg_lines.append(f"  - {req['name']}")
    if modified:
        msg_lines.append("")
        msg_lines.append(f"MODIFIED ({len(modified)}):")
        for req in modified:
            msg_lines.append(f"  - {req['name']}")
    if removed:
        msg_lines.append("")
        msg_lines.append(f"REMOVED ({len(removed)}):")
        for req in removed:
            msg_lines.append(f"  - {req['name']}")
    commit_msg = "\n".join(msg_lines) + "\n"

    # git add (system-spec + new archive dir). El spec viejo (spec_path) se
    # añade solo si está tracked — si era untracked, no hay nada que stagear.
    paths_to_add = [
        str(system_path.relative_to(repo_root)),
        str(archive_target.relative_to(repo_root)),
    ]
    ls_files_result = subprocess.run(
        ["git", "ls-files", "--error-unmatch", str(spec_path.relative_to(repo_root))],
        cwd=str(repo_root), capture_output=True, text=True
    )
    if ls_files_result.returncode == 0:
        paths_to_add.append(str(spec_path.relative_to(repo_root)))

    add_result = subprocess.run(
        ["git", "add"] + paths_to_add,
        cwd=str(repo_root), capture_output=True, text=True
    )
    if add_result.returncode != 0:
        print(f"Error en git add: {add_result.stderr}", file=sys.stderr)
        sys.exit(3)

    # git commit
    commit_result = subprocess.run(
        ["git", "commit", "-m", commit_msg],
        cwd=str(repo_root), capture_output=True, text=True
    )
    if commit_result.returncode != 0:
        print(f"Error en git commit: {commit_result.stderr}", file=sys.stderr)
        sys.exit(3)

    # Get commit SHA
    sha_result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=str(repo_root), capture_output=True, text=True
    )
    sha = sha_result.stdout.strip()[:10]
    title = commit_msg.split("\n")[0]
    print(f"  ✓ commit: {sha} {title}")

if errors:
    print(f"\n  ⚠ {len(errors)} advertencia(s):", file=sys.stderr)
    for e in errors:
        print(f"    - {e}", file=sys.stderr)
PY
then
  :  # success
else
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 4 ]; then
    err "Spec ya archivado. Usa --force para re-archivar."
  else
    err "Error aplicando el delta"
  fi
  exit $EXIT_CODE
fi

if [ "$DRY_RUN" = "1" ]; then
  ok "Dry run completado (no se escribió nada)"
else
  ok "Archive completo"
  note "System spec: ${SYSTEM_SPEC#$REPO_ROOT/}"
fi
