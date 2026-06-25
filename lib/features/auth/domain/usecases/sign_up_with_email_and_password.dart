import 'package:multiple_result/multiple_result.dart';

import '../entities/auth_failure.dart';
import '../entities/auth_user.dart';
import '../entities/email_address.dart';
import '../repositories/auth_repository.dart';

class SignUpParams {
  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final EmailAddress email;
  final String password;
}

class SignUpWithEmailAndPassword {
  const SignUpWithEmailAndPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser, AuthFailure>> call(SignUpParams params) {
    return _repository.signUp(
      name: params.name.trim(),
      email: params.email,
      password: params.password,
    );
  }
}
