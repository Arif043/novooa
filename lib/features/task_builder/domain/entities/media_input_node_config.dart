part of 'node_config.dart';

class MediaInputNodeConfig extends NodeConfig {
  const MediaInputNodeConfig({required this.instruction});

  final String instruction;

  factory MediaInputNodeConfig.initial() {
    return const MediaInputNodeConfig(
      instruction: 'Bitte füge ein Bild hinzu.',
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.mediaInput;

  @override
  List<Object?> get props => [instruction];

  MediaInputNodeConfig copyWith({String? instruction}) {
    return MediaInputNodeConfig(instruction: instruction ?? this.instruction);
  }
}
