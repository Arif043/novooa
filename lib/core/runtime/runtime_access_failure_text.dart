import 'package:easy_localization/easy_localization.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../localization/locale_keys.g.dart';

/// Der Text einer [RuntimeAccessFailure] aus dem Client-Paket; die einzige
/// Stelle, an der die App Verbindungs- und Anmeldefehler formuliert.
extension RuntimeAccessFailureText on RuntimeAccessFailure {
  String get text => switch (kind) {
    RuntimeAccessFailureKind.invalidAddress =>
      LocaleKeys.runtime_access_invalid_address.tr(),
    RuntimeAccessFailureKind.savedAddressUnreadable =>
      LocaleKeys.runtime_access_saved_address_unreadable.tr(),
    RuntimeAccessFailureKind.unreachable =>
      LocaleKeys.runtime_access_unreachable.tr(),
    RuntimeAccessFailureKind.certificateInvalid =>
      LocaleKeys.runtime_access_certificate_invalid.tr(),
    RuntimeAccessFailureKind.invalidCredentials =>
      LocaleKeys.runtime_access_invalid_credentials.tr(),
    RuntimeAccessFailureKind.invalidInvitation =>
      LocaleKeys.runtime_access_invalid_invitation.tr(),
    RuntimeAccessFailureKind.licenseTokenMismatch =>
      LocaleKeys.runtime_access_license_token_mismatch.tr(),
    RuntimeAccessFailureKind.adminNotFound =>
      LocaleKeys.runtime_access_admin_not_found.tr(),
    RuntimeAccessFailureKind.invalidPassword =>
      LocaleKeys.runtime_access_invalid_password.tr(),
    RuntimeAccessFailureKind.notLicensed =>
      LocaleKeys.runtime_access_not_licensed.tr(),
    RuntimeAccessFailureKind.tooManyAttempts =>
      LocaleKeys.runtime_access_too_many_attempts.tr(),
    RuntimeAccessFailureKind.noToken => LocaleKeys.runtime_access_no_token.tr(),
    RuntimeAccessFailureKind.failedWithStatus =>
      LocaleKeys.runtime_access_failed_with_status.tr(args: ['$statusCode']),
    RuntimeAccessFailureKind.sessionEnded =>
      LocaleKeys.runtime_access_session_ended.tr(),
    RuntimeAccessFailureKind.signOutFailed =>
      LocaleKeys.runtime_access_sign_out_failed.tr(),
    RuntimeAccessFailureKind.activationFailed =>
      LocaleKeys.runtime_access_activation_failed.tr(),
    RuntimeAccessFailureKind.activationTimeout =>
      LocaleKeys.runtime_access_activation_timeout.tr(),
    RuntimeAccessFailureKind.setupFailed =>
      LocaleKeys.runtime_setup_failed.tr(),
    RuntimeAccessFailureKind.setupAlreadyDone =>
      LocaleKeys.runtime_setup_already_done.tr(),
    RuntimeAccessFailureKind.rejectedByRuntime =>
      detail ?? LocaleKeys.runtime_setup_failed.tr(),
    RuntimeAccessFailureKind.unexpected =>
      LocaleKeys.ui_anmeldung_fehlgeschlagen_mit_grund.tr(args: ['$detail']),
  };
}
