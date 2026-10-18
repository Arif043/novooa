part of 'node_config.dart';

class ScriptNodeConfig extends NodeConfig
    with FileAttachmentSupport<ScriptNodeConfig> {
  const ScriptNodeConfig({
    required this.script,
    this.attachments = const [],
  });

  final String script;
  @override
  final List<NodeAttachment> attachments;

  factory ScriptNodeConfig.initial() {
    return const ScriptNodeConfig(script: '', attachments: []);
  }

  @override
  WorkflowPrimitive get primitive => .script;

  @override
  List<Object?> get props => [script, attachments];

  ScriptNodeConfig copyWith({
    String? script,
    List<NodeAttachment>? attachments,
  }) {
    return ScriptNodeConfig(
      script: script ?? this.script,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  ScriptNodeConfig copyWithAttachments(List<NodeAttachment> attachments) {
    return copyWith(attachments: attachments);
  }
}
