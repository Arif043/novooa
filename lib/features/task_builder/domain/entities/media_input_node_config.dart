part of 'node_config.dart';

class MediaInputNodeConfig extends NodeConfig {
  const MediaInputNodeConfig({
    required this.instruction,
    this.documentScanEnabled = false,
  });

  final String instruction;

  /// Öffnet bei der Kameraaufnahme einen Dokumentenscanner (automatische
  /// Kantenerkennung, perspektivische Entzerrung, Freistellung) statt der
  /// normalen Kamera. Nur auf Android/iOS wirksam — siehe
  /// `ImagePickerMediaInputPicker`.
  final bool documentScanEnabled;

  factory MediaInputNodeConfig.initial() {
    return const MediaInputNodeConfig(
      instruction: 'Bitte füge ein Bild hinzu.',
    );
  }

  @override
  WorkflowPrimitive get primitive => WorkflowPrimitive.mediaInput;

  @override
  List<Object?> get props => [instruction, documentScanEnabled];

  MediaInputNodeConfig copyWith({
    String? instruction,
    bool? documentScanEnabled,
  }) {
    return MediaInputNodeConfig(
      instruction: instruction ?? this.instruction,
      documentScanEnabled: documentScanEnabled ?? this.documentScanEnabled,
    );
  }
}
