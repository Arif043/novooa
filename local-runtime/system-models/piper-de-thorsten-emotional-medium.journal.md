# Piper Deutsch - Thorsten Emotional (`piper-de-thorsten-emotional-medium`)

> Journal des Systemmodells; Manifest: [`piper-de-thorsten-emotional-medium.json`](./piper-de-thorsten-emotional-medium.json).

**Status:** in Prüfung

## Steckbrief

ID `piper-de-thorsten-emotional-medium`, Version `375a0fe641dea077c2a47b4e9a056d6da521eed3` (Commit von `rhasspy/piper-voices`),
Aufgabe `text-to-speech`, Sprache `de`, Tags `emotional`.

## Herkunft

- Quelle: [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices/tree/375a0fe641dea077c2a47b4e9a056d6da521eed3/de/de_DE/thorsten_emotional/medium),
  Datei `de_DE-thorsten_emotional-medium.onnx` → `model.onnx`; Phonemzuordnung aus der zugehörigen
  `.onnx.json` im Manifest (`phonemeIdMap`).
- SHA-256: offen — die Datei liegt nicht im Repo; beim Holen eintragen.

## Lizenz

- Stimme und Trainingsdaten: [Thorsten-Voice](https://github.com/thorstenMueller/Thorsten-Voice) (emotionale Aufnahmen), CC0 (Model Card).
- Piper-Code: MIT ([rhasspy/piper](https://github.com/rhasspy/piper)).
- Phonemisierung in der Runtime über `phonemizer` und espeak-ng (beide GPL-3.0):
  betrifft die Runtime, nicht das Modell — zu bewerten.
- Bewertung: geklärt für Stimme und Datensatz (CC0); Phonemisierung siehe oben.

## Dokumentation

- `MODEL_CARD` im Ordner der Quelle, [Piper](https://github.com/rhasspy/piper),
  [Piper-Systemmodelle](../../docs/notes/piper-systemmodelle.md).

## Vertrag

- Eingänge `input`, `input_lengths`, `scales`, `sid` (Sprecher bzw. Emotion): `text.piperPhonemes`, `text.piperPhonemeLength` und
  `tensor.constant` (Settings `speaker`, `noiseScale`, `lengthScale`, `noiseWidth`).
- Ausgang `output` → `audio.wav` → Workflow-Wert `audio`.

## Prüfung

- 2026-10-26: Manifest besteht die Vertragsprüfung (Manifest-Test).
- ONNX-Prüfung, Trockenlauf und Hörtest gegen die Piper-Referenz: offen (Datei fehlt).

## Grenzen

- Emotionen als Sprecher-IDs (`sid`); Auswahl über das Setting `speaker`.

## Verlauf

- Vor 2026-10-26 — Manifest angelegt (nicht dokumentiert).
- 2026-10-26 — Tag aus dem Vokabular gesetzt; Journal nachgetragen.
