part of 'node_config.dart';

class WriteFileNodeConfig extends NodeConfig {
  const WriteFileNodeConfig({
    required this.fileName,
    required this.contentType,
    this.contentTemplate = '',
    this.fileId,
    this.folderId,
  });

  final String fileName;
  final String contentType;
  final String? fileId;

  /// Zielordner für neue Dateien; `null` heißt oberste Ebene. Bei einer
  /// bestehenden Datei (`fileId`) bleibt sie in ihrem Ordner.
  final String? folderId;
  final String contentTemplate;

  factory WriteFileNodeConfig.initial() {
    return const WriteFileNodeConfig(fileName: '', contentType: '');
  }

  @override
  WorkflowPrimitive get primitive => .writeFile;

  @override
  List<Object?> get props => [fileName, contentType, fileId, folderId, contentTemplate];

  WriteFileNodeConfig copyWith({
    String? fileName,
    String? contentType,
    String? fileId,
    String? folderId,
    String? contentTemplate,
    bool clearFileId = false,
    bool clearFolderId = false,
  }) {
    return WriteFileNodeConfig(
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      fileId: clearFileId ? null : fileId ?? this.fileId,
      folderId: clearFolderId ? null : folderId ?? this.folderId,
      contentTemplate: contentTemplate ?? this.contentTemplate,
    );
  }
}
