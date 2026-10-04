enum DocumentScanFailureKind {
  permissionDenied,
  cameraUnavailable,
  engineUnavailable,
  captureFailed,
  unsupported,
}

class DocumentScanFailure {
  const DocumentScanFailure(this.kind);

  final DocumentScanFailureKind kind;

  /// Ob ein erneuter Versuch sinnvoll sein kann (etwa nach erteilter Berechtigung).
  bool get isRetryable => kind != DocumentScanFailureKind.unsupported;

  String get message {
    return switch (kind) {
      DocumentScanFailureKind.permissionDenied =>
        'Der Kamerazugriff wurde verweigert. Erlaube ihn in den '
            'Browser-Einstellungen und versuche es erneut.',
      DocumentScanFailureKind.cameraUnavailable =>
        'Es wurde keine Kamera gefunden oder sie ist nicht erreichbar. Der '
            'Scanner braucht eine sichere Verbindung (https).',
      DocumentScanFailureKind.engineUnavailable =>
        'Die Dokumenterkennung konnte nicht geladen werden.',
      DocumentScanFailureKind.captureFailed =>
        'Die Aufnahme ist fehlgeschlagen. Bitte versuche es erneut.',
      DocumentScanFailureKind.unsupported =>
        'Der Dokumentenscanner steht auf diesem Gerät nicht zur Verfügung.',
    };
  }
}
