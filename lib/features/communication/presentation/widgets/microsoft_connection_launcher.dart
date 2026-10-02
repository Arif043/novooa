import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cubits/communication_cubit.dart';

/// Startet die Microsoft-Anmeldung im Browser — sowohl zum erstmaligen Verbinden
/// als auch, wenn ein Postfach neu verbunden werden muss (die Runtime erkennt das
/// Postfach und behält den Connector).
Future<void> startMicrosoftConnection(BuildContext context) async {
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
