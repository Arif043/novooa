# Bildgeometrie und Originalkoordinaten

> Jeder Bildeingang zeichnet auf, wie das Modellbild aus dem Original entstand (`modell = quelle × scale + offset`), damit Ausgänge ins Originalbild zurückgerechnet werden können.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Schritt | Wirkung auf die Geometrie |
| --- | --- |
| `image.resize`, `image.resizeShorterSide` | skaliert |
| `image.resizePad`, `image.resizeHeightPad` | skaliert und verschiebt (Rand) |
| `image.crop`, `image.centerCrop` | verschiebt |
| `image.decode`, `image.padToMultiple`, Tensorschritte | keine |
| `image.exifTranspose` | das gedrehte Foto wird zur Quelle |
| `image.perspectiveCrop` | nicht umkehrbar |

- Die Geometrie (dazu die Größe des Quellbildes) reist im Eingangstensor
  (`metadata`) bis zu den Ausgängen.
- `geometry.toSource` rechnet Boxen und Regionen, `mask.toSource` Masken und
  Karten zurück; `input` nennt den Bildeingang.
- `tensor.reshape`, `tensor.transpose`, `tensor.slice` am Eingang werden in
  der Geometrie nicht berücksichtigt.

## Siehe auch

- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [OCR-Pipeline](./ocr-pipeline.md)
