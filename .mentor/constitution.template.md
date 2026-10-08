# Constitución de <project>

> Gobernanza e invariantes del proyecto. Esta constitución no define el workflow ODD.

## Engineering Invariants

- <stack, arquitectura y restricciones que no deben romperse>
- <seguridad y privacidad>
- <testing y calidad>
- <compatibilidad y performance>

## Conventional Commits

Los commits siguen Conventional Commits 1.0.

- Un commit = una unidad lógica.
- El body puede documentar la razón cuando el cambio rompe un invariante.
- Los cambios sustanciales registran el commit en su T# de ODD.

## Testing

- Ejecutar tests relevantes antes del cierre.
- Si test-first no es aplicable, documentar la razón y ejecutar checks funcionales.
- No declarar completado un cambio sin evidencia.

## Scope

- Los hallazgos no autorizan cambios adicionales.
- Las ampliaciones de alcance requieren decisión explícita.
- El código existente es la referencia principal para convenciones y patrones.

## Delivery

- Push, PR y merge son decisiones separadas.
- Los work-unit commits son candidatos naturales de revisión.
