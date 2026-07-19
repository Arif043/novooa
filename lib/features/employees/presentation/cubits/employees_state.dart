import 'package:equatable/equatable.dart';

import '../../domain/entities/employee.dart';

enum EmployeesStatus { loading, ready, failure }

class EmployeesState extends Equatable {
  const EmployeesState({
    this.status = EmployeesStatus.loading,
    this.employees = const [],
    this.message,
  });

  final EmployeesStatus status;
  final List<Employee> employees;
  final String? message;

  EmployeesState copyWith({
    EmployeesStatus? status,
    List<Employee>? employees,
    String? message,
    bool clearMessage = false,
  }) {
    return EmployeesState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, employees, message];
}
