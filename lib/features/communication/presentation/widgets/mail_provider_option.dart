import 'package:flutter/material.dart';

import '../../domain/entities/communication_channel.dart';
import 'microsoft_connection_launcher.dart';

/// Ein Anbieter, bei dem sich ein Postfach verbinden lässt. Gmail und weitere
/// kommen als zusätzlicher Eintrag in [mailProviderOptions] hinzu; die Oberfläche
/// ändert sich dafür nicht.
class MailProviderOption {
  const MailProviderOption({
    required this.provider,
    required this.label,
    required this.description,
    required this.icon,
    required this.connect,
    this.logoAsset,
  });

  final CommunicationProvider provider;
  final String label;
  final String description;
  final IconData icon;

  /// Markenlogo; ohne Logo (oder wenn es fehlt) steht [icon].
  final String? logoAsset;
  final Future<void> Function(BuildContext context) connect;
}

final mailProviderOptions = <MailProviderOption>[
  const MailProviderOption(
    provider: CommunicationProvider.microsoftGraph,
    label: 'Microsoft Outlook',
    description: 'Outlook.com, Hotmail und Microsoft 365',
    icon: Icons.mail_outline,
    connect: startMicrosoftConnection,
    logoAsset: 'assets/icons/microsoft.png',
  ),
];

/// Der Anbieter, über den sich ein bestehendes Postfach neu verbinden lässt.
MailProviderOption? mailProviderFor(CommunicationProvider provider) {
  for (final option in mailProviderOptions) {
    if (option.provider == provider) return option;
  }
  return null;
}
