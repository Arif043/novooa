import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/domain/entities/media_input_submission.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/domain/entities/task_run_dialog_input_field.dart';
import 'package:syscat2/features/activity/domain/entities/task_run_interaction.dart';
import 'package:syscat2/features/activity/domain/entities/task_run_media_input.dart';
import 'package:syscat2/features/activity/domain/repositories/media_input_picker.dart';
import 'package:syscat2/features/activity/domain/repositories/task_activity_repository.dart';
import 'package:syscat2/features/activity/domain/repositories/task_run_media_input_repository.dart';
import 'package:syscat2/features/activity/domain/repositories/task_run_repository.dart';
import 'package:syscat2/features/activity/domain/usecases/review_task_run.dart';
import 'package:syscat2/features/activity/domain/usecases/upload_task_run_media_input.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_activities.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_runs.dart';
import 'package:syscat2/features/activity/presentation/cubits/activity_cubit.dart';
import 'package:syscat2/features/activity/presentation/cubits/activity_state.dart';

class _ActivityRepository implements TaskActivityRepository {
  _ActivityRepository(this.activities);

  final List<TaskActivity> activities;

  @override
  Future<void> add(TaskActivity activity) async {
    activities.add(activity);
  }

  @override
  Stream<List<TaskActivity>> watchRecent() {
    return Stream.value(activities);
  }
}

class _RunRepository implements TaskRunRepository {
  const _RunRepository(this.runs);

  final List<TaskRun> runs;

  @override
  Stream<List<TaskRun>> watchRecent() {
    return Stream.value(runs);
  }

  @override
  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
    Map<String, Object?> formValues = const {},
  }) async {}
}

class _RecordingRunRepository extends _RunRepository {
  _RecordingRunRepository(super.runs);

  Map<String, Object?>? submittedFormValues;

  @override
  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
    Map<String, Object?> formValues = const {},
  }) async {
    submittedFormValues = formValues;
  }
}

class _MediaInputPicker implements MediaInputPicker {
  @override
  Future<MediaInputSubmission?> pick(TaskRunMediaInputSource source) async {
    return null;
  }
}

class _FixedMediaInputPicker implements MediaInputPicker {
  const _FixedMediaInputPicker(this.submission);

  final MediaInputSubmission submission;

  @override
  Future<MediaInputSubmission?> pick(TaskRunMediaInputSource source) async {
    return submission;
  }
}

class _MediaInputRepository implements TaskRunMediaInputRepository {
  _MediaInputRepository({this.fails = false});

  final bool fails;
  final uploaded = <String>[];

  @override
  Future<String> upload(MediaInputSubmission submission) async {
    if (fails) throw StateError('Upload fehlgeschlagen');
    uploaded.add(submission.name);
    return 'file.${uploaded.length}';
  }
}

void main() {
  test('ActivityCubit laedt Aktivitaeten', () async {
    final cubit = ActivityCubit(
      watchTaskActivities: WatchTaskActivities(
        _ActivityRepository([_activity()]),
      ),
      watchTaskRuns: WatchTaskRuns(_RunRepository([_run()])),
      reviewTaskRun: ReviewTaskRun(_RunRepository([_run()])),
      mediaInputPicker: _MediaInputPicker(),
      uploadTaskRunMediaInput: UploadTaskRunMediaInput(_MediaInputRepository()),
    );

    cubit.load();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, ActivityLoadStatus.ready);
    expect(cubit.state.activities.single.taskTitle, 'Testaufgabe');
    expect(cubit.state.runs.single.status, TaskRunStatus.waitingForApproval);
    await cubit.close();
  });

  test('ein Formular mit Bild lädt es hoch und sendet dessen fileId', () async {
    final runRepository = _RecordingRunRepository([_formRun()]);
    final uploads = _MediaInputRepository();
    final cubit = _cubitWith(runRepository, uploads);

    final picked = await cubit.pickImage(TaskRunMediaInputSource.documentScan);
    await cubit.submitDialogInput(_formRun(), {
      'betrag': 12.5,
      'beleg': picked,
    });

    expect(uploads.uploaded, ['beleg.jpg']);
    expect(runRepository.submittedFormValues, {
      'betrag': 12.5,
      'beleg': 'file.1',
    });
    await cubit.close();
  });

  test('scheitert der Upload, geht keine Antwort an die Runtime', () async {
    final runRepository = _RecordingRunRepository([_formRun()]);
    final cubit = _cubitWith(runRepository, _MediaInputRepository(fails: true));

    await expectLater(
      cubit.submitDialogInput(_formRun(), {'beleg': _receipt}),
      throwsStateError,
    );

    expect(runRepository.submittedFormValues, isNull);
    await cubit.close();
  });
}

final _receipt = MediaInputSubmission(
  name: 'beleg.jpg',
  bytes: Uint8List.fromList([1, 2, 3]),
  contentType: 'image/jpeg',
);

ActivityCubit _cubitWith(
  _RecordingRunRepository runs,
  _MediaInputRepository uploads,
) {
  return ActivityCubit(
    watchTaskActivities: WatchTaskActivities(_ActivityRepository([])),
    watchTaskRuns: WatchTaskRuns(runs),
    reviewTaskRun: ReviewTaskRun(runs),
    mediaInputPicker: _FixedMediaInputPicker(_receipt),
    uploadTaskRunMediaInput: UploadTaskRunMediaInput(uploads),
  );
}

TaskActivity _activity() {
  return TaskActivity(
    id: const UniqueId('activity.1'),
    runId: const UniqueId('run.1'),
    taskId: 'task.1',
    taskTitle: 'Testaufgabe',
    target: TaskActivityTarget.task,
    status: TaskActivityStatus.started,
    occurredAt: DateTime.utc(2026),
  );
}

TaskRun _run() {
  return TaskRun(
    id: const UniqueId('run.1'),
    taskId: 'task.1',
    taskTitle: 'Testaufgabe',
    status: TaskRunStatus.waitingForApproval,
    updatedAt: DateTime.utc(2026),
  );
}

TaskRun _formRun() {
  return TaskRun(
    id: const UniqueId('run.form'),
    taskId: 'task.1',
    taskTitle: 'Beleg erfassen',
    status: TaskRunStatus.waitingForApproval,
    updatedAt: DateTime.utc(2026),
    interaction: const TaskRunInteraction(
      type: TaskRunInteractionType.dialogInput,
      instruction: 'Fotografiere den Beleg.',
      dialogInputFields: [
        TaskRunDialogInputField(
          name: 'betrag',
          type: TaskRunDialogInputFieldType.decimal,
          options: [],
        ),
        TaskRunDialogInputField(
          name: 'beleg',
          type: TaskRunDialogInputFieldType.image,
          options: [],
        ),
      ],
    ),
  );
}
