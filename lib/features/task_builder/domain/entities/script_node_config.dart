part of 'node_config.dart';

class ScriptNodeConfig extends NodeConfig
    with FileAttachmentSupport<ScriptNodeConfig> {
  const ScriptNodeConfig({
    required this.script,
    this.packages = const [],
    this.attachments = const [],
  });

  final String script;

  /// Python-Pakete von PyPI; leer heißt nur Standardbibliothek. Gleiche
  /// Listen teilen sich in der Runtime eine Umgebung.
  final List<PythonPackage> packages;
  @override
  final List<NodeAttachment> attachments;

  factory ScriptNodeConfig.initial() {
    return const ScriptNodeConfig(script: '', attachments: []);
  }

  @override
  WorkflowPrimitive get primitive => .script;

  @override
  List<Object?> get props => [script, packages, attachments];

  ScriptNodeConfig copyWith({
    String? script,
    List<PythonPackage>? packages,
    List<NodeAttachment>? attachments,
  }) {
    return ScriptNodeConfig(
      script: script ?? this.script,
      packages: packages ?? this.packages,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  ScriptNodeConfig copyWithAttachments(List<NodeAttachment> attachments) {
    return copyWith(attachments: attachments);
  }
}
