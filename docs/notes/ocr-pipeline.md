# OCR-Pipeline

> Texterkennung besteht aus allgemeinen Schritten: Detektor-Logits → Textregionen → Zeilen → Ausschnitt je Region → CTC-Dekodierung, ohne modellspezifischen Code.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```ts
transformations: [
  {type: "mask.textRegions", result: "detectedRegions",
   parameters: {threshold: 0.3, minimumPixels: 8, minimumScore: 0.5}},
  {type: "geometry.mergeRows", result: "regions",
   parameters: {minimumVerticalOverlap: 0.5}},
]
```

- `mask.textRegions` bildet die Wahrscheinlichkeitsmaske direkt auf bewertete
  Regionen ab; `geometry.mergeRows` fasst sie zu Lesezeilen zusammen.
- Liefert der Detektor ein kleineres Raster, projiziert
  `geometry.scaleBounds` die Bounds mit dem Modell-Stride zurück, bevor ein
  `forEach` sie für `image.crop` nutzt. PP-OCRv6-Small liefert bereits
  Eingabekoordinaten; dort entfällt die Skalierung.
- Die fachliche Form (z. B. `{pageRegions: [...]}`) beschreibt allein das
  `workflowOutput.mapping`.
- Das Textmodell nutzt `sequence.ctcGreedyDecode`; Alphabet und Leerindex
  stehen im Manifest.
- `image.crop` und `image.perspectiveCrop` nehmen Kontext-Referenzen
  (`$iteration.value.bounds`, `$global.detektor.value.bounds`), die die
  Runtime vor der Inferenz auflöst. So läuft dieselbe Crop-Transformation in
  jeder Iteration mit anderen Koordinaten.

## Siehe auch

- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
- [Baustein „Für jedes Element“](./foreach-baustein.md)
