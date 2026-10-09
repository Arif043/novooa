import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/file_failure.dart';
import 'package:syscat2/features/files/domain/entities/team_folder.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/usecases/create_team_folder.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_folders.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'write_file_folders_state.dart';

/// Liefert die Verzeichnisse für die Zielwahl des Bausteins „Datei schreiben"
/// und legt neue an, ohne dafür die Dateiverwaltung zu öffnen.
class WriteFileFoldersCubit extends Cubit<WriteFileFoldersState> {
  WriteFileFoldersCubit(
    this._authRepository,
    this._watchTeamFolders,
    this._createTeamFolder,
    this._getCurrentTeamId,
  ) : super(const WriteFileFoldersState());

  final AuthRepository _authRepository;
  final WatchTeamFolders _watchTeamFolders;
  final CreateTeamFolder _createTeamFolder;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<TeamFolder>>? _subscription;

  Future<void> load() async {
    if (_authRepository.currentUser() == null) {
      return _emitFailure('Du musst angemeldet sein.');
    }
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    await _subscription?.cancel();
    _subscription = _watchTeamFolders(teamId).listen(
      _emitFolders,
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          LocaleKeys.ui_folders_load_failed.tr(),
          error,
          stackTrace,
        );
      },
    );
  }

  /// Gibt die ID des neuen Verzeichnisses zurück, `null` bei einem Fehler
  /// (die Meldung steht dann im State).
  Future<String?> createFolder({
    required String name,
    required String? parentFolderId,
  }) async {
    final user = _authRepository.currentUser();
    if (user == null) return _failedCreation('Du musst angemeldet sein.');
    final teamId = await _teamIdOrNull();
    if (teamId == null) return null;
    emit(state.copyWith(isCreating: true));
    final folderOrFailure = await _createTeamFolder(
      teamId: teamId,
      ownerUid: user.id.value,
      name: name.trim(),
      parentFolderId: parentFolderId,
    );
    if (isClosed) return null;
    return folderOrFailure.when(_created, _failedCreationWith);
  }

  String _created(TeamFolder folder) {
    emit(state.copyWith(isCreating: false));
    return folder.id;
  }

  String? _failedCreationWith(FileFailure failure) {
    return _failedCreation(failure.message);
  }

  String? _failedCreation(String message) {
    emit(state.copyWith(isCreating: false, message: message));
    return null;
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

  void _emitFolders(List<TeamFolder> folders) {
    if (isClosed) return;
    emit(
      state.copyWith(status: WriteFileFoldersStatus.ready, folders: folders),
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(status: WriteFileFoldersStatus.failure, message: message),
    );
  }

  void _logAndEmitFailure(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'write_file_folders',
    );
    _emitFailure(message);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
