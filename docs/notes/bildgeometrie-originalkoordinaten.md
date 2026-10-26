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
| `image.tiles` | nicht umkehrbar; das Kachelraster reist stattdessen mit (`tensor.untile`) |
| `image.keepSource`, `image.sizeTensor` | keine |

- Die Geometrie (dazu die Größe des Quellbildes) reist im Eingangstensor
  (`metadata`) bis zu den Ausgängen, ebenso das Kachelraster (`tiles`) und
  ein mit `image.keepSource` gemerktes Quellbild (`sourceImage`, als PNG).
- `geometry.toSource` rechnet Boxen, Regionen und Keypoints, `mask.toSource`
  Masken und Karten zurück; `image.applyMask` setzt eine Maske als Alphakanal
  aufs Quellbild; `input` nennt den Bildeingang.
- `image.sizeTensor` gibt Maße und Skalierung als Tensor an Hilfseingänge
  eines Modells weiter (z. B. `scale_factor`).
- `tensor.reshape`, `tensor.transpose`, `tensor.slice` am Eingang werden in
  der Geometrie nicht berücksichtigt.

## Siehe auch

- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [OCR-Pipeline](./ocr-pipeline.md)
