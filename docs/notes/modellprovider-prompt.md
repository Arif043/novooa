# Modellprovider für Prompt-Bausteine

> Prompt-, Verfeinerungs- und Mitarbeiter-Executoren wählen Modelle nur über `ai-models.ts`; ein Baustein kann ein teamweites Sprachmodellprofil wählen.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Ort: `functions/src/features/task_execution/infrastructure/genkit/runner/ai-models.ts`.
- `languageModelId` wählt ein Sprachmodellprofil, zur Run-Zeit aufgelöst, mit
  eigener Provider-Verbindung. Ohne Auswahl gilt das Standardmodell
  (Legacy-Fallback).
- Standardmodell per `AI_PROVIDER`:

| `AI_PROVIDER` | Zweck |
| --- | --- |
| `google` (Standard) | Gemini über `@genkit-ai/google-genai` |
| `minimax` | MiniMax über OpenAI-kompatiblen Provider |
| `openai-compatible` | beliebiger kompatibler Cloud-Endpunkt |
| `local` | lokaler OpenAI-kompatibler Server |

In einer Firebase Function zeigt `127.0.0.1` auf die Function-Instanz, nicht
auf den Rechner der Nutzer:innen.

## Siehe auch

- [Sprachmodell-Anbieter](./sprachmodell-anbieter.md) — Verbindungen der Runtime
- [Prompt-Executor](./prompt-executor.md)
