import 'package:syscat2/features/assistant/domain/entities/assistant_message.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action_resolver.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/knowledge_base_agent_command_factory.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

class KnowledgeBaseAssistantPlanActionResolver
    implements AssistantPlanActionResolver {
  const KnowledgeBaseAssistantPlanActionResolver(
    this._cubit, {
    this.factory = const KnowledgeBaseAgentCommandFactory(),
  });

  final KnowledgeBaseCubit _cubit;
  final KnowledgeBaseAgentCommandFactory factory;

  @override
  List<AssistantPlanAction> actionsFor(AssistantMessage message) {
    return factory.fromSuggestions(message.actionSuggestions, _cubit);
  }
}
