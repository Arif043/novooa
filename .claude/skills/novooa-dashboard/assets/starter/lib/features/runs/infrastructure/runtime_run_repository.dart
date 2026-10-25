import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../domain/entities/task_run.dart';
import '../domain/repositories/run_repository.dart';
import 'task_run_mapper.dart';

/// `GET /v1/task-runs`, `POST /v1/task-runs/review`; Thema `task-runs`.
class RuntimeRunRepository implements RunRepository {
  const RuntimeRunRepository(this._api, this._realtime);

  final WorkspaceApiClient _api;
  final WorkspaceRealtimeChannel _realtime;

  @override
  Stream<List<TaskRun>> watchRuns() =>
      watchWorkspaceChannel('task-runs', _loadRuns, _realtime);

  Future<List<TaskRun>> _loadRuns() async {
    final response = await _api.get('/v1/task-runs');
    final items = response['items'];
    if (items is! List) return const [];
    return items
        .whereType<Map<String, Object?>>()
        .map(TaskRunMapper.fromJson)
        .toList();
  }

  @override
  Future<Result<RunId, RunReviewFailure>> review(
    RunId id,
    RunReviewDecision decision, {
    Map<String, Object> formValues = const {},
  }) async {
    try {
      await _api.post('/v1/task-runs/review', {
        'runId': id.value,
        'decision': decision.name,
        if (formValues.isNotEmpty) 'formValues': formValues,
      });
      return Success(id);
    } on WorkspaceHttpException {
      return const Error(RunReviewFailure.rejected);
    } on Object {
      return const Error(RunReviewFailure.unreachable);
    }
  }
}
