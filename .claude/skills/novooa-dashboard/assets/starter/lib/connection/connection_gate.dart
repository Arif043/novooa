import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/dashboard_dependencies.dart';
import '../app/dashboard_shell.dart';
import 'connection_page.dart';

/// Meldet genauso an wie das offizielle Frontend (`RuntimeConnectionCubit`
/// aus `novooa_runtime_client`) und zeigt danach das Dashboard.
class ConnectionGate extends StatefulWidget {
  const ConnectionGate({super.key});

  @override
  State<ConnectionGate> createState() => _ConnectionGateState();
}

class _ConnectionGateState extends State<ConnectionGate> {
  final _credentials = createRuntimeCredentialStore();
  final _sessionEvents = RuntimeSessionEvents();
  late final RuntimeConnectionCubit _connection = RuntimeConnectionCubit(
    RuntimeEndpointPreferences(SharedPreferencesAsync()),
    _credentials,
    const HttpRuntimeLoginClient(),
    const HttpRuntimeAvailability(),
    onboarding: const HttpRuntimeOnboardingClient(),
    onSignedOut: _restartAfterSignOut,
  );
  late final StreamSubscription<void> _sessionEnded;
  DashboardDependencies? _dependencies;

  @override
  void initState() {
    super.initState();
    _sessionEnded = _sessionEvents.sessionEnded.listen(
      (_) => _onSessionEnded(),
    );
    unawaited(_connect());
  }

  /// Desktop und Mobil fragen beim ersten Start nach der Adresse; im Web
  /// gilt `--dart-define=WORKSPACE_API_URL`, sonst die eigene Herkunft.
  Future<void> _connect() {
    final profile = RuntimeProfile.fromEnvironment();
    return _connection.initialize(
      RuntimeEndpoint.fromUri(profile.workspaceApiUri),
    );
  }

  /// Abmelden vergisst Sitzung und Adresse; danach beginnt alles von vorn.
  Future<void> _restartAfterSignOut() async {
    await _dropDependencies();
    await _connect();
  }

  @override
  void dispose() {
    unawaited(_sessionEnded.cancel());
    unawaited(_dropDependencies());
    unawaited(_connection.close());
    unawaited(_sessionEvents.close());
    super.dispose();
  }

  /// Ein abgelaufenes Token: zurück zur Anmeldung, Adresse bleibt.
  Future<void> _onSessionEnded() async {
    await _dropDependencies();
    await _connection.handleSessionEnded();
  }

  Future<void> _dropDependencies() async {
    final dependencies = _dependencies;
    _dependencies = null;
    await dependencies?.dispose();
  }

  DashboardDependencies _dependenciesFor(RuntimeEndpoint endpoint) =>
      _dependencies ??= DashboardDependencies(
        endpoint: endpoint,
        credentials: _credentials,
        sessionEvents: _sessionEvents,
      );

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _connection,
      child: BlocBuilder<RuntimeConnectionCubit, RuntimeConnectionState>(
        builder: (context, state) => switch (state) {
          RuntimeConnectionReady(:final endpoint) => DashboardShell(
            dependencies: _dependenciesFor(endpoint),
          ),
          _ => const ConnectionPage(),
        },
      ),
    );
  }
}
