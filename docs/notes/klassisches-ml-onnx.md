# Klassisches ML über ONNX

> Modelle aus `skl2onnx` oder `onnxmltools` (scikit-learn, XGBoost, LightGBM) laufen ohne neuen Code.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- **Datentypen:** Text- und Kategoriespalten sind `string`-Tensoren. Ein
  Datensatz `{"land": "CH", "umsatz": 88}` wird z. B. mit `json.toTensor`
  (Textspalte `[["CH"]]`) und `json.features` (Zahlenspalten) auf die
  benannten Eingänge verteilt. Passt ein Wert nicht zum Vertrag, nennt die
  Runtime Eingang und erwarteten Typ.
- **ZipMap:** Klassenwahrscheinlichkeiten als Liste von Dictionaries werden
  zu `float32` `[N, Klassen]` (Spalten in Klassenreihenfolge); die Klassen
  stehen zusätzlich als `$classes` bereit. Vertrag deklariert `float32`,
  z. B. `["dynamic", "dynamic"]`. `zipmap=False` geht ebenso.
- **Über Ausgänge hinweg:** `$outputs.<ausgang>.<wert>` und `$lookup` mit
  Referenz (`{"values": "$classes", "key": "$index"}`).

```json
"outputs": [
  {"name": "output_label", "dataType": "string", "shape": ["dynamic"],
   "semantic": "classification.label", "transformations": [],
   "workflowOutput": {"name": "klasse", "type": "string", "mapping": "$tensor.0"}},
  {"name": "output_probability", "dataType": "float32", "shape": ["dynamic", "dynamic"],
   "semantic": "classification.scores",
   "transformations": [{"type": "tensor.reduce", "parameters": {"operation": "max"}, "result": "best"}],
   "workflowOutput": {"name": "ergebnis", "type": "json",
     "mapping": {"label": "$outputs.output_label.tensor.0", "score": "$best.0"}}}
]
```

Tests mit echten Modellen in `local-runtime/python/tests/fixtures/sklearn`
(erzeugt mit `build_fixtures.py`): Klassifikator mit Text-Klassen und
ZipMap, Regressor, Pipeline mit `OneHotEncoder`.

## Siehe auch

- [Workflow-Output-Mapping](./workflow-output-mapping.md)
- [ONNX-Größengrenzen](./onnx-groessengrenzen.md) — Baum-Modelle über 2 GB
