# Objekterkennung und Segmentierung

> YOLO-Detektoren und Segmentierungsmodelle lassen sich allein über Manifest-Transformationen anbinden, mit Ergebnissen in Originalkoordinaten.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

## YOLOv8

Ausgang `[1, 4 + Klassen, 8400]` mit Mittelpunkt-Boxen im 640er-Raster;
Eingang mit `image.resizePad` auf 640×640 (mittig); Klassennamen als
Ressource `labels.txt`:

```json
"transformations": [
  {"type": "tensor.squeeze", "parameters": {}},
  {"type": "tensor.transpose", "parameters": {"axes": [1, 0]}},
  {"type": "tensor.nonMaximumSuppression", "parameters": {
    "box": {"centerX": 0, "centerY": 1, "width": 2, "height": 3},
    "classScores": {"start": 4}, "scoreThreshold": 0.25, "iouThreshold": 0.45, "maxDetections": 100}},
  {"type": "resource.lookup", "parameters": {"resource": "labels.txt", "key": "classIndex"}},
  {"type": "geometry.toSource", "parameters": {"input": "bild"}}
]
```

Ergebnis: `[{index, score, classIndex, label, box: {left, top, right,
bottom}}]` in Pixeln des Originals. YOLOv5 ergänzt `"objectnessIndex": 4` und
`"classScores": {"start": 5}`; normierte Koordinaten (0…1) nutzen `boxScale`.
Test: `tests/test_detector_formats.py`.

## Segmentierung als Bild

Klassen eingefärbt, in Originalgröße:

```json
"transformations": [
  {"type": "tensor.argmax", "parameters": {"axis": 1}},
  {"type": "mask.toSource", "parameters": {"input": "bild"}},
  {"type": "image.encode", "parameters": {"palette": [[0, 0, 0], [255, 0, 0], [0, 128, 255]]}}
],
"workflowOutput": {"name": "segmente", "type": "image", "mapping": "$tensor"}
```

## Siehe auch

- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
- [Transformationskatalog](./transformationskatalog.md)
