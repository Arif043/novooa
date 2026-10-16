# Automatische Master-Key-Rotation

> Die Runtime rotiert den Master-Key im laufenden Betrieb einen Kalendermonat nach der letzten Rotation, ohne Neustart und ohne alte Keys zu entfernen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

## Zeitpunkt

- `lastRotatedAt` im Schlüsselbund; Berechnung in UTC mit gleicher Uhrzeit.
  Fehlt der Tag im Folgemonat, gilt dessen letzter (31. Jan → 28. Feb).
- Beim Start sofortige Prüfung auf fällige oder unterbrochene Rotation. Nach
  langer Abschaltung wird einmal nachgeholt, ohne Zwischen-Keys.
- Ein Timer prüft spätestens nach 24 h erneut und plant die Fälligkeit im
  Fenster genau ein.

## Ablauf

1. Neuen aktiven Key zusammen mit allen alten und `rotationPending: true`
   sichern, **bevor** der Cipher ihn für neue Schreibvorgänge nutzt.
2. Datenschlüssel in SQLite in Batches und das Geheimnis der Lizenzdatei
   umschlüsseln; der Feld-Ciphertext bleibt. SQL-Updates sind atomar und
   prüfen den bisherigen Wert. Dateien: restriktive Rechte, fsync, atomarer
   Rename, unter Unix auch Verzeichnis-fsync.
3. Vor Abschluss alle Feldwerte authentifizieren und ihre Key-ID prüfen.

Während einer Unterbrechung liest die Runtime mit beiden Keys und schreibt
mit dem neuen. SQL-Schreibvorgänge wählen den Key in der Transaktion; die
Lizenzdatei wird seriell geschrieben, damit parallele Aktivierungen erhalten
bleiben.

## Fehler

`local_runtime.master_key_rotation_failed`, neuer Versuch nach fünf Minuten,
mit dem schon gesicherten Key. Erfolg: `local_runtime.master_key_rotated` mit
Anzahl umgeschlüsselter Datenschlüssel. Beim Herunterfahren wartet die Runtime
auf die laufende Prüfung.

Alte Keys bleiben, damit Backups nutzbar sind.

## Siehe auch

- [Manuelle Master-Key-Rotation](./master-key-manuelle-rotation.md)
- [Alte Master-Keys entfernen](./master-key-alte-entfernen.md)
