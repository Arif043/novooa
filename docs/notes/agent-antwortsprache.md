# Antwortsprache des Agenten

> Der Client sendet die App-Sprache als `locale`; Antwort und Command-Labels folgen ihr.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- `locale` (`en`/`de`/`tr`, aus `AssistantContext.languageCode`) im
  Anfragekörper von Callable, Runtime-Route und Relay.
- Die Agenten bauen ihre Prompts mit dem
  [LLM-Framework](./llm-aufruf-framework.md) (`assistant-prompt.ts`): `locale`
  wird zur festen Antwortsprache im Abschnitt `<response_language>` („Respond in
  German.“). Der Formathinweis verlangt `answer` und alle Command-Labels in
  dieser Sprache.
- Fehlt `locale` (ältere Clients), antwortet der Agent in der Sprache der
  Frage (früher fest deutsch).
- Die Systemanweisungen der Agenten und Subagenten sind englisch; Begriffe der
  Oberfläche stehen deutsch in Klammern (z. B. „task (Aufgabe)“), damit
  Antworten die Bezeichnungen der App treffen.
- Subagenten schreiben freie Texte in der Sprache der Anfrage des Orchestrators.

## Siehe auch

- [Architektur des Assistenten](./assistent-architektur.md)
