import 'package:flutter/material.dart';

import 'microsoft_connection_launcher.dart';

/// Ein Anbieter, bei dem sich ein Postfach verbinden lässt. Gmail und weitere
/// kommen als zusätzlicher Eintrag in [mailProviderOptions] hinzu; die Oberfläche
/// ändert sich dafür nicht.
class MailProviderOption {
  const MailProviderOption({required this.label, required this.connect});

  final String label;
  final Future<void> Function(BuildContext context) connect;
}

final mailProviderOptions = <MailProviderOption>[
  const MailProviderOption(
    label: 'Microsoft Outlook',
    connect: startMicrosoftConnection,
  ),
];
