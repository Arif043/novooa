import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_out.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_state.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/get_user_profile.dart';

class _SessionAuthRepository implements AuthRepository {
  _SessionAuthRepository(this._currentUser);

  AuthUser? _currentUser;
  int signOutCalls = 0;
  final controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? currentUser() => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => controller.stream;

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    return Result.success(_userWithEmail(email.value));
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    return Result.success(_userWithEmail(email.value));
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    signOutCalls++;
    _currentUser = null;
    return const Result.success(unit);
  }

  Future<void> close() => controller.close();
}

/// Antwortet konfigurierbar: erst n-mal `notFound`, danach Success.
class _ScriptedUserRepository implements UserRepository {
  _ScriptedUserRepository({
    this.notFoundCount = 0,
    this.failPermanently = false,
  });

  int notFoundCount;
  bool failPermanently;
  int getProfileCalls = 0;

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    return const Result.error(UserFailure(UserFailureKind.notFound));
  }

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    getProfileCalls++;
    if (failPermanently) {
      return const Result.error(UserFailure(UserFailureKind.notFound));
    }
    if (notFoundCount > 0) {
      notFoundCount--;
      return const Result.error(UserFailure(UserFailureKind.notFound));
    }
    return Result.success(_profile(id));
  }
}

AuthSessionCubit _cubitWith(
  _SessionAuthRepository authRepository,
  _ScriptedUserRepository userRepository, {
  int maxProfileRetries = 4,
}) {
  return AuthSessionCubit(
    authRepository: authRepository,
    signOutUseCase: SignOut(authRepository),
    getUserProfileUseCase: GetUserProfile(userRepository),
    retryBaseDelay: const Duration(milliseconds: 1),
    maxProfileRetries: maxProfileRetries,
  );
}

void main() {
  group('AuthSessionCubit', () {
    test('durchläuft verifying bevor currentUser gesetzt wird', () async {
      final repository = _SessionAuthRepository(null);
      final userRepository = _ScriptedUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      final statuses = cubit.stream
          .map((state) => state.status)
          .distinct()
          .take(2)
          .toList();
      repository.controller.add(_user());
      final observed = await statuses;
      expect(observed, [AuthSessionStatus.verifying, AuthSessionStatus.ready]);
      expect(cubit.state.currentUser?.email, 'ada@example.com');
      await cubit.close();
      await repository.close();
    });

    test(
      'wartet mit Backoff auf spät geschriebenes Firestore-Profil',
      () async {
        final repository = _SessionAuthRepository(null);
        final userRepository = _ScriptedUserRepository(notFoundCount: 2);
        final cubit = _cubitWith(repository, userRepository);
        final readyState = cubit.stream.firstWhere(
          (state) => state.status == AuthSessionStatus.ready,
        );
        repository.controller.add(_user());
        await readyState;
        expect(userRepository.getProfileCalls, greaterThanOrEqualTo(3));
        expect(cubit.state.currentUser?.email, 'ada@example.com');
        await cubit.close();
        await repository.close();
      },
    );

    test(
      'loggt aus und meldet Failure wenn das Profil dauerhaft fehlt',
      () async {
        final repository = _SessionAuthRepository(null);
        final userRepository = _ScriptedUserRepository(failPermanently: true);
        final cubit = _cubitWith(
          repository,
          userRepository,
          maxProfileRetries: 2,
        );
        final failureState = cubit.stream.firstWhere(
          (state) => state.status == AuthSessionStatus.failure,
        );
        repository.controller.add(_user());
        await failureState;
        expect(cubit.state.currentUser, isNull);
        expect(repository.signOutCalls, 1);
        expect(cubit.state.message, contains('nicht vollständig eingerichtet'));
        await cubit.close();
        await repository.close();
      },
    );

    test('setzt Session sofort auf null bei Sign-out-Event', () async {
      final repository = _SessionAuthRepository(_user());
      final userRepository = _ScriptedUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      // Warte, bis der initiale Verify-Cycle durchgelaufen ist.
      await cubit.stream.firstWhere(
        (state) => state.status == AuthSessionStatus.ready,
      );
      final nextState = cubit.stream.first;
      repository.controller.add(null);
      final observed = await nextState;
      expect(observed.currentUser, isNull);
      expect(observed.status, AuthSessionStatus.ready);
      await cubit.close();
      await repository.close();
    });

    test('delegiert signOut und leert die Session', () async {
      final repository = _SessionAuthRepository(_user());
      final userRepository = _ScriptedUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      await cubit.stream.firstWhere(
        (state) => state.status == AuthSessionStatus.ready,
      );
      await cubit.signOut();
      expect(repository.signOutCalls, 1);
      expect(cubit.state.currentUser, isNull);
      await cubit.close();
      await repository.close();
    });
  });
}

AuthUser _user() => _userWithEmail('ada@example.com');

AuthUser _userWithEmail(String email) {
  return AuthUser(
    id: const UniqueId('user.1'),
    email: email,
    displayName: 'Ada',
  );
}

UserProfile _profile(UniqueId id) {
  return UserProfile(
    id: id,
    email: UserEmail.tryCreate('ada@example.com')!,
    displayName: 'Ada',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}
