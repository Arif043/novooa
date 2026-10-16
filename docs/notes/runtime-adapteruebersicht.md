# Runtime-Adapterübersicht

> Welche lokalen Adapter die fachlichen Ports der Runtime erfüllen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- `task_execution`: Task Runner, Node Executors und Ports für Definitionen,
  Runs, Aktivitäten und ausgehende Nachrichten. Dateien, Wissensbasis und
  Nachrichten erhält die Ausführung nur über injizierte Ports; die Handler
  verdrahten die konkreten Adapter.
- `teams`, `scheduling`, `communication`, `files`, `knowledge_base`,
  `notifications`: je eigene Domain-Verträge und Adapter.
- Lokale SQL-Adapter (Tasks, Runs, Aktivitäten, Auslöser, Wissensbasis,
  Ordner) erhalten die native Drizzle-Datenbank per Dependency Injection.
- `SQLiteTeamFileStore`: Dateien im lokalen Root-Verzeichnis, Metadaten per
  Drizzle.
- `SQLiteDocumentStore`: team-scoped Datensammlungen hinter `DocumentStore`
  (Felder intern als JSON); der Task-Worker nutzt ihn für **Datensatz suchen**
  und **Datensatz speichern**.
- Assistenten: alle über `GenkitAssistantResponder`. Lokal verdrahtet der
  Wissensbasis-Agent `SQLiteKnowledgeBaseAssistantNoteStore`,
  `SQLiteTeamContextStore` und den HTTP/HTML-Adapter; der
  Aufgabenstudio-Agent braucht außer Modell und Prompt keinen Fachadapter.
- ML: siehe [ONNX-Inferenz über den ML-Dienst](./onnx-inferenz-ml-dienst.md).

## Siehe auch

- [Runtime-Schichten](./runtime-schichten.md)
- [SQLite-Anbindung mit Drizzle](./sqlite-drizzle-anbindung.md)
