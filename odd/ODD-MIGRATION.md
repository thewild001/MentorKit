# Migración experimental de MentorKit a ODD

## Objetivo

Probar ODD como workflow primario sin comprometer `main`.

## Cambios de arquitectura

- ODD se convierte en la capa de orquestación.
- `codebase-conformist` pasa a ser ejecutor principal dentro del ciclo ODD.
- `spec-writer` produce S# para documentos ODD cuando el trabajo es sustancial.
- `TodoWrite` permanece como tracking efímero.
- `openspec/` queda como compatibilidad legacy durante esta rama.
- La constitución deja de definir el workflow; define gobernanza e invariantes.
- La persistencia ODD abstrae LocalFile y deja Engram como backend opcional.

## Criterios de éxito

1. Un cambio pequeño no genera una spec persistente innecesaria.
2. Un cambio sustancial genera `odd/tasks/<feature>.md` antes del código.
3. El documento permite reanudar el trabajo después de una interrupción.
4. Cada unidad sustancial produce evidencia y commit.
5. Los hallazgos fuera de scope no se implementan silenciosamente.
6. Las capacidades actuales de MentorKit (graph, council, TDD, review, Git) siguen disponibles.
7. La CI valida la estructura ODD.
8. OpenSpec puede seguir consultándose durante la transición sin ser creado por defecto.

## Experimento recomendado

Probar al menos:

- 3 cambios SMALL;
- 2 features SUBSTANTIAL;
- 1 bug con diagnóstico;
- 1 cambio que requiera council;
- 1 interrupción/resume;
- 1 cambio de alcance después de una tarea completada.

Registrar fricciones y ajustar el clasificador antes de retirar OpenSpec.
