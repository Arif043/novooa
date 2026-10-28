import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/results/infrastructure/local_run_result_repository.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';

final _run = TaskRun(
  id: const UniqueId('run-1'),
  taskId: 'task-1',
  taskTitle: 'Beispiel',
  status: TaskRunStatus.succeeded,
  updatedAt: DateTime(2026, 10, 28),
);

void main() {
  test(
    'liest einen echten Graph-Schnappschuss der Runtime samt Zweigen',
    () async {
      final snapshot =
          jsonDecode(
                File(
                  'test/features/results/fixtures/run_graph_snapshot.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final repository = LocalRunResultRepository(_Client(graph: snapshot));

      final result = (await repository.load(_run)).tryGetSuccess()!;

      final graph = result.graph!;
      expect(graph.nodes.map((node) => node.id.value), [
        'node.1',
        'node.2',
        'node.3',
      ]);
      expect(graph.edges, hasLength(2));
      final branches =
          (graph.nodes.last.config as ConditionalNodeConfig).branches;
      expect(branches.every((branch) => branch.graph.nodes.isNotEmpty), isTrue);
      expect(result.nodes.single.parentNodeId, 'node.3');
    },
  );

  test('ein alter Lauf ohne Schnappschuss hat keinen Graphen', () async {
    final repository = LocalRunResultRepository(_Client(graph: null));

    final result = (await repository.load(_run)).tryGetSuccess()!;

    expect(result.graph, isNull);
  });
}

class _Client implements WorkspaceApiClient {
  _Client({required this.graph});

  final Map<String, Object?>? graph;

  @override
  Future<Map<String, Object?>> get(String path) async {
    if (path.endsWith('/graph')) {
      final snapshot = graph;
      if (snapshot == null) {
        throw WorkspaceHttpException(
          404,
          const WorkspaceApiError(message: 'fehlt'),
        );
      }
      return snapshot;
    }
    return {
      'items': [
        {
          'id': 'a1',
          'runId': 'run-1',
          'taskId': 'task-1',
          'taskTitle': 'node.3.1',
          'target': 'node',
          'status': 'succeeded',
          'occurredAt': '2026-10-28T10:00:00Z',
          'nodeId': 'innen',
          'parentNodeId': 'node.3',
          'outputs': <String, Object?>{},
        },
      ],
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
