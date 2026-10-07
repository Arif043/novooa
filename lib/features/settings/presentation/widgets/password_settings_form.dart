import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/password_settings_cubit.dart';
import '../cubits/password_settings_state.dart';
import 'new_password_field.dart';
import 'password_settings_form_body.dart';

class PasswordSettingsForm extends StatefulWidget {
  const PasswordSettingsForm({super.key});

  @override
  State<PasswordSettingsForm> createState() => _PasswordSettingsFormState();
}

class _PasswordSettingsFormState extends State<PasswordSettingsForm> {
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<PasswordSettingsCubit, PasswordSettingsState>(
        listener: _onStateChanged,
        builder: (context, state) => PasswordSettingsFormBody(
          state: state,
          passwordField: NewPasswordField(
            controller: _passwordController,
            enabled: state is! PasswordSettingsSaving,
            showPassword: _showPassword,
            onToggleVisibility: _toggleVisibility,
            onChanged: _onChanged,
            onSubmitted: (_) => _save(),
          ),
          hasInput: _passwordController.text.isNotEmpty,
          onSave: _save,
        ),
      );

  void _toggleVisibility() => setState(() => _showPassword = !_showPassword);

  void _onChanged(String _) {
    context.read<PasswordSettingsCubit>().clearFeedback();
    setState(() {});
  }

  void _onStateChanged(BuildContext context, PasswordSettingsState state) {
    if (state is! PasswordSettingsSuccess) return;
    _passwordController.clear();
    setState(() => _showPassword = false);
    FocusScope.of(context).unfocus();
  }

  void _save() {
    if (_passwordController.text.isEmpty) return;
    context.read<PasswordSettingsCubit>().save(_passwordController.text);
  }
}
