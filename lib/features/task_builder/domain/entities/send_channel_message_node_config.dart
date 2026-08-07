part of 'node_config.dart';

class SendChannelMessageNodeConfig extends NodeConfig {
  const SendChannelMessageNodeConfig({
    required this.kind,
    this.connectorId,
    required this.recipient,
    this.subject = '',
    required this.message,
  });

  factory SendChannelMessageNodeConfig.initial() {
    return const SendChannelMessageNodeConfig(
      kind: ChannelEventKind.whatsapp,
      recipient: '',
      message: '{{input}}',
    );
  }

  final ChannelEventKind kind;
  final String? connectorId;
  final String recipient;
  final String subject;
  final String message;

  @override
  WorkflowPrimitive get primitive => .sendChannelMessage;

  @override
  List<Object?> get props => [kind, connectorId, recipient, subject, message];

  SendChannelMessageNodeConfig copyWith({
    ChannelEventKind? kind,
    String? connectorId,
    String? recipient,
    String? subject,
    String? message,
  }) {
    return SendChannelMessageNodeConfig(
      kind: kind ?? this.kind,
      connectorId: connectorId ?? this.connectorId,
      recipient: recipient ?? this.recipient,
      subject: subject ?? this.subject,
      message: message ?? this.message,
    );
  }
}
