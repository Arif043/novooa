import 'dart:async';

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
import 'runtime_credential_store.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_preferences.dart';
import 'runtime_login_client.dart';
import 'runtime_onboarding_client.dart';

class RuntimeConnectionGate extends StatefulWidget {
  const RuntimeConnectionGate({
    super.key,
    required this.runtimeProfile,
    required this.configureApplication,
    required this.createApplication,
  });

  final RuntimeProfile runtimeProfile;
  final Future<void> Function(RuntimeProfile) configureApplication;
  final Widget Function(RuntimeProfile) createApplication;

  @override
  State<RuntimeConnectionGate> createState() => _RuntimeConnectionGateState();
}

class _RuntimeConnectionGateState extends State<RuntimeConnectionGate> {
  late final RuntimeConnectionCubit _cubit;

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
      SecureRuntimeCredentialStore(),
      const HttpRuntimeLoginClient(),
      const HttpRuntimeAvailability(),
      onboarding: const HttpRuntimeOnboardingClient(),
      // Erst ab der ersten erfolgreichen Verbindung registriert (siehe
      // `_startApplication`) — signOut() ist aber ohnehin erst erreichbar,
      // nachdem die App-Oberfläche (und damit die DI) schon steht.
      onSignedOut: () => serviceLocator<WorkspaceRealtimeChannel>().close(),
    );
    unawaited(
      _cubit.initialize(
        RuntimeEndpoint.fromUri(widget.runtimeProfile.workspaceApiUri),
      ),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
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
      setState(() {});
      return;
    }
    final profile = widget.runtimeProfile.withWorkspaceApiUri(endpoint.apiUri);
    await widget.configureApplication(profile);
    if (!mounted) return;
    setState(() => _application = widget.createApplication(profile));
  }
}
