import '../../domain/entities/task_definition.dart';

sealed class TaskBuilderState {
  const TaskBuilderState();
}

class TaskBuilderLoading extends TaskBuilderState {
  const TaskBuilderLoading();
}

class TaskBuilderLoaded extends TaskBuilderState {
  const TaskBuilderLoaded(this.taskDefinition);

  final TaskDefinition taskDefinition;
}

class TaskBuilderFailure extends TaskBuilderState {
  const TaskBuilderFailure(this.message);

  final String message;
}
