# Constitución de [project-name]
<!-- IDENTIDAD -->
<!-- llenar manualmente: sustituye [project-name] por el nombre real del proyecto -->

> Invariantes del proyecto. Toda decisión que rompa algo de esto debe
> justificarse explícitamente en el commit message y/o en el PR.

---

<!-- CONSTITUCIONAL -->
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

<!-- auto-derivado -->
## Stack tecnológico

Las herramientas que el agente asume disponibles y sus versiones pin.
Auto-detectado por el fingerprint del proyecto destino; el dev puede
sobreescribir cualquier campo manualmente.

<!-- llenar manualmente: stack del proyecto destino -->

- **Lenguaje principal:** <!-- llenar manualmente -->
- **Versión pin:** <!-- llenar manualmente -->
- **Package manager:** <!-- llenar manualmente -->
- **Lock file:** <!-- llenar manualmente --> (generado con `--universal --generate-hashes`)
- **VCS:** <!-- llenar manualmente -->
- **CI platform:** <!-- llenar manualmente -->
- **Plataformas target:** <!-- llenar manualmente -->

### Dependencias críticas (top-N por rol)

<!-- llenar manualmente: framework, ORM, test runner, linter, etc. -->

### Scripts principales

<!-- llenar manualmente: 3-10 scripts top-level ejecutables con su rol -->

| Script | Rol |
|---|---|
| <!-- llenar manualmente --> | <!-- llenar manualmente --> |

### Architecture (grafo de conocimiento)

<!-- auto-derivado -->

Si el proyecto tiene `graphify-out/graph.json` (grafo construido con
[graphifyy](https://pypi.org/project/graphifyy/)), esta sub-sección se
auto-rellena con los módulos críticos (god nodes) y comunidades naturales
detectadas por análisis de grafos. Si no hay grafo disponible, se
muestra el placeholder `<!-- Architecture omitida: ... -->`.

Para construir el grafo en tu proyecto:

```bash
.opencode/.mentorkit/venv/bin/graphify . --no-viz --quiet
```

---

<!-- CONSTITUCIONAL -->
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
> 💡 **Consejo de MentorKit**: Antes de llenar esta spec, usa:
> - `skill brainstorming` para explorar intención del usuario y requisitos
> - `skill writing-plans` para crear un checklist atómico y accionable
> Esto evita especificaciones vagas y asegura que sepas exactamente qué construir.
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

<!-- CONSTITUCIONAL -->
## Confirmation gate (regla de proceso)

Ningún cambio se implementa sin confirmación explícita del junior,
**tras verificar evidencia concreta de que el trabajo está listo**.

Antes de decir "go", debes:
1. Usar `skill verification-before-completion` para confirmar que:
   - Las pruebas pasan (si aplica)
   - El código cumple con lo especificado
   - No hay efectos secundarios no intencionales
2. Tener listo tu plan de implementación (de `skill writing-plans`)

El coste de un "go" extra es despreciable. El coste de una
implementación sorpresa (writes sin rollback, contaminación de git,
trabajo perdido) es alto. El plan se presenta, el junior verifica,
dice "go", recién ahí se implementa.

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

<!-- CONSTITUCIONAL -->
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

<!-- CONSTITUCIONAL -->
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

<!-- IDENTIDAD -->
## Identidad del proyecto

<!-- llenar manualmente: 5 líneas con la metadata básica del proyecto -->

- **Nombre del proyecto:** <!-- llenar manualmente -->
- **Descripción (1-2 frases):** <!-- llenar manualmente -->
- **Owners / maintainers:** <!-- llenar manualmente -->
- **Licencia:** <!-- llenar manualmente -->
- **URLs de docs:** <!-- llenar manualmente -->
