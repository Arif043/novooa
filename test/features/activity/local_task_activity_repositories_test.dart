import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/domain/entities/task_run_interaction.dart';
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

  test('liest documentScanEnabled aus einer mediaInput-Interaction', () async {
    final client = RecordingWorkspaceApiClient(
      interaction: {
        'kind': 'mediaInput',
        'instruction': 'Beleg fotografieren.',
        'documentScanEnabled': true,
      },
    );
    final run = (await LocalTaskRunRepository(client).watchRecent().first).single;

    expect(run.interaction?.type, TaskRunInteractionType.mediaInput);
    expect(run.mediaInput?.documentScanEnabled, isTrue);
  });

  test('liest documentScanEnabled als false, wenn das Feld fehlt', () async {
    final client = RecordingWorkspaceApiClient(
      interaction: {
        'kind': 'mediaInput',
        'instruction': 'Beleg fotografieren.',
      },
    );
    final run = (await LocalTaskRunRepository(client).watchRecent().first).single;

    expect(run.mediaInput?.documentScanEnabled, isFalse);
  });
}

class RecordingWorkspaceApiClient extends WorkspaceApiClient {
  RecordingWorkspaceApiClient({Map<String, Object?>? interaction})
    : _interaction = interaction;

  final Map<String, Object?>? _interaction;
  // Initialisierender Formalparameter (this._interaction) ist hier nicht
  // möglich, weil der Konstruktorparameter benannt ("interaction") anders
  // heißt als das private Feld — bewusste Namensklarheit im Aufruf
  // (`RecordingWorkspaceApiClient(interaction: ...)`).
  String? reviewedRunId;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async {
    return switch (path) {
      '/v1/task-runs' => {
        'items': [runJson(interaction: _interaction)],
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

Map<String, Object?> runJson({Map<String, Object?>? interaction}) => {
  'runId': 'run-1',
  'taskId': 'task-1',
  'taskTitle': 'Lokale Aufgabe',
  'status': 'waitingForApproval',
  'createdAt': '2026-09-08T10:00:00Z',
  'updatedAt': '2026-09-08T10:01:00Z',
  'interaction':
      interaction ?? {'kind': 'approval', 'instruction': 'Bitte prüfen.'},
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
