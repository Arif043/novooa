import 'package:multiple_result/multiple_result.dart';

import '../entities/employee.dart';
import '../entities/employee_draft.dart';
import '../entities/employee_failure.dart';
import '../repositories/employee_repository.dart';

class CreateEmployee {
  const CreateEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Result<Employee, EmployeeFailure>> call(EmployeeDraft draft) =>
      _repository.createEmployee(draft);
}

class UpdateEmployee {
  const UpdateEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Result<Employee, EmployeeFailure>> call(
    String employeeId,
    EmployeeDraft draft,
  ) => _repository.updateEmployee(employeeId, draft);
}

class DeleteEmployee {
  const DeleteEmployee(this._repository);

  final EmployeeRepository _repository;

  Future<Result<Unit, EmployeeFailure>> call(String employeeId) =>
      _repository.deleteEmployee(employeeId);
}
