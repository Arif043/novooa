# Deklarative Transformationen

> Ein- und Ausgänge nutzen dieselbe deklarative `transformations`-Syntax; ausgewertet wird sie nur in Python, TypeScript validiert lediglich.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```ts
inputs: [{
  name: "image", source: "image", dataType: "float32",
  shape: ["dynamic", 3, 224, 224],
  transformations: [
    {type: "image.decode", parameters: {colorSpace: "rgb"}},
    {type: "image.resize", parameters: {width: 224, height: 224}},
    {type: "tensor.layout", parameters: {order: "channelsFirst"}},
    {type: "tensor.normalize", parameters: {
      mean: [0.485, 0.456, 0.406], std: [0.229, 0.224, 0.225]}},
  ],
}]
```

- Eingabestrategien erzeugen Tensoren aus Workflow-Quellen,
  Ausgabestrategien technische Zwischenwerte; erst das
  [Workflow-Output-Mapping](./workflow-output-mapping.md) macht daraus den
  fachlichen Wert.
- Python entdeckt Strategien über ihre Kennung automatisch. Eine neue
  Transformation ergänzt nur ihr eigenes Modul; Worker, Registry und andere
  Strategien bleiben unverändert (OCP).
- TypeScript prüft nur den Aufbau eines Vertrags. Welche Transformationen es
  gibt und wie sie zusammenpassen, entscheidet allein der Python-Katalog —
  beim Cachen und Import über den ML-Dienst, beim Veröffentlichen
  (`models:publish`) über `contract_validation_worker.py`. Eine neue
  Transformation braucht deshalb keine Änderung in TypeScript.
- Parameter dürfen Kontext referenzieren (`$iteration.value.bounds`,
  `$global.detektor.value.bounds`); die Runtime löst sie direkt vor der
  Inferenz auf, Python sieht nur konkrete Werte.

## Siehe auch

- [Transformationen](../index/transformationen.md)
- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Aufbau des Python-ML-Dienstes](./python-ml-dienst-aufbau.md)
