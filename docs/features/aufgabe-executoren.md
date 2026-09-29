# Aufgabe: Executor

> Fachliche Details der implementierten Node-Executor. Den Laufzeitvertrag
> beschreibt [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md).

## Modellprovider

Prompt-, Refinement- und Employee-Agent-Executor waehlen Modelle ausschliesslich
ueber `functions/src/features/task_execution/infrastructure/genkit/runner/ai-models.ts`.

Prompt-Bausteine können zusätzlich ein teamweites Sprachmodellprofil über
`languageModelId` auswählen. Das Profil wird zur Run-Zeit aufgelöst und
verwendet seine eigene Provider-Verbindung; ohne Auswahl bleibt das bisherige
Standardmodell als Legacy-Fallback aktiv.

| `AI_PROVIDER` | Zweck |
| --- | --- |
| `google` | Gemini ueber `@genkit-ai/google-genai` |
| `minimax` | MiniMax ueber einen OpenAI-kompatiblen Provider |
| `openai-compatible` | Beliebiger kompatibler Cloud-Endpunkt |
| `local` | Lokaler OpenAI-kompatibler Server |

Google ist der Default. In einer Firebase Function verweist `127.0.0.1` auf
die Function-Instanz, nicht auf den Rechner der Nutzer:innen.

## Prompt

Der Prompt-Executor bietet die Output-Arten `text`, `decision`, `structured`
und `image`. Entscheidungen liefern die gewählte Option (ein Wert aus den vom
Nutzer definierten `choices` — fachlich ein Enum, kein Wahrheitswert) als
`value`. Strukturierte Prompts validieren ein required Zod-Object und legen
jedes Feld als benannten Output ab; jedes Feld trägt einen eigenen Typ
(`string`/`number`/`boolean`), der das Zod-Schema pro Feld steuert (inkl.
Koerzion bei `number`/`boolean`) und den resultierenden Workflow-Ausgabewert
entsprechend taggt, statt wie zuvor immer `string`. Die Gesamtstruktur wird
zusätzlich als `json`-`value` bereitgestellt.
Bild-Prompts verwenden Google GenAI mit `gemini-2.5-flash-image` (optional
ueber `GOOGLE_IMAGE_MODEL` konfigurierbar). Ein vorangehender `media`-Wert
wird aus Object Storage geladen und als Genkit-Medienteil an Gemini übergeben.
Das generierte Bild wird als Team-Datei gespeichert und als `media`-`value`
weitergereicht; Data-URLs verlassen den Executor nicht. Die Cloud Function
erhält den benötigten `GEMINI_API_KEY` als gebundenes Secret.

Bei einer Ollama-Verbindung registriert die Runtime ein lokales Genkit-Modell. Genkit steuert den gesamten Prompt-Aufruf und delegiert nur den Provider-Transport ueber einen nativen Ollama-Adapter an `/api/chat`. Bild-Data-URLs werden als Ollama-Bilder uebertragen; Entscheidungen und strukturierte Ausgaben reichen das von Genkit erzeugte JSON-Schema als natives `format` weiter. Middleware, Tracing und eine spaetere Werkzeugschleife bleiben damit im Genkit-Kontrollfluss.

`PromptExecutor` ist der Domain-Port mit `PromptExecutionRequest` und
`PromptExecutionResult`. `createGenkitPromptExecutor` bindet Genkit und den
temporären Anhangs-Workspace als Infrastrukturadapter. Der Node-Executor
bereitet ausschließlich Workflow-Werte auf und persistiert Bildausgaben.

Prompt-Anweisungen und Entscheidungen koennen Variablen per `{{name}}` und
Dot-Pfade wie `{{kunde.name}}` verwenden. Dateianhaenge und Wissensnotizen
stehen im read-only Workspace bereit. Transiente Modellfehler werden mit
exponentiellem Backoff wiederholt.

## Script

Der Script-Executor fuehrt isoliertes Python aus. Sein `input` wird aus dem
expliziten Feld `inputTemplate` aufgeloest. Setzt das Script eine String-
Variable `output`, wird sie als Baustein-Ausgabe verwendet.

```python
output = input.upper()
```

Das Limit betraegt fuenf Sekunden und 10 KB Output. Script-Variablen bleiben
innerhalb desselben Runs erhalten und stehen spaeteren Scripts wieder zur
Verfuegung.

Im Web-Editor prüft Tree-sitter mit einer lokal ausgelieferten Python-Wasm-
Grammatik die Syntax und zeigt Fehler im Gutter. Diese Prüfung läuft vollständig
im Browser, führt keinen Code aus und ersetzt keine Laufzeitprüfung des
Script-Executors.

```python
files
list_files()
read_file(display_name)
```

## Bedingter Ablauf

Die Branch-Auswahl kennt zwei unabhängige Pfade — welcher greift, entscheidet
sich pro Knoten daran, ob irgendein Branch ein `condition` trägt:

**Label-Matching** (Entscheidungs-Prompt-Vorgänger oder Altdaten): Der
Conditional-Executor löst sein explizites `valueTemplate` als Ziellabel auf
und waehlt den Branch mit dem exakt passenden Label, ansonsten den ersten
Branch (`executeConditionalFlow`, Domain-Funktion). Trägt ein direkt
vorgeschalteter Entscheidungs-Prompt eine Entscheidung bei, hält
`_syncConditionalSuccessors` `valueTemplate`/Branch-Labels automatisch mit
dessen `choices` synchron.

**Baukasten-Bedingungen** (kein Entscheidungs-Prompt-Vorgänger): Jeder Branch
trägt stattdessen einen eigenen booleschen Ausdrucksbaum (`BranchCondition`:
Vergleich `left`/`operator`/`right` oder Gruppe mit AND/OR/XOR-verknüpften
Kindern, beliebig verschachtelt — Verschachtelung ersetzt Klammern).
`selectConditionedBranch`/`evaluateBranchCondition`
(`branch-condition-evaluator.ts`) werten die Branches der Reihe nach aus und
wählen den ersten zutreffenden; ein Branch ohne `condition` ("Sonst") ist der
garantierte, in der UI erzwungene Fallback — kein stiller Rückfall auf den
ersten Branch wie beim Label-Matching. Operanden werden über
`resolveValue` (nicht `resolveText`) als Rohwert aufgelöst, damit echte
Zahlen-/Boolean-Vergleiche möglich sind; nicht-typisierte Werte werden beim
Vergleich ad-hoc koerziert. Der Baukasten-Editor
(`ConditionalBranchesEditor`) ersetzt für diesen Fall die frühere einzelne
"Wenn"-Freitexteingabe.

In beiden Faellen wird der Branch-Graph durch denselben Graph-Runner
ausgefuehrt; dessen finale Ausgabe wird `value` des Conditional-Knotens.
Ausgehende Top-Level-Kanten sind nur ein Legacy-Fallback.

## Iterative Verfeinerung

Der Refinement-Executor bewertet einen Entwurf in mehreren Runden mit
`{ critique, satisfied }` und verbessert ihn, bis die Bewertung erfuellt ist
oder `maxIterations` erreicht wird. Der Draft stammt ausschließlich aus
`draftTemplate`; ist dieses leer, erhält der Baustein einen leeren Entwurf.
`optimizerPrompt`, `critiquePrompt` und `maxIterations` steuern die Schleife.
Bei OpenAI-kompatiblen Providern existiert ein Text-JSON-Fallback fuer die
strukturierte Bewertung.

`IterativeRefinementExecutor` kapselt dafür die fachlichen Ein- und
Ausgabewerte. `createGenkitIterativeRefinementExecutor` implementiert den Port
mit Genkit, inklusive strukturierter Bewertung und Text-Fallback.

## Script

`ScriptExecutor` beschreibt die Eingabe, Variablen und Ausgabe eines Scripts.
`createPythonScriptExecutor` führt die isolierte Python-Subprocess-Runtime aus.
`createScriptNodeExecutor` liegt in der Domain, übergibt nur aufgelöste
Workflow-Werte an diesen Port und liefert dessen Ausgabe zurück. Die
Genkit-Registry bindet die Python-Runtime, den temporären Workspace und das
Protokollieren der Script-Ausgabe.

`forEach` verwendet `executeForEach` aus der Domain. Die Funktion validiert den
Unterplan, fuehrt die durch `itemsTemplate` und JSON-Pointer bestimmten Elemente
seriell und fail-fast aus und aggregiert dessen primaere Ausgaben. Der aktuelle
Wert wird ausschließlich als `iteration`-Scope in den Unterplan injiziert.

`modelInference`, Dateioperationen und das Senden von Nachrichten verwenden
bereits `ModelInference`, `TeamFileStore` beziehungsweise `TaskMessageSender`
als Domain-Ports. `modelInference`, `readFile`, `forEach`, Eingaben,
Ereignislesen und Pausen sind deshalb Domain-Executor. Deterministische
Bausteine wie Eingabe, Bedingung und Freigabe benötigen keinen eigenen
externen Executor-Port.

## Daten

`documentLookup` und `saveDocument` hängen ausschließlich am fachlichen
`DocumentStore`-Port. Die lokale Runtime injiziert dessen SQLite-Adapter in
den Graph-Runner. Ein Suchfehler wird als fachlicher Output zurückgegeben,
damit ein Arbeitsplan ihn mit dem vorhandenen Wenn-dann-Baustein behandeln
kann. Ein Speicherfehler bleibt dagegen ein Run-Fehler; so wird kein
unvollständig gespeicherter Datensatz als Erfolg ausgegeben.

Der Speichern-Executor stellt die benannte Datensammlung vor dem Speichern atomar sicher. Fehlt sie, wird sie für das aktive Team implizit angelegt; bei wiederholten Ausführungen bleibt sie unverändert. Ohne Fachbedingungen ist der Modus Anlegen aktiv und er erzeugt immer einen neuen Datensatz. Sobald mindestens eine Bedingung konfiguriert ist, verwendet er den Modus Aktualisieren oder anlegen: Er findet alle passenden Datensätze, aktualisiert sie mit den sichtbaren Feldzuordnungen und verwendet ihre IDs und Versionsstände ausschließlich intern. Ohne Treffer legt er einen neuen Datensatz an.

## Dateien und Kanaele

`readFile` gibt den UTF-8-Inhalt einer konkret referenzierten Version als
`value` aus. `writeFile` schreibt einen Textwert oder eine Datei-/Medienreferenz als neue Datei oder
Version. Die strukturierten Datei-Outputs sind in
[`../node-executor-outputs.md`](../node-executor-outputs.md#datei-schreiben)
dokumentiert.

`readEmail` und `readChannelEvent` uebersetzen Run-Events in benannte Outputs.
Microsoft-Graph-Connectoren liefern neue E-Mails per Webhook als Run-Event.
Gmail ist noch nicht implementiert.

`sendChannelMessage` liefert Empfaenger-, Channel- und
Provider-Nachrichten-ID. WhatsApp und SMS verwenden Twilio. Novooa verwendet
SendGrid ausschliesslich als globalen System-E-Mail-Dienst;
Arbeitspläne können SendGrid nicht verwenden.
Bei einem Microsoft-Graph-E-Mail-Event nutzt der Sende-Baustein ohne explizite
`connectorId` automatisch das auslösende Postfach und setzt den Betreff auf
`Re: <eingehender Betreff>`. Ein unabhängig gestarteter E-Mail-Baustein
benötigt eine `connectorId` eines aktiven Mail-Connectors.

## Push-Benachrichtigung

`notificationSend` sendet einen aufgelösten Text als Push-Benachrichtigung an
alle Nutzer:innen des aktuellen Teams. Der optionale `title` wird ebenfalls
als Template aufgelöst; ohne Wert verwendet der Baustein
„Benachrichtigung von novooa“. Ein leerer aufgelöster Text ist ein Run-Fehler.
Reiner Seiteneffekt ohne fachlichen Rückgabewert — der gesendete Text ist dem
Graphen durch die eigene Konfiguration bereits bekannt, ein Echo als Output
würde nur einen nicht vorhandenen neuen Wert suggerieren (siehe
[`../node-executor-outputs.md`](../node-executor-outputs.md)). Der Baustein
bekommt deshalb auch keinen Ausgabenamen im Aufgabenstudio.

Der Baustein hängt am fachlichen `TeamNotificationSender`-Port. In der Cloud
löst `FirebaseTeamNotificationSender` die Team-Mitglieder-UIDs über
`TeamMembershipStore.memberUids` auf und sendet je Mitglied über
`PushNotificationSender.sendToRecipient` (fehlerhafte Einzelzustellungen
werden dort bereits protokolliert und brechen die übrigen Zustellungen
nicht ab). Die lokale Runtime kennt keine einzelnen Mitglieder-UIDs, sondern
nur die beim Push-Relay registrierten Geräte der aktiven Lizenz; ein Team
entspricht dort einem Arbeitsbereich, daher sendet `LocalTeamNotificationSender`
einmalig über den bestehenden `RuntimePushRelayClient`.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md)
- [`../node-executor-outputs.md`](../node-executor-outputs.md)
