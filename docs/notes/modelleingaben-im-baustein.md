# Modelleingaben im Baustein

> Der `modelInference`-Baustein zeigt jeden Manifest-Eingang als eigene Reihe mit frei editierbarem Workflow-Mapping; Kanten bestimmen nur die Reihenfolge.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- Gespeichert je Eingang: Manifestname, `workflowMapping`, Quelltyp,
  Tensor-Datentyp und Form.
- Das Mapping akzeptiert feste Werte und Variablen wie `{{eingabe.value}}`;
  in einem `forEach`-Graphen zusätzlich `{{iteration.value}}`,
  `{{iteration.index}}`, `{{global.referenz.value}}` und
  `{{global.input.feld}}`.
- Eine alleinstehende Variable übergibt ihren ursprünglichen Wert, keine
  Textdarstellung.
- Das Manifest prüft Vollständigkeit, Eindeutigkeit und Typ jeder Quelle.
- Datei- und Bildwerte lädt der Adapter über `TeamFileContentReader`; eine
  Firebase-Storage-Referenz erreicht weder Manifest noch Runtime. Base64 gibt
  es nur an der technischen HTTP-Grenze der Inferenz.

```text
Workflow-Wert → Adapter → Modellquelle → PrepareModelInputs
                                          ↓
                                   ModelInputTransformer
                                          ↓
                                      ModelTensor
```

## Siehe auch

- [Inferenz-Use-Cases](./inferenz-use-cases.md)
- [Workflow-Output-Mapping](./workflow-output-mapping.md)
- [Eingangsbindungen](./modell-eingangsbindungen.md)
