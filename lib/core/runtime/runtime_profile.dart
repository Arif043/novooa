import 'package:flutter/foundation.dart';

enum RuntimeKind { cloud, standalone }

/// Liest einen persistierten oder konfigurierten Variantennamen. Liefert
/// `null` statt zu werfen, damit gespeicherte Altwerte verworfen werden
/// können, ohne den Start zu verhindern (siehe `RuntimeKindPreferences`).
RuntimeKind? runtimeKindOrNull(String? name) {
  return switch (name) {
    'cloud' => RuntimeKind.cloud,
    'standalone' => RuntimeKind.standalone,
    _ => null,
  };
}

/// Herkünfte, unter denen die novooa-Cloud ausgeliefert wird: die
/// Produktiv-Domain sowie die Firebase-Hosting-Domains (Live-Channel und
/// PR-Vorschauen wie `syscat-90bff--pr-12-abc.web.app`).
bool isCloudWebHost(String host) {
  return host == 'app.novooa.de' ||
      host.endsWith('.web.app') ||
      host.endsWith('.firebaseapp.com');
}

/// Im Web bestimmt die **Herkunft** die Betriebsvariante, nicht der Nutzer:
/// Unter einer Cloud-Domain gibt es nur die Cloud, unter jeder anderen
/// Adresse nur Standalone — denn dort liefert die Runtime der Nutzer:innen
/// die App selbst aus, erreichbar über deren IP oder Domain.
///
/// Reine Funktion (statt direkt auf `Uri.base` zuzugreifen), damit die
/// Zuordnung ohne Browser testbar bleibt.
RuntimeKind webRuntimeKindForOrigin(Uri origin) {
  return isCloudWebHost(origin.host)
      ? RuntimeKind.cloud
      : RuntimeKind.standalone;
}

class RuntimeProfile {
  const RuntimeProfile._(this.kind, this.workspaceApiUri);

  factory RuntimeProfile.fromEnvironment() =>
      RuntimeProfile.forKind(defaultKind);

  factory RuntimeProfile.forKind(RuntimeKind kind) {
    if (!supports(kind)) {
      throw StateError(
        'Im Web bestimmt die Herkunft die Betriebsvariante; '
        '${kind.name} ist hier nicht verfügbar.',
      );
    }
    return RuntimeProfile._(kind, _workspaceApiUriFor(kind));
  }

  /// Ein ausdrücklich gesetztes `--dart-define=NOVOOA_RUNTIME` gewinnt immer
  /// — sonst liesse sich die Cloud-Web-App nicht mehr lokal entwickeln
  /// (`flutter run -d chrome` läuft auf `localhost`, also keiner
  /// Cloud-Domain). `null`, wenn nichts gesetzt ist.
  static RuntimeKind? get configuredKind {
    if (_configuredKind.isEmpty) return null;
    final kind = runtimeKindOrNull(_configuredKind);
    if (kind == null) {
      throw ArgumentError.value(
        _configuredKind,
        'NOVOOA_RUNTIME',
        'Erlaubt sind cloud oder standalone.',
      );
    }
    return kind;
  }

  /// Die Variante ohne gespeicherte Nutzerwahl.
  static RuntimeKind get defaultKind {
    return configuredKind ??
        (kIsWeb ? webRuntimeKindForOrigin(Uri.base) : RuntimeKind.cloud);
  }

  /// Nativ sind beide Varianten wählbar. Im Web gibt es genau eine — die
  /// Herkunft (oder ein ausdrücklicher Build-Define) legt sie fest.
  static bool supports(RuntimeKind kind) {
    if (!kIsWeb) return true;
    return kind == defaultKind;
  }

  static Iterable<RuntimeKind> get supportedKinds {
    return RuntimeKind.values.where(supports);
  }

  /// Im Web-Standalone-Fall liefert die Runtime die App selbst aus — ihre
  /// API liegt damit auf derselben Herkunft. Das umgeht CORS und Mixed
  /// Content vollständig (siehe `docs/architecture/betriebsvarianten.md`).
  static Uri _workspaceApiUriFor(RuntimeKind kind) {
    if (kIsWeb && kind == RuntimeKind.standalone) {
      return Uri.parse(Uri.base.origin);
    }
    return Uri.parse(_configuredWorkspaceApiUrl);
  }

  static const _configuredKind = String.fromEnvironment('NOVOOA_RUNTIME');

  static const _configuredWorkspaceApiUrl = String.fromEnvironment(
    'WORKSPACE_API_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  final RuntimeKind kind;
  final Uri workspaceApiUri;

  RuntimeProfile withWorkspaceApiUri(Uri uri) => RuntimeProfile._(kind, uri);

  bool get isCloud => kind == RuntimeKind.cloud;
  bool get isStandalone => kind == RuntimeKind.standalone;
}
