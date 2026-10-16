# Dateiversionen in SQLite (0009)

> `files` hält Identität, Ablage und `current_version_id`; alle Versionsmetadaten liegen nur in `file_versions`.

Gehört zu: [Dateien](../index/dateien.md) · [Lokale Runtime](../index/lokale-runtime.md)

- `files`: Identität, Besitzer, Name, Ablage, Zeitstempel,
  `current_version_id`. Kein `content_type`, `size_bytes`, `storage_path`.
- `file_versions`: Name, Ersteller, Speicherpfad, Dateityp, Größe,
  Erstellungszeit; Bezug über `file_id`, keine eigene `team_id`.
- Zusammengesetzter Fremdschlüssel `files(id, current_version_id)` →
  `file_versions(file_id, id)` verhindert die Version einer anderen Datei.
- Löschen einer Datei entfernt ihre Versionen per Kaskade; negative Größen
  lehnt ein CHECK ab.
- Neue Datei: in einer Transaktion erst ohne Version anlegen, dann Version und
  Referenz schreiben. Listen und Rückgaben entstehen per Join; Team-scoped
  Versionsabfragen lösen das Team über `files` auf.
- HTTP-DTOs und Domain-Verträge sind von der SQL-Struktur unabhängig.
- Migration `0009_normalize_file_versions.sql`: Ein temporärer
  Sicherungsbestand verhindert, dass die Löschkaskade beim Tabellenumbau
  Versionen entfernt.

## Siehe auch

- [Datei- und Ordnerablage (0017/0018)](./sqlite-dateiablage-normalisiert.md)
- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
