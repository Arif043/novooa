import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/widgets/open_authorization_page.dart';

import '../cubits/google_accounts_cubit.dart';

/// Öffnet Google-Anmeldung und Picker im Browser. Mit [loginHint] wird ein
/// bekanntes Konto vorgewählt (weitere Dateien freigeben, neu verbinden).
Future<void> startGoogleAuthorization(
  BuildContext context, {
  String? loginHint,
}) {
  final cubit = context.read<GoogleAccountsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  return openAuthorizationPage(context, () async {
    final url = await cubit.beginAuthorization(loginHint: loginHint);
    if (url == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(LocaleKeys.google_drive_start_failed.tr())),
      );
    }
    return url;
  });
}
