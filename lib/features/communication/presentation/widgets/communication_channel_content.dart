import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import '../../domain/entities/communication_channel.dart';
import 'communication_channel_grid.dart';
import 'send_channel_message_dialog.dart';

class CommunicationChannelContent extends StatelessWidget {
  const CommunicationChannelContent({super.key, required this.channelState});

  final CommunicationState channelState;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasNoData) {
      return _hasFailure
          ? _PartialFailureState(onRetry: _retry)
          : const _EmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasFailure) _PartialFailureState(onRetry: _retry),
        if (_hasFailure) const SizedBox(height: AppSpacing.md),
        CommunicationChannelGrid(
          channels: _channels,
          onFakeMessage: (channel) => _dispatchFakeMessage(context, channel),
          onSendMessage: (channel) => _sendMessage(context, channel),
          onDelete: (channel) => _deleteChannel(context, channel),
        ),
      ],
    );
  }

  bool get _isLoading {
    return channelState.status == CommunicationLoadStatus.loading;
  }

  bool get _hasFailure {
    return channelState.status == CommunicationLoadStatus.failure;
  }

  bool get _hasNoData => _channels.isEmpty;

  List<CommunicationChannel> get _channels {
    return [...channelState.channels];
  }

  void _retry(BuildContext context) {
    context.read<CommunicationCubit>().load();
  }

  void _dispatchFakeMessage(
    BuildContext context,
    CommunicationChannel channel,
  ) {
    context.read<CommunicationCubit>().dispatchFake(channel);
  }

  Future<void> _sendMessage(
    BuildContext context,
    CommunicationChannel channel,
  ) async {
    final message = await showIosDialog<({String to, String body})>(
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

  void _deleteChannel(BuildContext context, CommunicationChannel channel) {
    context.read<CommunicationCubit>().delete(channel);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.bubble_left_bubble_right,
            size: AppSpacing.xxl,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Noch keine Verbindungen',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Verbinde E-Mail, WhatsApp oder SMS mit novooa.'),
        ],
      ),
    );
  }
}

class _PartialFailureState extends StatelessWidget {
  const _PartialFailureState({required this.onRetry});

  final ValueChanged<BuildContext> onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.exclamationmark_triangle),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Text('Kanäle konnten nicht vollständig geladen werden.'),
        ),
        IconButton(
          tooltip: 'Erneut versuchen',
          onPressed: () => onRetry(context),
          icon: const Icon(CupertinoIcons.arrow_clockwise),
        ),
      ],
    );
  }
}
