# Piper Deutsch - Eva (`piper-de-eva-x-low`)

> Journal des Systemmodells; Manifest: [`piper-de-eva-x-low.json`](./piper-de-eva-x-low.json).

**Status:** in Prüfung

## Steckbrief

ID `piper-de-eva-x-low`, Version `c10ece1aade47bb51c153c893d14e5bf8e5b7117` (Commit von `rhasspy/piper-voices`),
Aufgabe `text-to-speech`, Sprache `de`, Tags `lightweight`.

## Herkunft

- Quelle: [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices/tree/c10ece1aade47bb51c153c893d14e5bf8e5b7117/de/de_DE/eva_k/x_low),
  Datei `de_DE-eva_k-x_low.onnx` → `model.onnx`; Phonemzuordnung aus der zugehörigen
  `.onnx.json` im Manifest (`phonemeIdMap`).
- SHA-256: offen — die Datei liegt nicht im Repo; beim Holen eintragen.

## Lizenz

- Stimme und Trainingsdaten: [M-AILABS Speech Dataset](https://www.caito.de/2019/01/03/the-m-ailabs-speech-dataset/) (laut Model Card „License: See URL“; Audio aus LibriVox, gemeinfrei).
- Piper-Code: MIT ([rhasspy/piper](https://github.com/rhasspy/piper)).
- Phonemisierung in der Runtime über `phonemizer` und espeak-ng (beide GPL-3.0):
  betrifft die Runtime, nicht das Modell — zu bewerten.
- Bewertung: **offen** — Lizenztext des M-AILABS-Datensatzes sichern und bewerten.

## Dokumentation

- `MODEL_CARD` im Ordner der Quelle, [Piper](https://github.com/rhasspy/piper),
  [Piper-Systemmodelle](../../docs/notes/piper-systemmodelle.md).

## Vertrag

- Eingänge `input`, `input_lengths`, `scales`: `text.piperPhonemes`, `text.piperPhonemeLength` und
  `tensor.constant` (Settings `noiseScale`, `lengthScale`, `noiseWidth`).
- Ausgang `output` → `audio.wav` → Workflow-Wert `audio`.

## Prüfung

- 2026-10-26: Manifest besteht die Vertragsprüfung (Manifest-Test).
- ONNX-Prüfung, Trockenlauf und Hörtest gegen die Piper-Referenz: offen (Datei fehlt).

## Grenzen

- Qualität `x_low`: klein und schnell, hörbar weniger natürlich als Thorsten.

## Verlauf

- Vor 2026-10-26 — Manifest angelegt (nicht dokumentiert).
- 2026-10-26 — Tag aus dem Vokabular gesetzt; Journal nachgetragen.
