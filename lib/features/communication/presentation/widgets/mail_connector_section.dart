import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/mail_connector.dart';
import '../cubits/mail_connectors_cubit.dart';
import '../cubits/mail_connectors_state.dart';

class MailConnectorSection extends StatelessWidget {
  const MailConnectorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<MailConnectorsCubit>()..load(),
      child: const _MailConnectorView(),
    );
  }
}

class _MailConnectorView extends StatelessWidget {
  const _MailConnectorView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MailConnectorsCubit, MailConnectorsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (_, state) => SettingsSection(
        title: 'Postfächer',
        description: 'Verbundene Microsoft-Postfächer',
        icon: CupertinoIcons.envelope,
        child: _MailConnectorContent(state: state),
      ),
    );
  }

  void _showMessage(BuildContext context, MailConnectorsState state) {
    final message = state.message;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _MailConnectorContent extends StatelessWidget {
  const _MailConnectorContent({required this.state});

  final MailConnectorsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      MailConnectorsLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      MailConnectorsLoadStatus.failure => _FailureState(
        isConnecting: state.isConnecting,
        onConnect: () => _beginConnection(context),
      ),
      MailConnectorsLoadStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.connectors.isEmpty)
            const Text('Noch kein Postfach verbunden.'),
          ...state.connectors.map(
            (connector) => _ConnectorRow(connector: connector),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: state.isConnecting
                  ? null
                  : () => _beginConnection(context),
              icon: const Icon(CupertinoIcons.link),
              label: Text(
                state.isConnecting ? 'Wird geöffnet...' : 'Microsoft verbinden',
              ),
            ),
          ),
        ],
      ),
    };
  }

  Future<void> _beginConnection(BuildContext context) async {
    final authorizationUrl = await context
        .read<MailConnectorsCubit>()
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
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.isConnecting, required this.onConnect});

  final bool isConnecting;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FailureMessage(isConnecting: isConnecting),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: isConnecting ? null : onConnect,
          icon: const Icon(CupertinoIcons.link),
          label: const Text('Microsoft verbinden'),
        ),
      ],
    );
  }
}

class _FailureMessage extends StatelessWidget {
  const _FailureMessage({required this.isConnecting});

  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(CupertinoIcons.exclamationmark_triangle),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Text('Postfächer konnten nicht geladen werden.')),
        IconButton(
          tooltip: 'Erneut versuchen',
          onPressed: isConnecting
              ? null
              : context.read<MailConnectorsCubit>().load,
          icon: const Icon(CupertinoIcons.arrow_clockwise),
        ),
      ],
    );
  }
}

class _ConnectorRow extends StatelessWidget {
  const _ConnectorRow({required this.connector});

  final MailConnector connector;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(CupertinoIcons.envelope_fill, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connector.emailAddress, overflow: TextOverflow.ellipsis),
                Text(
                  _statusLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _statusLabel => switch (connector.status) {
    MailConnectorStatus.active => 'Aktiv',
    MailConnectorStatus.reauthorizationRequired =>
      'Erneute Anmeldung erforderlich',
    MailConnectorStatus.disconnected => 'Getrennt',
  };
}
