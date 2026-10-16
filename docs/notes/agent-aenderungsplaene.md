# Änderungspläne des Agenten

> Der Agent ändert nie direkt; er schlägt einen Plan vor, den die UI erst nach **Ausführen** Schritt für Schritt anwendet und bei Fehlern zurückrollt.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- `AssistantPlanAction`: ein auszuführender Schritt.
- `AssistantPlanExecutor`: führt Schritte sequenziell aus.
- `AssistantPlanExecution`: nimmt erfolgreiche Schritte in umgekehrter
  Reihenfolge zurück; bei einem Fehler automatisch, bevor die UI ihn zeigt.
- Command-Factories bleiben im Ziel-Feature. Aufgabenstudio und Wissensbasis
  adaptieren ihre typisierten Commands auf `AssistantPlanAction`; das
  Assistenz-Feature transportiert nur neutrale `AssistantActionSuggestion`-Daten,
  nie fachliche Command-Klassen.
- Commands je Aktion: Aufgaben `RenameTaskAgentCommand`,
  `AddNodeAgentCommand`, `ConfigureNodeAgentCommand`; Wissensbasis
  `CreateKnowledgeNoteAgentCommand`, `UpdateKnowledgeNoteAgentCommand`,
  `DeleteKnowledgeNoteAgentCommand`.

## Siehe auch

- [Commands und Agent-Cursor](./agent-commands-und-cursor.md)
- [Wissensbasis-Agent](./wissensbasis-agent.md)
