import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_id.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/usecases/create_team_folder.dart';
import '../../domain/usecases/delete_team_file.dart';
import '../../domain/usecases/upload_team_file.dart';
import '../../domain/usecases/watch_team_files.dart';
import '../../domain/usecases/watch_team_folders.dart';
import '../../../teams/domain/usecases/get_current_team_id.dart';
import 'files_state.dart';

class FilesCubit extends Cubit<FilesState> {
  FilesCubit(
    this._authRepository,
    this._watchTeamFiles,
    this._watchTeamFolders,
    this._uploadTeamFile,
    this._createTeamFolder,
    this._deleteTeamFile,
    this._getCurrentTeamId,
  ) : super(const FilesState());

  final AuthRepository _authRepository;
  final WatchTeamFiles _watchTeamFiles;
  final WatchTeamFolders _watchTeamFolders;
  final UploadTeamFile _uploadTeamFile;
  final CreateTeamFolder _createTeamFolder;
  final DeleteTeamFile _deleteTeamFile;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<TeamFile>>? _filesSubscription;
  StreamSubscription<List<TeamFolder>>? _foldersSubscription;
  var _filesLoaded = false;
  var _foldersLoaded = false;

  Future<void> load() async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure(FileFailureKind.unauthenticated);
    emit(const FilesState());
    _resetSubscriptions();
    final teamId = await _teamIdOrFailure();
    if (teamId == null) return;
    _filesSubscription = _watchTeamFiles(teamId).listen(
      _emitFiles,
      onError: (_) => _emitFailure(FileFailureKind.loadFailed),
    );
    _foldersSubscription = _watchTeamFolders(teamId).listen(
      _emitFolders,
      onError: (_) => _emitFailure(FileFailureKind.loadFailed),
    );
  }

  Future<void> upload(UploadFileInput input) async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure(FileFailureKind.unauthenticated);
    emit(state.copyWith(isUploading: true, message: null));
    final teamId = await _teamIdOrFailure();
    if (teamId == null) return;
    final fileOrFailure = await _uploadTeamFile(
      teamId: teamId,
      ownerUid: user.id.value,
      input: input,
      folderId: state.currentFolderId,
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

  Future<void> createFolder(String name) async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure(FileFailureKind.unauthenticated);
    emit(state.copyWith(isCreatingFolder: true, message: null));
    final teamId = await _teamIdOrFailure();
    if (teamId == null) return;
    final folderOrFailure = await _createTeamFolder(
      teamId: teamId,
      ownerUid: user.id.value,
      name: name,
      parentFolderId: state.currentFolderId,
    );
    if (isClosed) return;
    folderOrFailure.when(
      (_) => emit(
        state.copyWith(
          isCreatingFolder: false,
          message: 'Verzeichnis erstellt.',
        ),
      ),
      (failure) => emit(
        state.copyWith(isCreatingFolder: false, message: failure.message),
      ),
    );
  }

  Future<void> deleteFile(String fileId) async {
    final teamId = await _teamIdOrFailure();
    if (teamId == null) return;
    final deletedOrFailure = await _deleteTeamFile(
      teamId: teamId,
      fileId: fileId,
    );
    if (isClosed) return;
    deletedOrFailure.when(
      (_) => emit(state.copyWith(message: 'Datei gelöscht.')),
      (failure) => emit(state.copyWith(message: failure.message)),
    );
  }

  void openFolder(String folderId) {
    emit(state.copyWith(currentFolderId: folderId, message: null));
  }

  void openRoot() {
    emit(state.copyWith(clearCurrentFolderId: true, message: null));
  }

  void _emitFiles(List<TeamFile> files) {
    if (isClosed) return;
    _filesLoaded = true;
    emit(state.copyWith(status: _status, files: files));
  }

  void _emitFolders(List<TeamFolder> folders) {
    if (isClosed) return;
    _foldersLoaded = true;
    emit(state.copyWith(status: _status, folders: folders));
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

  FilesLoadStatus get _status {
    return _filesLoaded && _foldersLoaded
        ? FilesLoadStatus.ready
        : FilesLoadStatus.loading;
  }

  void _resetSubscriptions() {
    _filesLoaded = false;
    _foldersLoaded = false;
    _filesSubscription?.cancel();
    _foldersSubscription?.cancel();
  }

  Future<TeamId?> _teamIdOrFailure() async {
    try {
      return await _getCurrentTeamId();
    } catch (_) {
      _emitFailure(FileFailureKind.loadFailed);
      return null;
    }
  }

  @override
  Future<void> close() {
    _filesSubscription?.cancel();
    _foldersSubscription?.cancel();
    return super.close();
  }
}
