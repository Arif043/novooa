import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/syscat_background.dart';
import 'package:syscat2/generated/assets.dart';

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
    return SyscatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pageMobile),
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
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 416),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SyscatTheme.shadowMedium,
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: BlocListener<AuthFormCubit, AuthFormState>(
            listenWhen: _isNewFailure,
            listener: _showFailure,
            child: const _AuthPanelContent(),
          ),
        ),
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
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthHeader(),
        SizedBox(height: AppSpacing.xl),
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
        // Text('novooa', style: textTheme.headlineLarge),
        Image.asset(Assets.iconsFullv2Transparent),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Erstelle dein Konto oder logge dich ein.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
