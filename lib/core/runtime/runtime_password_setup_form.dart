import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';

/// Zweiter Einrichtungsschritt nach der Lizenz ([RuntimeLicenseForm]). Der
/// Lizenz-Token aus Schritt 1 reist im State mit; nur wenn die App ihn nicht
/// mehr kennt, wird er hier zusätzlich abgefragt.
class RuntimePasswordSetupForm extends StatefulWidget {
  const RuntimePasswordSetupForm({required this.setup, super.key});

  final RuntimeConnectionNeedsPasswordSetup setup;

  @override
  State<RuntimePasswordSetupForm> createState() =>
      _RuntimePasswordSetupFormState();
}

class _RuntimePasswordSetupFormState extends State<RuntimePasswordSetupForm> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = widget.setup;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PasswordSetupHeader(),
        const SizedBox(height: AppSpacing.xl),
        if (setup.needsTokenInput) ...[
          TextField(
            controller: _tokenController,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Lizenz-Token',
              helperText: 'Der Token, mit dem diese Runtime aktiviert wurde.',
              prefixIcon: Icon(Icons.key_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ..._passwordFields(_validationMessage ?? setup.errorMessage),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _setPassword,
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Passwort festlegen'),
        ),
      ],
    );
  }

  List<Widget> _passwordFields(String? errorMessage) => [
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
  ];

  void _setPassword() {
    final validationMessage = _validationMessageFor();
    setState(() => _validationMessage = validationMessage);
    if (validationMessage != null) return;
    context.read<RuntimeConnectionCubit>().setPassword(
      widget.setup.endpoint,
      _passwordController.text,
      activationToken: widget.setup.needsTokenInput
          ? _tokenController.text
          : null,
    );
  }

  String? _validationMessageFor() {
    if (widget.setup.needsTokenInput && _tokenController.text.trim().isEmpty) {
      return 'Bitte gib den Lizenz-Token dieser Runtime ein.';
    }
    final password = _passwordController.text;
    if (password.isEmpty || password != _confirmationController.text) {
      return 'Die Passwörter stimmen nicht überein.';
    }
    return null;
  }
}

class _PasswordSetupHeader extends StatelessWidget {
  const _PasswordSetupHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Zugriffs-Passwort festlegen',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Dieses Passwort schützt den Zugriff auf die lokale Runtime.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
