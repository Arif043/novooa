import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/auth_form_cubit.dart';
import '../cubits/auth_form_state.dart';
import 'auth_form_footer.dart';
import 'auth_mode_selector.dart';
import 'auth_submit_button.dart';
import 'auth_text_field.dart';

class AuthForm extends StatelessWidget {
  const AuthForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthFormCubit, AuthFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthModeSelector(mode: state.mode, isEnabled: !state.isSubmitting),
            const SizedBox(height: AppSpacing.lg),
            _AuthFields(state: state),
            AuthSubmitButton(state: state),
            const SizedBox(height: AppSpacing.xl),
            AuthFormFooter(state: state),
          ],
        );
      },
    );
  }
}

class _AuthFields extends StatelessWidget {
  const _AuthFields({required this.state});

  final AuthFormState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthFormCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.mode == AuthMode.signUp) ...[
          AuthTextField(
            enabled: !state.isSubmitting,
            hintText: 'Name',
            textInputAction: TextInputAction.next,
            onChanged: cubit.updateName,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AuthTextField(
          enabled: !state.isSubmitting,
          hintText: 'E-Mail',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: cubit.updateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          enabled: !state.isSubmitting,
          hintText: 'Passwort',
          obscureText: true,
          onChanged: cubit.updatePassword,
          onSubmitted: (_) => cubit.submit(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
