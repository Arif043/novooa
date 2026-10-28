import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/task_activity.dart';
import '../../domain/repositories/task_activity_repository.dart';
import '../models/task_activity_mapper.dart';

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
    return items.whereType<Map>().map(taskActivityFrom).toList(growable: false);
  }
}
