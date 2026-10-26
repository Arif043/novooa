# Modelle veröffentlichen

> Systemmodelle veröffentlicht nur der Betreiber über die CLI `models:publish`: Dateien in den globalen Modellspeicher, Katalogeintrag nach Firestore.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

Keine öffentliche Function, keine App-Oberfläche.

```bash
gcloud auth application-default login
export MODEL_STORE_S3_ENDPOINT=https://models.arif-it.de MODEL_STORE_S3_REGION=garage \
  MODEL_STORE_S3_BUCKET=web-novooa-models.arif-it.de MODEL_STORE_S3_ACCESS_KEY_ID=<schlüssel> MODEL_STORE_S3_SECRET_ACCESS_KEY=<geheimnis>
npm --prefix functions run models:publish -- \
  --project syscat-90bff \
  --manifest models/mobilenet-v3/model.json \
  --artifact models/mobilenet-v3/model.onnx \
  [--external-data models/mobilenet-v3/model.onnx.data] [--resource labels=models/mobilenet-v3/labels.json] \
  [--replace-version] --dry-run
```

Neue Tags zuerst eintragen und veröffentlichen:
`npm --prefix functions run models:tags:publish -- --project syscat-90bff [--dry-run]`
(liest `models/tags.json`, siehe [Tag-Vokabular](./modell-tag-vokabular.md)).

1. Manifest lesen (`task` ist Pflicht) und den Vertrag mit derselben
   [Vertragsprüfung](./ml-vertragspruefung.md) wie beim Cachen prüfen: Kette,
   Parameter und Setting-Bindungen aller Ein- und Ausgänge
   (`contract_validation_worker.py`).
2. Eine ONNX-Runtime-Session öffnen und Namen, Datentypen und feste Formen mit
   dem Manifest vergleichen (`onnx_validation_worker.py`). Dynamische Achsen
   des Modells nehmen jede Größe an; ZipMap-Ausgänge gelten als `float32`.
   Ausgänge, die Transformationen über Parameter lesen (`tensor.concat`,
   `keypoints.fromSimcc`), müssen im Modell existieren.
3. Größe und SHA-256 aller Dateien berechnen.
4. Im Katalog nachsehen: Jeder Tag muss im globalen Vokabular stehen
   (`models:install-local` prüft gegen `models/tags.json`). Steht unter der
   Modell-ID schon eine andere Artefaktversion, bricht die CLI ab, außer mit
   `--replace-version`.
5. Ohne `--dry-run`: Multipart-Upload (Prüfsumme in den Objekt-Metadaten),
   danach Katalogeintrag schreiben.

Beide Python-Prüfungen nutzen `--python <pfad>`, sonst `PYTHON_EXECUTABLE`
oder `python3`, mit den Paketen aus `local-runtime/python/requirements.txt`.

- Versionen sind unveränderlich: gleiche Prüfsumme wird übersprungen,
  abweichende ist ein Fehler.
- Warum `--replace-version`: Der Katalog führt je Modell-ID eine Version. Eine
  neue ersetzt sie für alle Runtimes, die das Modell noch nicht gecacht haben;
  das soll nie versehentlich geschehen. Dieselbe Version erneut zu
  veröffentlichen (etwa für korrigierte Texte) ist ohne Option erlaubt.
- Gewichtsdateien liegen im Modellordner; ihr Dateiname ist der erwartete
  Name.
- Ziel ist der Garage-Bucket auf unserem VPS ([Modellspeicher auf Garage](./modellspeicher-garage.md)).
- Der S3-Schlüssel bleibt beim Betreiber. Die Identität braucht Lese- und
  Schreibzugriff auf `modelCatalog`.
- `models:install-local -- --runtime-root <ordner>` prüft genauso und schreibt
  in den lokalen Modellspeicher einer Runtime.

## Siehe auch

- [Modellordner und Manifestdatei](./modellordner-und-manifest.md)
- [Globaler Modellspeicher](./globaler-modellspeicher.md)
