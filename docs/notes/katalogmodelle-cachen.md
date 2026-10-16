# Katalogmodelle cachen

> Standalone installiert Katalogmodelle nicht vorab, sondern cacht sie bei der Auswahl im Aufgabenstudio oder spätestens beim Lauf.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- **Auswahl im Aufgabenstudio:** `POST /v1/ml-models/catalog/:modelId/cache`
  startet das Vorladen im Hintergrund (`202`; `200`, wenn schon lokal).
  Fortschritt unter `GET /v1/ml-models/cache-status` (`downloading` oder
  `failed` mit Meldung); Realtime-Themen `model-cache` und für das fertige
  Modell `model-catalog`.
- **Beim Lauf:** Fehlt das Modell (nach Import einer Aufgabe oder Entfernen
  aus dem Cache), lädt `SelfCachingModelCatalog` es vor der Inferenz nach.
  Gleichzeitige Anfragen teilen sich einen Download (`CacheSystemModel`).

Ablauf von `CacheSystemModel` (Port `ModelArtifactPrefetcher`):

1. Modellvertrag gegen den ML-Dienst validieren.
2. Der ML-Dienst lädt die Dateien vor (`POST /v1/bundles`).
3. Eintrag teamgebunden mit `origin = catalog` speichern.

Die Runtime kopiert Katalogmodelle **nicht**; die Dateien liegen im
gemeinsamen Cache des Servers. Einträge bleiben, bis sie manuell entfernt
werden. Der Download-Status lebt nur im Speicher.

## Siehe auch

- [Machine-Learning-Einstellungen](./ml-einstellungen.md)
- [Modellbündel](./modellbuendel.md)
