# Datensammlungen in SQLite

> `SQLiteDocumentStore` speichert Felder als JSON in `documents.data_json`, Team, Sammlung, ID, Version und Zeitstempel als eigene Spalten; jeder Zugriff trägt die Team- und Sammlungsgrenze.

Gehört zu: [Daten](../index/daten.md)

- Tabellen `document_collections` und `documents` (Migrationen
  `012_document_store.sql`, `013_document_collection_display_name.sql` aus
  dem alten Migrationsstand; heute in der Initialmigration).
- Die Runtime vergibt eine interne Sammlungs-ID; Arbeitspläne nutzen nur den
  sichtbaren Namen. Namen sind je Team exakt eindeutig, Groß- und
  Kleinschreibung zählen („Kunden“ ≠ „kunden“).
- Die Runtime injiziert den Store in den lokalen Task-Worker.
- HTTP-API:
  - `GET /v1/data/collections`
  - `POST /v1/data/collections/{name}/query`
  - `POST /v1/data/collections/{name}/documents`
  - `PUT /v1/data/collections/{name}/documents/{id}`
  - `DELETE /v1/data/collections/{name}/documents/{id}`

Offen: Welche Felder bei wachsendem Volumen als SQLite-Ausdrucksindizes?

## Siehe auch

- [Datensammlungen: Fachmodell](./datensammlungen-fachmodell.md)
- [Runtime-Adapterübersicht](./runtime-adapteruebersicht.md)
