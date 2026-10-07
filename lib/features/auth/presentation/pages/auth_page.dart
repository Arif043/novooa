import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/syscat_auth_layout.dart';

import '../cubits/auth_form_cubit.dart';
import '../cubits/auth_form_state.dart';
import '../widgets/auth_form.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<AuthFormCubit>(),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return SyscatAuthLayout(
      child: BlocListener<AuthFormCubit, AuthFormState>(
        listenWhen: _isNewFailure,
        listener: _showFailure,
        child: const _AuthPanelContent(),
      ),
    );
  }

  bool _isNewFailure(AuthFormState previous, AuthFormState current) {
    if (current.status != AuthFormStatus.failure) return false;
    if (current.message == null) return false;
    return previous.message != current.message ||
        previous.status != AuthFormStatus.failure;
  }

  void _showFailure(BuildContext context, AuthFormState state) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(state.message!)));
  }
}

class _AuthPanelContent extends StatelessWidget {
  const _AuthPanelContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Erstelle dein Konto oder logge dich ein.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        const AuthForm(),
      ],
    );
  }
}
