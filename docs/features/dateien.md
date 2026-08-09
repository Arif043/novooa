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
- Aufgaben können über den Baustein **Datei schreiben** neue Dateien erzeugen.
- Arbeitsbereich mit generierter Team-ID automatisch bootstrappen.
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
users/{uid}.teamId = "{teamId}"
```

Die Team-ID ist eine generierte Dokument-ID und wird nicht aus der UID
abgeleitet. Die UI übergibt dem Dateien-Feature den aktuellen Team-Kontext aus
dem Team-Repository.

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

Jedes Version-Dokument trägt zusätzlich `createdAt`. Beim Anhängen wird dieser
Zeitpunkt als `versionCreatedAt` in der Node-Config gespeichert, damit die UI
die konkret referenzierte Version samt Erstellungszeit anzeigen kann.

### Inhalte und Versionsverlauf

Die Detailansicht einer Datei zeigt den Inhalt der gewählten Version und einen
chronologischen Verlauf. Textdateien und JSON können dort bearbeitet werden.
Das Sichern erzeugt immer eine neue Version; vorhandene Versionen werden weder
überschrieben noch verändert. Die aktuelle Version ist im Verlauf hervorgehoben,
während ältere Stände jederzeit zur Ansicht ausgewählt werden können.

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

Der Baustein **Datei schreiben** ist kein Attachment-Input, sondern ein
Persistenz-Output. Er schreibt den String-Output des Vorgänger-Nodes als neue
Datei ins Root-Verzeichnis des Team-Dateibereichs oder als neue Version einer
bestehenden Datei. Wenn im Root-Dateibereich bereits eine Datei mit demselben
Namen existiert, wird keine zweite Datei mit identischem Namen erzeugt, sondern
eine neue Version unter der bestehenden `fileId` geschrieben. Bei neuen
Versionen bleibt `fileId` stabil; nur `currentVersionId`, `storagePath`,
`sizeBytes`, `contentType` und `updatedAt` werden am Datei-Dokument
aktualisiert.

Erkennt der Baustein einen Bild-Prompt-Output als Base64-Data-URL, dekodiert er
die Bilddaten und speichert sie binär. MIME-Type und Dateiendung werden dabei
aus der Data-URL abgeleitet; eine zuvor konfigurierte Text-Endung wird ersetzt.

In der Task-Builder-UI wird dafür kein technisches Datei-ID-Feld angezeigt.
Nutzer:innen wählen im Dialog entweder eine bestehende Datei oder definieren
eine neue Datei über Dateiname und optionalen Content-Type.

Der Baustein **Datei lesen** ist das Gegenstück dazu. Er verwendet dieselbe
Dateiauswahl wie Attachments, speichert aber genau eine konkrete Version als
`NodeAttachment` in der Node-Config. Bei der Ausführung lädt der Backend-Runner
den referenzierten Storage-Pfad und gibt den UTF-8-Inhalt als String-Output des
Bausteins weiter.

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
