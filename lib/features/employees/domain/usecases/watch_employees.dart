import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/employee.dart';
import '../repositories/employee_repository.dart';

class WatchEmployees {
  const WatchEmployees(this._repository);

  final EmployeeRepository _repository;

  Stream<List<Employee>> call(TeamId teamId) =>
      _repository.watchEmployees(teamId);
}
