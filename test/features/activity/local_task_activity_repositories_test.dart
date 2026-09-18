import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/infrastructure/repositories/local_task_activity_repository.dart';
import 'package:syscat2/features/activity/infrastructure/repositories/local_task_run_repository.dart';

void main() {
  test('maps local runs, activities and a review command', () async {
    final client = RecordingWorkspaceApiClient();
    final runs = LocalTaskRunRepository(client);
    final activities = LocalTaskActivityRepository(client);

    final run = (await runs.watchRecent().first).single;
    final activity = (await activities.watchRecent().first).single;
    await runs.review(
      run: run,
      decision: TaskRunReviewDecision.approve,
      output: 'Freigegeben',
    );

    expect(run.status, TaskRunStatus.waitingForApproval);
    expect(activity.taskTitle, 'Lokale Aufgabe');
    expect(client.reviewedRunId, 'run-1');
  });
}

class RecordingWorkspaceApiClient extends WorkspaceApiClient {
  String? reviewedRunId;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async {
    return switch (path) {
      '/v1/task-runs' => {
        'items': [runJson()],
      },
      '/v1/activities' => {
        'items': [activityJson()],
      },
      _ => const {},
    };
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    if (path == '/v1/task-runs/review') {
      reviewedRunId = body['runId'] as String?;
    }
    return const {};
  }

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}

Map<String, Object?> runJson() => {
  'runId': 'run-1',
  'taskId': 'task-1',
  'taskTitle': 'Lokale Aufgabe',
  'status': 'waitingForApproval',
  'createdAt': '2026-09-08T10:00:00Z',
  'updatedAt': '2026-09-08T10:01:00Z',
  'interaction': {'kind': 'approval', 'instruction': 'Bitte prüfen.'},
};

Map<String, Object?> activityJson() => {
  'id': 'activity-1',
  'runId': 'run-1',
  'taskId': 'task-1',
  'taskTitle': 'Lokale Aufgabe',
  'target': 'task',
  'status': 'waiting',
  'occurredAt': '2026-09-08T10:01:00Z',
  'outputs': <String, Object?>{},
};
