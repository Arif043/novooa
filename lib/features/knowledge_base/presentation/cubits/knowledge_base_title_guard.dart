part of 'knowledge_base_cubit.dart';

extension _KnowledgeBaseTitleGuard on KnowledgeBaseCubit {
  /// Ein vergebener Titel bleibt im Editor stehen, wird aber nicht gespeichert,
  /// bis er wieder eindeutig ist — so meldet die Runtime beim Tippen keinen Konflikt.
  KnowledgeBaseState _titleTakenState(KnowledgeNote note) {
    final notes = state.notes.map((item) => item.id == note.id ? note : item);
    return state.copyWith(
      notes: notes.toList(),
      status: KnowledgeBaseStatus.failure,
      isSaving: false,
      message: const KnowledgeFailure(
        KnowledgeFailureKind.duplicateTitle,
      ).message,
    );
  }
}
