# prd-drp-extractor

## Objective

Optimizar el camino SUBSTANTIAL de MentorKit para leer documentos de requisitos
tipo DRP ("Descripción de Requisitos por Proceso"): conservar la estructura
real del documento y limitar la lectura normativa a partir de
«Descripción textual del requisito», tratando el resto como contexto.

## Specs

S1. Extracción nativa de ODT/DOCX que preserve la estructura.
- Acceptance: `mentorkit.py extract <archivo>` produce `<stem>.normalized.md`, `<stem>.drp.json` y `assets/` (solo imágenes referenciadas); usa solo biblioteca estándar; falla con rc=1 ante archivo inexistente.
- Checks: tests unitarios con fixture sintético; ejecución sobre el documento de ejemplo.

S2. Reconstrucción de la tabla de maquetación DRP.
- Acceptance: precondiciones, flujo básico (pasos numerados por fila), flujos alternativos (ids `3.a`, `4.b.2.a`), validaciones, conceptos, requisitos especiales, asuntos pendientes y prototipos quedan separados; el contexto previo se marca como informativo.
- Checks: tests unitarios; revisión del `.drp.json` del ejemplo.

S3. Diagnósticos sobre el propio documento.
- Acceptance: inconsistencias (validación sobre campo inexistente, saltos de numeración, desfase de ids de flujos alternativos) se reportan como `info`/`warning` y no se corrigen en silencio.
- Checks: ejecución sobre el ejemplo.

S4. Skills alineados con la realidad.
- Acceptance: `document-extractor` deja de referirse a un parser inexistente y documenta `extract`; `prd-reader` incorpora el mapeo DRP → PRD Analysis y la obligación de convertir diagnósticos y contradicciones de prototipo en Open Questions.
- Checks: aserciones de CI sobre los skills.

S5. Cobertura en CI.
- Acceptance: `platform-smoke.yml` ejecuta los tests contra la copia instalada de `.opencode/` en ubuntu, macOS y Windows.
- Checks: ejecución del workflow en el PR.

## Tasks

- [x] T1 — Extractor `prd_extract.py` (ODT/DOCX, DRP, diagnósticos)
  - Spec: S1, S2, S3
  - Route: `.opencode/prd_extract.py`
  - Commit: pending
- [x] T2 — Subcomando `extract` y registro en `REQUIRED`
  - Spec: S1
  - Route: `.opencode/mentorkit.py`
  - Commit: pending
- [x] T3 — Skills `document-extractor` y `prd-reader`
  - Spec: S4
  - Route: `.opencode/skills/`
  - Commit: pending
- [x] T4 — Tests con fixture sintético y paso de CI
  - Spec: S1, S2, S5
  - Route: `tests/test_prd_extract.py`, `.github/workflows/platform-smoke.yml`
  - Commit: pending

## Verification

- [x] S1 — `extract` sobre el ejemplo y archivo inexistente (rc=1)
- [x] S2 — 11 tests (1 omitido sin muestra); con `MENTORKIT_SAMPLE_PRD` también pasan
- [x] S3 — el ejemplo reporta 8 info y 3 warning
- [x] S4 — skills reescritos
- [ ] S5 — pendiente del resultado de CI en el PR (Windows/macOS no se pueden ejecutar aquí)
- [ ] Regressions: pendiente de CI

## Log

L1. Solicitud: usar un PRD de ejemplo (ODT, FORTES «Incluir codificador tipo Vía de ingreso») para optimizar el camino SUBSTANTIAL; lo relevante es lo que sigue a «Descripción textual del requisito».
L2. Hallazgo: `document-extractor` describía un «parser Python puro existente» que no existía en el repositorio.
L3. Hallazgo: el contenido normativo vive en una única tabla de maquetación de 12 columnas; un extractor de texto plano pierde la jerarquía de flujos.
L4. Decisión: los pasos del flujo básico no están numerados en el archivo; se numeran por fila. Los ids de flujos alternativos van sistemáticamente +1 sobre la fila que realiza la validación (posible paso implícito). No se adivina: se reporta como `numbering.suspected_offset` y requiere confirmación del analista.
L5. Decisión: el documento de ejemplo está marcado «USO INTERNO»; no se versiona. Los tests usan un fixture sintético; `MENTORKIT_SAMPLE_PRD` permite correr el real en local.
L6. Limitación: la ruta DOCX solo se probó con un fixture sintético, no con DOCX reales. El extractor no interpreta imágenes; el agente debe abrirlas y compararlas con `form_fields`.

## Delivery

- Status: active
- Branch: claude/prd-drp-extractor
- Review candidate: PR hacia feature/odd-migration
- Next step: revisar el resultado de platform-smoke en el PR
