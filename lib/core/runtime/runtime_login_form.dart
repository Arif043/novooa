import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../localization/locale_keys.g.dart';
import '../theme/app_spacing.dart';
import 'runtime_account_fields.dart';
import 'runtime_form_header.dart';

/// Anmeldung mit dem eigenen Konto einer eingerichteten Runtime; darunter die
/// Wege für eingeladene Personen und den Notzugang.
class RuntimeLoginForm extends StatefulWidget {
  const RuntimeLoginForm({
    super.key,
    required this.endpoint,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimeLoginForm> createState() => _RuntimeLoginFormState();
}

class _RuntimeLoginFormState extends State<RuntimeLoginForm> {
  final _loginNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _loginNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RuntimeFormHeader(
            title: LocaleKeys.runtime_sign_in_title.tr(),
            description: LocaleKeys.runtime_sign_in_description.tr(
              args: [widget.endpoint.displayAddress],
            ),
          ),
          RuntimeLoginNameField(
            controller: _loginNameController,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.md),
          RuntimePasswordField(
            controller: _passwordController,
            label: LocaleKeys.runtime_access_password.tr(),
            errorText: widget.errorMessage,
            onSubmitted: _login,
          ),
          const SizedBox(height: AppSpacing.lg),
          RuntimeFormButton(
            label: LocaleKeys.runtime_sign_in_action.tr(),
            onPressed: _login,
          ),
          const SizedBox(height: AppSpacing.sm),
          RuntimeSignInLink(
            label: LocaleKeys.runtime_invitation_link.tr(),
            onPressed: () => _show(RuntimeSignInMode.invitation),
          ),
          RuntimeSignInLink(
            label: LocaleKeys.runtime_recovery_link.tr(),
            onPressed: () => _show(RuntimeSignInMode.recovery),
          ),
        ],
      ),
    );
  }

  void _show(RuntimeSignInMode mode) =>
      context.read<RuntimeConnectionCubit>().showSignIn(widget.endpoint, mode);

  void _login() {
    context.read<RuntimeConnectionCubit>().login(
      widget.endpoint,
      loginName: _loginNameController.text,
      password: _passwordController.text,
    );
  }
}
