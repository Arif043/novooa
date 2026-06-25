import 'package:multiple_result/multiple_result.dart';

import '../entities/auth_failure.dart';
import '../entities/auth_user.dart';
import '../entities/email_address.dart';

abstract interface class AuthRepository {
  AuthUser? currentUser();

  Stream<AuthUser?> authStateChanges();

  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  });
}
