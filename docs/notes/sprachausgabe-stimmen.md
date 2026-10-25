# Stimmen der Sprachausgabe

> Eine Stimme ist optional; die Oberfläche holt die Stimmen beim Anbieter und zeigt sie in einem durchsuchbaren Sheet.

Gehört zu: [Sprachausgabe](../index/sprachausgabe.md)

- **Google AI:** Stimmenbibliothek `GET /v1beta/voices` (Standard `Kore`,
  falls vorhanden); nur bei Fehler oder leerer Liste die 30 eingebauten
  Gemini-Stimmen.
- **ElevenLabs:** Stimmen des Kontos (`voices.search`, bis 500), Standard die
  erste.
- **OpenAI-kompatibel:** feste Liste der OpenAI-Stimmen (Standard `alloy`);
  der Suchtext lässt sich als eigene Stimmen-ID übernehmen.

Endpunkt: `GET /v1/language-models/:languageModelId/voices`. Antwort:
`{voices: [{id, name, description?, language?}], defaultVoiceId,
allowsCustomVoice}`. API-Keys verlassen den Server nie.

## Siehe auch

- [Baustein „Text vorlesen“](./text-vorlesen-baustein.md)
- [Sprachmodell-Anbieter](./sprachmodell-anbieter.md)
