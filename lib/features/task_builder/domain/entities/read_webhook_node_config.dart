part of 'node_config.dart';

/// Liest das Ereignis, das die Aufgabe über einen Webhook gestartet hat.
class ReadWebhookNodeConfig extends NodeConfig {
  const ReadWebhookNodeConfig();

  factory ReadWebhookNodeConfig.initial() {
    return const ReadWebhookNodeConfig();
  }

  @override
  WorkflowPrimitive get primitive => .readWebhook;

  @override
  List<Object?> get props => const [];
}
