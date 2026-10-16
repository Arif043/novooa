# Eingangsbindungen

> Ein Modelleingang ist standardmäßig eine Workflow-Eingabe des Bausteins; `derived` und `generated` erzeugen technische Eingänge ohne eigenes Feld.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- **Standard:** Die Zuordnung steht im Arbeitsplan und darf ein Template
  enthalten.
- **`binding: {type: "derived", inputName: "..."}`:** leitet denselben
  Quellwert für einen weiteren Tensor ab.
- **`binding: {type: "generated", value: ...}`:** erzeugt eine technische
  Quelle aus dem Manifest.

Beide erscheinen weder als Eingabefeld noch in der Workflow-Konfiguration.
So bleiben etwa Piper-`input_lengths` und `scales` Vertragsdetails.

## Siehe auch

- [Modelleingaben im Baustein](./modelleingaben-im-baustein.md)
- [Modell-Settings](./modell-settings.md)
