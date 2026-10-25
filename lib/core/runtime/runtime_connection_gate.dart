import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_profile.dart';
import '../di/service_locator.dart';
import '../network/workspace_realtime_channel.dart';
import '../theme/syscat_theme.dart';
import 'http_runtime_availability.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_page.dart';
import 'runtime_connection_state.dart';
import 'runtime_credential_store_factory.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_preferences.dart';
import 'runtime_login_client.dart';
import 'runtime_onboarding_client.dart';
import 'runtime_session_events.dart';

class RuntimeConnectionGate extends StatefulWidget {
  const RuntimeConnectionGate({
    super.key,
    required this.runtimeProfile,
    required this.configureApplication,
    required this.createApplication,
    required this.onFullReset,
    this.onSignedInAgain,
  });

  final RuntimeProfile runtimeProfile;
  final Future<void> Function(RuntimeProfile) configureApplication;
  final Widget Function(RuntimeProfile) createApplication;

  /// Abmelden vergisst Sitzung und Adresse vollständig
  /// (siehe `RuntimeConnectionCubit.signOut`) — dieser Callback baut die
  /// Anwendung danach neu auf (DI-Reset + erneuter Boot-Versuch).
  final Future<void> Function() onFullReset;

  /// Nach einem Sitzungsende meldet sich womöglich eine andere Person an;
  /// die App bleibt bestehen, lädt aber ihr Konto neu.
  final Future<void> Function()? onSignedInAgain;

  @override
  State<RuntimeConnectionGate> createState() => _RuntimeConnectionGateState();
}

class _RuntimeConnectionGateState extends State<RuntimeConnectionGate> {
  late final RuntimeConnectionCubit _cubit;
  final RuntimeSessionEvents _sessionEvents = RuntimeSessionEvents();
  late final StreamSubscription<void> _sessionEndedSubscription;

  /// Wird genau einmal pro Prozesslaufzeit gebaut (siehe [_startApplication])
  /// — die Dependency-Injection registriert Singletons und verträgt kein
  /// zweites `configureApplication`. Ein erneutes Anmelden nach
  /// [RuntimeConnectionCubit.signOut] zeigt deshalb dieselbe Instanz wieder,
  /// statt die App neu aufzubauen.
  Widget? _application;
  bool _isStartingApplication = false;

  @override
  void initState() {
    super.initState();
    _cubit = RuntimeConnectionCubit(
      RuntimeEndpointPreferences(SharedPreferencesAsync()),
      createRuntimeCredentialStore(),
      const HttpRuntimeLoginClient(),
      const HttpRuntimeAvailability(),
      onboarding: const HttpRuntimeOnboardingClient(),
      // Erst ab der ersten erfolgreichen Verbindung registriert (siehe
      // `_startApplication`) — signOut() ist aber ohnehin erst erreichbar,
      // nachdem die App-Oberfläche (und damit die DI) schon steht.
      onSignedOut: () async {
        serviceLocator<WorkspaceRealtimeChannel>().close();
        await widget.onFullReset();
      },
    );
    _sessionEndedSubscription = _sessionEvents.sessionEnded.listen(
      (_) => unawaited(_onSessionEnded()),
    );
    unawaited(
      _cubit.initialize(
        RuntimeEndpoint.fromUri(widget.runtimeProfile.workspaceApiUri),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_sessionEndedSubscription.cancel());
    unawaited(_sessionEvents.close());
    _cubit.close();
    super.dispose();
  }

  /// Der Realtime-Kanal würde sonst mit dem ungültigen Token immer wieder ein
  /// Ticket anfordern; nach der erneuten Anmeldung baut ihn `watch()` neu auf.
  Future<void> _onSessionEnded() async {
    if (_cubit.state is! RuntimeConnectionReady) return;
    await serviceLocator<WorkspaceRealtimeChannel>().close();
    await _cubit.handleSessionEnded();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RuntimeConnectionCubit, RuntimeConnectionState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final application = _application;
          if (state is RuntimeConnectionReady && application != null) {
            return application;
          }
          return MaterialApp(
            title: 'novooa',
            debugShowCheckedModeBanner: false,
            theme: SyscatTheme.lightTheme,
            darkTheme: SyscatTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const RuntimeConnectionPage(),
          );
        },
      ),
    );
  }

  void _onStateChanged(BuildContext context, RuntimeConnectionState state) {
    if (state is! RuntimeConnectionReady) {
      // Betrifft insbesondere ein per Abmelden erzwungenes
      // RuntimeConnectionNeedsPassword: die nächste erfolgreiche Anmeldung
      // muss wieder als "Ready" behandelt werden können.
      _isStartingApplication = false;
      return;
    }
    if (_isStartingApplication) return;
    unawaited(_startApplication(state.endpoint));
  }

  Future<void> _startApplication(RuntimeEndpoint endpoint) async {
    _isStartingApplication = true;
    if (_application != null) {
      await widget.onSignedInAgain?.call();
      if (mounted) setState(() {});
      return;
    }
    final profile = widget.runtimeProfile.withWorkspaceApiUri(endpoint.apiUri);
    if (!serviceLocator.isRegistered<RuntimeSessionEvents>()) {
      serviceLocator.registerSingleton<RuntimeSessionEvents>(_sessionEvents);
    }
    await widget.configureApplication(profile);
    if (!mounted) return;
    setState(() => _application = widget.createApplication(profile));
  }
}
