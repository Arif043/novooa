part of 'node_config.dart';

class ReadEmailNodeConfig extends NodeConfig {
  const ReadEmailNodeConfig();

  factory ReadEmailNodeConfig.initial() {
    return const ReadEmailNodeConfig();
  }

  @override
  WorkflowPrimitive get primitive => .readEmail;

  @override
  List<Object?> get props => const [];
}

enum ChannelEventKind { email, whatsapp, sms }

class ReadChannelEventNodeConfig extends NodeConfig {
  const ReadChannelEventNodeConfig({required this.kind});

  factory ReadChannelEventNodeConfig.initial() {
    return const ReadChannelEventNodeConfig(kind: ChannelEventKind.whatsapp);
  }

  final ChannelEventKind kind;

  @override
  WorkflowPrimitive get primitive => .readChannelEvent;

  @override
  List<Object?> get props => [kind];

  ReadChannelEventNodeConfig copyWith({ChannelEventKind? kind}) {
    return ReadChannelEventNodeConfig(kind: kind ?? this.kind);
  }
}
