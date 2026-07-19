import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../user/domain/entities/user_failure.dart';
import '../../../user/domain/usecases/get_user_profile.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_session_state.dart';

class AuthSessionCubit extends Cubit<AuthSessionState> implements Listenable {
  AuthSessionCubit({
    required AuthRepository authRepository,
    required this.signOutUseCase,
    required GetUserProfile getUserProfileUseCase,
    Duration retryBaseDelay = const Duration(milliseconds: 200),
    int maxProfileRetries = 4,
  }) : _authRepository = authRepository,
       _getUserProfile = getUserProfileUseCase,
       _retryBaseDelay = retryBaseDelay,
       _maxProfileRetries = maxProfileRetries,
       super(const AuthSessionState(currentUser: null)) {
    _subscription = _authRepository.authStateChanges().listen(
      _onAuthChanged,
      onError: (_) {},
    );
    final initial = _authRepository.currentUser();
    if (initial != null) _startVerify(initial);
  }

  final AuthRepository _authRepository;
  final SignOut signOutUseCase;
  final GetUserProfile _getUserProfile;
  final Duration _retryBaseDelay;
  final int _maxProfileRetries;
  final List<VoidCallback> _listeners = [];
  late final StreamSubscription<AuthUser?> _subscription;

  /// Aktiv laufender Verify-Zyklus. Wird bei einem neuen Auth-Event
  /// invalidiert, damit ein alter Retry-Loop nicht einen inzwischen
  /// abgemeldeten User nachträglich als signed-in markieren kann.
  int _verifyGeneration = 0;

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  Future<void> signOut() async {
    if (state.status == AuthSessionStatus.signingOut) return;
    _emitSession(
      state.copyWith(
        status: AuthSessionStatus.signingOut,
        clearMessage: true,
      ),
    );
    final signOutOrFailure = await signOutUseCase();
    if (isClosed) return;
    signOutOrFailure.when(_clearSession, _emitFailure);
  }

  void _onAuthChanged(AuthUser? user) {
    // Invalidiert alle noch laufenden Verifys.
    _verifyGeneration++;
    if (user == null) {
      _emitSession(const AuthSessionState(currentUser: null));
      return;
    }
    _startVerify(user);
  }

  /// Wartet auf das Firestore-Profil mit Backoff, damit ein SignUp-Race
  /// zwischen Firebase Auth und dem `ensureProfile`-Write nicht in einen
  /// leeren Drawer / `invalidEmail`-Fehler mündet.
  Future<void> _startVerify(AuthUser user) async {
    final generation = ++_verifyGeneration;
    _emitSession(
      const AuthSessionState(
        currentUser: null,
        status: AuthSessionStatus.verifying,
      ),
    );
    final ok = await _profileReady(user, generation);
    if (isClosed || generation != _verifyGeneration) return;
    if (ok) {
      _emitSession(AuthSessionState(currentUser: user));
      return;
    }
    // Firestore-Profil ist auch nach Retries nicht bereit. Wir loggen den
    // User wieder aus, damit er nicht in einer App ohne Profil landet, und
    // zeigen eine sprechende Meldung.
    await signOutUseCase();
    if (isClosed || generation != _verifyGeneration) return;
    _emitSession(
      const AuthSessionState(
        currentUser: null,
        status: AuthSessionStatus.failure,
        message:
            'Konto konnte nicht vollständig eingerichtet werden. '
            'Bitte versuche es erneut.',
      ),
    );
  }

  Future<bool> _profileReady(AuthUser user, int generation) async {
    for (var attempt = 0; attempt < _maxProfileRetries; attempt++) {
      if (isClosed || generation != _verifyGeneration) return false;
      final result = await _getUserProfile(user.id);
      final ready = result.when(
        (_) => true,
        // Nur "existiert-noch-nicht"-Fehler rechtfertigen Retry; alles
        // andere (unauthenticated, unknown) ist ein echter Fehler.
        (failure) => _isRetryable(failure) ? false : false,
      );
      if (ready) return true;
      final retryable = result.when((_) => false, _isRetryable);
      if (!retryable) return false;
      await Future.delayed(_retryBaseDelay * (attempt + 1));
    }
    return false;
  }

  bool _isRetryable(UserFailure failure) {
    return switch (failure.kind) {
      // Kurz nach dem Firebase-SignUp existiert das Firestore-Dokument
      // manchmal noch nicht (notFound) oder ist noch pending (invalidEmail
      // aus einem halb-materialisierten Snapshot).
      UserFailureKind.notFound => true,
      UserFailureKind.invalidEmail => true,
      UserFailureKind.unknown => true,
      UserFailureKind.invalidName => false,
      UserFailureKind.unauthenticated => false,
    };
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
    _verifyGeneration++;
    await _subscription.cancel();
    return super.close();
  }
}
