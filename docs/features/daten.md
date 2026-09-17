# Feature: Daten

## Zweck

Das Feature stellt Arbeitsplänen lokale, dokumentorientierte Daten bereit.
Nutzer:innen arbeiten mit **Datensammlungen**, **Datensätzen** und sichtbaren
**Feldern**. Begriffe und Mechanismen wie Tabellen, SQL, JSON-Pfade oder
Datenbanktreiber bleiben vollständig in der Runtime verborgen.

## Verantwortlichkeiten

- Datensammlungen team-scoped anlegen.
- Genau einen oder mehrere Datensätze über sichere, strukturierte Filter
  finden.
- Datensätze erstellen, ersetzen und als „anlegen oder aktualisieren"
  speichern.
- Versionsstände für konkurrierende Aktualisierungen prüfen.
- Lokale Speicherung von einem späteren Cloud-Adapter entkoppeln.

## Fachmodell

```text
Datensammlung „Kund:innen"
└── Datensatz
    ├── ID
    ├── Felder: { name, email, status, ... }
    ├── Version
    ├── Erstellt am
    └── Aktualisiert am
```

Der Domain-Port `DocumentStore` definiert `findOne`, `findMany`, `create`,
`update` und `upsert`. Die Domain kennt weder SQLite noch Node- oder
Firebase-Abhängigkeiten. Für eine Suche wird ausschließlich eine sichere
Struktur übergeben: Feldname, Operator und Wert.

| Operator | Fachliche Bedeutung |
| --- | --- |
| `equals`, `notEquals` | ist gleich / ist nicht gleich |
| `contains` | Text enthält |
| `greaterThan`, `greaterThanOrEqual` | Zahl ist größer als / mindestens |
| `lessThan`, `lessThanOrEqual` | Zahl ist kleiner als / höchstens |

Filter referenzieren aktuell genau ein sichtbares Feld. Feldnamen sind keine
Pfade und werden vor der Ausführung validiert. Dadurch kann kein Arbeitsplan
SQL oder eine technische Datenbankabfrage einschleusen.

## Lokale Speicherung

Die lokale Runtime implementiert den Port mit `SQLiteDocumentStore`. SQLite ist
eine unsichtbare Implementierungsentscheidung. Die Migration
`012_document_store.sql` legt `document_collections` und `documents` an; `013_document_collection_display_name.sql` sichert eindeutige, exakte Sammlungsnamen je Team.
Die Runtime erzeugt eine interne Sammlungs-ID. Arbeitspläne verwenden ausschließlich den sichtbaren Namen; Groß- und Kleinschreibung bleiben Teil dieses Namens, daher sind Kunden und kunden getrennte Sammlungen. Dokumentfelder liegen als valides JSON in `data_json`; Team, Sammlung, ID,
Version und Zeitstempel sind getrennte Spalten. Der Zugriff enthält immer die
Team- und Sammlungsgrenze.

Dateianhänge bleiben im Feature **Dateien**. Ein Datensatz enthält lediglich
eine Referenz wie `dateiId`, niemals den Binärinhalt einer Datei.

## Arbeitsplan-Anbindung

Die Runtime-Komposition injiziert den `DocumentStore` in den lokalen
Task-Worker. Der sichtbare Baustein **Datensatz suchen** findet genau einen
Datensatz und erhält nur Sammlung, Feld, Vergleich und Wert. Er liefert immer
einen lesbaren primären Wert: **Datensatz gefunden**, **Kein passender
Datensatz gefunden** oder **Suche fehlgeschlagen**. Damit entscheidet der
normale Wenn-dann-Baustein ohne Speziallogik und ohne separaten Baustein
„Dokument existiert".

**Datensatz speichern** erhält eine Sammlung, sichtbare Feldbedingungen und eine Liste sichtbarer Feldzuordnungen. Ohne Bedingungen legt es immer einen neuen Datensatz an. Mit mindestens einer Bedingung aktualisiert es alle Datensätze, die die Bedingungen erfüllen; werden keine Datensätze gefunden, legt die Runtime einen neuen an. Nicht konfigurierte Felder bestehender Datensätze bleiben unverändert; der Store prüft dabei den Versionsstand.

**Datensätze suchen** liefert weiterhin einen einzelnen fachlich passenden Datensatz. Der Speichern-Baustein verwendet dagegen `findMany`, damit er alle passenden Datensätze aktualisieren kann.

## Qualitätssicherung

Der gleiche Fachvertrag läuft gegen einen In-Memory-Adapter und gegen SQLite.
Er deckt Treffer, keinen Treffer, Filter, Upsert, Teamtrennung, unveränderliche
Rückgaben und konkurrierende Updates mit derselben erwarteten Version ab.

## Aktueller Scope

- Enthalten: lokale Datensammlungen, strukturierte Filter, Speichern und
  optimistische Versionierung.
- Nicht enthalten: Löschen, freie SQL-Abfragen, Aggregationen und
  Cloud-Synchronisierung. Die Cloud-Runtime meldet für Datenbausteine bis zu
  einem späteren Firestore-Adapter eindeutig, dass die Datenablage dort noch
  nicht verfügbar ist.

## Offene Fragen

- Welche Felder sollen bei wachsendem Datenvolumen als SQLite-Ausdrucksindizes
  optimiert werden?
- Wie werden Schema-Hinweise für Einsteiger:innen gepflegt, ohne flexible
  Dokumente einzuschränken?
- Welche explizite Freigabe oder Archivierung ist vor einer späteren
  Löschfunktion erforderlich?

## Verwandt

[`../architecture.md`](../architecture.md) ·
[`../local-runtime.md`](../local-runtime.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`dateien.md`](./dateien.md)
