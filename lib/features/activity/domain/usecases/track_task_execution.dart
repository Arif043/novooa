import '../../../../core/domain/unique_id.dart';
import '../../../task_builder/domain/entities/task_definition.dart';
import '../../../task_builder/domain/entities/task_execution_failure.dart';
import '../../../task_builder/domain/entities/task_execution_result.dart';
import '../entities/task_activity.dart';
import '../repositories/task_activity_repository.dart';

typedef TaskActivityClock = DateTime Function();
typedef TaskActivityIdFactory = UniqueId Function();

class TrackTaskExecution {
  TrackTaskExecution(
    this._repository, {
    TaskActivityClock? clock,
    TaskActivityIdFactory? idFactory,
  }) : _clock = clock ?? DateTime.now,
       _idFactory = idFactory;

  final TaskActivityRepository _repository;
  final TaskActivityClock _clock;
  final TaskActivityIdFactory? _idFactory;
  int _idSequence = 0;

  Future<UniqueId> started(TaskDefinition taskDefinition, String input) async {
    final runId = _nextId();
    await _repository.add(
      _taskActivity(
        runId: runId,
        taskDefinition: taskDefinition,
        status: TaskActivityStatus.started,
        input: input,
      ),
    );
    return runId;
  }

  Future<void> succeeded({
    required UniqueId runId,
    required TaskDefinition taskDefinition,
    required TaskExecutionResult result,
  }) async {
    for (final nodeResult in result.nodeResults) {
      await _repository.add(_nodeActivity(runId, taskDefinition, nodeResult));
    }
    await _repository.add(
      _taskActivity(
        runId: runId,
        taskDefinition: taskDefinition,
        status: TaskActivityStatus.succeeded,
        output: result.finalOutput,
      ),
    );
  }

  Future<void> failed({
    required UniqueId runId,
    required TaskDefinition taskDefinition,
    required TaskExecutionFailure failure,
  }) {
    return _repository.add(
      _taskActivity(
        runId: runId,
        taskDefinition: taskDefinition,
        status: TaskActivityStatus.failed,
        message: failure.message,
      ),
    );
  }

  TaskActivity _taskActivity({
    required UniqueId runId,
    required TaskDefinition taskDefinition,
    required TaskActivityStatus status,
    String? input,
    String? output,
    String? message,
  }) {
    return TaskActivity(
      id: _nextId(),
      runId: runId,
      taskId: taskDefinition.id,
      taskTitle: taskDefinition.title,
      target: TaskActivityTarget.task,
      status: status,
      occurredAt: _clock(),
      input: input,
      output: output,
      message: message,
    );
  }

  TaskActivity _nodeActivity(
    UniqueId runId,
    TaskDefinition taskDefinition,
    NodeExecutionResult result,
  ) {
    return TaskActivity(
      id: _nextId(),
      runId: runId,
      taskId: taskDefinition.id,
      taskTitle: taskDefinition.title,
      target: TaskActivityTarget.node,
      status: _nodeStatus(result),
      occurredAt: _clock(),
      nodeId: result.nodeId,
      primitive: result.primitive,
      output: result.output,
      message: result.message,
    );
  }

  TaskActivityStatus _nodeStatus(NodeExecutionResult result) {
    return switch (result.status) {
      NodeExecutionStatus.executed => TaskActivityStatus.succeeded,
      NodeExecutionStatus.skipped => TaskActivityStatus.skipped,
    };
  }

  UniqueId _nextId() {
    final idFactory = _idFactory;
    if (idFactory != null) return idFactory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return UniqueId('$timestamp.${_idSequence++}');
  }
}
