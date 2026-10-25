import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/google_account.dart';
import 'google_authorization_launcher.dart';

/// Ein verbundenes Google-Konto mit der passenden Folgeaktion: weitere Dateien
/// freigeben oder, bei abgelaufener Anmeldung, neu verbinden.
class GoogleAccountTile extends StatelessWidget {
  const GoogleAccountTile({super.key, required this.account});

  final GoogleAccount account;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final expired = account.needsReauthorization;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        expired ? Icons.error_outline : Icons.account_circle_outlined,
        color: expired ? colors.error : null,
        semanticLabel: expired
            ? LocaleKeys.google_drive_reauthorization_required.tr()
            : null,
      ),
      title: Text(account.email, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        expired
            ? LocaleKeys.google_drive_reauthorization_required.tr()
            : LocaleKeys.google_drive_shared_count.tr(
                namedArgs: {'count': '${account.sharedItems.length}'},
              ),
      ),
      trailing: TextButton(
        onPressed: () =>
            startGoogleAuthorization(context, loginHint: account.email),
        child: Text(
          expired
              ? LocaleKeys.google_drive_reconnect.tr()
              : LocaleKeys.google_drive_share_more.tr(),
        ),
      ),
    );
  }
}
