import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_endpoint.dart';
import 'runtime_form_header.dart';

/// Anmeldung mit dem Zugriffs-Passwort einer eingerichteten Runtime.
class RuntimeLoginForm extends StatefulWidget {
  const RuntimeLoginForm({
    super.key,
    required this.endpoint,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimeLoginForm> createState() => _RuntimeLoginFormState();
}

class _RuntimeLoginFormState extends State<RuntimeLoginForm> {
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RuntimeFormHeader(
          title: 'Anmelden',
          description:
              'Gib das Zugriffs-Passwort der Runtime unter '
              '${widget.endpoint.displayAddress} ein.',
        ),
        TextField(
          controller: _passwordController,
          obscureText: _obscure,
          autofocus: true,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          decoration: runtimeFieldDecoration(
            context,
            label: 'Passwort',
            errorText: widget.errorMessage,
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Passwort anzeigen' : 'Passwort verbergen',
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(label: 'Anmelden', onPressed: _login),
      ],
    );
  }

  void _login() {
    context.read<RuntimeConnectionCubit>().login(
      widget.endpoint,
      _passwordController.text,
    );
  }
}
