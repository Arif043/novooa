import 'package:multiple_result/multiple_result.dart';

import '../entities/auth_failure.dart';
import '../repositories/auth_repository.dart';

class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<Unit, AuthFailure>> call() {
    return _repository.signOut();
  }
}