import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import '../widgets/syscat_auth_layout.dart';
import 'runtime_address_form.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';
import 'runtime_license_form.dart';
import 'runtime_login_form.dart';
import 'runtime_password_setup_form.dart';

/// Verbindung, Lizenz, Passwort-Einrichtung und Anmeldung einer Runtime — im
/// selben Rahmen wie die Cloud-Anmeldung ([SyscatAuthLayout]).
class RuntimeConnectionPage extends StatelessWidget {
  const RuntimeConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SyscatAuthLayout(
      maxCardWidth: SyscatAuthLayout.runtimeCardWidth,
      child: BlocBuilder<RuntimeConnectionCubit, RuntimeConnectionState>(
        builder: (context, state) => switch (state) {
          RuntimeConnectionLoading() ||
          RuntimeConnectionReady() => const _ConnectionLoading(),
          RuntimeConnectionConnecting(:final address) => RuntimeAddressForm(
            address: address,
            isConnecting: true,
          ),
          RuntimeConnectionNeedsAddress(:final address, :final errorMessage) =>
            RuntimeAddressForm(address: address, errorMessage: errorMessage),
          RuntimeConnectionNeedsPassword(
            :final endpoint,
            :final errorMessage,
          ) =>
            RuntimeLoginForm(endpoint: endpoint, errorMessage: errorMessage),
          RuntimeConnectionNeedsLicense(:final endpoint, :final errorMessage) =>
            RuntimeLicenseForm(endpoint: endpoint, errorMessage: errorMessage),
          RuntimeConnectionNeedsPasswordSetup() => RuntimePasswordSetupForm(
            setup: state,
          ),
          RuntimeConnectionUnreachable(:final endpoint, :final errorMessage) =>
            RuntimeUnreachableNotice(
              endpoint: endpoint,
              errorMessage: errorMessage,
            ),
        },
      ),
    );
  }
}

class _ConnectionLoading extends StatelessWidget {
  const _ConnectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Runtime wird verbunden …'),
        ],
      ),
    );
  }
}
