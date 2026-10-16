# Sicherheitsregeln der Dateiablage

> In der Cloud dürfen nur Team-Mitglieder Dateien und Ordner lesen und anlegen; Uploads sind auf 50 MB begrenzt und Versionen nie überschreibbar.

Gehört zu: [Dateien](../index/dateien.md)

- Firestore-Zugriff über `teams/{teamId}/members/{uid}`.
- Persönliche Teams darf nur die zugehörige Nutzer:in anlegen.
- Ordner: Team-Mitglieder dürfen anlegen und lesen.
- Storage: Uploads nur für Team-Mitglieder, höchstens 50 MB; für Versionen nur
  `create`, kein Überschreiben oder Löschen (Rotation löscht über das
  Admin-SDK).

Offen: Rollenrechte für Upload, Lesen und Löschen; wie der aktive
Team-Kontext global gewählt und gespeichert wird.

## Siehe auch

- [Dateiablage in der Cloud](./dateiablage-cloud-pfade.md)
- [Versionsrotation](./datei-versionsrotation.md)
