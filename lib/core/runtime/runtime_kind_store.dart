import 'runtime_profile.dart';

/// Persistiert die gewählte Betriebsvariante. Getrennt von
/// `RuntimeEndpointStore`, weil die Variante auch für die Cloud gilt, die
/// keinen Runtime-Endpunkt kennt.
abstract interface class RuntimeKindStore {
  /// `null`, solange keine Wahl gespeichert ist — dann gilt
  /// `RuntimeProfile.defaultKind`.
  Future<RuntimeKind?> load();
  Future<void> save(RuntimeKind kind);
}
