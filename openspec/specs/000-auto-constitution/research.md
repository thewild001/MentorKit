# Auto-generate constitution from skill outputs

> Status: Proposed (v3)
> Fecha: 2026-06-06
> Dominio: mentorkit-meta

## Intent

La sección "Stack tecnológico" del `openspec/memory/constitution.md`
es **per-project**: se regenera vacía desde el template al clonar
mentorkit, y se llena con los datos del **proyecto destino** al
correr `make init-constitution`. mentorkit NUNCA impone su propio
stack a proyectos downstream.

Este spec describe el **mecanismo** de auto-generación, NO un
snapshot de un stack específico. El spec es project-agnostic:
define CÓMO se detecta y escribe el stack de CUALQUIER proyecto
que adopte mentorkit.

### Por qué existe

Hoy mentorkit tiene un gap: la sección "Lenguaje y dependencias"
del constitution.md tiene 3 líneas y los proyectos que adopten
mentorkit deben llenarla manualmente, con drift inevitable entre
la constitución y la realidad del proyecto.

Cerrar este gap elimina:

- Drift entre constitución y realidad
- Onboarding friction (dev nuevo lee constitución y entiende el stack)
- Olvido de deps críticas al hacer cambios cross-stack

## Multi-stack by design

mentorkit está diseñado para servir proyectos con **cualquier stack
tecnológico** (Python, Go, Node.js, Rust, Java, C#, Elixir, etc.).
La herramienta misma es Python 3.12.13 + bash + uv, pero **lo que
hace** es independiente del stack del proyecto destino.

Esto significa:

- **Distribución**: el tarball es el mismo para todos los proyectos
- **Fingerprint**: detecta cualquier stack por señales de archivos
  (lock files, manifests, CI configs), no por asunción
- **Template**: solo tiene placeholders, no contiene snippets de
  Python que filtrarían a otros stacks
- **Tests**: cubrimos al menos Python, Go, Node.js y Rust para
  validar que ningún artefacto de mentorkit se cuele en
  constituciones de otros stacks
- **Documentación**: ejemplos y tutoriales deben mostrar al menos
  un caso no-Python para evitar暗示 (sugerir) que mentorkit es
  Python-only

## Architecture recap (C + D)

Decisión arquitectónica previa (ver observación engram
`architecture/repo-as-truth-engram-as-turbo-c-d`):

- **Repo = verdad canónica**: constitution, specs, design, git log
  viven en el repo. Cualquier dev puede leerlos sin engram.
- **engram = turbo opcional**: session summaries, bugfixes
  recurrentes, preferencias dev, aprendizaje operacional.
- **Agente CON o SIN engram**: graceful degradation. Si engram
  no está, la constitución sigue funcionando.
- **engram se seedea desde el repo**: bootstrap.sh opcionalmente
  instala engram y lo siembra con topics derivados (Pieza 3,
  fuera de scope de este spec).

## Approach

0. **Template con placeholder**: `constitution.template.md` tiene
   una sección "Stack tecnológico" con sub-secciones vacías y un
   comentario `<!-- auto-derivado -->` indicando que la
   herramienta la llena en runtime.

1. **codebase-graph → graph.json**: corre en el proyecto destino
   y produce `graphify-out/graph.json` con god nodes, rationale,
   comunidades.

2. **codebase-conformist --fingerprint**: corre en el proyecto
   destino y detecta:

   - Lenguajes (con versiones)
   - Runtimes (Python 3.12, Go 1.22, Node 20, etc.)
   - Package manager (uv, poetry, npm, cargo)
   - Dependencias críticas (top-N por rol: framework, ORM,
     test runner, linter)
   - VCS + branching model
   - CI platform (GitHub Actions, GitLab CI, CircleCI)
   - Plataformas target (Linux, macOS, Windows, browser, mobile)

3. **Render del template**: `make init-constitution` toma
   template + fingerprint + grafo y produce el `constitution.md`
   del proyecto destino. Solo llena secciones DERIVADAS; las
   CONSTITUCIONALES se copian del template sin cambios.

4. **Dry-run con diff antes de commit** (Confirmation gate):
   si la constitución destino ya existe, mostrar diff antes
   de commitear. El humano aprueba o aborta.

5. **Seed de engram (opcional)**: si engram está disponible,
   sembrar con topics estables derivados del fingerprint.

## Lifecycle de la constitución del proyecto

1. **INIT** (one-time): `make init-constitution` corre las skills
   sobre el proyecto destino, genera `constitution.md` con
   Capa 1 copiada + Capa 2 auto-detectada + Capa 3 vacía.

2. **ENRICH** (continuous): humanos editan `constitution.md`
   agregando Capa 3 (contexto que tools no detectan):

   - Convenciones de estilo no obvias
   - Restricciones organizacionales ("este equipo solo mergea
     los martes")
   - Decisiones arquitectónicas con rationale
   - Módulos con historia ("este archivo es legacy, no tocar")
   - Performance/SLA budgets
   - Compliance / regulatory constraints
   - Onboarding notes

3. **COMMIT**: `constitution.md` se commitea y pushea a git
   del proyecto. Tracked, versionado, NO efímero.

4. **CONSUME** (every agent op): el agente LEE `constitution.md`
   del proyecto como su referencia primaria. El fingerprint NO
   se vuelve a correr en cada operación — la constitución YA
   contiene la info de Capa 2.

5. **DRIFT-CHECK** (opcional, en CI o `make verify`): comparar
   constitución actual vs. código actual. Si hay drift, avisar
   al humano. No bloquear, no auto-arreglar.

## Drift detection (no conflict resolution)

La constitución del proyecto es la referencia. El código es la
realidad. Si divergen, el agente **avisa** (no resuelve).

| Caso | Comportamiento del agente |
|------|--------------------------|
| Constitución dice "Python 3.12", pyproject dice "3.11" | Avisar: "Drift detectado. ¿Actualizo constitución a 3.11, o arreglo pyproject a 3.12?" |
| Constitución lista módulo X como "god", fingerprint actual no lo detecta | Mantener constitución (humano decidió, fingerprint puede ser incompleto) |
| pyproject tiene nueva dep no en constitución | Sugerir agregar a constitución (Capa 3 enrichment) |
| Constitución menciona convención que código viola | Advertir (no bloquear): "El código no sigue la convención X de tu constitución" |

Drift ≠ Conflicto. Drift = humano no actualizó. El agente sugiere,
nunca impone.

## Distribution model (A + B + D)

mentorkit se distribuye como tarball vía `bash <(curl ...)`.
Tres piezas para que los updates lleguen a proyectos downstream
de forma transparente:

- **A. Version manifest**: cuando `bootstrap.sh` instala mentorkit,
  deja un archivo `.opencode/MENTORKIT_VERSION` con la versión
  instalada.

- **B. Smart-update en bootstrap**: si `.opencode/` ya existe,
  bootstrap.sh NO falla. Pregunta: "¿Actualizar de v3 a v5?
  Preservaré tu constitution.md y customs. [Y/n]". Si Y, hace
  smart-merge (preserva customizations del proyecto, sobreescribe
  solo `.opencode/skills/`, `install-mentorkit.sh`,
  `requirements.lock`).

- **D. CI gate**: nuevo job `verify-mentorkit-version` corre en
  cada push. Si `MENTORKIT_VERSION` local < latest, el MR falla
  con: "MentorKit v3 instalado, v5 disponible. Corre
  `bash <(curl ...)` para actualizar."

Resultado: dev normalmente no piensa en updates. Si el proyecto
queda outdated, CI lo avisa al hacer push. Re-correr el one-liner
es el mismo comando que ya conoce, ahora smart-update.

## Scope

### In-scope (DERIVADO, auto, per-project)

- **Stack tecnológico**: lenguajes, runtimes, pkg mgr, deps,
  VCS, CI, plataformas
- **Architecture (high-level)**: comunidades del grafo +
  god nodes (solo los módulos críticos)
- **Scripts principales**: auto-detect con `find` (top-N
  scripts top-level ejecutables)

### Out-of-scope (CONSTITUCIONAL, manual, idéntico para todos)

- Garantías verificadas en CI (1-7)
- Confirmation gate (regla de proceso)
- Conventional Commits (taxonomía cerrada)
- Flujo de specs (delta-based merge)

### Out-of-scope (IDENTIDAD, manual, per-project, NO auto)

- Nombre del proyecto
- Descripción
- Owners / maintainers
- Licencia
- URLs de docs

> El dev llena estas secciones manualmente. Auto-detectarlas
> introduce ambigüedad (¿de `pyproject.toml`? ¿de `README.md`?
> ¿de git remote?) y no vale el tradeoff.

## Risks + Mitigations

### Risk 1: Pérdida de información constitucional durante render

Si el render reescribe la constitución entera, se pierden
las garantías manuales.

**Mitigation**: el render usa 2 archivos distintos:

- `constitution.template.md` (en mentorkit, versionado)
- `constitution.md` (en proyecto destino, renderizado)

Solo sobreescribe secciones marcadas con `<!-- auto-derivado -->`. Las demás se copian del template tal cual.

### Risk 2: Errores de fingerprint (falsos positivos)

Si el fingerprint detecta mal el stack, la constitución queda mal.

**Mitigation**:

- Fingerprint defensivo: prefiere lock files sobre archivos
  declarativos
- Dev puede sobreescribir manualmente cualquier campo
  (sección no-readonly)
- Test ground truth: detección correcta en mentorkit mismo

### Risk 3: Grafo pesado para proyectos grandes

codebase-graph puede ser lento en proyectos con 10K+ archivos.

**Mitigation**:

- Grafo opcional, no requerido para el render
- Si no está disponible, renderiza sin sección "Architecture"
  (graceful degradation)
- Timeout configurable

### Risk 4: Calidad de rationale nodes

Rationale nodes vienen de comentarios WHY/HACK/IMPORTANT.
Si el código no los tiene, el grafo pierde valor.

**Mitigation**:

- Sección "Architecture" del render es **opcional**
- Documentar que comentarios WHY mejoran el render
- Dev puede editar manualmente

### Risk 5: Garantías cross-project inconsistentes

Si dos proyectos derivados tienen garantías diferentes, algo anda mal.

**Mitigation**:

- Garantías viven en `constitution.template.md` (versionado
  en mentorkit)
- Render detecta drift en garantías y avisa: "Las garantías
  de tu constitución difieren del template. ¿Actualizar? [Y/n]"

### Risk 6: Drift constitución vs. código (NUEVO)

Los humanos enriquecen la constitución una vez, pero el código
cambia. Sin nudges, la constitución queda desactualizada.

**Mitigation**:

- En cada `make verify` o `make ci`, si hay drift detectable
  (ej: nueva dep en pyproject no listada en constitución), avisar
- Nudge: "Tu constitución no menciona la nueva dep X. ¿Actualizar? [Y/n]"
- **No bloquear, no auto-arreglar** (humano decide)

### Risk 7: Constitución como "dumping ground" (NUEVO)

Si la constitución se vuelve un cajón de sastre, pierde foco.

**Mitigation**:

- Documentar estructura recomendada (CONSTITUCIONAL, DERIVADO,
  IDENTIDAD, ENRICHMENT)
- Tener un linter de constitución (futuro, fuera de scope)
- Diff en cada commit: si la constitución crece más de N líneas,
  alertar

## Acceptance criteria

1. `make init-constitution` corre sin error en mentorkit mismo
   y produce `constitution.md` con Stack correcto (validar contra
   `uv.lock` y `.gitlab-ci.yml` reales).

2. `make init-constitution` corre sin error en proyectos
   hipotéticos de **4 stacks**:

   - **Python** (mentorkit mismo, ground truth)
   - **Go** (`go.mod` + `main.go` + GitHub Actions)
   - **Node.js** (`package.json` + npm + GitHub Actions)
   - **Rust** (`Cargo.toml` + GitHub Actions)

   Cada uno produce constitución con Stack correcto de su stack.

3. **Test crítico de aislamiento (multi-stack)**: el Stack de
   mentorkit (Python 3.12.13, uv, GitLab CI) NUNCA aparece en
   constituciones de proyectos Go, Node.js, o Rust. Verificar
   con `grep` en cada uno → 0 matches.

4. Secciones CONSTITUCIONALES quedan IDÉNTICAS al template base
   después del render (diff de 0 líneas).

5. Secciones IDENTIDAD quedan VACÍAS con comentario
   `<!-- llenar manualmente -->`.

6. Fingerprint detecta Python 3.12.13 desde `requires-python`
   en `pyproject.toml`.

7. Fingerprint detecta uv desde `uv.lock` o `[tool.uv]`.

8. Si engram está, se seedea con al menos 2 topics estables
   (`architecture/<project>-stack` y `discovery/<project>-god-modules`).

9. Si engram NO está, el comando no falla (graceful degradation)
   y muestra: "engram no detectado, sección engram omitida".

10. Idempotencia: correr 2 veces seguidas produce el mismo output
    (mismo hash del `constitution.md` renderizado).

11. Dry-run con diff antes de commit (Confirmation gate): si la
    constitución destino es nueva, pregunta "¿Crear? [Y/n]". Si
    existe y hay diff, muestra diff y pregunta "¿Aplicar? [Y/n]".

12. La herramienta NO auto-commitea. El humano corre `git add` y
    `git commit` manualmente.

13. `constitution.md` queda TRACKEADO en git del proyecto destino
    (no en `.gitignore`, no en `archive/`, no efímero).

14. En CADA operación del agente en un proyecto con
    `constitution.md`, codebase-conformist LO LEE PRIMERO
    antes de hacer fingerprinting en vivo.

15. Drift detection (no conflict resolution): cuando constitución
    y código en vivo difieren, el agente muestra el diff y
    pregunta al humano. No impone.

16. La constitución tiene prioridad sobre el fingerprint en caso
    de drift. El agente sugiere actualizar la constitución si
    detecta drift, pero NO lo hace solo.

17. La constitución soporta ENRICH sin re-correr
    `make init-constitution`. Es decir, los humanos pueden
    agregar secciones libres (Markdown) que las herramientas
    no tocan.

18. **Distribution (A)**: `bootstrap.sh` deja
    `.opencode/MENTORKIT_VERSION` con la versión instalada.

19. **Distribution (B)**: si `.opencode/` ya existe, `bootstrap.sh`
    NO falla. Pregunta: "¿Actualizar de v3 a v5? Preservaré tu
    constitution.md. [Y/n]". Si Y, hace smart-merge (preserva
    customizations).

20. **Distribution (D)**: el CI job `verify-mentorkit-version`
    corre en cada push. Si `MENTORKIT_VERSION` local < latest,
    el MR falla con instrucción clara.

## Out of scope (general)

- Auto-merge a PRs (siempre confirmación humana)
- Per-dev preferences (eso va a engram, no a la constitución)
- Detección de "este dev prefiere X" (sesgo por dev)
- Linting de la constitución (otra herramienta, otro spec)
- Internacionalización del template
- Versionado de constituciones
- Monorepos con 1 constitución por paquete
- Auto-render en push (CI) — solo on-demand por ahora

## Dependencies

- **codebase-graph** skill: en mentorkit
  (verificar `.opencode/skills/codebase-graph/`)
- **codebase-conformist** skill: en mentorkit (ya existe)
- **Templating**: string.Template o str.replace en Python
  (YAGNI: no Jinja2 hasta que haga falta)
- **git**: para diff y commit final (humano)
- **engram** (opcional): para seed post-render
- **GitLab API**: para distribution D (chequear latest version)

## Open questions

- ¿Monorepos con 1 constitución por paquete? Spec actual
  asume 1 constitución por repo. Decidir en Pieza futura.
- ¿Re-render automático en push (CI)? Spec asume on-demand.
  Auto-on-push sería CI.
- ¿Linter de constitución (validar estructura de las 3
  capas + ENRICHMENT)? Out of scope ahora, futuro.
- ¿Soporte para fingerprint de stacks exóticos (Nix, Crystal,
  Zig)? Cobertura por ahora: Python, Go, Node, Rust.
  Extensible via plugins de fingerprint.

## Acceptance meta-criteria

Este spec se considera exitoso cuando:

- mentorkit mismo corre `make init-constitution` y produce
  constitución correcta (Python ground truth)
- **3 proyectos downstream hipotéticos** corren `make init-constitution`:

  - 1 Go (`go.mod`, GitHub Actions)
  - 1 Node.js (`package.json`, npm, GitHub Actions)
  - 1 Rust (`Cargo.toml`, GitHub Actions)

  Cada uno produce constitución con:

  - Stack correcto del proyecto destino (no de mentorkit)
  - Garantías idénticas (CONSTITUCIONAL, no se filtra stack)
  - IDENTIDAD vacía para llenar

- El test de aislamiento multi-stack (AC #3) pasa en los 3
- La idempotencia (AC #10) pasa en los 3
- Drift detection (AC #15) funciona con un proyecto de prueba
  al que se le cambia el stack manualmente
- Distribution A+B+D (AC #18-20) funciona en un test repo:
  - Install deja MENTORKIT_VERSION
  - Re-correr bootstrap actualiza (no falla)
  - Bajar versión local → CI falla con instrucción clara
