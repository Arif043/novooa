import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_action.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';

class DeleteKnowledgeNotePlanUndo implements AssistantPlanUndo {
  const DeleteKnowledgeNotePlanUndo(this._cubit, this._noteId);

  final KnowledgeBaseCubit _cubit;
  final String _noteId;

  @override
  Future<void> undo() => _cubit.deleteSuggestedNote(_noteId);
}

class RestoreKnowledgeNotePlanUndo implements AssistantPlanUndo {
  const RestoreKnowledgeNotePlanUndo(this._cubit, this._note);

  final KnowledgeBaseCubit _cubit;
  final KnowledgeNote _note;

  @override
  Future<void> undo() => _cubit.restoreSuggestedNote(_note);
}
