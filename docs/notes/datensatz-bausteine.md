# Datensatz-Bausteine

> „Datensatz suchen“ findet genau einen Datensatz und meldet das Ergebnis als lesbares Label; „Datensatz speichern“ legt an oder aktualisiert alle Treffer.

Gehört zu: [Aufgabe](../index/aufgabe.md)

Beide hängen nur am fachlichen `DocumentStore`-Port; Standalone injiziert den
SQLite-Adapter in den Graph-Runner.

**`documentLookup`**

- Sucht über eine Sammlung und sichere, sichtbare Feldbedingungen.
- `value` ist immer ein Label für den Bedingten Ablauf: `Datensatz gefunden`,
  `Kein passender Datensatz gefunden` oder `Suche fehlgeschlagen`. Ein eigener
  „Existiert?“-Baustein ist deshalb unnötig.
- Weitere Werte: `found`, `record` (Fachfelder oder `null`), `message`.
- Ein Suchfehler ist fachlicher Output, kein Run-Fehler.

**`saveDocument`**

- Ohne Bedingungen: **Anlegen**, immer ein neuer Datensatz.
- Mit Bedingungen: **Aktualisieren oder anlegen** — alle Treffer mit den
  sichtbaren Feldzuordnungen aktualisieren, nicht konfigurierte Felder
  bleiben; ohne Treffer neu anlegen.
- IDs und Versionen nutzt er nur intern; die gelesene Version geht an den
  Store, sodass eine parallele Änderung abgewiesen statt überschrieben wird.
- Die Sammlung wird vorher atomar sichergestellt (implizit angelegt).
- Ein Speicherfehler bleibt Run-Fehler, damit nichts halb Gespeichertes als
  Erfolg gilt.

## Siehe auch

- [Sammlung als Tabelle](./sammlung-als-tabelle.md)
- [Daten](../index/daten.md)
