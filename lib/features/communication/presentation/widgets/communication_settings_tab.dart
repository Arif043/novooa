import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/runtime/workspace_capabilities.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import 'communication_channel_content.dart';
import 'microsoft_connection_launcher.dart';
import 'create_communication_channel_dialog.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommunicationHeader(
          isBusy: channelState.isCreating || channelState.isConnecting,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView(
            children: [CommunicationChannelContent(channelState: channelState)],
          ),
        ),
      ],
    );
  }
}

class _CommunicationHeader extends StatelessWidget {
  const _CommunicationHeader({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Text('Kommunikation', style: Theme.of(context).textTheme.displayMedium),
        FilledButton.icon(
          onPressed: isBusy ? null : () => _connect(context),
          icon: const Icon(CupertinoIcons.add_circled),
          label: Text(
            _supportsMessaging ? 'Kanal verbinden' : 'Postfach verbinden',
          ),
        ),
      ],
    );
  }

  /// WhatsApp und SMS gibt es nur in der Cloud; in der lokalen Runtime bleibt
  /// einzig das Outlook-Postfach, das ohne Zwischenfrage verbunden wird.
  bool get _supportsMessaging =>
      serviceLocator<WorkspaceCapabilities>().messagingChannels;

  Future<void> _connect(BuildContext context) {
    if (_supportsMessaging) return _showConnectionActions(context);
    return startMicrosoftConnection(context);
  }

  Future<void> _showConnectionActions(BuildContext context) async {
    final channelKind = await showIosActionSheet<CommunicationChannelKind>(
      context: context,
      title: 'Kanal verbinden',
      actions: const [
        IosAction(label: 'E-Mail mit Microsoft Outlook', value: .email),
        IosAction(label: 'WhatsApp', value: .whatsapp),
        IosAction(label: 'SMS', value: .sms),
      ],
    );
    if (channelKind == null || !context.mounted) return;
    if (channelKind == CommunicationChannelKind.email) {
      await startMicrosoftConnection(context);
      return;
    }
    await _createChannel(context, channelKind);
  }

  Future<void> _createChannel(
    BuildContext context,
    CommunicationChannelKind kind,
  ) async {
    final input = await showIosDialog(
      context: context,
      builder: (_) => CreateCommunicationChannelDialog(initialKind: kind),
    );
    if (input == null || !context.mounted) return;
    await context.read<CommunicationCubit>().create(input);
  }
}
