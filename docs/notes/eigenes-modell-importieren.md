# Eigenes Modell importieren

> Ein Import besteht aus Manifest, ONNX-Datei und optionalen Gewichten; die Runtime streamt alles, prüft es und speichert einen teamgebundenen Eintrag.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

1. In der App ONNX-Datei und Gewichte in einem Schritt wählen: genau eine
   Datei endet auf `.onnx`, die übrigen gelten als Gewichte unter ihrem
   Namen.
2. `POST /v1/ml-models/imports {manifest}` → kurzlebige Import-ID.
3. Jede Gewichtsdatei, zuletzt das Artefakt per `PUT` als Binärstream.
4. Die Runtime schreibt jeden Stream direkt nach `model-imports/<id>/` und
   berechnet Größe und SHA-256 beim Empfang.
5. Erst mit dem Artefakt-Upload werden Manifest und Vertrag validiert
   ([Vertragsprüfung](./ml-vertragspruefung.md)) und alle Dateien zusammen
   übernommen; der Import-Ordner wird entfernt.

- Keine feste Größengrenze: Vor dem Schreiben prüft die Runtime anhand von
  `content-length` den freien Platz (`statfs`); optional begrenzt
  `MODEL_ARTIFACT_MAX_BYTES` jede Datei. JSON-Anfragen bleiben auf 1 MiB.
- Importe gehören immer dem aktiven Team und erscheinen auch in der
  Modellsuche. Ablage unter
  `model-artifacts/{artifactId}/versions/{versionId}/` im Runtime-Root.
- Tab und Endpunkte gibt es nicht in der Cloud.

## Siehe auch

- [ONNX-Größengrenzen](./onnx-groessengrenzen.md)
- [Machine-Learning-Einstellungen](./ml-einstellungen.md)
