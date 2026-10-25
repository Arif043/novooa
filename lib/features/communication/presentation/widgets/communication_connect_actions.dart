import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import 'communication_mailboxes_sheet.dart';
import 'mail_provider_option.dart';

const connectActionLabel = 'Postfach verbinden';

/// Der Dialog zeigt die verbundenen Postfächer und führt über
/// „Weiteres Postfach verbinden“ zur Wahl des Anbieters.
Future<void> connectChannel(BuildContext context) async {
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
