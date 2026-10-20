import '../../domain/entities/runtime_user.dart';
import '../../domain/entities/runtime_user_failure.dart';

RuntimeUser runtimeUserFromJson(Map<String, Object?> json) => RuntimeUser(
  uid: json['uid'] as String? ?? '',
  loginName: json['loginName'] as String? ?? '',
  displayName: json['displayName'] as String? ?? '',
  role: json['role'] == 'admin' ? RuntimeRole.admin : RuntimeRole.member,
  hasPassword: json['hasPassword'] == true,
);

RuntimeUserOverview runtimeUserOverviewFromJson(Map<String, Object?> json) {
  final items = json['items'] as List<Object?>? ?? const [];
  return RuntimeUserOverview(
    users: [
      for (final item in items.whereType<Map<String, Object?>>())
        runtimeUserFromJson(item),
    ],
    maxUsers: (json['maxUsers'] as num?)?.toInt(),
  );
}

UserInvitation userInvitationFromJson(Map<String, Object?> json) =>
    UserInvitation(
      code: json['code'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );

CreatedRuntimeUser createdRuntimeUserFromJson(Map<String, Object?> json) =>
    CreatedRuntimeUser(
      user: runtimeUserFromJson(json['user'] as Map<String, Object?>? ?? {}),
      invitation: userInvitationFromJson(
        json['invitation'] as Map<String, Object?>? ?? {},
      ),
    );

Map<String, Object?> newRuntimeUserToJson(NewRuntimeUser user) => {
  'displayName': user.displayName.trim(),
  'loginName': user.loginName.trim(),
  'role': user.role.name,
};

/// Der Fehlercode der Runtime bestimmt die Art; unbekannte Codes gelten als
/// nicht erreichbar.
RuntimeUserFailure runtimeUserFailureFor(String? code, String message) {
  final kind = switch (code) {
    'invalid_input' => RuntimeUserFailureKind.invalidInput,
    'login_name_taken' => RuntimeUserFailureKind.loginNameTaken,
    'user_limit_reached' => RuntimeUserFailureKind.userLimitReached,
    'last_admin' => RuntimeUserFailureKind.lastAdmin,
    'own_account' => RuntimeUserFailureKind.ownAccount,
    'workspace_owner' => RuntimeUserFailureKind.workspaceOwner,
    'user_not_found' => RuntimeUserFailureKind.notFound,
    'admin_required' => RuntimeUserFailureKind.adminRequired,
    _ => RuntimeUserFailureKind.unavailable,
  };
  return RuntimeUserFailure(kind, serverMessage: message);
}
