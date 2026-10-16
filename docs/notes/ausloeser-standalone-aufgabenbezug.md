# Auslöser in der Standalone-Datenbank

> In SQLite gehört ein Auslöser über den Fremdschlüssel `task_id` zu seiner Aufgabe und damit zum Team.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Seit Migration `0013` gibt es keinen Auslöser ohne bestehende Aufgabe.
Teamgrenzen gelten für Listen, Aktivieren, Webhook-Token und Worker-Updates.
Zeitplan-, Ereignis- und Policy-Konfiguration bleiben flexible JSON-Daten.

Wird eine Aufgabe gelöscht, entfernt das Aufgabenrepository ihre Auslöser und
Webhook-Geheimnisse atomar. Historische Läufe bleiben erhalten. Der
Firestore-Adapter behält sein eigenes Speichermodell.

## Siehe auch

- [Auslöser-Datenmodell](./ausloeser-datenmodell.md)
- [SQLite-Normalisierung](../architecture/sqlite-normalisierung.md)
