# Baustein „Text vorlesen“

> `textToSpeech` spricht Text mit einem verbundenen Sprachmodell oder einem lokalen ONNX-Modell und liefert die Aufnahme als Audio-Datei.

Gehört zu: [Sprachausgabe](../index/sprachausgabe.md)

| Feld | Bedeutung |
| --- | --- |
| `languageModelId` | gesetzt → Sprachmodell; leer → ONNX-Modell (`modelId`, Eingaben …) |
| `speechText` | vorzulesender Text, Templates erlaubt |
| `voiceId` | Stimme; leer = Standardstimme des Anbieters |

- Ausgabe: `value` (`audio`), Team-Datei `sprach-ausgabe.wav` bzw. `.mp3`.
- Beim Wechsel des Sprachmodells wird die Stimme zurückgesetzt (IDs sind
  anbieterspezifisch).

| Verbindung | Protokoll | Format |
| --- | --- | --- |
| Google AI | `POST /v1beta/interactions` (Audio-Antwort), 24 kHz mono | WAV |
| ElevenLabs | SDK `@elevenlabs/elevenlabs-js` (`textToSpeech.convert`) | MP3 |
| OpenAI-kompatibel (inkl. Mistral, xAI, OpenRouter, Abacus.AI, Hugging Face) | `POST {Basis-URL}/audio/speech` | MP3 |

- Ollama spricht nicht; Dienste ohne `/audio/speech` liefern einen Fehler, den
  die Meldung weitergibt.
- **ElevenLabs** ist ein eigener Anbieter (`elevenLabs`), nur Sprache: API-Key
  genügt; seine Modelle (`models.list`, nur `canDoTextToSpeech`) erscheinen als
  Sprachmodelle.
- Maximale Textlänge: Google 8000, OpenAI-kompatibel 4096, ElevenLabs 5000
  Zeichen; länger bricht mit Hinweis ab (keine Aufteilung).

## Siehe auch

- [Stimmen der Sprachausgabe](./sprachausgabe-stimmen.md)
- [Keine Fähigkeitskataloge für Sprachmodelle](./sprachmodelle-ohne-faehigkeitskatalog.md)
- [Piper-Systemmodelle](./piper-systemmodelle.md)
