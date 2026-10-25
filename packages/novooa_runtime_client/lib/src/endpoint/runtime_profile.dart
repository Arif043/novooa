import 'package:flutter/foundation.dart';

/// Wo die App ihre Runtime erreicht.
class RuntimeProfile {
  const RuntimeProfile._(this.workspaceApiUri);

  /// Ein ausdrücklich gesetztes `WORKSPACE_API_URL` gilt immer, auch im Web
  /// (Entwicklung mit `flutter run -d chrome`). Sonst liefert im Web die
  /// Runtime die App selbst aus — ihre API liegt auf derselben Herkunft, was
  /// CORS und Mixed Content vermeidet (siehe
  /// `docs/notes/mixed-content-im-lan.md`). Nativ gilt die lokale Runtime,
  /// bis der Nutzer eine andere Adresse speichert.
  factory RuntimeProfile.fromEnvironment() {
    if (_configuredWorkspaceApiUrl.isNotEmpty) {
      return RuntimeProfile._(Uri.parse(_configuredWorkspaceApiUrl));
    }
    return RuntimeProfile._(
      kIsWeb ? Uri.parse(Uri.base.origin) : Uri.parse(_localRuntimeUrl),
    );
  }

  static const _configuredWorkspaceApiUrl = String.fromEnvironment(
    'WORKSPACE_API_URL',
  );

  static const _localRuntimeUrl = 'http://127.0.0.1:8090';

  final Uri workspaceApiUri;

  RuntimeProfile withWorkspaceApiUri(Uri uri) => RuntimeProfile._(uri);
}
