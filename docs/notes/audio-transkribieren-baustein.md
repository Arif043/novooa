# Baustein „Audio transkribieren“

> `speechToText` transkribiert eine Audiodatei mit einem verbundenen Sprachmodell oder einem lokalen ONNX-Modell und liefert den Text.

Gehört zu: [Sprachausgabe](../index/sprachausgabe.md)

| Feld | Bedeutung |
| --- | --- |
| `languageModelId` | gesetzt → Sprachmodell; leer → ONNX-Modell („Lokales Modell (ONNX)“) |
| `audioTemplate` | Verweis auf die Audiodatei, z. B. `{{aufnahme.value}}` |

Ausgabe: `value` (`string`), das Transkript.

| Verbindung | Protokoll | Grenze |
| --- | --- | --- |
| Google AI | jedes Gemini-Modell, Audio inline an `models/{id}:generateContent` | 14 MB |
| ElevenLabs | SDK `speechToText.convert` mit Scribe (`scribe_v2`, `scribe_v1`) | 1 GB |
| OpenAI-kompatibel | `POST {Basis-URL}/audio/transcriptions` (multipart), z. B. `whisper-1` | 25 MB |

- Google hat keine eigenen Transkriptionsmodelle; jedes Gemini-Modell versteht
  Audio.
- Ollama transkribiert nicht.
- Audio wird nicht gestückelt; zu große Dateien brechen mit Hinweis ab.

Code (beide Sprachbausteine): Backend
`functions/src/features/speech_synthesis/` und `speech_transcription/`
(Domain `SpeechProvider`, `LanguageModelSpeech`, Adapter je Protokoll),
ElevenLabs-Fassade in `language_models/infrastructure/elevenlabs/`; Client
`lib/features/speech_synthesis/` und `text_to_speech_widget.dart`.

## Siehe auch

- [Baustein „Text vorlesen“](./text-vorlesen-baustein.md)
- [Typebenen eines Modellvertrags](./modell-typebenen.md) — `audio`
