import '../../domain/entities/employee_attachment.dart';

enum NodeEmployeeAssignmentsStatus { loading, ready, failure }

class NodeEmployeeAssignmentsState {
  const NodeEmployeeAssignmentsState({
    this.status = NodeEmployeeAssignmentsStatus.loading,
    this.employees = const [],
    this.message,
  });

  final NodeEmployeeAssignmentsStatus status;
  final List<EmployeeAttachment> employees;
  final String? message;
}
