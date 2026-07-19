import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import '../../domain/entities/employee_failure.dart';
import '../../domain/usecases/create_employee.dart';
import '../../domain/usecases/delete_employee.dart';
import '../../domain/usecases/update_employee.dart';
import '../../domain/usecases/watch_employees.dart';
import 'employees_state.dart';

class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(
    this._authRepository,
    this._watchEmployees,
    this._createEmployee,
    this._updateEmployee,
    this._deleteEmployee,
    this._getCurrentTeamId,
  ) : super(const EmployeesState());

  final AuthRepository _authRepository;
  final WatchEmployees _watchEmployees;
  final CreateEmployee _createEmployee;
  final UpdateEmployee _updateEmployee;
  final DeleteEmployee _deleteEmployee;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Employee>>? _subscription;

  Future<void> load() async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      return _emitFailure(EmployeeFailureKind.unauthenticated);
    }
    emit(const EmployeesState());
    _subscription?.cancel();
    _subscription = _watchEmployees(teamId).listen(
      _emitEmployees,
      onError: (_) => _emitFailure(EmployeeFailureKind.loadFailed),
    );
  }

  Future<Employee?> createEmployee(EmployeeDraft draft) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(EmployeeFailureKind.unauthenticated);
      return null;
    }
    final result = await _createEmployee(teamId: teamId, draft: draft);
    return result.when(
      (employee) {
        emit(state.copyWith(message: 'Mitarbeiter gespeichert.'));
        return employee;
      },
      (failure) {
        _emitFailure(failure.kind);
        return null;
      },
    );
  }

  Future<Employee?> updateEmployee({
    required String employeeId,
    required EmployeeDraft draft,
  }) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(EmployeeFailureKind.unauthenticated);
      return null;
    }
    final result = await _updateEmployee(
      teamId: teamId,
      employeeId: employeeId,
      draft: draft,
    );
    return result.when(
      (employee) {
        emit(state.copyWith(message: 'Mitarbeiter gespeichert.'));
        return employee;
      },
      (failure) {
        _emitFailure(failure.kind);
        return null;
      },
    );
  }

  Future<bool> deleteEmployee(String employeeId) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) {
      _emitFailure(EmployeeFailureKind.unauthenticated);
      return false;
    }
    final result = await _deleteEmployee(
      teamId: teamId,
      employeeId: employeeId,
    );
    return result.when(
      (_) {
        emit(state.copyWith(message: 'Mitarbeiter gelöscht.'));
        return true;
      },
      (failure) {
        _emitFailure(failure.kind);
        return false;
      },
    );
  }

  void _emitEmployees(List<Employee> employees) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: EmployeesStatus.ready,
        employees: employees,
        clearMessage: true,
      ),
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    final user = _authRepository.currentUser();
    if (user == null) return null;
    try {
      return await _getCurrentTeamId();
    } catch (_) {
      return null;
    }
  }

  void _emitFailure(EmployeeFailureKind kind) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: EmployeesStatus.failure,
        message: EmployeeFailure(kind).message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
