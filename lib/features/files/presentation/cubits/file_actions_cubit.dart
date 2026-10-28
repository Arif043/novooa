import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/file_failure.dart';
import '../../domain/entities/file_name.dart';
import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/upload_file_input.dart';
import 'file_actions_dependencies.dart';
import 'file_actions_state.dart';

/// Alle ändernden Aktionen der Detailseite. Ergebnisse meldet der Zustand
/// einmalig (Snackbar); die Seite selbst folgt den Datei-Streams.
class FileActionsCubit extends Cubit<FileActionsState> {
  FileActionsCubit(this._authRepository, this._actions)
    : super(const FileActionsIdle());

  final AuthRepository _authRepository;
  final FileActionsDependencies _actions;

  /// Liefert den Fehler zurück, damit der Dialog ihn am Feld zeigen kann.
  Future<FileFailureKind?> rename(TeamFile file, String input) {
    final name = FileName.tryParse(input);
    if (name == null) {
      return _fail(FileAction.rename, FileFailureKind.invalidFileName);
    }
    return _run(FileAction.rename, () => _actions.rename(file, name));
  }

  Future<FileFailureKind?> move(TeamFile file, String? folderId) =>
      _run(FileAction.move, () => _actions.move(file, folderId));

  /// [copySuffix] ist sprachabhängig (` (Kopie)`); die Runtime macht den
  /// Namen eindeutig.
  Future<FileFailureKind?> copy(TeamFile file, String copySuffix) {
    final name = FileName.tryParse(file.displayName);
    if (name == null) return _fail(FileAction.copy, FileFailureKind.copyFailed);
    return _run(
      FileAction.copy,
      () => _actions.copy(file, name.withBaseSuffix(copySuffix)),
      createdFile: (copied) => copied,
    );
  }

  Future<FileFailureKind?> delete(TeamFile file) => _run(
    FileAction.delete,
    () => _actions.delete(teamId: file.teamId, fileId: file.id),
  );

  Future<FileFailureKind?> download(TeamFile file, FileVersion version) =>
      _run(FileAction.download, () => _actions.saveToDevice(file, version));

  Future<FileFailureKind?> restore(FileVersion version) =>
      _run(FileAction.restore, () => _actions.restore(version));

  Future<FileFailureKind?> uploadVersion(
    TeamFile file,
    UploadFileInput input,
  ) => _newVersion(FileAction.uploadVersion, file, input);

  Future<FileFailureKind?> saveText(TeamFile file, String content) {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return _newVersion(FileAction.saveText, file, _inputFor(file, bytes));
  }

  Future<FileFailureKind?> saveImage(TeamFile file, Uint8List bytes) =>
      _newVersion(FileAction.saveImage, file, _inputFor(file, bytes));

  Future<FileFailureKind?> _newVersion(
    FileAction action,
    TeamFile file,
    UploadFileInput input,
  ) {
    final user = _authRepository.currentUser();
    if (user == null) return _fail(action, FileFailureKind.unauthenticated);
    return _run(
      action,
      () => _actions.createVersion(
        file: file,
        ownerUid: user.id.value,
        input: input,
      ),
    );
  }

  UploadFileInput _inputFor(TeamFile file, Uint8List bytes) {
    return UploadFileInput(
      name: file.displayName,
      bytes: bytes,
      sizeBytes: bytes.length,
      contentType: file.contentType,
    );
  }

  Future<FileFailureKind?> _run<T extends Object>(
    FileAction action,
    Future<Result<T, FileFailure>> Function() request, {
    TeamFile? Function(T value)? createdFile,
  }) async {
    emit(FileActionRunning(action));
    final valueOrFailure = await request();
    if (isClosed) return null;
    return valueOrFailure.when((value) {
      emit(FileActionSucceeded(action, createdFile: createdFile?.call(value)));
      return null;
    }, (failure) => _emitFailure(action, failure.kind));
  }

  Future<FileFailureKind?> _fail(FileAction action, FileFailureKind kind) =>
      Future.value(_emitFailure(action, kind));

  FileFailureKind _emitFailure(FileAction action, FileFailureKind kind) {
    if (!isClosed) emit(FileActionFailed(action, kind));
    return kind;
  }
}
