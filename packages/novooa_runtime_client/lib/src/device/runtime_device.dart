import 'package:flutter/foundation.dart';

import 'browser_name.dart';

/// Was der Client beim Anmelden über sich meldet, damit Personen ihre Geräte
/// in der Liste der Sitzungen wiedererkennen. Reine Anzeige, keine
/// Berechtigung.
@immutable
class RuntimeDevice {
  const RuntimeDevice({required this.app, required this.os, this.browser});

  /// Das aktuelle Gerät; [app] unterscheidet z. B. ein Kunden-Dashboard von
  /// der offiziellen App.
  factory RuntimeDevice.current({required String app}) => RuntimeDevice(
    app: app,
    os: runtimeDeviceOsFor(defaultTargetPlatform),
    browser: currentBrowserName(),
  );

  final String app;

  /// `android`, `ios`, `macos`, `windows`, `linux` oder `unknown`.
  final String os;

  /// Nur im Web gesetzt, z. B. `Chrome`.
  final String? browser;

  Map<String, Object?> toJson() => {'app': app, 'os': os, 'browser': browser};
}

String runtimeDeviceOsFor(TargetPlatform platform) => switch (platform) {
  .android => 'android',
  .iOS => 'ios',
  .macOS => 'macos',
  .windows => 'windows',
  .linux => 'linux',
  .fuchsia => 'unknown',
};
