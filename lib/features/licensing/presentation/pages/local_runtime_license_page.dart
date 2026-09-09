import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/local_runtime_license_cubit.dart';
import '../cubits/local_runtime_license_state.dart';

class LocalRuntimeLicensePage extends StatefulWidget {
  const LocalRuntimeLicensePage({super.key});

  @override
  State<LocalRuntimeLicensePage> createState() =>
      _LocalRuntimeLicensePageState();
}

class _LocalRuntimeLicensePageState extends State<LocalRuntimeLicensePage> {
  String _licenseKey = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalRuntimeLicenseCubit, LocalRuntimeLicenseCubitState>(
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

  Widget _contentFor(
    BuildContext context,
    LocalRuntimeLicenseCubitState state,
  ) {
    return switch (state) {
      LocalRuntimeLicenseLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      LocalRuntimeLicenseActivating() => const Center(
        child: CircularProgressIndicator(),
      ),
      LocalRuntimeLicenseActive() => const SizedBox.shrink(),
      LocalRuntimeLicenseNeedsActivation() => _activationForm(context),
      LocalRuntimeLicenseFailureState(:final failure) => _activationForm(
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
        Text('Lokale Runtime aktivieren', style: theme.textTheme.headlineSmall),
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
    context.read<LocalRuntimeLicenseCubit>().activate(_licenseKey);
  }
}
