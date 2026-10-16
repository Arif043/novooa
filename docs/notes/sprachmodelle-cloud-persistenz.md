# Sprachmodelle in der Cloud

> Sprachmodelle sind team-scoped: Verbindungen tragen Anbieter und Endpunkt, Modelle verweisen auf eine Verbindung, API-Keys liegen nur verschlüsselt in einer für Clients gesperrten Collection.

Gehört zu: [Architektur](../index/architektur.md)

- `languageModelConnections`: Anbieter-Metadaten und Endpunkt. Google AI
  nativ; xAI, Mistral, OpenRouter, Abacus.AI, Hugging Face mit festen
  OpenAI-kompatiblen Endpunkten; ElevenLabs über sein SDK, nur Sprache. Nur der
  generische Anbieter erlaubt eine frei gewählte HTTPS-Adresse.
- `languageModels`: Verbindung plus konkrete Modell-ID.
- `languageModelSecrets`: API-Keys, nur durch Callable Functions
  verschlüsselt geschrieben; für Clients weder lesbar noch schreibbar.
- Standalone: dieselben Metadaten in SQLite, Secrets im lokalen Secret Store
  ([Sprachmodell-Anbieter](./sprachmodell-anbieter.md)).

## Siehe auch

- [Modellprovider für Prompt-Bausteine](./modellprovider-prompt.md)
