import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_endpoint.dart';

class RuntimeLicenseForm extends StatefulWidget {
  const RuntimeLicenseForm({
    required this.endpoint,
    this.errorMessage,
    super.key,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimeLicenseForm> createState() => _RuntimeLicenseFormState();
}

class _RuntimeLicenseFormState extends State<RuntimeLicenseForm> {
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.workspace_premium_outlined, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Lizenz aktivieren',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Für diese Runtime ist keine gültige Lizenz aktiviert.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _tokenController,
          autocorrect: false,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Lizenz-Token',
            errorText: widget.errorMessage,
            prefixIcon: const Icon(Icons.key_outlined),
          ),
          onSubmitted: (_) => _activate(),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _activate,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Lizenz aktivieren'),
        ),
      ],
    );
  }

  void _activate() {
    context.read<RuntimeConnectionCubit>().activateLicense(
      widget.endpoint,
      _tokenController.text,
    );
  }
}
