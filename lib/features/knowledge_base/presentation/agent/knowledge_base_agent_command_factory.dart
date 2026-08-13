import 'package:syscat2/features/assistant/domain/entities/assistant_action_suggestion.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/create_knowledge_note_agent_command.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/delete_knowledge_note_agent_command.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/knowledge_base_agent_command.dart';
import 'package:syscat2/features/knowledge_base/presentation/agent/update_knowledge_note_agent_command.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

class KnowledgeBaseAgentCommandFactory {
  const KnowledgeBaseAgentCommandFactory();

  List<AssistantPlanAction> fromSuggestions(
    List<AssistantActionSuggestion> suggestions,
    KnowledgeBaseCubit cubit,
  ) {
    return suggestions
        .where(
          (suggestion) =>
              suggestion.target == AssistantActionTarget.knowledgeBase,
        )
        .map(_fromSuggestion)
        .nonNulls
        .map(
          (command) => KnowledgeBasePlanAction(cubit: cubit, command: command),
        )
        .toList(growable: false);
  }

  KnowledgeBaseAgentCommand? _fromSuggestion(
    AssistantActionSuggestion suggestion,
  ) {
    return switch (suggestion.type) {
      'createKnowledgeNote' => _createNote(suggestion),
      'updateKnowledgeNote' => _updateNote(suggestion),
      'deleteKnowledgeNote' => _deleteNote(suggestion),
      _ => null,
    };
  }

  KnowledgeBaseAgentCommand? _createNote(AssistantActionSuggestion suggestion) {
    final title = _requiredText(suggestion.stringArgument('title'));
    final content = suggestion.stringArgument('content');
    if (title == null || content == null) return null;
    return CreateKnowledgeNoteAgentCommand(
      label: suggestion.label,
      title: title,
      content: content,
    );
  }

  KnowledgeBaseAgentCommand? _updateNote(AssistantActionSuggestion suggestion) {
    final noteId = _requiredText(suggestion.stringArgument('noteId'));
    final title = _requiredText(suggestion.stringArgument('title'));
    final content = suggestion.stringArgument('content');
    if (noteId == null || title == null || content == null) return null;
    return UpdateKnowledgeNoteAgentCommand(
      label: suggestion.label,
      noteId: noteId,
      title: title,
      content: content,
    );
  }

  KnowledgeBaseAgentCommand? _deleteNote(AssistantActionSuggestion suggestion) {
    final noteId = _requiredText(suggestion.stringArgument('noteId'));
    if (noteId == null) return null;
    return DeleteKnowledgeNoteAgentCommand(
      label: suggestion.label,
      noteId: noteId,
    );
  }
}

String? _requiredText(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
