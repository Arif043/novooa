# Feature: Dateien

> Datei-Ablage für Aufgaben-Bausteine. Nutzer:innen laden Dateien hoch, die
> später an unterstützende Nodes wie Prompt-Bausteine angehängt werden können.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md)

## Zweck

Das Feature stellt eine teamfähige Dateiablage bereit. Heute nutzt die App
einen persönlichen Arbeitsbereich pro Nutzer:in; später kann derselbe
Datenpfad für echte Teams verwendet werden. Dateien werden in Firebase Storage
gespeichert, Metadaten und Versionen in Firestore.

## Verantwortlichkeiten

- Dateien über die Subpage **Dateien** hochladen.
- Verzeichnisse für eine bessere Übersicht erstellen und öffnen.
- Datei-Metadaten live aus Firestore anzeigen.
- Uploads in Firebase Storage unter einem team-scoped Pfad speichern.
- Hochgeladene Dateien in unterstützten Aufgaben-Bausteinen auswählen.
- Persönlichen Arbeitsbereich `personal_<uid>` automatisch bootstrappen.
- Versionierung vorbereiten: jede Datei verweist auf `currentVersionId`.
- Domain-Schicht frei von Firebase-, Flutter- und Picker-Abhängigkeiten halten.

## Datenmodell

Firestore:

```text
teams/{teamId}
teams/{teamId}/members/{uid}
teams/{teamId}/folders/{folderId}
teams/{teamId}/files/{fileId}
teams/{teamId}/files/{fileId}/versions/{versionId}
```

Storage:

```text
teams/{teamId}/files/{fileId}/versions/{versionId}/{fileName}
```

Aktueller Team-Kontext:

```text
teamId = personal_<uid>
```

Die persönliche Team-ID ist ein Übergangsmodell. Sobald das Team-Feature
eingeführt wird, soll die UI statt `TeamId.personal(uid)` den aktuell
ausgewählten Team-Kontext an das Dateien-Feature übergeben.

### Verzeichnisse

Verzeichnisse sind Firestore-Metadaten und verändern die Storage-Pfade nicht.
Ein Ordner-Dokument liegt unter:

```text
teams/{teamId}/folders/{folderId}
```

Relevante Felder:

```text
id, teamId, ownerUid, name, parentFolderId, createdAt, updatedAt
```

Dateien speichern optional `folderId`. `null` bedeutet Root-Verzeichnis.
Unterverzeichnisse nutzen `parentFolderId`; auch hier bedeutet `null` Root.
Damit bleibt die bestehende Copy-on-Write-Struktur für Datei-Versionen stabil.

## Copy-on-Write

Der erste Upload erzeugt eine Datei und eine erste Version. Spätere Änderungen
sollen nicht dieselbe Storage-Datei überschreiben, sondern eine neue Version
unter demselben `fileId` anlegen:

```text
teams/{teamId}/files/{fileId}/versions/{newVersionId}/{fileName}
```

Das Datei-Dokument aktualisiert dann nur `currentVersionId`, `storagePath`,
`sizeBytes`, `contentType` und `updatedAt`. Alte Versionen bleiben
referenzierbar.

## Nutzung in Aufgaben

Unterstützende Node-Configs implementieren `FileAttachmentSupport` und speichern
eine Liste von `NodeAttachment`s. Die UI lädt auswählbare Dateien über
`WatchTeamFiles` aus dem aktuellen Team-Kontext und referenziert beim Anhängen
die aktuelle Dateiversion.

Bei der Ausführung lädt der Functions-Runner angehängte Storage-Dateien in ein
temporäres Verzeichnis und übergibt diesen Workspace an den jeweiligen
Node-Executor. Prompt-Nodes erhalten ihn über die Genkit-Filesystem-Middleware
(`@genkit-ai/middleware`) als read-only Workspace. Script-Nodes erhalten
stattdessen Python-Hilfsfunktionen wie `list_files()` und `read_file(name)`.

## Security

- Firestore-Zugriff basiert auf `teams/{teamId}/members/{uid}`.
- Persönliche Teams dürfen nur von der zugehörigen Nutzer:in erstellt werden.
- Verzeichnisse dürfen von Team-Mitgliedern erstellt und gelesen werden.
- Storage-Uploads sind auf Team-Mitglieder und 50 MB begrenzt.
- Storage erlaubt nur `create` für Versionen, kein Überschreiben oder Löschen.

## Offene Fragen

- Wie wird der aktive Team-Kontext global gewählt und gespeichert?
- Welche Rollenrechte brauchen Team-Mitglieder für Upload, Lesen und Löschen?
- Wann werden alte Dateiversionen aufgeräumt oder archiviert?
- Wie werden hochgeladene Dateien in Prompt-Bausteinen ausgewählt?

## Verwandt

- [`../architecture.md`](../architecture.md)
- [`aufgabe.md`](./aufgabe.md)
