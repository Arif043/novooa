# Transformation `sequence.segments`

> Frame-Scores → Zeitabschnitte `{start, end, score}`; Klassenscores (Frames × Klassen) → `{start, end, index, label?, score}` je wahrscheinlichster Klasse.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `json-result`

Zeiten in Sekunden, Werte auf 6 Stellen gerundet.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `frameDuration` | Zahl ≥ 0 | nein | – |
| `hopLength` | ganze Zahl ≥ 1 | nein | – |
| `sampleRate` | ganze Zahl ≥ 1 | nein | – |
| `threshold` | Zahl | nein | `0.5` |
| `labels` | Liste aus Text | nein | – |
| `backgroundIndex` | ganze Zahl ≥ 0 | nein | – |
| `mergeGap` | Zahl ≥ 0 | nein | `0` |
| `minDuration` | Zahl ≥ 0 | nein | `0` |

## Fachliche Tests

- [`test_sequence_segments.py`](../../local-runtime/python/tests/test_sequence_segments.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [OCR-Pipeline](./ocr-pipeline.md)
