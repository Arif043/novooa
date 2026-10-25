import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/runtime_user.dart';
import '../../domain/entities/runtime_user_failure.dart';
import '../../domain/repositories/runtime_user_repository.dart';
import 'runtime_user_json_mapper.dart';

/// Konten der lokalen Runtime über deren HTTP-API.
class LocalRuntimeUserRepository implements RuntimeUserRepository {
  const LocalRuntimeUserRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Future<Result<RuntimeUser, RuntimeUserFailure>> currentUser() => _attempt(
    () async => runtimeUserFromJson(await _client.get('/v1/auth/me')),
  );

  @override
  Stream<RuntimeUserOverview> watchUsers() => watchWorkspaceChannel(
    'users',
    () async => runtimeUserOverviewFromJson(await _client.get('/v1/users')),
    _channel,
  );

  @override
  Future<Result<CreatedRuntimeUser, RuntimeUserFailure>> createUser(
    NewRuntimeUser user,
  ) => _attempt(
    () async => createdRuntimeUserFromJson(
      await _client.post('/v1/users', newRuntimeUserToJson(user)),
    ),
  );

  @override
  Future<Result<RuntimeUser, RuntimeUserFailure>> changeRole(
    String uid,
    RuntimeRole role,
  ) => _attempt(
    () async => runtimeUserFromJson(
      await _client.put(_userPath(uid), {'role': role.name}),
    ),
  );

  @override
  Future<Result<UserInvitation, RuntimeUserFailure>> resetPassword(
    String uid,
  ) => _attempt(
    () async => userInvitationFromJson(
      await _client.post('${_userPath(uid)}/invitation', const {}),
    ),
  );

  @override
  Future<Result<Unit, RuntimeUserFailure>> deleteUser(String uid) =>
      _attempt(() async {
        await _client.delete(_userPath(uid));
        return unit;
      });

  String _userPath(String uid) => '/v1/users/${Uri.encodeComponent(uid)}';

  Future<Result<T, RuntimeUserFailure>> _attempt<T extends Object>(
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(runtimeUserFailureFor(error.errorCode, error.message));
    } on Object {
      return const Error(
        RuntimeUserFailure(RuntimeUserFailureKind.unavailable),
      );
    }
  }
}
