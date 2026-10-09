import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
// Nur für Tests: lädt die echten Übersetzungsdateien ohne EasyLocalization-Widget.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';

/// Macht `tr()` in Unit- und Widget-Tests ohne Widget-Baum nutzbar.
void loadTestTranslations(Locale locale) {
  final file = File('assets/translations/${locale.languageCode}.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  Localization.load(locale, translations: Translations(json));
}

Future<void> initializeTestLocalization({
  Locale locale = const Locale('de'),
}) async {
  await EasyLocalization.ensureInitialized();
  loadTestTranslations(locale);
}
