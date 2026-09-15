import 'package:flutter/foundation.dart';

enum RuntimeKind { cloud, standalone }

class RuntimeProfile {
  const RuntimeProfile._(this.kind, this.workspaceApiUri);

  factory RuntimeProfile.fromEnvironment() {
    const configuredKind = String.fromEnvironment(
      'NOVOOA_RUNTIME',
      defaultValue: 'cloud',
    );
    final kind = switch (configuredKind) {
      'cloud' => RuntimeKind.cloud,
      'standalone' => RuntimeKind.standalone,
      _ => throw ArgumentError.value(
        configuredKind,
        'NOVOOA_RUNTIME',
        'Erlaubt sind cloud oder standalone.',
      ),
    };
    if (kind == RuntimeKind.standalone && kIsWeb) {
      throw StateError('Die novooa-Runtime ist nur für native Apps verfügbar.');
    }
    const configuredUrl = String.fromEnvironment(
      'WORKSPACE_API_URL',
      defaultValue: 'http://127.0.0.1:8090',
    );
    return RuntimeProfile._(kind, Uri.parse(configuredUrl));
  }

  final RuntimeKind kind;
  final Uri workspaceApiUri;

  RuntimeProfile withWorkspaceApiUri(Uri uri) => RuntimeProfile._(kind, uri);

  bool get isCloud => kind == RuntimeKind.cloud;
  bool get isStandalone => kind == RuntimeKind.standalone;

  bool get pushNotificationsEnabled => isCloud || _standalonePushEnabled;

  static const _standalonePushEnabled = bool.fromEnvironment(
    'NOVOOA_PUSH_ENABLED',
    defaultValue: false,
  );
}
