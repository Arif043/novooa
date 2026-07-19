enum EmployeeFailureKind {
  unauthenticated,
  loadFailed,
  saveFailed,
  deleteFailed,
  invalidName,
}

class EmployeeFailure {
  const EmployeeFailure(this.kind);

  final EmployeeFailureKind kind;

  String get message {
    return switch (kind) {
      EmployeeFailureKind.unauthenticated =>
        'Du musst angemeldet sein, um Mitarbeiter zu verwalten.',
      EmployeeFailureKind.loadFailed =>
        'Mitarbeiter konnten nicht geladen werden.',
      EmployeeFailureKind.saveFailed =>
        'Mitarbeiter konnte nicht gespeichert werden.',
      EmployeeFailureKind.deleteFailed =>
        'Mitarbeiter konnte nicht gelöscht werden.',
      EmployeeFailureKind.invalidName => 'Gib einen Namen für den Mitarbeiter ein.',
    };
  }
}
