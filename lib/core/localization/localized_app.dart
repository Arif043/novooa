import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Englisch ist Standard und Rückfall; Deutsch und Türkisch kommen hinzu. Ohne
/// gespeicherte Wahl gilt die Gerätesprache, sofern unterstützt.
Widget localizedApp(Widget app) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('de'), Locale('tr')],
    fallbackLocale: const Locale('en'),
    path: 'assets/translations',
    useOnlyLangCode: true,
    child: app,
  );
}
