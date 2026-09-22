import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runtime_profile.dart';
import '../theme/syscat_theme.dart';
import 'http_runtime_availability.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_page.dart';
import 'runtime_connection_state.dart';
import 'runtime_credential_store.dart';
import 'runtime_endpoint.dart';
import 'runtime_endpoint_preferences.dart';
import 'runtime_login_client.dart';

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
    final application = _application;
    if (application != null) return application;
    return BlocProvider.value(
      value: _cubit,
      child: MaterialApp(
        title: 'novooa',
        debugShowCheckedModeBanner: false,
        theme: SyscatTheme.lightTheme,
        darkTheme: SyscatTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: BlocListener<RuntimeConnectionCubit, RuntimeConnectionState>(
          listenWhen: (_, state) =>
              state is RuntimeConnectionReady && !_isStartingApplication,
          listener: (_, state) {
            final endpoint = (state as RuntimeConnectionReady).endpoint;
            unawaited(_startApplication(endpoint));
          },
          child: const RuntimeConnectionPage(),
        ),
      ),
    );
  }

  Future<void> _startApplication(RuntimeEndpoint endpoint) async {
    _isStartingApplication = true;
    final profile = widget.runtimeProfile.withWorkspaceApiUri(endpoint.apiUri);
    await widget.configureApplication(profile);
    if (!mounted) return;
    setState(() => _application = widget.createApplication(profile));
  }
}
