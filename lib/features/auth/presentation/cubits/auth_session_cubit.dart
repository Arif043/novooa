import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> implements Listenable {
  AuthSessionCubit({
    required AuthRepository authRepository,
    required this.signOutUseCase,
  }) : super(AuthSessionState(currentUser: authRepository.currentUser())) {
    _subscription = authRepository.authStateChanges().listen(
      _setCurrentUser,
      onError: (_) {},
    );
  }

  final SignOut signOutUseCase;
  final List<VoidCallback> _listeners = [];
  late final StreamSubscription<AuthUser?> _subscription;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  Future<void> signOut() async {
    if (state.status == AuthSessionStatus.signingOut) return;
    _emitSession(state.copyWith(status: AuthSessionStatus.signingOut));
    final signOutOrFailure = await signOutUseCase();
    if (isClosed) return;
    signOutOrFailure.when(_clearSession, _emitFailure);
  }

  void _setCurrentUser(AuthUser? user) {
    _emitSession(AuthSessionState(currentUser: user));
  }

  void _clearSession(Unit _) {
    _emitSession(const AuthSessionState(currentUser: null));
  }

  void _emitFailure(AuthFailure failure) {
    _emitSession(
      state.copyWith(
        status: AuthSessionStatus.failure,
        message: failure.message,
      ),
    );
  }

  void _emitSession(AuthSessionState nextState) {
    if (isClosed) return;
    emit(nextState);
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
