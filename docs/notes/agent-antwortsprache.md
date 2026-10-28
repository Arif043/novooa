# Antwortsprache des Agenten

> Der Client sendet die App-Sprache als `locale`; Antwort und Command-Labels folgen ihr.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- `locale` (`en`/`de`/`tr`, aus `AssistantContext.languageCode`) im
  Anfragekörper von Callable, Runtime-Route und Relay.
- `promptWithAnswerLanguage` hängt die Antwortsprache an den Nutzerprompt.
- Fehlt `locale` (ältere Clients), antwortet der Agent deutsch.
- Die System-Prompts der Agenten sind noch deutsch; mit der Umstellung auf das
  [LLM-Framework](./llm-aufruf-framework.md) (geplant) werden sie englisch,
  die Antwortsprache steuert dann der Abschnitt `response_language`.

## Siehe auch

- [Architektur des Assistenten](./assistent-architektur.md)
