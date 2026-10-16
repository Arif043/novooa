# Antwortsprache des Agenten

> Der Client sendet die App-Sprache als `locale`; Antwort und Command-Labels folgen ihr.

Gehört zu: [KI-Agent](../index/ki-agent.md)

- `locale` (`en`/`de`/`tr`, aus `AssistantContext.languageCode`) im
  Anfragekörper von Callable, Runtime-Route und Relay.
- `promptWithAnswerLanguage` hängt die Antwortsprache an den Nutzerprompt.
- Fehlt `locale` (ältere Clients), antwortet der Agent deutsch.
- Die System-Prompts selbst sind noch deutsch.

## Siehe auch

- [Architektur des Assistenten](./assistent-architektur.md)
