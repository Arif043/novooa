import 'package:easy_localization/easy_localization.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../l10n/dashboard_keys.dart';

/// Formuliert Fehler aus `novooa_runtime_client` in der Sprache des Dashboards.
extension AccessFailureText on RuntimeAccessFailure {
  String get text => switch (kind) {
    RuntimeAccessFailureKind.invalidAddress ||
    RuntimeAccessFailureKind.savedAddressUnreadable ||
    RuntimeAccessFailureKind.unreachable ||
    RuntimeAccessFailureKind.certificateInvalid ||
    RuntimeAccessFailureKind.invalidCredentials ||
    RuntimeAccessFailureKind.invalidInvitation ||
    RuntimeAccessFailureKind.invalidPassword ||
    RuntimeAccessFailureKind.notLicensed ||
    RuntimeAccessFailureKind.tooManyAttempts ||
    RuntimeAccessFailureKind.sessionEnded ||
    RuntimeAccessFailureKind.signOutFailed => DashboardKeys.failure(
      kind.name,
    ).tr(),
    RuntimeAccessFailureKind.rejectedByRuntime =>
      detail ?? DashboardKeys.failure('other').tr(),
    _ => DashboardKeys.failure('other').tr(),
  };
}
