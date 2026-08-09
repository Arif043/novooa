import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import 'communication_channel_content.dart';
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
          onPressed: isBusy ? null : () => _showConnectionActions(context),
          icon: const Icon(CupertinoIcons.add_circled),
          label: const Text('Kanal verbinden'),
        ),
      ],
    );
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
      await _connectMicrosoft(context);
      return;
    }
    await _createChannel(context, channelKind);
  }

  Future<void> _connectMicrosoft(BuildContext context) async {
    final authorizationUrl = await context
        .read<CommunicationCubit>()
        .beginMicrosoftConnection();
    if (authorizationUrl == null || !context.mounted) return;
    final opened = await launchUrl(
      Uri.parse(authorizationUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microsoft-Anmeldung konnte nicht geöffnet werden.'),
        ),
      );
    }
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
