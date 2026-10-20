# Benutzerkonten in SQLite (0025)

> Migration 0025 ersetzt das eine Betreiber-Passwort durch Konten: Anmeldename am Profil, Passwörter und Einladungen in eigenen Tabellen, Sitzungen mit Konto.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- `user_profiles.login_name` (eindeutiger Index; leer beim Profil des
  Arbeitsbereichs bis zur Einrichtung). SQLite kann keine NOT-NULL-Spalte ohne
  Default ergänzen; die Pflicht prüft der Use Case.
- `runtime_password_credentials(uid, password_hash, salt, updated_at)` (seit
  [0026](./sqlite-passwort-hashes-0026.md) verschlüsselt als `encrypted_hash`) und
  `runtime_invitations(code_hash, uid, expires_at, created_at)`, beide mit
  `ON DELETE CASCADE` am Profil.
- `runtime_sessions` wird neu angelegt, jetzt mit `uid` (Fremdschlüssel,
  Kaskade); alle alten Sitzungen entfallen.
- `runtime_access_credential` (das frühere Betreiber-Passwort) wird gelöscht;
  ohne Kompatibilitätscode richten bestehende Runtimes ihr erstes Konto neu ein.
- `team_members.role`: `owner` wird `admin`; neue Arbeitsbereiche legen ihr
  Profil als `admin` an.
- `task_runs.started_by_uid` und `reviewed_by_uid` für die
  [Herkunft eines Laufs](./lauf-herkunft.md).
- drizzle-kit fragt beim Erzeugen interaktiv nach einer Umbenennung; die
  Migration entstand deshalb in zwei Schritten und wurde von Hand zu einer
  zusammengeführt. Test: `multi-user-migration.test.ts` (Stand 0024 → 0025).

## Siehe auch

- [Benutzerkonten der Runtime](./runtime-benutzerkonten.md)
- [SQLite-Migrationen](./sqlite-migrationen.md)
