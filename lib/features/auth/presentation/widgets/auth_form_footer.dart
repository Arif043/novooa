import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/auth_form_cubit.dart';
import '../cubits/auth_form_state.dart';

class AuthFormFooter extends StatelessWidget {
  const AuthFormFooter({super.key, required this.state});

  final AuthFormState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AuthDivider(),
        const SizedBox(height: AppSpacing.xl),
        _GoogleButton(isEnabled: !state.isSubmitting),
        const SizedBox(height: AppSpacing.lg),
        _ModeHint(mode: state.mode, isEnabled: !state.isSubmitting),
      ],
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider();

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerTheme.color;
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('oder', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isEnabled});

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isEnabled ? () => _showUnavailable(context) : null,
        icon: const _GoogleMark(),
        label: const Text('Mit Google anmelden'),
      ),
    );
  }

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google-Anmeldung ist noch nicht aktiv.')),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  const _ModeHint({required this.mode, required this.isEnabled});

  final AuthMode mode;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Text('Du nutzt novooa Standalone?', style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          onPressed: isEnabled ? () => _changeMode(context) : null,
          child: Text(_action),
        ),
      ],
    );
  }

  String get _prefix {
    return mode == AuthMode.signUp
        ? 'Bereits registriert?'
        : 'Noch kein Konto?';
  }

  String get _action {
    return mode == AuthMode.signUp ? 'Jetzt einloggen' : 'Jetzt registrieren';
  }

  void _changeMode(BuildContext context) {
    final nextMode = mode == AuthMode.signUp
        ? AuthMode.signIn
        : AuthMode.signUp;
    context.read<AuthFormCubit>().changeMode(nextMode);
  }
}
