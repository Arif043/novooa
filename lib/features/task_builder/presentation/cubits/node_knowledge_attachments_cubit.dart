import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
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
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          LocaleKeys.ui_notes_load_failed.tr(),
          error,
          stackTrace,
        );
      },
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      _logAndEmitFailure(
        LocaleKeys.ui_team_load_failed.tr(),
        error,
        stackTrace,
      );
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

  void _logAndEmitFailure(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'node_knowledge_attachments',
    );
    _emitFailure(message);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
