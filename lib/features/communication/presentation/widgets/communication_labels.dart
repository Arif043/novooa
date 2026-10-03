import 'package:flutter/material.dart';

import '../../domain/entities/communication_channel.dart';

/// Anzeigetexte und Icons eines Kanals. Anbieter sind austauschbar: Die UI
/// kennt sie nur über ihren Namen, nicht über ihre Eigenheiten.
extension CommunicationChannelLabels on CommunicationChannel {
  IconData get icon => switch (kind) {
    CommunicationChannelKind.email => Icons.mail_outline,
    CommunicationChannelKind.whatsapp => Icons.chat_outlined,
    CommunicationChannelKind.sms => Icons.sms_outlined,
  };

  String get kindLabel => switch (kind) {
    CommunicationChannelKind.email => 'E-Mail',
    CommunicationChannelKind.whatsapp => 'WhatsApp',
    CommunicationChannelKind.sms => 'SMS',
  };

  String get providerLabel => switch (provider) {
    CommunicationProvider.microsoftGraph => 'Microsoft Outlook',
    CommunicationProvider.twilio => 'Twilio',
  };

  String get statusLabel => switch (status) {
    CommunicationChannelStatus.setupRequired => 'Einrichtung nötig',
    CommunicationChannelStatus.pendingVerification => 'Verifizierung läuft',
    CommunicationChannelStatus.active => 'Aktiv',
    CommunicationChannelStatus.reauthorizationRequired =>
      'Erneute Anmeldung erforderlich',
    CommunicationChannelStatus.disabled => 'Deaktiviert',
  };

  String get directionLabel {
    if (capabilities.inbound && capabilities.outbound) {
      return 'Empfangen und senden';
    }
    if (capabilities.inbound) return 'Nur empfangen';
    if (capabilities.outbound) return 'Nur senden';
    return 'Keine Richtung';
  }
}
