enum FileFailureKind {
  unauthenticated,
  noFileSelected,
  loadFailed,
  uploadFailed,
  downloadFailed,
  createFolderFailed,
  deleteFailed,
  invalidFolderName,
  invalidFileName,

  /// Im Zielverzeichnis gibt es schon eine Datei mit diesem Namen.
  nameTaken,
  renameFailed,
  moveFailed,
  copyFailed,
  restoreFailed,
  saveFailed,

  /// Die Person hat die Auswahl abgebrochen; kein Fehler, den man meldet.
  cancelled,
}

/// Fehler der Dateiablage; den sichtbaren Text liefert die Presentation
/// (`fileFailureMessage`).
class FileFailure {
  const FileFailure(this.kind);

  final FileFailureKind kind;
}
