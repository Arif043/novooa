import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_endpoint.dart';

/// Zweiter und letzter Einrichtungsschritt (siehe
/// `RuntimeSetupCodeForm`) — der zuvor eingegebene Kopplungscode reist im
/// State mit und wird erst hier zusammen mit dem Passwort verschickt.
class RuntimePasswordSetupForm extends StatefulWidget {
  const RuntimePasswordSetupForm({
    required this.endpoint,
    this.errorMessage,
    super.key,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimePasswordSetupForm> createState() => _RuntimePasswordSetupFormState();
}

class _RuntimePasswordSetupFormState extends State<RuntimePasswordSetupForm> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
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
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _changeCode,
          child: const Text('Einrichtungscode ändern'),
        ),
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
    context.read<RuntimeConnectionCubit>().setPassword(widget.endpoint, password);
  }

  void _changeCode() {
    context.read<RuntimeConnectionCubit>().changeSetupCode(widget.endpoint);
  }
}
