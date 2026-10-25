import 'package:equatable/equatable.dart';

import 'session_device.dart';

/// Öffentliche Kennung einer Sitzung; nicht das Token.
extension type const RuntimeSessionId(String value) {}

/// Eine angemeldete Sitzung des eigenen Kontos.
class RuntimeSession extends Equatable {
  const RuntimeSession({
    required this.id,
    required this.isCurrent,
    required this.signedInAt,
    required this.lastActiveAt,
    required this.device,
  });

  final RuntimeSessionId id;

  /// Die Sitzung dieses Geräts; sie endet nur über das Abmelden.
  final bool isCurrent;
  final DateTime signedInAt;

  /// Höchstens auf eine Stunde genau: Die Runtime schreibt die Nutzung
  /// nur stündlich.
  final DateTime lastActiveAt;
  final SessionDevice device;

  @override
  List<Object?> get props => [id, isCurrent, signedInAt, lastActiveAt, device];
}
