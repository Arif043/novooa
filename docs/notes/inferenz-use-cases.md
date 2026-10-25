# Inferenz-Use-Cases

> `RunModelInferenceWithSources` löst Modell und Quellen auf, `RunModelInference` nimmt nur Tensoren; die Runtime bekommt Katalogeintrag und Tensoren, nie Modellbytes.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```text
ModelCatalog → RunModelInferenceWithSources
                     ↓
             PrepareModelInputs
                     ↓
             RunModelInference
                     ↓
        ModelInferenceRuntime
```

- `RunModelInferenceWithSources`: Verfügbarkeit für das Team auflösen,
  benannte Workflow-Quellen gegen das Manifest validieren, vorbereiten.
- `PrepareModelInputs`: ordnet Quellen den Eingängen zu; die Umwandlung
  macht der Port `ModelInputTransformer`.
- `RunModelInference`: prüft Eingabe-Tensoren gegen das Manifest, übergibt
  nur den Katalogeintrag und validiert auch die Ausgabe-Tensoren.

Wie Dateien zum ML-Dienst kommen, entscheidet die Infrastructure.

## Siehe auch

- [ONNX-Inferenz über den ML-Dienst](./onnx-inferenz-ml-dienst.md)
- [Modelleingaben im Baustein](./modelleingaben-im-baustein.md)
