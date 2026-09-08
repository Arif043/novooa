import '../../../../core/network/local_runtime_api_client.dart';
import '../../domain/entities/create_task_trigger_input.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../../domain/repositories/task_trigger_repository.dart';

class LocalTaskTriggerRepository implements TaskTriggerRepository {
  const LocalTaskTriggerRepository(this._client);

  final LocalRuntimeApiClient _client;

  @override
  Future<void> createTrigger(CreateTaskTriggerInput input) async {
    if (!input.isValid) return;
    await _client.post('/v1/task-triggers', {
      'taskId': input.taskId,
      'type': input.type.name,
      'enabled': input.enabled,
      'config': input.schedule == null
          ? <String, Object?>{}
          : _schedule(input.schedule!),
      'eventConfig': input.event == null
          ? <String, Object?>{}
          : _event(input.event!),
      'policy': {'ifRunning': input.policy.name},
    });
  }

  @override
  Future<void> deleteTrigger(String triggerId) =>
      _client.delete('/v1/task-triggers/$triggerId');

  @override
  Future<void> setTriggerEnabled(String triggerId, bool enabled) =>
      _client.put('/v1/task-triggers/$triggerId/enabled', {'enabled': enabled});

  @override
  Stream<List<TaskTrigger>> watchTriggers() => pollLocalRuntime(_loadTriggers);

  Future<List<TaskTrigger>> _loadTriggers() async {
    final response = await _client.get('/v1/task-triggers');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Zeitplanliste ist ungültig.');
    }
    return items.whereType<Map>().map(_triggerFrom).toList(growable: false);
  }

  Map<String, Object?> _schedule(ScheduleConfig value) => {
    'kind': value.kind.name,
    'timezone': value.timezone,
    'runAt': value.runAt?.toUtc().toIso8601String(),
    'timeOfDay': value.timeOfDay,
    'weekdays': value.weekdays,
    'slots': value.slots
        .map((slot) => {'weekday': slot.weekday, 'timeOfDay': slot.timeOfDay})
        .toList(growable: false),
  };

  Map<String, Object?> _event(EventTriggerConfig value) => {
    'source': value.source.name,
    'filter': value.filter,
    'channelId': value.channelId,
  };

  TaskTrigger _triggerFrom(Map<dynamic, dynamic> value) {
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return TaskTrigger(
      id: _string(data['id']),
      teamId: _string(data['teamId']),
      taskId: _string(data['taskId']),
      taskTitle: _string(data['taskTitle'], fallback: 'Unbenannte Aufgabe'),
      type: _type(data['type']),
      enabled: data['enabled'] is bool ? data['enabled'] as bool : false,
      schedule: _scheduleFrom(data['config']),
      event: _eventFrom(data['eventConfig']),
      policy: _policy(data['policy']),
      nextRunAt: _dateOrNull(data['nextRunAt']),
      lastRunAt: _dateOrNull(data['lastRunAt']),
      lastRunId: _nullableString(data['lastRunId']),
    );
  }

  TriggerType _type(Object? value) => TriggerType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TriggerType.schedule,
  );

  ScheduleConfig? _scheduleFrom(Object? value) {
    if (value is! Map) return null;
    final config = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    if (config.isEmpty) return null;
    return ScheduleConfig(
      kind: ScheduleKind.values.firstWhere(
        (kind) => kind.name == config['kind'],
        orElse: () => ScheduleKind.daily,
      ),
      timezone: _string(config['timezone'], fallback: 'Europe/Berlin'),
      runAt: _dateOrNull(config['runAt']),
      timeOfDay: _nullableString(config['timeOfDay']),
      weekdays: _integers(config['weekdays']),
      slots: _slots(config['slots']),
    );
  }

  EventTriggerConfig? _eventFrom(Object? value) {
    if (value is! Map || value.isEmpty) return null;
    final config = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return EventTriggerConfig(
      source: EventTriggerSource.values.firstWhere(
        (source) => source.name == config['source'],
        orElse: () => EventTriggerSource.webhookReceived,
      ),
      filter: _string(config['filter']),
      channelId: _nullableString(config['channelId']),
    );
  }

  TriggerRunPolicy _policy(Object? value) {
    final policy = value is Map ? value['ifRunning'] : null;
    return TriggerRunPolicy.values.firstWhere(
      (item) => item.name == policy,
      orElse: () => TriggerRunPolicy.skipIfRunning,
    );
  }

  List<int> _integers(Object? value) =>
      value is List ? value.whereType<int>().toList(growable: false) : const [];

  List<WeeklyTimeSlot> _slots(Object? value) => value is List
      ? value
            .whereType<Map>()
            .map(
              (slot) => WeeklyTimeSlot(
                weekday: slot['weekday'] as int? ?? 0,
                timeOfDay: _string(slot['timeOfDay']),
              ),
            )
            .toList(growable: false)
      : const [];

  DateTime? _dateOrNull(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  String _string(Object? value, {String fallback = ''}) =>
      value is String ? value : fallback;

  String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
