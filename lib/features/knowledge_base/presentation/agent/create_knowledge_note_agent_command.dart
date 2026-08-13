import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/knowledge_base_agent_command.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/knowledge_base_agent_undo.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

final class CreateKnowledgeNoteAgentCommand extends KnowledgeBaseAgentCommand {
  const CreateKnowledgeNoteAgentCommand({
    required String label,
    required this.title,
    required this.content,
  }) : super(label);

  final String title;
  final String content;

  @override
  Future<AssistantPlanUndo> perform(KnowledgeBaseCubit cubit) async {
    final note = await cubit.createSuggestedNote(
      title: title,
      content: content,
    );
    return DeleteKnowledgeNotePlanUndo(cubit, note.id);
  }
}
