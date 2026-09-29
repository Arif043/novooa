import 'runtime_profile.dart';

/// Welche Features in der aktuellen Betriebsvariante verfügbar sind.
///
/// Ersetzt das bisherige Ad-hoc-Muster, per
/// `serviceLocator.isRegistered<T>()` zu erraten, ob eine Variante ein
/// Feature unterstützt (siehe `docs/architecture/betriebsvarianten.md`,
/// Blocker 6) — ob eine Klasse zufällig in der DI registriert ist, ist kein
/// fachliches Feature-Flag, auch wenn beides bisher zusammenfiel. Einmal pro
/// Prozess aus der [RuntimeKind] abgeleitet und als Singleton registriert
/// (siehe `configureDependencies`), statt live am Container zu schnüffeln.
class WorkspaceCapabilities {
  const WorkspaceCapabilities({
    required this.assistant,
    required this.dataCollections,
    required this.modelCatalog,
  });

  factory WorkspaceCapabilities.forKind(RuntimeKind kind) => switch (kind) {
    RuntimeKind.cloud => const WorkspaceCapabilities(
      assistant: true,
      dataCollections: false,
      modelCatalog: false,
    ),
    RuntimeKind.standalone => const WorkspaceCapabilities(
      // Absichtlich noch false: Der lokalen Runtime fehlt der
      // Assistant-Endpunkt (siehe docs/architecture/betriebsvarianten.md).
      // Sobald er existiert, kippt dieser eine Wert — keine Suche mehr nach
      // verstreuten Registrierungs-Checks nötig.
      assistant: false,
      dataCollections: true,
      modelCatalog: true,
    ),
  };

  /// KI-Agent (Aufgabenstudio- und Wissensbasis-Assistent).
  final bool assistant;

  /// Dokumentorientierte Datensammlungen (`ListDataCollections`) — Cloud hat
  /// dafür noch keinen Firestore-`DataRepository`.
  final bool dataCollections;

  /// ONNX-Modellkatalog (`ModelCatalogCubit`).
  final bool modelCatalog;
}
