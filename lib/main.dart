import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'core/di/service_locator.dart';
import 'core/runtime/push_availability.dart';
import 'core/localization/localized_app.dart';
import 'core/logging/logger.dart';
import 'core/logging/application_bloc_observer.dart';
import 'core/logging/developer_client_logger.dart';
import 'core/logging/workspace_client_logger.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'core/widgets/offline_status_snackbar.dart';
import 'features/runtime_users/presentation/cubits/current_runtime_user_cubit.dart';
import 'features/notifications/infrastructure/datasources/push_click_navigation_policy.dart';
import 'features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import 'features/notifications/presentation/widgets/fcm_foreground_notification_listener.dart';
import 'features/licensing/presentation/cubits/runtime_license_cubit.dart';
import 'core/runtime/runtime_connection_gate.dart';
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

/// Auch der Wiedereinstiegspunkt nach dem Abmelden (siehe `onFullReset`).
/// `WidgetsFlutterBinding.ensureInitialized()` ist dafür mehrfach aufrufbar.
Future<void> _startApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  if (isPushEnabled()) await _initializeFirebase();
  configureClientLogger(const DeveloperClientLogger());
  Bloc.observer = ApplicationBlocObserver();
  _configureErrorLogging();
  registerMediaInputPickerPlatform();
  if (isPushEnabled()) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(
    // Anmeldung und Einrichtung brauchen die Übersetzungen schon vor der App.
    localizedApp(
      RuntimeConnectionGate(
        runtimeProfile: RuntimeProfile.fromEnvironment(),
        configureApplication: _configureApplication,
        createApplication: (_) => const MyApp(),
        // Abmelden vergisst Sitzung und Adresse; danach beginnt alles neu.
        onFullReset: () async {
          await resetDependencies();
          await _startApplication();
        },
        onSignedInAgain: () => serviceLocator<CurrentRuntimeUserCubit>().load(),
      ),
    ),
  );
}

Future<void> _configureApplication(RuntimeProfile runtimeProfile) async {
  await configureDependencies(runtimeProfile: runtimeProfile);
  configureClientLogger(
    WorkspaceClientLogger(serviceLocator<WorkspaceApiClient>()),
  );
  if (isPushEnabled()) {
    unawaited(serviceLocator<FcmBootstrapper>().start());
  }
}

/// Wird nur aufgerufen, wenn [isPushEnabled] true ist — die Plattform ist
/// dann schon berücksichtigt; ein `UnsupportedError` wäre ein echter Bug.
Future<void> _initializeFirebase() async {
  // Nach dem Abmelden durchläuft derselbe Prozess `_startApplication` ein
  // zweites Mal — Firebase lässt sich aber nicht zweimal initialisieren.
  if (Firebase.apps.isNotEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    final app = MaterialApp.router(
      title: 'novooa',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: SyscatTheme.lightTheme,
      // darkTheme: SyscatTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Sprache, Datums- und Zeitauswahl der Material-Widgets folgen easy_localization.
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      routerConfig: serviceLocator<AppRouter>().router,
      builder: _wrapApplication,
    );
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: serviceLocator<RuntimeLicenseCubit>()),
        BlocProvider.value(value: serviceLocator<CurrentRuntimeUserCubit>()),
        BlocProvider.value(value: serviceLocator<PluginsCubit>()),
      ],
      child: app,
    );
  }

  Widget _wrapApplication(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    final app = isPushEnabled()
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
