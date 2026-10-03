import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import '../../domain/entities/employee_failure.dart';
import '../../domain/repositories/employee_repository.dart';

/// Für Betriebsvarianten ohne Mitarbeiter (Cloud): keine Mitarbeiter, kein Speicher.
class UnavailableEmployeeRepository implements EmployeeRepository {
  const UnavailableEmployeeRepository();

  static const _failure = EmployeeFailure(
    'Mitarbeiter sind in dieser Betriebsvariante noch nicht verfügbar.',
  );

  @override
  Stream<List<Employee>> watchEmployees(TeamId teamId) =>
      Stream.value(const []);

  @override
  Future<Result<Employee, EmployeeFailure>> createEmployee(
    EmployeeDraft draft,
  ) async => const Error(_failure);

  @override
  Future<Result<Employee, EmployeeFailure>> updateEmployee(
    String employeeId,
    EmployeeDraft draft,
  ) async => const Error(_failure);

  @override
  Future<Result<Unit, EmployeeFailure>> deleteEmployee(
    String employeeId,
  ) async => const Error(_failure);
}
