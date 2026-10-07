import 'package:multiple_result/multiple_result.dart';

import '../entities/new_password.dart';
import '../entities/password_failure.dart';
import '../repositories/password_repository.dart';

class SetNewPassword {
  const SetNewPassword(this._repository);

  final PasswordRepository _repository;

  Future<Result<Unit, PasswordFailure>> call(String value) async {
    final password = NewPassword.parse(value);
    if (password == null) return const Error(PasswordFailure.invalidPassword);
    return _repository.updatePassword(password);
  }
}
