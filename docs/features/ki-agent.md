## Zweck

Der In-App KI-Agent hilft Nutzer:innen beim Erstellen von Aufgaben und beim
Pflegen der Wissensbasis. Die gemeinsame Assistenzoberfläche läuft im Client.
TaskBuilder und Wissensbasis-Agent nutzen jeweils eine authentifizierte
Genkit-Callable Function.

**Läuft in Cloud und Standalone — aber die beiden Agenten an verschiedenen
Orten.** `WorkspaceCapabilities.assistant` (siehe
[`../architecture/betriebsvarianten.md`](../architecture/betriebsvarianten.md),
Blocker 6) steht für beide Varianten auf `true`; die App spricht in Standalone
weiter mit der Runtime (`POST /v1/assistant/task-builder` und
`/v1/assistant/knowledge-base`, `assistantRoutes`).

| Agent | Cloud-Variante | Standalone (lokale Runtime) |
| --- | --- | --- |
| **Aufgabenstudio** | Callable `askTaskBuilderAssistant`, Modell aus Remote Config | Die Runtime reicht Frage und Verlauf über das Relay `localRuntimeTaskBuilderRelay` an den Agenten in der Cloud; Modell aus Remote Config |
| **Wissensbasis** | Callable `askKnowledgeBaseAssistant`, Notizen aus Firestore, Modell aus Remote Config | Läuft **in der Runtime** mit den Notizen aus SQLite und dem **Sprachmodell des Nutzers** |

Gründe: Der Aufgabenstudio-Agent braucht keine lokalen Daten und läuft deshalb
mit dem Modell des Betreibers. Der Wissensbasis-Agent liest die Notizen des
Nutzers; sie sollen das Gerät nicht verlassen. Er nutzt darum ein Modell des Nutzers
(`resolveDefaultLanguageModel`): das, was dieser unter Einstellungen →
„Sprachmodelle“ als **Sprachmodell des Wissensbasis-Agenten** gewählt hat
(`LanguageModelDefaults.knowledgeAssistantModelId`, nur in der Runtime sichtbar),
sonst sein **Standardmodell**. Ohne beides — oder wenn das Modell gelöscht
wurde — bekommt er den Hinweis, eines zu verbinden und zu wählen; es gibt keinen
Rückfall auf ein Modell des Betreibers. Ausgelassen ist bewusst nur das Audit-Logging der Cloud-Variante
in der Runtime — es dient dort der teamübergreifenden Aufsicht.

## Sprachmodell des Agenten in der Cloud

Den Modellnamen legt die Cloud fest. Er steht als String im Firebase-Remote-
Config-Parameter **`assistant_model`** (Server-Template), zum Beispiel
`gemini-3.1-flash-lite` (der Standard im Code); es sind Google-Modelle (Gemini
API). Ältere Modelle werden von Google abgeschaltet und für neue Projekte
abgelehnt — dann scheitert jede Anfrage des Agenten mit einem 404; der Name in
Remote Config muss ein aktuell verfügbares Modell sein. Nutzer:innen wählen ihn
nicht, und es gibt keine Auswahl pro Team. Die Cloud-Funktionen
(`runTaskBuilderAssistant`, `askKnowledgeBaseAssistant`) lesen ihn über
`RemoteConfigAssistantModel` und cachen ihn fünf Minuten
(`CachedAssistantModelSettings`); eine Änderung in der Console wirkt also
spätestens nach fünf Minuten, ohne Deploy.

- Leer, nicht vorhanden oder ungültig (erlaubt sind Kleinbuchstaben, Ziffern,
  `.`, `-`, `_`): Es gilt das Standardmodell aus `ai-models.ts`
  (`GOOGLE_TEXT_MODEL` bzw. der eingebaute Standardwert).
- Ein unbekannter, aber gültig geschriebener Name wird nicht vorab geprüft; die
  Anfrage scheitert dann bei Google mit einer Fehlermeldung.
- Remote Config nicht erreichbar: Der zuletzt bekannte Wert bleibt, zuerst
  keiner; nach 30 Sekunden wird erneut versucht.

### Relay für lokale Runtimes

`localRuntimeTaskBuilderRelay` (`onRequest`, 120 s) prüft die signierte Lizenz
der Runtime (`FirebaseRuntimeRelayLicenseVerifier`), führt denselben Agenten
wie die App aus (`runTaskBuilderAssistant`) und liefert dieselbe Antwort
(`answer`, `commands`, `knowledgeCommands`). Die Runtime kennt die URL über
`LOCAL_RUNTIME_TASK_BUILDER_RELAY_URL` (im Compose-Betrieb vorbelegt). Ohne URL
oder Lizenz meldet sie einen lesbaren Fehler.

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
  Er ist ein Orchestrator mit Subagenten, siehe
  [Multiagenten-Architektur](#multiagenten-architektur-aufgabenstudio).
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

## Multiagenten-Architektur (Aufgabenstudio)

Der Aufgabenstudio-Agent ist ein **Orchestrator**. Er führt das Gespräch und
liefert als Einziger `answer` und `commands`. Facharbeit delegiert er an drei
Subagenten. Jeder Subagent ist für ihn ein Tool („Agents as Tools“) mit eigenem
System-Prompt, eigenen Tools und einem Zod-Ausgabeschema.

| Subagent (Tool) | Aufgabe | Tools | Ausgabe |
| --- | --- | --- | --- |
| `anforderungsanalyse` | Zerlegt einen Automatisierungswunsch in Bausteine und kennt dafür das Produktwissen (`novooa-product-knowledge.ts`) | keine | Ziel, Auslöser, Schritte (mit `umsetzbar`), offene Fragen, `benoetigtModell`, `benoetigtScript` |
| `modellkatalog_suche` | Findet passende ONNX-Modelle für `modelInference` | `sucheModelle` (lesend, `SearchModelCatalog`) | bis zu drei Vorschläge mit `modelId`, Begründung, Ein- und Ausgaben |
| `python_entwicklung` | Schreibt Code für den Script-Baustein (`input`, `output`, `workflow_output`) | keine | `script`, `inputTemplate`, `workflowOutputs`, `hinweise` |

- **Ablauf:** Bei einem Automatisierungswunsch ruft der Orchestrator zuerst die
  Anforderungsanalyse auf. Je nach Profil folgen Modellsuche und
  Python-Entwicklung, unabhängige Aufrufe parallel. Offene Fragen stellt er in
  `answer`, statt zu raten.
- **Nur Vorschläge:** Subagenten haben keine verändernden Tools. Änderungen
  bleiben `commands` und werden erst nach **Ausführen** angewendet.
  `addNode` mit `primitive: script` trägt `script` und `inputTemplate`.
- **Kein Ausführen von Code:** Der Python-Subagent führt nichts aus.
  `scriptDraftProblems` (Domain) prüft den Entwurf statisch (Ausgabenamen,
  Typen, deklarierte `workflow_output`-Aufrufe). Funde erscheinen als
  `Prüfung: …` in `hinweise`.
- **Grenzen:** Pro Anfrage gibt es höchstens fünf Delegationen
  (`DelegationBudget`). Subagenten haben 1–4 Tool-Runden, der Orchestrator 8.
  Callable und Relay laufen höchstens 120 s.
- **Fehler:** Ein fehlgeschlagener Subagent liefert `{ok: false, grund}` als
  Tool-Antwort. Der Orchestrator arbeitet ohne ihn weiter und sagt, was fehlt.
- **Team-Bezug:** Der Callable löst das aktive Team auf; die Modellsuche umfasst
  dann System- und Team-Modelle. Das Relay kennt kein Team (`teamIdForActor`
  liefert `null`) und sucht nur im globalen Katalog.
- **Umsetzung:** `defineSubagentTool` (`assistant/infrastructure/genkit/subagents`)
  erzeugt pro Anfrage ein `ai.dynamicTool`. Modell und Budget gelten so nur für
  diese Anfrage. Die Specs liegen im jeweiligen Feature:
  `machine_learning/infrastructure/genkit/model-catalog-subagent.ts` und
  `task_execution/infrastructure/genkit/assistant/subagents/`. Alle Subagenten
  nutzen das Modell aus `assistant_model`. Delegationen erscheinen als
  verschachtelte Spans im Genkit-Trace.

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

- Aufgaben: `RenameTaskAgentCommand`, `AddNodeAgentCommand`,
  `ConfigureNodeAgentCommand`
- Wissensbasis: `CreateKnowledgeNoteAgentCommand`,
  `UpdateKnowledgeNoteAgentCommand`, `DeleteKnowledgeNoteAgentCommand`

### Antwortsprache

Der Client sendet `locale` (`en`/`de`/`tr`, aus `AssistantContext.languageCode`) im Anfragekörper
(Callable, Runtime-Route und Relay). `promptWithAnswerLanguage` hängt die Antwortsprache an den
Nutzerprompt; `answer` und Command-Labels folgen ihr. Fehlt `locale` (ältere Clients), bleibt der
Agent beim bisherigen Deutsch. Die System-Prompts selbst sind noch deutsch.

### Aufgabenstudio-Commands und Agent-Cursor

| Command | Argumente | Wirkung |
| --- | --- | --- |
| `renameTask` | `title` | Aufgabe umbenennen |
| `addNode` | `primitive`, `kind`, `ref`, Feldwerte (`title`, `value`, `instruction`, …) | Baustein anlegen und direkt befüllen |
| `configureNode` | `nodeRef`, `fields` | Eingabemaske eines Bausteins befüllen |

`ref` ist eine plan-lokale Kennung: Node-IDs entstehen erst beim Ausführen,
`configureNode.nodeRef` zeigt deshalb auf das `ref` eines `addNode` im selben
Plan. Erlaubte Feldschlüssel (`NodeFieldKey`): `title`, `description`,
`outputName`, `value`, `instruction`, `modelId`, `recipient`, `message`,
`script`, `inputTemplate`; andere Schlüssel verwirft das Backend.
`outputName` ist im Agenten-Protokoll der Name des Hauptwerts; der Client
schreibt ihn in den `WorkflowOutput` mit dem Schlüssel `value`.
`configureNode` auf bereits bestehende Bausteine setzt voraus, dass der Client
deren IDs und Werte an den Agenten übermittelt – das ist noch offen.

**Der Agent liefert nur Fachliches.** Auswählen, Hinfahren, Klicken und Tippen
erzeugt der Client selbst: Beim Ausführen reicht `AssistantActionPlan` den
`AgentCursorPerformer` (aus `AgentCursorScope`) an den `AssistantPlanExecutor`.
Aktionen, die `CursorAwarePlanAction` implementieren, bedienen die Oberfläche
sichtbar; `NodeFieldPlayer` wählt den Baustein, fährt den Cursor an das Feld
(`AgentCursorAnchor`) und tippt schrittweise in den Cubit. Fehlt ein Anker oder
sind Animationen reduziert, springt der Cursor bzw. wird übersprungen; die
Änderung hängt nie am Cursor. Der Cursor gehört zum Aufgabenstudio
(`TaskBuilderShellFrame`), nicht zur Wissensbasis.

**Cursor ohne LLM testen:** Im Debug-Modus beantwortet `AssistantCubit` die
Eingabe `/mock` mit einem festen Plan (`MockAssistantReplies`: umbenennen, drei
Bausteine anlegen, Prompt befüllen) und ruft kein Modell auf. Im Release-Build
ist der Pfad inaktiv.

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
ohne zusätzliche Persistenz. Das Baustein-Wissen der Anforderungsanalyse steht
in `novooa-product-knowledge.ts` und muss mit
[`aufgabe.md`](./aufgabe.md#primitives) § Primitives übereinstimmen.

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
