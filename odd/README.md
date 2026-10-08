# Organic Driven Development (ODD)

MentorKit usa ODD como modelo de orquestación para decidir **cuánto proceso necesita realmente cada cambio**.

## Principios

1. Una explicación, investigación o lectura no autoriza cambios.
2. Una solicitud explícita de implementación autoriza el cambio salvo que exista una decisión crítica que requiera aclaración.
3. El agente explora primero y pregunta solo por decisiones que no puede resolver con seguridad.
4. Cambios pequeños y suficientemente entendidos no necesitan un artefacto persistente.
5. Trabajo sustancial crea `odd/tasks/<feature>.md` **antes del primer write de código**.
6. El documento de feature es la fuente de verdad recuperable del trabajo sustancial.
7. `TodoWrite` es estado efímero de ejecución; no sustituye el documento ODD.
8. Cada unidad de trabajo sustancial termina con verificación y un commit atómico.
9. Push, PR y merge son decisiones de entrega separadas.
10. Los hallazgos no amplían silenciosamente el alcance autorizado.

## Flujo

```
Request
  ↓
Authorize
  ↓
Explore
  ↓
Resolve uncertainty
  ↓
Classify
  ├── SMALL
  │     ↓
  │   Implement → Verify → Commit → Close
  │
  └── SUBSTANTIAL
        ↓
      Feature Document
        ↓
      Specs + Tasks
        ↓
      Implement task-by-task
        ↓
      Verify → Work-unit Commit
        ↓
      Review / PR
        ↓
      Close
```

## Persistencia

La implementación actual define una interfaz conceptual de persistencia:

- **LocalFile**: obligatorio y siempre disponible.
- **Engram**: adaptador opcional para continuidad cross-session.
- **Future backends**: posibles sin cambiar el workflow.

La ausencia de Engram nunca debe bloquear el trabajo ni convertir una memoria faltante en una afirmación de éxito.

## Compatibilidad con OpenSpec

Durante esta migración experimental, `openspec/` se conserva como **legacy compatibility store**. El flujo ODD no crea ni requiere nuevas specs en OpenSpec.

La eliminación definitiva de OpenSpec se hará solo después de validar el flujo ODD en esta rama y resolver las regresiones encontradas.
