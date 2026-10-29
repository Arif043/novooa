# Datenmodell der Wissensnotizen

> Wissensnotizen sind team-scoped Markdown-Dokumente einer Wissensbasis; sie werden bewusst nicht versioniert.

Gehört zu: [Wissensbasis](../index/wissensbasis.md)

Gespeichert in SQLite (`knowledge_notes`).

| Feld | Typ | Bedeutung |
| --- | --- | --- |
| `knowledgeBaseId` | `string` | aktuell `default` |
| `title` | `string` | Anzeigename, pro Wissensbasis eindeutig (ohne Groß/Klein) |
| `path` | `string` | importierter Markdown-Pfad |
| `content` | `string` | Markdown-Inhalt |
| `outgoingLinks` | `list<string>` | verlinkte Notiz-IDs (in SQLite berechnet) |
| `createdAt` | `timestamp` | Anlage |
| `updatedAt` | `timestamp` | Änderung |

Warum keine Versionen: Die Wissensbasis ist ein lebendiger Zettelkasten;
Dateien behalten dagegen ihre [Copy-on-Write-Versionen](./datei-copy-on-write.md).
Wissensbasis und normale Dateien bleiben getrennt.

## Siehe auch

- [Links zwischen Wissensnotizen](./wissenslinks-syntax.md)
- [Wissenslinks werden beim Lesen berechnet (0019)](./sqlite-wissenslinks-berechnet.md)
