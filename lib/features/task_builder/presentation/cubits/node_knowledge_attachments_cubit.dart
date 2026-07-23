import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/knowledge_attachment.dart';
import 'node_knowledge_attachments_state.dart';

class NodeKnowledgeAttachmentsCubit
    extends Cubit<NodeKnowledgeAttachmentsState> {
  NodeKnowledgeAttachmentsCubit(
    this._authRepository,
    this._watchKnowledgeNotes,
    this._getCurrentTeamId,
  ) : super(const NodeKnowledgeAttachmentsState());

  final AuthRepository _authRepository;
  final WatchKnowledgeNotes _watchKnowledgeNotes;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<KnowledgeNote>>? _subscription;

  Future<void> load() async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure('Du musst angemeldet sein.');
    emit(const NodeKnowledgeAttachmentsState());
    _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchKnowledgeNotes(teamId).listen(
      _emitNotes,
      onError: (_) => _emitFailure('Notizen konnten nicht geladen werden.'),
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (_) {
      _emitFailure('Team konnte nicht geladen werden.');
      return null;
    }
  }

  void _emitNotes(List<KnowledgeNote> notes) {
    if (isClosed) return;
    emit(
      NodeKnowledgeAttachmentsState(
        status: NodeKnowledgeAttachmentsStatus.ready,
        notes: notes.map(_toAttachment).toList(growable: false),
      ),
    );
  }

  KnowledgeAttachment _toAttachment(KnowledgeNote note) {
    return KnowledgeAttachment(
      knowledgeBaseId: note.knowledgeBaseId,
      noteId: note.id,
      title: note.title,
      path: note.path,
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      NodeKnowledgeAttachmentsState(
        status: NodeKnowledgeAttachmentsStatus.failure,
        message: message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
