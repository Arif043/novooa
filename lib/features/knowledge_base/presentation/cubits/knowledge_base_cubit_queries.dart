part of 'knowledge_base_cubit.dart';

/// Lesende Hilfen des Cubits ohne eigene Zustandsänderung.
extension _KnowledgeBaseCubitQueries on KnowledgeBaseCubit {
  String? _selectedIdFor(List<KnowledgeNote> notes) {
    if (notes.any((note) => note.id == state.selectedNoteId)) {
      return state.selectedNoteId;
    }
    return notes.isEmpty ? null : notes.first.id;
  }

  Future<TeamId?> _teamIdOrNull() async {
    final user = _authRepository.currentUser();
    if (user == null) return null;
    try {
      return await _getCurrentTeamId();
    } catch (_) {
      return null;
    }
  }
}
