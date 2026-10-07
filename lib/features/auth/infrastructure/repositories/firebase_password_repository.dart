import 'package:firebase_auth/firebase_auth.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/new_password.dart';
import '../../domain/entities/password_failure.dart';
import '../../domain/repositories/password_repository.dart';

class FirebasePasswordRepository implements PasswordRepository {
  const FirebasePasswordRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<Result<Unit, PasswordFailure>> updatePassword(
    NewPassword password,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return const Error(PasswordFailure.signInRequired);
    try {
      await user.updatePassword(password.value);
      return const Success(unit);
    } on FirebaseAuthException catch (error) {
      return Error(_failureFor(error.code));
    } on Object {
      return const Error(PasswordFailure.unexpected);
    }
  }

  PasswordFailure _failureFor(String code) => switch (code) {
    'weak-password' => PasswordFailure.invalidPassword,
    'requires-recent-login' => PasswordFailure.recentLoginRequired,
    'user-token-expired' ||
    'invalid-user-token' ||
    'user-disabled' ||
    'user-not-found' => PasswordFailure.signInRequired,
    'network-request-failed' => PasswordFailure.network,
    'too-many-requests' => PasswordFailure.rateLimited,
    _ => PasswordFailure.unexpected,
  };
}
