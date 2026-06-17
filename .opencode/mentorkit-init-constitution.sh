#!/usr/bin/env bash
# .opencode/mentorkit-init-constitution.sh
#
# Genera (o regenera) `openspec/memory/constitution.md` del proyecto destino
# a partir de `openspec/memory/constitution.template.md` (CONSTITUCIONALES
# verbatim) + fingerprint del proyecto (Stack, scripts) auto-detectado.
#
# ENRICH-aware: si el constitution.md destino ya existe, las secciones
# añadidas por humanos (que no estén en el template) se preservan. Las
# secciones CONSTITUCIONALES siempre se sobrescriben con la versión del
# template (son ground truth).
#
# Uso:
#   bash .opencode/mentorkit-init-constitution.sh [opciones]
#   make init-constitution [DRY_RUN=1] [FORCE=1] [NO_FINGERPRINT=1] [NO_GRAPH=1]
#
# Opciones:
#   --dry-run           Computa fingerprint + render, pero NO escribe.
#                       Imprime el output completo a stdout.
#   --force             Sobreescribe destination sin pedir confirmación.
#   --no-fingerprint    Skip fingerprint. Renderiza solo el template
#                       (Stack section queda con placeholders).
#   --no-graph          Skip graph integration. Sub-sección Architecture
#                       queda con placeholder "grafo no disponible".
#   --target <path>     [DEPRECATED — se ignora]
#   -h | --help         Mostrar esta ayuda.
#
# Variables de entorno (alternativas a las flags):
#   DRY_RUN=1           Equivale a --dry-run
#   FORCE=1             Equivale a --force
#   NO_FINGERPRINT=1    Equivale a --no-fingerprint
#   NO_GRAPH=1          Equivale a --no-graph
#   TARGET=<path>       Equivale a --target
#
# Exit codes:
#   0  - éxito (incluye dry-run exitoso y "sin cambios")
#   1  - error de uso (no es repo git, flag inválida, args faltantes)
#   2  - template malformado (markers faltantes o duplicados)
#   3  - error de I/O (no se pudo escribir destination)
#   4  - no se detectó stack (proyecto sin manifests reconocidos)
#   5  - usuario abortó en el confirmation gate

set -uo pipefail

# ──────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────
err()  { echo "❌ $*" >&2; }
ok()   { echo "✅ $*"; }
note() { echo "ℹ  $*"; }

# ──────────────────────────────────────────────────────────────────────
# 1. Parsear flags + env vars
# ──────────────────────────────────────────────────────────────────────
DRY_RUN="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"
NO_FINGERPRINT="${NO_FINGERPRINT:-0}"
NO_GRAPH="${NO_GRAPH:-0}"
TARGET="${TARGET:-openspec/memory/constitution.md}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)         DRY_RUN=1 ;;
    --force)           FORCE=1 ;;
    --no-fingerprint)  NO_FINGERPRINT=1 ;;
    --no-graph)        NO_GRAPH=1 ;;
    --target)          shift 2 ;;  # deprecated, se ignora
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
      err "Argumento posicional no esperado: $1"
      err "Usa --help para ver las opciones."
      exit 1
      ;;
  esac
  shift
done

# ──────────────────────────────────────────────────────────────────────
# 2. Detectar repo root
# ──────────────────────────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  err "No estamos dentro de un repo git."
  exit 1
}
cd "$REPO_ROOT" || { err "No se pudo cd a $REPO_ROOT"; exit 1; }
note "Repo root: $REPO_ROOT"
note "Target:    $TARGET"

# ──────────────────────────────────────────────────────────────────────
# 3. Validar template
# ──────────────────────────────────────────────────────────────────────
TEMPLATE_PATH="$REPO_ROOT/openspec/memory/constitution.template.md"
[ -f "$TEMPLATE_PATH" ] || {
  err "Template no encontrado: $TEMPLATE_PATH"
  err "Pieza 2 (template) debe estar commiteada antes de usar este script."
  exit 2
}

# Validar que el template tiene los markers requeridos
for marker in "CONSTITUCIONAL" "auto-derivado" "IDENTIDAD"; do
  if ! grep -q "<!-- $marker -->" "$TEMPLATE_PATH"; then
    err "Template malformado: falta marker <!-- $marker -->"
    exit 2
  fi
done
note "Template OK (3 marcadores presentes)"

# ──────────────────────────────────────────────────────────────────────
# 4. Compute fingerprint (Python heredoc) → /tmp/.fingerprint.json
# ──────────────────────────────────────────────────────────────────────
FINGERPRINT_FILE="$(mktemp -t mk-fp.XXXXXX)"
ENRICHED_SECTIONS_FILE="$(mktemp -t mk-en.XXXXXX)"
RENDERED_FILE="$(mktemp -t mk-rd.XXXXXX)"
trap 'rm -f "$FINGERPRINT_FILE" "$ENRICHED_SECTIONS_FILE" "$RENDERED_FILE"' EXIT

if [ "$NO_FINGERPRINT" = "1" ]; then
  note "Fingerprint desactivado (--no-fingerprint)"
  echo '{"stack": null, "scripts": [], "engram": false, "graph": {"available": false, "god_nodes": [], "communities": [], "rationale_count": 0}}' > "$FINGERPRINT_FILE"
else
  note "Computando fingerprint del proyecto (4 stacks)..."
  if REPO_ROOT="$REPO_ROOT" python3 <<'PYEOF' > "$FINGERPRINT_FILE"
import os, re, json, subprocess
from pathlib import Path

repo_root = Path(os.environ['REPO_ROOT'])

stack = {
    'lang': None, 'version': None, 'pkg_manager': None,
    'lock_file': None, 'vcs': 'git', 'ci': None, 'platforms': [],
}

# ── Python (priority: uv.lock > requirements.lock > pyproject.toml) ──
uv_lock = repo_root / 'uv.lock'
pyproject = repo_root / 'pyproject.toml'
py_version = repo_root / '.python-version'
opencode_req_lock = repo_root / '.opencode' / 'requirements.lock'

if uv_lock.exists():
    stack['lang'] = 'Python'
    stack['pkg_manager'] = 'uv'
    stack['lock_file'] = 'uv.lock'
    if py_version.exists():
        stack['version'] = py_version.read_text().strip()
    elif pyproject.exists():
        m = re.search(r'requires-python\s*=\s*["\']([^"\']+)["\']', pyproject.read_text())
        if m:
            stack['version'] = m.group(1).replace('>=', '').replace('~=', '').replace('==', '').strip()
elif opencode_req_lock.exists():
    stack['lang'] = 'Python'
    stack['pkg_manager'] = 'uv'
    stack['lock_file'] = '.opencode/requirements.lock'
    if py_version.exists():
        stack['version'] = py_version.read_text().strip()
elif pyproject.exists():
    text = pyproject.read_text()
    if '[tool.uv]' in text or re.search(r'^\[project\]', text, re.MULTILINE):
        stack['lang'] = 'Python'
        stack['pkg_manager'] = 'uv' if '[tool.uv]' in text else 'pip'
        m = re.search(r'requires-python\s*=\s*["\']([^"\']+)["\']', text)
        if m:
            stack['version'] = m.group(1).replace('>=', '').replace('~=', '').replace('==', '').strip()
elif py_version.exists():
    stack['lang'] = 'Python'
    stack['version'] = py_version.read_text().strip()

# ── Go ──────────────────────────────────────────────────────────────
go_mod = repo_root / 'go.mod'
if not stack['lang'] and go_mod.exists():
    text = go_mod.read_text()
    m = re.search(r'^go\s+(\d+\.\d+(?:\.\d+)?)', text, re.MULTILINE)
    stack['lang'] = 'Go'
    stack['version'] = m.group(1) if m else None
    stack['pkg_manager'] = 'go modules'
    stack['lock_file'] = 'go.sum' if (repo_root / 'go.sum').exists() else None

# ── Node.js ─────────────────────────────────────────────────────────
pkg_json = repo_root / 'package.json'
if not stack['lang'] and pkg_json.exists():
    if (repo_root / 'package-lock.json').exists():
        stack['lang'] = 'Node.js'
        stack['pkg_manager'] = 'npm'
        stack['lock_file'] = 'package-lock.json'
    elif (repo_root / 'yarn.lock').exists():
        stack['lang'] = 'Node.js'
        stack['pkg_manager'] = 'yarn'
        stack['lock_file'] = 'yarn.lock'
    elif (repo_root / 'pnpm-lock.yaml').exists():
        stack['lang'] = 'Node.js'
        stack['pkg_manager'] = 'pnpm'
        stack['lock_file'] = 'pnpm-lock.yaml'
    else:
        stack['lang'] = 'Node.js'
        stack['pkg_manager'] = 'npm'

# ── Rust ────────────────────────────────────────────────────────────
cargo = repo_root / 'Cargo.toml'
if not stack['lang'] and cargo.exists():
    stack['lang'] = 'Rust'
    stack['pkg_manager'] = 'cargo'
    stack['lock_file'] = 'Cargo.lock' if (repo_root / 'Cargo.lock').exists() else None

# ── CI detection ────────────────────────────────────────────────────
if (repo_root / '.gitlab-ci.yml').exists():
    stack['ci'] = 'GitLab CI'
elif (repo_root / '.github' / 'workflows').is_dir() \
     and any((repo_root / '.github' / 'workflows').glob('*.y*ml')):
    stack['ci'] = 'GitHub Actions'
elif (repo_root / '.circleci').is_dir():
    stack['ci'] = 'CircleCI'
elif (repo_root / 'azure-pipelines.yml').exists():
    stack['ci'] = 'Azure Pipelines'
else:
    stack['ci'] = 'N/A (no detectado)'

# ── Scripts principales: top-N top-level ejecutables ───────────────
scripts = []
find_result = subprocess.run(
    ['find', str(repo_root), '-maxdepth', '3', '-type', 'f',
     '(', '-name', '*.sh', '-o', '-name', 'Makefile', '-o', '-name', 'bootstrap.sh', ')',
     '-not', '-path', '*/.git/*',
     '-not', '-path', '*/.opencode/.mentorkit/*',
     '-not', '-path', '*/node_modules/*',
     '-not', '-path', '*/venv/*',
     '-not', '-path', '*/__pycache__/*',
     '-not', '-path', '*/target/*'],
    capture_output=True, text=True
)
for line in find_result.stdout.splitlines()[:10]:
    p = Path(line)
    if not p.exists():
        continue
    rel = p.relative_to(repo_root)
    role = '(rol no detectado)'
    try:
        text = p.read_text(errors='ignore')
        for hdr_line in text.splitlines()[:25]:
            m = re.match(r'#\s*(?:Rol|Script|Use|Uso)\s*:\s*(.+)', hdr_line, re.IGNORECASE)
            if m:
                role = m.group(1).strip()
                break
    except Exception:
        pass
    scripts.append({'path': str(rel), 'role': role})

# ── engram check ──────────────────────────────────────────────────
engram_check = subprocess.run(
    ['bash', '-c', 'command -v engram >/dev/null 2>&1'],
    capture_output=True
)
engram_available = engram_check.returncode == 0

# ── Graph check (graphify-out/graph.json si existe) ─────────────────
graph_data = {'available': False, 'god_nodes': [], 'communities': [], 'rationale_count': 0}
graph_json = repo_root / 'graphify-out' / 'graph.json'
if graph_json.exists():
    try:
        gdata = json.loads(graph_json.read_text())
        g_nodes = gdata.get('nodes', [])
        g_links = gdata.get('links', gdata.get('edges', []))
        # God nodes: top-10 by degree (in + out)
        from collections import Counter, defaultdict
        degree = Counter()
        for link in g_links:
            degree[link.get('source', '')] += 1
            degree[link.get('target', '')] += 1
        nodes_by_id = {n['id']: n for n in g_nodes if 'id' in n}
        god_nodes = [
            {'label': nodes_by_id.get(nid, {}).get('label', nid), 'degree': cnt}
            for nid, cnt in degree.most_common(10) if nid
        ]
        # Communities: top-5 by size
        communities_map = defaultdict(list)
        for nid, node in nodes_by_id.items():
            comm = str(node.get('community', node.get('cluster', 'general')))
            label = node.get('label', nid)
            if label:
                communities_map[comm].append(label)
        top_communities = sorted(
            communities_map.items(), key=lambda x: len(x[1]), reverse=True
        )[:5]
        # Rationale nodes count
        rationale_count = sum(
            1 for n in g_nodes
            if n.get('type', '') == 'rationale_for'
            or any(kw in str(n.get('label', '')).lower()
                   for kw in ['rationale', 'why', 'hack', 'important', 'note'])
        )
        graph_data = {
            'available': True,
            'god_nodes': god_nodes,
            'communities': [
                {'id': cid, 'size': len(members), 'top_members': members[:5]}
                for cid, members in top_communities
            ],
            'rationale_count': rationale_count,
            'total_nodes': len(g_nodes),
            'total_links': len(g_links),
        }
    except (json.JSONDecodeError, KeyError, TypeError) as e:
        # graph.json corrupto → degradar graciosamente
        graph_data = {'available': False, 'error': str(e), 'god_nodes': [], 'communities': [], 'rationale_count': 0}

result = {
    'stack': stack,
    'scripts': scripts,
    'engram': engram_available,
    'graph': graph_data,
}
print(json.dumps(result, indent=2, ensure_ascii=False))
PYEOF
  then
    note "Fingerprint OK"
  else
    err "Fingerprint Python heredoc falló (rc=$?)"
    exit 1
  fi
fi



# Validar fingerprint
if ! python3 -c "import json,sys; d=json.load(open('$FINGERPRINT_FILE')); assert 'stack' in d"; then
  err "Fingerprint JSON inválido"
  exit 1
fi

# Mostrar fingerprint resumido
STACK_LANG=$(python3 -c "import json; d=json.load(open('$FINGERPRINT_FILE')); s=d.get('stack') or {}; print(s.get('lang') or '(no detectado)')")
STACK_VER=$(python3 -c "import json; d=json.load(open('$FINGERPRINT_FILE')); s=d.get('stack') or {}; print(s.get('version') or '-')")
SCRIPTS_N=$(python3 -c "import json; d=json.load(open('$FINGERPRINT_FILE')); print(len(d.get('scripts', [])))")
ENGRAM=$(python3 -c "import json; d=json.load(open('$FINGERPRINT_FILE')); print('sí' if d.get('engram') else 'no')")
GRAPH_AVAIL=$(python3 -c "import json; d=json.load(open('$FINGERPRINT_FILE')); g=d.get('graph') or {}; print('sí' if g.get('available') else 'no')")
note "Stack detectado: $STACK_LANG $STACK_VER"
note "Scripts: $SCRIPTS_N"
note "engram: $ENGRAM"
note "graph: $GRAPH_AVAIL"

# S3: Override graph data si --no-graph está activo (después de mostrar
# el status arriba, así el dev ve lo que se habría detectado)
if [ "$NO_GRAPH" = "1" ]; then
  note "Graph integration desactivado (--no-graph)"
  python3 -c "
import json
fp_path = '$FINGERPRINT_FILE'
d = json.load(open(fp_path))
d['graph'] = {'available': False, 'god_nodes': [], 'communities': [], 'rationale_count': 0, 'disabled_by_flag': True}
json.dump(d, open(fp_path, 'w'), indent=2, ensure_ascii=False)
"
fi

# ──────────────────────────────────────────────────────────────────────
# 5. Render (Python heredoc) → /tmp/.rendered.md
# ──────────────────────────────────────────────────────────────────────
note "Renderizando constitución desde template + fingerprint..."
TEMPLATE_PATH="$TEMPLATE_PATH" FINGERPRINT_FILE="$FINGERPRINT_FILE" \
  TARGET="$TARGET" REPO_ROOT="$REPO_ROOT" NO_FINGERPRINT="$NO_FINGERPRINT" \
  python3 <<'PYEOF' > "$RENDERED_FILE"
import os, re, sys, json
from pathlib import Path

template_path = Path(os.environ['TEMPLATE_PATH'])
fingerprint = json.loads(Path(os.environ['FINGERPRINT_FILE']).read_text())
target_rel = os.environ['TARGET']
repo_root = Path(os.environ['REPO_ROOT'])
target_abs = repo_root / target_rel
no_fingerprint = os.environ.get('NO_FINGERPRINT', '0') == '1'

stack = fingerprint.get('stack') or {}
scripts = fingerprint.get('scripts', [])
engram_available = fingerprint.get('engram', False)

# Si --no-fingerprint, no abortar por stack vacío (el dev quiere renderizar
# solo el template, con placeholders N/A en el Stack section)
if not stack.get('lang') and not no_fingerprint:
    print("ERROR: No se detectó stack. Aborta.", file=sys.stderr)
    sys.exit(4)

template = template_path.read_text()

# ── Parsear template en secciones ──────────────────────────────────
def strip_code_blocks(text):
    """Elimina bloques de código (```...```) del texto para evitar falsos
    positivos al parsear delimitadores `---` y headings `## `.
    
    Preserva longitudes de LÍNEA (cada línea del code block se reemplaza
    con un string de la misma longitud) para que los offsets en el texto
    stripped correspondan a los offsets en el texto original. Esto es
    crítico: si las longitudes no coinciden, el parser extrae contenido
    de posiciones incorrectas.
    """
    def replacer(match):
        lines = match.group(0).split('\n')
        # Cada línea se reemplaza con un string de la misma longitud
        # (espacios) para preservar offsets absolutos
        return '\n'.join(' ' * len(line) for line in lines)
    return re.sub(r'```[\s\S]*?```', replacer, text)

def parse_template_sections(text):
    """Parse template en secciones, delimitadas por `---`.
    
    Estructura del template: cada bloque entre `---` contiene un marker
    (CONSTITUCIONAL / auto-derivado / IDENTIDAD), un heading `## `, y
    el contenido. El preamble (H1 + blockquote intro) está antes del
    primer `---`.
    
    Returns: (preamble, sections)
    - preamble: texto antes del primer `---` (ORIGINAL, con code blocks)
    - sections: list de {title, type, content} en orden
    """
    text_stripped = strip_code_blocks(text)
    sep_positions = [m.start() for m in re.finditer(r'(?m)^---\s*$', text_stripped)]
    
    if sep_positions:
        preamble_end = sep_positions[0] + 4
        section_ranges = []
        for i, sep_pos in enumerate(sep_positions):
            section_start = sep_pos + 4
            section_end = sep_positions[i + 1] if i + 1 < len(sep_positions) else len(text_stripped)
            section_ranges.append((section_start, section_end))
    else:
        preamble_end = 0
        section_ranges = [(0, len(text_stripped))]
    
    preamble = text[:preamble_end].rstrip() + '\n' if preamble_end > 0 else ''
    
    sections = []
    for start, end in section_ranges:
        if start >= end:
            continue
        section_text_stripped = text_stripped[start:end]
        # Marker en el chunk stripped
        marker_match = re.search(r'<!--\s*(CONSTITUCIONAL|auto-derivado|IDENTIDAD)\s*-->', section_text_stripped)
        marker = marker_match.group(1) if marker_match else 'ENRICHMENT'
        # Heading en el chunk stripped
        heading_match = re.search(r'^##\s+(.+?)\s*$', section_text_stripped, re.MULTILINE)
        if not heading_match:
            continue
        title = heading_match.group(1).strip()
        # Heading end en chunk_stripped
        heading_end_in_chunk = heading_match.end()
        # Convertir a posición absoluta en text_stripped
        heading_end_abs = start + heading_end_in_chunk
        # Extraer content del texto ORIGINAL (con code blocks)
        content = text[heading_end_abs:end].rstrip() + '\n'
        sections.append({
            'title': title,
            'type': marker,
            'content': content,
        })
    
    return preamble, sections

preamble_tpl, tpl_sections = parse_template_sections(template)

# ── Parsear destination (si existe) ────────────────────────────────
def parse_destination_sections(text):
    """Parse destination constitution en secciones, delimitadas por H2.
    
    A diferencia del template (que usa `---` entre secciones), el
    destination puede tener H2s sin `---` entre ellos. Por eso usamos
    los H2 como delimitadores primarios.
    
    Returns: (preamble, sections)
    - preamble: texto antes del primer H2 (ORIGINAL, con code blocks)
    - sections: list de {title, content} en orden
    """
    text_stripped = strip_code_blocks(text)
    
    # Encontrar posiciones de todos los H2 en stripped text
    h2_positions = [(m.start(), m.end(), m.group(1).strip())
                    for m in re.finditer(r'^##\s+(.+?)\s*$', text_stripped, re.MULTILINE)]
    
    if not h2_positions:
        return text, []
    
    # Preamble: texto antes del primer H2
    first_h2_start = h2_positions[0][0]
    preamble = text[:first_h2_start]
    # Strip `---` lines (separadores residuales de archivos viejos) y
    # whitespace trailing → evita duplicación de `---` en cada re-render
    preamble = re.sub(r'(?m)^---\s*\n', '', preamble)
    preamble = preamble.rstrip() + '\n' if preamble else ''
    
    sections = []
    for i, (h2_start, h2_end, title) in enumerate(h2_positions):
        # Siguiente H2 start o EOF
        next_h2_start = h2_positions[i + 1][0] if i + 1 < len(h2_positions) else len(text)
        # Content: desde h2_end hasta next_h2_start
        content = text[h2_end:next_h2_start]
        # Strip `---` lines (eran separadores en archivos viejos, ahora son contenido
        # residual que se duplica en cada re-render → rompe idempotency)
        content = re.sub(r'(?m)^---\s*\n', '', content)
        content = content.rstrip() + '\n'
        sections.append({
            'title': title,
            'content': content,
        })
    
    return preamble, sections

dest_sections = []
if target_abs.exists():
    dest_text = target_abs.read_text()
    _, dest_sections = parse_destination_sections(dest_text)
dest_titles = {s['title']: s for s in dest_sections}

# ── Generar contenido para cada sección auto-derivada ─────────────
def build_stack_section():
    """Genera el contenido del `## Stack tecnológico` completo."""
    lines = []
    
    # Stack section intro
    lines.append("Las herramientas que el agente asume disponibles y sus versiones pin.")
    lines.append("Auto-detectado por el fingerprint del proyecto destino; el dev puede")
    lines.append("sobreescribir cualquier campo manualmente.")
    lines.append("")
    
    # Stack fields (use 'N/A' for None values to avoid printing Python's "None")
    def val(key, default='N/A'):
        v = stack.get(key)
        return v if v else default
    
    lines.append(f"- **Lenguaje principal:** {val('lang')}")
    lines.append(f"- **Versión pin:** {val('version')}")
    lines.append(f"- **Package manager:** {val('pkg_manager')}")
    lines.append(f"- **Lock file:** {val('lock_file')}")
    lines.append(f"- **VCS:** {val('vcs', 'git')}")
    lines.append(f"- **CI platform:** {val('ci')}")
    platforms = stack.get('platforms') or []
    lines.append(f"- **Plataformas target:** {', '.join(platforms) if platforms else 'N/A'}")
    lines.append("")
    
    # Sub-section: Dependencias críticas
    lines.append("### Dependencias críticas (top-N por rol)")
    lines.append("")
    lines.append("<!-- llenar manualmente: framework, ORM, test runner, linter, etc. -->")
    lines.append("")
    lines.append("<!-- Pieza 3b.1: el fingerprint no extrae top-N deps todavía. ")
    lines.append("     Esto se enriquece en iteraciones futuras. -->")
    lines.append("")
    
    # Sub-section: Scripts principales
    lines.append("### Scripts principales")
    lines.append("")
    if scripts:
        lines.append("| Script | Rol |")
        lines.append("|---|---|")
        for s in scripts:
            lines.append(f"| `{s['path']}` | {s['role']} |")
    else:
        lines.append("<!-- No se detectaron scripts top-level ejecutables. -->")
    lines.append("")

    # Sub-section: Architecture (grafo de conocimiento)
    lines.append("### Architecture (grafo de conocimiento)")
    lines.append("")
    graph = fingerprint.get('graph') or {}
    if graph.get('available'):
        total = graph.get('total_nodes', 0)
        links = graph.get('total_links', 0)
        rationale_n = graph.get('rationale_count', 0)
        lines.append(f"Grafo detectado: **{total} nodos, {links} aristas, "
                     f"{rationale_n} nodos rationale** "
                     f"(`graphify-out/graph.json`).")
        lines.append("")
        god_nodes = graph.get('god_nodes', [])
        if god_nodes:
            lines.append("**God nodes (módulos críticos por grado):**")
            lines.append("")
            lines.append("| Módulo | Grado |")
            lines.append("|---|---|")
            for gn in god_nodes[:10]:
                lines.append(f"| `{gn['label']}` | {gn['degree']} |")
            lines.append("")
        communities = graph.get('communities', [])
        if communities:
            lines.append("**Comunidades naturales (top-5 por tamaño):**")
            lines.append("")
            for comm in communities:
                members = ', '.join(f"`{m}`" for m in comm['top_members'])
                lines.append(f"- **Comunidad {comm['id']}** ({comm['size']} nodos): "
                             f"{members}{'...' if comm['size'] > 5 else ''}")
            lines.append("")
    elif graph.get('disabled_by_flag'):
        lines.append("<!-- Architecture omitida: --no-graph flag activo. -->")
        lines.append("")
    elif graph.get('error'):
        lines.append(f"<!-- Architecture omitida: graphify-out/graph.json corrupto "
                     f"({graph['error']}). -->")
        lines.append("")
    else:
        lines.append("<!-- Architecture omitida: graphify-out/graph.json no disponible. "
                     "Construye el grafo con `.opencode/.mentorkit/venv/bin/graphify . "
                     "--no-viz --quiet` y vuelve a correr init-constitution. -->")
        lines.append("")

    return "\n".join(lines)

# ── Renderizar cada sección del template ──────────────────────────
def strip_section_marker(text, marker):
    """Elimina la línea `<!-- MARKER -->` del texto de una sección."""
    pattern = re.compile(rf'^\s*<!--\s*{re.escape(marker)}\s*-->\s*\n', re.MULTILINE)
    return pattern.sub('', text, count=1)

# Construir preamble del destination (H1 + blockquote) si existe,
# sino el del template
output_preamble = ''
if dest_sections and target_abs.exists():
    # Re-extraer preamble del destination (H1, blockquote, etc.)
    dest_text = target_abs.read_text()
    dest_chunks = re.split(r'(?m)^---\s*$', dest_text)
    if dest_chunks:
        output_preamble = dest_chunks[0]
elif preamble_tpl:
    output_preamble = preamble_tpl

# Normalizar preamble: colapsar whitespace y strip `---` residual
# (sin esto, blank lines se acumulan en cada re-render → rompe idempotency)
if output_preamble:
    # Strip `---` lines (separadores residuales)
    output_preamble = re.sub(r'(?m)^---\s*\n', '', output_preamble)
    # Strip comentarios `<!-- ... -->` (markers del template que ya no deben
    # aparecer en el destination renderizado)
    output_preamble = re.sub(r'(?m)^<!--.*?-->\s*\n?', '', output_preamble)
    # Colapsar 3+ newlines a exactamente 2 (1 blank line entre bloques)
    output_preamble = re.sub(r'\n{3,}', '\n\n', output_preamble)
    output_preamble = output_preamble.rstrip() + '\n'

# Si no hay preamble del destination, usar el del template pero
# ajustar el H1 al project_name (del fingerprint si está, o "del proyecto")
project_name = repo_root.name
h1_match = re.search(r'^#\s+Constitución\s+de\s+[^\n]+$', output_preamble, re.MULTILINE)
if h1_match:
    output_preamble = re.sub(
        r'^#\s+Constitución\s+de\s+[^\n]+$',
        f'# Constitución de {project_name}',
        output_preamble,
        count=1,
        flags=re.MULTILINE
    )
elif not h1_match:
    # No H1 en preamble, añadir uno
    output_preamble = f"# Constitución de {project_name}\n\n" + output_preamble

# Construir output final
out_parts = [output_preamble]
tpl_titles = set()

for tpl_sec in tpl_sections:
    tpl_titles.add(tpl_sec['title'])
    
    if tpl_sec['type'] == 'auto-derivado':
        # Regenerar desde fingerprint
        content = build_stack_section()
        out_parts.append(f"\n---\n\n## {tpl_sec['title']}\n\n{content}\n")
    elif tpl_sec['type'] == 'CONSTITUCIONAL':
        # Tomar del template (ground truth). Si el dev lo editó, se sobrescribe
        # con la versión del template (esto es drift, mostrar en confirmation gate).
        content = tpl_sec['content']
        out_parts.append(f"\n---\n\n## {tpl_sec['title']}\n\n{content}\n")
    elif tpl_sec['type'] == 'IDENTIDAD':
        # Si el destination tiene esta sección, preservar la versión del dev
        # (que ya llenó los `<!-- llenar manualmente -->`)
        if tpl_sec['title'] in dest_titles:
            content = dest_titles[tpl_sec['title']]['content']
        else:
            content = tpl_sec['content']
        out_parts.append(f"\n---\n\n## {tpl_sec['title']}\n\n{content}\n")
    else:
        # ENRICHMENT (sin marker) — preservar del destination si existe
        if tpl_sec['title'] in dest_titles:
            content = dest_titles[tpl_sec['title']]['content']
        else:
            content = tpl_sec['content']
        out_parts.append(f"\n---\n\n## {tpl_sec['title']}\n\n{content}\n")

# Preservar secciones del destination que NO están en el template (ENRICHMENT additions)
enrichment_sections = [s for s in dest_sections if s['title'] not in tpl_titles]
for sec in enrichment_sections:
    out_parts.append(f"\n---\n\n## {sec['title']}\n\n{sec['content']}\n")

# Construir output final
output = "".join(out_parts).rstrip() + "\n"

# Pieza 3b.2 implementada: Architecture sub-section ya está en el Stack section.
# Si el grafo no está disponible, la sub-sección muestra un placeholder.

# Mensaje sobre engram
if not engram_available:
    output += "<!-- ℹ engram no detectado, sección engram omitida -->\n"

print(output, end='')
PYEOF
RC=$?
if [ $RC -ne 0 ]; then
  if [ $RC -eq 4 ]; then
    err "No se detectó ningún stack. Aborta."
  else
    err "Render Python heredoc falló (rc=$RC)"
  fi
  exit $RC
fi
note "Render OK"

# ──────────────────────────────────────────────────────────────────────
# 6. Confirmation gate + write
# ──────────────────────────────────────────────────────────────────────
DEST_PATH="$REPO_ROOT/$TARGET"

if [ "$DRY_RUN" = "1" ]; then
  note "=== DRY RUN — output completo a continuación ==="
  echo
  cat "$RENDERED_FILE"
  echo
  note "=== FIN DRY RUN — no se escribió nada ==="
  ok "Dry run completado"
  exit 0
fi

if [ "$FORCE" != "1" ]; then
  if [ ! -f "$DEST_PATH" ]; then
    note "Destination nuevo: $TARGET"
    read -r -p "¿Crear? [Y/n] " response
    case "${response:-Y}" in
      [Yy]*) ;;
      *) err "Abortado por el usuario"; exit 5 ;;
    esac
  else
    if diff -q "$DEST_PATH" "$RENDERED_FILE" > /dev/null 2>&1; then
      ok "Sin cambios (idempotencia — el render es idéntico al destination actual)"
      exit 0
    fi
    note "Diff (primeras 50 líneas):"
    diff "$DEST_PATH" "$RENDERED_FILE" | head -50 || true
    echo
    read -r -p "¿Aplicar cambios? [Y/n] " response
    case "${response:-Y}" in
      [Yy]*) ;;
      *) err "Abortado por el usuario"; exit 5 ;;
    esac
  fi
fi

# Write
mkdir -p "$(dirname "$DEST_PATH")"
cp "$RENDERED_FILE" "$DEST_PATH" || {
  err "No se pudo escribir: $DEST_PATH"
  exit 3
}

# Summary
SHA="$(sha256sum "$DEST_PATH" | cut -d' ' -f1)"
ok "Constitución escrita: $TARGET"
note "SHA256: $SHA"
note "NO commiteado (CONST-010). Para commitear:"
note "  git add $TARGET && git commit -m 'docs(constitution): regenerate from template'"

# Mensaje final del script (operacional)
# Pieza 3b.2 implementada: Architecture sub-section ya está en el output.
