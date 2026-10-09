import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/domain/usecases/watch_employees.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'node_employee_assignments_state.dart';

/// Beobachtet die Team-Mitarbeiter und stellt sie dem NodeInspector als
/// Auswahl-Slot bereit — analog zu [NodeSkillAttachmentsCubit], nur dass
/// eine Zuweisung 0..1 statt 0..n ist.
class NodeEmployeeAssignmentsCubit extends Cubit<NodeEmployeeAssignmentsState> {
  NodeEmployeeAssignmentsCubit(
    this._authRepository,
    this._watchEmployees,
    this._getCurrentTeamId,
  ) : super(const NodeEmployeeAssignmentsState());

  final AuthRepository _authRepository;
  final WatchEmployees _watchEmployees;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Employee>>? _subscription;

  Future<void> load() async {
    final user = _authRepository.currentUser();
    if (user == null) return _emitFailure('Du musst angemeldet sein.');
    emit(const NodeEmployeeAssignmentsState());
    _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchEmployees(teamId).listen(
      _emitEmployees,
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          LocaleKeys.ui_employees_load_failed.tr(),
          error,
          stackTrace,
        );
      },
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      _logAndEmitFailure(
        LocaleKeys.ui_team_load_failed.tr(),
        error,
        stackTrace,
      );
      return null;
    }
  }

  void _emitEmployees(List<Employee> employees) {
    if (isClosed) return;
    emit(
      NodeEmployeeAssignmentsState(
        status: NodeEmployeeAssignmentsStatus.ready,
        employees: employees,
      ),
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      NodeEmployeeAssignmentsState(
        status: NodeEmployeeAssignmentsStatus.failure,
        message: message,
      ),
    );
  }

  void _logAndEmitFailure(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'node_employee_assignments',
    );
    _emitFailure(message);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
