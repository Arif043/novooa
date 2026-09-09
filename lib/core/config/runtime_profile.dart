import 'package:flutter/foundation.dart';

enum RuntimeKind { cloud, local }

class RuntimeProfile {
  const RuntimeProfile._(this.kind, this.localRuntimeUri);

  factory RuntimeProfile.fromEnvironment() {
    const configuredKind = String.fromEnvironment(
      'NOVOOA_RUNTIME',
      defaultValue: 'cloud',
    );
    final kind = switch (configuredKind) {
      'cloud' => RuntimeKind.cloud,
      'local' => RuntimeKind.local,
      _ => throw ArgumentError.value(
        configuredKind,
        'NOVOOA_RUNTIME',
        'Erlaubt sind cloud oder local.',
      ),
    };
    if (kind == RuntimeKind.local && kIsWeb) {
      throw StateError(
        'Die lokale novooa-Runtime ist nur für native Apps verfügbar.',
      );
    }
    const configuredUrl = String.fromEnvironment(
      'LOCAL_RUNTIME_URL',
      defaultValue: 'http://127.0.0.1:8090',
    );
    return RuntimeProfile._(kind, Uri.parse(configuredUrl));
  }

  final RuntimeKind kind;
  final Uri localRuntimeUri;

  bool get isCloud => kind == RuntimeKind.cloud;
  bool get isLocal => kind == RuntimeKind.local;
}
