import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/employee.dart';
import '../entities/employee_draft.dart';
import '../entities/employee_failure.dart';

abstract class EmployeeRepository {
  Stream<List<Employee>> watchEmployees(TeamId teamId);

  Future<Result<Employee, EmployeeFailure>> createEmployee(EmployeeDraft draft);

  Future<Result<Employee, EmployeeFailure>> updateEmployee(
    String employeeId,
    EmployeeDraft draft,
  );

  Future<Result<Unit, EmployeeFailure>> deleteEmployee(String employeeId);
}
