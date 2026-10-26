# Entscheidung: Generative Modelle über Sprachmodelle

> Text erzeugen, übersetzen, zusammenfassen, Bilder beschreiben und transkribieren laufen über Sprachmodelle; der ML-Dienst rechnet nur Modelle, die ihr Ergebnis in einem ONNX-Aufruf liefern.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Fähigkeit | Weg |
| --- | --- |
| Text erzeugen, übersetzen, zusammenfassen, Fragen frei beantworten | [Prompt-Baustein](./prompt-executor.md) mit einem [Sprachmodell](./sprachmodell-anbieter.md) |
| Bilder beschreiben | Prompt-Baustein mit einem Sprachmodell mit Bildeingabe |
| Sprache transkribieren | [Audio transkribieren](./audio-transkribieren-baustein.md) über ein Sprachmodell (auch einen lokalen, OpenAI-kompatiblen Whisper-Server); als ONNX-Modell nur CTC-Modelle wie Wav2Vec2, die in einem Aufruf rechnen |
| Klassifizieren, Erkennen, Segmentieren, Vorhersagen, Vorlesen | ML-Dienst (ONNX) |

## Warum

- **Ein Aufruf je Inferenz:** Der ML-Dienst führt Vorverarbeitung, genau
  einen `session.run` und Nachverarbeitung aus. Generative Modelle erzeugen
  ihre Ausgabe Token für Token; dafür bräuchte er Decoder-Schleifen,
  Suchstrategien, KV-Cache, Modelle aus mehreren Dateien und Tokenizer —
  doppelt zu dem, was Sprachmodelle schon leisten.
- **Kein Tokenizer:** Ohne generative Modelle braucht der ML-Dienst keine
  Tokenisierung. Nachzurüsten wäre sie erst für lokale Encoder-Modelle
  (Embeddings für semantische Suche, Text-Klassifikation in hoher Stückzahl).
- **Klare Modellsuche:** Das [Aufgaben-Vokabular](./modellaufgaben-und-sprachen.md)
  enthält keine generativen Aufgaben, damit der Katalog nichts anbietet, was
  kein ONNX-Modell erfüllen kann.

## Grenzen

Ebenfalls mehrere Aufrufe bräuchten zustandsbehaftete Streaming-Modelle (etwa
Silero VAD) und Eingaben über die feste Fensterlänge eines Modells hinaus.
Sie sind nicht abgedeckt; Bilder lassen sich über Regionen und „Für jedes
Element“ in Ausschnitten rechnen, Audio noch nicht.

## Siehe auch

- [Entscheidung: ML-Inferenz nur lokal](./ml-nur-lokal-entscheidung.md)
- [Schnittstelle des ML-Dienstes](./ml-dienst-schnittstelle.md)
