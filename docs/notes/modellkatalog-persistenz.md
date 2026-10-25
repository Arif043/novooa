# Persistenz des Modellkatalogs

> Der globale Katalog liegt in Firestore (`modelCatalog/{modelId}`), die Runtime hält ihre Modelle in SQLite (`model_catalog`); beide erfüllen den Port `ModelCatalog`.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- `FirestoreModelCatalog` erfüllt zusätzlich `SystemModelCatalog`
  (`listSystemEntries`) für Aufrufer ohne Team.
- Der globale Firestore-Katalog ist die **primäre Quelle** für ONNX-Modelle.
  Die Runtime liest ihn nach der Firebase-Anmeldung über
  `GET /v1/ml-models/catalog` (ohne Firebase-Sitzung `503`) und cacht Modelle
  erst bei Bedarf.
- SQLite-Spalten: `origin` (`catalog` oder `import`, Migration
  `0020_model_catalog_origin.sql`; ältere Einträge gelten als Import),
  `task`, `languages_json`, `translations_json`.
- Systemmodell vs. Teammodell über `team_id`
  ([Normalisierung 0015](./sqlite-modellkatalog-normalisiert.md)).

## Siehe auch

- [Katalogmodelle cachen](./katalogmodelle-cachen.md)
- [Modellsuche](./modellsuche.md)
