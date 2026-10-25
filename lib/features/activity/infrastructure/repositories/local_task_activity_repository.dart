import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/task_activity.dart';
import '../../domain/repositories/task_activity_repository.dart';
import '../models/failure_details_mapper.dart';
import '../models/run_origin_mapper.dart';
import '../models/teamwork_conversation_mapper.dart';

class LocalTaskActivityRepository implements TaskActivityRepository {
  const LocalTaskActivityRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<TaskActivity>> watchRecent() =>
      watchWorkspaceChannel('task-activities', _loadActivities, _channel);

  @override
  Future<void> add(TaskActivity activity) {
    return _client.post('/v1/activities', {
      'id': activity.id.value,
      'runId': activity.runId.value,
      'taskId': activity.taskId,
      'taskTitle': activity.taskTitle,
      'target': activity.target.name,
      'status': activity.status.name,
      'occurredAt': activity.occurredAt.toUtc().toIso8601String(),
      'nodeId': activity.nodeId,
      'primitive': activity.primitive,
      'input': activity.input,
      'output': activity.output,
      'message': activity.message,
      'outputs': activity.outputs,
    });
  }

  Future<List<TaskActivity>> _loadActivities() async {
    final response = await _client.get('/v1/activities');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Aktivitätenliste ist ungültig.');
    }
    return items
        .whereType<Map>()
        .map(_activityFromJson)
        .toList(growable: false);
  }

  TaskActivity _activityFromJson(Map<dynamic, dynamic> value) {
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
      origin: runOriginFrom(data['origin']),
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
}
