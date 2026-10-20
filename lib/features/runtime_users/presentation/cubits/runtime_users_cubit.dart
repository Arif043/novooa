import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';

import '../../domain/entities/runtime_user.dart';
import '../../domain/entities/runtime_user_failure.dart';
import '../../domain/usecases/runtime_user_use_cases.dart';
import 'runtime_users_state.dart';

/// Benutzerverwaltung für Admins: Liste, Anlegen mit Einladungscode, Rolle
/// ändern, Passwort zurücksetzen, Löschen. Die Liste folgt dem Realtime-Kanal.
class RuntimeUsersCubit extends Cubit<RuntimeUsersState> {
  RuntimeUsersCubit(
    this._watchUsers,
    this._createUser,
    this._changeRole,
    this._resetPassword,
    this._deleteUser,
  ) : super(const RuntimeUsersState());

  final WatchRuntimeUsers _watchUsers;
  final CreateRuntimeUser _createUser;
  final ChangeRuntimeUserRole _changeRole;
  final ResetRuntimeUserPassword _resetPassword;
  final DeleteRuntimeUser _deleteUser;
  StreamSubscription<RuntimeUserOverview>? _subscription;

  Future<void> load() async {
    emit(const RuntimeUsersState());
    await _subscription?.cancel();
    _subscription = _watchUsers().listen(_emitOverview, onError: _loadFailed);
  }

  /// `true`, wenn das Konto angelegt wurde; der Code erscheint dann einmalig.
  Future<bool> create(NewRuntimeUser user) async {
    final createdOrFailure = await _createUser(user);
    if (isClosed) return false;
    return createdOrFailure.when(
      (created) {
        _showInvitation(created.user.displayName, created.invitation);
        return true;
      },
      (failure) {
        _report(failure);
        return false;
      },
    );
  }

  Future<void> changeRole(RuntimeUser user, RuntimeRole role) async {
    final userOrFailure = await _changeRole(user.uid, role);
    if (isClosed) return;
    userOrFailure.when(
      (_) => _confirm(RuntimeUsersConfirmation.roleChanged),
      _report,
    );
  }

  Future<void> resetPassword(RuntimeUser user) async {
    final invitationOrFailure = await _resetPassword(user.uid);
    if (isClosed) return;
    invitationOrFailure.when(
      (invitation) => _showInvitation(user.displayName, invitation),
      _report,
    );
  }

  Future<void> delete(RuntimeUser user) async {
    final deletedOrFailure = await _deleteUser(user.uid);
    if (isClosed) return;
    deletedOrFailure.when(
      (_) => _confirm(RuntimeUsersConfirmation.deleted),
      _report,
    );
  }

  /// Nach dem Anzeigen einer Meldung oder eines Codes.
  void noticeShown() => emit(state.copyWith());

  void _emitOverview(RuntimeUserOverview overview) {
    if (isClosed) return;
    emit(state.copyWith(status: RuntimeUsersStatus.ready, overview: overview));
  }

  void _loadFailed(Object error, StackTrace stackTrace) {
    logException(
      message: 'Benutzer konnten nicht geladen werden.',
      error: error,
      stackTrace: stackTrace,
      name: 'runtime-users',
    );
    if (isClosed) return;
    emit(state.copyWith(status: RuntimeUsersStatus.failure));
  }

  void _showInvitation(String displayName, UserInvitation invitation) => emit(
    state.copyWith(
      issuedInvitation: IssuedInvitation(
        displayName: displayName,
        invitation: invitation,
      ),
    ),
  );

  void _confirm(RuntimeUsersConfirmation confirmation) =>
      emit(state.copyWith(confirmation: confirmation));

  void _report(RuntimeUserFailure failure) =>
      emit(state.copyWith(failure: failure));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
