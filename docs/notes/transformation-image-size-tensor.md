# Transformation `image.sizeTensor`

> Liefert Bildmaße oder Skalierungsfaktoren als Tensor für Hilfseingänge eines Modells.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `tensor`

`height`/`width` sind die Maße des aktuellen (z. B. skalierten) Bildes, `sourceHeight`/ `sourceWidth` die des Originals, `scaleY`/`scaleX` der Skalierungsfaktor dazwischen. Gedacht für einen abgeleiteten Eingang (`binding: derived`) mit denselben Bildschritten wie der Bildeingang.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `values` | Liste aus `height` oder `width` oder `sourceHeight` oder `sourceWidth` oder `scaleY` oder `scaleX` | ja | – |

## Beispiel

Eingang `scale_factor` eines Paddle-Detektors (PP-DocLayout) mit `binding: {type: derived, inputName: image}` und denselben Bildschritten wie `image`.

```json
{"type": "image.sizeTensor", "parameters": {"values": ["scaleY", "scaleX"]}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Eingangsbindungen](./modell-eingangsbindungen.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
