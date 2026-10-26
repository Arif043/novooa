# Transformation `audio.frames`

> Zerlegt Mono-Audio in Fenster fester Dauer und rechnet sie als Batch.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `audio` → `tensor`

Für Modelle mit fester Eingabelänge über längere Aufnahmen (Geräusch-, Sprecher- oder Aktivitätserkennung). Fenster `seconds`, Schritt `hopSeconds` (Standard: ohne Überlappung); das letzte Fenster wird mit Stille aufgefüllt. Ein Fenster je `hopSeconds` ab Sekunde 0.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `seconds` | Zahl ≥ 0 | ja | – |
| `hopSeconds` | Zahl ≥ 0 | nein | – |

## Beispiel

Klassifikation langer Aufnahmen in Fenstern; danach z. B. `tensor.reduce` über die Fenster.

```json
{"type": "audio.frames", "parameters": {"seconds": 0.96, "hopSeconds": 0.48}}
```

## Fachliche Tests

- [`test_tiles_and_frames.py`](../../local-runtime/python/tests/test_tiles_and_frames.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
