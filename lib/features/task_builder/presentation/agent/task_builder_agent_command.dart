import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

abstract class TaskBuilderAgentCommand {
  const TaskBuilderAgentCommand(this.label);

  final String label;

  Future<void> perform(TaskBuilderCubit cubit);

  /// Standard: ohne sichtbare Bedienung. Commands mit Eingabemasken überschreiben.
  Future<void> performWithCursor(
    TaskBuilderCubit cubit,
    AgentCursorPerformer cursor,
  ) => perform(cubit);
}

class TaskBuilderPlanAction implements CursorAwarePlanAction {
  const TaskBuilderPlanAction({required this.cubit, required this.command});

  final TaskBuilderCubit cubit;
  final TaskBuilderAgentCommand command;

  @override
  String get label => command.label;

  @override
  Future<AssistantPlanUndo?> execute() => _run(() => command.perform(cubit));

  @override
  Future<AssistantPlanUndo?> executeWithCursor(AgentCursorPerformer cursor) {
    return _run(() => command.performWithCursor(cubit, cursor));
  }

  Future<AssistantPlanUndo?> _run(Future<void> Function() perform) async {
    final task = cubit.loadedTaskOrNull();
    if (task == null) return null;
    await perform();
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
