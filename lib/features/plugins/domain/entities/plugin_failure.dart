/// Ein Fehler im Umgang mit Plugins, mit einer Meldung für den Nutzer
/// (vom Server bereits auf Deutsch formuliert).
class PluginFailure {
  const PluginFailure(this.message);

  static const loadFailed = PluginFailure(
    'Plugins konnten nicht geladen werden.',
  );
  static const uninstallFailed = PluginFailure(
    'Plugin konnte nicht deinstalliert werden.',
  );
  static const installFailed = PluginFailure(
    'Die Installation ist fehlgeschlagen.',
  );
  static const catalogFailed = PluginFailure(
    'Der Plugin-Katalog konnte nicht geladen werden.',
  );
  static const settingsFailed = PluginFailure(
    'Die Einstellungen konnten nicht gespeichert werden.',
  );

  /// Der Nutzer hat die Auswahl abgebrochen — kein Fehler, nur kein Ergebnis.
  static const cancelled = PluginFailure('');

  final String message;

  bool get isCancelled => message.isEmpty;
}
