# SqueezeNet 1.1 (`squeezenet-1-1`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** in Prüfung

## Steckbrief

ID `squeezenet-1-1`, Version `1.1-7`, Aufgabe `image-classification`,
sprachunabhängig, Tags `everyday-objects`, `animals`, `lightweight`.
Ordnet ein Bild einer von 1 000 ImageNet-Kategorien zu.

## Herkunft

- Quelle: [ONNX Model Zoo (legacy)](https://huggingface.co/onnxmodelzoo/legacy_models/tree/main/validated/vision/classification),
  `squeezenet/model/squeezenet1.1-7.onnx` (Opset 7).
- SHA-256: offen — die Datei liegt nicht im Repo; beim Holen eintragen.

## Lizenz

- Gewichte und Code: BSD (ursprüngliches SqueezeNet-Projekt), ONNX-Konvertierung
  im Model Zoo.
- Trainingsdaten: ImageNet-1k; dessen Bedingungen erlauben nur nicht-kommerzielle
  Nutzung, was für trainierte Gewichte strittig ist.
- Bewertung: **offen** — vor der Veröffentlichung rechtlich klären.

## Dokumentation

- Paper [SqueezeNet (arXiv 1602.07360)](https://arxiv.org/abs/1602.07360),
  Model-Zoo-Beschreibung im Ordner der Quelle.
- Referenz der Vorverarbeitung: Model Zoo (Größe 224, ImageNet-Mittelwerte).

## Vertrag

- Eingang `data` (Bild, `[1, 3, 224, 224]`): `image.decode` → `image.resize`
  (224 × 224) → `tensor.layout` → `tensor.normalize` (ImageNet-Werte in 0…255).
- Ausgang `squeezenet0_flatten0_reshape0` → `tensor.softmax` → `tensor.topK` →
  Workflow-Wert `classifications` mit Index, Label und Score.

## Prüfung

- 2026-10-26: Manifest besteht die Vertragsprüfung (Manifest-Test).
- ONNX-Prüfung, Trockenlauf und fachlicher Referenztest: offen (Datei fehlt).

## Grenzen

- `image.resize` ohne Erhalt des Seitenverhältnisses; die Referenz skaliert die
  kürzere Seite und schneidet mittig zu (`image.resizeShorterSide` +
  `image.centerCrop` wären näher).
- Die 1 000 Labels stehen im Manifest; als Ressource mit `resource.lookup`
  wäre es übersichtlicher. `tensor.topK` nutzt noch das alte `parameter`-Format.

## Verlauf

- Vor 2026-10-26 — Manifest angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags ergänzt; Journal nachgetragen; Lizenzfrage offen.
