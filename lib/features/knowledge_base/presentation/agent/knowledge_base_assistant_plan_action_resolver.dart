import 'package:syscat2/features/assistant/domain/entities/assistant_knowledge_command.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_message.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action_resolver.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

class KnowledgeBaseAssistantPlanActionResolver
    implements AssistantPlanActionResolver {
  const KnowledgeBaseAssistantPlanActionResolver(this._cubit);

  final KnowledgeBaseCubit _cubit;

  @override
  List<AssistantPlanAction> actionsFor(AssistantMessage message) {
    return message.knowledgeCommands
        .map((command) => _actionFor(command))
        .whereType<AssistantPlanAction>()
        .toList(growable: false);
  }

  AssistantPlanAction? _actionFor(AssistantKnowledgeCommand command) {
    return switch (command.type) {
      'createKnowledgeNote' || 'updateKnowledgeNote' || 'deleteKnowledgeNote' =>
        KnowledgeBasePlanAction(cubit: _cubit, command: command),
      _ => null,
    };
  }
}

class KnowledgeBasePlanAction implements AssistantPlanAction {
  const KnowledgeBasePlanAction({required this.cubit, required this.command});

  final KnowledgeBaseCubit cubit;
  final AssistantKnowledgeCommand command;

  @override
  String get label => command.label;

  @override
  Future<AssistantPlanUndo?> execute() {
    return switch (command.type) {
      'createKnowledgeNote' => _createNote(),
      'updateKnowledgeNote' => _updateNote(),
      'deleteKnowledgeNote' => _deleteNote(),
      _ => throw StateError(
        'Der Vorschlag enthält keine bekannte Notizaktion.',
      ),
    };
  }

  Future<AssistantPlanUndo> _createNote() async {
    final note = await cubit.createSuggestedNote(
      title: _required(command.title, 'Name'),
      content: command.content ?? '',
    );
    return _DeleteKnowledgeNoteUndo(cubit, note.id);
  }

  Future<AssistantPlanUndo> _updateNote() async {
    final existing = _existingNote();
    await cubit.updateSuggestedNote(
      noteId: existing.id,
      title: _required(command.title, 'Name'),
      content: command.content ?? '',
    );
    return _RestoreKnowledgeNoteUndo(cubit, existing);
  }

  Future<AssistantPlanUndo> _deleteNote() async {
    final existing = _existingNote();
    await cubit.deleteSuggestedNote(existing.id);
    return _RestoreKnowledgeNoteUndo(cubit, existing);
  }

  KnowledgeNote _existingNote() {
    final noteId = _required(command.noteId, 'Notiz-ID');
    final note = cubit.noteWithId(noteId);
    if (note == null) {
      throw StateError('Die vorgeschlagene Notiz wurde nicht gefunden.');
    }
    return note;
  }
}

class _DeleteKnowledgeNoteUndo implements AssistantPlanUndo {
  const _DeleteKnowledgeNoteUndo(this._cubit, this._noteId);

  final KnowledgeBaseCubit _cubit;
  final String _noteId;

  @override
  Future<void> undo() => _cubit.deleteSuggestedNote(_noteId);
}

class _RestoreKnowledgeNoteUndo implements AssistantPlanUndo {
  const _RestoreKnowledgeNoteUndo(this._cubit, this._note);

  final KnowledgeBaseCubit _cubit;
  final KnowledgeNote _note;

  @override
  Future<void> undo() => _cubit.restoreSuggestedNote(_note);
}

String _required(String? value, String label) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) throw StateError('$label fehlt im Vorschlag.');
  return text;
}
