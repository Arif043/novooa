import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_file.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_files.dart';

import '../../domain/entities/node_attachment.dart';
import 'node_file_attachments_state.dart';

class NodeFileAttachmentsCubit extends Cubit<NodeFileAttachmentsState> {
  NodeFileAttachmentsCubit(this._authRepository, this._watchTeamFiles)
    : super(const NodeFileAttachmentsState());

  final AuthRepository _authRepository;
  final WatchTeamFiles _watchTeamFiles;
  StreamSubscription<List<TeamFile>>? _subscription;

  void load() {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure('Du musst angemeldet sein.');
    emit(const NodeFileAttachmentsState());
    _subscription?.cancel();
    _subscription = _watchTeamFiles(TeamId.personal(user.id.value)).listen(
      _emitFiles,
      onError: (_) => _emitFailure('Dateien konnten nicht geladen werden.'),
    );
  }

  void _emitFiles(List<TeamFile> files) {
    if (isClosed) return;
    emit(
      NodeFileAttachmentsState(
        status: NodeFileAttachmentsStatus.ready,
        files: files.map(_toAttachment).toList(growable: false),
      ),
    );
  }

  NodeAttachment _toAttachment(TeamFile file) {
    return NodeAttachment(
      id: '${file.id}:${file.currentVersionId}',
      storagePath: file.storagePath,
      generation: file.currentVersionId,
      displayName: file.displayName,
      contentType: file.contentType,
      sizeBytes: file.sizeBytes,
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      NodeFileAttachmentsState(
        status: NodeFileAttachmentsStatus.failure,
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
