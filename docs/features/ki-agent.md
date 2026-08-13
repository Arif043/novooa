## Zweck

Der In-App KI-Agent hilft Nutzer:innen beim Erstellen von Aufgaben und beim
Pflegen der Wissensbasis. Er ist als Assistenzoberfläche im Client umgesetzt und
nutzt Firebase AI Logic als API-Schicht für Modellaufrufe.

## Verantwortlichkeiten

- Kontextbezogene Hilfe für Aufgabenbau, Nodes, Trigger und Wissensbasis geben.
- Antworten kurz, konkret und auf Deutsch formulieren.
- Öffentliche URLs in Nutzerfragen mit Firebase AI Logic URL Context auswerten.
- Wissensbasis-Notizen des aktuellen Teams über Firebase-AI-Lese-Tools
  recherchieren.
- Den Domain-Layer von Firebase AI Logic entkoppeln.
- UI-Zustände für leer, ladend, Fehler und erfolgreiche Antworten abbilden.

## Architektur

- Domain: `AssistantRepository`, `AskAssistant`, `AssistantMessage`,
  `AssistantContext`.
- Infrastructure: `FirebaseAiAssistantDatasource` kapselt Firebase AI Logic.
- URL Context liest konkrete öffentliche URLs aus einer Agentenanfrage. Die
  Abrufmetadaten werden als Quellen an der Agentenantwort dargestellt.
- `InternalAssistantKnowledge` liefert pro unterstütztem Bereich ein kurzes
  internes Wissensstück, das direkt in den Systemprompt geschrieben wird.
- `FirebaseAiKnowledgeBaseReadTools` stellt im Wissensbasis-Kontext
  `searchKnowledgeNotes` und `readKnowledgeNote` als
  `AutoFunctionDeclaration` bereit. `ChatSession.sendMessage` führt diese
  Leseaufrufe automatisch aus.
- Presentation: `AssistantCubit` steuert Verlauf, Ladezustand und Fehler.
- Einstieg: Die Root-AppBar öffnet den Agenten und übergibt den aktuellen
  Bereich als Kontext.

## Änderungspläne

Für Änderungen schlägt der Agent einen Plan vor, statt eine Mutation direkt
auszuführen. Die gemeinsame Assistant-UI zeigt die Schritte und wendet sie erst
nach einem Klick auf **Ausführen** an.

- `AssistantPlanAction` kapselt einen auszuführenden Schritt.
- `AssistantPlanExecutor` führt Schritte sequenziell aus.
- `AssistantPlanExecution` nimmt alle erfolgreich ausgeführten Schritte in
  umgekehrter Reihenfolge zurück.
- Schlägt ein Schritt fehl, führt der Executor denselben Rollback automatisch
  aus, bevor die UI den Fehler anzeigt.

Fachliche Command-Factories bleiben im jeweiligen Ziel-Feature. Der
Aufgaben-Builder adaptiert seine typisierten Commands auf
`AssistantPlanAction`; die Wissensbasis tut dies ebenfalls. Das Assistant-
Feature transportiert nur neutrale `AssistantActionSuggestion`-Daten aus dem
Modellprotokoll, niemals fachliche Command-Klassen.

Konkrete Commands sind je Aktion getrennt gekapselt:

- Aufgaben: `RenameTaskAgentCommand`, `AddNodeAgentCommand`
- Wissensbasis: `CreateKnowledgeNoteAgentCommand`,
  `UpdateKnowledgeNoteAgentCommand`, `DeleteKnowledgeNoteAgentCommand`

## Wissensbasis-Agent

Im Bereich **Wissensbasis** kann der Agent zunächst nach Notizen suchen und
dann den vollständigen Markdown einer Notiz lesen. Beide Tools sind
team-begrenzt: Sie verwenden den aktuell angemeldeten Nutzer und
`GetCurrentTeamId`; teamübergreifende IDs werden nicht angenommen.

Notizinhalte gelten als untrusted Kontext. Sie dürfen die Systemanweisungen
nicht überschreiben. Der Agent kann deshalb über die Tools keine Daten ändern.

Für Erstellen, Bearbeiten und Löschen liefert Gemini stattdessen einen
strukturierten `knowledgeCommands`-Vorschlag. Die Assistant-UI zeigt ihn als
Plan und führt ihn erst nach **Ausführen** aus. Jede erfolgreiche Änderung
liefert eine Rückgängig-Aktion:

- Erstellen → die neue Notiz löschen
- Bearbeiten → den gespeicherten vorherigen Zustand wiederherstellen
- Löschen → die Notiz mit derselben ID wiederherstellen

## Interne Wissensbasis

Der MVP nutzt kein separates RAG. Aktuell unterstützt der interne Agent nur
zwei Bereiche:

- Aufgaben
- Wissensbasis

Die Wissensbasis wird als verbindliche Produktinformation in die
`systemInstruction` von Firebase AI Logic eingefügt. Dadurch bleibt der Agent
einfach, schnell änderbar und ohne zusätzliche Persistenz.

## URL Context

Der Agent aktiviert `Tool.urlContext()` für `gemini-3.5-flash`. Er kann damit
konkrete öffentliche URLs aus einer Frage zusammenfassen oder vergleichen.
Nackte Domains wie `laraevent.de` werden als `https://laraevent.de`
normalisiert.
URL Context ist kein Website-Crawler: Login-Bereiche, Paywalls und mehrseitige
Crawls werden nicht unterstützt. Webseiteninhalt gilt als untrusted Kontext und
kann die Systemanweisungen des Agenten nicht ändern.

## Offene Fragen

- Ob die interne Wissensbasis später aus Markdown-Assets oder vom Backend
  geladen wird.
- Ob Antworten und Verläufe pro Team persistiert werden sollen.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`wissensbasis.md`](./wissensbasis.md)
- [`../architecture.md`](../architecture.md)
