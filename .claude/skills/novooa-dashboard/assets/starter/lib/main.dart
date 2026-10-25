import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app/dashboard_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('de'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const DashboardApp(),
    ),
  );
}
