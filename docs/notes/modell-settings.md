# Modell-Settings

> Einstellbare Modellparameter sind sichtbare `settings` (Slider, Checkbox, Radiogruppe); Transformationen binden sie über `"$name"`.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```ts
settings: [{
  name: "anzahl", label: "Anzahl der Ergebnisse",
  control: {type: "slider", initial: 3, minimum: 1, maximum: 20, step: 1},
}],
// in einer Transformation:
{type: "tensor.topK", result: "topClasses", parameters: {k: "$anzahl"}}
```

- Der Baustein zeigt das Setting unter den Modelleinstellungen und speichert
  nur den Wert (`settings: [{name: "anzahl", valueTemplate: "5"}]`); ein
  Template ist erlaubt.
- Vor dem Lauf ersetzt `resolveModelContractBindings` jedes `"$anzahl"` in
  Ein- und Ausgangsparametern. Transformationen wissen nichts von Settings.
- Warum: Der Modellautor kontrolliert Grenzen und Standardwert, und ein Plan
  bleibt beim Modell-Update validierbar — ohne versteckte Modelleingaben.

Mehrere Settings in einem Tensor (Piper):

```ts
{name: "scales", source: "text", binding: {type: "generated", value: ""},
 dataType: "float32", shape: [3],
 transformations: [{type: "tensor.constant",
   parameters: {values: ["$noiseScale", "$lengthScale", "$noiseWidth"]}}]}
```

**Altformat:** Früher `parameters: {parameter: {name, label, default,
minimum, maximum}}` am Ausgang und Werte als `outputParameters`. Beim Lesen
wird daraus ein Slider-Setting `<ausgang>_<name>`
(`legacy-output-parameter-settings.ts`); gespeicherte Werte werden Settings
gleichen Namens (`legacy-model-output-parameters.ts`,
`legacy_model_output_parameters.dart`). Ohne Bindung nutzt `tensor.topK` den
alten Standardwert.

## Siehe auch

- [Vertragsprüfung](./ml-vertragspruefung.md) — passt das Steuerelement zum Parameter?
- [Eingangsbindungen](./modell-eingangsbindungen.md)
