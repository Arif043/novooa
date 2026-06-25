import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class AuthForm extends StatelessWidget {
  const AuthForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeSelector(mode: state.mode, isEnabled: !state.isSubmitting),
            const SizedBox(height: AppSpacing.lg),
            _AuthFields(state: state),
            _SubmitButton(state: state),
          ],
        );
      },
    );
  }
}

class _AuthFields extends StatelessWidget {
  const _AuthFields({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.mode == AuthMode.signUp) ...[
          _NameField(isEnabled: !state.isSubmitting),
          const SizedBox(height: AppSpacing.md),
        ],
        _EmailField(isEnabled: !state.isSubmitting),
        const SizedBox(height: AppSpacing.md),
        _PasswordField(isEnabled: !state.isSubmitting),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.isEnabled});

  final AuthMode mode;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AuthMode>(
      segments: const [
        ButtonSegment(value: AuthMode.signUp, label: Text('Registrieren')),
        ButtonSegment(value: AuthMode.signIn, label: Text('Login')),
      ],
      selected: {mode},
      onSelectionChanged: isEnabled
          ? (value) => context.read<AuthCubit>().changeMode(value.first)
          : null,
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
      onChanged: context.read<AuthCubit>().updateName,
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
      onChanged: context.read<AuthCubit>().updateEmail,
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
      onChanged: context.read<AuthCubit>().updatePassword,
      onSubmitted: (_) => context.read<AuthCubit>().submit(),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: state.isSubmitting ? null : context.read<AuthCubit>().submit,
      child: state.isSubmitting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              state.mode == AuthMode.signUp ? 'Konto erstellen' : 'Einloggen',
            ),
    );
  }
}
