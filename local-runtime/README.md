# Lokale Runtime

Dieser Ordner enthält die lokale Persistenz-Struktur für eine spätere
vollständig lokal ausführbare novooa-Version.

## Migrationen

Migrationen liegen unter `migrations/` und werden in aufsteigender Reihenfolge
ausgeführt. Die erste Migration bildet die bestehenden Cloud-Konzepte lokal ab:

- Teams und Mitglieder
- Aufgaben und TaskRuns
- Aktivitäten
- Zeit- und Event-Trigger
- Kommunikationskanäle
- Wissensbasis
- Dateien und Dateiversionen

Die Cloud Functions nutzen diese Dateien noch nicht direkt. Sie dienen als
Vertrag für die späteren SQLite-Adapter:

- `SQLiteTaskStore`
- `SQLiteTaskRunStore`
- `SQLiteActivityStore`
- `SQLiteTaskTriggerStore`
- `LocalTeamFileStore`
- `SQLiteKnowledgeBaseStore`

Der konkrete SQLite-Treiber ist bewusst noch nicht festgelegt. Die Adapter
nutzen vorerst `LocalSqlDatabase`, damit wir den Treiber später austauschen
können, ohne die Runtime-Ports erneut anzufassen.

Migrationen werden über `SqlMigrationRunner` angewendet. Der Runner erwartet
bereits aufbereitete Statements; ein lokaler CLI kann die Dateien aus
`migrations/` lesen und mit `migrationFromSqlFile` in Migrationen umwandeln.
