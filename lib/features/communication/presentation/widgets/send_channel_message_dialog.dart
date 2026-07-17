import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';

class SendChannelMessageDialog extends StatefulWidget {
  const SendChannelMessageDialog({super.key, required this.channel});

  final CommunicationChannel channel;

  @override
  State<SendChannelMessageDialog> createState() {
    return _SendChannelMessageDialogState();
  }
}

class _SendChannelMessageDialogState extends State<SendChannelMessageDialog> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nachricht senden'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _recipientController,
              decoration: InputDecoration(
                labelText: 'Empfänger',
                hintText: _recipientHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Nachricht'),
              minLines: 4,
              maxLines: 8,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Senden'),
        ),
      ],
    );
  }

  String get _recipientHint {
    return switch (widget.channel.kind) {
      CommunicationChannelKind.whatsapp => '+491234567890',
      CommunicationChannelKind.sms => '+491234567890',
      CommunicationChannelKind.email => 'name@example.com',
    };
  }

  void _submit(BuildContext context) {
    final recipient = _recipientController.text.trim();
    final message = _messageController.text.trim();
    if (recipient.isEmpty || message.isEmpty) return;
    Navigator.of(context).pop((to: recipient, body: message));
  }
}
