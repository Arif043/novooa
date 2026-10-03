import 'package:syscat2/features/employees/domain/entities/employee.dart';

enum NodeEmployeeAssignmentsStatus { loading, ready, failure }

class NodeEmployeeAssignmentsState {
  const NodeEmployeeAssignmentsState({
    this.status = NodeEmployeeAssignmentsStatus.loading,
    this.employees = const [],
    this.message,
  });

  final NodeEmployeeAssignmentsStatus status;
  final List<Employee> employees;
  final String? message;
}
