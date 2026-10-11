/// Eine hochzuladende Datei, als Datenstrom geöffnet, damit auch große Modelle nie ganz im Speicher liegen.
class ModelImportFile {
  const ModelImportFile({
    required this.name,
    required this.length,
    required this.open,
  });

  final String name;
  final int length;
  final Stream<List<int>> Function() open;
}

class ModelCatalogImport {
  const ModelCatalogImport({
    required this.manifestJson,
    required this.artifactLength,
    required this.openArtifact,
    this.weights = const [],
  });

  final String manifestJson;
  final int artifactLength;
  final Stream<List<int>> Function() openArtifact;

  /// Ausgelagerte Gewichte (ONNX External Data) unter dem Namen, unter dem das Modell sie erwartet.
  final List<ModelImportFile> weights;
}
