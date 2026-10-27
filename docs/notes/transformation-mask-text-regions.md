# Transformation `mask.textRegions`

> Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab — die DB-Nachverarbeitung von DBNet und PP-OCR.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `regions`

Schwelle, Dilatation und Mindestscore wie bei DBNet; `unclipRatio` vergrößert
jede Region wie das „Unclip“ der Referenz je Seite um `Fläche × unclipRatio /
Umfang`, weil das Modell nur den Kern einer Textzeile markiert (für
achsenparallele Boxen exakt). Ohne Unclip werden Ober- und Unterlängen
abgeschnitten, und der Recognizer liest falsch. `padding` fügt danach einen
festen Rand hinzu.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `threshold` | Zahl 0…1 | nein | `0.3` |
| `minimumPixels` | ganze Zahl ≥ 0 | nein | `1` |
| `minimumScore` | Zahl 0…1 | nein | `0` |
| `dilationWidth` | ganze Zahl ≥ 1 | nein | `1` |
| `dilationHeight` | ganze Zahl ≥ 1 | nein | `1` |
| `padding` | ganze Zahl ≥ 0 | nein | `0` |
| `unclipRatio` | Zahl ≥ 0 (PP-OCR: 1,6) | nein | `0` |

## Beispiel

Aus `models/pp-ocr-v6/detector/model.json`:

```json
{"type": "mask.textRegions", "parameters": {"threshold": 0.3, "minimumPixels": 8, "minimumScore": 0.5, "dilationWidth": 2, "dilationHeight": 2, "unclipRatio": 1.6}, "result": "detectedRegions"}
```

## Fachliche Tests

Ende zu Ende im [Referenztest von PP-OCRv6](../../local-runtime/python/tests/test_reference_pp_ocr_v6.py) gegen RapidOCR; Einzeltests:

- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
- [OCR-Pipeline](./ocr-pipeline.md)
