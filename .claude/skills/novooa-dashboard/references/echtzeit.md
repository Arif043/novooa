# Echtzeit

Die Runtime schickt keine Daten über den Echtzeit-Kanal, nur das Signal
„Thema X hat sich geändert“. Wer es empfängt, lädt die Liste erneut über
HTTP.

## Protokoll (macht das Paket)

1. `POST /v1/realtime/ticket` mit Session-Token → `{ticket}`; gilt 10
   Sekunden und einmal (Browser können beim WebSocket keine Header setzen).
2. WebSocket `/v1/realtime?ticket=<ticket>` (`ws`/`wss` passend zur Adresse).
3. Abonnieren: `{"type": "subscribe", "topic": "task-runs"}`.
4. Signal: `{"type": "changed", "topic": "task-runs"}`.
5. Abmelden oder Sitzungsende schließt die Verbindung mit Code `4401`; die
   Runtime prüft offene Verbindungen zusätzlich jede Minute.

`WorkspaceRealtimeChannel` hält genau eine Verbindung, verbindet sich mit
Backoff neu und multiplext alle Themen.

## Im Dashboard

```dart
final realtime = WorkspaceRealtimeChannel(endpoint.apiUri, api);

Stream<List<TaskRun>> watchRuns() =>
    watchWorkspaceChannel('task-runs', _loadRuns, realtime);
```

`watchWorkspaceChannel(topic, load, channel)` lädt einmal sofort, danach bei
jedem Signal; überlappende Signale führen zu genau einem Nachladen. Fehler von
`load` kommen als Fehler im Stream an; der Cubit zeigt dann den Fehlerzustand
mit „Erneut versuchen“.

Beim Abmelden oder Sitzungsende `realtime.close()` aufrufen (die Vorlage tut
das in `DashboardDependencies.dispose`), sonst fordert der Kanal mit dem alten
Token weiter Tickets an.

## Themen

| Thema | Auslöser | Nachladen |
| --- | --- | --- |
| `tasks` | Aufgabe gespeichert oder gelöscht | `GET /v1/tasks` |
| `task-runs` | Lauf gestartet, fortgesetzt, beendet, Freigabe | `GET /v1/task-runs` |
| `task-activities` | neuer Schritt eines Laufs | `GET /v1/activities` |
| `task-triggers` | Auslöser geändert | `GET /v1/task-triggers` |
| `files`, `folders` | Dateiablage geändert | `GET /v1/files`, `GET /v1/folders` |
| `users` | Konten geändert | (Dashboard: meist nicht nötig) |

Ein Lauf ändert seinen Status nie ohne Aktivität; wer beides zeigt, abonniert
`task-runs` und `task-activities`.
