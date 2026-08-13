import 'package:syscat2/features/assistant/domain/entities/assistant_message.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action_resolver.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command_factory.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class TaskBuilderAssistantPlanActionResolver
    implements AssistantPlanActionResolver {
  const TaskBuilderAssistantPlanActionResolver(
    this._cubit, {
    this.factory = const TaskBuilderAgentCommandFactory(),
  });

  final TaskBuilderCubit _cubit;
  final TaskBuilderAgentCommandFactory factory;

  @override
  List<AssistantPlanAction> actionsFor(AssistantMessage message) {
    return factory.fromDtos(message.taskCommands, _cubit);
  }
}
