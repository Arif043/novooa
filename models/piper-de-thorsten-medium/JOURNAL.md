# Piper Deutsch - Thorsten (mittel) (`piper-de-thorsten-medium`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** in Prüfung

## Steckbrief

ID `piper-de-thorsten-medium`, Version `c10ece1aade47bb51c153c893d14e5bf8e5b7117` (Commit von `rhasspy/piper-voices`),
Aufgabe `text-to-speech`, Sprache `de`, Tags `high-quality`.

## Herkunft

- Quelle: [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices/tree/c10ece1aade47bb51c153c893d14e5bf8e5b7117/de/de_DE/thorsten/medium),
  Datei `de_DE-thorsten-medium.onnx` → `model.onnx`; Phonemzuordnung aus der zugehörigen
  `.onnx.json` im Manifest (`phonemeIdMap`).
- SHA-256: offen — die Datei liegt nicht im Repo; beim Holen eintragen.

## Lizenz

- Stimme und Trainingsdaten: [Thorsten-Voice](https://github.com/thorstenMueller/Thorsten-Voice), CC0 (Model Card).
- Piper-Code: MIT ([rhasspy/piper](https://github.com/rhasspy/piper)).
- Phonemisierung in der Runtime über `phonemizer` und espeak-ng (beide GPL-3.0):
  betrifft die Runtime, nicht das Modell — zu bewerten.
- Bewertung: geklärt für Stimme und Datensatz (CC0); Phonemisierung siehe oben.

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

- Eine Sprecherstimme; Qualität `medium`.

## Verlauf

- Vor 2026-10-26 — Manifest angelegt (nicht dokumentiert).
- 2026-10-26 — Tag aus dem Vokabular gesetzt; Journal nachgetragen.
