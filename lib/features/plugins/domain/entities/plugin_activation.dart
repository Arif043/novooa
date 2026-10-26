import 'package:equatable/equatable.dart';

/// Kennung eines eingebauten Plugins, z. B. `googleDrive`.
extension type const PluginId(String value) {}

/// Ob ein Plugin im Arbeitsbereich aktiv ist. Standard ist aus.
class PluginActivation extends Equatable {
  const PluginActivation({
    required this.id,
    required this.isEnabled,
    this.enabledAt,
  });

  final PluginId id;
  final bool isEnabled;
  final DateTime? enabledAt;

  @override
  List<Object?> get props => [id, isEnabled, enabledAt];
}
