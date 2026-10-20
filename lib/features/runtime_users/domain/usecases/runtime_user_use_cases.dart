import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_user.dart';
import '../entities/runtime_user_failure.dart';
import '../repositories/runtime_user_repository.dart';

class LoadCurrentRuntimeUser {
  const LoadCurrentRuntimeUser(this._repository);

  final RuntimeUserRepository _repository;

  Future<Result<RuntimeUser, RuntimeUserFailure>> call() =>
      _repository.currentUser();
}

class WatchRuntimeUsers {
  const WatchRuntimeUsers(this._repository);

  final RuntimeUserRepository _repository;

  Stream<RuntimeUserOverview> call() => _repository.watchUsers();
}

class CreateRuntimeUser {
  const CreateRuntimeUser(this._repository);

  final RuntimeUserRepository _repository;

  Future<Result<CreatedRuntimeUser, RuntimeUserFailure>> call(
    NewRuntimeUser user,
  ) => _repository.createUser(user);
}

class ChangeRuntimeUserRole {
  const ChangeRuntimeUserRole(this._repository);

  final RuntimeUserRepository _repository;

  Future<Result<RuntimeUser, RuntimeUserFailure>> call(
    String uid,
    RuntimeRole role,
  ) => _repository.changeRole(uid, role);
}

class ResetRuntimeUserPassword {
  const ResetRuntimeUserPassword(this._repository);

  final RuntimeUserRepository _repository;

  Future<Result<UserInvitation, RuntimeUserFailure>> call(String uid) =>
      _repository.resetPassword(uid);
}

class DeleteRuntimeUser {
  const DeleteRuntimeUser(this._repository);

  final RuntimeUserRepository _repository;

  Future<Result<Unit, RuntimeUserFailure>> call(String uid) =>
      _repository.deleteUser(uid);
}
