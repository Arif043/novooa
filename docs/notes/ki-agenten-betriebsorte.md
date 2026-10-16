# Wo die KI-Agenten laufen

> Der Aufgabenstudio-Agent läuft immer in der Cloud mit dem Modell des Betreibers; der Wissensbasis-Agent läuft in Standalone in der Runtime mit dem Modell des Nutzers, damit Notizen das Gerät nicht verlassen.

Gehört zu: [KI-Agent](../index/ki-agent.md) · [Lokale Runtime](../index/lokale-runtime.md)

| Agent | Cloud | Standalone |
| --- | --- | --- |
| **Aufgabenstudio** | Callable `askTaskBuilderAssistant`, Modell aus Remote Config | Runtime reicht Frage und Verlauf über `localRuntimeTaskBuilderRelay` an die Cloud |
| **Wissensbasis** | Callable `askKnowledgeBaseAssistant`, Notizen aus Firestore, Modell aus Remote Config | in der Runtime, Notizen aus SQLite, Sprachmodell des Nutzers |

- `WorkspaceCapabilities.assistant` ist in beiden Varianten `true`; in
  Standalone spricht die App die Runtime an (`POST /v1/assistant/task-builder`,
  `/v1/assistant/knowledge-base`, `assistantRoutes`).
- Warum: Der Aufgabenstudio-Agent braucht keine lokalen Daten. Der
  Wissensbasis-Agent liest Notizen, die lokal bleiben sollen.
- Modell des Wissensbasis-Agenten (`resolveDefaultLanguageModel`): das unter
  Einstellungen → „Sprachmodelle“ gewählte
  (`LanguageModelDefaults.knowledgeAssistantModelId`, nur in der Runtime
  sichtbar), sonst das Standardmodell. Fehlt beides oder wurde es gelöscht,
  bekommt er einen Hinweis — kein Rückfall auf ein Betreibermodell.
- In der Runtime fehlt bewusst nur das Audit-Logging der Cloud (dient dort der
  teamübergreifenden Aufsicht).

## Siehe auch

- [Agentenmodell über Remote Config](./agent-modell-remote-config.md)
- [Relay des Aufgabenstudio-Agenten](./aufgabenstudio-agent-relay.md)
- [Fähigkeiten je Variante](./workspace-capabilities.md)
