import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/syscat_background.dart';

import '../../domain/usecases/sign_in_with_email_and_password.dart';
import '../../domain/usecases/sign_up_with_email_and_password.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/auth_form.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.signUp, required this.signIn});

  final SignUpWithEmailAndPassword signUp;
  final SignInWithEmailAndPassword signIn;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(signUp: signUp, signIn: signIn),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return SyscatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: const _AuthPanel(),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocListener<AuthCubit, AuthState>(
            listener: _showFailure,
            child: const _AuthPanelContent(),
          ),
        ),
      ),
    );
  }

  void _showFailure(BuildContext context, AuthState state) {
    if (state.status != AuthStatus.failure || state.message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.message!)));
  }
}

class _AuthPanelContent extends StatelessWidget {
  const _AuthPanelContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthHeader(),
        SizedBox(height: AppSpacing.lg),
        AuthForm(),
      ],
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Syscat starten', style: textTheme.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Erstelle dein Konto oder logge dich ein.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
