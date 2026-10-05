/// Ein Fehler im Umgang mit Verbindungen, mit einer Meldung für Nutzer:innen
/// (vom Server bereits auf Deutsch formuliert).
class ConnectionFailure {
  const ConnectionFailure(this.message);

  static const loadFailed = ConnectionFailure(
    'Verbindungen konnten nicht geladen werden.',
  );
  static const saveFailed = ConnectionFailure(
    'Die Verbindung konnte nicht gespeichert werden.',
  );
  static const deleteFailed = ConnectionFailure(
    'Die Verbindung konnte nicht gelöscht werden.',
  );
  static const testFailed = ConnectionFailure(
    'Die Verbindung konnte nicht getestet werden.',
  );

  final String message;
}
