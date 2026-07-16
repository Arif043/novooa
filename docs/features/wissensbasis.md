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
- Eine Obsidian-ähnliche Arbeitsfläche für Lesen, Schreiben und Verlinken
  anbieten.

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

## UI

Route: `/knowledge-base`, Drawer-Label: **Wissensbasis**.

Die Seite ist an Obsidian angelehnt:

- Links: Vault/Explorer mit Suche und „Notiz erstellen".
- Mitte: Umschaltbares Hauptpanel mit Markdown-Editor oder Graph-View.
- Rechts: Eigenschaften, Speicherstatus, verlinkte Notizen und Backlinks.

Die Graph-Ansicht orientiert sich am Obsidian-Look-and-Feel: dunkle Canvas,
organisch verteilte verschiebbare Punkt-Knoten, feine gedämpfte
Verbindungslinien, dezente Labels, Pan/Zoom und eine kleine Overlay-Leiste zum
Zurücksetzen der Ansicht. Verbundene Knoten werden beim Ziehen federnd
mitbewegt und springen beim Loslassen zurück. Kanten entstehen aus
`outgoingLinks`. Ein Klick auf einen Knoten selektiert die zugehörige Notiz im
Editor.

Änderungen werden per Debounce automatisch gespeichert. Nutzer:innen müssen
keinen Speichern-Button bedienen.

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

- Notizen können erstellt, bearbeitet und gelöscht werden.
- `outgoingLinks` werden clientseitig aus `[[Wiki Links]]` und
  Markdown-Links auf bekannte Notizen abgeleitet.
- Graph-View zeigt die aus `outgoingLinks` abgeleiteten Beziehungen.
- Prompt-Bausteine können Wissensnotizen anhängen.
- Script-Bausteine sind bewusst noch nicht angebunden.
- Import und robuste Legacy-Markdown-Migration folgen später.

## Offene Fragen

- Wie wird eine Legacy-Wissensbasis importiert und in stabile Notiz-IDs
  übersetzt?
- Werden Markdownlinks zusätzlich zu `outgoingLinks` serverseitig geparst?
- Welche Limits gelten pro Run für Anzahl Notizen, Rekursionstiefe und Bytes?

## Verwandt

[`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`dateien.md`](./dateien.md)
