import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/employee.dart';
import '../entities/employee_draft.dart';
import '../entities/employee_failure.dart';

abstract class EmployeeRepository {
  Stream<List<Employee>> watchEmployees(TeamId teamId);

  Future<Result<Employee, EmployeeFailure>> createEmployee({
    required TeamId teamId,
    required EmployeeDraft draft,
  });

  Future<Result<Employee, EmployeeFailure>> updateEmployee({
    required TeamId teamId,
    required String employeeId,
    required EmployeeDraft draft,
  });

  Future<Result<Unit, EmployeeFailure>> deleteEmployee({
    required TeamId teamId,
    required String employeeId,
  });
}
