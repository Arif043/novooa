# Iterative Verfeinerung

> Der Baustein bewertet einen Entwurf rundenweise mit `{critique, satisfied}` und verbessert ihn, bis die Bewertung erfüllt ist oder `maxIterations` erreicht wird.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Entwurf nur aus `draftTemplate`; leer ergibt einen leeren Entwurf.
- Steuerung: `optimizerPrompt`, `critiquePrompt`, `maxIterations`.
- Mitarbeiter oder Fähigkeiten wie beim Prompt.
- OpenAI-kompatible Provider: Text-JSON-Fallback für die strukturierte
  Bewertung.
- Prompts über das [LLM-Framework](./llm-aufruf-framework.md)
  (`iterative-refinement-prompts.ts`, Aufrufe in
  `iterative-refinement-calls.ts`): Bei der Bewertung sind die Kriterien
  `<task>`, Ziel und Entwurf `<context>`; bei der Überarbeitung ist der
  Optimierer-Prompt `<task>`, dazu Ziel, aktueller Entwurf und Feedback als
  `<context>`. Die Antwort folgt der Sprache der Kriterien bzw. Anweisung.
- Port `IterativeRefinementExecutor`, Adapter
  `createGenkitIterativeRefinementExecutor`.

## Siehe auch

- [Prompt-Executor](./prompt-executor.md)
