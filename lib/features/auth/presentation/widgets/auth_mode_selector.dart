import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/auth_form_cubit.dart';
import '../cubits/auth_form_state.dart';

class AuthModeSelector extends StatelessWidget {
  const AuthModeSelector({
    super.key,
    required this.mode,
    required this.isEnabled,
  });

  final AuthMode mode;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: SegmentedButton<AuthMode>(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.surface;
            }
            return colorScheme.surfaceContainer;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        showSelectedIcon: true,
        segments: const [
          ButtonSegment(value: AuthMode.signUp, label: Text('Registrieren')),
          ButtonSegment(value: AuthMode.signIn, label: Text('Login')),
        ],
        selected: {mode},
        onSelectionChanged: isEnabled
            ? (value) => context.read<AuthFormCubit>().changeMode(value.first)
            : null,
      ),
    );
  }
}
