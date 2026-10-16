# SQLite und Firebase: fünf Regeln

> Standalone nutzt SQLite, die Cloud Firestore; beide teilen Fachmodelle und Verträge, dürfen aber eigene Speichermodelle haben. MongoDB ist nicht vorgesehen.

Gehört zu: [Architektur](../index/architektur.md)

1. **Ein gemeinsames fachliches Modell.** Dateien, Versionen, Mitarbeiter und
   Aufgaben bedeuten überall dasselbe. Entitäten, Use Cases und Ports sind
   datenbank- und frameworkfrei; SQL-Zeilen und Firestore-Snapshots gehören in
   die Infrastructure.
2. **Eigene Speichermodelle je Backend.** SQLite normalisiert stabile
   Beziehungen, Firestore bettet ein oder verteilt auf Collections; Mapper
   übersetzen in dieselben Objekte. Flexible Konfigurationen, Snapshots und
   freie Dokumente dürfen in SQLite JSON bleiben; ein identisches Schema ist
   kein Ziel.
3. **Eine maßgebliche Quelle je Information** (z. B. Größe und Pfad an der
   Dateiversion). Kopien für Listen sind ausdrücklich abgeleitet, mit
   definierter Aktualisierung, Konsistenz und Wiederherstellung. Historische
   Snapshots sind eigene Fakten.
4. **Dieselben Konsistenzregeln.** Zusammengehörige Änderungen („Version
   anlegen und aktuelle Version umstellen“) sind atomar: SQL-Transaktion bzw.
   Firestore-Transaktion oder atomarer Batch. Teamgrenzen und Invarianten
   gelten überall, zusätzlich durch die jeweiligen Schutzmechanismen.
5. **Gemeinsame Vertragstests** für beide Adapter: Teamgrenzen,
   Versionierung, Löschverhalten, Sortierung, Fehler, Konkurrenz;
   backend-spezifische Tests ergänzen Constraints, Indizes, Transaktionen.

**Benennung:** SQLite-Adapter tragen `SQLite` im Klassen- und `sqlite-` im
Dateinamen (`SQLiteTeamFileStore` in `sqlite-team-file-store.ts`), ebenso
Abfragen, Mapper, Projektionen. `Local` meint die Runtime und ihre
HTTP-Clients und Dateisystemdienste, `Firestore` die Firestore-Adapter.

Die Regeln sind Zielvorgaben; nicht jeder Adapter erfüllt sie schon. Eine
automatische Synchronisierung zwischen Cloud und Standalone gibt es nicht; sie
bräuchte einen eigenen Vertrag mit Konfliktregeln.

## Siehe auch

- [SQLite-Prüfstand (3NF)](./sqlite-3nf-pruefstand.md)
- [Runtime-Schichten](./runtime-schichten.md)
