import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/knowledge_base_agent_command.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/knowledge_base_agent_undo.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

final class UpdateKnowledgeNoteAgentCommand extends KnowledgeBaseAgentCommand {
  const UpdateKnowledgeNoteAgentCommand({
    required String label,
    required this.noteId,
    required this.title,
    required this.content,
  }) : super(label);

  final String noteId;
  final String title;
  final String content;

  @override
  Future<AssistantPlanUndo> perform(KnowledgeBaseCubit cubit) async {
    final existing = _existingNote(cubit);
    await cubit.updateSuggestedNote(
      noteId: existing.id,
      title: title,
      content: content,
    );
    return RestoreKnowledgeNotePlanUndo(cubit, existing);
  }

  KnowledgeNote _existingNote(KnowledgeBaseCubit cubit) {
    final note = cubit.noteWithId(noteId);
    if (note == null) {
      throw StateError('Die vorgeschlagene Notiz wurde nicht gefunden.');
    }
    return note;
  }
}
