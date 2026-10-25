import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import 'communication_channel_grid.dart';
import 'communication_connect_actions.dart';
import 'communication_states.dart';

/// Die vier Zustände der Kanalliste: Laden, Fehler, Leer, Erfolg.
class CommunicationChannelContent extends StatelessWidget {
  const CommunicationChannelContent({super.key, required this.channelState});

  final CommunicationState channelState;

  @override
  Widget build(BuildContext context) {
    final channels = channelState.channels;
    final failed = channelState.status == CommunicationLoadStatus.failure;
    if (channelState.status == CommunicationLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (channels.isEmpty) {
      return failed
          ? CommunicationFailureState(onRetry: () => _retry(context))
          : CommunicationEmptyState(onConnect: () => connectChannel(context));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failed) ...[
          CommunicationFailureBanner(onRetry: () => _retry(context)),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(child: _grid(context, channels)),
      ],
    );
  }

  Widget _grid(BuildContext context, List<CommunicationChannel> channels) {
    return CommunicationChannelGrid(
      channels: channels,
      onReconnect: (channel) => reconnectMailbox(context, channel),
    );
  }

  void _retry(BuildContext context) {
    context.read<CommunicationCubit>().load();
  }
}
