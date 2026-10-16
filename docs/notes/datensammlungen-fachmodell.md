# Datensammlungen: Fachmodell

> Arbeitspläne arbeiten mit Datensammlungen, Datensätzen und sichtbaren Feldern; Tabellen, SQL und JSON-Pfade bleiben vollständig in der Runtime verborgen.

Gehört zu: [Daten](../index/daten.md)

```text
Datensammlung „Kund:innen“
└── Datensatz
    ├── ID
    ├── Felder: { name, email, status, ... }
    ├── Version
    ├── Erstellt am
    └── Aktualisiert am
```

- Port `DocumentStore`: `findOne`, `findMany`, `create`, `update`, `upsert`;
  dazu Sammlungen und Datensätze listen und zählen und einen Datensatz über
  seine interne Identität löschen. Die Domain kennt weder SQLite noch Node
  noch Firebase.
- Suchen bekommen nur eine sichere Struktur: Feldname, Operator, Wert.

| Operator | Bedeutung |
| --- | --- |
| `equals`, `notEquals` | ist gleich / ist nicht gleich |
| `contains` | Text enthält |
| `greaterThan`, `greaterThanOrEqual` | größer als / mindestens |
| `lessThan`, `lessThanOrEqual` | kleiner als / höchstens |

- Ein Filter referenziert genau ein sichtbares Feld; Feldnamen sind keine
  Pfade und werden validiert. Warum: Kein Arbeitsplan kann SQL einschleusen.
- Optimistische Versionierung: Aktualisierungen prüfen den Versionsstand.
- Dateien bleiben im Feature Dateien; ein Datensatz hält nur eine Referenz wie
  `dateiId`, nie Bytes.
- Ein gemeinsamer Vertragstest läuft gegen In-Memory und SQLite: Treffer, kein
  Treffer, Filter, Upsert, Teamtrennung, unveränderliche Rückgaben,
  konkurrierende Updates mit gleicher Version.

## Siehe auch

- [Datensammlungen in SQLite](./datensammlungen-sqlite.md)
- [Datensatz-Bausteine](./datensatz-bausteine.md)
