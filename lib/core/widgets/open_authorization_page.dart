import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/locale_keys.g.dart';

/// Öffnet die Anmeldeseite eines Anbieters (Microsoft, Google) im Browser.
/// Das Ergebnis kommt nicht hierher zurück: Die Runtime erfährt es über ihr
/// Wake-up und meldet die geänderte Liste.
Future<void> openAuthorizationPage(
  BuildContext context,
  Future<String?> Function() authorizationUrl,
) async {
  final url = await authorizationUrl();
  if (url == null || !context.mounted) return;
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LocaleKeys.ui_authorization_page_open_failed.tr()),
      ),
    );
  }
}
