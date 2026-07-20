import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class ExecutedTaskBuilderAgentCommand {
  const ExecutedTaskBuilderAgentCommand({
    required this.command,
    required this.previousTask,
  });

  final TaskBuilderAgentCommand command;
  final Task previousTask;
}

class TaskBuilderAgentCommandHistory {
  const TaskBuilderAgentCommandHistory(this.items);

  final List<ExecutedTaskBuilderAgentCommand> items;

  bool get canUndo => items.isNotEmpty;

  Future<void> undo(TaskBuilderCubit cubit) {
    final firstCommand = items.first;
    return firstCommand.command.undo(cubit, firstCommand.previousTask);
  }
}
