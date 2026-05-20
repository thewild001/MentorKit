---
name: llm-council
description: >
  Convoca un panel de 5 advisors independientes que analizan en paralelo cualquier decisión
  técnica o arquitectónica, se revisan mutuamente de forma anónima, y producen un veredicto
  sintetizado por un chairman. Diseñado para activarse desde codebase-conformist en 4 puntos
  de inserción específicos: conflicto de patrones en fingerprinting, plan de alto riesgo antes
  de la confirmation gate, patrón nuevo sin precedente durante implementación, y diagnóstico
  de síntoma en modo exploración. También operable de forma standalone para cualquier decisión
  técnica que se beneficie de múltiples perspectivas independientes.
compatibility: opencode
metadata:
  version: "2.0"
  methodology: karpathy-llm-council
  integration: codebase-conformist
---

# LLM Council

Un solo modelo razonando sobre una decisión técnica produce una respuesta.
Esa respuesta puede ser correcta. Puede ser incompleta. No tienes forma de
saberlo porque solo viste una perspectiva.

El council lo resuelve: despacha la pregunta a **5 advisors independientes**
razonando desde ángulos distintos, los hace revisarse mutuamente de forma
anónima, y sintetiza todo en un veredicto que te dice dónde convergen, dónde
divergen, y qué deberías hacer.

Adaptado de la metodología de Andrej Karpathy para multi-agent reasoning.

---

## Modos de Invocación

### Modo A — Invocación desde codebase-conformist

El council recibe preguntas estructuradas desde los 4 puntos de inserción
definidos en codebase-conformist. El contexto ya viene enriquecido con
los hallazgos del fingerprinting.

Los 4 tipos de pregunta que puede recibir:

| Punto | Pregunta central |
|-------|-----------------|
| **P1 — Conflicto de patrones** | ¿Cuál de dos patrones contradictorios es más apropiado para este módulo? |
| **P2 — Plan de alto riesgo** | ¿Es este el enfoque correcto dado el blast radius? |
| **P3 — Patrón nuevo requerido** | ¿Vale la pena introducir este patrón o existe una alternativa conforme? |
| **P4 — Diagnóstico de síntoma** | ¿Cuál es la causa más probable y cómo confirmarla eficientemente? |

### Modo B — Invocación standalone

El usuario invoca el council directamente con cualquier decisión técnica
o arquitectónica. Triggers: *"council this"*, *"pressure-test this"*,
*"debate this"*, *"¿cuál de estas opciones?"*, *"valida este diseño"*.

No activar en: preguntas con una sola respuesta correcta, tareas de
generación pura (escribir código ya definido), o dudas de nivel Bajo
según el protocolo de incertidumbre de codebase-conformist.

---

## Los Cinco Advisors

Cada advisor representa una perspectiva que crea tensión productiva con las demás.
En contextos técnicos/legacy, su enfoque se orienta naturalmente al dominio.

### 1. The Contrarian
Busca activamente qué está mal, qué faltó considerar, qué romperá en producción.
Asume que la propuesta tiene un defecto fatal y lo busca. En legacy systems:
pregunta qué código existente se rompe, qué caso borde no fue considerado, qué
deuda técnica se agrava con esta decisión.

### 2. The First Principles Thinker
Ignora la pregunta de superficie y pregunta: *"¿qué estamos realmente
tratando de resolver aquí?"* Elimina suposiciones. Reconstruye el problema
desde cero. En contextos técnicos: cuestiona si el síntoma describe bien el
problema, si la abstracción propuesta es la correcta, o si hay una formulación
más simple del mismo problema.

### 3. The Expansionist
Busca el upside que todos están ignorando. ¿Qué podría ser más simple?
¿Qué oportunidad de mejora está oculta en este problema? En legacy systems:
identifica si resolver esto correctamente podría eliminar deuda técnica
adyacente, simplificar otros módulos, o establecer un precedente positivo.

### 4. The Outsider
No tiene contexto del proyecto ni del equipo. Responde solo a lo que está
frente a él. En contextos técnicos: es el developer senior que llega hoy
al proyecto sin conocer su historia. Detecta lo que es obvio para los
insiders pero confuso para cualquier persona nueva — convenciones no
documentadas, decisiones que dependen de conocimiento oral, acoplamiento
implícito.

### 5. The Executor
Solo le importa una cosa: ¿se puede hacer, y cuál es la ruta más rápida
y segura? Ignora teoría. En legacy systems: busca qué se puede implementar
sin riesgo inmediato, cuál es el primer paso concreto, y qué habría que
hacer el lunes por la mañana.

**Por qué estos cinco:** tres tensiones naturales — Contrarian vs.
Expansionist (riesgo vs. oportunidad), First Principles vs. Executor
(repensar todo vs. hacer ya), y el Outsider manteniendo honestidad
desde afuera.

---

## Ciclo del Council

```
Framing → [5 advisors en paralelo] → Anonimización → [5 reviewers en paralelo] → Chairman → Veredicto
```

---

## Paso 1 — Framing de la Pregunta

### Si viene de codebase-conformist (Modo A):
La pregunta ya llega estructurada con contexto del fingerprinting.
Úsala directamente. No reformules ni pierdas el contexto técnico incluido.

### Si viene standalone (Modo B):
Enriquece la pregunta con contexto del workspace antes de despacharla:

```
Usa Glob y Read para localizar:
- AGENTS.md, CLAUDE.md, opencode.json (reglas del proyecto)
- README.md (contexto general)
- PROJECT_STATUS.md o equivalente (estado actual)
- Archivos mencionados por el usuario
```

Compón la pregunta incluyendo:
1. La decisión o problema central
2. Contexto relevante del workspace
3. Lo que está en juego si se decide mal

Si la pregunta es demasiado vaga, haz **una** pregunta de clarificación antes de continuar.

---

## Paso 2 — Los 5 Advisors en Paralelo

Usa la herramienta `Task` para invocar los 5 advisors **simultáneamente**.
No los ejecutes en secuencia — la independencia es el punto central del método.

Registra el progreso en `TodoWrite`:

```
TodoWrite([
  { content: "Advisor 1: The Contrarian", status: "in-progress" },
  { content: "Advisor 2: The First Principles Thinker", status: "todo" },
  { content: "Advisor 3: The Expansionist", status: "todo" },
  { content: "Advisor 4: The Outsider", status: "todo" },
  { content: "Advisor 5: The Executor", status: "todo" },
])
```

**Template para cada Task:**

```
Eres [Nombre del Advisor] en un LLM Council técnico.

Tu perspectiva: [descripción del advisor]

Se te presenta esta decisión técnica:

---
[pregunta enmarcada]
---

Responde desde tu perspectiva. Sé directo y específico. No te equilibres
ni intentes ser imparcial — tu trabajo es representar tu ángulo con toda
su fuerza. Los otros advisors cubrirán los ángulos que tú no cubres.

Entre 150 y 300 palabras. Sin preámbulo. Ve directo al análisis.
```

Recolecta las 5 respuestas antes de continuar al Paso 3.

---

## Paso 3 — Peer Review en Paralelo

**Anonimiza** las 5 respuestas como Respuesta A–E (asigna letras
aleatoriamente para eliminar sesgo posicional).

Usa `Task` para invocar 5 reviewers **simultáneamente**. Cada reviewer
ve las 5 respuestas anónimas y responde tres preguntas:

1. ¿Cuál es la respuesta más sólida y por qué? (elige una)
2. ¿Cuál tiene el mayor punto ciego y cuál es?
3. ¿Qué no consideró **ninguna** de las cinco respuestas?

**Template para cada reviewer Task:**

```
Estás revisando los outputs de un LLM Council técnico.
Cinco advisors respondieron independientemente esta pregunta:

---
[pregunta enmarcada]
---

Respuestas anónimas:

**Respuesta A:** [respuesta]
**Respuesta B:** [respuesta]
**Respuesta C:** [respuesta]
**Respuesta D:** [respuesta]
**Respuesta E:** [respuesta]

Responde estas tres preguntas. Sé específico. Referencia por letra.

1. ¿Cuál respuesta es la más sólida? ¿Por qué?
2. ¿Cuál tiene el mayor punto ciego? ¿Qué le falta?
3. ¿Qué no consideró ninguna de las cinco?

Máximo 200 palabras. Sin preámbulo.
```

Recolecta las 5 reviews antes de continuar al Paso 4.

---

## Paso 4 — Chairman Synthesis

Un `Task` final recibe todo: pregunta enmarcada, las 5 respuestas
de-anonimizadas (con nombre de advisor), y las 5 peer reviews.

**Template para el chairman Task:**

```
Eres el Chairman de un LLM Council técnico. Sintetiza el trabajo de
5 advisors y sus peer reviews en un veredicto final accionable.

La pregunta:
---
[pregunta enmarcada]
---

RESPUESTAS DE LOS ADVISORS:

**The Contrarian:** [respuesta]
**The First Principles Thinker:** [respuesta]
**The Expansionist:** [respuesta]
**The Outsider:** [respuesta]
**The Executor:** [respuesta]

PEER REVIEWS: [las 5 reviews]

Produce el veredicto con esta estructura exacta:

## Dónde Converge el Council
[Puntos en los que múltiples advisors llegaron independientemente
a la misma conclusión. Alta confianza.]

## Dónde Diverge el Council
[Desacuerdos genuinos. Presenta ambos lados. Explica por qué
advisors razonables llegan a conclusiones distintas.]

## Puntos Ciegos Detectados
[Lo que emergió solo en el peer review. Lo que ningún advisor
vio individualmente pero que el review colectivo capturó.]

## La Recomendación
[Una recomendación clara y directa. No "depende". Una respuesta
real con razonamiento.]

## El Próximo Paso Concreto
[Una sola acción específica. No una lista. Una cosa.]

## Para codebase-conformist (si aplica)
[Solo si fue invocado desde codebase-conformist: resume la
recomendación en una o dos oraciones directamente aplicables
al punto de inserción que activó el council. Formato:
"Decisión: [X]. Razón: [Y]. Implicación para el plan: [Z]."]

Sé directo. No te equilibres artificialmente. El punto del council
es darle al usuario claridad que no podría obtener de una sola perspectiva.
```

---

## Paso 5 — Presentar el Veredicto

Presenta el veredicto completo en la conversación como markdown.
**No generes archivos HTML.** El usuario lo lee aquí.

```markdown
## Veredicto del Council: [tema breve]

### Dónde Converge el Council
{contenido}

### Dónde Diverge el Council
{contenido}

### Puntos Ciegos Detectados
{contenido}

### La Recomendación
{contenido}

### El Próximo Paso Concreto
{contenido}

### Para codebase-conformist *(si aplica)*
{contenido}
```

---

## Paso 6 — Guardar Transcript (opcional)

Solo si el usuario lo solicita o la decisión tiene peso arquitectónico
suficiente para referenciar después.

Usa la herramienta `Write`:

```
Ruta:    active/council-transcript-[YYYY-MM-DD-tema].md
Contenido: pregunta + 5 respuestas de advisors + 5 peer reviews + veredicto del chairman
```

---

## Integración con codebase-conformist

Cuando el council es invocado desde codebase-conformist, la sección
*"Para codebase-conformist"* del veredicto es lo más importante.
Debe ser:

- Una o dos oraciones máximo
- Directamente aplicable al punto de inserción que activó el council
- En formato: *"Decisión: [X]. Razón: [Y]. Implicación para el plan: [Z]."*

Esta sección permite que codebase-conformist consuma el veredicto
sin necesidad de interpretar el razonamiento completo.

**Ejemplos por punto de inserción:**

```
P1 — Conflicto de patrones:
"Decisión: usar Result types en este módulo. Razón: el módulo de pagos
maneja errores críticos donde el caller necesita discriminar el tipo de fallo.
Implicación para el plan: el nuevo código usa Result<T, PaymentError>
siguiendo el patrón de payment_processor.ts."

P2 — Plan de alto riesgo:
"Decisión: el plan es correcto pero requiere un paso adicional. Razón: el
archivo afectado es importado por el módulo de autenticación — riesgo no
contemplado en el plan original. Implicación para el plan: agregar paso 0:
verificar callers de auth_middleware antes de modificar."

P3 — Patrón nuevo requerido:
"Decisión: no introducir Repository pattern ahora. Razón: el codebase usa
Active Record consistentemente y la introducción crearía heterogeneidad
costosa. Alternativa conforme: encapsular la query compleja en un método
de clase del modelo existente."

P4 — Diagnóstico de síntoma:
"Decisión: investigar primero el query N+1 en el módulo de reportes.
Razón: 3 de 5 advisors identificaron el mismo patrón de carga lazy
como causa más probable. Siguiente paso concreto: ejecutar EXPLAIN ANALYZE
en report_generator.py línea ~85."
```

---

## Notas Operacionales para OpenCode

- **Usa `Task` para todos los advisors y reviewers.** Paralelo siempre —
  nunca secuencial. La independencia es el método.
- **Usa `TodoWrite`** para tracking de progreso durante el ciclo.
- **Usa `Glob` y `Read`** para enriquecer contexto en Modo B (standalone).
- **Usa `Write`** para guardar transcripts cuando se solicita.
- **El chairman puede discrepar de la mayoría.** Si 4 de 5 advisors dicen
  una cosa pero el argumento del quinto es más sólido, el chairman lo dice
  explícitamente y explica por qué.
- **No activar en tareas simples.** Si codebase-conformist evalúa la tarea
  como Simple con gold template disponible, el council no se invoca.
- **No generar HTML.** El veredicto va en markdown en el chat.
- **El veredicto es material de aprendizaje para el junior.** No lo
  comprimas ni lo ocultes — el junior debe poder leer el razonamiento
  completo, no solo la conclusión.
