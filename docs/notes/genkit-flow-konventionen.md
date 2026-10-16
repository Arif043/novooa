# Genkit-Flow-Konventionen

> Flows heißen `…Flow`, haben Zod-Schemas, beziehen Modelle nur über `ai-models.ts` und werden in `functions/src/index.ts` re-exportiert.

Gehört zu: [Architektur](../index/architektur.md)

- Name `camelCase` mit Endung `Flow`; Datei `<feature>-workflows.ts`, für
  Querschnittsdienste eine eigene gleichnamige Datei.
- `inputSchema`/`outputSchema` mit Zod (`z.object(...)`), kein `any`;
  `streamSchema` nur bei Streaming.
- Modelle nur über
  `functions/src/features/task_execution/infrastructure/genkit/runner/ai-models.ts`
  (Profile `google`, `minimax`, `openai-compatible`, `local`).
- Cloud-Secrets über `defineSecret` bzw. Secret Manager; lokale Runtimes nutzen
  eigene `.env`-Werte und setzen keine Cloud-Secrets voraus.
- Tools mit `ai.defineTool({...}, async (...) => {...})` im Feature, das sie
  braucht.
- Logging: `logger.info` für Lebenszyklus, `logger.error` für Fehler.

| Flow | Status |
| --- | --- |
| `runTaskDefinitionFlow` | produktiv (Aufgabe) |
| `reviewTaskRunFlow` | produktiv (Aktivitäten) |
| `menuSuggestionFlow` (`genkit-sample.ts`) | Vorlage, nicht produktiv |

## Siehe auch

- [Backend: Schichtregeln](./backend-schichtregeln.md)
- [Auth, App Check und Telemetrie](./auth-appcheck-telemetrie.md)
