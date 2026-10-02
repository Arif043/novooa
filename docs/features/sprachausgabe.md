# Feature „Sprachausgabe" (Text vorlesen über Sprachmodelle)

Der Baustein **Text vorlesen** (`textToSpeech`) spricht Text entweder mit einem
lokalen ONNX-Modell (siehe [`ml-modelle.md`](./ml-modelle.md)) oder mit einem
**verbundenen Sprachmodell**. Die Auswahl der Sprachmodelle ist bewusst nicht
gefiltert: Welches Modell sprechen kann, entscheidet der Anbieter; Fehler
erscheinen als lesbare Meldung im Lauf.

## Konfiguration des Bausteins

| Feld              | Bedeutung                                                              |
| ----------------- | ---------------------------------------------------------------------- |
| `languageModelId` | Gesetzt → Sprachmodell. Leer → ONNX-Modell (`modelId`, Eingaben, …).   |
| `speechText`      | Vorzulesender Text, darf Template-Ausdrücke enthalten.                 |
| `voiceId`         | Stimme; leer = Standardstimme des Anbieters (keine Pflichtauswahl).    |

Ausgabe: `value` (Typ `audio`) verweist auf die als Team-Datei gespeicherte
Aufnahme (`sprach-ausgabe.wav` bzw. `.mp3`). Beim Wechsel des Sprachmodells wird
die Stimme zurückgesetzt, da Stimmen-IDs anbieterspezifisch sind.

## Anbieter

| Verbindung                              | Protokoll                                                   | Format |
| --------------------------------------- | ----------------------------------------------------------- | ------ |
| Google AI                               | `POST /v1beta/interactions` (Audio-Antwort), 24 kHz mono    | WAV    |
| ElevenLabs                              | SDK `@elevenlabs/elevenlabs-js` (`textToSpeech.convert`)    | MP3    |
| OpenAI-kompatibel (inkl. Mistral, xAI, OpenRouter, Abacus.AI, Hugging Face) | `POST {Basis-URL}/audio/speech` | MP3 |

Ollama bietet keine Sprachausgabe. Dienste ohne `/audio/speech` antworten mit
einem Fehler, den die Meldung weitergibt.

**ElevenLabs** ist ein eigener Anbieter (`elevenLabs`) und kennt nur Sprache:
Die Verbindung braucht nur den API-Key, ihre Modelle (`models.list`, nur
`canDoTextToSpeech`) werden als Sprachmodelle angeboten.

## Keine Fähigkeitskataloge

Wir pflegen keinen Katalog, welches Modell sprechen kann. „Text vorlesen" zeigt
alle Sprachmodelle und geht optimistisch davon aus, dass die Wahl passt; sonst
steht der Fehler des Anbieters in der Aktivität. Als einziger Komfort blendet der
Client in den Auswahlen für Prompt-Bausteine und Standardmodelle Modelle aus,
deren ID `tts` als eigenes Wortteil enthält (`LanguageModel.isSpeechModel`),
sowie alle ElevenLabs-Modelle. Dieser Filter ist rein clientseitig und gilt auch
für bereits gespeicherte Modelle. Die Entdeckung nimmt `*-tts`-Modelle bei
Google auch dann auf, wenn sie `generateContent` nicht melden.

## Stimmen

Eine Stimme muss nicht gewählt werden. Die Oberfläche holt die Stimmen beim
Anbieter und zeigt sie in einem durchsuchbaren Sheet:

- **Google AI:** die Stimmen der Stimmenbibliothek `GET /v1beta/voices` (Standard `Kore`, falls vorhanden); nur wenn
  die Abfrage fehlschlägt oder leer ist, gelten die 30 fest eingebauten
  Gemini-Stimmen.
- **ElevenLabs:** Stimmen des Kontos (`voices.search`, bis 500), Standard ist die
  erste.
- **OpenAI-kompatibel:** feste Liste der OpenAI-Stimmen (Standard `alloy`); der
  Suchtext lässt sich als eigene Stimmen-ID übernehmen.

Endpunkte:

- Lokale Runtime: `GET /v1/language-models/:languageModelId/voices`
- Cloud: Callable `listSpeechVoices` (`{languageModelId}`)

Antwort: `{voices: [{id, name, description?, language?}], defaultVoiceId,
allowsCustomVoice}`. API-Keys verlassen den Server nie.

## Grenzen

Maximale Textlänge pro Aufruf: Google 8000, OpenAI-kompatibel 4096,
ElevenLabs 5000 Zeichen; längere Texte brechen mit Hinweis ab (Aufteilung ist
nicht Teil dieser Version). Sprache-zu-Text über Sprachmodelle folgt später.

## Code

- Backend: `functions/src/features/speech_synthesis/` (Domain: `SpeechProvider`,
  `LanguageModelSpeech`; Adapter je Protokoll), ElevenLabs-Fassade in
  `language_models/infrastructure/elevenlabs/`.
- Client: `lib/features/speech_synthesis/` und
  `task_builder/presentation/widgets/text_to_speech_widget.dart`.
