part of 'node_config.dart';

class WriteFileNodeConfig extends NodeConfig {
  const WriteFileNodeConfig({
    required this.fileName,
    required this.contentType,
    this.contentTemplate = '',
    this.fileId,
  });

  final String fileName;
  final String contentType;
  final String? fileId;
  final String contentTemplate;

  factory WriteFileNodeConfig.initial() {
    return const WriteFileNodeConfig(fileName: '', contentType: '');
  }

  @override
  WorkflowPrimitive get primitive => .writeFile;

  @override
  List<Object?> get props => [fileName, contentType, fileId, contentTemplate];

  WriteFileNodeConfig copyWith({
    String? fileName,
    String? contentType,
    String? fileId,
    String? contentTemplate,
    bool clearFileId = false,
  }) {
    return WriteFileNodeConfig(
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      fileId: clearFileId ? null : fileId ?? this.fileId,
      contentTemplate: contentTemplate ?? this.contentTemplate,
    );
  }
}
