---
name: codebase-graph
description: >
  Construye y mantiene un grafo de conocimiento del codebase usando codebase-memory-mcp
  (primario) con Graphify como fallback. Enriquece el Fingerprinting de
  codebase-conformist con: god nodes (módulos críticos por los que pasa todo),
  rationale nodes (conocimiento implícito extraído de comentarios WHY/HACK/IMPORTANT),
  estructura de comunidades (clustering Leiden), conexiones sorprendentes entre módulos,
  blast radius (trace_path), detección de cambios (detect_changes) y ADRs vivos (manage_adr).
  Persiste el grafo cross-sesión y cross-proyecto — resuelve el gap de continuidad.
  Invocado por codebase-conformist antes del Fingerprinting (Paso -0.5).
  Degrada graciosamente si ningún backend está disponible.
compatibility: opencode
metadata:
  version: "2.0"
  requires: "codebase-memory-mcp (MCP, primario) | graphifyy (pip, fallback en .opencode/.mentorkit/venv/)"
---

# Codebase Graph

Convierte el codebase en un grafo de conocimiento persistente y lo hace
disponible para codebase-conformist como contexto enriquecido de Fingerprinting.

**Por qué importa:** el Fingerprinting manual lee archivos linealmente.
El grafo de codebase-memory-mcp proporciona 71.5x menos tokens por consulta, detecta
los módulos críticos automáticamente, y extrae el conocimiento implícito
(comentarios `#WHY`, `#HACK`, `#IMPORTANT`) que de otro modo se pierde.
**Nuevo:** blast radius real vía `trace_path`, detección spec↔code vía `detect_changes`,
ADRs versionados en grafo vía `manage_adr`.

---

## Paso 1 — Verificar disponibilidad de backends (MCP primario, Graphify fallback)

> **Convención:** MCP se invoca via `codebase-memory-mcp cli <tool> '{json}'`.
> Graphify se invoca como módulo Python vía `.opencode/mentorkit-python.sh -m graphify`.

```bash
# 1.1 — Detectar codebase-memory-mcp (PRIMARIO)
if command -v codebase-memory-mcp >/dev/null 2>&1; then
    MCP_AVAILABLE=true
    echo "+ codebase-memory-mcp disponible — BACKEND PRIMARIO"
else
    MCP_AVAILABLE=false
    echo "! codebase-memory-mcp no encontrado en PATH"
fi

# 1.2 — Verificar/instalar Graphify (FALLBACK)
# NOTA: el nombre del paquete PyPI es "graphifyy" (2 y), pero el módulo importable
# es "graphify" (1 y). El -m graphify (sin doble y) es el que ejecuta la CLI.
graphify() {
    .opencode/mentorkit-python.sh -m graphify "$@"
}

if .opencode/mentorkit-python.sh -c "import graphify" 2>/dev/null; then
    GRAPHIFY_AVAILABLE=true
    echo "+ Graphify disponible en el venv — FALLBACK"
else
    echo "! Graphify no instalado en el venv — instalando..."
    if .opencode/mentorkit-python.sh -m pip install graphifyy --quiet; then
        graphify install --platform opencode \
            --output-dir .opencode/skills/graphify 2>/dev/null \
            || echo "! graphify install falló (no crítico, el módulo ya está disponible)"
        GRAPHIFY_AVAILABLE=true
        echo "+ Graphify instalado y configurado — FALLBACK"
    else
        echo "! pip install graphifyy falló"
        GRAPHIFY_AVAILABLE=false
    fi
fi

# 1.3 — Decidir backend activo
if [[ "$MCP_AVAILABLE" == "true" ]]; then
    BACKEND="mcp"
    PROJECT_NAME=$(basename "$PWD")
    echo "✓ Backend activo: MCP (codebase-memory-mcp) — project: $PROJECT_NAME"
elif [[ "$GRAPHIFY_AVAILABLE" == "true" ]]; then
    BACKEND="graphify"
    echo "✓ Backend activo: Graphify (fallback local)"
else
    BACKEND="none"
    echo "! Ningún backend disponible — Fingerprinting manual"
fi
```

Si `BACKEND="none"`, codebase-conformist continúa con Fingerprinting manual — no hay bloqueo del flujo.

---

## Paso 2 — Verificar estado del grafo (según backend)

```bash
case "$BACKEND" in
    mcp)
        # MCP: el grafo vive en el servidor, verificar index_status
        echo "~ Consultando estado del grafo en MCP..."
        INDEX_STATUS_JSON=$(codebase-memory-mcp cli index_status "{\"project\": \"$PROJECT_NAME\"}" 2>/dev/null || echo '{"indexed":false}')
        INDEXED=$(echo "$INDEX_STATUS_JSON" | grep -o '"indexed":true' || echo "")
        if [[ -n "$INDEXED" ]]; then
            GRAPH_STATUS="FRESH"
            echo "+ Grafo indexado en MCP — listo para consultas"
        else
            GRAPH_STATUS="MISSING"
            echo "! Grafo no indexado en MCP — primera construcción"
        fi
        ;;
    graphify)
        # Graphify: verificar archivo local
        GRAPH_JSON="graphify-out/graph.json"
        GRAPH_REPORT="graphify-out/GRAPH_REPORT.md"

        if [[ -f "${GRAPH_JSON}" ]]; then
            if [[ "$(uname)" == "Darwin" ]]; then
                GRAPH_AGE=$(( ( $(date +%s) - $(stat -f %m "${GRAPH_JSON}") ) / 3600 ))
            else
                GRAPH_AGE=$(( ( $(date +%s) - $(stat -c %Y "${GRAPH_JSON}") ) / 3600 ))
            fi
            echo "+ graph.json existe (${GRAPH_AGE}h de antigüedad)"

            if [[ ${GRAPH_AGE} -lt 24 ]]; then
                GRAPH_STATUS="FRESH"
            elif [[ ${GRAPH_AGE} -lt 168 ]]; then
                GRAPH_STATUS="STALE"
            else
                GRAPH_STATUS="OUTDATED"
            fi
        else
            GRAPH_STATUS="MISSING"
            echo "! graph.json no encontrado — primera construcción"
        fi
        echo "Estado: ${GRAPH_STATUS}"
        ;;
    *)
        GRAPH_STATUS="UNAVAILABLE"
        ;;
esac
```

---

## Paso 3 — Construir o actualizar el grafo (según backend)

```bash
case "$BACKEND" in
    mcp)
        case "${GRAPH_STATUS}" in
            FRESH)
                echo "+ Grafo en MCP fresco — reutilizando sin reconstruir"
                ;;
            MISSING|OUTDATED)
                echo "~ Indexando repositorio en MCP..."
                echo "  (primera indexación puede tardar según el tamaño del proyecto)"
                codebase-memory-mcp cli index_repository "{
                    \"repo_path\": \"$PWD\",
                    \"mode\": \"full\",
                    \"persistence\": true
                }" 2>/dev/null \
                    || echo "! Indexación MCP falló — intentando fallback Graphify"
                ;;
        esac
        ;;
    graphify)
        case "${GRAPH_STATUS}" in
            FRESH)
                echo "+ Grafo reciente — reutilizando sin reconstruir"
                ;;
            STALE)
                echo "~ Actualizando archivos modificados..."
                graphify . --update --no-viz --quiet 2>/dev/null \
                    || echo "! Actualización falló — usando grafo existente"
                ;;
            OUTDATED|MISSING)
                echo "~ Construyendo grafo de conocimiento con Graphify..."
                echo "  (primera construcción puede tardar según el tamaño del proyecto)"
                graphify . --no-viz 2>/dev/null \
                    || echo "! Construcción falló — Fingerprinting manual"
                ;;
        esac
        ;;
    *)
        echo "! Backend no disponible — saltando construcción de grafo"
        ;;
esac
```

---

## Paso 4 — Extraer Graph Context (MCP tools preferidos, Graphify fallback)

### 4.1 — Backend MCP: usar tools nativos del MCP

```bash
if [[ "$BACKEND" == "mcp" ]]; then
    echo "="
    echo "GRAPH CONTEXT — MentorKit Fingerprinting (via codebase-memory-mcp)"
    echo "="

    # Project name para queries
    PROJECT_NAME=$(basename "$PWD")

    # 4.1.1 — God Nodes via query_graph (Cypher)
    echo ""
    echo "### GOD NODES (zonas críticas del codebase)"
    codebase-memory-mcp cli query_graph "{
        \"project\": \"$PROJECT_NAME\",
        \"query\": \"MATCH (n) WHERE n.degree > 10 RETURN n.label, n.degree ORDER BY n.degree DESC LIMIT 10\"
    }" 2>/dev/null | head -30

    # 4.1.2 — Rationale Nodes (conocimiento implícito) via search_graph
    echo ""
    echo "### CONOCIMIENTO IMPLÍCITO (rationale nodes)"
    codebase-memory-mcp cli search_graph "{
        \"project\": \"$PROJECT_NAME\",
        \"semantic_query\": [\"why\", \"hack\", \"important\", \"note\", \"rationale\"],
        \"limit\": 15
    }" 2>/dev/null | head -40

    # 4.1.3 — Arquitectura general via get_architecture
    echo ""
    echo "### ARQUITECTURA (comunidades Leiden + visión general)"
    codebase-memory-mcp cli get_architecture "{
        \"project\": \"$PROJECT_NAME\",
        \"aspects\": [\"clusters\", \"packages\", \"dependencies\"]
    }" 2>/dev/null | head -60

    # 4.1.4 — Conexiones sorprendentes via query_graph
    echo ""
    echo "### CONEXIONES SORPRENDENTES (acoplamiento oculto)"
    codebase-memory-mcp cli query_graph "{
        \"project\": \"$PROJECT_NAME\",
        \"query\": \"MATCH (a)-[r:INFERRED]->(b) WHERE r.confidence_score > 0.75 RETURN a.label, type(r), b.label, r.confidence_score ORDER BY r.confidence_score DESC LIMIT 5\"
    }" 2>/dev/null | head -20

    echo ""
    echo "="

    # 4.1.5 — NUEVO: Blast radius tool disponible para codebase-conformist
    echo ""
    echo "### HERRAMIENTAS DISPONIBLES BAJO DEMANDA"
    echo "  trace_path        → blast radius desde archivo/símbolo (para Impact Gate)"
    echo "  detect_changes    → spec↔code traceability (para archive-spec)"
    echo "  manage_adr        → ADRs versionados en grafo (para Constitution)"

fi
```

### 4.2 — Backend Graphify: parser Python existente (fallback)

```bash
if [[ "$BACKEND" == "graphify" ]]; then
    GRAPH_JSON="graphify-out/graph.json"
    GRAPH_REPORT="graphify-out/GRAPH_REPORT.md"

    if [[ -f "${GRAPH_JSON}" ]]; then
        python3 << 'PYEOF'
import json, sys
from pathlib import Path
from collections import defaultdict, Counter

graph_path = Path("graphify-out/graph.json")
if not graph_path.exists():
    print("GRAPH_CONTEXT_UNAVAILABLE")
    sys.exit(0)

with open(graph_path) as f:
    data = json.load(f)

nodes = {n['id']: n for n in data.get('nodes', [])}
links = data.get('links', data.get('edges', []))

# God Nodes
degree = Counter()
for link in links:
    degree[link.get('source', '')] += 1
    degree[link.get('target', '')] += 1

god_nodes = [
    (nodes.get(nid, {}).get('label', nid), cnt)
    for nid, cnt in degree.most_common(10)
    if nid
]

# Rationale Nodes
rationale_nodes = [
    n for n in nodes.values()
    if n.get('type', '') == 'rationale_for'
    or any(kw in str(n.get('label', '')).lower()
           for kw in ['rationale', 'why', 'hack', 'important', 'note'])
][:15]

# Comunidades Leiden
communities = defaultdict(list)
for nid, node in nodes.items():
    comm = node.get('community', node.get('cluster', 'general'))
    label = node.get('label', nid)
    if label:
        communities[str(comm)].append(label)

top_communities = sorted(
    communities.items(), key=lambda x: len(x[1]), reverse=True
)[:5]

# Conexiones sorprendentes
surprising = [
    {
        'source': nodes.get(l.get('source', ''), {}).get('label', l.get('source', '')),
        'target': nodes.get(l.get('target', ''), {}).get('label', l.get('target', '')),
        'relation': l.get('relation', ''),
        'confidence': l.get('confidence_score', 0),
    }
    for l in links
    if l.get('status') == 'INFERRED' and l.get('confidence_score', 0) > 0.75
][:5]

# Output
print("=" * 60)
print("GRAPH CONTEXT — MentorKit Fingerprinting (via Graphify)")
print("=" * 60)
print(f"\nTotal: {len(nodes)} nodos, {len(links)} aristas")
print(f"Estado: {data.get('metadata', {}).get('created', 'desconocido')}")

print(f"\n### GOD NODES (zonas críticas del codebase)")
for label, deg in god_nodes:
    print(f"  [{deg:3d} conexiones]  {label}")

print(f"\n### CONOCIMIENTO IMPLÍCITO (rationale nodes)")
for n in rationale_nodes:
    label = n.get('label', '')
    source = n.get('source_file', n.get('file', ''))
    print(f"  {label[:80]}")
    if source:
        print(f"    -> {source}")

print(f"\n### COMUNIDADES (módulos naturales)")
for comm_id, members in top_communities:
    print(f"  Comunidad {comm_id} ({len(members)} nodos): "
          f"{', '.join(members[:5])}{'...' if len(members) > 5 else ''}")

print(f"\n### CONEXIONES SORPRENDENTES (acoplamiento oculto)")
for s in surprising:
    print(f"  {s['source']} --[{s['relation']}]--> {s['target']}"
          f"  (confianza: {s['confidence']:.2f})")

print("\n" + "=" * 60)
PYEOF
    else
        echo "! graph.json no encontrado — Graph Context no disponible"
    fi
fi
```

---

## Paso 5 — Leer GRAPH_REPORT.md (solo backend Graphify)

```bash
if [[ "$BACKEND" == "graphify" && -f "graphify-out/GRAPH_REPORT.md" ]]; then
    echo ""
    echo "### GRAPH REPORT (Graphify)"
    awk '/^## God Nodes/,/^## / { print }
         /^## Surprising/,/^## / { print }
         /^## Suggested Questions/,/^## / { print }' \
        graphify-out/GRAPH_REPORT.md | head -60
fi
```

---

## Retorno a codebase-conformist

El Graph Context devuelto contiene (MCP o Graphify):

```
GRAPH CONTEXT:
  God Nodes       → [lista] módulos con más conexiones = zonas sensibles
  Rationale Nodes → [lista] decisiones de diseño implícitas extraídas del código
  Comunidades     → [lista] agrupaciones naturales de módulos (Leiden)
  Sorprendentes   → [lista] acoplamientos ocultos a vigilar en el plan
  Arquitectura    → [resumen] packages, dependencies, clusters
  Token savings   → ~71.5x menos tokens vs lectura manual de archivos
```

**NUEVAS HERRAMIENTAS BAJO DEMANDA (via MCP):**

```
  trace_path(project, function_name, mode, depth)
        → blast radius real para Impact Gate (Paso 2.5)
        → modes: calls | data_flow | cross_service

  detect_changes(project, base_branch, scope, depth)
        → spec↔code traceability para archive-spec / verify
        → detecta specs huérfanas, código sin spec, drift

  manage_adr(project, mode, content, sections)
        → ADRs versionados en grafo (no solo markdown)
        → modes: get | update | sections
```

**codebase-conformist usa este contexto para:**
- Fingerprinting 1.1: priorizar lectura de god nodes en lugar de leer todo
- Fingerprinting 1.2: los god nodes = análisis de impacto en callers ya resuelto
- Phase -1 Gates: zonas sensibles ya identificadas automáticamente
- **NUEVO** Impact Gate: `trace_path` → blast radius real, no estimado
- **NUEVO** Archive/Verify: `detect_changes` → spec↔code drift detection
- **NUEVO** Constitution: `manage_adr` → ADRs vivos en grafo
- Plan: acoplamientos ocultos informan el blast radius

---

## Comportamiento cuando ningún backend está disponible

```bash
! Graph Context no disponible
  Razón: [MCP no en PATH | Graphify no instalado | construcción falló | permisos]
  Acción: codebase-conformist procede con Fingerprinting manual completo
  Recomendación:
    - make install    (instala graphifyy desde requirements.lock)
    - codebase-memory-mcp install  (instala MCP si no está)
```

**El flujo de MentorKit nunca se bloquea por backends de grafo.**
Son mejoras opcionales, no requisitos.