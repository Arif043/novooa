import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../localization/locale_keys.g.dart';
import '../theme/app_spacing.dart';
import 'runtime_account_fields.dart';
import 'runtime_password_rule.dart';
import 'runtime_form_header.dart';

/// Eingeladene Personen lösen den Code ihres Admins ein und setzen dabei ihr
/// eigenes Passwort; danach sind sie angemeldet.
class RuntimeInvitationForm extends StatefulWidget {
  const RuntimeInvitationForm({
    super.key,
    required this.endpoint,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimeInvitationForm> createState() => _RuntimeInvitationFormState();
}

class _RuntimeInvitationFormState extends State<RuntimeInvitationForm> {
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RuntimeFormHeader(
          title: LocaleKeys.runtime_invitation_title.tr(),
          description: LocaleKeys.runtime_invitation_description.tr(),
        ),
        TextField(
          controller: _codeController,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          decoration: runtimeFieldDecoration(
            context,
            label: LocaleKeys.runtime_invitation_code.tr(),
            hint: 'ABCD-EFGH-JKMN-PQRS',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RuntimePasswordField(
          controller: _passwordController,
          label: LocaleKeys.runtime_access_new_password.tr(),
          isNewPassword: true,
          showsRule: true,
        ),
        const SizedBox(height: AppSpacing.md),
        RuntimePasswordField(
          controller: _confirmationController,
          label: LocaleKeys.runtime_access_repeat_password.tr(),
          isNewPassword: true,
          errorText: _validationMessage ?? widget.errorMessage,
          onSubmitted: _redeem,
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(
          label: LocaleKeys.runtime_invitation_action.tr(),
          onPressed: _redeem,
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

  void _redeem() {
    final problem = runtimeNewPasswordProblem(
      _passwordController.text,
      confirmation: _confirmationController.text,
    );
    setState(() => _validationMessage = problem);
    if (problem != null) return;
    context.read<RuntimeConnectionCubit>().redeemInvitation(
      widget.endpoint,
      code: _codeController.text,
      password: _passwordController.text,
    );
  }
}
