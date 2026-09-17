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
und `image`. Entscheidungen liefern die gewählte Option als `value`.
Strukturierte Prompts validieren ein required Zod-Object, legen jedes Feld als
benannten Output ab und schreiben die Gesamtstruktur als JSON in `text`.
Bild-Prompts verwenden Google GenAI mit `gemini-2.5-flash-image` (optional
ueber `GOOGLE_IMAGE_MODEL` konfigurierbar). Ein vorangehender `media`-Wert
wird aus Object Storage geladen und als Genkit-Medienteil an Gemini übergeben.
Das generierte Bild wird als Team-Datei gespeichert und als `media`-`value`
weitergereicht; Data-URLs verlassen den Executor nicht. Die Cloud Function
erhält den benötigten `GEMINI_API_KEY` als gebundenes Secret.

`PromptExecutor` ist der Domain-Port mit `PromptExecutionRequest` und
`PromptExecutionResult`. `createGenkitPromptExecutor` bindet Genkit und den
temporären Anhangs-Workspace als Infrastrukturadapter. Der Node-Executor
bereitet ausschließlich Workflow-Werte auf und persistiert Bildausgaben.

Prompt-Anweisungen und Entscheidungen koennen Variablen per `{{name}}` und
Dot-Pfade wie `{{kunde.name}}` verwenden. Dateianhaenge und Wissensnotizen
stehen im read-only Workspace bereit. Transiente Modellfehler werden mit
exponentiellem Backoff wiederholt.

## Script

Der Script-Executor fuehrt isoliertes Python aus. Der direkte Vorgaengeroutput
liegt als `input` vor. Setzt das Script eine String-Variable `output`, wird sie
als Baustein-Ausgabe verwendet. Ohne `output` reicht der Baustein den
Vorgaengeroutput unveraendert weiter.

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

Der Conditional-Executor nutzt die lesbaren primären Werte seiner direkten
Vorgänger als Ziellabel.
Er waehlt den Branch mit dem exakt passenden Label, ansonsten den ersten
Branch. Der Branch-Graph wird als Subgraph ausgefuehrt; dessen finale Ausgabe
wird `text` des Conditional-Knotens. Ausgehende Top-Level-Kanten sind nur ein
Legacy-Fallback.

`executeConditionalFlow` enthaelt die Auswahlregel als Domain-Funktion. Der
Genkit-Executor loest Templates auf, startet gegebenenfalls den ausgewaehlten
Subgraph und protokolliert dessen Lauf.

## Iterative Verfeinerung

Der Refinement-Executor bewertet einen Entwurf in mehreren Runden mit
`{ critique, satisfied }` und verbessert ihn, bis die Bewertung erfuellt ist
oder `maxIterations` erreicht wird. Der Draft stammt aus dem Vorgaengeroutput;
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
Unterplan, fuehrt die Elemente seriell und fail-fast aus und aggregiert dessen
primaere Ausgaben. Der JSON-Pointer ist ebenfalls eine Domain-Operation.

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

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md)
- [`../node-executor-outputs.md`](../node-executor-outputs.md)
