import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/sign_up_cubit.dart';
import '../cubits/sign_up_state.dart';

class SignUpForm extends StatelessWidget {
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpCubit, SignUpState>(
      builder: (context, state) {
        final isSubmitting = state is SignUpSubmitting;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NameField(isEnabled: !isSubmitting),
            const SizedBox(height: AppSpacing.md),
            _EmailField(isEnabled: !isSubmitting),
            const SizedBox(height: AppSpacing.md),
            _PasswordField(isEnabled: !isSubmitting),
            const SizedBox(height: AppSpacing.lg),
            _SubmitButton(isSubmitting: isSubmitting),
          ],
        );
      },
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: isEnabled,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: 'Name'),
      onChanged: context.read<SignUpCubit>().updateName,
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: isEnabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(labelText: 'E-Mail'),
      onChanged: context.read<SignUpCubit>().updateEmail,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: isEnabled,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Passwort'),
      onChanged: context.read<SignUpCubit>().updatePassword,
      onSubmitted: (_) => context.read<SignUpCubit>().submit(),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting});

  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isSubmitting ? null : context.read<SignUpCubit>().submit,
      child: isSubmitting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Konto erstellen'),
    );
  }
}
