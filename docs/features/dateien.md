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

### Standalone: normalisierte Versionsmetadaten

In SQLite enthält `files` die Dateiidentität, Teamzuordnung, Besitzer, Namen,
Ordner, Zeitstempel und `current_version_id`. `file_versions` enthält die
Versionen mit ihrem jeweiligen Namen, Ersteller, Speicherpfad, Dateityp,
Dateigröße und Erstellungszeitpunkt. `content_type`, `size_bytes` und
`storage_path` werden nicht zusätzlich in `files` gespeichert. Die Version
verweist über `file_id` auf ihre Datei; eine eigene `team_id` ist nicht nötig.

Ein zusammengesetzter Fremdschlüssel von
`files(id, current_version_id)` auf `file_versions(file_id, id)` verhindert
die Auswahl einer Version einer anderen Datei. Der Versions-Fremdschlüssel
löscht beim Entfernen einer Datei ihre Versionen mit. Negative Dateigrößen
werden durch einen CHECK-Constraint abgelehnt.

Neue Dateien werden innerhalb einer Transaktion zunächst ohne aktuelle
Version angelegt; anschließend werden Version und Versionsreferenz geschrieben.
Der lokale Adapter setzt Listenansichten und fachliche Rückgaben über Joins
zusammen. Team-scoped Versionsabfragen lösen das Team über `files` auf.
Die HTTP-DTOs und Domain-Verträge bleiben unabhängig von dieser SQL-Struktur.

Die Schemaänderung liegt in `0009_normalize_file_versions.sql` samt
Drizzle-Snapshot. Ein temporärer Sicherungsbestand während des Tabellenumbaus
verhindert, dass die vorhandene Löschkaskade die Versionen entfernt.

### Cloud: separater Firestore-Adapter

Der Cloud-Adapter verwendet weiterhin die folgenden Dokumentpfade. Die
normalisierte SQLite-Struktur erfordert keine Änderung der Firestore-Dokumente.
Die dort zusätzlich gespeicherten aktuellen Versionsmetadaten sind eine
abgeleitete Darstellung für Lesezugriffe; neue Version und aktuelle
Versionsmetadaten werden gemeinsam geschrieben.

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
Tabellenkalkulationsdateien (`.xlsx`) werden schreibgeschützt als Tabelle mit
Blattauswahl angezeigt (`package:excel`) — Fettformatierung aus der Quelldatei
wird übernommen, Zellen mit E-Mail-Adressen oder Web-URLs erscheinen als
anklickbare Links; PDF-Dateien werden über `package:pdfx` mit
Seitennavigation und Zoom dargestellt.

### Versionsrotation

Pro Datei werden nur die letzten N Versionen behalten; die aktuelle Version
bleibt immer erhalten. Ältere Versionen werden samt Storage-Objekt gelöscht.
Referenzen auf rotierte Versionen (z. B. `NodeAttachment` mit konkreter
`versionId`) lassen sich danach nicht mehr laden.

- **novooa Cloud:** festes Limit von 10. Der Firestore-Trigger
  `rotateFileVersions` (`onDocumentCreated` auf `…/versions/{versionId}`)
  rotiert nach jeder neuen Version — auch bei direkten Client-Uploads. Er
  löscht über das Admin-SDK; die Storage-Regeln (nur `create`) bleiben
  unverändert.
- **Standalone:** `LocalTeamFileStore` rotiert nach jedem Schreiben. Das Limit
  (1–1000, Standard 10) wird pro Arbeitsbereich in `workspace_file_settings`
  gespeichert und in der UI unter „Einstellungen" → „Allgemein" →
  „Dateiversionen" festgelegt (`GET`/`PUT /v1/file-settings`). Eine Änderung
  greift beim nächsten Schreiben einer Version; bereits vorhandene
  Überhangversionen werden dann mit entfernt.

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

Dateien lassen sich über `DELETE /v1/files/:fileId` löschen (lokale Runtime):
Metadaten, alle Versionen und Dateiinhalte werden entfernt. Im Client gibt es
dafür die Aktion „Löschen" mit Bestätigung am Dateieintrag. Schreiben, neue
Versionen und Löschen lösen Datei-Ereignisse für Event-Trigger aus
(siehe [`zeitplan.md`](./zeitplan.md) § Datei-Ereignisse).

Der Baustein **Datei schreiben** ist kein Attachment-Input, sondern ein
Persistenz-Output. Er schreibt den String-Output des Vorgänger-Nodes als neue
Datei in ein wählbares Verzeichnis des Team-Dateibereichs (`folderId` in der
Node-Config, ohne Angabe: oberste Ebene) oder als neue Version einer
bestehenden Datei, die in ihrem Verzeichnis bleibt. Wenn im Root-Dateibereich bereits eine Datei mit demselben
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
eine neue Datei über Dateiname und Zielverzeichnis. Bestehende Dateien lassen
sich über Chips nach Kategorie filtern (Text, Bilder, Video, Audio, PDF,
Tabellen; angeboten werden nur Kategorien mit Dateien). Unter „Neu" kann das
Zielverzeichnis gewählt und über „Neuer Ordner" direkt angelegt werden — im
jeweils gewählten Verzeichnis. Den Content-Type bestimmt der Executor selbst
(`text/plain`, bei Bildern und Tabellen aus dem Quellwert).

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
- Wie werden hochgeladene Dateien in Prompt-Bausteinen ausgewählt?

## Verwandt

- [`../architecture.md`](../architecture.md)
- [`aufgabe.md`](./aufgabe.md)

## Standalone: Ordnerbeziehungen

Seit Migration `0016` sichern zusammengesetzte SQLite-Fremdschlüssel ab,
dass Elternordner und Dateiablage zum selben Team gehören. Wurzelordner und
Dateien ohne Ordner bleiben möglich. Selbstbezüge und Zyklen werden auch
bei direkten SQL-Schreibzugriffen abgelehnt.

Ein Ordnerbaum mit enthaltenen Dateien kann nicht direkt gelöscht werden.
Dateien müssen vorher über den Datei-Adapter gelöscht oder gültig umgeordnet
werden; die SQLite-Löschkaskade selbst entfernt keine Dateiinhalte auf dem
Dateisystem. Für leere Ordnerbäume bleibt die Unterordnerkaskade erhalten.

Der lokale Datei-Adapter prüft den Ordner innerhalb seiner Schreibtransaktion
und bereinigt neue Dateiinhalte bei fehlgeschlagener Metadatenanlage. Migration
und Import/Export erhalten Versionen einschließlich ihrer Rotationsreihenfolge.
Firestore verwendet weiterhin seinen eigenen Adapter.

Die SQL-Zyklusprüfung verwendet rekursive Abfragen innerhalb der Trigger-
Unterabfrage, entsprechend der [SQLite-Trigger-Dokumentation](https://www.sqlite.org/lang_createtrigger.html).
