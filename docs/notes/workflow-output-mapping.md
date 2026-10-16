# Workflow-Output-Mapping

> `workflowOutput` ist kein Transformationsschritt, sondern beschreibt deklarativ, welcher fachliche Workflow-Wert aus den Ergebnissen eines Ausgangs entsteht.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```ts
outputs: [{
  name: "scores", dataType: "float32", shape: ["dynamic", 1000],
  semantic: "classification.scores",
  transformations: [
    {type: "tensor.softmax", parameters: {axis: -1}},
    {type: "tensor.topK", result: "topClasses", parameters: {k: "$anzahl"}},
  ],
  workflowOutput: {
    name: "classifications", type: "json",
    mapping: {"$map": {from: "topClasses", item: {
      index: "$item.index",
      label: {"$lookup": {values: ["Klasse A", "Klasse B"], key: "$item.index"}},
      score: "$item.value",
    }}},
  },
}]
```

Das Mapping kennt:

- Literale und Referenzen (`$topClasses`, `$item.value`, `$tensor`,
  `$tensor.0`); `result` einer Transformation benennt einen Zwischenwert.
- `$map` (`from`, `item`) für Listen.
- `$lookup` (`values` als Liste oder Referenz wie `"$classes"`, `key`).
- `$outputs.<ausgang>.<wert>`: Endwert (`tensor`) oder benanntes Ergebnis
  eines anderen Ausgangs; `outputs` ist als Ergebnisname reserviert.

Warum: Die Ergebnisstruktur steht im Manifest statt im Code einer
Strategie. Technische ONNX-Ausgangsnamen erreichen den Workflow nie; eine
SqueezeNet-Ausgabe steht als `{{modell1.classifications}}` bereit, der beste
Treffer unter `{{modell1.classifications.0.score}}`.

## Siehe auch

- [Deklarative Transformationen](./transformationen-deklarativ.md)
- [Klassisches ML über ONNX](./klassisches-ml-onnx.md)
