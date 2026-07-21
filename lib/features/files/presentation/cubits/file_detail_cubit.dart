import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/upload_file_input.dart';
import '../../domain/usecases/create_file_version.dart';
import '../../domain/usecases/download_file_version.dart';
import '../../domain/usecases/watch_file_versions.dart';
import 'file_detail_state.dart';

class FileDetailCubit extends Cubit<FileDetailState> {
  FileDetailCubit(
    this._authRepository,
    this._watchFileVersions,
    this._downloadFileVersion,
    this._createFileVersion,
  ) : super(const FileDetailState());

  final AuthRepository _authRepository;
  final WatchFileVersions _watchFileVersions;
  final DownloadFileVersion _downloadFileVersion;
  final CreateFileVersion _createFileVersion;
  StreamSubscription<List<FileVersion>>? _versionsSubscription;
  TeamFile? _file;

  void load(TeamFile file) {
    _file = file;
    _versionsSubscription?.cancel();
    _versionsSubscription = _watchFileVersions(file.teamId, file.id).listen(
      _onVersions,
      onError: (_) => _emitFailure(FileFailureKind.loadFailed),
    );
  }

  Future<void> selectVersion(FileVersion version) async {
    emit(
      state.copyWith(
        selectedVersion: version,
        clearContent: true,
        message: null,
      ),
    );
    final bytesOrFailure = await _downloadFileVersion(version);
    if (isClosed) return;
    bytesOrFailure.when(
      (bytes) => emit(
        state.copyWith(status: FileDetailStatus.ready, content: _decode(bytes)),
      ),
      (failure) => _emitFailure(failure.kind),
    );
  }

  Future<void> save(String content) async {
    final file = _file;
    final user = _authRepository.currentUser();
    if (file == null || user == null) {
      return _emitFailure(FileFailureKind.unauthenticated);
    }
    final input = _inputFor(file, content);
    emit(state.copyWith(isSaving: true, message: null));
    final fileOrFailure = await _createFileVersion(
      file: file,
      ownerUid: user.id.value,
      input: input,
    );
    if (isClosed) return;
    fileOrFailure.when(
      (updatedFile) {
        _file = updatedFile;
        emit(
          state.copyWith(
            isSaving: false,
            clearSelectedVersion: true,
            clearContent: true,
            message: 'Neue Version gespeichert.',
          ),
        );
      },
      (failure) =>
          emit(state.copyWith(isSaving: false, message: failure.message)),
    );
  }

  void _onVersions(List<FileVersion> versions) {
    if (versions.isEmpty || isClosed) {
      return;
    }
    final selected = state.selectedVersion;
    emit(state.copyWith(status: FileDetailStatus.ready, versions: versions));
    if (selected == null) {
      unawaited(selectVersion(versions.first));
    }
  }

  UploadFileInput _inputFor(TeamFile file, String content) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return UploadFileInput(
      name: file.displayName,
      bytes: bytes,
      sizeBytes: bytes.length,
      contentType: file.contentType,
    );
  }

  String _decode(Uint8List bytes) => utf8.decode(bytes, allowMalformed: true);

  void _emitFailure(FileFailureKind kind) {
    if (!isClosed) {
      emit(
        state.copyWith(
          status: FileDetailStatus.failure,
          message: FileFailure(kind).message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _versionsSubscription?.cancel();
    return super.close();
  }
}
