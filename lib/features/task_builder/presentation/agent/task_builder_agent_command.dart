import 'package:syscat2/features/assistant/domain/entities/assistant_task_command.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

abstract interface class TaskBuilderAgentCommand {
  String get label;
  Future<Task?> execute(TaskBuilderCubit cubit);
  Future<void> undo(TaskBuilderCubit cubit, Task previousTask);
}

abstract class SnapshotTaskBuilderAgentCommand
    implements TaskBuilderAgentCommand {
  const SnapshotTaskBuilderAgentCommand(this.source);

  final AssistantTaskCommand source;

  @override
  String get label => source.label;

  @override
  Future<Task?> execute(TaskBuilderCubit cubit) async {
    final before = cubit.loadedTaskOrNull();
    if (before == null) return null;
    await perform(cubit);
    return before;
  }

  @override
  Future<void> undo(TaskBuilderCubit cubit, Task previousTask) {
    return cubit.restoreTask(previousTask);
  }

  Future<void> perform(TaskBuilderCubit cubit);
}
