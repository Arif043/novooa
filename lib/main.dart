import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/service_locator.dart';
import 'core/runtime/runtime_kind_preferences.dart';
import 'core/runtime/runtime_profile.dart';
import 'core/runtime/runtime_startup_decision.dart';
import 'core/runtime/runtime_variant_switcher.dart';
import 'core/runtime/workspace_capabilities.dart';
import 'core/firebase/firebase_emulator_config.dart';
import 'core/firebase/firestore_web_cache.dart';
import 'core/logging/logger.dart';
import 'core/logging/application_bloc_observer.dart';
import 'core/logging/developer_client_logger.dart';
import 'core/logging/workspace_client_logger.dart';
import 'core/network/workspace_api_client.dart';
import 'core/network/network_status.dart';
import 'core/routing/app_router.dart';
import 'core/theme/syscat_theme.dart';
import 'core/widgets/offline_status_snackbar.dart';
import 'features/auth/presentation/cubits/auth_session_cubit.dart';
import 'features/notifications/infrastructure/datasources/fcm_push_click_bridge.dart';
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

/// Auch der Wiedereinstiegspunkt nach einem vollständigen Reset (siehe
/// `_bootRuntimeKind`s `onFullReset`) — löst die Startentscheidung dann
/// einfach neu auf. `WidgetsFlutterBinding.ensureInitialized()` ist dafür
/// mehrfach aufrufbar gemacht.
Future<void> _startApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  final kind = await resolveStartupRuntimeKind();
  await _bootRuntimeKind(kind);
}

Future<void> _bootRuntimeKind(RuntimeKind kind) async {
  final runtimeProfile = RuntimeProfile.forKind(kind);
  // Einzige Quelle dafür, ob Push aktiv wird: `WorkspaceCapabilities`. Muss
  // hier als reine Funktion gelesen werden (statt aus dem DI-Container),
  // weil `configureDependencies()` — das `WorkspaceCapabilities` erst
  // registriert — von dieser Entscheidung selbst abhängt (Firebase muss vor
  // der Cloud-DI stehen).
  final capabilities = WorkspaceCapabilities.forKind(kind);
  if (capabilities.push) {
    await _initializeFirebase();
  }
  configureClientLogger(const DeveloperClientLogger());
  Bloc.observer = ApplicationBlocObserver();
  _configureErrorLogging();
  registerMediaInputPickerPlatform();
  if (runtimeProfile.isCloud) {
    await _configureCloudPlatform();
  }
  if (capabilities.push) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  if (runtimeProfile.isStandalone) {
    runApp(
      RuntimeVariantSwitcherScope(
        switcher: const _AppRuntimeVariantSwitcher(),
        child: RuntimeConnectionGate(
          runtimeProfile: runtimeProfile,
          configureApplication: _configureApplication,
          createApplication: (profile) => MyApp(runtimeProfile: profile),
          // Abmelden vergisst Sitzung, Adresse und Varianten-Wahl
          // vollständig und ruft diesen Callback. Ein erneutes Auflösen der
          // Startentscheidung landet danach nativ korrekt wieder beim
          // Cloud-Login (mit Wechsel-Hinweis zurück zur eigenen Runtime)
          // oder im Web direkt wieder im Standalone-Fluss — dort gibt die
          // Herkunft die Variante ohnehin fix vor.
          onFullReset: () async {
            await resetDependencies();
            await _startApplication();
          },
        ),
      ),
    );
    return;
  }
  await _configureApplication(runtimeProfile);
  runApp(
    RuntimeVariantSwitcherScope(
      switcher: const _AppRuntimeVariantSwitcher(),
      child: MyApp(runtimeProfile: runtimeProfile),
    ),
  );
}

/// Speichert die neue Wahl, baut die DI zurück und bootet die Anwendung
/// für die neue Variante — alles im selben Prozess. Kein Neustart nötig,
/// weil `configureDependencies` genau für diesen Zweck ein frisches
/// `GetIt` verträgt (`resetDependencies()`) und Firebase nur einmal pro
/// Prozess initialisiert wird (siehe Schutz in `_initializeFirebase`).
class _AppRuntimeVariantSwitcher implements RuntimeVariantSwitcher {
  const _AppRuntimeVariantSwitcher();

  @override
  Future<void> switchTo(RuntimeKind kind) async {
    try {
      await RuntimeKindPreferences(SharedPreferencesAsync()).save(kind);
    } catch (error, stackTrace) {
      logException(
        message: 'Betriebsvariante konnte nicht gespeichert werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'runtime',
      );
    }
    await resetDependencies();
    await _startApplication();
  }
}

Future<void> _configureCloudPlatform() async {
  await FirebaseAppCheck.instance.activate(providerWeb: _webAppCheckProvider());
  configureFirestoreWebCache(FirebaseFirestore.instance);
  if (FirebaseEmulatorConfig.enabled) {
    await const FirebaseEmulatorConfig().connect();
  }
}

Future<void> _configureApplication(RuntimeProfile runtimeProfile) async {
  await configureDependencies(runtimeProfile: runtimeProfile);
  configureClientLogger(
    runtimeProfile.isStandalone
        ? WorkspaceClientLogger(serviceLocator<WorkspaceApiClient>())
        : const DeveloperClientLogger(),
  );
  if (!runtimeProfile.isStandalone && shouldNavigateFromPushClick()) {
    const FcmPushClickBridge().start(_openNotificationData);
  }
  if (serviceLocator<WorkspaceCapabilities>().push) {
    unawaited(serviceLocator<FcmBootstrapper>().start());
  }
}

/// Wird nur aufgerufen, wenn `WorkspaceCapabilities.push` bereits true ist —
/// die Fähigkeit hat die Zielplattform schon berücksichtigt (siehe dort),
/// ein `UnsupportedError` an dieser Stelle wäre also ein echter Bug und darf
/// durchschlagen statt Push still zur Laufzeit zu deaktivieren.
Future<void> _initializeFirebase() async {
  // Nach einem vollständigen Reset (siehe `onFullReset`) kann derselbe
  // Prozess `_bootRuntimeKind` ein zweites Mal durchlaufen — Firebase lässt
  // sich aber nicht zweimal initialisieren.
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

WebProvider _webAppCheckProvider() {
  if (kDebugMode) return WebDebugProvider();
  return ReCaptchaV3Provider('6LeIpVotAAAAAJKgujQhyiUZNrNkDxChOSKqXcCz');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.runtimeProfile});

  final RuntimeProfile runtimeProfile;

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
      // Deutsch: Datums- und Zeitauswahl, Tooltips und Fehlertexte der Material-Widgets.
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: serviceLocator<AppRouter>().router,
      builder: _wrapApplication,
    );
    return MultiBlocProvider(
      providers: [
        if (widget.runtimeProfile.isCloud)
          BlocProvider.value(value: serviceLocator<AuthSessionCubit>()),
        if (widget.runtimeProfile.isStandalone)
          BlocProvider.value(value: serviceLocator<RuntimeLicenseCubit>()),
      ],
      child: app,
    );
  }

  Widget _wrapApplication(BuildContext context, Widget? child) {
    final content = child ?? const SizedBox.shrink();
    final app = serviceLocator<WorkspaceCapabilities>().push
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
