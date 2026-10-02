/// Ein Fehler im Umgang mit Fähigkeiten, mit einer Meldung für den Nutzer
/// (vom Server bereits auf Deutsch formuliert).
class SkillFailure {
  const SkillFailure(this.message);

  static const loadFailed = SkillFailure(
    'Fähigkeiten konnten nicht geladen werden.',
  );
  static const deleteFailed = SkillFailure(
    'Fähigkeit konnte nicht gelöscht werden.',
  );

  /// Der Nutzer hat die Auswahl abgebrochen — kein Fehler, nur kein Ergebnis.
  static const cancelled = SkillFailure('');
  static const importFailed = SkillFailure('Der Import ist fehlgeschlagen.');

  final String message;

  bool get isCancelled => message.isEmpty;
}
