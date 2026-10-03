part of 'node_config.dart';

/// Mixin für NodeConfigs, die einen Mitarbeiter (Subagent) tragen können.
/// 0..1 pro Node. Die Config hält nur die ID; Rahmenbedingung und
/// Fähigkeiten lädt die Runtime beim Lauf frisch. Mitarbeiter und eigene
/// Fähigkeiten schließen sich aus (siehe `resolveNodeDelegation`).
mixin EmployeeAssignmentSupport<T extends NodeConfig> on NodeConfig {
  String? get employeeId;

  /// `null` entfernt den Mitarbeiter.
  T copyWithEmployeeId(String? employeeId);

  /// Weist den Mitarbeiter zu und entfernt dabei eigene Fähigkeiten.
  T assignEmployee(String employeeId) => copyWithEmployeeId(employeeId);

  T unassignEmployee() => copyWithEmployeeId(null);
}
