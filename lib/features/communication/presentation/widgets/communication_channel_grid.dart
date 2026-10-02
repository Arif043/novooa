import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';
import 'communication_channel_tile.dart';

class CommunicationChannelGrid extends StatelessWidget {
  const CommunicationChannelGrid({
    super.key,
    required this.channels,
    required this.onFakeMessage,
    required this.onSendMessage,
    required this.onDelete,
    required this.onReconnect,
  });

  final List<CommunicationChannel> channels;
  final ValueChanged<CommunicationChannel> onFakeMessage;
  final ValueChanged<CommunicationChannel> onSendMessage;
  final ValueChanged<CommunicationChannel> onDelete;
  final ValueChanged<CommunicationChannel> onReconnect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        final tileWidth =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
        // Die Höhe richtet sich nach dem Inhalt der Kachel (Chips, Hinweise),
        // statt nach einem festen Seitenverhältnis, das bei schmalen Karten überläuft.
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final channel in channels)
              SizedBox(width: tileWidth, child: _tileFor(channel)),
          ],
        );
      },
    );
  }

  Widget _tileFor(CommunicationChannel channel) {
    final hasChannelActions = !channel.isConnectorBacked;
    return CommunicationChannelTile(
      channel: channel,
      onFakeMessage: hasChannelActions && channel.isActive
          ? () => onFakeMessage(channel)
          : null,
      onSendMessage:
          hasChannelActions && channel.isActive && channel.capabilities.outbound
          ? () => onSendMessage(channel)
          : null,
      onDelete: hasChannelActions ? () => onDelete(channel) : null,
      onReconnect: channel.needsReconnection
          ? () => onReconnect(channel)
          : null,
    );
  }

  int _columnsFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }
}
