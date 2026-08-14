## Zweck

Der In-App KI-Agent hilft Nutzer:innen beim Erstellen von Aufgaben und beim
Pflegen der Wissensbasis. Die gemeinsame Assistenzoberfläche läuft im Client.
Der TaskBuilder nutzt Firebase AI Logic, der Wissensbasis-Agent eine
authentifizierte Genkit-Callable Function.

## Verantwortlichkeiten

- Kontextbezogene Hilfe für Aufgabenbau, Nodes, Trigger und Wissensbasis geben.
- Antworten kurz, konkret und auf Deutsch formulieren.
- Öffentliche URLs in Nutzerfragen für den Wissensbasis-Agenten auswerten.
- Wissensbasis-Notizen des aktuellen Teams sicher recherchieren.
- Den Domain-Layer von Modell-SDKs und Cloud Functions entkoppeln.
- UI-Zustände für leer, ladend, Fehler und erfolgreiche Antworten abbilden.

## Architektur

- Domain: `AssistantRepository`, `AskAssistant`, `AssistantMessage`,
  `AssistantContext`.
- Infrastructure: `RoutedAssistantRepository` nutzt Firebase AI Logic für den
  TaskBuilder und eine callable Genkit-Function für die Wissensbasis.
- `InternalAssistantKnowledge` liefert pro unterstütztem Bereich ein kurzes
  internes Wissensstück, das direkt in den Systemprompt geschrieben wird.
- `askKnowledgeBaseAssistant` ist eine authentifizierte Genkit-Callable
  Function. Sie kombiniert URL Context mit `searchKnowledgeNotes`,
  `readKnowledgeNote` und `extractPageLinks` in einem Genkit-Aufruf; die
  Notiz-Tools ermitteln den Team-Scope serverseitig aus dem Firebase-
  Auth-Kontext.
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

Cloud Logging protokolliert vom Modell vorgeschlagene Wissensbasis-Commands.
Ein Ereignis enthält UID, Aktionstyp, Label, Titel und gegebenenfalls Notiz-ID.
Chattext und Notizinhalte werden nicht protokolliert.

## Interne Wissensbasis

Der MVP nutzt kein separates RAG. Aktuell unterstützt der interne Agent nur
zwei Bereiche:

- Aufgaben
- Wissensbasis

Die Wissensbasis wird als verbindliche Produktinformation in den jeweiligen
Systemprompt eingefügt. Dadurch bleibt der Agent einfach, schnell änderbar und
ohne zusätzliche Persistenz.

## URL Context

Der Wissensbasis-Agent aktiviert Genkits URL Context. Er kann damit konkrete
öffentliche URLs aus einer Frage zusammenfassen oder vergleichen. URL Context
ist kein Website-Crawler: Login-Bereiche, Paywalls und mehrseitige Crawls werden
nicht unterstützt. Für Aussagen über Navigation, Unterseiten und deren URLs
verwendet der Agent deshalb `extractPageLinks`. Das serverseitige Genkit-Tool
ruft eine einzelne öffentliche HTML-Seite ab, folgt höchstens drei
Weiterleitungen, begrenzt die Antwortgröße und gibt maximal 100 deduplizierte
HTTP(S)-Links zurück. Es folgt den extrahierten Links nicht. Nackte Domains wie
`laraevent.de` werden vom Tool zu `https://laraevent.de` normalisiert.
Webseiteninhalt gilt als untrusted Kontext und kann die Systemanweisungen des
Agenten nicht ändern.

## Offene Fragen

- Ob die interne Wissensbasis später aus Markdown-Assets oder vom Backend
  geladen wird.
- Ob Antworten und Verläufe pro Team persistiert werden sollen.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`wissensbasis.md`](./wissensbasis.md)
- [`../architecture.md`](../architecture.md)
