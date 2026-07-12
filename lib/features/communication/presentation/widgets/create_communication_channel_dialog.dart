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
  final TextEditingController _accountSidController = TextEditingController();
  CommunicationProvider _provider = CommunicationProvider.twilio;
  CommunicationChannelKind _kind = CommunicationChannelKind.whatsapp;
  bool _inbound = true;
  bool _outbound = false;

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _accountSidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kanal hinzufügen'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProviderField(value: _provider, onChanged: _setProvider),
            const SizedBox(height: AppSpacing.md),
            _KindField(value: _kind, onChanged: _setKind),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Adresse',
                hintText: _addressHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _accountSidController,
              decoration: const InputDecoration(
                labelText: 'Twilio Account SID',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              value: _inbound,
              onChanged: (value) => setState(() => _inbound = value),
              title: const Text('Eingehende Nachrichten'),
            ),
            SwitchListTile(
              value: _outbound,
              onChanged: (value) => setState(() => _outbound = value),
              title: const Text('Ausgehende Nachrichten'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Erstellen')),
      ],
    );
  }

  void _setProvider(CommunicationProvider provider) {
    setState(() {
      _provider = provider;
      if (provider == CommunicationProvider.sendgrid) {
        _kind = CommunicationChannelKind.email;
      }
    });
  }

  void _setKind(CommunicationChannelKind kind) {
    setState(() => _kind = kind);
  }

  void _submit() {
    Navigator.of(context).pop(
      CreateCommunicationChannelInput(
        provider: _provider,
        kind: _kind,
        label: _labelController.text,
        address: _addressController.text,
        accountSid: _accountSidController.text,
        capabilities: ChannelCapabilities(
          inbound: _inbound,
          outbound: _outbound,
        ),
      ),
    );
  }

  String get _addressHint {
    return switch (_kind) {
      CommunicationChannelKind.whatsapp => 'whatsapp:+491234567890',
      CommunicationChannelKind.sms => '+491234567890',
      CommunicationChannelKind.email => 'eingang@example.com',
    };
  }
}

class _ProviderField extends StatelessWidget {
  const _ProviderField({required this.value, required this.onChanged});

  final CommunicationProvider value;
  final ValueChanged<CommunicationProvider> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CommunicationProvider>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Provider'),
      items: CommunicationProvider.values.map(_item).toList(growable: false),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  DropdownMenuItem<CommunicationProvider> _item(
    CommunicationProvider provider,
  ) {
    return DropdownMenuItem(
      value: provider,
      child: Text(_providerLabel(provider)),
    );
  }

  String _providerLabel(CommunicationProvider provider) {
    return switch (provider) {
      CommunicationProvider.twilio => 'Twilio',
      CommunicationProvider.sendgrid => 'SendGrid',
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
