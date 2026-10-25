import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../app/dashboard_theme.dart';
import '../l10n/dashboard_keys.dart';
import '../shared/async_views.dart';
import 'access_failure_text.dart';
import 'address_form.dart';
import 'setup_required_notice.dart';
import 'sign_in_form.dart';

/// Alles vor dem Dashboard: Adresse, Anmeldung, Einladung. Ersteinrichtung,
/// Lizenz und Notzugang bleiben dem offiziellen Frontend vorbehalten.
class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RuntimeConnectionCubit>().state;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: Spacing.contentMaxWidth,
              ),
              child: _StepFor(state: state),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepFor extends StatelessWidget {
  const _StepFor({required this.state});

  final RuntimeConnectionState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    RuntimeConnectionLoading() ||
    RuntimeConnectionReady() => const LoadingView(),
    RuntimeConnectionConnecting(:final address) => LoadingView(
      label: DashboardKeys.connectionConnecting.tr(
        namedArgs: {'address': address},
      ),
    ),
    RuntimeConnectionNeedsAddress(:final address, :final failure) =>
      AddressForm(address: address, failureText: failure?.text),
    RuntimeConnectionNeedsPassword(:final mode)
        when mode == RuntimeSignInMode.recovery =>
      const SetupRequiredNotice(),
    RuntimeConnectionNeedsPassword(
      :final endpoint,
      :final mode,
      :final failure,
    ) =>
      SignInForm(endpoint: endpoint, mode: mode, failureText: failure?.text),
    RuntimeConnectionNeedsLicense() ||
    RuntimeConnectionNeedsPasswordSetup() => const SetupRequiredNotice(),
    RuntimeConnectionUnreachable(:final endpoint, :final failure) =>
      FailureView(
        message: failure?.text ?? DashboardKeys.connectionUnreachable.tr(),
        onRetry: () => context.read<RuntimeConnectionCubit>().connect(
          endpoint.displayAddress,
        ),
      ),
  };
}
