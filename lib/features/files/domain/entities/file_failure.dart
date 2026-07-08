enum FileFailureKind {
  unauthenticated,
  noFileSelected,
  loadFailed,
  uploadFailed,
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
    };
  }
}
