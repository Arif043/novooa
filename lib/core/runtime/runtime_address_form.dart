import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import 'runtime_form_header.dart';
import '../theme/app_spacing.dart';

/// Erster Schritt nativ: die Adresse der Runtime im LAN oder ihre Domain.
class RuntimeAddressForm extends StatefulWidget {
  const RuntimeAddressForm({
    super.key,
    required this.address,
    this.errorMessage,
    this.isConnecting = false,
  });

  final String address;
  final String? errorMessage;
  final bool isConnecting;

  @override
  State<RuntimeAddressForm> createState() => _RuntimeAddressFormState();
}

class _RuntimeAddressFormState extends State<RuntimeAddressForm> {
  late final TextEditingController _addressController = TextEditingController(
    text: widget.address,
  );

  @override
  void didUpdateWidget(covariant RuntimeAddressForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _addressController.text = widget.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RuntimeFormHeader(
          title: 'Runtime verbinden',
          description:
              'Gib die IP-Adresse des Rechners im LAN ein, auf dem novooa '
              'läuft. Ist die Runtime über eine Domain mit Zertifikat '
              'erreichbar, gib stattdessen die Domain ein — die Verbindung '
              'läuft dann verschlüsselt. Für einen internen Hostnamen ohne '
              'Zertifikat stelle http:// voran.',
        ),
        TextField(
          controller: _addressController,
          enabled: !widget.isConnecting,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: runtimeFieldDecoration(
            context,
            label: 'Adresse der Runtime',
            hint: '192.168.1.42 oder novooa.beispiel.de',
            errorText: widget.errorMessage,
          ),
          onSubmitted: (_) => _connect(),
        ),
        const SizedBox(height: AppSpacing.lg),
        RuntimeFormButton(
          label: 'Verbinden',
          isBusy: widget.isConnecting,
          onPressed: _connect,
        ),
      ],
    );
  }

  void _connect() {
    context.read<RuntimeConnectionCubit>().connect(_addressController.text);
  }
}

/// Web-Pendant zur Adress-Eingabe: Es gibt nichts einzugeben, die Origin
/// steht fest — nur der Grund und ein erneuter Versuch.
class RuntimeUnreachableNotice extends StatelessWidget {
  const RuntimeUnreachableNotice({
    super.key,
    required this.endpoint,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RuntimeFormHeader(
          title: 'Runtime nicht erreichbar',
          description:
              errorMessage ??
              'Die Runtime unter dieser Adresse antwortet gerade nicht.',
        ),
        RuntimeFormButton(
          label: 'Erneut versuchen',
          onPressed: () => context.read<RuntimeConnectionCubit>().connect(
            endpoint.displayAddress,
          ),
        ),
      ],
    );
  }
}
