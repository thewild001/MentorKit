# Constitución de mentorkit

> Invariantes del proyecto. Toda decisión que rompa algo de esto debe
> justificarse explícitamente en el commit message y/o en el PR.

---

## Conventional Commits

Los commits siguen [Conventional Commits 1.0](https://www.conventionalcommits.org/).
La taxonomía de tipos (keyword) es **cerrada** — no se inventan nuevos keywords:

| Keyword      | Significado                                       |
|--------------|---------------------------------------------------|
| `feat`       | Nueva feature visible al usuario                  |
| `fix`        | Bug fix                                           |
| `chore`      | Mantenimiento sin cambio de comportamiento        |
| `docs`       | Solo cambios de documentación                     |
| `refactor`   | Cambio interno sin nueva feature ni fix           |
| `test`       | Solo cambios en tests                             |
| `perf`       | Mejora de performance                             |
| `build`      | Cambios al build system o dependencias            |
| `ci`         | Cambios al pipeline de CI                         |
| `style`      | Formateo sin cambio lógico                        |

**Reglas:**

- **Scope opcional** entre paréntesis, indica el módulo: `feat(bootstrap): ...`
- **Body en español.** El keyword y el scope van en inglés (parte del estándar
  Conventional Commits), el texto descriptivo va en español para consistencia
  con el idioma del proyecto.
- **Breaking changes**: sufijo `!` después del tipo/scope + sección
  `BREAKING CHANGE:` en el footer.
- **Atomicidad**: 1 commit = 1 cambio lógico. No acumular cosas no relacionadas.

---

## Lenguaje y dependencias

- **Python 3.12.13** pin exacto (LTS). El venv trae su propio Python.
- **Bash 4+** para scripts (NO `sh`). Estilo defensivo: `set -uo pipefail`
  (sin `-e`, para que el diagnóstico corra aunque el install falle).
- **uv** como package manager (NO pip, NO poetry).

## Scripts principales

| Script | Rol |
|---|---|
| `bootstrap.sh` | Orquestador end-to-end: descarga tarball, copia, install |
| `.opencode/install-mentorkit.sh` | Installer con 5 fases + idempotencia |
| `.opencode/mentorkit-verify.sh` | Verify con modo `--json` para CI |
| `.opencode/mentorkit-python.sh` | Wrapper que fuerza Python del venv |
| `.opencode/mentorkit-archive-spec.sh` | Delta-based merge de specs al system-spec |
| `Makefile` | Targets one-command (install/verify/clean/hooks/ci/archive-spec con `--commit`) |

## Flujo de specs (delta-based merge)

Las specs viven en dos lugares con propósitos distintos:

- **Specs in-progress** (`.specify/specs/<NNN>-<slug>/spec.md`): el contrato
  de cada feature durante implementación. Pueden ser ricas (contexto,
  vocabulario, prototipos UI, `[NEEDS CLARIFICATION]` resueltos en chat).
- **System-spec** (`.specify/system-spec.md`): agregado vivo de TODOS los
  requirements, organizados por dominio (`cli`, `ci`, `install`, etc.).
  Es lo que el dev consulta para entender "qué puede hacer este sistema".

Al cerrar una spec, se **mergea** al system-spec con formato delta
(ADDED / MODIFIED / REMOVED Requirements) mediante
`make archive-spec SPEC=<path>`. La spec original se mueve a
`.specify/specs/archive/<YYYY-MM-DD>-<slug>/` y la sección `## Contexto`
(separada por `---`) se preserva en el archivo archivado pero NO
se mergea al system-spec.

**Auto-commit (recomendado):** añadir `COMMIT=1` para que el script
produzca un commit con autor, fecha y diff limpio. Sin esto, los
archivos quedan en el working tree y el CI `verify-spec-history` falla.
Si el working tree tiene cambios no relacionados con el archive, usar
`FORCE_DIRTY=1` para bypassear la safety check.

**Formato obligatorio de las specs mergeables:**

```markdown
## Status: Active
## Dominio: <nombre-del-dominio>
## Fecha: <YYYY-MM-DD>

## ADDED Requirements
### Requirement: <nombre-estable>
[1-3 párrafos]
#### Scenario: <escenario>
- **WHEN** <condición>
- **THEN** <resultado>

## MODIFIED Requirements  (opcional)
## REMOVED Requirements   (opcional)

---
## Contexto (opcional, NO se mergea)
[Sección libre preservada solo en el archive]
```

**Reglas:**

- `## Status`, `## Dominio`, `## Fecha` son obligatorios (el script las parsea).
- Cada `### Requirement:` debe tener al menos un `#### Scenario:`.
- El nombre del `### Requirement:` es el ID estable. NO renombrar entre
  MODIFIED — el script lo usa para encontrar y reemplazar.
- La línea `---` antes de `## Contexto` es el delimitador entre delta y
  contexto. Sin ella, el script intenta parsear el contexto como
  requirements.

## Confirmation gate (regla de proceso)

Ningún cambio se implementa sin confirmación explícita del junior,
sin importar la complejidad. Aplica a:

- Fixes de 1 línea (typos, renames)
- Logs / comentarios
- Borrado de dead code
- Refactors triviales
- Tests puntuales
- Documentación

El coste de un "go" extra es despreciable. El coste de una
implementación sorpresa (writes sin rollback, contaminación de git,
trabajo perdido) es alto. El plan se presenta, el junior dice "go",
recién ahí se implementa.

**Excepciones explícitas** (no requieren gate):

- Cambios puramente operacionales al sistema de mentorkit mismo
  (commit de esta garantía, save de reglas en engram, etc.)
- Read-only: `git log`, `grep`, `cat`, búsquedas, lecturas

**Confirmaciones aceptadas** (sin re-preguntar):

`go` · `ok` · `dale` · `sí` · `si` · `adelante` · `proceed` · `yes` ·
`perfecto` · `confirmo` · `aprobado` · `hazlo`

**Si la respuesta es ambigua** (ej: "más o menos", "ok pero con X"),
se pide clarificación antes de implementar. No se asume consentimiento
parcial.

---

## Garantías verificadas en CI

El job `verify-install` (y `verify-platform-coverage`) ejecuta en cada push:

1. Python 3.12.13 pin exacto
2. Lock file con SHA256 (53 paquetes, --universal)
3. Idempotencia (re-install no degrada el venv)
4. Self-contained (no depende del Python del sistema)
5. Lock cubre plataforma cross-platform (linux/macos/windows)
6. **System-spec stays in sync.** El job `verify-archive-spec` valida en
   cada push que el script `archive-spec` corre sin romperse (smoke + dry-run)
   y que el `system-spec.md` mantiene su header y metadata correctos. Si
   una spec se queda sin archivar, queda registrada como deuda técnica.
7. **Specs con historial en git.** El job `verify-spec-history` falla el
   build si encuentra archives de specs sin commitear en `.specify/`
   (working tree sucio). Para que el archive produzca un commit, usar
   `COMMIT=1 make archive-spec SPEC=<path>`. El commit sigue Conventional
   Commits: `docs(specs): archive <fecha> <slug> (<dominio>)` con cuerpo
   que lista `ADDED (N):`, `MODIFIED (N):`, `REMOVED (N):` y los nombres
   de los requirements tocados. Así el equipo puede auditar la evolución
   de los requirements con `git log -- .specify/system-spec.md`,
   `git blame`, y `git log --grep="^docs(specs): archive"`.
