enum SkillFailureKind {
  unauthenticated,
  loadFailed,
  saveFailed,
  deleteFailed,
  invalidTitle,
}

class SkillFailure {
  const SkillFailure(this.kind);

  final SkillFailureKind kind;

  String get message {
    return switch (kind) {
      SkillFailureKind.unauthenticated =>
        'Du musst angemeldet sein, um Fähigkeiten zu verwalten.',
      SkillFailureKind.loadFailed => 'Fähigkeiten konnten nicht geladen werden.',
      SkillFailureKind.saveFailed =>
        'Fähigkeit konnte nicht gespeichert werden.',
      SkillFailureKind.deleteFailed =>
        'Fähigkeit konnte nicht gelöscht werden.',
      SkillFailureKind.invalidTitle => 'Gib einen Namen für die Fähigkeit ein.',
    };
  }
}
