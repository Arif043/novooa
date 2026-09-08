import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/service_locator.dart';
import 'core/config/runtime_profile.dart';
import 'core/firebase/firebase_emulator_config.dart';
import 'core/firebase/firestore_web_cache.dart';
import 'core/logging/syscat_log.dart';
import 'core/network/network_status.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'core/widgets/offline_status_snackbar.dart';
import 'features/auth/presentation/cubits/auth_session_cubit.dart';
import 'features/notifications/infrastructure/datasources/fcm_push_click_bridge.dart';
import 'features/notifications/infrastructure/datasources/push_click_navigation_policy.dart';
import 'features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import 'features/notifications/presentation/widgets/fcm_foreground_notification_listener.dart';
import 'features/activity/infrastructure/datasources/media_input_picker_platform_registration.dart';
import 'firebase_options.dart';
import 'local_runtime_app.dart';

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
  final runtimeProfile = RuntimeProfile.fromEnvironment();
  if (runtimeProfile.isLocal) {
    _configureErrorLogging();
    registerMediaInputPickerPlatform();
    configureDependencies(runtimeProfile: runtimeProfile);
    runApp(const LocalRuntimeApp());
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(providerWeb: _webAppCheckProvider());
  _configureErrorLogging();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  configureFirestoreWebCache(FirebaseFirestore.instance);
  if (FirebaseEmulatorConfig.enabled) {
    await const FirebaseEmulatorConfig().connect();
  }
  registerMediaInputPickerPlatform();
  configureDependencies(runtimeProfile: runtimeProfile);
  if (shouldNavigateFromPushClick()) {
    const FcmPushClickBridge().start(_openNotificationData);
  }
  unawaited(serviceLocator<FcmBootstrapper>().start());
  runApp(const MyApp());
}

void _configureErrorLogging() {
  FlutterError.onError = (details) {
    logSyscatException(
      message: 'Unbehandelter Flutter-Fehler.',
      error: details.exception,
      stackTrace: details.stack,
      name: 'flutter',
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logSyscatException(
      message: 'Unbehandelter Dart-Fehler.',
      error: error,
      stackTrace: stackTrace,
      name: 'flutter',
    );
    return true;
  };
}

WebProvider _webAppCheckProvider() {
  if (kDebugMode) return WebDebugProvider();
  return ReCaptchaV3Provider('6LeIpVotAAAAAJKgujQhyiUZNrNkDxChOSKqXcCz');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _networkStatus = NetworkStatus();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<AuthSessionCubit>(),
      child: MaterialApp.router(
        title: 'novooa',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        theme: SyscatTheme.lightTheme,
        darkTheme: SyscatTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: serviceLocator<AppRouter>().router,
        builder: (context, child) => OfflineStatusSnackbar(
          isOnline: _networkStatus.watch(),
          scaffoldMessengerKey: _scaffoldMessengerKey,
          child: FcmForegroundNotificationListener(
            onNotificationOpened: _openNotificationFromPushClick,
            onForegroundNotificationAction: _openNotification,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

void _openNotification(RemoteMessage message) {
  _openNotificationData(message.data);
}

void _openNotificationFromPushClick(RemoteMessage message) {
  if (shouldNavigateFromPushClick()) _openNotification(message);
}

void _openNotificationData(Map<String, dynamic> data) {
  final runId = data['runId'] as String?;
  final location = Uri(
    path: AppRouter.activity,
    queryParameters: runId == null
        ? null
        : {
            'runId': runId,
            'open': DateTime.now().microsecondsSinceEpoch.toString(),
          },
  );
  serviceLocator<AppRouter>().router.go(location.toString());
}
