import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../app/dashboard_theme.dart';
import '../l10n/dashboard_keys.dart';

/// Anmeldung mit Konto oder mit einem Einladungscode (eigenes Passwort
/// setzen). Konten legt ein Admin im offiziellen Frontend an.
class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.endpoint,
    required this.mode,
    this.failureText,
  });

  final RuntimeEndpoint endpoint;
  final RuntimeSignInMode mode;
  final String? failureText;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _name = TextEditingController();
  final _password = TextEditingController();

  bool get _isInvitation => widget.mode == RuntimeSignInMode.invitation;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final connection = context.read<RuntimeConnectionCubit>();
    if (_isInvitation) {
      connection.redeemInvitation(
        widget.endpoint,
        code: _name.text,
        password: _password.text,
      );
      return;
    }
    connection.login(
      widget.endpoint,
      loginName: _name.text,
      password: _password.text,
    );
  }

  void _switchMode() => context.read<RuntimeConnectionCubit>().showSignIn(
    widget.endpoint,
    _isInvitation ? RuntimeSignInMode.password : RuntimeSignInMode.invitation,
  );

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DashboardKeys.signInTitle.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: Spacing.lg),
          _NameField(controller: _name, isInvitation: _isInvitation),
          const SizedBox(height: Spacing.md),
          _PasswordField(
            controller: _password,
            failureText: widget.failureText,
            onSubmitted: _submit,
          ),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: _submit,
            child: Text(
              (_isInvitation
                      ? DashboardKeys.signInInvitationAction
                      : DashboardKeys.signInAction)
                  .tr(),
            ),
          ),
          TextButton(
            onPressed: _switchMode,
            child: Text(
              (_isInvitation
                      ? DashboardKeys.signInBack
                      : DashboardKeys.signInHaveInvitation)
                  .tr(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.isInvitation});

  final TextEditingController controller;
  final bool isInvitation;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofillHints: isInvitation ? null : const [AutofillHints.username],
    decoration: InputDecoration(
      labelText:
          (isInvitation
                  ? DashboardKeys.signInInvitationCode
                  : DashboardKeys.signInLoginName)
              .tr(),
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.failureText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String? failureText;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: true,
    autofillHints: const [AutofillHints.password],
    onSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(
      labelText: DashboardKeys.signInPassword.tr(),
      errorText: failureText,
      errorMaxLines: 3,
    ),
  );
}
