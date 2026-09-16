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
`012_document_store.sql` legt `document_collections` und `documents` an.
Dokumentfelder liegen als valides JSON in `data_json`; Team, Sammlung, ID,
Version und Zeitstempel sind getrennte Spalten. Der Zugriff enthält immer die
Team- und Sammlungsgrenze.

Dateianhänge bleiben im Feature **Dateien**. Ein Datensatz enthält lediglich
eine Referenz wie `dateiId`, niemals den Binärinhalt einer Datei.

## Arbeitsplan-Anbindung

Die Runtime-Komposition stellt den `DocumentStore` bereits als injizierten Port
bereit. Die sichtbaren Bausteine **Datensatz suchen**, **Datensätze suchen**
und **Datensatz speichern** folgen als eigener Workflow-Vertrag. Der
Suchbaustein wird dann fachlich „gefunden", „nicht gefunden" oder „Suche
fehlgeschlagen" liefern; der bestehende Wenn-dann-Baustein entscheidet anhand
dieses Ergebnisses oder einzelner Felder. Es gibt bewusst keinen separaten
Baustein „Dokument existiert".

## Qualitätssicherung

Der gleiche Fachvertrag läuft gegen einen In-Memory-Adapter und gegen SQLite.
Er deckt Treffer, keinen Treffer, Filter, Upsert, Teamtrennung, unveränderliche
Rückgaben und konkurrierende Updates mit derselben erwarteten Version ab.

## Aktueller Scope

- Enthalten: lokale Datensammlungen, strukturierte Filter, Speichern und
  optimistische Versionierung.
- Nicht enthalten: Löschen, freie SQL-Abfragen, Aggregationen,
  Cloud-Synchronisierung und sichtbare Workflow-Bausteine.

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
