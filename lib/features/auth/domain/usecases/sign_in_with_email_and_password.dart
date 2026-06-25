import 'package:multiple_result/multiple_result.dart';

import '../entities/auth_failure.dart';
import '../entities/auth_user.dart';
import '../entities/email_address.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final EmailAddress email;
  final String password;
}

class SignInWithEmailAndPassword {
  const SignInWithEmailAndPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser, AuthFailure>> call(SignInParams params) {
    return _repository.signIn(email: params.email, password: params.password);
  }
}
