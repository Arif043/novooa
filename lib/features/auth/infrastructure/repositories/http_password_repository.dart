import 'dart:async';

import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/new_password.dart';
import '../../domain/entities/password_failure.dart';
import '../../domain/repositories/password_repository.dart';

class HttpPasswordRepository implements PasswordRepository {
  const HttpPasswordRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<Result<Unit, PasswordFailure>> updatePassword(
    NewPassword password,
  ) async {
    try {
      await _client.put('/v1/auth/password', {'password': password.value});
      return const Success(unit);
    } on WorkspaceHttpException catch (error) {
      return Error(_failureFor(error.statusCode));
    } on WorkspaceConnectionException {
      return const Error(PasswordFailure.network);
    } on TimeoutException {
      return const Error(PasswordFailure.network);
    } on Object {
      return const Error(PasswordFailure.unexpected);
    }
  }

  PasswordFailure _failureFor(int status) => switch (status) {
    400 => PasswordFailure.invalidPassword,
    401 => PasswordFailure.signInRequired,
    429 => PasswordFailure.rateLimited,
    _ => PasswordFailure.unexpected,
  };
}
