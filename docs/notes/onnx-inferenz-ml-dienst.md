# ONNX-Inferenz über den ML-Dienst

> Tensor-Vorverarbeitung und ONNX-Inferenz laufen im Python-Dienst `novooa-ml`; die Runtime gibt nur Referenzen weiter und fällt nie auf die Cloud zurück.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Adapter in der Runtime: `HttpPythonModelInputTransformer` und
  `SidecarOnnxInferenceRuntime`. Ohne Dienst meldet die Runtime einen klaren
  lokalen ML-Fehler.
- Ports: `ModelInferenceRuntime` und `ModelInputTransformer`
  (`PrepareModelInputs`); die Cloud bekommt später eigene Adapter.
- Workflow-Werte werden gemäß Manifest in Tensoren umgewandelt. Für
  Bildquellen gibt es eine erweiterbare Registry (Dekodierung, Skalierung,
  Layout, Normalisierung); weitere Quelltypen kommen als Strategien. Weder
  Pipeline noch Modell-Baustein hängen an Firebase Storage oder Bildern.
- Katalogmodelle liest der Dienst aus dem gemeinsamen Cache des Servers;
  eigene Modelle streamt ihm die Runtime in seinen Bündelspeicher
  ([ML-Modelle § Modellbündel](../features/ml-modelle.md#modellbündel-und-ml-dienst)).
- Abhängigkeiten:
  [`local-runtime/python/requirements.txt`](../../local-runtime/python/requirements.txt).

## Siehe auch

- [Volumes und Datenablage der Runtime](./runtime-volumes-und-datenablage.md)
- [Ports und Netze der Runtime](./runtime-ports-und-netze.md)
