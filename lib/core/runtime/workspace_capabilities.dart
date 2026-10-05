import 'package:flutter/foundation.dart';

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
///
/// **Einzige Quelle** für „ist Feature X verfügbar?" — insbesondere [push]:
/// `main.dart` darf daneben keine eigene, zur Laufzeit ermittelte
/// Ja/Nein-Entscheidung mehr führen (etwa „hat `Firebase.initializeApp()`
/// geklappt?"). Alles, was diese Frage deterministisch beeinflusst —
/// Betriebsvariante, Build-Flag, Zielplattform — fließt deshalb bereits hier
/// in [forKind] ein.
class WorkspaceCapabilities {
  const WorkspaceCapabilities({
    required this.assistant,
    required this.dataCollections,
    required this.modelCatalog,
    required this.push,
    required this.messagingChannels,
    required this.skills,
    required this.employees,
    required this.connections,
  });

  factory WorkspaceCapabilities.forKind(RuntimeKind kind) => switch (kind) {
    RuntimeKind.cloud => const WorkspaceCapabilities(
      assistant: true,
      dataCollections: false,
      modelCatalog: false,
      push: true,
      messagingChannels: true,
      skills: false,
      employees: false,
      connections: false,
    ),
    RuntimeKind.standalone => WorkspaceCapabilities(
      assistant: true,
      dataCollections: true,
      modelCatalog: true,
      push: _standalonePushEnabled && _pushSupportedOnThisPlatform,
      messagingChannels: false,
      skills: true,
      employees: true,
      connections: true,
    ),
  };

  /// KI-Agent (Aufgabenstudio- und Wissensbasis-Assistent).
  final bool assistant;

  /// Dokumentorientierte Datensammlungen (`ListDataCollections`) — Cloud hat
  /// dafür noch keinen Firestore-`DataRepository`.
  final bool dataCollections;

  /// ONNX-Modellkatalog (`ModelCatalogCubit`).
  final bool modelCatalog;

  /// WhatsApp- und SMS-Kanäle (Twilio über Team-Konten in der Cloud). In der
  /// lokalen Runtime gibt es nur E-Mail-Postfächer.
  final bool messagingChannels;

  /// Fähigkeiten (Skills) nach agentskills.io: Ordner im Skills-Ordner der
  /// lokalen Runtime. Die Cloud hat dafür noch keinen Speicher.
  final bool skills;

  /// Mitarbeiter (Subagenten) mit Rahmenbedingung und Fähigkeiten. Sie
  /// brauchen Fähigkeiten und einen Speicher in der lokalen Runtime.
  final bool employees;

  /// Verbindungen zu externen HTTP-Systemen (Zugangsdaten im Backend, Baustein
  /// „HTTP-Anfrage“). Die Cloud hat dafür noch keinen Speicher.
  final bool connections;

  /// Firebase-Push (FCM/APNs). Für Standalone bewusst standardmäßig aus,
  /// damit sich der macOS-Client ohne Apple-Entwicklungszertifikat bauen
  /// lässt (siehe `docs/local-runtime.md` § Push-Benachrichtigungen). Zur
  /// Auslieferung mit `--dart-define=NOVOOA_PUSH_ENABLED=true` aktivierbar —
  /// dort allerdings nur auf Plattformen, die `firebase_options.dart`
  /// überhaupt konfiguriert (siehe [_pushSupportedOnThisPlatform]).
  final bool push;

  static const _standalonePushEnabled = bool.fromEnvironment(
    'NOVOOA_PUSH_ENABLED',
    defaultValue: false,
  );

  /// Firebase Cloud Messaging hat keine Desktop-SDKs für Windows/Linux —
  /// `firebase_options.dart` wirft dort immer `UnsupportedError`. Das ist
  /// eine feste Plattformgrenze, kein Laufzeitzufall, und gehört deshalb
  /// hier in die Fähigkeit hinein statt als Try/Catch-Rückfall erst beim
  /// tatsächlichen `Firebase.initializeApp()`-Aufruf in `main.dart`
  /// entdeckt zu werden.
  static bool get _pushSupportedOnThisPlatform {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => false,
    };
  }
}
