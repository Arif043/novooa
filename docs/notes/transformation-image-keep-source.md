# Transformation `image.keepSource`

> Merkt sich das Originalbild, damit ein Ausgang es weiterverarbeiten kann.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

Das Bild reist als PNG in den Metadaten des Eingangs zum Ausgang. Es muss das Bild sein, auf das sich die Geometrie bezieht — also vor jedem Skalieren oder Zuschneiden stehen (nach `image.exifTranspose` ist erlaubt).

## Parameter

Keine.

## Beispiel

Erster Schritt (nach `image.exifTranspose`) eines Eingangs, dessen Ausgang `image.applyMask` nutzt.

```json
{"type": "image.keepSource", "parameters": {}}
```

## Fachliche Tests

- [`test_image_mask.py`](../../local-runtime/python/tests/test_image_mask.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Transformation image.applyMask](./transformation-image-apply-mask.md)
