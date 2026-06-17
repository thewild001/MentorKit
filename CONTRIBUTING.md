# Guía de Contribución a MentorKit con Skills Superpower

Esta guía describe cómo contribuir a MentorKit utilizando los skills de la categoría "superpower" para mantener la consistencia y calidad del orquestador.

## 📋 Flujo de Contribución Mejorado

MentorKit sigue su flujo Constitution → Spec → Fingerprinting → Plan → Confirm → Implement → PR, pero ahora con integración explícita de skills superpower en cada fase.

### 1. Antes de Empezar: Preparación
```bash
# El skill using-superpowers se carga automáticamente al iniciar cualquier sesión con MentorKit
# Esto habilita todos los demás skills superpower para su uso
```

### 2. Especificación (Spec)
Antes de crear o modificar una spec:

```bash
# Explora intención y requisitos
opencode run skill brainstorming

# Crea un plan atómico y accionable
opencode run skill writing-plans
```

> 💡 **Tip**: La sección de Contexto en las specs ahora incluye recordatorios para usar estos skills.

### 3. Planificación (Plan)
Al definir tu plan de implementación:

```bash
# Divide tu trabajo en unidades de trabajo revisables
opencode run skill work-unit-commits
```

Esto asegura que tus commits sean:
- Atómicos (un cambio lógico por commit)
- Fáciles de revertir si es necesario
- Claramente descriptivos para revisores

### 4. Confirmación (Confirm)
**ANTES** de decir "go" en el confirmation gate:

```bash
# Verifica evidencia concreta de que tu trabajo está listo
opencode run skill verification-before-completion
```

Esto verifica:
- Que las pruebas pasan (si aplica)
- Que el código cumple con lo especificado
- Que no hay efectos secundarios no intencionales

Solo después de esta verificación debes proceder con el confirmation gate existente.

### 5. Implementación (Implement)
Durante la fase de implementación:

```bash
# Crea un workspace aislado para evitar contaminar el main branch
opencode run skill using-git-worktrees
```

Para tareas complejas o independientes:
```bash
# Ejecuta trabajo en paralelo sin riesgo de conflictos de estado
opencode run skill subagent-driven-development
```

### 6. Revisión de PR (Pull Request)
Al preparar tu PR:

```bash
# Verifica que tu trabajo cumple con los requisitos antes de solicitar review
opencode run skill requesting-code-review
```

Al recibir feedback:
```bash
# Analiza técnicamente cada sugerencia antes de implementarla
opencode run skill receiving-code-review
```

Al decidir cómo integrar tu rama:
```bash
# Elige entre merge, squash, rebase basado en el contexto
opencode run skill finishing-a-development-branch
```

### 7. Después del Merge: Auto-mejora
Si identificas oportunidades para mejorar MentorKit mismo:

```bash
# Crea o mejora skills especializados basado en lo aprendido
opencode run skill writing-skills
```

Luego sigue el flujo estándar de contribución para proponer tu skill.

## 🎯 Skills Superpower Relevantes para MentorKit

| Skill | Cuándo Usarlo | Beneficio |
|-------|---------------|-----------|
| `using-superpowers` | Al inicio de cualquier sesión (automático) | Habilita todos los demás skills |
| `brainstorming` | Antes de especificar | Explora intención y evita supuestos |
| `writing-plans` | Antes de implementar | Crea planes atómicos y accionables |
| `verification-before-completion` | Antes de decir "go" | Asegura evidencia antes de implementar |
| `using-git-worktrees` | Durante implementación | Aislamiento seguro de trabajo |
| `subagent-driven-development` | Para tareas complejas | Ejecución paralela sin conflictos |
| `requesting-code-review` | Antes de soliciting PR | Verificación previa al review |
| `receiving-code-review` | Al recibir feedback | Análisis técnico riguroso de sugerencias |
| `finishing-a-development-branch` | Al cerrar la rama | Decisión informada sobre integración |
| `work-unit-commits` | Durante todo el flujo | Commits atómicos y revisables |
| `writing-skills` | Para mejorar MentorKit | Creación y mejora de skills especializados |

## 🔧 Ejemplo de Flujo Completo

```bash
# 1. Empezar (using-superpowers se carga automáticamente)

# 2. Especificar
opencode run skill brainstorming
opencode run skill writing-plans
# [Crear o modificar spec.md]

# 3. Planificar
opencode run skill work-unit-commits
# [Definir plan de implementación]

# 4. Confirmar
opencode run skill verification-before-completion
# [Decir "go" en el confirmation gate]

# 5. Implementar
opencode run skill using-git-worktrees
# [Para tareas complejas: opencode run skill subagent-driven-development]
# [Implementar cambios]

# 6. PR
opencode run skill requesting-code-review
# [Crear PR]
# [Recibir feedback: opencode run skill receiving-code-review]
# [Decidir integración: opencode run skill finishing-a-development-branch]

# 7. Mejorar
# [Si identificas mejoras para MentorKit:]
opencode run skill writing-skills
```

## ✅ Mejores Prácticas

1. **Nunca omitas la verificación**: El paso de `verification-before-completion` es lo que transforma el confirmation gate de un simple sí/no en un proceso basado en evidencia.

2. **Los worktrees son tu amigo**: Siempre usa `using-git-worktrees` antes de comenzar a modificar código para mantener tu main branch limpio.

3. **Los commits cuentan una historia**: Usa `work-unit-commits` para asegurar que cada commit tenga un propósito claro y sea fácil de entender.

4. **El feedback es un regalo**: Cuando recibes sugerencias de review, usa `receiving-code-review` para analizarlas técnicamente antes de descartarlas o implementarlas.

5. **Mejora continuamente**: Si mientras trabajas identificas una oportunidad para mejorar MentorKit mismo, no dudes en crear una skill usando `writing-skills`.

## ❌ Qué Evitar

- No saltarte la verificación diciendo "confío en que funciona"
- No hacer cambios directamente en tu main branch sin usar worktrees
- No acumular múltiples cambios lógicos en un solo commit
- No implementar sugerencias de review sin analizarlas técnicamente primero
- No asumir que el flujo de MentorKit es suficiente sin los skills de apoyo

## 📏 Métricas de Calidad

Al contribuir, busca que tus PRs:
- Requieran ≤ 2 rondas de revisiones (indicando buena preparación previa)
- Tengan commits atómicos y fáciles de revisar
- Incluyan evidencia de verificación en la descripción o comentarios
- Mantengan el main branch limpio gracias al uso de worktrees
- Contribuyan a la mejora continua del orquestador cuando sea apropiado

---

**Recordatorio**: Los skills superpower no son pasos adicionales que seguir, sino técnicas que hacen que el flujo existente de MentorKit funcione mejor, reduzca el trabajo perdido y construya confianza en cada contribution. Si sientes que alguno de estos skills te está añadiendo burocracia en lugar de valor, por favor proporciona feedback para mejorar su integración.