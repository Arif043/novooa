enum EventTriggerSource {
  emailReceived('E-Mail empfangen'),
  whatsappMessageReceived('WhatsApp-Nachricht'),
  fileCreated('Datei erstellt'),
  webhookReceived('Webhook empfangen');

  const EventTriggerSource(this.label);

  final String label;
}

class EventTriggerConfig {
  const EventTriggerConfig({
    required this.source,
    this.filter = '',
    this.channelId,
  });

  final EventTriggerSource source;
  final String filter;
  final String? channelId;

  bool get isValid => true;
}
