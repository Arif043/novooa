import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/employee.dart';
import '../entities/employee_draft.dart';
import '../entities/employee_failure.dart';
import '../repositories/employee_repository.dart';

class UpdateEmployee {
  const UpdateEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Result<Employee, EmployeeFailure>> call({
    required TeamId teamId,
    required String employeeId,
    required EmployeeDraft draft,
  }) {
    return _repository.updateEmployee(
      teamId: teamId,
      employeeId: employeeId,
      draft: draft,
    );
  }
}
