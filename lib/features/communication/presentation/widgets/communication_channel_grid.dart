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
  });

  final List<CommunicationChannel> channels;
  final ValueChanged<CommunicationChannel> onFakeMessage;
  final ValueChanged<CommunicationChannel> onSendMessage;
  final ValueChanged<CommunicationChannel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: channels.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columnsFor(constraints.maxWidth),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.55,
        ),
        itemBuilder: (context, index) {
          final channel = channels[index];
          final hasChannelActions = !channel.isConnectorBacked;
          return CommunicationChannelTile(
            channel: channel,
            onFakeMessage: hasChannelActions && channel.isActive
                ? () => onFakeMessage(channel)
                : null,
            onSendMessage:
                hasChannelActions &&
                    channel.isActive &&
                    channel.capabilities.outbound
                ? () => onSendMessage(channel)
                : null,
            onDelete: hasChannelActions ? () => onDelete(channel) : null,
          );
        },
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }
}
