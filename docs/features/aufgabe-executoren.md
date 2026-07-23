# Aufgabe: Executor

> Fachliche Details der implementierten Node-Executor. Den Laufzeitvertrag
> beschreibt [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md).

## Modellprovider

Prompt-, Refinement- und Employee-Agent-Executor waehlen Modelle ausschliesslich
ueber `functions/src/task-runner/ai-models.ts`.

| `AI_PROVIDER` | Zweck |
| --- | --- |
| `google` | Gemini ueber `@genkit-ai/google-genai` |
| `minimax` | MiniMax ueber einen OpenAI-kompatiblen Provider |
| `openai-compatible` | Beliebiger kompatibler Cloud-Endpunkt |
| `local` | Lokaler OpenAI-kompatibler Server |

Google ist der Default. In einer Firebase Function verweist `127.0.0.1` auf
die Function-Instanz, nicht auf den Rechner der Nutzer:innen.

## Prompt

Der Prompt-Executor bietet die Output-Arten `text`, `decision` und
`structured`. Entscheidungen liefern die gewaehlte Option als `text`.
Strukturierte Prompts validieren ein required Zod-Object, legen jedes Feld als
benannten Output ab und schreiben die Gesamtstruktur als JSON in `text`.

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

Der Conditional-Executor nutzt den direkten Vorgaengeroutput als Ziellabel.
Er waehlt den Branch mit dem exakt passenden Label, ansonsten den ersten
Branch. Der Branch-Graph wird als Subgraph ausgefuehrt; dessen finale Ausgabe
wird `text` des Conditional-Knotens. Ausgehende Top-Level-Kanten sind nur ein
Legacy-Fallback.

## Iterative Verfeinerung

Der Refinement-Executor bewertet einen Entwurf in mehreren Runden mit
`{ critique, satisfied }` und verbessert ihn, bis die Bewertung erfuellt ist
oder `maxIterations` erreicht wird. Der Draft stammt aus dem Vorgaengeroutput;
`optimizerPrompt`, `critiquePrompt` und `maxIterations` steuern die Schleife.
Bei OpenAI-kompatiblen Providern existiert ein Text-JSON-Fallback fuer die
strukturierte Bewertung.

## Dateien und Kanaele

`readFile` gibt den UTF-8-Inhalt einer konkret referenzierten Version als
`text` aus. `writeFile` schreibt den Vorgaengeroutput als neue Datei oder
Version. Die strukturierten Datei-Outputs sind in
[`../node-executor-outputs.md`](../node-executor-outputs.md#datei-schreiben)
dokumentiert.

`readEmail` und `readChannelEvent` uebersetzen Run-Events in benannte Outputs.
`sendChannelMessage` sendet E-Mail, WhatsApp oder SMS und liefert unter anderem
Empfaenger-, Channel- und Provider-Nachrichten-ID. WhatsApp/SMS verwenden
Twilio, E-Mail SendGrid; die benoetigten Function-Secrets sind
`TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` und `SENDGRID_API_KEY`.

## Verwandt

- [`aufgabe.md`](./aufgabe.md)
- [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md)
- [`../node-executor-outputs.md`](../node-executor-outputs.md)
