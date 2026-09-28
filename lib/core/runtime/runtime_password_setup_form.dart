import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_endpoint.dart';

class RuntimePasswordSetupForm extends StatefulWidget {
  const RuntimePasswordSetupForm({
    required this.endpoint,
    this.errorMessage,
    this.requiresCode = false,
    this.addresses = const [],
    super.key,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;
  final bool requiresCode;
  final List<String> addresses;

  @override
  State<RuntimePasswordSetupForm> createState() => _RuntimePasswordSetupFormState();
}

class _RuntimePasswordSetupFormState extends State<RuntimePasswordSetupForm> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final errorMessage = _validationMessage ?? widget.errorMessage;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Zugriffs-Passwort festlegen',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Dieses Passwort schützt den Zugriff auf die lokale Runtime.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (widget.requiresCode) ...[
          TextField(
            controller: _codeController,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Einrichtungscode',
              helperText: 'Steht im Start-Log der Runtime '
                  '(docker compose logs).',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Passwort',
            prefixIcon: Icon(Icons.password_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _confirmationController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Passwort wiederholen',
            errorText: errorMessage,
            prefixIcon: const Icon(Icons.password_outlined),
          ),
          onSubmitted: (_) => _setPassword(),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _setPassword,
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Passwort festlegen'),
        ),
        if (widget.addresses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _ReachableAddresses(addresses: widget.addresses),
        ],
      ],
    );
  }

  void _setPassword() {
    final password = _passwordController.text;
    if (password.isEmpty || password != _confirmationController.text) {
      setState(() => _validationMessage = 'Die Passwörter stimmen nicht überein.');
      return;
    }
    setState(() => _validationMessage = null);
    context.read<RuntimeConnectionCubit>().setPassword(
      widget.endpoint,
      password,
      code: _codeController.text,
    );
  }
}

/// Zeigt, unter welchen Adressen andere Geräte diese Runtime erreichen —
/// von ihr selbst ermittelt. Bewusst keine Eingabe: Ein abgetippter Wert
/// würde bei jedem DHCP-Wechsel still falsch.
class _ReachableAddresses extends StatelessWidget {
  const _ReachableAddresses({required this.addresses});

  final List<String> addresses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Von anderen Geräten erreichbar unter', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        for (final address in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SelectableText(address, style: textTheme.bodyMedium),
          ),
      ],
    );
  }
}
