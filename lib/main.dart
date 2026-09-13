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
import 'core/logging/logger.dart';
import 'core/logging/application_bloc_observer.dart';
import 'core/logging/developer_client_logger.dart';
import 'core/logging/local_runtime_client_logger.dart';
import 'core/network/local_runtime_api_client.dart';
import 'core/network/network_status.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'core/widgets/offline_status_snackbar.dart';
import 'features/auth/presentation/cubits/auth_session_cubit.dart';
import 'features/notifications/infrastructure/datasources/fcm_push_click_bridge.dart';
import 'features/notifications/infrastructure/datasources/push_click_navigation_policy.dart';
import 'features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import 'features/notifications/presentation/widgets/fcm_foreground_notification_listener.dart';
import 'features/licensing/presentation/cubits/local_runtime_license_cubit.dart';
import 'features/activity/infrastructure/datasources/media_input_picker_platform_registration.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  logInfo(
    'Background-Nachricht: ${message.messageId ?? message.data}',
    name: 'fcm',
  );
}

Future<void> main() =>
    runZonedGuarded(_startApplication, _logUncaughtZoneError) ?? Future.value();

Future<void> _startApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  final runtimeProfile = RuntimeProfile.fromEnvironment();
  final pushFirebaseEnabled = await _initializeFirebase(runtimeProfile);
  if (runtimeProfile.isCloud) {
    await FirebaseAppCheck.instance.activate(
      providerWeb: _webAppCheckProvider(),
    );
    configureFirestoreWebCache(FirebaseFirestore.instance);
    if (FirebaseEmulatorConfig.enabled) {
      await const FirebaseEmulatorConfig().connect();
    }
  }
  if (pushFirebaseEnabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  registerMediaInputPickerPlatform();
  configureDependencies(runtimeProfile: runtimeProfile);
  configureClientLogger(
    runtimeProfile.isLocal
        ? LocalRuntimeClientLogger(serviceLocator<LocalRuntimeApiClient>())
        : const DeveloperClientLogger(),
  );
  Bloc.observer = ApplicationBlocObserver();
  _configureErrorLogging();
  if (!runtimeProfile.isLocal && shouldNavigateFromPushClick()) {
    const FcmPushClickBridge().start(_openNotificationData);
  }
  if (pushFirebaseEnabled) {
    unawaited(serviceLocator<FcmBootstrapper>().start());
  }
  runApp(
    MyApp(
      runtimeProfile: runtimeProfile,
      pushFirebaseEnabled: pushFirebaseEnabled,
    ),
  );
}

Future<bool> _initializeFirebase(RuntimeProfile profile) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } on UnsupportedError catch (error, stackTrace) {
    if (profile.isCloud) rethrow;
    logException(
      message: 'Lokale Push-Benachrichtigungen sind nicht konfiguriert.',
      error: error,
      stackTrace: stackTrace,
      name: 'fcm',
    );
    return false;
  }
}

void _logUncaughtZoneError(Object error, StackTrace stackTrace) {
  logException(
    message: 'Unbehandelter asynchroner Fehler.',
    error: error,
    stackTrace: stackTrace,
    name: 'zone',
  );
}

void _configureErrorLogging() {
  FlutterError.onError = (details) {
    logException(
      message: 'Unbehandelter Flutter-Fehler.',
      error: details.exception,
      stackTrace: details.stack,
      name: 'flutter',
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logException(
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
  const MyApp({
    super.key,
    required this.runtimeProfile,
    required this.pushFirebaseEnabled,
  });

  final RuntimeProfile runtimeProfile;
  final bool pushFirebaseEnabled;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _networkStatus = NetworkStatus();

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: 'novooa',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: SyscatTheme.lightTheme,
      darkTheme: SyscatTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: serviceLocator<AppRouter>().router,
      builder: _wrapApplication,
    );
    return MultiBlocProvider(
      providers: [
        if (widget.runtimeProfile.isCloud)
          BlocProvider.value(value: serviceLocator<AuthSessionCubit>()),
        if (widget.runtimeProfile.isLocal)
          BlocProvider.value(value: serviceLocator<LocalRuntimeLicenseCubit>()),
      ],
      child: app,
    );
  }

  Widget _wrapApplication(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    final app = widget.pushFirebaseEnabled
        ? FcmForegroundNotificationListener(
            onNotificationOpened: _openNotificationFromPushClick,
            onForegroundNotificationAction: _openNotification,
            child: content,
          )
        : content;
    return OfflineStatusSnackbar(
      isOnline: _networkStatus.watch(),
      scaffoldMessengerKey: _scaffoldMessengerKey,
      child: app,
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
