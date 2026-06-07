---
name: codebase-graph
description: >
  Construye y mantiene un grafo de conocimiento del codebase usando Graphify.
  Enriquece el Fingerprinting de codebase-conformist con: god nodes (módulos
  críticos por los que pasa todo), rationale nodes (conocimiento implícito
  extraído de comentarios WHY/HACK/IMPORTANT), estructura de comunidades
  (clustering Leiden), y conexiones sorprendentes entre módulos. Persiste
  el grafo en graphify-out/graph.json entre sesiones — resuelve el gap de
  continuidad. Invocado por codebase-conformist antes del Fingerprinting.
  Degrada graciosamente si Graphify no está instalado.
compatibility: opencode
metadata:
  version: "1.0"
  requires: "graphifyy (pip, instalado en .opencode/.mentorkit/venv/)"
---

# Codebase Graph

Convierte el codebase en un grafo de conocimiento persistente y lo hace
disponible para codebase-conformist como contexto enriquecido de Fingerprinting.

**Por qué importa:** el Fingerprinting manual lee archivos linealmente.
El grafo de Graphify proporciona 71.5x menos tokens por consulta, detecta
los módulos críticos automáticamente, y extrae el conocimiento implícito
(comentarios `#WHY`, `#HACK`, `#IMPORTANT`) que de otro modo se pierde.

---

## Paso 1 — Verificar disponibilidad de Graphify

> **Convención:** todas las invocaciones Python pasan por `.opencode/mentorkit-python.sh`
> (ver `.opencode/skills/document-extractor/SKILL.md` para detalles del wrapper).
> `graphify` se invoca como módulo Python vía `-m graphify` para garantizar que
> use el venv de MentorKit.

```bash
# Función helper: invoca graphify via wrapper, siempre en el venv
graphify() {
    .opencode/mentorkit-python.sh -m graphify "$@"
}

# Verificar/instalar graphifyy en el venv
# NOTA: el nombre del paquete PyPI es "graphifyy" (2 y), pero el módulo importable
# es "graphify" (1 y). El -m graphify (sin doble y) es el que ejecuta la CLI.
if .opencode/mentorkit-python.sh -c "import graphify" 2>/dev/null; then
    echo "+ Graphify disponible en el venv"
else
    echo "! Graphify no instalado en el venv — instalando..."
    if .opencode/mentorkit-python.sh -m pip install graphifyy --quiet; then
        graphify install --platform opencode \
            --output-dir .opencode/skills/graphify 2>/dev/null \
            || echo "! graphify install falló (no crítico, el módulo ya está disponible)"
        echo "+ Graphify instalado y configurado"
    else
        echo "! pip install graphifyy falló"
        echo "  El Fingerprinting usará lectura manual de archivos"
        GRAPHIFY_UNAVAILABLE=true
    fi
fi
```

Si `GRAPHIFY_UNAVAILABLE=true`, codebase-conformist continúa con
Fingerprinting manual — no hay bloqueo del flujo.

---

## Paso 2 — Verificar estado del grafo

```bash
GRAPH_JSON="graphify-out/graph.json"
GRAPH_REPORT="graphify-out/GRAPH_REPORT.md"

if [[ -f "${GRAPH_JSON}" ]]; then
    # Calcular antigüedad en horas
    if [[ "$(uname)" == "Darwin" ]]; then
        GRAPH_AGE=$(( ( $(date +%s) - $(stat -f %m "${GRAPH_JSON}") ) / 3600 ))
    else
        GRAPH_AGE=$(( ( $(date +%s) - $(stat -c %Y "${GRAPH_JSON}") ) / 3600 ))
    fi
    echo "+ graph.json existe (${GRAPH_AGE}h de antigüedad)"

    if [[ ${GRAPH_AGE} -lt 24 ]]; then
        GRAPH_STATUS="FRESH"      # < 24h: usar directamente
    elif [[ ${GRAPH_AGE} -lt 168 ]]; then
        GRAPH_STATUS="STALE"      # 1-7 días: actualizar archivos modificados
    else
        GRAPH_STATUS="OUTDATED"   # > 7 días: reconstruir
    fi
else
    GRAPH_STATUS="MISSING"
    echo "! graph.json no encontrado — primera construcción"
fi

echo "Estado: ${GRAPH_STATUS}"
```

---

## Paso 3 — Construir o actualizar el grafo

```bash
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
        echo "~ Construyendo grafo de conocimiento..."
        echo "  (primera construcción puede tardar según el tamaño del proyecto)"
        graphify . --no-viz 2>/dev/null \
            || echo "! Construcción falló — Fingerprinting manual"
        ;;
esac
```

---

## Paso 4 — Extraer Graph Context

Con `Bash`, ejecutar el parser Python sobre `graph.json`:

```python
import json, sys
from pathlib import Path
from collections import defaultdict, Counter

graph_path = Path("graphify-out/graph.json")
report_path = Path("graphify-out/GRAPH_REPORT.md")

if not graph_path.exists():
    print("GRAPH_CONTEXT_UNAVAILABLE")
    sys.exit(0)

with open(graph_path) as f:
    data = json.load(f)

nodes = {n['id']: n for n in data.get('nodes', [])}
links = data.get('links', data.get('edges', []))

# ── God Nodes (módulos críticos por grado) ────────────────────────────────
degree = Counter()
for link in links:
    degree[link.get('source', '')] += 1
    degree[link.get('target', '')] += 1

god_nodes = [
    (nodes.get(nid, {}).get('label', nid), cnt)
    for nid, cnt in degree.most_common(10)
    if nid
]

# ── Rationale Nodes (conocimiento implícito) ──────────────────────────────
rationale_nodes = [
    n for n in nodes.values()
    if n.get('type', '') == 'rationale_for'
    or any(kw in str(n.get('label', '')).lower()
           for kw in ['rationale', 'why', 'hack', 'important', 'note'])
][:15]

# ── Comunidades Leiden (módulos naturales) ────────────────────────────────
communities = defaultdict(list)
for nid, node in nodes.items():
    comm = node.get('community', node.get('cluster', 'general'))
    label = node.get('label', nid)
    if label:
        communities[str(comm)].append(label)

# Top comunidades por tamaño
top_communities = sorted(
    communities.items(), key=lambda x: len(x[1]), reverse=True
)[:5]

# ── Conexiones sorprendentes ──────────────────────────────────────────────
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

# ── Output estructurado ───────────────────────────────────────────────────
print("=" * 60)
print("GRAPH CONTEXT — MentorKit Fingerprinting")
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
```

---

## Paso 5 — Leer GRAPH_REPORT.md

```bash
if [[ -f "graphify-out/GRAPH_REPORT.md" ]]; then
    echo ""
    echo "### GRAPH REPORT (Graphify)"
    # Extraer solo las secciones relevantes para codebase-conformist
    awk '/^## God Nodes/,/^## / { print }
         /^## Surprising/,/^## / { print }
         /^## Suggested Questions/,/^## / { print }' \
        graphify-out/GRAPH_REPORT.md | head -60
fi
```

---

## Retorno a codebase-conformist

El Graph Context devuelto contiene:

```
GRAPH CONTEXT:
  God Nodes      → [lista] módulos con más conexiones = zonas sensibles
  Rationale Nodes → [lista] decisiones de diseño implícitas extraídas del código
  Comunidades    → [lista] agrupaciones naturales de módulos (Leiden)
  Sorprendentes  → [lista] acoplamientos ocultos a vigilar en el plan
  Token savings  → ~71.5x menos tokens vs lectura manual de archivos
```

**codebase-conformist usa este contexto para:**
- Fingerprinting 1.1: priorizar lectura de god nodes en lugar de leer todo
- Fingerprinting 1.2: los god nodes = análisis de impacto en callers ya resuelto
- Phase -1 Gates: zonas sensibles ya identificadas automáticamente
- Plan: acoplamientos ocultos informan el blast radius

---

## Comportamiento cuando Graphify no está disponible

Si Graphify no puede construir el grafo por cualquier razón:

```
! Graph Context no disponible
  Razón: [Graphify no instalado | construcción falló | permisos]
  Acción: codebase-conformist procede con Fingerprinting manual completo
  Recomendación: make install    (instala graphifyy desde requirements.lock)
```

**El flujo de MentorKit nunca se bloquea por Graphify.**
Es una mejora opcional, no un requisito.
