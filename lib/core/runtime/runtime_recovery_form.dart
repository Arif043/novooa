import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/locale_keys.g.dart';
import '../theme/app_spacing.dart';
import 'license_token_field.dart';
import 'runtime_account_fields.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';
import 'runtime_endpoint.dart';
import 'runtime_form_header.dart';

/// Notzugang, wenn kein Admin mehr hineinkommt: Wer den Lizenz-Token der
/// Runtime besitzt, setzt das Passwort eines Admins neu.
class RuntimeRecoveryForm extends StatefulWidget {
  const RuntimeRecoveryForm({
    super.key,
    required this.endpoint,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimeRecoveryForm> createState() => _RuntimeRecoveryFormState();
}

class _RuntimeRecoveryFormState extends State<RuntimeRecoveryForm> {
  final _loginNameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _token = '';
  String? _validationMessage;

  @override
  void dispose() {
    _loginNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RuntimeFormHeader(
          title: LocaleKeys.runtime_recovery_title.tr(),
          description: LocaleKeys.runtime_recovery_description.tr(),
        ),
        LicenseTokenField(
          onChanged: (token) => _token = token,
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeLoginNameField(controller: _loginNameController),
        const SizedBox(height: AppSpacing.md),
        RuntimePasswordField(
          controller: _passwordController,
          label: LocaleKeys.runtime_access_new_password.tr(),
          isNewPassword: true,
          errorText: _validationMessage ?? widget.errorMessage,
          onSubmitted: _recover,
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(
          label: LocaleKeys.runtime_recovery_action.tr(),
          onPressed: _recover,
        ),
        const SizedBox(height: AppSpacing.sm),
        RuntimeSignInLink(
          label: LocaleKeys.runtime_sign_in_back.tr(),
          onPressed: () => context.read<RuntimeConnectionCubit>().showSignIn(
            widget.endpoint,
            RuntimeSignInMode.password,
          ),
        ),
      ],
    );
  }

  void _recover() {
    final incomplete = _token.length != LicenseTokenField.length;
    setState(
      () => _validationMessage = incomplete
          ? LocaleKeys.runtime_access_token_incomplete.tr()
          : null,
    );
    if (incomplete) return;
    context.read<RuntimeConnectionCubit>().recoverAccess(
      widget.endpoint,
      activationToken: _token,
      loginName: _loginNameController.text,
      password: _passwordController.text,
    );
  }
}
