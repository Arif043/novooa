import 'package:flutter/material.dart';

import '../../../../core/widgets/responsive_card_grid.dart';
import '../../domain/entities/communication_channel.dart';
import 'communication_channel_tile.dart';

/// Postfächer als Karten im gemeinsamen Raster.
class CommunicationChannelGrid extends StatelessWidget {
  const CommunicationChannelGrid({
    super.key,
    required this.channels,
    required this.onReconnect,
  });

  final List<CommunicationChannel> channels;
  final ValueChanged<CommunicationChannel> onReconnect;

  @override
  Widget build(BuildContext context) {
    return ResponsiveCardGrid(
      children: [for (final channel in channels) _tileFor(channel)],
    );
  }

  Widget _tileFor(CommunicationChannel channel) {
    return CommunicationChannelTile(
      key: ValueKey(channel.id),
      channel: channel,
      onReconnect: channel.needsReconnection
          ? () => onReconnect(channel)
          : null,
    );
  }
}
