import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../connection/connection_gate.dart';
import 'dashboard_config.dart';
import 'dashboard_theme.dart';

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: DashboardConfig.title,
      debugShowCheckedModeBanner: false,
      theme: DashboardTheme.light(),
      darkTheme: DashboardTheme.dark(),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const ConnectionGate(),
    );
  }
}
