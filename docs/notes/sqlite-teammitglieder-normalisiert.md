# Benutzerprofile und Teammitglieder (0011)

> `user_profiles` hält genau ein Profil je `uid`; `team_members` speichert nur Zuordnung, Rolle und Zeitpunkte.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Schlüssel von `team_members`: `team_id` + `uid`; Fremdschlüssel auf `teams`
  und `user_profiles`. Index auf `uid` und `created_at` für die
  Arbeitsbereichsauswahl.
- Team löschen entfernt Mitgliedschaften, das Profil bleibt; Profil löschen
  entfernt dessen Mitgliedschaften.
- Migration: Profil aus der zuletzt aktualisierten Mitgliedschaft (bei
  Gleichstand kleinste Team-ID); Anlagezeit = früheste Mitgliedschaft; Rollen
  und Zeitpunkte bleiben.
- Die Initialisierung des Arbeitsbereichs legt Profil, Team und Mitgliedschaft
  atomar an und erhält vorhandene Profile und Rollen.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
