/// Ein Fehler im Umgang mit Mitarbeitern, mit einer Meldung für den Nutzer
/// (vom Server bereits auf Deutsch formuliert).
class EmployeeFailure {
  const EmployeeFailure(this.message);

  static const loadFailed = EmployeeFailure(
    'Mitarbeiter konnten nicht geladen werden.',
  );
  static const saveFailed = EmployeeFailure(
    'Mitarbeiter konnte nicht gespeichert werden.',
  );
  static const deleteFailed = EmployeeFailure(
    'Mitarbeiter konnte nicht gelöscht werden.',
  );

  final String message;
}
