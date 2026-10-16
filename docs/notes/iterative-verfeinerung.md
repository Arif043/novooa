# Iterative Verfeinerung

> Der Baustein bewertet einen Entwurf rundenweise mit `{critique, satisfied}` und verbessert ihn, bis die Bewertung erfüllt ist oder `maxIterations` erreicht wird.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Entwurf nur aus `draftTemplate`; leer ergibt einen leeren Entwurf.
- Steuerung: `optimizerPrompt`, `critiquePrompt`, `maxIterations`.
- Mitarbeiter oder Fähigkeiten wie beim Prompt.
- OpenAI-kompatible Provider: Text-JSON-Fallback für die strukturierte
  Bewertung.
- Port `IterativeRefinementExecutor`, Adapter
  `createGenkitIterativeRefinementExecutor`.

## Siehe auch

- [Prompt-Executor](./prompt-executor.md)
