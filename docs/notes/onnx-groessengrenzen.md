# ONNX-Größengrenzen

> `model.onnx` darf höchstens 2 GB groß sein; größere Modelle lagern ihre Gewichte als ONNX External Data aus.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- Die 2-GB-Grenze ist die Protobuf-Grenze von ONNX.
- Für External Data gelten nur Plattenplatz und Arbeitsspeicher des Servers.
- Baum-Modelle über 2 GB lassen sich nur mit dem Operator `TreeEnsemble`
  (ONNX-ML Opset 5) auslagern; ältere Baum-Operatoren speichern die Bäume als
  nicht auslagerbare Attribute.
- Der ML-Dienst lädt `InferenceSession(<bündel>/model.onnx)` über den Pfad,
  damit ONNX Runtime ausgelagerte Gewichte daneben findet.

## Siehe auch

- [Modellbündel](./modellbuendel.md)
- [Eigenes Modell importieren](./eigenes-modell-importieren.md)
