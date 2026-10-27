import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/knowledge_failure.dart';
import '../../domain/entities/knowledge_note.dart';
import '../../domain/entities/knowledge_note_draft.dart';
import '../../domain/services/markdown_link_extractor.dart';
import '../../domain/services/knowledge_note_draft_factory.dart';
import '../../domain/usecases/create_knowledge_note.dart';
import '../../domain/usecases/delete_knowledge_note.dart';
import '../../domain/usecases/restore_knowledge_note.dart';
import '../../domain/usecases/update_knowledge_note.dart';
import '../../domain/usecases/watch_knowledge_notes.dart';
import 'knowledge_base_state.dart';

part 'knowledge_base_assistant_mutations.dart';

class KnowledgeBaseCubit extends Cubit<KnowledgeBaseState> {
  KnowledgeBaseCubit(
    this._authRepository,
    this._watchKnowledgeNotes,
    this._createKnowledgeNote,
    this._updateKnowledgeNote,
    this._deleteKnowledgeNote,
    this._restoreKnowledgeNote,
    this._getCurrentTeamId, [
    this._linkExtractor = const MarkdownLinkExtractor(),
    this._draftFactory = const KnowledgeNoteDraftFactory(),
  ]) : super(const KnowledgeBaseState());

  final AuthRepository _authRepository;
  final WatchKnowledgeNotes _watchKnowledgeNotes;
  final CreateKnowledgeNote _createKnowledgeNote;
  final UpdateKnowledgeNote _updateKnowledgeNote;
  final DeleteKnowledgeNote _deleteKnowledgeNote;
  final RestoreKnowledgeNote _restoreKnowledgeNote;
  final GetCurrentTeamId _getCurrentTeamId;
  final MarkdownLinkExtractor _linkExtractor;
  final KnowledgeNoteDraftFactory _draftFactory;
  StreamSubscription<List<KnowledgeNote>>? _subscription;
  Timer? _saveDebounce;

  Future<void> load() async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      return _emitFailure(KnowledgeFailureKind.unauthenticated);
    }
    emit(const KnowledgeBaseState());
    _subscription?.cancel();
    _subscription = _watchKnowledgeNotes(teamId).listen(
      _emitNotes,
      onError: (_) => _emitFailure(KnowledgeFailureKind.loadFailed),
    );
  }

  Future<void> createNote() async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure(KnowledgeFailureKind.unauthenticated);
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    final title = _draftFactory.newTitle(state.notes.length);
    final noteOrFailure = await _createKnowledgeNote(
      teamId: teamId,
      ownerUid: user.id.value,
      draft: _draftFactory.create(title: title, content: '# $title\n'),
    );
    noteOrFailure.when(
      (note) => emit(state.copyWith(selectedNoteId: note.id, message: null)),
      (failure) => _emitFailure(failure.kind),
    );
  }

  void selectNote(String noteId) {
    emit(state.copyWith(selectedNoteId: noteId, message: null));
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query, message: null));
  }

  void updateTitle(String value) {
    final note = state.selectedNote;
    if (note == null) return;
    _updateSelected(
      note.copyWith(title: value, path: _draftFactory.pathFor(value)),
    );
  }

  void updateContent(String value) {
    final note = state.selectedNote;
    if (note == null) return;
    final links = _linkExtractor(content: value, notes: state.notes);
    _updateSelected(note.copyWith(content: value, outgoingLinks: links));
  }

  Future<void> deleteSelected() async {
    final note = state.selectedNote;
    final teamId = await _teamIdOrNull();
    if (note == null || teamId == null) return;
    final noteOrFailure = await _deleteKnowledgeNote(
      teamId: teamId,
      noteId: note.id,
    );
    noteOrFailure.when(
      (_) => emit(state.copyWith(clearSelectedNote: true, message: null)),
      (failure) => _emitFailure(failure.kind),
    );
  }

  void _emitNotes(List<KnowledgeNote> notes) {
    if (isClosed) return;
    final selectedId = _selectedIdFor(notes);
    emit(
      state.copyWith(
        status: KnowledgeBaseStatus.ready,
        notes: notes,
        selectedNoteId: selectedId,
        message: null,
      ),
    );
  }

  void _updateSelected(KnowledgeNote note) {
    final notes = state.notes.map((item) => item.id == note.id ? note : item);
    emit(state.copyWith(notes: notes.toList(), isSaving: true, message: null));
    _scheduleSave(note);
  }

  /// Wartezeit nach der letzten Eingabe, bevor automatisch gespeichert wird.
  static const saveDelay = Duration(seconds: 2);

  void _scheduleSave(KnowledgeNote note) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(saveDelay, () {
      unawaited(_save(note));
    });
  }

  Future<void> _save(KnowledgeNote note) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      return _emitFailure(KnowledgeFailureKind.unauthenticated);
    }
    final noteOrFailure = await _updateKnowledgeNote(
      teamId: teamId,
      noteId: note.id,
      draft: _draftFactory.fromNote(note),
    );
    if (isClosed) return;
    noteOrFailure.when(
      // Kein Hinweis bei Erfolg: Das Statuslabel neben den Ansichtsknöpfen zeigt es an.
      (_) => emit(
        state.copyWith(status: KnowledgeBaseStatus.ready, isSaving: false),
      ),
      (failure) => _emitFailure(failure.kind),
    );
  }

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

  void _emitFailure(KnowledgeFailureKind kind) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: KnowledgeBaseStatus.failure,
        isSaving: false,
        message: KnowledgeFailure(kind).message,
      ),
    );
  }

  @override
  Future<void> close() {
    _saveDebounce?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
