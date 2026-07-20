import 'dart:async';

import 'package:syscat2/features/assistant/domain/entities/assistant_task_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command_factory.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command_history.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

typedef AgentCommandStepChanged = void Function(int index);

class TaskBuilderAgentCommandExecutor {
  const TaskBuilderAgentCommandExecutor(
    this._cubit, {
    this.factory = const TaskBuilderAgentCommandFactory(),
  });

  final TaskBuilderCubit _cubit;
  final TaskBuilderAgentCommandFactory factory;

  Future<TaskBuilderAgentCommandHistory> execute(
    List<AssistantTaskCommand> dtos, {
    AgentCommandStepChanged? onStepChanged,
  }) async {
    final commands = factory.fromDtos(dtos);
    final executed = <ExecutedTaskBuilderAgentCommand>[];
    for (var index = 0; index < commands.length; index++) {
      onStepChanged?.call(index);
      await _execute(commands[index], executed);
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    return TaskBuilderAgentCommandHistory(executed);
  }

  Future<void> _execute(
    TaskBuilderAgentCommand command,
    List<ExecutedTaskBuilderAgentCommand> executed,
  ) async {
    final previousTask = await command.execute(_cubit);
    if (previousTask == null) return;
    executed.add(
      ExecutedTaskBuilderAgentCommand(
        command: command,
        previousTask: previousTask,
      ),
    );
  }
}
