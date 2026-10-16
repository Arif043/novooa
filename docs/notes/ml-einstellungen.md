# Machine-Learning-Einstellungen

> Der Tab „Machine Learning“ (nur Standalone) zeigt gecachte und eigene Modelle; den Katalog selbst durchsucht man im Aufgabenstudio.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- **Gecachte Modelle** (`origin = catalog`): Größe, laufende oder
  gescheiterte Downloads, „Aus dem Cache entfernen“.
- **Eigene Modelle** (`origin = import`): siehe
  [Eigenes Modell importieren](./eigenes-modell-importieren.md).

```text
GET    /v1/ml-models                         gecachte und eigene Modelle (mit origin)
GET    /v1/ml-models/catalog                 globaler Katalog (503 ohne Firebase-Sitzung)
POST   /v1/ml-models/catalog/:modelId/cache  Hintergrund-Download starten
GET    /v1/ml-models/cache-status            laufende und gescheiterte Downloads
POST   /v1/ml-models/imports                 { manifest }
PUT    /v1/ml-models/imports/:id/external-data/:name  application/onnx (Gewichte, optional, zuerst)
PUT    /v1/ml-models/imports/:id/artifact    application/onnx (Binärstream, schließt den Import ab)
DELETE /v1/ml-models/:id                     aus dem Cache entfernen / Import löschen
```

Entfernen löscht auch die Artefaktdateien, sofern kein anderer Eintrag
dieselbe Artefaktversion nutzt. Aufgaben mit einem entfernten Katalogmodell
laden es beim nächsten Lauf neu; ein entferntes eigenes Modell ist weg.

## Siehe auch

- [Katalogmodelle cachen](./katalogmodelle-cachen.md)
