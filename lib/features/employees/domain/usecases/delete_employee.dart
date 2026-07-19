import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/employee_failure.dart';
import '../repositories/employee_repository.dart';

class DeleteEmployee {
  const DeleteEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Result<Unit, EmployeeFailure>> call({
    required TeamId teamId,
    required String employeeId,
  }) {
    return _repository.deleteEmployee(teamId: teamId, employeeId: employeeId);
  }
}
