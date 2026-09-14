import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/runtime_license_cubit.dart';
import '../cubits/runtime_license_state.dart';

class RuntimeActivationPage extends StatefulWidget {
  const RuntimeActivationPage({super.key});

  @override
  State<RuntimeActivationPage> createState() => _RuntimeActivationPageState();
}

class _RuntimeActivationPageState extends State<RuntimeActivationPage> {
  String _licenseKey = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RuntimeLicenseCubit, RuntimeLicenseCubitState>(
      builder: (context, state) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _contentFor(context, state),
          ),
        ),
      ),
    );
  }

  Widget _contentFor(BuildContext context, RuntimeLicenseCubitState state) {
    return switch (state) {
      RuntimeLicenseLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      RuntimeLicenseActivating() => const Center(
        child: CircularProgressIndicator(),
      ),
      RuntimeLicenseActive() => const SizedBox.shrink(),
      RuntimeLicenseNeedsActivation() => _activationForm(context),
      RuntimeLicenseFailureState(:final failure) => _activationForm(
        context,
        message: failure.message,
      ),
    };
  }

  Widget _activationForm(BuildContext context, {String? message}) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Runtime aktivieren', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Gib den zwölfstelligen Lizenzschlüssel für diesen Arbeitsbereich ein.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 14,
          onChanged: (value) => _licenseKey = value,
          onSubmitted: (_) => _activate(context),
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            counterText: '',
            labelText: 'Lizenzschlüssel',
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () => _activate(context),
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Aktivieren'),
        ),
      ],
    );
  }

  void _activate(BuildContext context) {
    context.read<RuntimeLicenseCubit>().activate(_licenseKey);
  }
}
