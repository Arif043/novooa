import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/runtime/workspace_capabilities.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import 'create_communication_channel_dialog.dart';
import 'communication_mailboxes_sheet.dart';
import 'mail_provider_option.dart';

/// WhatsApp und SMS gibt es nur in der Cloud; lokal bleiben die Postfächer.
bool get supportsMessagingChannels =>
    serviceLocator<WorkspaceCapabilities>().messagingChannels;

String get connectActionLabel =>
    supportsMessagingChannels ? 'Kanal verbinden' : 'Postfach verbinden';

/// Der Einstieg „verbinden“: Lokal wählt man nur, wenn es mehrere Anbieter
/// gibt; in der Cloud zuerst die Art des Kanals.
Future<void> connectChannel(BuildContext context) {
  if (supportsMessagingChannels) return _chooseChannel(context);
  return _chooseMailProvider(context);
}

/// Lokal: Der Dialog zeigt die verbundenen Postfächer und führt über
/// „Weiteres Postfach verbinden“ zur Wahl des Anbieters.
Future<void> _chooseMailProvider(BuildContext context) async {
  final cubit = context.read<CommunicationCubit>();
  final option = await CommunicationMailboxesSheet.show(
    context,
    cubit: cubit,
    startWithProviders: cubit.state.channels.every((c) => !c.isConnectorBacked),
  );
  if (option == null || !context.mounted) return;
  await option.connect(context);
}

/// Ein Postfach mit abgelaufener Anmeldung über seinen eigenen Anbieter
/// neu verbinden.
Future<void> reconnectMailbox(
  BuildContext context,
  CommunicationChannel channel,
) async {
  await mailProviderFor(channel.provider)?.connect(context);
}

Future<void> _chooseChannel(BuildContext context) async {
  final choice = await showIosActionSheet<Object>(
    context: context,
    title: 'Kanal verbinden',
    actions: [
      for (final option in mailProviderOptions)
        IosAction(label: 'E-Mail mit ${option.label}', value: option),
      const IosAction(
        label: 'WhatsApp',
        value: CommunicationChannelKind.whatsapp,
      ),
      const IosAction(label: 'SMS', value: CommunicationChannelKind.sms),
    ],
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case MailProviderOption():
      await choice.connect(context);
    case CommunicationChannelKind():
      await _createChannel(context, choice);
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
