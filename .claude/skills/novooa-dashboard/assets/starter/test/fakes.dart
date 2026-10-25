import 'dart:async';

import 'package:multiple_result/multiple_result.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/domain/entities/task_run.dart';
import 'package:__DASHBOARD_PACKAGE__/features/runs/domain/repositories/run_repository.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/domain/entities/dashboard_task.dart';
import 'package:__DASHBOARD_PACKAGE__/features/tasks/domain/repositories/task_catalog.dart';

class FakeTaskCatalog implements TaskCatalog {
  final tasks = StreamController<List<DashboardTask>>.broadcast();
  final starts = <(TaskId, String)>[];
  Result<RunId, TaskStartFailure> startResult = const Success(RunId('run-1'));

  @override
  Stream<List<DashboardTask>> watchTasks() => tasks.stream;

  @override
  Future<Result<RunId, TaskStartFailure>> start(
    TaskId id, {
    String context = '',
  }) async {
    starts.add((id, context));
    return startResult;
  }
}

class FakeRunRepository implements RunRepository {
  final runs = StreamController<List<TaskRun>>.broadcast();
  final reviews = <(RunId, RunReviewDecision, Map<String, Object>)>[];
  Result<RunId, RunReviewFailure> reviewResult = const Success(RunId('run-1'));

  @override
  Stream<List<TaskRun>> watchRuns() => runs.stream;

  @override
  Future<Result<RunId, RunReviewFailure>> review(
    RunId id,
    RunReviewDecision decision, {
    Map<String, Object> formValues = const {},
  }) async {
    reviews.add((id, decision, formValues));
    return reviewResult;
  }
}

TaskRun waitingRun({RunInteraction? interaction}) => TaskRun(
  id: const RunId('run-1'),
  taskId: const TaskId('task-1'),
  taskTitle: 'Rechnung prüfen',
  status: RunStatus.waitingForApproval,
  updatedAt: DateTime(2026, 10, 25),
  interaction: interaction ?? const ApprovalRequest('Bitte prüfen'),
);
