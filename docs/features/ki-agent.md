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
- Presentation: `AssistantCubit` steuert Verlauf, Ladezustand und Fehler.
- Einstieg: Die Root-AppBar öffnet den Agenten und übergibt den aktuellen
  Bereich als Kontext.

## Offene Fragen

- Ob der Agent später Task-Entwürfe direkt erzeugen darf oder vorerst nur
  erklärt.
- Ob Wissensbasis-Notizen als zusätzlicher Retrieval-Kontext eingebunden
  werden.
- Ob Antworten und Verläufe pro Team persistiert werden sollen.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`wissensbasis.md`](./wissensbasis.md)
- [`../architecture.md`](../architecture.md)
