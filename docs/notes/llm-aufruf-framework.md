# Framework für LLM-Aufrufe

> Prompts entstehen abschnittsweise mit einem `PromptBuilder`, werden als XML-Tags gerendert und über einen einzigen Port `LlmGateway` ausgeführt; Protokoll und Fehlerübersetzung legen sich als Decorator darum.

Gehört zu: [Architektur](../index/architektur.md)

- **Ort:** Domain in `functions/src/features/language_models/domain/prompting/`
  (reines TypeScript), Genkit-Adapter in
  `functions/src/features/language_models/infrastructure/genkit/llm/`.
- **Abschnitte** (`prompt-section.ts`) mit fester Reihenfolge und Zielteil:
  - System: `role`, `rules`, `employee`, `attachments`, `reference` (benannt,
    mehrfach), `output_format`, `response_language`
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
- **Gateway:** `LlmRequest {binding, prompt, label, output}`; das Binding
  trägt auch Werkzeuge, `maxTurns` und ein fortgesetztes Gespräch
  (`continuation`, aus `LlmResponse.conversation`); Textfelder dürfen mit
  `allowEmpty` leer bleiben;
  `output` ist `text`, `choice`, `structured`, `image` oder `schema` (ein
  fertiges Schema der Infrastruktur, für die Domain opak) — das Schema baut
  sonst der Adapter (`llm-output-schema.ts`), der Prompt nennt das Format nur
  kurz. `GenkitLlmGateway` ist der einzige Aufruf von `ai.generate`.
- **Decorators** (`llm-gateway-factory.ts`): außen Fehlerübersetzung
  (`withTranslatedGenkitErrors`), darin das Protokoll mit dem gerenderten
  Prompt (`LlmCallLog`; im Ausführungsprotokoll `ReadableLlmCallLog`).
  Retry bleibt Middleware je Modellanfrage (`languageModelRetry`).
- Die Skills-Middleware von Genkit fügt dem Systemteil ihren eigenen
  `<skills>`-Block hinzu; das passt zum XML-Format.

## Stand der Umstellung

Alle LLM-Aufrufe laufen über das Framework:

- **Aufgabenausführung:** [Prompt-Baustein](./prompt-executor.md)
  (`prompt-node-prompt.ts`), [Iterative Verfeinerung](./iterative-verfeinerung.md)
  (`iterative-refinement-prompts.ts`) und [Teamarbeit](./teamwork-ausfuehrung.md)
  (Orchestrator, Prüfung, Systemteil und Aufträge der Mitglieder). Gemeinsame
  Formulierungen (Anhänge, Verweis auf den Mitarbeiter) stehen in
  `workflow-prompt-sections.ts`; die Rolle verweist nur auf `<employee>`, wenn
  es eine Rahmenbedingung gibt.
- **In-App-Agenten:** Aufgabenstudio-Agent und Wissensbasis-Agent über
  `GenkitAssistantResponder` (Verlauf aus dem Client als `history`, Ausgabeart
  `schema` für das Zod-Schema mit Commands, Aktionskontext für die Werkzeuge),
  die drei Subagenten über `defineSubagentTool`
  ([Antwortsprache des Agenten](./agent-antwortsprache.md)).
- Mitglieder der Teamarbeit führen ein zustandsbehaftetes Genkit-Gespräch
  (`EmployeeConversation`); sie nutzen Builder und Renderer, aber nicht den
  Gateway — ohne Protokoll und Fehlerübersetzung je Turn.
- Protokoll: Aufrufe der Aufgabenausführung erscheinen im Ausführungsprotokoll
  (`ReadableLlmCallLog`); die Agenten laufen mit `silentLlmCallLog`.

## Siehe auch

- [Fehlerschichtung eines Modellaufrufs](./fehlerschichtung-modellaufruf.md)
- [Antwortsprache des Agenten](./agent-antwortsprache.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
