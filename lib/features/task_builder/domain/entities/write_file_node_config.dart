part of 'node_config.dart';

class WriteFileNodeConfig extends NodeConfig {
  const WriteFileNodeConfig({
    required this.fileName,
    required this.contentType,
    this.fileId,
  });

  final String fileName;
  final String contentType;
  final String? fileId;

  factory WriteFileNodeConfig.initial() {
    return const WriteFileNodeConfig(
      fileName: 'ausgabe.txt',
      contentType: 'text/plain',
    );
  }

  @override
  WorkflowPrimitive get primitive => .writeFile;

  @override
  List<Object?> get props => [fileName, contentType, fileId];

  WriteFileNodeConfig copyWith({
    String? fileName,
    String? contentType,
    String? fileId,
    bool clearFileId = false,
  }) {
    return WriteFileNodeConfig(
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      fileId: clearFileId ? null : fileId ?? this.fileId,
    );
  }
}
