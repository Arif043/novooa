import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/create_task_trigger_input.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../models/event_trigger_config_mapper.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../../domain/entities/trigger_cycle_analysis.dart';
import '../../domain/repositories/task_trigger_repository.dart';

class LocalTaskTriggerRepository implements TaskTriggerRepository {
  const LocalTaskTriggerRepository(this._client, this._channel, this._baseUri);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  /// Adresse der Runtime, unter der externe Systeme Webhooks aufrufen.
  final Uri _baseUri;

  @override
  Future<TriggerCycleAnalysis> analyzeTrigger(
    CreateTaskTriggerInput input,
  ) async {
    if (input.type != TriggerType.event || !input.isValid) {
      return TriggerCycleAnalysis.none;
    }
    final response = await _client.post(
      '/v1/task-triggers/analysis',
      _body(input),
    );
    final warnings = response['warnings'];
    return TriggerCycleAnalysis(
      blocked: response['blocked'] as String?,
      warnings: warnings is List
          ? warnings.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  @override
  Future<void> createTrigger(CreateTaskTriggerInput input) async {
    if (!input.isValid) return;
    await _client.post('/v1/task-triggers', _body(input));
  }

  Map<String, Object?> _body(CreateTaskTriggerInput input) => {
    'taskId': input.taskId,
    'type': input.type.name,
    'enabled': input.enabled,
    'config': input.schedule == null
        ? <String, Object?>{}
        : _schedule(input.schedule!),
    'eventConfig': input.event == null
        ? <String, Object?>{}
        : EventTriggerConfigMapper.toDocument(input.event!),
    'policy': {'ifRunning': input.policy.name},
  };

  @override
  Future<void> deleteTrigger(String triggerId) =>
      _client.delete('/v1/task-triggers/$triggerId');

  @override
  Future<void> rotateWebhookToken(String triggerId) =>
      _client.post('/v1/task-triggers/$triggerId/webhook-token', const {});

  @override
  Future<void> setTriggerEnabled(String triggerId, bool enabled) =>
      _client.put('/v1/task-triggers/$triggerId/enabled', {'enabled': enabled});

  @override
  Stream<List<TaskTrigger>> watchTriggers() =>
      watchWorkspaceChannel('task-triggers', _loadTriggers, _channel);

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

  TaskTrigger _triggerFrom(Map<dynamic, dynamic> value) {
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    final event = EventTriggerConfigMapper.fromDocument(data['eventConfig']);
    return TaskTrigger(
      id: _string(data['id']),
      teamId: _string(data['teamId']),
      taskId: _string(data['taskId']),
      taskTitle: _string(data['taskTitle'], fallback: 'Unbenannte Aufgabe'),
      type: _type(data['type']),
      enabled: data['enabled'] is bool ? data['enabled'] as bool : false,
      schedule: _scheduleFrom(data['config']),
      event: event,
      webhookUrl: _webhookUrl(_string(data['id']), event),
      policy: _policy(data['policy']),
      nextRunAt: _dateOrNull(data['nextRunAt']),
      lastRunAt: _dateOrNull(data['lastRunAt']),
      lastRunId: _nullableString(data['lastRunId']),
    );
  }

  String? _webhookUrl(String triggerId, EventTriggerConfig? event) {
    final token = event?.webhook?.token ?? '';
    if (token.isEmpty) return null;
    return _baseUri
        .replace(
          pathSegments: [
            ..._baseUri.pathSegments.where((segment) => segment.isNotEmpty),
            'hooks',
            triggerId,
            token,
          ],
          query: null,
          fragment: null,
        )
        .toString();
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
