part of 'node_config.dart';

class SendChannelMessageNodeConfig extends NodeConfig {
  const SendChannelMessageNodeConfig({
    required this.kind,
    required this.recipient,
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
  final String recipient;
  final String message;

  @override
  WorkflowPrimitive get primitive => .sendChannelMessage;

  @override
  List<Object?> get props => [kind, recipient, message];

  SendChannelMessageNodeConfig copyWith({
    ChannelEventKind? kind,
    String? recipient,
    String? message,
  }) {
    return SendChannelMessageNodeConfig(
      kind: kind ?? this.kind,
      recipient: recipient ?? this.recipient,
      message: message ?? this.message,
    );
  }
}
