import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/widgets/open_authorization_page.dart';

import '../cubits/communication_cubit.dart';

/// Startet die Microsoft-Anmeldung im Browser — sowohl zum erstmaligen Verbinden
/// als auch, wenn ein Postfach neu verbunden werden muss (die Runtime erkennt das
/// Postfach und behält den Connector).
Future<void> startMicrosoftConnection(BuildContext context) {
  final cubit = context.read<CommunicationCubit>();
  return openAuthorizationPage(context, cubit.beginMicrosoftConnection);
}
