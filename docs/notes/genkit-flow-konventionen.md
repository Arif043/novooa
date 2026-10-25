# Genkit-Flow-Konventionen

> Flows heißen `…Flow`, haben Zod-Schemas und beziehen Modelle nur über `ai-models.ts`; die Runtime ruft sie im eigenen Prozess auf.

Gehört zu: [Architektur](../index/architektur.md)

- Name `camelCase` mit Endung `Flow`; Datei `<feature>-workflows.ts`, für
  Querschnittsdienste eine eigene gleichnamige Datei.
- `inputSchema`/`outputSchema` mit Zod (`z.object(...)`), kein `any`;
  `streamSchema` nur bei Streaming.
- Modelle nur über
  `functions/src/features/task_execution/infrastructure/genkit/runner/ai-models.ts`
  (Profile `google`, `minimax`, `openai-compatible`, `local`).
- Die Runtime nutzt eigene `.env`-Werte; Secrets über `defineSecret` braucht
  nur das Relay des Aufgabenstudio-Agenten in Firebase.
- Tools mit `ai.defineTool({...}, async (...) => {...})` im Feature, das sie
  braucht.
- Logging: `logger.info` für Lebenszyklus, `logger.error` für Fehler.

## Siehe auch

- [Backend: Schichtregeln](./backend-schichtregeln.md)
- [Relay des Aufgabenstudio-Agenten](./aufgabenstudio-agent-relay.md)
