import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/task_builder/infrastructure/datasources/local_http_task_runner_datasource.dart';
import 'package:syscat2/features/task_builder/infrastructure/repositories/local_task_repository.dart';

void main() {
  test('loads and starts a task through the local runtime', () async {
    final client = RecordingWorkspaceApiClient()
      ..responses['GET /v1/tasks'] = {
        'items': [taskJson()],
      }
      ..responses['POST /v1/task-runs'] = {
        'runId': 'run-1',
        'taskId': 'task-1',
        'status': 'queued',
      };
    final repository = LocalTaskRepository(
      client,
      LocalHttpTaskRunnerDatasource(client),
    );

    final tasks = await repository.watchTasks().first;
    final runOrFailure = await repository.execute(task: tasks.single);

    expect(tasks.single.id, 'task-1');
    runOrFailure.when(
      (run) => expect(run.runId.value, 'run-1'),
      (failure) => fail(failure.message),
    );
    expect(client.requests, contains('PUT /v1/tasks/task-1'));
    expect(client.requests, contains('POST /v1/task-runs'));
  });
}

class RecordingWorkspaceApiClient extends WorkspaceApiClient {
  final Map<String, Map<String, Object?>> responses = {};
  final List<String> requests = [];

  @override
  Future<Map<String, Object?>> delete(String path) => _response('DELETE', path);

  @override
  Future<Map<String, Object?>> get(String path) => _response('GET', path);

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) {
    return _response('POST', path);
  }

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) {
    return _response('PUT', path);
  }

  Future<Map<String, Object?>> _response(String method, String path) async {
    final key = '$method $path';
    requests.add(key);
    return responses[key] ?? const {};
  }
}

Map<String, Object?> taskJson() => {
  'id': 'task-1',
  'title': 'Lokale Aufgabe',
  'objective': '',
  'selectedNodeId': 'node-1',
  'graph': {
    'nodes': [
      {
        'id': 'node-1',
        'title': 'Text',
        'description': '',
        'referenceName': 'text',
        'config': {'primitive': 'stringInput', 'value': 'Hallo'},
      },
    ],
    'edges': <Object?>[],
  },
};
