import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import '../../domain/entities/employee_failure.dart';
import '../../domain/usecases/employee_use_cases.dart';
import '../../domain/usecases/watch_employees.dart';
import 'employees_state.dart';

/// Verwaltet die Mitarbeiter: Liste, Anlegen, Ändern, Löschen. Änderungen
/// meldet die Runtime per Realtime-Kanal, die Liste aktualisiert sich selbst.
class EmployeesCubit extends Cubit<EmployeesState> {
  EmployeesCubit(
    this._watchEmployees,
    this._createEmployee,
    this._updateEmployee,
    this._deleteEmployee,
    this._getCurrentTeamId,
  ) : super(const EmployeesState());

  final WatchEmployees _watchEmployees;
  final CreateEmployee _createEmployee;
  final UpdateEmployee _updateEmployee;
  final DeleteEmployee _deleteEmployee;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Employee>>? _subscription;

  Future<void> load() async {
    emit(const EmployeesState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchEmployees(teamId).listen(
      _emitEmployees,
      onError: (Object error, StackTrace stackTrace) {
        logException(
          message: 'Mitarbeiter konnten nicht geladen werden.',
          error: error,
          stackTrace: stackTrace,
          name: 'employees',
        );
        _emitFailure(EmployeeFailure.loadFailed.message);
      },
    );
  }

  /// `true`, wenn gespeichert wurde; bei einem Fehler bleibt der Editor offen
  /// und die Meldung erscheint als Snackbar.
  Future<bool> save(EmployeeDraft draft, {String? employeeId}) async {
    final result = employeeId == null
        ? await _createEmployee(draft)
        : await _updateEmployee(employeeId, draft);
    if (isClosed) return false;
    return result.when(
      (_) {
        emit(state.copyWith(message: 'Mitarbeiter gespeichert.'));
        return true;
      },
      (failure) {
        emit(state.copyWith(message: failure.message));
        return false;
      },
    );
  }

  Future<void> delete(String employeeId) async {
    final result = await _deleteEmployee(employeeId);
    if (isClosed) return;
    result.when(
      (_) => emit(state.copyWith(message: 'Mitarbeiter gelöscht.')),
      (failure) => emit(state.copyWith(message: failure.message)),
    );
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      logException(
        message: 'Team konnte nicht geladen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'employees',
      );
      _emitFailure('Team konnte nicht geladen werden.');
      return null;
    }
  }

  void _emitEmployees(List<Employee> employees) {
    if (isClosed) return;
    emit(state.copyWith(status: EmployeesStatus.ready, employees: employees));
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: EmployeesStatus.failure, message: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
