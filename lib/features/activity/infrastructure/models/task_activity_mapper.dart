import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/task_activity.dart';
import 'failure_details_mapper.dart';
import 'run_effect_mapper.dart';
import 'run_origin_mapper.dart';
import 'teamwork_conversation_mapper.dart';

/// Eine Aktivität aus `GET /v1/activities` bzw. `/v1/task-runs/:id/activities`.
TaskActivity taskActivityFrom(Map<dynamic, dynamic> value) {
  final data = {
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
  return TaskActivity(
    id: UniqueId(_string(data['id'])),
    runId: UniqueId(_string(data['runId'])),
    taskId: _string(data['taskId']),
    taskTitle: _string(data['taskTitle'], fallback: 'Unbenannte Aufgabe'),
    target: _targetFrom(data['target']),
    status: _statusFrom(data['status']),
    occurredAt: _dateFrom(data['occurredAt']),
    nodeId: _nullableString(data['nodeId']),
    primitive: _nullableString(data['primitive']),
    input: _nullableString(data['input']),
    output: _nullableString(data['output']),
    message: _nullableString(data['message']),
    failureCode: ActivityFailureCode.fromName(data['failureCode']),
    failureDetails: failureDetailsFrom(data['failureDetails']),
    outputs: _outputsFrom(data['outputs']),
    stdout: _consoleText(data['console'], 'stdout'),
    stderr: _consoleText(data['console'], 'stderr'),
    conversation: teamworkConversationFrom(data['conversation']),
    effects: runEffectsFrom(data['effects']),
    origin: runOriginFrom(data['origin']),
    parentNodeId: _nullableString(data['parentNodeId']),
    iteration: data['iteration'] is num
        ? (data['iteration'] as num).toInt()
        : null,
    selectedBranchId: _nullableString(data['selectedBranchId']),
  );
}

String _consoleText(Object? console, String stream) {
  if (console is! Map) return '';
  final text = console[stream];
  return text is String ? text : '';
}

TaskActivityTarget _targetFrom(Object? value) =>
    TaskActivityTarget.values.firstWhere(
      (target) => target.name == value,
      orElse: () => TaskActivityTarget.task,
    );

TaskActivityStatus _statusFrom(Object? value) =>
    TaskActivityStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaskActivityStatus.started,
    );

DateTime _dateFrom(Object? value) => value is String
    ? DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0)
    : DateTime.fromMillisecondsSinceEpoch(0);

Map<String, Object?> _outputsFrom(Object? value) => value is Map
    ? {for (final entry in value.entries) entry.key.toString(): entry.value}
    : const {};

String _string(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;
String? _nullableString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;
