import 'package:flutter/material.dart';

import '../../../../core/widgets/responsive_card_grid.dart';
import '../../domain/entities/communication_channel.dart';
import 'communication_channel_tile.dart';

/// Kanäle als Karten im gemeinsamen Raster. Die Aktionen einer Karte hängen
/// davon ab, ob ein Connector (Postfach) oder ein Team-Kanal dahintersteht.
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
    return ResponsiveCardGrid(
      children: [for (final channel in channels) _tileFor(channel)],
    );
  }

  Widget _tileFor(CommunicationChannel channel) {
    final hasChannelActions = !channel.isConnectorBacked;
    return CommunicationChannelTile(
      key: ValueKey(channel.id),
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
}
