import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';

class CommunicationChannelTile extends StatelessWidget {
  const CommunicationChannelTile({
    super.key,
    required this.channel,
    this.onFakeMessage,
    this.onSendMessage,
    this.onDelete,
  });

  final CommunicationChannel channel;
  final VoidCallback? onFakeMessage;
  final VoidCallback? onSendMessage;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    channel.label,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onFakeMessage != null)
                  IconButton(
                    tooltip: 'Testnachricht auslösen',
                    onPressed: onFakeMessage,
                    icon: const Icon(Icons.bolt_outlined),
                  ),
                if (onSendMessage != null)
                  IconButton(
                    tooltip: 'Nachricht senden',
                    onPressed: onSendMessage,
                    icon: const Icon(Icons.send_outlined),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Kanal entfernen',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(channel.address, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(label: _kindLabel),
                _InfoChip(label: _statusLabel),
                if (channel.capabilities.inbound)
                  const _InfoChip(label: 'Eingang'),
                if (channel.capabilities.outbound)
                  const _InfoChip(label: 'Ausgang'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (channel.kind) {
    CommunicationChannelKind.email => Icons.mail_outline,
    CommunicationChannelKind.whatsapp => Icons.chat_outlined,
    CommunicationChannelKind.sms => Icons.sms_outlined,
  };

  String get _kindLabel => switch (channel.kind) {
    CommunicationChannelKind.email => 'E-Mail',
    CommunicationChannelKind.whatsapp => 'WhatsApp',
    CommunicationChannelKind.sms => 'SMS',
  };

  String get _statusLabel => switch (channel.status) {
    CommunicationChannelStatus.setupRequired => 'Einrichtung nötig',
    CommunicationChannelStatus.pendingVerification => 'Verifizierung läuft',
    CommunicationChannelStatus.active => 'Aktiv',
    CommunicationChannelStatus.reauthorizationRequired =>
      'Erneute Anmeldung erforderlich',
    CommunicationChannelStatus.disabled => 'Deaktiviert',
  };
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}
