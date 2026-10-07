import 'package:multiple_result/multiple_result.dart';

import '../entities/new_password.dart';
import '../entities/password_failure.dart';

abstract interface class PasswordRepository {
  Future<Result<Unit, PasswordFailure>> updatePassword(NewPassword password);
}
