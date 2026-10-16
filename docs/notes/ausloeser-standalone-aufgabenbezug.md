# Auslöser in der Standalone-Datenbank

> In SQLite gehört ein Auslöser über den Fremdschlüssel `task_id` zu seiner Aufgabe und damit zum Team.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Seit Migration `0013` gibt es keinen Auslöser ohne bestehende Aufgabe.
Teamgrenzen gelten für Listen, Aktivieren, Webhook-Token und Worker-Updates.
Zeitplan-, Ereignis- und Policy-Konfiguration bleiben flexible JSON-Daten.

Der Index auf `task_id` und `enabled` unterstützt Aufgabenbezüge, der
Fälligkeitsindex bleibt. Beim Anlegen wird die Teamzugehörigkeit der Aufgabe
in der Schreibtransaktion erneut geprüft.

Wird eine Aufgabe gelöscht, entfernt das Aufgabenrepository ihre
Webhook-Geheimnisse und die Aufgabe in einer Transaktion; die Auslöser fallen
per Kaskade weg. Die API meldet danach beide Ressourcen (`tasks` und
`task-triggers`). Auch ein einzelner Auslöser wird samt Geheimnis atomar
gelöscht. Historische Läufe mit Titelsnapshots bleiben erhalten.

Die Migration bricht bei verwaisten Aufgabenbezügen oder widersprüchlichen
Teamzuordnungen vollständig ab. Der Firestore-Adapter behält sein eigenes
Speichermodell.

## Siehe auch

- [Auslöser-Datenmodell](./ausloeser-datenmodell.md)
- [SQLite-Prüfstand (3NF)](./sqlite-3nf-pruefstand.md)
