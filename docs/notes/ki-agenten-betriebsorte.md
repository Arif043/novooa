# Wo die KI-Agenten laufen

> Der Aufgabenstudio-Agent läuft über ein Relay in Firebase mit dem Modell des Betreibers; der Wissensbasis-Agent läuft in der Runtime mit dem Modell des Nutzers, damit Notizen das Gerät nicht verlassen.

Gehört zu: [KI-Agent](../index/ki-agent.md) · [Lokale Runtime](../index/lokale-runtime.md)

| Agent | Wo | Modell |
| --- | --- | --- |
| **Aufgabenstudio** | Die Runtime reicht Frage und Verlauf über `localRuntimeTaskBuilderRelay` weiter | aus Remote Config |
| **Wissensbasis** | in der Runtime, Notizen aus SQLite | Sprachmodell des Nutzers |

- Die App spricht immer die Runtime an (`POST /v1/assistant/task-builder`,
  `/v1/assistant/knowledge-base`, `assistantRoutes`).
- Warum: Der Aufgabenstudio-Agent braucht keine lokalen Daten. Der
  Wissensbasis-Agent liest Notizen, die lokal bleiben sollen.
- Modell des Wissensbasis-Agenten (`resolveDefaultLanguageModel`): das unter
  Einstellungen → „Sprachmodelle“ gewählte
  (`LanguageModelDefaults.knowledgeAssistantModelId`), sonst das
  Standardmodell. Fehlt beides oder wurde es gelöscht, bekommt er einen
  Hinweis — kein Rückfall auf ein Betreibermodell.

## Siehe auch

- [Agentenmodell über Remote Config](./agent-modell-remote-config.md)
- [Relay des Aufgabenstudio-Agenten](./aufgabenstudio-agent-relay.md)
