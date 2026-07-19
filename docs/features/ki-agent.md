## Zweck

Der In-App KI-Agent hilft Nutzer:innen beim Erstellen von Aufgaben und beim
Pflegen der Wissensbasis. Er ist als Assistenzoberfläche im Client umgesetzt und
nutzt Firebase AI Logic als API-Schicht für Modellaufrufe.

## Verantwortlichkeiten

- Kontextbezogene Hilfe für Aufgabenbau, Nodes, Trigger und Wissensbasis geben.
- Antworten kurz, konkret und auf Deutsch formulieren.
- Den Domain-Layer von Firebase AI Logic entkoppeln.
- UI-Zustände für leer, ladend, Fehler und erfolgreiche Antworten abbilden.

## Architektur

- Domain: `AssistantRepository`, `AskAssistant`, `AssistantMessage`,
  `AssistantContext`.
- Infrastructure: `FirebaseAiAssistantDatasource` kapselt Firebase AI Logic.
- `InternalAssistantKnowledge` liefert pro unterstütztem Bereich ein kurzes
  internes Wissensstück, das direkt in den Systemprompt geschrieben wird.
- Presentation: `AssistantCubit` steuert Verlauf, Ladezustand und Fehler.
- Einstieg: Die Root-AppBar öffnet den Agenten und übergibt den aktuellen
  Bereich als Kontext.

## Interne Wissensbasis

Der MVP nutzt kein separates RAG. Aktuell unterstützt der interne Agent nur
zwei Bereiche:

- Aufgaben
- Wissensbasis

Die Wissensbasis wird als verbindliche Produktinformation in die
`systemInstruction` von Firebase AI Logic eingefügt. Dadurch bleibt der Agent
einfach, schnell änderbar und ohne zusätzliche Persistenz.

## Offene Fragen

- Ob der Agent später Task-Entwürfe direkt erzeugen darf oder vorerst nur
  erklärt.
- Ob die interne Wissensbasis später aus Markdown-Assets oder vom Backend
  geladen wird.
- Ob Antworten und Verläufe pro Team persistiert werden sollen.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`wissensbasis.md`](./wissensbasis.md)
- [`../architecture.md`](../architecture.md)
