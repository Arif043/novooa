import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/firebase/firebase_emulator_config.dart';
import 'core/logging/syscat_log.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'features/auth/presentation/cubits/auth_session_cubit.dart';
import 'features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import 'features/notifications/presentation/widgets/fcm_foreground_notification_listener.dart';
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
  await FirebaseAppCheck.instance.activate(providerWeb: _webAppCheckProvider());
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if (FirebaseEmulatorConfig.enabled) {
    await const FirebaseEmulatorConfig().connect();
  }
  configureDependencies();
  unawaited(serviceLocator<FcmBootstrapper>().start());
  runApp(const MyApp());
}

WebProvider _webAppCheckProvider() {
  if (kDebugMode) return WebDebugProvider();
  return ReCaptchaV3Provider('6LeIpVotAAAAAJKgujQhyiUZNrNkDxChOSKqXcCz');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<AuthSessionCubit>(),
      child: MaterialApp.router(
        title: 'novooa',
        debugShowCheckedModeBanner: false,
        theme: SyscatTheme.lightTheme,
        darkTheme: SyscatTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: serviceLocator<AppRouter>().router,
        builder: (context, child) => FcmForegroundNotificationListener(
          onNotificationOpened: _openNotification,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

void _openNotification(RemoteMessage message) {
  final runId = message.data['runId'];
  final location = Uri(
    path: AppRouter.activity,
    queryParameters: runId == null ? null : {'runId': runId},
  );
  serviceLocator<AppRouter>().router.go(location.toString());
}
