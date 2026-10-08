# ODD Persistence Contract

## Purpose

ODD necesita recuperar trabajo sustancial sin convertir una memoria externa en autoridad sobre el repositorio.

## Sources

1. **LocalFile (obligatorio):** `odd/tasks/<feature>.md`. Es la copia durable mínima y versionada por Git.
2. **Engram (opcional):** espejo del documento completo para continuidad cross-session.
3. **Future backends:** cualquier backend adicional debe conservar el mismo contrato.

## Contract

- Antes del primer source write de trabajo SUBSTANTIAL debe existir el archivo local.
- El espejo externo debe contener el documento completo, no un resumen que pueda perder contexto.
- Las escrituras en memoria no son atómicas: escribir y volver a leer para comprobarlas.
- Al reanudar: leer local + recuperar espejo + comparar con código/diff real.
- Si falta el espejo, continuar con local y marcar la sincronización pendiente.
- Si local y espejo difieren, el repositorio observado y el estado de Git tienen precedencia.
- La memoria nunca autoriza cambios ni amplía scope.

## Engram Adapter

La rama no hace que Engram sea dependencia obligatoria. La integración debe descubrir la capacidad disponible en el runtime y actuar como adaptador opcional.

Contrato conceptual:

```
write(feature, full_document)
read(feature) -> full_document | missing
status(feature) -> reachable | unavailable
```

Si el runtime no dispone de Engram, ODD continúa con LocalFile.
