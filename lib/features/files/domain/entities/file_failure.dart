enum FileFailureKind {
  unauthenticated,
  noFileSelected,
  loadFailed,
  uploadFailed,
  downloadFailed,
  createFolderFailed,
  invalidFolderName,
}

class FileFailure {
  const FileFailure(this.kind);

  final FileFailureKind kind;

  String get message {
    return switch (kind) {
      FileFailureKind.unauthenticated =>
        'Du musst angemeldet sein, um Dateien zu nutzen.',
      FileFailureKind.noFileSelected => 'Es wurde keine Datei ausgewählt.',
      FileFailureKind.loadFailed => 'Dateien konnten nicht geladen werden.',
      FileFailureKind.uploadFailed => 'Datei konnte nicht hochgeladen werden.',
      FileFailureKind.downloadFailed =>
        'Dateiinhalt konnte nicht geladen werden.',
      FileFailureKind.createFolderFailed =>
        'Verzeichnis konnte nicht erstellt werden.',
      FileFailureKind.invalidFolderName =>
        'Gib einen Namen für das Verzeichnis ein.',
    };
  }
}
