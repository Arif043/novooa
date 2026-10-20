import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/runtime_user.dart';
import '../../domain/entities/runtime_user_failure.dart';

extension RuntimeRoleLabel on RuntimeRole {
  String get label => switch (this) {
    RuntimeRole.admin => LocaleKeys.runtime_users_role_admin.tr(),
    RuntimeRole.member => LocaleKeys.runtime_users_role_member.tr(),
  };
}

extension RuntimeUserFailureMessage on RuntimeUserFailure {
  /// Eingabefehler erklärt die Runtime selbst; alles andere übersetzt die App.
  String get message => switch (kind) {
    RuntimeUserFailureKind.invalidInput =>
      serverMessage ?? LocaleKeys.runtime_users_failure_unavailable.tr(),
    RuntimeUserFailureKind.loginNameTaken =>
      LocaleKeys.runtime_users_failure_login_name_taken.tr(),
    RuntimeUserFailureKind.userLimitReached =>
      LocaleKeys.runtime_users_failure_user_limit_reached.tr(),
    RuntimeUserFailureKind.lastAdmin =>
      LocaleKeys.runtime_users_failure_last_admin.tr(),
    RuntimeUserFailureKind.ownAccount =>
      LocaleKeys.runtime_users_failure_own_account.tr(),
    RuntimeUserFailureKind.workspaceOwner =>
      LocaleKeys.runtime_users_failure_workspace_owner.tr(),
    RuntimeUserFailureKind.notFound =>
      LocaleKeys.runtime_users_failure_not_found.tr(),
    RuntimeUserFailureKind.adminRequired =>
      LocaleKeys.runtime_users_failure_admin_required.tr(),
    RuntimeUserFailureKind.unavailable =>
      LocaleKeys.runtime_users_failure_unavailable.tr(),
  };
}

/// Bis zu zwei Initialen aus dem Namen, sonst aus dem Anmeldenamen.
String initialsOf(RuntimeUser user) {
  final words = user.displayName.trim().split(RegExp(r'\s+'));
  final letters = words.where((word) => word.isNotEmpty).map((word) => word[0]);
  final initials = letters.take(2).join();
  final fallback = user.loginName.isEmpty ? '?' : user.loginName[0];
  return (initials.isEmpty ? fallback : initials).toUpperCase();
}
