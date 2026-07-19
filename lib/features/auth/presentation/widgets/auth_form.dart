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

class _AuthFields extends StatefulWidget {
  const _AuthFields({required this.state});

  final AuthFormState state;

  @override
  State<_AuthFields> createState() => _AuthFieldsState();
}

class _AuthFieldsState extends State<_AuthFields> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncControllersToState(widget.state);
  }

  @override
  void didUpdateWidget(_AuthFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllersToState(widget.state);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthFormCubit>();
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.mode == AuthMode.signUp) ...[
          AuthTextField(
            controller: _nameController,
            enabled: !state.isSubmitting,
            hintText: 'Name',
            textInputAction: TextInputAction.next,
            onChanged: cubit.updateName,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AuthTextField(
          controller: _emailController,
          enabled: !state.isSubmitting,
          hintText: 'E-Mail',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onChanged: cubit.updateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          controller: _passwordController,
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

  /// Hält Controller und Cubit-State bidirektional konsistent.
  ///
  /// Wichtig für zwei Fälle: (a) `changeMode` setzt die Werte im State
  /// wieder auf leer zurück — die sichtbaren Textfelder müssen mitziehen;
  /// (b) nach einem gescheiterten Login setzt der Cubit `password: ''` und
  /// erwartet, dass das Passwortfeld wirklich leer ist.
  void _syncControllersToState(AuthFormState state) {
    _syncController(_nameController, state.name);
    _syncController(_emailController, state.email);
    _syncController(_passwordController, state.password);
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
