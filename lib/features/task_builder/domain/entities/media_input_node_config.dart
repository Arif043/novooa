part of 'node_config.dart';

enum MediaInputSource {
  gallery('Bild auswählen'),
  camera('Kamera verwenden');

  const MediaInputSource(this.label);

  final String label;
}

class MediaInputNodeConfig extends NodeConfig {
  const MediaInputNodeConfig({required this.instruction, required this.source});

  final String instruction;
  final MediaInputSource source;

  factory MediaInputNodeConfig.initial() {
    return const MediaInputNodeConfig(
      instruction: 'Bitte füge ein Bild hinzu.',
      source: MediaInputSource.gallery,
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.mediaInput;

  @override
  List<Object?> get props => [instruction, source];

  MediaInputNodeConfig copyWith({
    String? instruction,
    MediaInputSource? source,
  }) {
    return MediaInputNodeConfig(
      instruction: instruction ?? this.instruction,
      source: source ?? this.source,
    );
  }
}
