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
  const ReadChannelEventNodeConfig({
    required this.kind,
    this.outputNames = const ChannelEventOutputNames(),
  });

  factory ReadChannelEventNodeConfig.initial() {
    return const ReadChannelEventNodeConfig(kind: ChannelEventKind.whatsapp);
  }

  final ChannelEventKind kind;
  final ChannelEventOutputNames outputNames;

  /// Die Werte dieses Kanals in fester Reihenfolge; nur E-Mails haben einen
  /// Betreff.
  List<ChannelEventOutputField> get outputFields => [
    ChannelEventOutputField.sender,
    if (kind == ChannelEventKind.email) ChannelEventOutputField.subject,
    ChannelEventOutputField.message,
    ChannelEventOutputField.receivedAt,
  ];

  @override
  WorkflowPrimitive get primitive => .readChannelEvent;

  @override
  List<Object?> get props => [kind, outputNames];

  ReadChannelEventNodeConfig copyWith({
    ChannelEventKind? kind,
    ChannelEventOutputNames? outputNames,
  }) {
    return ReadChannelEventNodeConfig(
      kind: kind ?? this.kind,
      outputNames: outputNames ?? this.outputNames,
    );
  }
}
