import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';
import '../../domain/entities/create_communication_channel_input.dart';

class CreateCommunicationChannelDialog extends StatefulWidget {
  const CreateCommunicationChannelDialog({super.key});

  @override
  State<CreateCommunicationChannelDialog> createState() {
    return _CreateCommunicationChannelDialogState();
  }
}

class _CreateCommunicationChannelDialogState
    extends State<CreateCommunicationChannelDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  CommunicationChannelKind _kind = CommunicationChannelKind.whatsapp;

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$_kindLabel verbinden'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _KindField(value: _kind, onChanged: _setKind),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Anzeigename'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: _addressLabel,
                hintText: _addressHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Verbinden')),
      ],
    );
  }

  void _setKind(CommunicationChannelKind kind) {
    setState(() => _kind = kind);
  }

  void _submit() {
    Navigator.of(context).pop(
      CreateCommunicationChannelInput(
        provider: _providerForKind,
        kind: _kind,
        label: _labelController.text,
        address: _addressController.text,
        capabilities: const ChannelCapabilities(inbound: true, outbound: true),
      ),
    );
  }

  String get _addressLabel {
    return switch (_kind) {
      CommunicationChannelKind.whatsapp ||
      CommunicationChannelKind.sms => 'Telefonnummer',
      CommunicationChannelKind.email => 'E-Mail-Adresse',
    };
  }

  String get _addressHint {
    return switch (_kind) {
      CommunicationChannelKind.whatsapp => '+491234567890',
      CommunicationChannelKind.sms => '+491234567890',
      CommunicationChannelKind.email => 'eingang@example.com',
    };
  }

  CommunicationProvider get _providerForKind {
    return switch (_kind) {
      CommunicationChannelKind.whatsapp ||
      CommunicationChannelKind.sms => CommunicationProvider.twilio,
      CommunicationChannelKind.email => CommunicationProvider.sendgrid,
    };
  }

  String get _kindLabel {
    return switch (_kind) {
      CommunicationChannelKind.whatsapp => 'WhatsApp',
      CommunicationChannelKind.sms => 'SMS',
      CommunicationChannelKind.email => 'E-Mail',
    };
  }
}

class _KindField extends StatelessWidget {
  const _KindField({required this.value, required this.onChanged});

  final CommunicationChannelKind value;
  final ValueChanged<CommunicationChannelKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CommunicationChannelKind>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Art'),
      items: CommunicationChannelKind.values.map(_item).toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  DropdownMenuItem<CommunicationChannelKind> _item(
    CommunicationChannelKind kind,
  ) {
    return DropdownMenuItem(value: kind, child: Text(_kindLabel(kind)));
  }

  String _kindLabel(CommunicationChannelKind kind) {
    return switch (kind) {
      CommunicationChannelKind.whatsapp => 'WhatsApp',
      CommunicationChannelKind.sms => 'SMS',
      CommunicationChannelKind.email => 'E-Mail',
    };
  }
}
