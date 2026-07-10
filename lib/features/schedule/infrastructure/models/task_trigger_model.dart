import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';

class TaskTriggerModel {
  const TaskTriggerModel({
    required this.id,
    required this.teamId,
    required this.taskId,
    required this.taskTitle,
    required this.enabled,
    required this.schedule,
    required this.policy,
    this.nextRunAt,
    this.lastRunAt,
    this.lastRunId,
  });

  final String id;
  final String teamId;
  final String taskId;
  final String taskTitle;
  final bool enabled;
  final ScheduleConfig schedule;
  final TriggerRunPolicy policy;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String? lastRunId;

  factory TaskTriggerModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return TaskTriggerModel(
      id: data['id'] as String? ?? snapshot.id,
      teamId: data['teamId'] as String? ?? '',
      taskId: data['taskId'] as String? ?? '',
      taskTitle: data['taskTitle'] as String? ?? 'Unbenannte Aufgabe',
      enabled: data['enabled'] as bool? ?? false,
      schedule: _scheduleFrom(data['config']),
      policy: _policyFrom(data['policy']),
      nextRunAt: _dateFrom(data['nextRunAt']),
      lastRunAt: _dateFrom(data['lastRunAt']),
      lastRunId: data['lastRunId'] as String?,
    );
  }

  TaskTrigger toDomain() {
    return TaskTrigger(
      id: id,
      teamId: teamId,
      taskId: taskId,
      taskTitle: taskTitle,
      type: TriggerType.schedule,
      enabled: enabled,
      schedule: schedule,
      policy: policy,
      nextRunAt: nextRunAt,
      lastRunAt: lastRunAt,
      lastRunId: lastRunId,
    );
  }

  static ScheduleConfig _scheduleFrom(Object? value) {
    final data = value is Map ? _objectMapFrom(value) : <String, Object?>{};
    return ScheduleConfig(
      kind: _kindFrom(data['kind']),
      timezone: data['timezone'] as String? ?? 'Europe/Berlin',
      runAt: _dateFrom(data['runAt']),
      timeOfDay: data['timeOfDay'] as String?,
      weekdays: _weekdaysFrom(data['weekdays']),
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

  static DateTime? _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static Map<String, Object?> _objectMapFrom(Map<dynamic, dynamic> data) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
}
