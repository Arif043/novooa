import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/runtime/license_token_field.dart';
import '../../../../core/runtime/runtime_form_header.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/syscat_auth_layout.dart';
import '../cubits/runtime_license_cubit.dart';
import '../cubits/runtime_license_state.dart';

/// Erscheint in der App, sobald die Lizenz der Runtime fehlt oder abgelaufen
/// ist — im selben Rahmen wie Anmeldung und Einrichtung.
class RuntimeActivationPage extends StatefulWidget {
  const RuntimeActivationPage({super.key});

  @override
  State<RuntimeActivationPage> createState() => _RuntimeActivationPageState();
}

class _RuntimeActivationPageState extends State<RuntimeActivationPage> {
  String _token = '';

  bool get _isComplete => _token.length == LicenseTokenField.length;

  @override
  Widget build(BuildContext context) {
    return SyscatAuthLayout(
      maxCardWidth: SyscatAuthLayout.runtimeCardWidth,
      child: BlocBuilder<RuntimeLicenseCubit, RuntimeLicenseCubitState>(
        builder: (context, state) => switch (state) {
          RuntimeLicenseLoading() || RuntimeLicenseReleasing() => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          RuntimeLicenseActive() => const SizedBox.shrink(),
          RuntimeLicenseActivating() => _activationForm(isBusy: true),
          RuntimeLicenseNeedsActivation() => _activationForm(),
          RuntimeLicenseFailureState(:final failure) => _activationForm(
            errorText: failure.message,
          ),
        },
      ),
    );
  }

  Widget _activationForm({String? errorText, bool isBusy = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RuntimeFormHeader(
          title: 'Lizenz aktivieren',
          description:
              'Die Lizenz dieser Runtime ist nicht aktiv. Gib den Lizenz-Token '
              'für diesen Arbeitsbereich ein.',
        ),
        LicenseTokenField(
          enabled: !isBusy,
          errorText: errorText,
          onChanged: (token) => setState(() => _token = token),
          onSubmitted: _activate,
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(
          label: 'Aktivieren',
          isBusy: isBusy,
          onPressed: _isComplete ? _activate : null,
        ),
      ],
    );
  }

  void _activate() {
    if (!_isComplete) return;
    context.read<RuntimeLicenseCubit>().activate(_token);
  }
}
