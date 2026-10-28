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
  einmal und ruft das Modell über das [LLM-Framework](./llm-aufruf-framework.md)
  auf; die bereichsspezifischen Factories liefern nur Modell, Anweisungen
  (`PromptBuilder` für den Systemteil), Tools, Ausgabeschema und
  Antwort-Parser. `assistantPrompt` ergänzt Antwortsprache, Verlauf
  (`messages`), genannte Webseiten (`<context name="public_urls">`) und die
  Frage als `<task>`.
- **Zustandslos:** Den Verlauf schickt der Client mit jeder Frage (die jüngsten
  acht Nachrichten, `maximumHistoryMessages`); die Runtime-Route und der
  Callable nehmen höchstens acht an. Deshalb läuft derselbe Responder in
  Runtime und Relay, ohne Sitzung auf dem Server.
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
