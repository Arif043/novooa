import 'package:equatable/equatable.dart';

class PluginSettings extends Equatable {
  const PluginSettings({this.values = const {}, this.secretsSet = const {}});

  /// Werte ohne Geheimnisse; Standardwerte aus dem Manifest sind bereits eingesetzt.
  final Map<String, Object> values;

  /// Schlüssel der Geheimnisse, die im Backend gesetzt sind.
  final Set<String> secretsSet;

  @override
  List<Object?> get props => [values, secretsSet];
}
