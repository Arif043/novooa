# Feature: Wissensbasis

## Zweck

Die Wissensbasis stellt Markdown-Notizen nach der Zettelkasten-Methode für
KI-Bausteine bereit. Sie ist kein eigener Workflow-Baustein, sondern wird wie
ein fachlicher Anhang an unterstützte Bausteine gehängt.

## Verantwortlichkeiten

- Markdown-Notizen team-scoped in Firestore modellieren.
- Einheitliche Markdown-Notizen als Informationsbausteine bereitstellen.
- Rekursive Link-Auflösung serverseitig beim TaskRun durchführen.
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
| `content`         | `string`         | Markdown-Inhalt                                |
| `outgoingLinks`   | `list<string>`   | Verlinkte Notiz-IDs                            |
| `createdAt`       | `timestamp`      | Anlagezeitpunkt                                |
| `updatedAt`       | `timestamp`      | Änderungszeitpunkt                             |

Die Wissensbasis wird bewusst nicht versioniert. Normale Dateien behalten ihre
Copy-on-Write-Versionierung unter `teams/{teamId}/files/{fileId}/versions`.

## UI

Route: `/knowledge-base`, Drawer-Label: **Wissensbasis**.

Die Seite kombiniert einen Obsidian-artigen Notiz-Workflow mit dem Designsystem
„Luminous Precision“ (Inter, ruhige Flächen, dezente Orange-Akzente):

- Links: Notizliste mit Suche, Inhaltsvorschau und „Notiz erstellen".
- Mitte: Dokumentfläche mit „Schreiben“, „Lesen“ und „Graph“ sowie sichtbarem Speicherstatus.
- Rechts: Eigenschaften, Speicherstatus, verlinkte Notizen und Backlinks.

### Lesen-Ansicht (Markdown-Rendering)

„Lesen“ rendert die Notiz mit `flutter_markdown_plus` als GitHub-Flavored
Markdown (`KnowledgeMarkdownPreview`): Überschriften `#`–`######`, **fett**,
*kursiv*, ~~durchgestrichen~~, ungeordnete, nummerierte und Aufgabenlisten,
Tabellen, Zitate, Inline-Code und Codeblöcke, horizontale Linien, Bilder,
Autolinks und Emoji-Kürzel (`:smile:`). Der Text ist markierbar.

- `[[Ziel]]` und `[[Ziel|Anzeigetext]]` werden über `KnowledgeWikiLinkSyntax`
  zu Links auf die Notiz. Ohne passende Notiz bleibt der Wiki-Link als Text
  stehen.
- Markdown-Links auf eine Notiz (`[Text](leitfaden.md)`) öffnen ebenfalls die
  Notiz. Die Zuordnung „Linkziel → Notiz“ (ID, Titel, Pfad mit/ohne `.md`)
  liegt im Domain-Service `KnowledgeNoteResolver`, den auch
  `MarkdownLinkExtractor` für Graph und Backlinks nutzt.
- `http`, `https` und `mailto` öffnen sich extern
  (`KnowledgeMarkdownLinkHandler`), andere Schemata werden ignoriert.
- **Fußnoten** (`Text[^1]` und `[^1]: Fußnotentext`): Die Definitionen werden
  aus dem Fließtext gelöst (`KnowledgeFootnotes`) und unter der Notiz als
  eigener Abschnitt gerendert, nummeriert in Definitionsreihenfolge. Die
  hochgestellte Nummer springt zur Fußnote, „Zurück zur Textstelle“ zurück an
  die vorherige Leseposition. Definitionen in Codeblöcken und Verweise ohne
  Definition bleiben Text.
- **Formeln** (LaTeX über `flutter_math_fork`): `$…$` im Fließtext,
  `$$…$$` sowie `$$`-Blöcke über mehrere Zeilen und `\[…\]` als abgesetzte
  Formel. Wie in Obsidian/Pandoc darf direkt innerhalb der `$` kein Leerzeichen
  stehen und auf das schließende `$` keine Ziffer folgen — Beträge wie
  „5 $ bis 10 $“ bleiben Text. Fehlerhafte Formeln erscheinen als roter
  Quelltext.
- **Markierung** (`==Text==`) hinterlegt den Text mit dem Akzent des Themes.
  Formatierung innerhalb der Markierung wird nicht zusätzlich gerendert.
- Gestaltung kommt vollständig aus dem Theme (`KnowledgeMarkdownStyleSheet`).
- Leere Notizen zeigen einen Hinweis auf „Schreiben“.

Auf kleinen Displays bzw. bei großer Schrift wechseln Notizliste und Dokument
in eine Einspaltenansicht mit „Alle Notizen“-Navigation. Kompakte Auswahlfelder
ersetzen bei Platzmangel die Segmentauswahl. Löschen erfordert eine Bestätigung.

Die Graph-Ansicht folgt dem Hell-/Dunkelmodus: ruhige Canvas,
organisch verteilte verschiebbare Punkt-Knoten, feine gedämpfte
Verbindungslinien, dezente Labels, Pan/Zoom und eine kleine Overlay-Leiste zum
Zurücksetzen der Ansicht. Verbundene Knoten werden beim Ziehen federnd
sanft mitbewegt und kehren gedämpft zu ihrer Ruheposition zurück. Der gezogene
Knoten bleibt am Ablagepunkt; unverbundene Notizen werden nicht abgestoßen.
Die Interaktionsphysik verwendet feste Zeitschritte und die bestehende Anordnung
als Ruheposition statt einer erneuten globalen Kräfteverteilung. Bei reduzierter
Bewegung bleibt die direkte Positionierung ohne federnde Animation erhalten. Kanten entstehen aus
`outgoingLinks`. Ein Klick auf einen Knoten selektiert die zugehörige Notiz im
Editor.

Änderungen werden per Debounce automatisch gespeichert. Nutzer:innen müssen
keinen Speichern-Button bedienen.

## KI-Agent

Der KI-Agent im rechten Drawer kann die Notizen des aktuellen Teams lesen:
Er sucht zunächst in Titel, Pfad und Markdown und lädt danach gezielt einzelne
Notizen. Die Genkit-Tools sind laufzeitneutral; die Cloud verdrahtet sie mit
Firestore und Firebase Auth, die lokale Runtime mit SQLite und lokaler
Identität. Beide Varianten beachten dieselbe Teamgrenze.

Der fachliche Vertrag `KnowledgeBaseAssistant` ist ebenfalls laufzeitneutral.
Die Genkit-Implementierung erstellt Modell und Tools, während der Firebase-
Callable ausschließlich Authentifizierung, Eingabeprüfung, Fehlerprotokollierung
und die Firestore-Abhängigkeiten verdrahtet.

Erstellen, Bearbeiten und Löschen sind keine automatischen Tool-Aufrufe. Der
Agent erzeugt dafür einen sichtbaren, bestätigungspflichtigen Plan. Nach dessen
Ausführung kann die gesamte Änderung über **Rückgängig** zurückgenommen werden.

## Node-Anhänge

Unterstützte NodeConfigs speichern `knowledgeAttachments` zusätzlich zu
`attachments`. Ein Anhang enthält nur Referenz-Metadaten:

```json
{
  "knowledgeBaseId": "default",
  "noteId": "note.1",
  "title": "Index",
  "path": "index.md"
}
```

Beim TaskRun lädt das Backend jede angehängte Notiz sowie ihre direkten und
indirekten ausgehenden Links unter `knowledge/` in den Genkit-Workspace. Die
Suche läuft Ebene für Ebene (Breitensuche): erst alle direkten Anhänge, dann
deren Links, dann die Links der Links. Sie endet nach 5 Ebenen bzw. 50 Notizen;
beim Limit fallen also die am weitesten entfernten Notizen weg. Der Prompt
nennt ausschließlich die direkt angehängte Notiz. Verlinkte Notizen werden nicht
als Prompt-Anhang aufgezählt; die KI entdeckt sie über die Links im Markdown und
bei Bedarf über `knowledge/manifest.json`.

## Aktueller Scope

- Notizen können erstellt, bearbeitet und gelöscht werden.
- `outgoingLinks` werden clientseitig aus `[[Wiki Links]]`,
  `[[Ziel|Anzeigetext]]` und Markdown-Links auf bekannte Notizen abgeleitet.
- `[[Ziel#Abschnitt]]` löst wie in Obsidian die Notiz `Ziel` auf; der
  Abschnitt ist für die aktuelle Einzelnotiz-Ansicht noch ohne Wirkung.
- Notizen können über Titel, ID, Pfad oder den Pfad ohne `.md` verlinkt werden.
- Wiki Links sind in der Ansicht klickbar und öffnen die verknüpfte Notiz.
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
