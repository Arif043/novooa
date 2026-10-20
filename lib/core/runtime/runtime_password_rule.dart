import 'package:easy_localization/easy_localization.dart';

import '../localization/locale_keys.g.dart';

/// Gleiche Grenzen wie `RuntimePassword` in der Runtime; die Prüfung hier
/// spart nur den Umweg über eine abgelehnte Anfrage.
const runtimePasswordMinimumLength = 12;
const runtimePasswordMaximumLength = 1000;

/// Meldung zu einem neuen Passwort oder `null`, wenn es passt.
String? runtimeNewPasswordProblem(String password, {String? confirmation}) {
  final length = password.length;
  if (length < runtimePasswordMinimumLength ||
      length > runtimePasswordMaximumLength) {
    return LocaleKeys.runtime_access_invalid_password.tr();
  }
  if (confirmation != null && confirmation != password) {
    return LocaleKeys.runtime_access_passwords_differ.tr();
  }
  return null;
}
