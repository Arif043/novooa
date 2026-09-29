## Zweck

Der In-App KI-Agent hilft Nutzer:innen beim Erstellen von Aufgaben und beim
Pflegen der Wissensbasis. Die gemeinsame Assistenzoberfläche läuft im Client.
TaskBuilder und Wissensbasis-Agent nutzen jeweils eine authentifizierte
Genkit-Callable Function.

**Läuft in Cloud und Standalone.** `WorkspaceCapabilities.assistant` (siehe
[`../architecture/betriebsvarianten.md`](../architecture/betriebsvarianten.md),
Blocker 6) steht für beide Varianten auf `true`. Die lokale Runtime bedient
denselben Anfrage-/Antwort-Vertrag wie die Firebase Callable Functions über
`POST /v1/assistant/task-builder` und `POST /v1/assistant/knowledge-base`
(`LocalAssistantHttpHandler`). Wiederverwendet werden dabei die bereits
Firebase-entkoppelten Bausteine der Backend-Domain — `GenkitAssistantResponder`,
die reinen `createTaskBuilderAssistant`/`createKnowledgeBaseAssistant`-
Factories — sowie die für die Aufgaben-Ausführung ohnehin vorhandene lokale
Infrastruktur: `SQLiteKnowledgeBaseAssistantNoteStore`,
`SQLiteTeamContextStore` und der Standardmodell-Pfad aus `ai-models.ts`
(dasselbe Sprachmodell, das "Standardmodell verwenden" in Prompt-Bausteinen
nutzt). Ausgelassen ist bewusst nur das Audit-Logging der Cloud-Variante —
das dient dort der teamübergreifenden Aufsicht, für einen einzelnen
Standalone-Betreiber ohne Mehrwert.

## Verantwortlichkeiten

- Kontextbezogene Hilfe für Aufgabenbau, Nodes, Trigger und Wissensbasis geben.
- Antworten kurz, konkret und auf Deutsch formulieren.
- Öffentliche URLs in Nutzerfragen für den Wissensbasis-Agenten auswerten.
- Wissensbasis-Notizen des aktuellen Teams sicher recherchieren.
- Den Domain-Layer von Modell-SDKs und Cloud Functions entkoppeln.
- UI-Zustände für leer, ladend, Fehler und erfolgreiche Antworten abbilden.

## Architektur

- Client-Domain: `AssistantRepository`, `AskAssistant`, `AssistantMessage`,
  `AssistantContext`.
- Backend-Domain: `AssistantActor`, `AssistantMessage`, `AssistantRequest`,
  `AssistantExecutionContext`, der Port `AssistantResponder` und der Use Case
  `AskAssistant`. Diese Typen kennen weder Firebase noch Genkit.
- Client-Infrastructure: `RoutedAssistantRepository` wählt nur noch zwischen
  den zwei typisierten Callable-Datasources. `FirebaseFunctionsAssistantDatasource`
  kapselt Auth, Timeout, Verlauf und die Response-Validierung einmal zentral.
- Backend-Infrastructure: `GenkitAssistantResponder` implementiert den
  Backend-Port einmalig. Die bereichsspezifischen Factory-Funktionen liefern
  nur Modell, Prompt, Tools und den Response-Parser.
- `askTaskBuilderAssistant` und `askKnowledgeBaseAssistant` sind
  authentifizierte Genkit-Callable Functions. Beide verwenden `GEMINI_API_KEY`,
  dieselbe Modellkonfiguration und denselben serverseitigen Laufzeitkontext.
- Der TaskBuilder-Agent generiert nur Vorschläge für `renameTask` und
  `addNode`; die bestehende interaktive Ausführung im Client bleibt unverändert.
- Die Wissensbasis kombiniert URL Context mit `searchKnowledgeNotes`,
  `readKnowledgeNote` und `extractPageLinks`; die Notiz-Tools ermitteln den
  Team-Scope serverseitig aus dem Laufzeitkontext.
- Die Tool-Definitionen und der öffentliche HTTP/HTML-Adapter liegen unter
  `knowledge_base/infrastructure/genkit`. Firebase verdrahtet sie mit
  Firestore und Firebase Auth; eine lokale Runtime kann dieselben Definitionen
  mit SQLite- und lokaler Identitätsadaptern registrieren.
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

Der MVP nutzt kein separates RAG. Die bereichsspezifischen Prompts enthalten
das relevante Produktwissen direkt und unterstützen aktuell zwei Bereiche:

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
