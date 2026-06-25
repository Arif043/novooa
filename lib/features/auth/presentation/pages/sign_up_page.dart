import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/syscat_background.dart';

import '../../domain/usecases/sign_up_with_email_and_password.dart';
import '../cubits/sign_up_cubit.dart';
import '../cubits/sign_up_state.dart';
import '../widgets/sign_up_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key, required this.signUp});

  final SignUpWithEmailAndPassword signUp;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpCubit(signUp: signUp),
      child: const _SignUpView(),
    );
  }
}

class _SignUpView extends StatelessWidget {
  const _SignUpView();

  @override
  Widget build(BuildContext context) {
    return SyscatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: const _SignUpPanel(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpPanel extends StatelessWidget {
  const _SignUpPanel();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: BlocListener<SignUpCubit, SignUpState>(
            listener: _showFailure,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SignUpHeader(),
                SizedBox(height: AppSpacing.lg),
                SignUpForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFailure(BuildContext context, SignUpState state) {
    if (state case SignUpFailure(:final message)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Syscat starten', style: textTheme.displayLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Erstelle dein Konto und baue deine ersten Aufgaben.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
