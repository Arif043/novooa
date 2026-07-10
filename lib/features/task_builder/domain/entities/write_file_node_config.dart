part of 'node_config.dart';

class WriteFileNodeConfig extends NodeConfig {
  const WriteFileNodeConfig({
    required this.fileName,
    required this.contentType,
  });

  final String fileName;
  final String contentType;

  factory WriteFileNodeConfig.initial() {
    return const WriteFileNodeConfig(
      fileName: 'ausgabe.txt',
      contentType: 'text/plain',
    );
  }

  @override
  WorkflowPrimitive get primitive => .writeFile;

  @override
  List<Object?> get props => [fileName, contentType];

  WriteFileNodeConfig copyWith({String? fileName, String? contentType}) {
    return WriteFileNodeConfig(
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
    );
  }
}
