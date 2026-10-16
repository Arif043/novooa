# Runtime-API des nativen Clients

> Der Client spricht REST-Ressourcen unter `/v1/<collection>`; sie sind Runtime-APIs im lokalen Netz, kein Cloud-HTTP-Vertrag.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

| Ressource | Endpunkte |
| --- | --- |
| Aufgaben | `GET`, `PUT`, `DELETE /v1/tasks` |
| Runs, Aktivitäten | `GET /v1/task-runs`, `GET /v1/activities` |
| Wissensnotizen | `/v1/knowledge-notes` |
| Zeitpläne | `/v1/task-triggers` |
| Dateien, Ordner | `/v1/files`, `/v1/folders` |
| Mitarbeiter | `/v1/employees` |
| Protokoll | `/v1/application-logs` |

Konvention: Listen als `{items: [...]}`, `POST` legt an, `PUT` schreibt
(Upsert), `DELETE` löscht; das Realtime-Thema heißt wie die Collection.

Dateien gehen als Base64-kodierte JSON-Payloads an die Runtime und werden im
Volume abgelegt.

Die UI-Vorschau ersetzt genau diese Schnittstelle durch In-Memory-Transporte
([UI-Vorschau](../architecture/ui-vorschau.md)).

## Siehe auch

- [Anfrage-Pipeline: Lizenz → Session → Route](./runtime-anfrage-pipeline.md)
- [Verschlüsselter Transport über http](./verschluesselter-transport.md)
