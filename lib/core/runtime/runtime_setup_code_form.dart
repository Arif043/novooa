import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_spacing.dart';
import 'runtime_connection_cubit.dart';
import 'runtime_endpoint.dart';

/// Erster der beiden Einrichtungsschritte (siehe
/// `docs/architecture/betriebsvarianten.md`): Der Code aus dem Start-Log
/// der Runtime beweist Zugriff auf den Host — erst danach folgt das
/// Passwort ([RuntimePasswordSetupForm]).
class RuntimeSetupCodeForm extends StatefulWidget {
  const RuntimeSetupCodeForm({
    required this.endpoint,
    this.errorMessage,
    this.addresses = const [],
    super.key,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;
  final List<String> addresses;

  @override
  State<RuntimeSetupCodeForm> createState() => _RuntimeSetupCodeFormState();
}

class _RuntimeSetupCodeFormState extends State<RuntimeSetupCodeForm> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.key_outlined, size: 48, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Runtime koppeln',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Gib den Einrichtungscode aus dem Start-Log der Runtime ein '
          '(docker compose logs).',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _codeController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Einrichtungscode',
            errorText: widget.errorMessage,
            prefixIcon: const Icon(Icons.key_outlined),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Weiter'),
        ),
        if (widget.addresses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _ReachableAddresses(addresses: widget.addresses),
        ],
      ],
    );
  }

  void _submit() {
    context.read<RuntimeConnectionCubit>().submitSetupCode(
      widget.endpoint,
      _codeController.text,
    );
  }
}

/// Zeigt, unter welchen Adressen andere Geräte diese Runtime erreichen —
/// von ihr selbst ermittelt. Bewusst keine Eingabe: Ein abgetippter Wert
/// würde bei jedem DHCP-Wechsel still falsch.
class _ReachableAddresses extends StatelessWidget {
  const _ReachableAddresses({required this.addresses});

  final List<String> addresses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Von anderen Geräten erreichbar unter', style: textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        for (final address in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SelectableText(address, style: textTheme.bodyMedium),
          ),
      ],
    );
  }
}
