import '../../domain/entities/file_failure.dart';
import '../../domain/entities/team_file.dart';

enum FileAction {
  rename,
  move,
  copy,
  delete,
  download,
  restore,
  uploadVersion,
  saveText,
  saveImage,
}

sealed class FileActionsState {
  const FileActionsState();

  bool isRunning(FileAction action) =>
      this is FileActionRunning && (this as FileActionRunning).action == action;
}

final class FileActionsIdle extends FileActionsState {
  const FileActionsIdle();
}

final class FileActionRunning extends FileActionsState {
  const FileActionRunning(this.action);

  final FileAction action;
}

final class FileActionSucceeded extends FileActionsState {
  const FileActionSucceeded(this.action, {this.createdFile});

  final FileAction action;

  /// Die neue Datei nach einer Kopie, damit die Seite sie öffnen kann.
  final TeamFile? createdFile;
}

final class FileActionFailed extends FileActionsState {
  const FileActionFailed(this.action, this.kind);

  final FileAction action;
  final FileFailureKind kind;
}
