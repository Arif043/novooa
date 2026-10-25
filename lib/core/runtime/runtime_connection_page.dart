import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import '../widgets/syscat_auth_layout.dart';
import 'runtime_address_form.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';
import 'runtime_license_form.dart';
import 'runtime_admin_setup_form.dart';
import 'runtime_invitation_form.dart';
import 'runtime_login_form.dart';
import 'runtime_recovery_form.dart';

/// Verbindung, Lizenz, erstes Konto und Anmeldung einer Runtime im Rahmen
/// von [SyscatAuthLayout].
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
          RuntimeConnectionNeedsPassword() => _SignInForm(state: state),
          RuntimeConnectionNeedsLicense(:final endpoint, :final errorMessage) =>
            RuntimeLicenseForm(endpoint: endpoint, errorMessage: errorMessage),
          RuntimeConnectionNeedsPasswordSetup() => RuntimeAdminSetupForm(
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

/// Anmeldung mit Konto, Einladungscode oder Notzugang.
class _SignInForm extends StatelessWidget {
  const _SignInForm({required this.state});

  final RuntimeConnectionNeedsPassword state;

  @override
  Widget build(BuildContext context) {
    final RuntimeConnectionNeedsPassword(:endpoint, :errorMessage) = state;
    return switch (state.mode) {
      RuntimeSignInMode.password => RuntimeLoginForm(
        endpoint: endpoint,
        errorMessage: errorMessage,
      ),
      RuntimeSignInMode.invitation => RuntimeInvitationForm(
        endpoint: endpoint,
        errorMessage: errorMessage,
      ),
      RuntimeSignInMode.recovery => RuntimeRecoveryForm(
        endpoint: endpoint,
        errorMessage: errorMessage,
      ),
    };
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
