import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/usecases/upload_team_file.dart';
import '../../domain/usecases/watch_team_files.dart';
import 'files_state.dart';

class FilesCubit extends Cubit<FilesState> {
  FilesCubit(this._authRepository, this._watchTeamFiles, this._uploadTeamFile)
    : super(const FilesState());

  final AuthRepository _authRepository;
  final WatchTeamFiles _watchTeamFiles;
  final UploadTeamFile _uploadTeamFile;
  StreamSubscription<List<TeamFile>>? _subscription;

  void load() {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure(FileFailureKind.unauthenticated);
    emit(const FilesState());
    _subscription?.cancel();
    _subscription = _watchTeamFiles(TeamId.personal(user.id.value)).listen(
      _emitFiles,
      onError: (_) => _emitFailure(FileFailureKind.loadFailed),
    );
  }

  Future<void> upload(UploadFileInput input) async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure(FileFailureKind.unauthenticated);
    emit(state.copyWith(isUploading: true, message: null));
    final fileOrFailure = await _uploadTeamFile(
      teamId: TeamId.personal(user.id.value),
      ownerUid: user.id.value,
      input: input,
    );
    if (isClosed) return;
    fileOrFailure.when(
      (_) => emit(
        state.copyWith(isUploading: false, message: 'Datei hochgeladen.'),
      ),
      (failure) =>
          emit(state.copyWith(isUploading: false, message: failure.message)),
    );
  }

  void _emitFiles(List<TeamFile> files) {
    if (isClosed) return;
    emit(state.copyWith(status: FilesLoadStatus.ready, files: files));
  }

  void _emitFailure(FileFailureKind kind) {
    if (isClosed) return;
    emit(
      FilesState(
        status: FilesLoadStatus.failure,
        message: FileFailure(kind).message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
