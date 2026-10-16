# Typebenen eines Modellvertrags

> Workflow-Werttyp, Modellquelltyp und Tensor-Datentyp sind drei getrennte Ebenen; Transformationen verbinden sie.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Ebene | Zweck | Beispiele |
| --- | --- | --- |
| Workflow-Werttyp | fachlicher Wert zwischen Bausteinen | `string`, `number`, `boolean`, `json`, `audio`, `image` (Bild-`media`) |
| Modellquelltyp | Wert vor der Transformation einer Eingabe | `text`, `number`, `image`, `audio`, `file`, `datetime`, `boolean`, `json`, `tensor` |
| Tensor-Datentyp | ONNX-Repräsentation an der Inferenzgrenze | `float32`, `float16`, `float64`, `int64`, `int32`, `int16`, `int8`, `uint8`, `bool`, `string` samt Form |

`string`-Tensoren reisen als UTF-8-JSON-Array in Zeilenfolge.

Beispiel: Ein Slider liefert `number` `1.0`; `tensor.constant` formt ihn für
Kokoro zu `float32[1]` am Eingang `speed`.

Am Runtime-Rand arbeiten alle Modelle mit Tensoren. Ein Eingang beschreibt
Quelle und Transformationspipeline, ein Ausgang seine Semantik und eine
optionale Pipeline.

- `audio` verweist immer auf eine gespeicherte Audiodatei. STT-Manifeste haben
  einen `audio`-Eingang, TTS-Manifeste einen `audio`-Workflow-Ausgang.
- Ein Workflow-Ausgang `image` (aus `image.encode`) wird als Team-Datei
  gespeichert und als Bild (`media`) weitergegeben.
- `textToSpeech` und `speechToText` nutzen denselben Vertrag wie
  `modelInference` und filtern den Katalog auf Audio-Aus- bzw. -Eingänge.
  `textToSpeech` kann stattdessen ein Sprachmodell nutzen
  ([Sprachausgabe](../index/sprachausgabe.md)).

## Siehe auch

- [Eingangsbindungen](./modell-eingangsbindungen.md)
- [Deklarative Transformationen](./transformationen-deklarativ.md)
- [Workflow-Output-Mapping](./workflow-output-mapping.md)
