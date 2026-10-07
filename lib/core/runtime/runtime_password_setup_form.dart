import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'license_token_field.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';
import 'runtime_form_header.dart';
import 'runtime_license_form.dart';

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
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String _token = '';
  String? _validationMessage;

  @override
  void dispose() {
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
        const RuntimeFormHeader(
          title: 'Zugriffs-Passwort festlegen',
          description:
              'Dieses Passwort schützt den Zugriff auf die Runtime. Alle '
              'Geräte melden sich damit an.',
        ),
        if (setup.needsTokenInput) ...[
          LicenseTokenField(onChanged: (token) => _token = token),
          const SizedBox(height: AppSpacing.lg),
        ],
        ..._passwordFields(_validationMessage ?? setup.errorMessage),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(label: 'Passwort festlegen', onPressed: _setPassword),
      ],
    );
  }

  List<Widget> _passwordFields(String? errorMessage) => [
    TextField(
      controller: _passwordController,
      obscureText: true,
      autofocus: !widget.setup.needsTokenInput,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      decoration: runtimeFieldDecoration(context, label: 'Passwort'),
    ),
    const SizedBox(height: AppSpacing.md),
    TextField(
      controller: _confirmationController,
      obscureText: true,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.newPassword],
      decoration: runtimeFieldDecoration(
        context,
        label: 'Passwort wiederholen',
        errorText: errorMessage,
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
      activationToken: widget.setup.needsTokenInput ? _token : null,
    );
  }

  String? _validationMessageFor() {
    if (widget.setup.needsTokenInput &&
        _token.length != LicenseTokenField.length) {
      return 'Bitte gib alle 16 Zeichen des Lizenz-Tokens ein.';
    }
    final password = _passwordController.text;
    if (password.isEmpty || password != _confirmationController.text) {
      return 'Die Passwörter stimmen nicht überein.';
    }
    return null;
  }
}
