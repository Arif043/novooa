import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import '../../domain/entities/employee_failure.dart';
import '../../domain/repositories/employee_repository.dart';
import 'employee_json_mapper.dart';

/// Mitarbeiter der lokalen Runtime über deren HTTP-API.
class LocalEmployeeRepository implements EmployeeRepository {
  const LocalEmployeeRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Stream<List<Employee>> watchEmployees(TeamId teamId) {
    return watchWorkspaceChannel('employees', _load, _channel);
  }

  Future<List<Employee>> _load() async =>
      employeesFromJson(await _client.get('/v1/employees'));

  @override
  Future<Result<Employee, EmployeeFailure>> createEmployee(
    EmployeeDraft draft,
  ) => _attempt(
    () async => employeeFromJson(
      await _client.post('/v1/employees', employeeDraftToJson(draft)),
    ),
    EmployeeFailure.saveFailed,
  );

  @override
  Future<Result<Employee, EmployeeFailure>> updateEmployee(
    String employeeId,
    EmployeeDraft draft,
  ) => _attempt(
    () async => employeeFromJson(
      await _client.put(
        '/v1/employees/${Uri.encodeComponent(employeeId)}',
        employeeDraftToJson(draft),
      ),
    ),
    EmployeeFailure.saveFailed,
  );

  @override
  Future<Result<Unit, EmployeeFailure>> deleteEmployee(String employeeId) =>
      _attempt(() async {
        await _client.delete(
          '/v1/employees/${Uri.encodeComponent(employeeId)}',
        );
        return unit;
      }, EmployeeFailure.deleteFailed);

  Future<Result<T, EmployeeFailure>> _attempt<T extends Object>(
    Future<T> Function() action,
    EmployeeFailure fallback,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(EmployeeFailure(error.message));
    } on Object {
      return Error(fallback);
    }
  }
}
