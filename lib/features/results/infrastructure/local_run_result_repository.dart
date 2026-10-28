import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../activity/domain/entities/task_activity.dart';
import '../../activity/domain/entities/task_run.dart';
import '../../activity/infrastructure/models/task_activity_mapper.dart';
import '../../task_builder/domain/entities/workflow_graph.dart';
import '../../task_builder/infrastructure/models/task_document_mapper.dart';
import '../domain/entities/run_result.dart';
import '../domain/entities/run_result_failure.dart';
import '../domain/repositories/run_result_repository.dart';

/// Lädt den Graph-Schnappschuss und alle Node-Aktivitäten eines Laufs.
class LocalRunResultRepository implements RunResultRepository {
  LocalRunResultRepository(this._client);

  final WorkspaceApiClient _client;
  final _taskMapper = TaskDocumentMapper();

  @override
  Future<Result<RunResult, RunResultFailure>> load(TaskRun run) async {
    try {
      final path = '/v1/task-runs/${run.id.value}';
      final (graph, activities) = await (
        _graph(path, fallbackId: run.taskId),
        _client.get('$path/activities'),
      ).wait;
      return Success(
        RunResult(run: run, graph: graph, nodes: _items(activities)),
      );
    } on Object {
      return const Error(RunResultFailure.loadFailed);
    }
  }

  /// Läufe von vor dem Schnappschuss haben keinen Graphen (404).
  Future<WorkflowGraph?> _graph(
    String path, {
    required String fallbackId,
  }) async {
    try {
      final snapshot = await _client.get('$path/graph');
      return _taskMapper.fromMap({
        ...snapshot,
        'graph': {'nodes': snapshot['nodes'], 'edges': snapshot['edges']},
      }, fallbackId: fallbackId).graph;
    } on WorkspaceHttpException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  List<TaskActivity> _items(Map<String, Object?> response) {
    final items = response['items'];
    if (items is! List) throw const FormatException('Aktivitäten fehlen.');
    return items.whereType<Map>().map(taskActivityFrom).toList(growable: false);
  }
}
