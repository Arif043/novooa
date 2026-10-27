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
- HTTP-API (`local-data-collection-routes.ts`, `local-data-document-routes.ts`,
  `local-data-transfer-routes.ts`):
  - `GET /v1/data/collections`, `POST /v1/data/collections` (anlegen; 409 bei
    belegtem Namen)
  - `PUT /v1/data/collections/{name}` (umbenennen; 409),
    `DELETE /v1/data/collections/{name}` (samt Datensätzen)
  - `POST /v1/data/collections/{name}/query` (Suche, Filter, `sort`)
  - `POST /v1/data/collections/{name}/documents`,
    `PUT …/documents/{id}`, `DELETE …/documents/{id}`
  - `DELETE /v1/data/collections/{name}/documents` (leeren),
    `POST …/documents/delete` mit `ids` (Mehrfachlöschen, höchstens 500)
  - `POST …/export`, `POST …/import`
    ([Import und Export von Datensammlungen](./datensammlungen-import-export.md))
- Sortierung in SQL: Rang der Wertart per `json_type`, dann
  `json_extract(...) COLLATE NOCASE`, danach Änderungszeit und ID
  (`sqlite-document-sort.ts`) — dieselbe Ordnung wie der In-Memory-Store.
- Löschen einer Sammlung entfernt ihre Datensätze in derselben Transaktion
  ausdrücklich, unabhängig vom Fremdschlüssel.

Offen: Welche Felder bei wachsendem Volumen als SQLite-Ausdrucksindizes?

## Siehe auch

- [Datensammlungen: Fachmodell](./datensammlungen-fachmodell.md)
- [Runtime-Adapterübersicht](./runtime-adapteruebersicht.md)
