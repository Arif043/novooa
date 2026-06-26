enum SettingsFailureKind {
  unauthenticated,
  invalidApiKey,
  invalidDisplayName,
  loadFailed,
  saveFailed,
}

class SettingsFailure {
  const SettingsFailure(this.kind);

  final SettingsFailureKind kind;

  String get message {
    return switch (kind) {
      SettingsFailureKind.unauthenticated =>
        'Du musst angemeldet sein, um Einstellungen zu ändern.',
      SettingsFailureKind.invalidApiKey =>
        'Bitte gib einen gültigen API-Key ein.',
      SettingsFailureKind.invalidDisplayName =>
        'Bitte gib deinen Namen mit mindestens 2 Zeichen ein.',
      SettingsFailureKind.loadFailed =>
        'Einstellungen konnten nicht geladen werden.',
      SettingsFailureKind.saveFailed =>
        'Einstellungen konnten nicht gespeichert werden.',
    };
  }
}
