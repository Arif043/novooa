import 'package:flutter/widgets.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

final class RenameTaskAgentCommand extends TaskBuilderAgentCommand {
  const RenameTaskAgentCommand({required String label, required this.title})
    : super(label);

  final String title;

  @override
  Future<void> perform(TaskBuilderCubit cubit) => cubit.updateTitle(title);

  @override
  Future<void> performWithCursor(
    TaskBuilderCubit cubit,
    AgentCursorPerformer cursor,
  ) async {
    await cursor.typeInto(
      TaskBuilderCursorTargets.taskTitle,
      title,
      cubit.updateTitle,
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
