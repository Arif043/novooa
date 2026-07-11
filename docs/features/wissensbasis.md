# Feature: Wissensbasis

## Zweck

Die Wissensbasis stellt Markdown-Notizen nach der Zettelkasten-Methode für
KI-Bausteine bereit. Sie ist kein eigener Workflow-Baustein, sondern wird wie
ein fachlicher Anhang an unterstützte Bausteine gehängt.

## Verantwortlichkeiten

- Markdown-Notizen team-scoped in Firestore modellieren.
- Atomare Notizen als einzelne Informationsbausteine bereitstellen.
- MOC-Notizen als Einstiegspunkt in verlinkte Notizen behandeln.
- Rekursive MOC-Auflösung serverseitig beim TaskRun durchführen.
- Genkit die aufgelösten Notizen über die Filesystem-Middleware bereitstellen.
- Normale Dateien und Wissensbasis getrennt halten.

## Datenmodell

Firestore:

```text
teams/{teamId}/knowledgeBases/{knowledgeBaseId}
teams/{teamId}/knowledgeBases/{knowledgeBaseId}/notes/{noteId}
```

Notizfelder:

| Feld              | Typ              | Bedeutung                                      |
| ----------------- | ---------------- | ---------------------------------------------- |
| `knowledgeBaseId` | `string`         | Aktuell `default`                              |
| `title`           | `string`         | Anzeigename                                    |
| `path`            | `string`         | Importierter Markdown-Pfad                     |
| `type`            | `atomic\|moc`    | Einzelnotiz oder Map-of-Content                |
| `content`         | `string`         | Markdown-Inhalt                                |
| `outgoingLinks`   | `list<string>`   | Verlinkte Notiz-IDs                            |
| `createdAt`       | `timestamp`      | Anlagezeitpunkt                                |
| `updatedAt`       | `timestamp`      | Änderungszeitpunkt                             |

Die Wissensbasis wird bewusst nicht versioniert. Normale Dateien behalten ihre
Copy-on-Write-Versionierung unter `teams/{teamId}/files/{fileId}/versions`.

## Node-Anhänge

Unterstützte NodeConfigs speichern `knowledgeAttachments` zusätzlich zu
`attachments`. Ein Anhang enthält nur Referenz-Metadaten:

```json
{
  "knowledgeBaseId": "default",
  "noteId": "note.1",
  "title": "Index",
  "path": "index.md",
  "type": "moc"
}
```

Beim TaskRun lädt das Backend die referenzierten Notizen. Atomare Notizen werden
nur einzeln bereitgestellt. MOC-Notizen werden inklusive indirekter Links
rekursiv aufgelöst und unter `knowledge/` in den Genkit-Workspace geschrieben.

## Aktueller Scope

- Prompt-Bausteine können Wissensnotizen anhängen.
- Script-Bausteine sind bewusst noch nicht angebunden.
- Import, Editor und Link-Erkennung für Legacy-Markdown folgen später.
- Clientseitige Schreibrechte für Notizen sind in den Rules noch gesperrt.

## Offene Fragen

- Wie wird eine Legacy-Wissensbasis importiert und in stabile Notiz-IDs
  übersetzt?
- Werden Markdownlinks zusätzlich zu `outgoingLinks` serverseitig geparst?
- Welche Limits gelten pro Run für Anzahl Notizen, Rekursionstiefe und Bytes?

## Verwandt

[`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`dateien.md`](./dateien.md)
