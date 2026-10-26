# Transformation `image.applyMask`

> Setzt eine Maske des Modells als Alphakanal auf das Originalbild (Freistellen).

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `imageFile`

Die Maske `[H, W]` liegt im Modellbild; über die Geometrie des Eingangs `input` wird sie auf das Originalbild abgebildet, das `image.keepSource` dort gemerkt hat. `range: unit` erwartet Werte 0…1 (z. B. nach `tensor.sigmoid`), `range: byte` 0…255. Ergebnis ist ein PNG mit Transparenz.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `input` | Text | ja | – |
| `range` | `unit` oder `byte` | nein | `"unit"` |
| `fileName` | Text | nein | `"freigestellt.png"` |

## Beispiel

BiRefNet: Ausgang nach `tensor.sigmoid`; der Eingang beginnt mit `image.keepSource`.

```json
{"type": "image.applyMask", "parameters": {"input": "image", "fileName": "freigestellt.png"}}
```

## Fachliche Tests

- [`test_image_mask.py`](../../local-runtime/python/tests/test_image_mask.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Transformation image.keepSource](./transformation-image-keep-source.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
