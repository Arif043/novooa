import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../domain/entities/dashboard_task.dart';
import '../domain/repositories/task_catalog.dart';

/// `GET /v1/tasks`, `POST /v1/task-runs`; aktualisiert über das Thema `tasks`.
class RuntimeTaskCatalog implements TaskCatalog {
  const RuntimeTaskCatalog(this._api, this._realtime);

  final WorkspaceApiClient _api;
  final WorkspaceRealtimeChannel _realtime;

  @override
  Stream<List<DashboardTask>> watchTasks() =>
      watchWorkspaceChannel('tasks', _loadTasks, _realtime);

  Future<List<DashboardTask>> _loadTasks() async {
    final response = await _api.get('/v1/tasks');
    final items = response['items'];
    if (items is! List) return const [];
    return items.whereType<Map<String, Object?>>().map(_taskFrom).toList();
  }

  DashboardTask _taskFrom(Map<String, Object?> json) => DashboardTask(
    id: TaskId(json['id'] as String? ?? ''),
    title: json['title'] as String? ?? '',
    objective: json['objective'] as String? ?? '',
  );

  @override
  Future<Result<RunId, TaskStartFailure>> start(
    TaskId id, {
    String context = '',
  }) async {
    try {
      final response = await _api.post('/v1/task-runs', {
        'taskId': id.value,
        'context': context,
      });
      final runId = response['runId'];
      if (runId is! String) return const Error(TaskStartFailure.rejected);
      return Success(RunId(runId));
    } on WorkspaceHttpException {
      return const Error(TaskStartFailure.rejected);
    } on Object {
      return const Error(TaskStartFailure.unreachable);
    }
  }
}
