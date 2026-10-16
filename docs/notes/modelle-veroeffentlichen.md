# Modelle veröffentlichen

> Systemmodelle veröffentlicht nur der Betreiber über die CLI `models:publish`: Dateien in den globalen Modellspeicher, Katalogeintrag nach Firestore.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

Keine öffentliche Function, keine App-Oberfläche.

```bash
gcloud auth application-default login
export MODEL_STORE_S3_ENDPOINT=https://fsn1.your-objectstorage.com MODEL_STORE_S3_REGION=fsn1 \
  MODEL_STORE_S3_BUCKET=<bucket> MODEL_STORE_S3_ACCESS_KEY_ID=<schlüssel> MODEL_STORE_S3_SECRET_ACCESS_KEY=<geheimnis>
npm --prefix functions run models:publish -- \
  --project syscat-90bff \
  --manifest models/mobilenet-v3/model.json \
  --artifact models/mobilenet-v3/model.onnx \
  [--external-data models/mobilenet-v3/model.onnx.data] [--resource labels=models/mobilenet-v3/labels.json] \
  --dry-run
```

1. Manifest und Modell validieren; eine ONNX-Runtime-Session öffnen und Namen,
   Datentypen und statische Formen mit dem Manifest vergleichen (`--python
   <pfad>`, sonst `PYTHON_EXECUTABLE` oder `python3`).
2. Größe und SHA-256 aller Dateien berechnen.
3. Ohne `--dry-run`: Multipart-Upload (Prüfsumme in den Objekt-Metadaten),
   danach Katalogeintrag schreiben.

- Versionen sind unveränderlich: gleiche Prüfsumme wird übersprungen,
  abweichende ist ein Fehler.
- Gewichtsdateien liegen im Modellordner; ihr Dateiname ist der erwartete
  Name.
- Der S3-Schlüssel bleibt beim Betreiber. Die Identität braucht
  Schreibzugriff auf `modelCatalog`.
- Die CLI akzeptiert derzeit Bild- und Tensoreingänge, die registrierten
  Bildtransformationen und keine Ausgangsnachverarbeitung.

## Siehe auch

- [Modellordner und Manifestdatei](./modellordner-und-manifest.md)
- [Globaler Modellspeicher](./globaler-modellspeicher.md)
