# Prompt-Executor

> Der Prompt-Baustein kennt die Ausgabearten Text, Entscheidung, strukturiert und Bild; Genkit und Workspace hängen als Adapter hinter dem Port `PromptExecutor`.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **Text:** `value` (`string`).
- **Entscheidung:** gewählte Option aus den `choices` des Nutzers (fachlich
  ein Enum, kein Wahrheitswert) als `value`.
- **Strukturiert:** validiert ein Zod-Object; jedes Feld wird ein eigener
  Output mit eigenem Typ (`string`/`number`/`boolean` inklusive Koerzion,
  `datetime` nach ISO 8601, `json` als Text, der geparst wird).
  Felder, die das Modell zusätzlich liefert, fallen weg. Einen `value`
  gibt es nicht.
- **Bild:** Google GenAI mit `gemini-2.5-flash-image` (`GOOGLE_IMAGE_MODEL`).
  Ein vorangehender `media`-Wert geht als Genkit-Medienteil an Gemini; das
  Ergebnis wird Team-Datei und `media`-`value`. Data-URLs verlassen den
  Executor nicht. Secret `GEMINI_API_KEY`.
- **Ollama:** lokales Genkit-Modell; Genkit steuert den Aufruf, der native
  Adapter spricht `/api/chat`. Bilder als Ollama-Bilder, JSON-Schemas als
  geschlossenes `format` (`additionalProperties: false`), Generierungsoptionen als `options`/`think`. Werkzeuge
  gehen als Ollama-`tools`, Aufrufe kommen als `tool_calls` zurück; die Werkzeugschleife, Middleware und Tracing
  bleiben im Genkit-Kontrollfluss. Mit Werkzeugen entfällt `format` (die Grammatik ließe keine Aufrufe zu), die
  strukturierte Ausgabe verlangt Genkit dann über Anweisungen im Prompt.
- **Generierungsoptionen** (Temperatur, Antwortlänge, Kontextfenster,
  Nachdenken) pro Baustein: [Generierungsoptionen](./generierungsoptionen.md).
- **Prompt:** baut `prompt-node-prompt.ts` mit dem
  [LLM-Framework](./llm-aufruf-framework.md): englische Rolle („ein Schritt
  einer automatisierten Aufgabe, nur das Ergebnis“), ggf. Mitarbeiter,
  Anhänge, kurzer Formathinweis und Antwortsprache im Systemteil; die
  Anweisung wörtlich als `<task>`. Der Aufruf läuft über `LlmGateway`.
- Das Protokoll nennt pro Modellaufruf den gerenderten Prompt, die Optionen
  und die Zahl der Bilder; Bilder stehen nie im Eingabetext, sondern gehen
  als eigene Medienteile mit.
- Anweisungen nutzen `{{name}}` und Dot-Pfade (`{{kunde.name}}`); Anhänge im
  read-only Workspace. Transiente Modellfehler: exponentieller Backoff.
- Optional ein [Mitarbeiter](../index/mitarbeiter.md) **oder** eigene
  [Fähigkeiten](../index/faehigkeiten.md), nie beides.

Port: `PromptExecutor` (`PromptExecutionRequest` → `ResultAsync<PromptExecutionResult,
LanguageModelFailure>`), Adapter `GenkitPromptExecutor`. Der Node-Executor
(`genkit-prompt-node-executor.ts`) bereitet nur Workflow-Werte auf, speichert
Bildausgaben und gibt eine Failure als `err(NodeFailure)` an den Runner
([Fehlerschichtung](./fehlerschichtung-modellaufruf.md)).

## Siehe auch

- [Modellprovider für Prompt-Bausteine](./modellprovider-prompt.md)
- [Anhänge und Workspace](./anhaenge-workspace.md)
- [Entscheidungs-Prompt und Zweige](./entscheidungs-prompt-zweige.md)
- [Generierungsoptionen](./generierungsoptionen.md)
- [Fehlerschichtung eines Modellaufrufs](./fehlerschichtung-modellaufruf.md)
