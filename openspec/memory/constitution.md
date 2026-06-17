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

## Stack tecnológico

Las herramientas que el agente asume disponibles y sus versiones pin.
Auto-detectado por el fingerprint del proyecto destino; el dev puede
sobreescribir cualquier campo manualmente.

- **Lenguaje principal:** N/A
- **Versión pin:** N/A
- **Package manager:** N/A
- **Lock file:** N/A
- **VCS:** git
- **CI platform:** N/A
- **Plataformas target:** N/A

### Dependencias críticas (top-N por rol)

<!-- llenar manualmente: framework, ORM, test runner, linter, etc. -->

<!-- Pieza 3b.1: el fingerprint no extrae top-N deps todavía. 
     Esto se enriquece en iteraciones futuras. -->

### Scripts principales

<!-- No se detectaron scripts top-level ejecutables. -->

### Architecture (grafo de conocimiento)

<!-- Architecture omitida: graphify-out/graph.json no disponible. Construye el grafo con `.opencode/.mentorkit/venv/bin/graphify . --no-viz --quiet` y vuelve a correr init-constitution. -->


---

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


---

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


`N` jobs en stage `verify` corren en paralelo en cada push. La
implementación detallada de cada check vive en el archivo de CI del
proyecto (`.gitlab-ci.yml`, `.github/workflows/*.yml`, etc.); esta
lista es el **contrato constitucional** — lo que el sistema promete
a quien use el repo.

<!-- llenar manualmente: lista numerada de 5-10 garantías que el CI verifica -->

1. <!-- llenar manualmente -->
2. <!-- llenar manualmente -->
3. <!-- llenar manualmente -->
4. <!-- llenar manualmente -->
5. <!-- llenar manualmente -->

**Filosofía:** "probado en mi máquina" no es una garantía. El CI es la
única forma de mantener las garantías en el tiempo — un PR futuro no
podrá romper un invariante constitucional sin que el CI lo detecte.

**Detección de drift (opcional):** si tu constitución y tu CI divergen
(garantías listadas que el CI no verifica, o viceversa), el agente lo
avisa en `make verify`. El humano decide si actualizar la constitución
o el CI. **Nunca auto-resuelve.**


---

## Evolución de la constitución


La constitución no es estática. Sigue un lifecycle de 5 fases:

1. **INIT** (one-time): la tool de auto-generación produce la constitución
   del proyecto destino con las secciones CONSTITUCIONALES copiadas
   verbatim de este template, las DERIVADAS (Stack, scripts) auto-detectadas
   vía fingerprint, y las IDENTIDAD vacías con placeholders para llenar
   manualmente.
2. **ENRICH** (continuous): humanos agregan secciones o contenido que
   las tools no detectan — convenciones de estilo no obvias, decisiones
   arquitectónicas con rationale, módulos legacy que no se tocan,
   performance/SLA budgets, compliance constraints, onboarding notes.
3. **COMMIT**: la constitución se commitea y pushea a git del proyecto.
   Tracked, versionado, no efímero.
4. **CONSUME** (cada operación del agente): el agente lee la constitución
   del proyecto ANTES de hacer fingerprinting en vivo. La constitución
   ya contiene la info de Stack — no re-detectarla en cada operación.
5. **DRIFT-CHECK** (opcional, en CI o `make verify`): comparar constitución
   actual vs. código actual. Si hay drift, avisar al humano. No bloquear,
   no auto-arreglar.

**Drift ≠ Conflicto:** cuando constitución y código difieren, el agente
sugiere al humano, nunca impone. El humano decide si actualizar la
constitución o arreglar el código.

**ENRICHMENT funciona sin re-render:** las secciones SIN marker
`<!-- auto-derivado -->` son preservadas en re-renders. Los humanos
pueden agregar secciones libres (Markdown) sin que las tools las toquen,
mientras no marquen la sección como auto-derivada.


---

## Identidad del proyecto


<!-- llenar manualmente: 5 líneas con la metadata básica del proyecto -->

- **Nombre del proyecto:** <!-- llenar manualmente -->
- **Descripción (1-2 frases):** <!-- llenar manualmente -->
- **Owners / maintainers:** <!-- llenar manualmente -->
- **Licencia:** <!-- llenar manualmente -->
- **URLs de docs:** <!-- llenar manualmente -->


---

## Lenguaje y dependencias


- **Python 3.12.13** pin exacto (LTS). El venv trae su propio Python.
- **Bash 4+** para scripts (NO `sh`). Estilo defensivo: `set -uo pipefail`
  (sin `-e`, para que el diagnóstico corra aunque el install falle).
- **uv** como package manager (NO pip, NO poetry).
  - Input: `.opencode/requirements.in` (lista de deps en alto nivel)
  - Output pinneado: `.opencode/requirements.lock` (generado con
    `uv pip compile --universal --generate-hashes`). El CI verifica
    que el lock mantenga `--universal` y ≥20 hashes por paquete con
    C extensions (numpy, scipy, cryptography, pillow, etc.).


---

## Scripts principales


| Script | Rol |
|---|---|
| `bootstrap.sh` | Orquestador end-to-end: descarga tarball, copia, install |
| `.opencode/install-mentorkit.sh` | Installer con 5 fases + idempotencia |
| `.opencode/mentorkit-verify.sh` | Verify con modo `--json` para CI |
| `.opencode/mentorkit-python.sh` | Wrapper que fuerza Python del venv |
| `.opencode/mentorkit-archive-spec.sh` | Delta-based merge de specs al system-spec |
| `.opencode/mentorkit-init-constitution.sh` | Auto-genera constitution.md desde template + fingerprint (Pieza 3b.2: incluye integración graph — god nodes + comunidades) |
| `Makefile` | Targets one-command (`help`/`install`/`verify`/`clean`/`ci`/`archive-spec`/`init-constitution`/`all`; `archive-spec` acepta `COMMIT=1`; `init-constitution` acepta `DRY_RUN=1`/`FORCE=1`/`NO_FINGERPRINT=1`/`NO_GRAPH=1`/`TARGET=<path>`) |


---

## Diseño evolutivo de la constitución


El proceso que genera/actualiza esta constitución vive en
`.specify/specs/000-auto-constitution/spec.md` (formato delta, 18
requirements `CONST-001..018`). El diseño completo (lifecycle, drift
detection, distribution A+B+D, riesgos y mitigaciones) está en
`research.md` del mismo dir.

**Piezas 1-3b.2** (spec, template, render tool con graph integration) están
DONE. **Piezas 4-7** (engram seed, distribución A+B+D, CI version gate)
están PENDING — ver `research.md` § Approach.

<!-- ℹ engram no detectado, sección engram omitida -->
<!-- ℹ engram no detectado, sección engram omitida -->
<!-- ℹ engram no detectado, sección engram omitida -->
<!-- ℹ engram no detectado, sección engram omitida -->
<!-- ℹ engram no detectado, sección engram omitida -->
