import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../localization/locale_keys.g.dart';
import '../theme/app_spacing.dart';
import 'license_token_field.dart';
import 'runtime_account_fields.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_connection_state.dart';
import 'runtime_form_header.dart';
import 'runtime_onboarding_client.dart';

/// Zweiter Einrichtungsschritt nach der Lizenz: das erste Konto, das Admin
/// wird. Der Lizenz-Token aus Schritt 1 reist im State mit; nur wenn die App
/// ihn nicht mehr kennt, wird er hier zusätzlich abgefragt.
class RuntimeAdminSetupForm extends StatefulWidget {
  const RuntimeAdminSetupForm({required this.setup, super.key});

  final RuntimeConnectionNeedsPasswordSetup setup;

  @override
  State<RuntimeAdminSetupForm> createState() => _RuntimeAdminSetupFormState();
}

class _RuntimeAdminSetupFormState extends State<RuntimeAdminSetupForm> {
  final _nameController = TextEditingController();
  final _loginNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String _token = '';
  String? _validationMessage;

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _loginNameController,
      _passwordController,
      _confirmationController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = widget.setup;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RuntimeFormHeader(
          title: LocaleKeys.runtime_setup_title.tr(),
          description: LocaleKeys.runtime_setup_description.tr(),
        ),
        if (setup.needsTokenInput) ...[
          LicenseTokenField(onChanged: (token) => _token = token),
          const SizedBox(height: AppSpacing.lg),
        ],
        TextField(
          controller: _nameController,
          autofocus: !setup.needsTokenInput,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: runtimeFieldDecoration(
            context,
            label: LocaleKeys.runtime_access_display_name.tr(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        RuntimeLoginNameField(controller: _loginNameController),
        const SizedBox(height: AppSpacing.md),
        RuntimePasswordField(
          controller: _passwordController,
          label: LocaleKeys.runtime_access_password.tr(),
          isNewPassword: true,
        ),
        const SizedBox(height: AppSpacing.md),
        RuntimePasswordField(
          controller: _confirmationController,
          label: LocaleKeys.runtime_access_repeat_password.tr(),
          isNewPassword: true,
          errorText: _validationMessage ?? setup.errorMessage,
          onSubmitted: _setUp,
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(
          label: LocaleKeys.runtime_setup_action.tr(),
          onPressed: _setUp,
        ),
      ],
    );
  }

  void _setUp() {
    final validationMessage = _validationMessageFor();
    setState(() => _validationMessage = validationMessage);
    if (validationMessage != null) return;
    context.read<RuntimeConnectionCubit>().setUpAdmin(
      widget.setup.endpoint,
      RuntimeAdminAccount(
        displayName: _nameController.text,
        loginName: _loginNameController.text,
        password: _passwordController.text,
      ),
      activationToken: widget.setup.needsTokenInput ? _token : null,
    );
  }

  String? _validationMessageFor() {
    if (widget.setup.needsTokenInput &&
        _token.length != LicenseTokenField.length) {
      return LocaleKeys.runtime_access_token_incomplete.tr();
    }
    final password = _passwordController.text;
    if (password.isEmpty || password != _confirmationController.text) {
      return LocaleKeys.runtime_access_passwords_differ.tr();
    }
    return null;
  }
}
