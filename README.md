# mentorkit

> Orquestador de workflow para juniors. Constitution → Spec → Fingerprinting → Plan → Confirm → Implement → PR.

**Plataforma:** Linux · macOS · Windows (vía WSL2) · **Python:** 3.12.13 (pin exacto) · **Deps:** 60 con lock con SHA256

---

## 🚀 Instalación rápida (en tu proyecto)

Si quieres usar mentorkit en **tu propio proyecto**, sin clonar este repo:

```bash
# Desde la raíz de tu proyecto (cualquier directorio, no necesita ser un repo git)
bash <(curl -fsSLk -H "PRIVATE-TOKEN: ${MENTORKIT_TOKEN:-glpat-RhMcJxUMWSx5N0tkYKStlm86MQp1OjI2bAk.01.0z1ay31li}" \
    "https://gitlab.prod.uci.cu/api/v4/projects/fortes%2Fmentorkit/repository/files/bootstrap.sh/raw?ref=main")
```

> El endpoint `/-/raw/` no funciona con `PRIVATE-TOKEN` en este GitLab (devuelve
> el sign-in). El endpoint `/api/v4/.../repository/files/.../raw` SÍ funciona.
> El token embebido tiene scope `read_api` (solo lectura). Si tienes tu propio
> token, exportalo primero: `export MENTORKIT_TOKEN=glpat-xxxxx`.

**Eso es todo.** El one-liner:

1. Descarga mentorkit (tarball, ~73KB)
2. Crea `.opencode/` en tu proyecto con skills, installer, verify, lock file
3. Crea el venv con Python 3.12.13 (usa `uv` que trae el installer; no usa el Python del sistema)
4. Instala 60 paquetes desde el lock con verificación SHA256
5. Corre `verify` y confirma que todo está OK

Tiempo: ~30s la primera vez, ~1s en re-runs.

Al terminar verás:

```
  MentorKit  v4.0 — Instalador one-liner

  1/4  Descargando mentorkit (tarball)...
  2/4  Extrayendo...
  3/4  Instalando en /home/.../tu-proyecto...
  4/4  Configurando entorno Python (esto puede tardar 30s la primera vez)...
  ...
  ✓  MentorKit instalado en /home/.../tu-proyecto
```

**No necesitas correr `make install` después** — el bootstrap ya instaló todo. El `Makefile` queda disponible para `make verify` si quieres validar localmente, pero es opcional.

Ver [`bootstrap.sh`](./bootstrap.sh) y [.opencode/README.md](./.opencode/README.md) para detalles completos.

### 🪟 ¿Estás en Windows?

MentorKit está escrito en bash. El instalador, el Makefile y el CI asumen un
entorno POSIX. En Windows nativo (PowerShell, CMD) **no funciona todavía** —
el lock file tiene los wheels correctos (colorama, pyreadline3, onnxruntime 1.20.1
para `sys_platform == 'win32'`), pero el journey end-to-end no está validado fuera
de Linux.

**Camino recomendado: WSL2.** Habilitá WSL2 y Ubuntu desde PowerShell (admin):

```powershell
wsl --install
```

Reinicia, abre "Ubuntu" desde el menú inicio, y a partir de ahí todo es bash nativo.
El one-liner de arriba funciona **tal cual** dentro de Ubuntu en WSL2 — no hay
cambios. Tiempo total del setup WSL2 + MentorKit: ~5 minutos.

> ¿Por qué no PowerShell nativo? Reescribir `bootstrap.sh`, `install-mentorkit.sh`
> y `Makefile` a PowerShell es ~3x trabajo y mantiene dos codebases. WSL2 te da
> el mismo DX que un dev de Linux/macOS a costo cero de
> mantenimiento. Si necesitas soporte nativo de Windows, abre un issue — es
> decisión de roadmap, no de un fix rápido.

---

## 🛠 Para desarrollar mentorkit mismo

Si vas a **modificar mentorkit** (cambiar skills, installer, CI), clona el repo:

```bash
git clone gitlab.prod.uci.cu:fortes/mentorkit.git
cd mentorkit
make install   # setup del venv de desarrollo
```

Aquí el `Makefile`, `.gitlab-ci.yml` y el `README.md` raíz son parte de tu workflow de desarrollo, no del producto distribuido.

### Targets de desarrollo

| Target              | Qué hace                                              | Cuándo correrlo              |
|---------------------|-------------------------------------------------------|------------------------------|
| `make help`         | Muestra esta tabla                                    | Cuando no recuerdes los targets |
| `make install`      | Crea/repara el venv (Python 3.12.13 + 60 deps)        | Después de clonar, o si venv se rompe |
| `make verify`       | Chequeo rápido: Python + 4 imports                    | Antes de commitear (la CI también lo corre) |
| `make clean`        | Borra el venv (fuerza install fresh)                  | Si quieres empezar de cero   |
| `make ci`           | Simula el pipeline de GitLab CI localmente            | Antes de push, si quieres validar |
| `make all`          | Alias de `install`                                    | -                            |
| `make archive-spec` | Archiva una spec in-progress al system-spec (delta). `TARGET=specify\|openspec\|both` | Al cerrar un spec, antes de MR (ver abajo) — añadir `COMMIT=1` para que el archive produzca un commit con historial |
| `make init-constitution` | Genera/regenera `.specify/memory/constitution.md` desde template + fingerprint | Una vez al inicializar mentorkit en un proyecto, o cuando cambia el stack (añadir `DRY_RUN=1` para preview, `NO_GRAPH=1` para omitir integración con el grafo de conocimiento) |
| `make sync-openspec` | Mirror `.specify/` → `openspec/` (best-effort) | Cuando quieras sincronizar el espejo dual-path manualmente |

### 🚀 Flujo de trabajo mejorado con Skills Superpower

MentorKit ahora incluye una integración de skills "superpower" que endurece la consistencia del orquestador sin añadir pasos adicionales al flujo. Estas skills se activan automáticamente o se sugieren en puntos clave para:

- **Evitar trabajo perdido**: Verificación obligatoria antes de implementar
- **Mejorar la calidad de PRs**: Commits atómicos y manejo estructurado de feedback  
- **Reducir ansiedad**: Caminos claros y aislamiento seguro de trabajo
- **Auto-mejora del equipo**: Capacidad para crear y mejorar skills especializados

Las skills se integran como técnicas implícitas en cada fase:
- **Especificación**: `brainstorming` + `writing-plans` antes de tocar código
- **Confirmación**: `verification-before-completion` como parte del gate existente
- **Implementación**: `using-git-worktrees` para aislamiento seguro
- **PR**: `receiving-code-review`, `requesting-code-review` y `work-unit-commits`
- **Mejora continua**: `writing-skills` para evolucionar el propio orquestador

---

## 📦 ¿Qué contiene el repo?

- **`bootstrap.sh`** — orquestador end-to-end que descarga mentorkit como tarball y lo instala en tu proyecto (el one-liner de arriba descarga ESTE archivo)
- **`.opencode/skills/`** — 20 skills especializados (6 core + 14 superpowers)
- **`.opencode/install-mentorkit.sh`** — installer que garantiza Python 3.12.13 + 60 deps con SHA256 (modos: install, `--verify`, `--fix`)
- **`.opencode/requirements.lock`** — lock file con hashes exactos
- **`.gitlab-ci.yml`** — 5 jobs paralelos (`verify-install`, `verify-platform-coverage`, `verify-archive-spec`, `verify-spec-history`, `verify-openspec`) que ejecutan las 7 garantías en cada push
- **`Makefile`** — entry point para setup one-command en dev
- **`openspec/`** — espejo dual-path de especificaciones (ver [OpenSpec Dual-Path Mirror](#-openspec-dual-path-mirror))
- **Ver [.opencode/README.md](./.opencode/README.md)** para detalles del orchestrator y constitución.

---

## 🔒 Garantías del entorno (verificadas en CI)

1. **Python 3.12.13 pin exacto** — sin sorpresas de versión
2. **Lock con SHA256** — `requirements.lock` garantiza deps inmutables
3. **uv autocontenido en el venv** — no requiere `uv` en el PATH del sistema
4. **`mentorkit-verify.sh` PASS** — markitdown, striprtf, graphify, uv importables desde el venv
5. **Cross-platform** — el lock cubre Linux, macOS y Windows (con markers `sys_platform == 'win32'` para `colorama`, `pyreadline3`, `onnxruntime==1.20.1`)
6. **System-spec stays in sync** — `archive-spec` operacional + dry-run de specs in-progress + integridad del system-spec
7. **Specs con historial en git** — archives de specs commiteados (working tree en `.specify/` limpio)

8. **OpenSpec mirror integridad** — `verify-openspec` chequea que `.specify/` y `openspec/` estén sincronizados (warn, no fail)

Los jobs `verify-install`, `verify-platform-coverage`, `verify-archive-spec`, `verify-spec-history` y `verify-openspec` corren las 8 garantías en cada push y fallan el build si alguna se rompe.

---

## 📐 Flujo de specs (spec → system-spec)

MentorKit separa dos cosas:

- **Specs in-progress** (`.specify/specs/<NNN>-<slug>/spec.md`): viven solo durante
  la implementación. Son el contrato de la feature. Pueden ser ricos (contexto,
  vocabulario, prototipos UI).
- **System-spec** (`.specify/system-spec.md`): agregado vivo de TODOS los
  requirements del proyecto, organizados por dominio. Es lo que el dev
  consulta para entender "qué puede hacer este sistema".

Al cerrar una spec, se **mergea** al system-spec con formato delta
(ADDED / MODIFIED / REMOVED Requirements). El spec original queda
archivado en `.specify/specs/archive/<YYYY-MM-DD>-<slug>/` para
referencia futura, pero el system-spec solo contiene el delta.

### `make archive-spec` — archivar y mergear

```bash
# 1) Previsualizar (recomendado antes de mergear)
DRY_RUN=1 make archive-spec SPEC=.specify/specs/001-archive-spec/spec.md

# 2) Archivar y mergear al system-spec (sin commit — el dev decide cuándo commitear)
make archive-spec SPEC=.specify/specs/001-archive-spec/spec.md

# 3) Archivar + mergear + commitear (en un solo paso, deja historial en git)
COMMIT=1 make archive-spec SPEC=.specify/specs/001-archive-spec/spec.md

# 4) Re-archivar (sobrescribir un archive previo del mismo día)
FORCE=1 make archive-spec SPEC=.specify/specs/001-archive-spec/spec.md
```

**Lo que hace:**

1. Parsea el spec (header + `## ADDED/MODIFIED/REMOVED Requirements`).
2. Valida formato: exige `## Status:`, `## Dominio:`, `## Fecha:` y al
   menos un `### Requirement:` con un `#### Scenario:`.
3. Hace **idempotency check** temprano: si el archive target ya existe
   y no pasaste `--force`/`FORCE=1`, aborta con exit 4.
4. Lee el system-spec actual, aplica el delta al dominio correspondiente:
   - `ADDED`: añade los requirements al final de la sección del dominio.
   - `MODIFIED`: busca por nombre dentro del dominio y reemplaza.
   - `REMOVED`: busca por nombre dentro del dominio y borra.
5. Escribe el system-spec actualizado, mueve la spec al directorio archive
   y borra el dir origen si quedó vacío.
6. Imprime el diff (`+/- N` líneas) y la ruta final.

**Exit codes:**

| Code | Significado |
|------|-------------|
| 0    | Éxito (archivo mergeado o dry-run) |
| 1    | Error de uso (sin args, flag inválida, no git repo) |
| 2    | Spec mal formado (sin `## Status`/`## Dominio`/`## Fecha`) |
| 3    | Error de I/O (no se pudo escribir system-spec o mover spec) |
| 4    | Spec ya archivado (usa `--force` o `FORCE=1` para sobrescribir) |

**Formato de la spec (delta):**

```markdown
# Spec: Nombre de la Feature

**Número:** 001
**Slug:** mi-feature

---

## Status: Active
## Dominio: cli
## Fecha: 2026-06-06

## ADDED Requirements

### Requirement: Comando archive-spec
El sistema debe permitir archivar specs in-progress en el system-spec
mediante delta-based merge. La operación es idempotente.

#### Scenario: archivado exitoso
- **WHEN** el usuario corre `make archive-spec SPEC=...`
- **THEN** la spec se mueve a `.specify/specs/archive/` y se mergea al system-spec

#### Scenario: dry-run
- **WHEN** el usuario corre con `DRY_RUN=1`
- **THEN** el script parsea y muestra el diff, sin escribir nada

---

## Contexto (opcional, NO se mergea al system-spec)
[Sección libre que se preserva en el spec archivado: decisiones,
 historia, vocabulario, prototipos UI, etc.]
```

La línea `---` antes de `## Contexto` indica el límite entre el delta
mergeable y el contexto del feature. Sin ella, el script intenta parsear
el contexto como si fuera un requirement.

El job de CI `verify-archive-spec` corre 6 chequeos en cada push
(smoke + dry-run + integridad del system-spec) y falla el build si
rompes algo del flujo.

## 📜 Historial de requirements (git history)

Cada archive produce (opcionalmente) un commit con autor, fecha y diff
limpio, para que el equipo pueda auditar la evolución de los requirements
por persona y por fecha.

### Activar el auto-commit

```bash
# 1) Previsualizar (recomendado)
DRY_RUN=1 make archive-spec SPEC=.specify/specs/001-foo/spec.md

# 2) Archivar + mergear + commitear (en un solo paso)
COMMIT=1 make archive-spec SPEC=.specify/specs/001-foo/spec.md
```

El commit resultante sigue Conventional Commits:

```
docs(specs): archive 2026-06-06 001-archive-spec (cli)

ADDED (1):
  - Comando archive-spec

MODIFIED (1):
  - Validate-archive-spec

REMOVED (1):
  - Deprecated-manual-edit
```

El título incluye fecha + slug + dominio para que sea fácil filtrar.
El cuerpo lista los requirements tocados (con conteo) para que el diff
se entienda sin abrir el spec.

### Flags y variables de entorno

| Flag / Var          | Default | Cuándo usarlo |
|---------------------|---------|---------------|
| `--commit` / `COMMIT=1`     | off | Para que el archive produzca un commit. Sin esto, los archivos quedan en el working tree y el job `verify-spec-history` falla. |
| `--no-commit` / `COMMIT=0`  | off | Override explícito de `COMMIT=1` heredado del entorno. |
| `--force-dirty` / `FORCE_DIRTY=1` | off | Si el working tree tiene cambios no relacionados con el archive (sin esto, el commit aborta con exit 3 para no contaminar el commit del archive). |
| `--dry-run` / `DRY_RUN=1`   | off | Previsualiza sin escribir nada. Combinable con `COMMIT=1` (en dry-run no se commitea aunque lo pidas). |
| `--force` / `FORCE=1`       | off | Sobrescribe un archive del mismo día. |

### Flags de `make init-constitution`

| Flag / Var                | Default | Cuándo usarlo |
|---------------------------|---------|---------------|
| `--dry-run` / `DRY_RUN=1` | off | Previsualiza el render sin escribir el archivo. |
| `--force` / `FORCE=1`     | off | Sobrescribe un constitution.md existente sin pedir confirmación. |
| `--no-fingerprint` / `NO_FINGERPRINT=1` | off | Skip el análisis del stack (útil para regenerar constitution con template actualizado sin esperar el fingerprint). |
| `--no-graph` / `NO_GRAPH=1` | off | Skip la integración con `graphify-out/graph.json` (Pieza 3b.2). La sub-sección `### Architecture` mostrará el placeholder `--no-graph flag activo` en lugar de los god nodes y comunidades. Útil en CI/entornos sin `graph.json`. |
| `--target <path>`         | `.specify/memory/constitution.md` | Escribe la constitución a un path distinto del default. |

### Consultar el historial

```bash
# Historia completa del system-spec (cronológica, con autores)
git log --follow -- .specify/system-spec.md

# Solo los archives (filtrando por título del commit)
git log --grep="^docs(specs): archive" --oneline

# Diff de un archive concreto
git show <sha>

# Quién cambió QUÉ requirement (auditoría línea por línea)
git blame .specify/system-spec.md

# Spec archivado concreto (cambios desde su creación)
git log --follow -- .specify/specs/archive/2026-06-06-001-archive-spec/spec.md
```

### Garantía: archives siempre commiteados (CI)

El job `verify-spec-history` corre en cada push y **falla el build** si
encuentra archives sin commitear en `.specify/`:

```
❌ Hay archives de specs sin commitear:
   ?? .specify/specs/archive/2026-06-06-001-foo/spec.md
   M  .specify/system-spec.md

Esto rompe el historial de requirements en git (sin autor ni fecha).
Soluciones:
  1) Si archivaste sin querer: git restore .specify/specs/archive/ y borra el spec.
  2) Si fue intencional: make archive-spec COMMIT=1 SPEC=<path>
```

Si intencionalmente estás archivando algo con cambios no relacionados en
el working tree, usa `COMMIT=1 FORCE_DIRTY=1 make archive-spec SPEC=...`
para bypassear la safety check.

---

## 📐 OpenSpec Dual-Path Mirror

MentorKit soporta un **espejo dual-path** opcional: junto al almacén primario
`.specify/`, replica las especificaciones a `openspec/` para trazabilidad en
revisiones y visibilidad desde la raíz del proyecto.

### Arquitectura

```
.specify/                   ← almacén PRIMARIO
  system-spec.md              — especificación consolidada
  specs/archive/              — specs archivados
  memory/constitution.md      — constitución del proyecto

openspec/                   ← espejo (mirror best-effort)
  config.yaml                 — reglas SDD dual-path
  system-spec.md              — copia mirror
  specs/                      — copia mirror de specs activos
  changes/                    — cambios activos + archive
```

### Flujo de operación

| Operación | `.specify/` | `openspec/` |
|-----------|:-----------:|:-----------:|
| **Lectura** de constitution/specs | Primario | Fallback si `.specify/` no existe |
| **Escritura** de specs (skills) | ✅ Siempre | ✅ Mirror (best-effort) |
| **Archive** | ✅ Destino primario | Mirror con `--target both` |
| **Verificación** | — | Warn en desync, no fail |

### Uso del flag `--target`

El script `archive-spec` acepta `--target` con tres valores:

```bash
# Modo specify (default): opera solo sobre .specify/
make archive-spec SPEC=.specify/specs/001-foo/spec.md

# Modo openspec: opera solo sobre openspec/
TARGET=openspec make archive-spec SPEC=.specify/specs/001-foo/spec.md

# Modo both: escribe en .specify/ y replica a openspec/
TARGET=both make archive-spec SPEC=.specify/specs/001-foo/spec.md
```

### Sincronización manual

```bash
make sync-openspec    # mirror .specify/ → openspec/ (best-effort)
```

### CI: verify-openspec

El job `verify-openspec` corre en paralelo en cada push y verifica que ambos
almacenes estén sincronizados. **Warn, no fail** — si detecta desync muestra
una advertencia pero nunca rompe el build:

```
ℹ  OpenSpec mirror integrity check:
   ✓ openspec/config.yaml exists
   ✓ openspec/specs/ directory exists
   ✓ openspec/changes/ directory exists
   ⚠  WARN: .specify/system-spec.md ≠ openspec/system-spec.md
   ⚠  Run 'make sync-openspec' to re-sync
```

Esto permite que el equipo tenga visibilidad de la desync sin bloquear el
desarrollo.

### Skills con soporte dual-path

Cuatro skills de MentorKit tienen conocimiento del espejo OpenSpec:

| Skill | Soporte OpenSpec |
|-------|------------------|
| `codebase-conformist` | Fallback a `openspec/` para constitution + spec reads. Dual-write en research. |
| `spec-writer` | Dual-write: escribe a `.specify/` y replica a `openspec/`. Constitution read con fallback. |
| `prd-reader` | Dual-write para salida de spec. Constitution + system-spec reads con fallback. |
| `llm-council` | Fallback para carga de contexto. Council transcript guardado en `openspec/council/`. |

---

## 🤝 Contribuir

1. `make install` (primera vez)
2. Crea rama: `git checkout -b feat/mi-feature`
3. Haz cambios, commitea
4. `make ci` (simula el pipeline localmente, opcional)
5. Push y MR

---

## 📜 Créditos

Desarrollado por [fortes](https://gitlab.prod.uci.cu/fortes) · Universidad de las Ciencias Informáticas (UCI)
