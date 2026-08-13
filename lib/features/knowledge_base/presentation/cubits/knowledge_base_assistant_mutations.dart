part of 'knowledge_base_cubit.dart';

extension KnowledgeBaseAssistantMutations on KnowledgeBaseCubit {
  Future<KnowledgeNote> createSuggestedNote({
    required String title,
    required String content,
  }) async {
    final teamId = await _requiredTeamId();
    final user = _authRepository.currentUser();
    if (user == null) throw StateError(_unauthenticatedMessage);
    _cancelPendingSave();
    final noteOrFailure = await _createKnowledgeNote(
      teamId: teamId,
      ownerUid: user.id.value,
      draft: _draftFor(title: title, content: content),
    );
    return noteOrFailure.when(_selectNote, _throwFailure);
  }

  Future<KnowledgeNote> updateSuggestedNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    final teamId = await _requiredTeamId();
    _cancelPendingSave();
    final noteOrFailure = await _updateKnowledgeNote(
      teamId: teamId,
      noteId: noteId,
      draft: _draftFor(title: title, content: content),
    );
    return noteOrFailure.when(_selectNote, _throwFailure);
  }

  Future<void> deleteSuggestedNote(String noteId) async {
    final teamId = await _requiredTeamId();
    _cancelPendingSave();
    final noteOrFailure = await _deleteKnowledgeNote(
      teamId: teamId,
      noteId: noteId,
    );
    noteOrFailure.when((_) => _removeNote(noteId), _throwFailure);
  }

  Future<void> restoreSuggestedNote(KnowledgeNote note) async {
    final teamId = await _requiredTeamId();
    final noteOrFailure = await _restoreKnowledgeNote(
      teamId: teamId,
      note: note,
    );
    noteOrFailure.when(_selectNote, _throwFailure);
  }

  KnowledgeNote? noteWithId(String noteId) {
    for (final note in state.notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  Future<TeamId> _requiredTeamId() async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) throw StateError(_unauthenticatedMessage);
    return teamId;
  }

  KnowledgeNoteDraft _draftFor({
    required String title,
    required String content,
  }) {
    return _draftFactory.create(
      title: title,
      content: content,
      outgoingLinks: _linkExtractor(content: content, notes: state.notes),
    );
  }

  KnowledgeNote _selectNote(KnowledgeNote note) {
    _upsertNote(note);
    return note;
  }

  Never _throwFailure(KnowledgeFailure failure) {
    throw StateError(failure.message);
  }

  void _cancelPendingSave() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
  }

  void _upsertNote(KnowledgeNote note) {
    final withoutNote = state.notes.where((item) => item.id != note.id);
    final notes = [...withoutNote, note]
      ..sort((left, right) => left.title.compareTo(right.title));
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(
      state.copyWith(notes: notes, selectedNoteId: note.id, isSaving: false),
    );
  }

  void _removeNote(String noteId) {
    final notes = state.notes.where((note) => note.id != noteId).toList();
    if (notes.isEmpty) {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      emit(
        state.copyWith(notes: notes, clearSelectedNote: true, isSaving: false),
      );
      return;
    }
    final selectedId = state.selectedNoteId == noteId
        ? notes.first.id
        : state.selectedNoteId;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(
      state.copyWith(notes: notes, selectedNoteId: selectedId, isSaving: false),
    );
  }
}

final _unauthenticatedMessage = KnowledgeFailure(
  KnowledgeFailureKind.unauthenticated,
).message;
