enum EventTriggerSource {
  emailReceived('E-Mail empfangen'),
  whatsappMessageReceived('WhatsApp-Nachricht'),
  fileCreated('Datei erstellt'),
  webhookReceived('Webhook empfangen');

  const EventTriggerSource(this.label);

  final String label;
}

class EventTriggerConfig {
  const EventTriggerConfig({required this.source, this.filter = ''});

  final EventTriggerSource source;
  final String filter;

  bool get isValid => true;
}
