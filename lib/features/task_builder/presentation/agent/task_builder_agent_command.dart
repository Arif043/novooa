import 'package:syscat2/features/assistant/domain/entities/assistant_task_command.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

abstract class TaskBuilderAgentCommand {
  const TaskBuilderAgentCommand(this.source);

  final AssistantTaskCommand source;

  String get label => source.label;

  Future<void> perform(TaskBuilderCubit cubit);
}

class TaskBuilderPlanAction implements AssistantPlanAction {
  const TaskBuilderPlanAction({required this.cubit, required this.command});

  final TaskBuilderCubit cubit;
  final TaskBuilderAgentCommand command;

  @override
  String get label => command.label;

  @override
  Future<AssistantPlanUndo?> execute() async {
    final task = cubit.loadedTaskOrNull();
    if (task == null) return null;
    await command.perform(cubit);
    return _TaskBuilderPlanUndo(cubit, task);
  }
}

class _TaskBuilderPlanUndo implements AssistantPlanUndo {
  const _TaskBuilderPlanUndo(this._cubit, this._task);

  final TaskBuilderCubit _cubit;
  final Task _task;

  @override
  Future<void> undo() => _cubit.restoreTask(_task);
}
