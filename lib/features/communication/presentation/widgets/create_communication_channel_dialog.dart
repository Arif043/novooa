import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';
import '../../domain/entities/create_communication_channel_input.dart';
import 'whatsapp_business_onboarding_notice.dart';

class CreateCommunicationChannelDialog extends StatefulWidget {
  const CreateCommunicationChannelDialog({
    super.key,
    required this.initialKind,
  });

  final CommunicationChannelKind initialKind;

  @override
  State<CreateCommunicationChannelDialog> createState() {
    return _CreateCommunicationChannelDialogState();
  }
}

class _CreateCommunicationChannelDialogState
    extends State<CreateCommunicationChannelDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  late CommunicationChannelKind _kind;
  bool _acceptedWhatsappOnboarding = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
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
            if (_kind == CommunicationChannelKind.whatsapp) ...[
              const SizedBox(height: AppSpacing.md),
              WhatsappBusinessOnboardingNotice(
                accepted: _acceptedWhatsappOnboarding,
                onChanged: _setWhatsappOnboardingAccepted,
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _canSubmit ? _submit : null,
          child: _button,
        ),
      ],
    );
  }

  void _setKind(CommunicationChannelKind kind) {
    setState(() => _kind = kind);
  }

  void _setWhatsappOnboardingAccepted(bool accepted) {
    setState(() => _acceptedWhatsappOnboarding = accepted);
  }

  void _submit() {
    Navigator.of(context).pop(
      CreateCommunicationChannelInput(
        provider: _providerForKind,
        kind: _kind,
        label: _labelController.text,
        address: _addressController.text,
        capabilities: const ChannelCapabilities(inbound: true, outbound: true),
        status: _statusForKind,
      ),
    );
  }

  bool get _canSubmit {
    if (_kind != CommunicationChannelKind.whatsapp) return true;
    return _acceptedWhatsappOnboarding;
  }

  Widget get _button {
    return Text(
      _kind == CommunicationChannelKind.whatsapp
          ? 'Onboarding starten'
          : 'Verbinden',
    );
  }

  String get _addressLabel {
    return switch (_kind) {
      CommunicationChannelKind.email => 'E-Mail-Adresse',
      CommunicationChannelKind.whatsapp ||
      CommunicationChannelKind.sms => 'Telefonnummer',
    };
  }

  String get _addressHint {
    return switch (_kind) {
      CommunicationChannelKind.email => 'name@beispiel.de',
      CommunicationChannelKind.whatsapp => '+491234567890',
      CommunicationChannelKind.sms => '+491234567890',
    };
  }

  CommunicationProvider get _providerForKind {
    return switch (_kind) {
      CommunicationChannelKind.email => CommunicationProvider.microsoftGraph,
      CommunicationChannelKind.whatsapp ||
      CommunicationChannelKind.sms => CommunicationProvider.twilio,
    };
  }

  CommunicationChannelStatus get _statusForKind {
    return switch (_kind) {
      CommunicationChannelKind.email =>
        CommunicationChannelStatus.setupRequired,
      CommunicationChannelKind.whatsapp =>
        CommunicationChannelStatus.pendingVerification,
      CommunicationChannelKind.sms => CommunicationChannelStatus.active,
    };
  }

  String get _kindLabel {
    return switch (_kind) {
      CommunicationChannelKind.email => 'E-Mail',
      CommunicationChannelKind.whatsapp => 'WhatsApp',
      CommunicationChannelKind.sms => 'SMS',
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
      items: const [
        CommunicationChannelKind.whatsapp,
        CommunicationChannelKind.sms,
      ].map(_item).toList(growable: false),
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
      CommunicationChannelKind.email => 'E-Mail',
      CommunicationChannelKind.whatsapp => 'WhatsApp',
      CommunicationChannelKind.sms => 'SMS',
    };
  }
}
