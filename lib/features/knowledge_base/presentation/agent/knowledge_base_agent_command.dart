import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

abstract class KnowledgeBaseAgentCommand {
  const KnowledgeBaseAgentCommand(this.label);

  final String label;

  Future<AssistantPlanUndo?> perform(KnowledgeBaseCubit cubit);
}

class KnowledgeBasePlanAction implements AssistantPlanAction {
  const KnowledgeBasePlanAction({required this.cubit, required this.command});

  final KnowledgeBaseCubit cubit;
  final KnowledgeBaseAgentCommand command;

  @override
  String get label => command.label;

  @override
  Future<AssistantPlanUndo?> execute() => command.perform(cubit);
}
