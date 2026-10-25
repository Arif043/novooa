import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import 'communication_channel_content.dart';
import 'communication_connect_actions.dart';

class CommunicationSettingsTab extends StatelessWidget {
  const CommunicationSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<CommunicationCubit>()..load(),
        ),
      ],
      child: const _CommunicationView(),
    );
  }
}

class _CommunicationView extends StatelessWidget {
  const _CommunicationView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CommunicationCubit, CommunicationState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: _showChannelMessage,
        ),
      ],
      child: BlocBuilder<CommunicationCubit, CommunicationState>(
        builder: (context, channelState) =>
            _CommunicationBody(channelState: channelState),
      ),
    );
  }

  void _showChannelMessage(BuildContext context, CommunicationState state) {
    _showMessage(context, state.message);
  }

  void _showMessage(BuildContext context, String? message) {
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CommunicationBody extends StatelessWidget {
  const _CommunicationBody({required this.channelState});

  final CommunicationState channelState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommunicationHeader(
            isBusy: channelState.isConnecting,
            showAction: _showHeaderAction,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: CommunicationChannelContent(channelState: channelState),
          ),
        ],
      ),
    );
  }

  /// Im Leerzustand trägt dessen eigene Aktion; zwei gleiche Knöpfe wären
  /// nur Rauschen.
  bool get _showHeaderAction {
    final isEmpty = channelState.channels.isEmpty;
    return !(isEmpty && channelState.status == CommunicationLoadStatus.ready);
  }
}

class _CommunicationHeader extends StatelessWidget {
  const _CommunicationHeader({required this.isBusy, required this.showAction});

  final bool isBusy;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kommunikation', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Verbundene Postfächer, über die Aufgaben Nachrichten '
                'empfangen und senden.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (showAction) ...[
          const SizedBox(width: AppSpacing.md),
          FilledButton.icon(
            onPressed: isBusy ? null : () => connectChannel(context),
            icon: const Icon(Icons.add),
            label: Text(connectActionLabel),
          ),
        ],
      ],
    );
  }
}
