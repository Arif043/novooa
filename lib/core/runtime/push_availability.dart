import 'package:flutter/foundation.dart';

/// Firebase-Push (FCM/APNs) über das Push-Relay der Runtime.
///
/// Standardmäßig aus, damit sich der macOS-Client ohne
/// Apple-Entwicklungszertifikat bauen lässt (siehe
/// `docs/notes/push-standalone.md`). Zur Auslieferung mit
/// `--dart-define=NOVOOA_PUSH_ENABLED=true` aktivierbar, aber nur auf
/// Plattformen, die `firebase_options.dart` konfiguriert: Für Windows und
/// Linux gibt es kein FCM-SDK.
bool isPushEnabled() => _pushRequested && _pushSupportedOnThisPlatform;

const _pushRequested = bool.fromEnvironment('NOVOOA_PUSH_ENABLED');

bool get _pushSupportedOnThisPlatform {
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
