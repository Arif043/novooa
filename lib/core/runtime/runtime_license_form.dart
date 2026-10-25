import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../theme/app_spacing.dart';
import 'license_token_field.dart';
import 'runtime_form_header.dart';

class RuntimeLicenseForm extends StatefulWidget {
  const RuntimeLicenseForm({
    required this.endpoint,
    this.errorMessage,
    super.key,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  State<RuntimeLicenseForm> createState() => _RuntimeLicenseFormState();
}

class _RuntimeLicenseFormState extends State<RuntimeLicenseForm> {
  String _token = '';

  bool get _isComplete => _token.length == LicenseTokenField.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RuntimeFormHeader(
          title: 'Lizenz aktivieren',
          description:
              'Für diese Runtime ist noch keine Lizenz aktiviert. Gib den '
              'Lizenz-Token ein, den du beim Kauf erhalten hast.',
        ),
        LicenseTokenField(
          errorText: widget.errorMessage,
          onChanged: (token) => setState(() => _token = token),
          onSubmitted: _activate,
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(
          label: 'Lizenz aktivieren',
          onPressed: _isComplete ? _activate : null,
        ),
      ],
    );
  }

  void _activate() {
    if (!_isComplete) return;
    context.read<RuntimeConnectionCubit>().activateLicense(
      widget.endpoint,
      _token,
    );
  }
}
