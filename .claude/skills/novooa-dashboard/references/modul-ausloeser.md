# Modul „Auslöser“ (optional)

Zeigt die Auslöser der angebotenen Aufgaben (Zeitpläne, Ereignisse, Webhooks)
und schaltet sie an oder aus. **Anlegen, Ändern und Löschen bleiben im
offiziellen Frontend**: Konfiguration, Schleifenschutz und Webhook-Geheimnisse
sind dort vollständig abgebildet.

Nur einbauen, wenn der Kunde es ausdrücklich will. Mitglieder dürfen
Auslöser schalten; keine Admin-Rechte nötig.

## API

`GET /v1/task-triggers` → `{items: TaskTrigger[]}`, Thema `task-triggers`.

```json
{"id": "…", "teamId": "…", "taskId": "…", "taskTitle": "…",
 "type": "schedule|event", "enabled": true,
 "config": {…}, "eventConfig": {…}, "policy": {…},
 "nextRunAt": "ISO|null", "lastRunAt": "ISO|null", "lastRunId": "…|null"}
```

`PUT /v1/task-triggers/:id/enabled {enabled}` → der geänderte Auslöser.
Beim Einschalten kann die Runtime mit `400 {error}` ablehnen, wenn der
Auslöser eine Schleife zwischen Aufgaben bilden würde; `error` ist ein
verständlicher Text und wird so angezeigt. `404`, wenn es ihn nicht mehr gibt.

`config` und `eventConfig` sind interne Formate des offiziellen Frontends;
das Modul wertet sie nicht aus und zeigt stattdessen Art und nächsten Lauf.

## Code

Ordner `lib/features/triggers/` nach [Architektur](architektur.md).

```dart
// domain/entities/task_trigger.dart
extension type const TriggerId(String value) {}

enum TriggerKind { schedule, event }

class TaskTrigger extends Equatable {
  const TaskTrigger({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.kind,
    required this.enabled,
    this.nextRunAt,
  });

  final TriggerId id;
  final TaskId taskId;
  final String taskTitle;
  final TriggerKind kind;
  final bool enabled;
  final DateTime? nextRunAt;

  TaskTrigger copyWith({bool? enabled}) => TaskTrigger(
    id: id, taskId: taskId, taskTitle: taskTitle, kind: kind,
    enabled: enabled ?? this.enabled, nextRunAt: nextRunAt,
  );

  @override
  List<Object?> get props => [id, enabled, nextRunAt];
}

/// Ablehnung beim Einschalten trägt den Grund der Runtime.
class TriggerSwitchFailure {
  const TriggerSwitchFailure(this.reason);
  final String? reason;
}
```

```dart
// domain/repositories/trigger_repository.dart
abstract interface class TriggerRepository {
  Stream<List<TaskTrigger>> watchTriggers();
  Future<Result<TaskTrigger, TriggerSwitchFailure>> setEnabled(
    TriggerId id, {required bool enabled});
}
```

```dart
// infrastructure/runtime_trigger_repository.dart
class RuntimeTriggerRepository implements TriggerRepository {
  const RuntimeTriggerRepository(this._api, this._realtime);

  final WorkspaceApiClient _api;
  final WorkspaceRealtimeChannel _realtime;

  @override
  Stream<List<TaskTrigger>> watchTriggers() =>
      watchWorkspaceChannel('task-triggers', _load, _realtime);

  Future<List<TaskTrigger>> _load() async {
    final items = (await _api.get('/v1/task-triggers'))['items'];
    if (items is! List) return const [];
    return items.whereType<Map<String, Object?>>().map(_triggerFrom).toList();
  }

  TaskTrigger _triggerFrom(Map<String, Object?> json) => TaskTrigger(
    id: TriggerId(json['id'] as String? ?? ''),
    taskId: TaskId(json['taskId'] as String? ?? ''),
    taskTitle: json['taskTitle'] as String? ?? '',
    kind: json['type'] == 'event' ? TriggerKind.event : TriggerKind.schedule,
    enabled: json['enabled'] == true,
    nextRunAt: DateTime.tryParse(json['nextRunAt'] as String? ?? ''),
  );

  @override
  Future<Result<TaskTrigger, TriggerSwitchFailure>> setEnabled(
    TriggerId id, {required bool enabled}) async {
    try {
      final json = await _api.put(
        '/v1/task-triggers/${id.value}/enabled', {'enabled': enabled});
      return Success(_triggerFrom(json));
    } on WorkspaceHttpException catch (error) {
      return Error(TriggerSwitchFailure(error.statusCode == 400 ? error.message : null));
    } on Object {
      return const Error(TriggerSwitchFailure(null));
    }
  }
}
```

Presentation: `TriggersCubit` (Laden, Fehler, Geladen; nach
`DashboardConfig.showsTask(taskId)` gefiltert) und ein `TriggerSwitchCubit`
für das Schalten (Senden, Fehler mit Grund). Die Liste zeigt je Auslöser eine
Karte mit Aufgabentitel, Art („Zeitplan“ / „Ereignis“), nächstem Lauf und
einem `Switch` mit `semanticLabel`. Während des Sendens ist der Schalter
gesperrt; eine Ablehnung erscheint als Snackbar mit dem Grund der Runtime.

## Einbinden

1. `DashboardConfig.showsTriggers = true` ergänzen.
2. `RuntimeTriggerRepository` in `DashboardDependencies._register`
   registrieren.
3. Cubits im `DashboardShell` bereitstellen, Ziel „Auslöser“ in
   `DashboardNavigation` nur bei `showsTriggers`.
4. Texte (`triggers.title`, `triggers.empty`, `triggers.schedule`,
   `triggers.event`, `triggers.next_run`, `triggers.switch_failed`) in
   `en`, `de`, `tr`.
5. Cubit-Tests: Laden, Schalten erfolgreich, Ablehnung mit Grund.
