import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/di/service_locator.dart';
import 'core/firebase/firebase_emulator_config.dart';
import 'core/logging/syscat_log.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logSyscatInfo(
    'Background-Nachricht: ${message.messageId ?? message.data}',
    name: 'fcm',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if (FirebaseEmulatorConfig.enabled) {
    await const FirebaseEmulatorConfig().connect();
  }
  configureDependencies();
  unawaited(serviceLocator<FcmBootstrapper>().start());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Syscat',
      debugShowCheckedModeBanner: false,
      theme: SyscatTheme.lightTheme,
      darkTheme: SyscatTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: serviceLocator<AppRouter>().router,
    );
  }
}
