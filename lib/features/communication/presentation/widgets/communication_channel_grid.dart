import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import 'communication_channel_tile.dart';
import 'send_channel_message_dialog.dart';

class CommunicationChannelGrid extends StatelessWidget {
  const CommunicationChannelGrid({super.key, required this.channels});

  final List<CommunicationChannel> channels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: channels.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnsFor(constraints.maxWidth),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            return CommunicationChannelTile(
              channel: channels[index],
              onFakeMessage: () => context
                  .read<CommunicationCubit>()
                  .dispatchFake(channels[index]),
              onSendMessage: () => _sendMessage(context, channels[index]),
              onDelete: () =>
                  context.read<CommunicationCubit>().delete(channels[index]),
            );
          },
        );
      },
    );
  }

  int _columnsFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }

  Future<void> _sendMessage(
    BuildContext context,
    CommunicationChannel channel,
  ) async {
    final message = await showDialog<({String to, String body})>(
      context: context,
      builder: (_) => SendChannelMessageDialog(channel: channel),
    );
    if (message == null || !context.mounted) return;
    await context.read<CommunicationCubit>().send(
      channel: channel,
      to: message.to,
      body: message.body,
    );
  }
}
