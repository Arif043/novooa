# Backend: Feature-First-Struktur

> `functions/src` ist nach Features geordnet, jedes mit `domain` und `infrastructure`; eine `application`-Schicht gibt es nicht, Use Cases liegen in `domain/usecases`.

Gehört zu: [Architektur](../index/architektur.md)

```text
functions/src/
  index.ts                 re-exportiert nur öffentliche Trigger, keine Logik
  features/<feature>/
    domain/{entities,repositories,usecases}/
    infrastructure/{firebase,genkit,local,functions,…}/
  shared/                  echte Querschnittsthemen
    firebase/ genkit/ local/ logging/ rate_limiting/
```

- `shared/` nur ohne fachliche Zuständigkeit, z. B. strukturiertes Logging
  (`firebase-functions/logger`) oder `shared/rate_limiting` (`RateLimiter`,
  `TokenBucketRateLimiter`, Ports für Eimer-Speicher und -Einstellungen,
  `InMemoryBucketStateStore`; genutzt von Skills-Relay, Webhooks und
  Runtime-Login). Konkrete Speicher und Einstellungen bleiben im Feature.
- Etwas wandert erst nach `shared/`, wenn mindestens zwei Features es ohne
  fachliche Kopplung brauchen.
- Die Migration in diese Struktur ist abgeschlossen.

| Feature | Verantwortung |
| --- | --- |
| `assistant` | Agentenanfrage, Ausführungskontext, Responder-Ports, Genkit-/Callable-Adapter |
| `task_execution` | Task-Definitionen, Runs, Graph Runner, Node Executors, Cloud Tasks |
| `teams` | Arbeitsbereich, Mitgliedschaft, Einladungen |
| `scheduling` | Zeit- und Ereignis-Auslöser, Fälligkeiten |
| `communication` | Nachrichten, Kanäle, Inbox, Mail-Connectoren, Provider-Sender |
| `files` | Datei-Metadaten, Versionen, Objektzugriff |
| `knowledge_base` | Notizen, Links, Workspace-Auflösung |
| `machine_learning` | Modellkatalog, ONNX-Verträge, Inferenzports |
| `notifications` | In-App-Freigaben, Push-Versand |

Weitere: `connections`, `webhooks`, `integrations`, `skills`, `employees`,
`data`, `workspace_transfer`, `speech_synthesis`, `speech_transcription`,
`language_models`, `licensing`, `runtime_security`.

## Siehe auch

- [Backend: Schichtregeln](./backend-schichtregeln.md)
- [Integrations-Plugins](./integrations-plugins.md)
