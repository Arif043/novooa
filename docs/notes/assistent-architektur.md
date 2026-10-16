# Architektur des Assistenten

> Client und Backend haben je eine frameworkfreie Assistenz-Domain; Genkit, Firebase und Callables sitzen nur in der Infrastructure.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- **Client-Domain:** `AssistantRepository`, `AskAssistant`,
  `AssistantMessage`, `AssistantContext`.
- **Backend-Domain:** `AssistantActor`, `AssistantMessage`,
  `AssistantRequest`, `AssistantExecutionContext`, Port `AssistantResponder`,
  Use Case `AskAssistant`.
- **Client-Infrastructure:** `RoutedAssistantRepository` wählt zwischen zwei
  typisierten Datasources; `FirebaseFunctionsAssistantDatasource` kapselt
  Auth, Timeout, Verlauf und Antwortprüfung zentral.
- **Backend-Infrastructure:** `GenkitAssistantResponder` implementiert den Port
  einmal; die bereichsspezifischen Factories liefern nur Modell, Prompt, Tools
  und Antwort-Parser.
- **Presentation:** `AssistantCubit` steuert Verlauf, Laden und Fehler. Die
  Root-AppBar öffnet den Agenten und übergibt den aktuellen Bereich als
  Kontext. Leer-, Lade-, Fehler- und Erfolgszustände sind abgebildet.
- **Produktwissen:** Kein separates RAG. Die Prompts der Bereiche Aufgaben und
  Wissensbasis enthalten das Produktwissen direkt; das Baustein-Wissen steht in
  `novooa-product-knowledge.ts` und muss zum
  [Bausteinkatalog](./bausteinkatalog.md) passen.

## Siehe auch

- [Multiagenten-Architektur des Aufgabenstudios](./multiagenten-aufgabenstudio.md)
- [Wissensbasis-Agent](./wissensbasis-agent.md)
- [Laufzeitgrenzen der Ausführung](./ausfuehrung-laufzeitgrenzen.md)
