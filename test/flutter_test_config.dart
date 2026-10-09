import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_translations.dart';

/// Alle Tests laufen standardmäßig mit deutschen Texten; so bleiben
/// bestehende `find.text('…')`-Erwartungen gültig.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  EasyLocalization.logger.enableLevels = [];
  await initializeTestLocalization();
  await testMain();
}
