part of 'node_config.dart';

/// Mixin für NodeConfigs, die einen Mitarbeiter (Subagent) tragen können.
/// 0..1 pro Node — ein Baustein wird an genau einen oder keinen Mitarbeiter
/// delegiert.
mixin EmployeeAssignmentSupport<T extends NodeConfig> on NodeConfig {
  EmployeeAttachment? get employee;

  T copyWithEmployee(EmployeeAttachment? employee);

  T assignEmployee(EmployeeAttachment attachment) {
    return copyWithEmployee(attachment);
  }

  T unassignEmployee() {
    return copyWithEmployee(null);
  }
}
