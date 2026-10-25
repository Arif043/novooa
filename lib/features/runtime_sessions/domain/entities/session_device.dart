import 'package:equatable/equatable.dart';

enum DeviceOs { android, ios, macos, windows, linux, unknown }

/// Was ein Gerät beim Anmelden über sich gemeldet hat.
class SessionDevice extends Equatable {
  const SessionDevice({required this.app, required this.os, this.browser});

  /// Name der App; leer, wenn das Gerät nichts gemeldet hat.
  final String app;
  final DeviceOs os;

  /// Nur bei Anmeldungen im Browser.
  final String? browser;

  static const officialApp = 'novooa';

  bool get isOfficialApp => app == officialApp;

  bool get isKnown =>
      app.isNotEmpty || os != DeviceOs.unknown || browser != null;

  @override
  List<Object?> get props => [app, os, browser];
}
