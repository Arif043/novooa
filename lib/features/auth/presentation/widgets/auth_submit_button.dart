import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({super.key, required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: state.isSubmitting ? null : context.read<AuthCubit>().submit,
        child: state.isSubmitting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_label),
      ),
    );
  }

  String get _label {
    return state.mode == AuthMode.signUp ? 'Konto erstellen' : 'Einloggen';
  }
}
