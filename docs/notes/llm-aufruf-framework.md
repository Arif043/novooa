# Framework für LLM-Aufrufe

> Prompts entstehen abschnittsweise mit einem `PromptBuilder`, werden als XML-Tags gerendert und über einen einzigen Port `LlmGateway` ausgeführt; Protokoll und Fehlerübersetzung legen sich als Decorator darum.

Gehört zu: [Architektur](../index/architektur.md)

- **Ort:** Domain in `functions/src/features/language_models/domain/prompting/`
  (reines TypeScript), Genkit-Adapter in
  `functions/src/features/language_models/infrastructure/genkit/llm/`.
- **Abschnitte** (`prompt-section.ts`) mit fester Reihenfolge und Zielteil:
  - System: `role`, `rules`, `employee`, `attachments`, `output_format`,
    `response_language`
  - Nutzer: `task`, `context` (benannt, mehrfach)

  Die Reihenfolge folgt der Art, nicht der Aufrufreihenfolge. Leere
  Abschnitte fallen weg; Bilder gehen als Medienteile, der Verlauf als
  `messages` mit.
- **`PromptBuilder`:** unveränderlich, jede Methode liefert einen neuen
  Builder (`.role() .employee() .attachments() .outputFormat()
  .responseLanguage() .task() .context() .media() .history() .build()`).
- **Renderer** als Strategie (`PromptRenderer`); Standard ist
  `XmlPromptRenderer`: `<task>…</task>`, `<context name="rechnung">…</context>`.
  Warum XML: Tags grenzen eingebettete Nutzerdaten (Notizen, Mails,
  Template-Werte mit eigenen Überschriften) eindeutig ab. Ein schließender
  Tag desselben Abschnitts im Inhalt wird entschärft (`<\/task>`), Namen
  werden als Attribut maskiert.
- **Feste Texte englisch**, die Antwort folgt der Sprache der Aufgabe
  (`response_language`, Richtlinie `sameAsTask`) oder einer festen Sprache
  (`en`/`de`/`tr`). Die Anweisung des Nutzers bleibt wörtlich.
- **Gateway:** `LlmRequest {binding, prompt, label, output}`;
  `output` ist `text`, `choice`, `structured` oder `image` — das Schema baut
  der Adapter (`llm-output-schema.ts`), der Prompt nennt das Format nur
  kurz. `GenkitLlmGateway` ist der einzige Aufruf von `ai.generate`.
- **Decorators** (`llm-gateway-factory.ts`): außen Fehlerübersetzung
  (`withTranslatedGenkitErrors`), darin das Protokoll mit dem gerenderten
  Prompt (`LlmCallLog`; im Ausführungsprotokoll `ReadableLlmCallLog`).
  Retry bleibt Middleware je Modellanfrage (`languageModelRetry`).
- Die Skills-Middleware von Genkit fügt dem Systemteil ihren eigenen
  `<skills>`-Block hinzu; das passt zum XML-Format.

## Stand der Umstellung

- Umgestellt: [Prompt-Baustein](./prompt-executor.md)
  (`prompt-node-prompt.ts`).
- Geplant: Iterative Verfeinerung, Teamarbeit (Orchestrator, Prüfung,
  Mitglieder), Aufgabenstudio-Agent und seine Subagenten,
  Wissensbasis-Agent.

## Siehe auch

- [Fehlerschichtung eines Modellaufrufs](./fehlerschichtung-modellaufruf.md)
- [Antwortsprache des Agenten](./agent-antwortsprache.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
