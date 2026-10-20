# Verschlüsselte Passwort-Hashes (0026)

> Migration 0026 legt `runtime_password_credentials` neu an: Der scrypt-Hash liegt nur noch als Envelope unter dem Master-Key in `encrypted_hash`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Warum: Datenbank und Schlüsselbund liegen in getrennten Volumes. Gerät nur
  die Datenbank nach außen (etwa eine Sicherung des Daten-Volumes), lassen sich
  die Passwörter ohne Master-Key nicht offline durchprobieren.
- Spalten: `uid`, `encrypted_hash`, `salt`, `updated_at`. Das Salt bleibt im
  Klartext; es ist kein Geheimnis.
- Feldkontext `["runtime-password", uid, "scrypt-hash"]`: Ein in die Zeile
  eines anderen Kontos kopierter Hash zählt beim Anmelden als falsches
  Passwort.
- Kein Pepper zusätzlich: Er läge im selben Schlüsselbund und ließe sich nicht
  rotieren; die Envelope wird bei der
  [Master-Key-Rotation](./master-key-automatische-rotation.md) neu verpackt.
- Die Migration löscht alle Passwörter und Sitzungen, ohne
  Kompatibilitätscode: Jede Runtime legt ihr Admin-Konto neu an
  ([Ersteinrichtung](./runtime-ersteinrichtung.md)), Mitglieder erhalten neue
  [Einladungscodes](./runtime-einladungscodes.md). Konten, Rollen und alle
  übrigen Daten bleiben.
- Sitzungstokens und Einladungscodes bleiben SHA-256-Hashes; sie sind
  zufällig, eine Verschlüsselung brächte nichts.

## Siehe auch

- [Feldverschlüsselung mit Envelopes](./feldverschluesselung-envelope.md)
- [Benutzerkonten in SQLite (0025)](./sqlite-benutzerkonten-0025.md)
- [Benutzerkonten der Runtime](./runtime-benutzerkonten.md)
