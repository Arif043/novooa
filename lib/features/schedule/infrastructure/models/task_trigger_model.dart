import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/event_trigger_config.dart';
import 'event_trigger_config_mapper.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';

class TaskTriggerModel {
  const TaskTriggerModel({
    required this.id,
    required this.teamId,
    required this.taskId,
    required this.taskTitle,
    required this.type,
    required this.enabled,
    required this.policy,
    this.schedule,
    this.event,
    this.nextRunAt,
    this.lastRunAt,
    this.lastRunId,
  });

  final String id;
  final String teamId;
  final String taskId;
  final String taskTitle;
  final TriggerType type;
  final bool enabled;
  final ScheduleConfig? schedule;
  final EventTriggerConfig? event;
  final TriggerRunPolicy policy;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String? lastRunId;

  factory TaskTriggerModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return TaskTriggerModel.fromData(id: snapshot.id, data: snapshot.data());
  }

  factory TaskTriggerModel.fromData({
    required String id,
    required Map<String, dynamic>? data,
  }) {
    final fields = data ?? {};
    return TaskTriggerModel(
      id: fields['id'] as String? ?? id,
      teamId: fields['teamId'] as String? ?? '',
      taskId: fields['taskId'] as String? ?? '',
      taskTitle: fields['taskTitle'] as String? ?? 'Unbenannte Aufgabe',
      type: _typeFrom(fields['type']),
      enabled: fields['enabled'] as bool? ?? false,
      schedule: _scheduleFrom(fields['config']),
      event: _eventFrom(fields['eventConfig']),
      policy: _policyFrom(fields['policy']),
      nextRunAt: _dateFrom(fields['nextRunAt']),
      lastRunAt: _dateFrom(fields['lastRunAt']),
      lastRunId: fields['lastRunId'] as String?,
    );
  }

  TaskTrigger toDomain() {
    return TaskTrigger(
      id: id,
      teamId: teamId,
      taskId: taskId,
      taskTitle: taskTitle,
      type: type,
      enabled: enabled,
      schedule: schedule,
      event: event,
      policy: policy,
      nextRunAt: nextRunAt,
      lastRunAt: lastRunAt,
      lastRunId: lastRunId,
    );
  }

  static TriggerType _typeFrom(Object? value) {
    return TriggerType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TriggerType.schedule,
    );
  }

  static EventTriggerConfig? _eventFrom(Object? value) =>
      EventTriggerConfigMapper.fromDocument(value);

  static ScheduleConfig? _scheduleFrom(Object? value) {
    if (value is! Map) return null;
    final data = _objectMapFrom(value);
    return ScheduleConfig(
      kind: _kindFrom(data['kind']),
      timezone: data['timezone'] as String? ?? 'Europe/Berlin',
      runAt: _dateFrom(data['runAt']),
      timeOfDay: data['timeOfDay'] as String?,
      weekdays: _weekdaysFrom(data['weekdays']),
      slots: _slotsFrom(data),
    );
  }

  static ScheduleKind _kindFrom(Object? value) {
    return ScheduleKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => ScheduleKind.daily,
    );
  }

  static TriggerRunPolicy _policyFrom(Object? value) {
    final data = value is Map ? _objectMapFrom(value) : <String, Object?>{};
    return TriggerRunPolicy.values.firstWhere(
      (policy) => policy.name == data['ifRunning'],
      orElse: () => TriggerRunPolicy.skipIfRunning,
    );
  }

  static List<int> _weekdaysFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<int>().toList(growable: false);
  }

  static List<WeeklyTimeSlot> _slotsFrom(Map<String, Object?> data) {
    final slots = _slotListFrom(data['slots']);
    if (slots.isNotEmpty) return slots;
    final timeOfDay = data['timeOfDay'] as String?;
    if (timeOfDay == null) return const [];
    return _weekdaysFrom(data['weekdays'])
        .map(
          (weekday) => WeeklyTimeSlot(weekday: weekday, timeOfDay: timeOfDay),
        )
        .toList(growable: false);
  }

  static List<WeeklyTimeSlot> _slotListFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(_objectMapFrom)
        .map(_slotFrom)
        .where((slot) => slot.isValid)
        .toList(growable: false);
  }

  static WeeklyTimeSlot _slotFrom(Map<String, Object?> data) {
    return WeeklyTimeSlot(
      weekday: data['weekday'] as int? ?? 0,
      timeOfDay: data['timeOfDay'] as String? ?? '',
    );
  }

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static Map<String, Object?> _objectMapFrom(Map<dynamic, dynamic> data) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
}
