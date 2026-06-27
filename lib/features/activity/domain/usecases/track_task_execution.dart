import '../../../../core/entities/unique_id.dart';
import '../entities/task_activity.dart';
import '../repositories/task_activity_repository.dart';

typedef TaskActivityClock = DateTime Function();
typedef TaskActivityIdFactory = UniqueId Function();

class TrackTaskStart {
  const TrackTaskStart({
    required this.taskId,
    required this.taskTitle,
    required this.input,
  });

  final String taskId;
  final String taskTitle;
  final String input;
}

class TrackTaskSuccess {
  const TrackTaskSuccess({
    required this.taskId,
    required this.taskTitle,
    required this.output,
    required this.nodes,
  });

  final String taskId;
  final String taskTitle;
  final String output;
  final List<TrackNodeActivity> nodes;
}

class TrackTaskFailure {
  const TrackTaskFailure({
    required this.taskId,
    required this.taskTitle,
    required this.message,
  });

  final String taskId;
  final String taskTitle;
  final String message;
}

class TrackNodeActivity {
  const TrackNodeActivity({
    required this.nodeId,
    required this.primitive,
    required this.status,
    required this.output,
    this.message,
  });

  final String nodeId;
  final String primitive;
  final TaskActivityStatus status;
  final String output;
  final String? message;
}

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

  Future<UniqueId> started(TrackTaskStart start) async {
    final runId = _nextId();
    await _repository.add(
      _taskActivity(
        runId: runId,
        taskId: start.taskId,
        taskTitle: start.taskTitle,
        status: TaskActivityStatus.started,
        input: start.input,
      ),
    );
    return runId;
  }

  Future<void> succeeded({
    required UniqueId runId,
    required TrackTaskSuccess success,
  }) async {
    for (final node in success.nodes) {
      await _repository.add(_nodeActivity(runId, success, node));
    }
    await _repository.add(
      _taskActivity(
        runId: runId,
        taskId: success.taskId,
        taskTitle: success.taskTitle,
        status: TaskActivityStatus.succeeded,
        output: success.output,
      ),
    );
  }

  Future<void> failed({
    required UniqueId runId,
    required TrackTaskFailure failure,
  }) {
    return _repository.add(
      _taskActivity(
        runId: runId,
        taskId: failure.taskId,
        taskTitle: failure.taskTitle,
        status: TaskActivityStatus.failed,
        message: failure.message,
      ),
    );
  }

  TaskActivity _taskActivity({
    required UniqueId runId,
    required String taskId,
    required String taskTitle,
    required TaskActivityStatus status,
    String? input,
    String? output,
    String? message,
  }) {
    return TaskActivity(
      id: _nextId(),
      runId: runId,
      taskId: taskId,
      taskTitle: taskTitle,
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
    TrackTaskSuccess success,
    TrackNodeActivity node,
  ) {
    return TaskActivity(
      id: _nextId(),
      runId: runId,
      taskId: success.taskId,
      taskTitle: success.taskTitle,
      target: TaskActivityTarget.node,
      status: node.status,
      occurredAt: _clock(),
      nodeId: node.nodeId,
      primitive: node.primitive,
      output: node.output,
      message: node.message,
    );
  }

  UniqueId _nextId() {
    final idFactory = _idFactory;
    if (idFactory != null) return idFactory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return UniqueId('$timestamp.${_idSequence++}');
  }
}
