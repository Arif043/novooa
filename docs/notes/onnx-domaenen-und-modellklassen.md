# ONNX-Domänen und Modellklassen

> novooa legt keine Operator-Domäne fest; sie steht in der Modelldatei, und ONNX Runtime lädt die passenden Kernel.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Methode | Domäne | Stand |
| --- | --- | --- |
| CNN, Bildklassifikation, OCR | `ai.onnx` | unterstützt |
| MLP | `ai.onnx` | unterstützt |
| SVM, Random Forest, Gradient Boosting, lineare/logistische Regression | `ai.onnx.ml` | unterstützt ([Klassisches ML](./klassisches-ml-onnx.md)) |
| XGBoost, LightGBM (`onnxmltools`) | `ai.onnx.ml` | unterstützt |
| Transformer, Text-Embedding | `ai.onnx` | Tokenizer fehlt |

Die früher genannten Lücken für klassisches ML sind geschlossen:
`string`-Tensoren gibt es, Tabellenmerkmale liefert `json.features`, und
ZipMap-Ausgänge wandelt der Ausgabe-Worker in `float32` um, statt sie
abzulehnen.

**Import-Allowlist (geplant):** Für importierte Modelle sollen die
verwendeten Operatoren geprüft werden — `ai.onnx.ml` vollständig, aus der
Default-Domäne nur `Cast`, `Concat`, `Reshape`, `Identity`, `Transpose`,
`Gather` und elementweise Arithmetik, alles andere abgelehnt. Eine Prüfung
nur der Domäne genügt nicht, weil `ai.onnx.ml`-Modelle fast immer auch die
Default-Domäne importieren. Kuratierte Deep-Learning-Modelle sind ausgenommen.

Offen: Tokenisierung für Textmodelle (`onnxruntime-extensions`, eigenes
Vokabular als Strategie oder vortokenisierte Eingaben).

## Siehe auch

- [Klassisches ML über ONNX](./klassisches-ml-onnx.md)
- [Eigenes Modell importieren](./eigenes-modell-importieren.md)
