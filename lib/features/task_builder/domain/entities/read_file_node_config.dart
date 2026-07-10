part of 'node_config.dart';

class ReadFileNodeConfig extends NodeConfig {
  const ReadFileNodeConfig({this.file});

  final NodeAttachment? file;

  factory ReadFileNodeConfig.initial() {
    return const ReadFileNodeConfig();
  }

  @override
  WorkflowPrimitive get primitive => .readFile;

  @override
  List<Object?> get props => [file];

  ReadFileNodeConfig copyWith({NodeAttachment? file, bool clearFile = false}) {
    return ReadFileNodeConfig(file: clearFile ? null : file ?? this.file);
  }
}
