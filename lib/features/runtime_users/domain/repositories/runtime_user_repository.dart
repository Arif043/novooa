import 'package:multiple_result/multiple_result.dart';

import '../entities/runtime_user.dart';
import '../entities/runtime_user_failure.dart';

abstract interface class RuntimeUserRepository {
  /// Das angemeldete Konto.
  Future<Result<RuntimeUser, RuntimeUserFailure>> currentUser();

  /// Alle Konten; aktualisiert sich, wenn sich Konten ändern.
  Stream<RuntimeUserOverview> watchUsers();

  Future<Result<CreatedRuntimeUser, RuntimeUserFailure>> createUser(
    NewRuntimeUser user,
  );

  Future<Result<RuntimeUser, RuntimeUserFailure>> changeRole(
    String uid,
    RuntimeRole role,
  );

  /// Das alte Passwort gilt nicht mehr; liefert einen neuen Einladungscode.
  Future<Result<UserInvitation, RuntimeUserFailure>> resetPassword(String uid);

  Future<Result<Unit, RuntimeUserFailure>> deleteUser(String uid);
}
