# Ablauf und Garantien von Import/Export

> Import geschieht in zwei Schritten — prüfen, dann übernehmen —, und alle Zeilen werden in einer einzigen SQLite-Transaktion geschrieben.

Gehört zu: [Import/Export](../index/import-export.md)

- **Export:** `POST /v1/transfer/export {categories}` streamt
  `application/zip`. Versionen ohne Bytes auf der Platte werden ausgelassen.
- **Prüfen:** `POST /v1/transfer/imports` (`application/zip`, höchstens
  4 GiB) → `{importId, manifest}`; der Upload liegt 30 Minuten unter
  `<runtimeRoot>/transfer-imports/`. Die App zeigt die Anzahl je Bereich.
- **Übernehmen:** `POST /v1/transfer/imports/{id}/apply {categories}` →
  `{imported}`. Erst alle Bereiche lesen und prüfen und Bytes kopieren, dann
  alle Zeilen in **einer** Transaktion. Scheitert ein Bereich, bleibt der
  Bestand unverändert und neu kopierte Dateien werden entfernt.
- **Verwerfen:** `DELETE /v1/transfer/imports/{id}`.
- Dateien: erst ohne Versionsreferenz, dann Versionen, dann aktuelle
  Referenzen — in derselben Transaktion; Versions-IDs dürfen keiner anderen
  Datei gehören.

**Sonderregeln:**

- **Fähigkeiten:** Der Skills-Ordner ist nicht team-gebunden. Ein
  gleichnamiger Skill wird **vollständig ersetzt**, andere bleiben. Scheitert
  ein späterer Bereich, wird der alte Stand wiederhergestellt und Neues
  entfernt. `..`, absolute Pfade, fehlende `SKILL.md`, doppelte Namen oder
  überschrittene Grenzen (200 Dateien, 10 MB) machen den Export ungültig.
- **Mitarbeiter:** gleiche IDs überschreiben; gleicher Name unter anderer ID
  → „ (2)“, „ (3)“ …; eine ID, die im Ziel einem anderen Team gehört, wird nie
  überschrieben. Ungültige Namen oder Skill-Namen machen den Export ungültig.
- **Datensammlungen:** gleichnamige Sammlung im Ziel nimmt die Datensätze auf.

## Siehe auch

- [Architektur von Import/Export](./transfer-architektur.md)
- [Bereiche von Import/Export](./transfer-bereiche.md)
